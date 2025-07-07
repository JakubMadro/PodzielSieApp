const Group = require('../../models/Group');
const User = require('../../models/User');
const groupService = require('../services/groupService');
const settlementService = require('../services/settlementService');
const { sendNotification } = require('../../utils/notifications');

/**
 * @desc    Tworzenie nowej grupy
 * @route   POST /api/groups
 * @access  Private
 */
exports.createGroup = async (req, res, next) => {
    try {
        const { name, description, defaultCurrency } = req.body;

        // Utwórz nową grupę
        const group = new Group({
            name,
            description,
            defaultCurrency: defaultCurrency || 'PLN',
            members: [{
                user: req.user._id,
                role: 'admin',
                joined: new Date()
            }],
            isArchived: false
        });

        // Zapisz grupę w bazie danych
        await group.save();

        // Zwróć grupę (z informacjami o członku-założycielu)
        const populatedGroup = await Group.findById(group._id).populate('members.user', 'firstName lastName email avatar');

        res.status(201).json({
            success: true,
            message: 'Grupa utworzona pomyślnie',
            group: populatedGroup
        });
    } catch (error) {
        next(error);
    }
};

/**
 * @desc    Pobieranie listy grup użytkownika
 * @route   GET /api/groups
 * @access  Private
 */
exports.getUserGroups = async (req, res, next) => {
    try {
        // Pobierz grupy, w których użytkownik jest członkiem
        const userGroups = await groupService.getUserGroups(req.user._id);

        res.json({
            success: true,
            groups: userGroups
        });
    } catch (error) {
        next(error);
    }
};

/**
 * @desc    Pobieranie szczegółów grupy
 * @route   GET /api/groups/:id
 * @access  Private (tylko członkowie grupy)
 */
exports.getGroupDetails = async (req, res, next) => {
    try {
        const { id } = req.params;

        // Sprawdź, czy grupa istnieje i czy użytkownik jest jej członkiem
        // Dzięki middleware isGroupMember mamy już dostęp do grupy w req.group

        // Pobierz szczegóły grupy (z członkami)
        const group = await Group.findById(id)
            .populate('members.user', 'firstName lastName email avatar');

        if (!group) {
            return res.status(404).json({
                success: false,
                message: 'Grupa nie została znaleziona'
            });
        }

        // Sprawdź, czy użytkownik jest członkiem grupy
        const isMember = group.members.some(
            member => member.user._id.toString() === req.user._id.toString()
        );

        if (!isMember) {
            return res.status(403).json({
                success: false,
                message: 'Nie masz dostępu do tej grupy'
            });
        }

        // Pobierz bilans użytkownika w grupie
        const balances = await settlementService.getGroupBalances(id);

        // Oblicz bilans dla bieżącego użytkownika
        let userBalance = 0;
        balances.forEach(balance => {
            if (balance.payer.toString() === req.user._id.toString()) {
                userBalance -= balance.amount;
            }
            if (balance.receiver.toString() === req.user._id.toString()) {
                userBalance += balance.amount;
            }
        });

        // Dodaj informację o bilansie do obiektu grupy
        const groupWithBalance = group.toObject();
        groupWithBalance.userBalance = userBalance;

        res.json({
            success: true,
            group: groupWithBalance
        });
    } catch (error) {
        next(error);
    }
};

/**
 * @desc    Aktualizacja grupy
 * @route   PUT /api/groups/:id
 * @access  Private (tylko admin grupy)
 */
exports.updateGroup = async (req, res, next) => {
    try {
        const { id } = req.params;
        const { name, description, defaultCurrency } = req.body;

        // Sprawdź, czy użytkownik jest administratorem grupy (middleware isGroupAdmin)
        const group = req.group;

        // Aktualizuj tylko podane pola
        if (name) group.name = name;
        if (description !== undefined) group.description = description;
        if (defaultCurrency) group.defaultCurrency = defaultCurrency;

        // Zapisz zaktualizowaną grupę
        await group.save();

        // Pobierz zaktualizowaną grupę z informacjami o członkach
        const updatedGroup = await Group.findById(id)
            .populate('members.user', 'firstName lastName email avatar');

        res.json({
            success: true,
            message: 'Grupa zaktualizowana pomyślnie',
            group: updatedGroup
        });
    } catch (error) {
        next(error);
    }
};

