const Group = require('../../models/Group');
const User = require('../../models/User');
const Expense = require('../../models/Expense');
const Settlement = require('../../models/Settlement');
const mongoose = require('mongoose');

/**
 * Pobiera grupy, do których należy użytkownik
 *
 * @param {string} userId - ID użytkownika
 * @param {boolean} includeArchived - Czy uwzględnić zarchiwizowane grupy
 * @returns {Promise<Array>} - Tablica grup użytkownika
 */
exports.getUserGroups = async (userId, includeArchived = false) => {
    try {
        // Przygotuj zapytanie bazowe
        const query = {
            'members.user': userId
        };

        // Dodaj filtr na zarchiwizowane grupy, jeśli potrzeba
        if (!includeArchived) {
            query.isArchived = false;
        }

        // Pobierz grupy z bazy danych
        const groups = await Group.find(query)
            .populate('members.user', 'firstName lastName email avatar')
            .sort({ updatedAt: -1 });

        return groups;
    } catch (error) {
        console.error('Błąd podczas pobierania grup użytkownika:', error);
        throw error;
    }
};

/**
 * Tworzy nową grupę
 *
 * @param {string} userId - ID użytkownika tworzącego grupę
 * @param {Object} groupData - Dane nowej grupy
 * @returns {Promise<Object>} - Utworzona grupa
 */
exports.createGroup = async (userId, groupData) => {
    const session = await mongoose.startSession();
    session.startTransaction();

    try {
        // Utwórz nową grupę
        const group = new Group({
            name: groupData.name,
            description: groupData.description || '',
            defaultCurrency: groupData.defaultCurrency || 'PLN',
            members: [{
                user: userId,
                role: 'admin',
                joined: new Date()
            }],
            isArchived: false
        });

        // Zapisz grupę w bazie danych
        await group.save({ session });

        // Pobierz zapisaną grupę z populacją
        const populatedGroup = await Group.findById(group._id)
            .populate('members.user', 'firstName lastName email avatar')
            .session(session);

        await session.commitTransaction();
        return populatedGroup;
    } catch (error) {
        await session.abortTransaction();
        console.error('Błąd podczas tworzenia grupy:', error);
        throw error;
    } finally {
        session.endSession();
    }
};

/**
 * Pobiera szczegóły grupy
 *
 * @param {string} groupId - ID grupy
 * @param {string} userId - ID użytkownika (do weryfikacji uprawnień)
 * @returns {Promise<Object>} - Grupa z szczegółami
 */
exports.getGroupDetails = async (groupId, userId) => {
    try {
        // Pobierz grupę z bazy danych
        const group = await Group.findById(groupId)
            .populate('members.user', 'firstName lastName email avatar');

        if (!group) {
            throw new Error('Grupa nie została znaleziona');
        }

        // Sprawdź, czy użytkownik jest członkiem grupy
        const isMember = group.members.some(
            member => member.user._id.toString() === userId.toString()
        );

        if (!isMember) {
            throw new Error('Brak dostępu do tej grupy');
        }

        return group;
    } catch (error) {
        console.error(`Błąd podczas pobierania szczegółów grupy ${groupId}:`, error);
        throw error;
    }
};

/**
 * Aktualizuje dane grupy
 *
 * @param {string} groupId - ID grupy
 * @param {string} userId - ID użytkownika (do weryfikacji uprawnień)
 * @param {Object} updateData - Dane do aktualizacji
 * @returns {Promise<Object>} - Zaktualizowana grupa
 */
exports.updateGroup = async (groupId, userId, updateData) => {
    try {
        // Pobierz grupę z bazy danych
        const group = await Group.findById(groupId);

        if (!group) {
            throw new Error('Grupa nie została znaleziona');
        }

        // Sprawdź, czy użytkownik jest administratorem grupy
        const isAdmin = group.members.some(
            member => member.user.toString() === userId.toString() && member.role === 'admin'
        );

        if (!isAdmin) {
            throw new Error('Brak uprawnień do edycji grupy');
        }

        // Aktualizuj pola grupy
        if (updateData.name) group.name = updateData.name;
        if (updateData.description !== undefined) group.description = updateData.description;
        if (updateData.defaultCurrency) group.defaultCurrency = updateData.defaultCurrency;

        // Zapisz zaktualizowaną grupę
        await group.save();

        // Pobierz zaktualizowaną grupę z populacją
        const updatedGroup = await Group.findById(groupId)
            .populate('members.user', 'firstName lastName email avatar');

        return updatedGroup;
    } catch (error) {
        console.error(`Błąd podczas aktualizacji grupy ${groupId}:`, error);
        throw error;
    }
};