/**
 * @desc    Dodawanie nowego członka do grupy
 * @route   POST /api/groups/:id/members
 * @access  Private (tylko admin grupy)
 */
exports.addGroupMember = async (req, res, next) => {
    try {
        const { id } = req.params;
        const { email, role = 'member' } = req.body;

        // Sprawdź, czy użytkownik jest administratorem grupy (middleware isGroupAdmin)
        const group = req.group;

        // Znajdź użytkownika po adresie email
        const user = await User.findOne({ email });
        if (!user) {
            return res.status(404).json({
                success: false,
                message: 'Użytkownik o podanym adresie email nie istnieje'
            });
        }

        // Sprawdź, czy użytkownik jest już członkiem grupy
        const isAlreadyMember = group.members.some(
            member => member.user.toString() === user._id.toString()
        );

        if (isAlreadyMember) {
            return res.status(409).json({
                success: false,
                message: 'Użytkownik jest już członkiem tej grupy'
            });
        }

        // Dodaj nowego członka do grupy
        group.members.push({
            user: user._id,
            role,
            joined: new Date()
        });

        // Zapisz zaktualizowaną grupę
        await group.save();

        // Wyślij powiadomienie do nowego członka
        if (user.notificationSettings.groupInvite) {
            await sendNotification(
                user._id,
                'Zostałeś dodany do nowej grupy',
                `${req.user.firstName} dodał Cię do grupy "${group.name}"`,
                {
                    type: 'GROUP_INVITE',
                    groupId: group._id
                }
            );
        }

        // Pobierz zaktualizowaną grupę z informacjami o członkach
        const updatedGroup = await Group.findById(id)
            .populate('members.user', 'firstName lastName email avatar');

        res.json({
            success: true,
            message: 'Członek dodany pomyślnie',
            group: updatedGroup
        });
    } catch (error) {
        next(error);
    }
};

/**
 * @desc    Usuwanie członka z grupy
 * @route   DELETE /api/groups/:id/members/:userId
 * @access  Private (tylko admin grupy lub sam użytkownik)
 */
exports.removeGroupMember = async (req, res, next) => {
    try {
        const { id, userId } = req.params;

        // Pobierz grupę
        const group = await Group.findById(id);
        if (!group) {
            return res.status(404).json({
                success: false,
                message: 'Grupa nie została znaleziona'
            });
        }

        // Sprawdź, czy usuwany członek istnieje w grupie
        const memberIndex = group.members.findIndex(
            member => member.user.toString() === userId
        );

        if (memberIndex === -1) {
            return res.status(404).json({
                success: false,
                message: 'Członek nie został znaleziony w grupie'
            });
        }

        // Sprawdź uprawnienia (tylko admin grupy lub sam użytkownik może usunąć członka)
        const isAdmin = group.members.some(
            member => member.user.toString() === req.user._id.toString() && member.role === 'admin'
        );

        const isSelfRemoval = userId === req.user._id.toString();

        if (!isAdmin && !isSelfRemoval) {
            return res.status(403).json({
                success: false,
                message: 'Nie masz uprawnień do usunięcia tego członka'
            });
        }

        // Nie pozwól na usunięcie ostatniego administratora
        if (group.members[memberIndex].role === 'admin') {
            const adminCount = group.members.filter(member => member.role === 'admin').length;

            if (adminCount === 1) {
                return res.status(400).json({
                    success: false,
                    message: 'Nie można usunąć ostatniego administratora grupy'
                });
            }
        }

        // Usuń członka z grupy
        group.members.splice(memberIndex, 1);

        // Zapisz zaktualizowaną grupę
        await group.save();

        // Pobierz zaktualizowaną grupę z informacjami o członkach
        const updatedGroup = await Group.findById(id)
            .populate('members.user', 'firstName lastName email avatar');

        res.json({
            success: true,
            message: 'Członek usunięty pomyślnie',
            group: updatedGroup
        });
    } catch (error) {
        next(error);
    }
};

/**
 * @desc    Zmiana roli członka w grupie
 * @route   PUT /api/groups/:id/members/:userId
 * @access  Private (tylko admin grupy)
 */