/**
 * Dodaje nowego członka do grupy
 *
 * @param {string} groupId - ID grupy
 * @param {string} adminId - ID administratora dodającego członka
 * @param {string} userEmail - Email nowego członka
 * @param {string} role - Rola nowego członka (admin/member)
 * @returns {Promise<Object>} - Zaktualizowana grupa
 */
exports.addGroupMember = async (groupId, adminId, userEmail, role = 'member') => {
    const session = await mongoose.startSession();
    session.startTransaction();

    try {
        // Pobierz grupę
        const group = await Group.findById(groupId).session(session);

        if (!group) {
            throw new Error('Grupa nie została znaleziona');
        }

        // Sprawdź, czy użytkownik jest administratorem grupy
        const isAdmin = group.members.some(
            member => member.user.toString() === adminId.toString() && member.role === 'admin'
        );

        if (!isAdmin) {
            throw new Error('Brak uprawnień do dodawania członków');
        }

        // Znajdź użytkownika po adresie email
        const user = await User.findOne({ email: userEmail }).session(session);
        if (!user) {
            throw new Error('Użytkownik o podanym adresie email nie istnieje');
        }

        // Sprawdź, czy użytkownik jest już członkiem grupy
        const isAlreadyMember = group.members.some(
            member => member.user.toString() === user._id.toString()
        );

        if (isAlreadyMember) {
            throw new Error('Użytkownik jest już członkiem tej grupy');
        }

        // Dodaj nowego członka do grupy
        group.members.push({
            user: user._id,
            role,
            joined: new Date()
        });

        // Zapisz zaktualizowaną grupę
        await group.save({ session });

        // Pobierz zaktualizowaną grupę z populacją
        const updatedGroup = await Group.findById(groupId)
            .populate('members.user', 'firstName lastName email avatar')
            .session(session);

        await session.commitTransaction();
        return updatedGroup;
    } catch (error) {
        await session.abortTransaction();
        console.error(`Błąd podczas dodawania członka do grupy ${groupId}:`, error);
        throw error;
    } finally {
        session.endSession();
    }
};

/**
 * Usuwa członka z grupy
 *
 * @param {string} groupId - ID grupy
 * @param {string} currentUserId - ID użytkownika wykonującego operację
 * @param {string} memberIdToRemove - ID członka do usunięcia
 * @returns {Promise<Object>} - Zaktualizowana grupa
 */
exports.removeGroupMember = async (groupId, currentUserId, memberIdToRemove) => {
    const session = await mongoose.startSession();
    session.startTransaction();

    try {
        // Pobierz grupę
        const group = await Group.findById(groupId).session(session);

        if (!group) {
            throw new Error('Grupa nie została znaleziona');
        }

        // Sprawdź, czy usuwany członek istnieje w grupie
        const memberIndex = group.members.findIndex(
            member => member.user.toString() === memberIdToRemove.toString()
        );

        if (memberIndex === -1) {
            throw new Error('Członek nie został znaleziony w grupie');
        }

        // Sprawdź uprawnienia (tylko admin grupy lub sam użytkownik może usunąć członka)
        const isAdmin = group.members.some(
            member => member.user.toString() === currentUserId.toString() && member.role === 'admin'
        );

        const isSelfRemoval = memberIdToRemove.toString() === currentUserId.toString();

        if (!isAdmin && !isSelfRemoval) {
            throw new Error('Brak uprawnień do usunięcia tego członka');
        }

        // Nie pozwól na usunięcie ostatniego administratora
        if (group.members[memberIndex].role === 'admin') {
            const adminCount = group.members.filter(member => member.role === 'admin').length;

            if (adminCount === 1) {
                throw new Error('Nie można usunąć ostatniego administratora grupy');
            }
        }

        // Usuń członka z grupy
        group.members.splice(memberIndex, 1);

        // Zapisz zaktualizowaną grupę
        await group.save({ session });

        // Pobierz zaktualizowaną grupę z populacją
        const updatedGroup = await Group.findById(groupId)
            .populate('members.user', 'firstName lastName email avatar')
            .session(session);

        await session.commitTransaction();
        return updatedGroup;
    } catch (error) {
        await session.abortTransaction();
        console.error(`Błąd podczas usuwania członka ${memberIdToRemove} z grupy ${groupId}:`, error);
        throw error;
    } finally {
        session.endSession();
    }
};

/**
 * Zmienia rolę członka w grupie
 *
 * @param {string} groupId - ID grupy
 * @param {string} adminId - ID administratora zmieniającego rolę
 * @param {string} memberId - ID członka, którego rola ma być zmieniona
 * @param {string} newRole - Nowa rola (admin/member)
 * @returns {Promise<Object>} - Zaktualizowana grupa
 */
exports.updateMemberRole = async (groupId, adminId, memberId, newRole) => {
    try {
        // Sprawdź, czy rola jest poprawna
        if (newRole !== 'admin' && newRole !== 'member') {
            throw new Error('Rola musi być jedną z: admin, member');
        }

        // Pobierz grupę
        const group = await Group.findById(groupId);
        if (!group) {
            throw new Error('Grupa nie została znaleziona');
        }

        // Sprawdź, czy użytkownik jest administratorem grupy
        const isAdmin = group.members.some(
            member => member.user.toString() === adminId.toString() && member.role === 'admin'
        );

        if (!isAdmin) {
            throw new Error('Brak uprawnień do zmiany roli');
        }

        // Znajdź członka, którego rola ma być zmieniona
        const memberIndex = group.members.findIndex(
            member => member.user.toString() === memberId.toString()
        );

        if (memberIndex === -1) {
            throw new Error('Członek nie został znaleziony w grupie');
        }

        // Jeśli zmieniamy rolę z admin na member, upewnij się, że nie jest to ostatni admin
        if (group.members[memberIndex].role === 'admin' && newRole === 'member') {
            const adminCount = group.members.filter(member => member.role === 'admin').length;

            if (adminCount === 1) {
                throw new Error('Nie można zmienić roli ostatniego administratora');
            }
        }

        // Zaktualizuj rolę członka
        group.members[memberIndex].role = newRole;

        // Zapisz zaktualizowaną grupę
        await group.save();

        // Pobierz zaktualizowaną grupę z populacją
        const updatedGroup = await Group.findById(groupId)
            .populate('members.user', 'firstName lastName email avatar');

        return updatedGroup;
    } catch (error) {
        console.error(`Błąd podczas aktualizacji roli członka ${memberId} w grupie ${groupId}:`, error);
        throw error;
    }
};

/**
 * Zmienia status archiwizacji grupy
 *
 * @param {string} groupId - ID grupy
 * @param {string} adminId - ID administratora
 * @param {boolean} archive - Czy grupa ma być zarchiwizowana
 * @returns {Promise<Object>} - Zaktualizowana grupa
 */
exports.toggleArchiveGroup = async (groupId, adminId, archive) => {
    try {
        // Pobierz grupę
        const group = await Group.findById(groupId);
        if (!group) {
            throw new Error('Grupa nie została znaleziona');
        }

        // Sprawdź, czy użytkownik jest administratorem grupy
        const isAdmin = group.members.some(
            member => member.user.toString() === adminId.toString() && member.role === 'admin'
        );

        if (!isAdmin) {
            throw new Error('Brak uprawnień do archiwizacji grupy');
        }

        // Zaktualizuj status archiwizacji
        group.isArchived = archive;

        // Zapisz zaktualizowaną grupę
        await group.save();

        return group;
    } catch (error) {
        console.error(`Błąd podczas zmiany statusu archiwizacji grupy ${groupId}:`, error);
        throw error;
    }
};

/**
 * Usuwa grupę
 *
 * @param {string} groupId - ID grupy
 * @param {string} adminId - ID administratora
 * @returns {Promise<boolean>} - Sukces operacji
 */
exports.deleteGroup = async (groupId, adminId) => {
    const session = await mongoose.startSession();
    session.startTransaction();

    try {
        // Pobierz grupę
        const group = await Group.findById(groupId).session(session);
        if (!group) {
            throw new Error('Grupa nie została znaleziona');
        }

        // Sprawdź, czy użytkownik jest administratorem grupy
        const isAdmin = group.members.some(
            member => member.user.toString() === adminId.toString() && member.role === 'admin'
        );

        if (!isAdmin) {
            throw new Error('Brak uprawnień do usunięcia grupy');
        }

        // Usuń wszystkie wydatki związane z grupą
        await Expense.deleteMany({ group: groupId }).session(session);

        // Usuń wszystkie rozliczenia związane z grupą
        await Settlement.deleteMany({ group: groupId }).session(session);

        // Usuń grupę
        await Group.findByIdAndDelete(groupId).session(session);

        await session.commitTransaction();
        return true;
    } catch (error) {
        await session.abortTransaction();
        console.error(`Błąd podczas usuwania grupy ${groupId}:`, error);
        throw error;
    } finally {
        session.endSession();
    }
};