exports.updateMemberRole = async (req, res, next) => {
    try {
        const { id, userId } = req.params;
        const { role } = req.body;

        // Sprawdź, czy rola jest poprawna
        if (role !== 'admin' && role !== 'member') {
            return res.status(400).json({
                success: false,
                message: 'Rola musi być jedną z: admin, member'
            });
        }

        // Pobierz grupę
        const group = await Group.findById(id);
        if (!group) {
            return res.status(404).json({
                success: false,
                message: 'Grupa nie została znaleziona'
            });
        }

        // Sprawdź, czy użytkownik jest administratorem grupy
        const isAdmin = group.members.some(
            member => member.user.toString() === req.user._id.toString() && member.role === 'admin'
        );

        if (!isAdmin) {
            return res.status(403).json({
                success: false,
                message: 'Nie masz uprawnień do zmiany roli'
            });
        }

        // Znajdź członka, którego rola ma być zmieniona
        const memberIndex = group.members.findIndex(
            member => member.user.toString() === userId
        );

        if (memberIndex === -1) {
            return res.status(404).json({
                success: false,
                message: 'Członek nie został znaleziony w grupie'
            });
        }

        // Jeśli zmieniamy rolę z admin na member, upewnij się, że nie jest to ostatni admin
        if (group.members[memberIndex].role === 'admin' && role === 'member') {
            const adminCount = group.members.filter(member => member.role === 'admin').length;

            if (adminCount === 1) {
                return res.status(400).json({
                    success: false,
                    message: 'Nie można zmienić roli ostatniego administratora'
                });
            }
        }

        // Zaktualizuj rolę członka
        group.members[memberIndex].role = role;

        // Zapisz zaktualizowaną grupę
        await group.save();

        // Pobierz zaktualizowaną grupę z informacjami o członkach
        const updatedGroup = await Group.findById(id)
            .populate('members.user', 'firstName lastName email avatar');

        res.json({
            success: true,
            message: 'Rola członka zaktualizowana pomyślnie',
            group: updatedGroup
        });
    } catch (error) {
        next(error);
    }
};

/**
 * @desc    Archiwizacja / przywracanie grupy
 * @route   PUT /api/groups/:id/archive
 * @access  Private (tylko admin grupy)
 */
exports.toggleArchiveGroup = async (req, res, next) => {
    try {
        const { id } = req.params;
        const { archive } = req.body;

        // Pobierz grupę
        const group = await Group.findById(id);
        if (!group) {
            return res.status(404).json({
                success: false,
                message: 'Grupa nie została znaleziona'
            });
        }

        // Sprawdź, czy użytkownik jest administratorem grupy
        const isAdmin = group.members.some(
            member => member.user.toString() === req.user._id.toString() && member.role === 'admin'
        );

        if (!isAdmin) {
            return res.status(403).json({
                success: false,
                message: 'Nie masz uprawnień do archiwizacji/przywracania grupy'
            });
        }

        // Zaktualizuj status archiwizacji
        group.isArchived = archive;

        // Zapisz zaktualizowaną grupę
        await group.save();

        res.json({
            success: true,
            message: archive ? 'Grupa zarchiwizowana pomyślnie' : 'Grupa przywrócona pomyślnie',
            group
        });
    } catch (error) {
        next(error);
    }
};

/**
 * @desc    Usunięcie grupy
 * @route   DELETE /api/groups/:id
 * @access  Private (tylko admin grupy)
 */
exports.deleteGroup = async (req, res, next) => {
    try {
        const { id } = req.params;

        // Pobierz grupę
        const group = await Group.findById(id);
        if (!group) {
            return res.status(404).json({
                success: false,
                message: 'Grupa nie została znaleziona'
            });
        }

        // Sprawdź, czy użytkownik jest administratorem grupy
        const isAdmin = group.members.some(
            member => member.user.toString() === req.user._id.toString() && member.role === 'admin'
        );

        if (!isAdmin) {
            return res.status(403).json({
                success: false,
                message: 'Nie masz uprawnień do usunięcia grupy'
            });
        }

        // Sprawdź, czy grupa ma nierozliczone wydatki
        // TODO: Dodać logikę sprawdzania nierozliczonych wydatków
        // W rzeczywistej aplikacji powinno się sprawdzić, czy wszystkie rozliczenia są zakończone

        // Usuń grupę
        await Group.findByIdAndDelete(id);

        res.json({
            success: true,
            message: 'Grupa usunięta pomyślnie'
        });
    } catch (error) {
        next(error);
    }
};