/**
 * Pobiera statystyki grupy
 *
 * @param {string} groupId - ID grupy
 * @param {string} userId - ID użytkownika (do weryfikacji uprawnień)
 * @returns {Promise<Object>} - Statystyki grupy
 */
exports.getGroupStatistics = async (groupId, userId) => {
    try {
        // Pobierz grupę
        const group = await Group.findById(groupId);
        if (!group) {
            throw new Error('Grupa nie została znaleziona');
        }

        // Sprawdź, czy użytkownik jest członkiem grupy
        const isMember = group.members.some(
            member => member.user.toString() === userId.toString()
        );

        if (!isMember) {
            throw new Error('Brak dostępu do tej grupy');
        }

        // Pobierz wszystkie wydatki w grupie
        const expenses = await Expense.find({ group: groupId });

        // Przygotuj statystyki
        const totalExpenses = expenses.length;
        const totalAmount = expenses.reduce((sum, expense) => sum + expense.amount, 0);

        // Oblicz wydatki według kategorii
        const expensesByCategory = {};
        expenses.forEach(expense => {
            if (!expensesByCategory[expense.category]) {
                expensesByCategory[expense.category] = 0;
            }
            expensesByCategory[expense.category] += expense.amount;
        });

        // Oblicz wydatki według użytkownika
        const expensesByUser = {};
        expenses.forEach(expense => {
            const paidBy = expense.paidBy.toString();
            if (!expensesByUser[paidBy]) {
                expensesByUser[paidBy] = 0;
            }
            expensesByUser[paidBy] += expense.amount;
        });

        // Oblicz wydatki po miesiącach
        const expensesByMonth = {};
        expenses.forEach(expense => {
            const date = new Date(expense.date);
            const monthKey = `${date.getFullYear()}-${(date.getMonth() + 1).toString().padStart(2, '0')}`;

            if (!expensesByMonth[monthKey]) {
                expensesByMonth[monthKey] = 0;
            }
            expensesByMonth[monthKey] += expense.amount;
        });

        // Zwróć statystyki
        return {
            totalExpenses,
            totalAmount,
            currency: group.defaultCurrency,
            expensesByCategory,
            expensesByUser,
            expensesByMonth
        };
    } catch (error) {
        console.error(`Błąd podczas pobierania statystyk grupy ${groupId}:`, error);
        throw error;
    }
};

/**
 * Sprawdza, czy użytkownik jest członkiem grupy
 *
 * @param {string} groupId - ID grupy
 * @param {string} userId - ID użytkownika
 * @returns {Promise<boolean>} - Czy użytkownik jest członkiem grupy
 */
exports.isGroupMember = async (groupId, userId) => {
    try {
        const group = await Group.findById(groupId);

        if (!group) {
            return false;
        }

        // Upewnij się, że porównujemy stringi
        return group.members.some(member => member.user.toString() === userId.toString());
    } catch (error) {
        console.error(`Błąd podczas sprawdzania członkostwa użytkownika ${userId} w grupie ${groupId}:`, error);
        return false;
    }
};

/**
 * Sprawdza, czy użytkownik jest administratorem grupy
 *
 * @param {string} groupId - ID grupy
 * @param {string} userId - ID użytkownika
 * @returns {Promise<boolean>} - Czy użytkownik jest administratorem grupy
 */
exports.isGroupAdmin = async (groupId, userId) => {
    try {
        const group = await Group.findById(groupId);

        if (!group) {
            return false;
        }

        // Spójne porównywanie za pomocą stringów
        return group.members.some(
            member => member.user.toString() === userId.toString() && member.role === 'admin'
        );
    } catch (error) {
        console.error(`Błąd podczas sprawdzania uprawnień administratora dla użytkownika ${userId} w grupie ${groupId}:`, error);
        return false;
    }
};

/**
 * Znajduje grupy na podstawie tekstu wyszukiwania
 *
 * @param {string} userId - ID użytkownika wykonującego wyszukiwanie
 * @param {string} searchText - Tekst wyszukiwania
 * @returns {Promise<Array>} - Znalezione grupy
 */
exports.searchUserGroups = async (userId, searchText) => {
    try {
        const searchRegex = new RegExp(searchText, 'i');

        // Znajdź grupy, do których należy użytkownik i które odpowiadają kryteriom wyszukiwania
        const groups = await Group.find({
            'members.user': userId,
            $or: [
                { name: searchRegex },
                { description: searchRegex }
            ]
        })
            .populate('members.user', 'firstName lastName email avatar')
            .sort({ updatedAt: -1 });

        return groups;
    } catch (error) {
        console.error(`Błąd podczas wyszukiwania grup dla użytkownika ${userId}:`, error);
        throw error;
    }
};