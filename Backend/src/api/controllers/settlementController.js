const Settlement = require('../../models/Settlement');
const Expense = require('../../models/Expense');
const Group = require('../../models/Group');
const User = require('../../models/User');
const settlementService = require('../services/settlementService');
const { sendNotification } = require('../../utils/notifications');

/**
 * @desc    Pobieranie sald grupy
 * @route   GET /api/groups/:groupId/balances
 * @access  Private (tylko członkowie grupy)
 */
exports.getGroupBalances = async (req, res, next) => {
    try {
        const { groupId } = req.params;

        // Sprawdź, czy grupa istnieje
        const group = await Group.findById(groupId);
        if (!group) {
            return res.status(404).json({
                success: false,
                message: 'Grupa nie została znaleziona'
            });
        }

        // Sprawdź, czy użytkownik jest członkiem grupy
        const isMember = group.members.some(
            member => member.user.toString() === req.user._id.toString()
        );

        if (!isMember) {
            return res.status(403).json({
                success: false,
                message: 'Nie jesteś członkiem tej grupy'
            });
        }

        // Pobierz salda i propozycje rozliczeń
        const settlements = await settlementService.getSettlementsByGroup(groupId);

        // Pobierz uzupełnione dane o użytkownikach
        const populatedSettlements = await Settlement.find({
            _id: { $in: settlements.map(s => s._id) }
        })
            .populate('payer', 'firstName lastName email avatar')
            .populate('receiver', 'firstName lastName email avatar');

        // Rozdziel na rozliczenia dotyczące użytkownika i pozostałe
        const userSettlements = populatedSettlements.filter(
            s => s.payer._id.toString() === req.user._id.toString() ||
                s.receiver._id.toString() === req.user._id.toString()
        );

        const otherSettlements = populatedSettlements.filter(
            s => s.payer._id.toString() !== req.user._id.toString() &&
                s.receiver._id.toString() !== req.user._id.toString()
        );

        res.json({
            success: true,
            userSettlements,
            otherSettlements,
            totalSettlements: populatedSettlements.length
        });
    } catch (error) {
        next(error);
    }
};

/**
 * @desc    Aktualizacja sald grupy
 * @route   POST /api/groups/:groupId/balances/refresh
 * @access  Private (tylko członkowie grupy)
 */
exports.refreshGroupBalances = async (req, res, next) => {
    try {
        const { groupId } = req.params;

        // Sprawdź, czy grupa istnieje
        const group = await Group.findById(groupId);
        if (!group) {
            return res.status(404).json({
                success: false,
                message: 'Grupa nie została znaleziona'
            });
        }

        // Sprawdź, czy użytkownik jest członkiem grupy
        const isMember = group.members.some(
            member => member.user.toString() === req.user._id.toString()
        );

        if (!isMember) {
            return res.status(403).json({
                success: false,
                message: 'Nie jesteś członkiem tej grupy'
            });
        }

        // Aktualizuj salda i propozycje rozliczeń
        await settlementService.updateBalances(groupId);

        // Pobierz zaktualizowane salda
        const settlements = await settlementService.getSettlementsByGroup(groupId);

        // Pobierz uzupełnione dane o użytkownikach
        const populatedSettlements = await Settlement.find({
            _id: { $in: settlements.map(s => s._id) }
        })
            .populate('payer', 'firstName lastName email avatar')
            .populate('receiver', 'firstName lastName email avatar');

        // Rozdziel na rozliczenia dotyczące użytkownika i pozostałe
        const userSettlements = populatedSettlements.filter(
            s => s.payer._id.toString() === req.user._id.toString() ||
                s.receiver._id.toString() === req.user._id.toString()
        );

        const otherSettlements = populatedSettlements.filter(
            s => s.payer._id.toString() !== req.user._id.toString() &&
                s.receiver._id.toString() !== req.user._id.toString()
        );

        res.json({
            success: true,
            message: 'Salda zaktualizowane pomyślnie',
            userSettlements,
            otherSettlements,
            totalSettlements: populatedSettlements.length
        });
    } catch (error) {
        next(error);
    }
};

/**
 * @desc    Pobieranie szczegółów rozliczenia
 * @route   GET /api/settlements/:id
 * @access  Private (tylko płatnik lub odbiorca)
 */
exports.getSettlementDetails = async (req, res, next) => {
    try {
        const { id } = req.params;

        // Pobierz rozliczenie z bazy danych
        const settlement = await Settlement.findById(id)
            .populate('payer', 'firstName lastName email avatar')
            .populate('receiver', 'firstName lastName email avatar')
            .populate('relatedExpenses');

        if (!settlement) {
            return res.status(404).json({
                success: false,
                message: 'Rozliczenie nie zostało znalezione'
            });
        }

        // Sprawdź, czy użytkownik jest płatnikiem lub odbiorcą
        const isPayerOrReceiver = (
            settlement.payer._id.toString() === req.user._id.toString() ||
            settlement.receiver._id.toString() === req.user._id.toString()
        );

        if (!isPayerOrReceiver) {
            return res.status(403).json({
                success: false,
                message: 'Nie masz dostępu do tego rozliczenia'
            });
        }

        res.json({
            success: true,
            settlement
        });
    } catch (error) {
        next(error);
    }
};

/**
 * @desc    Oznaczenie rozliczenia jako zakończone
 * @route   POST /api/settlements/:id/settle
 * @access  Private (tylko płatnik)
 */
exports.settleDebt = async (req, res, next) => {
    try {
        const { id } = req.params;
        const { paymentMethod, paymentReference } = req.body;

        // Pobierz rozliczenie z bazy danych
        const settlement = await Settlement.findById(id);

        if (!settlement) {
            return res.status(404).json({
                success: false,
                message: 'Rozliczenie nie zostało znalezione'
            });
        }

        // Sprawdź, czy użytkownik jest płatnikiem
        if (settlement.payer.toString() !== req.user._id.toString()) {
            return res.status(403).json({
                success: false,
                message: 'Tylko płatnik może oznaczyć dług jako spłacony'
            });
        }

        // Sprawdź, czy rozliczenie nie jest już zakończone
        if (settlement.status === 'completed') {
            return res.status(400).json({
                success: false,
                message: 'To rozliczenie zostało już zakończone'
            });
        }

        // Zaktualizuj rozliczenie
        const updatedSettlement = await settlementService.settleDebt(
            id,
            req.user._id.toString(),
            paymentMethod,
            paymentReference
        );

        // Powiadom odbiorcę o spłacie
        const receiver = await User.findById(settlement.receiver);
        if (receiver && receiver.notificationSettings.settlementRequest) {
            await sendNotification(
                receiver._id,
                'Dług został spłacony',
                `${req.user.firstName} spłacił Ci dług w wysokości ${settlement.amount} ${settlement.currency}`,
                {
                    type: 'DEBT_SETTLED',
                    settlementId: settlement._id,
                    groupId: settlement.group
                }
            );
        }

        // Pobierz zaktualizowane rozliczenie z danymi użytkowników
        const populatedSettlement = await Settlement.findById(id)
            .populate('payer', 'firstName lastName email avatar')
            .populate('receiver', 'firstName lastName email avatar');

        res.json({
            success: true,
            message: 'Dług oznaczony jako spłacony',
            settlement: populatedSettlement
        });
    } catch (error) {
        next(error);
    }
};

/**
 * @desc    Pobieranie historii rozliczeń użytkownika
 * @route   GET /api/settlements/history
 * @access  Private
 */
exports.getSettlementHistory = async (req, res, next) => {
    try {
        const { page = 1, limit = 20 } = req.query;

        // Pobierz historię rozliczeń użytkownika
        const options = {
            page: parseInt(page, 10),
            limit: parseInt(limit, 10),
            sort: { settledAt: -1 },
            populate: [
                { path: 'payer', select: 'firstName lastName email avatar' },
                { path: 'receiver', select: 'firstName lastName email avatar' },
                { path: 'group', select: 'name' }
            ]
        };

        const filter = {
            $or: [
                { payer: req.user._id },
                { receiver: req.user._id }
            ],
            status: 'completed'
        };

        const settlements = await settlementService.getPaginatedSettlements(filter, options);

        res.json({
            success: true,
            settlements: settlements.docs,
            pagination: {
                totalDocs: settlements.totalDocs,
                limit: settlements.limit,
                totalPages: settlements.totalPages,
                page: settlements.page,
                hasPrevPage: settlements.hasPrevPage,
                hasNextPage: settlements.hasNextPage,
                prevPage: settlements.prevPage,
                nextPage: settlements.nextPage
            }
        });
    } catch (error) {
        next(error);
    }
    /**
     * @desc    Pobieranie bilansów grupy z sugestiami rozliczeń
     * @route   GET /api/groups/:groupId/balances
     * @access  Private (tylko członkowie grupy)
     */
    exports.getGroupBalances = async (req, res, next) => {
        try {
            const { groupId } = req.params;

            // Sprawdź, czy grupa istnieje i użytkownik jest członkiem
            const group = await Group.findById(groupId);
            if (!group) {
                return res.status(404).json({
                    success: false,
                    message: 'Grupa nie została znaleziona'
                });
            }

            const isMember = group.members.some(
                member => member.user.toString() === req.user._id.toString()
            );

            if (!isMember) {
                return res.status(403).json({
                    success: false,
                    message: 'Nie jesteś członkiem tej grupy'
                });
            }

            // Pobierz wszystkie wydatki w grupie
            const expenses = await Expense.find({ group: groupId })
                .populate('paidBy', 'firstName lastName email')
                .populate('splits.user', 'firstName lastName email');

            // Oblicz bilanse użytkowników
            const userBalances = {};

            // Inicjalizuj bilanse wszystkich członków
            group.members.forEach(member => {
                userBalances[member.user.toString()] = {
                    id: member.user.toString(),
                    firstName: '', // Będzie wypełnione później
                    lastName: '',
                    email: '',
                    balance: 0
                };
            });

            // Oblicz bilanse na podstawie wydatków
            expenses.forEach(expense => {
                const paidById = expense.paidBy._id.toString();

                // Dodaj całą kwotę do salda płatnika
                if (userBalances[paidById]) {
                    userBalances[paidById].balance += expense.amount;
                }

                // Odejmij kwoty od osób w podziale
                expense.splits.forEach(split => {
                    const userId = split.user._id.toString();
                    if (userBalances[userId]) {
                        userBalances[userId].balance -= split.amount;
                    }
                });
            });

            // Wypełnij dane użytkowników
            const populatedUsers = await User.find({
                _id: { $in: Object.keys(userBalances) }
            }).select('firstName lastName email');

            populatedUsers.forEach(user => {
                const userId = user._id.toString();
                if (userBalances[userId]) {
                    userBalances[userId].firstName = user.firstName;
                    userBalances[userId].lastName = user.lastName;
                    userBalances[userId].email = user.email;
                }
            });

            // Generuj sugestie rozliczeń (algorytm upraszczania długów)
            const settlementSuggestions = [];
            const balanceArray = Object.values(userBalances);

            // Znajdź dłużników i wierzycieli
            const debtors = balanceArray.filter(user => user.balance < -0.01);
            const creditors = balanceArray.filter(user => user.balance > 0.01);

            // Prosty algorytm dopasowywania
            debtors.forEach(debtor => {
                creditors.forEach(creditor => {
                    if (Math.abs(debtor.balance) > 0.01 && creditor.balance > 0.01) {
                        const amount = Math.min(Math.abs(debtor.balance), creditor.balance);

                        settlementSuggestions.push({
                            fromUser: {
                                id: debtor.id,
                                firstName: debtor.firstName,
                                lastName: debtor.lastName,
                                email: debtor.email
                            },
                            toUser: {
                                id: creditor.id,
                                firstName: creditor.firstName,
                                lastName: creditor.lastName,
                                email: creditor.email
                            },
                            amount: Math.round(amount * 100) / 100
                        });

                        debtor.balance += amount;
                        creditor.balance -= amount;
                    }
                });
            });

            res.json({
                success: true,
                balances: Object.values(userBalances),
                currency: group.defaultCurrency,
                settlementSuggestions
            });

        } catch (error) {
            next(error);
        }
    };


};
/**
 * @desc    Pobieranie oczekujących rozliczeń użytkownika
 * @route   GET /api/settlements/pending
 * @access  Private
 */
exports.getPendingSettlements = async (req, res, next) => {
    try {
        const { page = 1, limit = 20 } = req.query;

        const options = {
            page: parseInt(page, 10),
            limit: parseInt(limit, 10)
        };

        const settlements = await settlementService.getPendingSettlements(req.user._id, options);

        res.json({
            success: true,
            settlements: settlements.docs,
            pagination: {
                totalDocs: settlements.totalDocs,
                limit: settlements.limit,
                totalPages: settlements.totalPages,
                page: settlements.page,
                hasPrevPage: settlements.hasPrevPage,
                hasNextPage: settlements.hasNextPage,
                prevPage: settlements.prevPage,
                nextPage: settlements.nextPage
            }
        });
    } catch (error) {
        next(error);
    }
};

/**
 * @desc    Pobieranie zakończonych rozliczeń użytkownika
 * @route   GET /api/settlements/completed
 * @access  Private
 */
exports.getCompletedSettlements = async (req, res, next) => {
    try {
        const { page = 1, limit = 20 } = req.query;

        const options = {
            page: parseInt(page, 10),
            limit: parseInt(limit, 10)
        };

        const settlements = await settlementService.getCompletedSettlements(req.user._id, options);

        res.json({
            success: true,
            settlements: settlements.docs,
            pagination: {
                totalDocs: settlements.totalDocs,
                limit: settlements.limit,
                totalPages: settlements.totalPages,
                page: settlements.page,
                hasPrevPage: settlements.hasPrevPage,
                hasNextPage: settlements.hasNextPage,
                prevPage: settlements.prevPage,
                nextPage: settlements.nextPage
            }
        });
    } catch (error) {
        next(error);
    }
};

/**
 * @desc    Pobieranie wszystkich rozliczeń użytkownika
 * @route   GET /api/settlements
 * @access  Private
 */
exports.getAllUserSettlements = async (req, res, next) => {
    try {
        const { page = 1, limit = 20 } = req.query;

        const options = {
            page: parseInt(page, 10),
            limit: parseInt(limit, 10)
        };

        const settlements = await settlementService.getAllUserSettlements(req.user._id, options);

        res.json({
            success: true,
            settlements: settlements.docs,
            pagination: {
                totalDocs: settlements.totalDocs,
                limit: settlements.limit,
                totalPages: settlements.totalPages,
                page: settlements.page,
                hasPrevPage: settlements.hasPrevPage,
                hasNextPage: settlements.hasNextPage,
                prevPage: settlements.prevPage,
                nextPage: settlements.nextPage
            }
        });
    } catch (error) {
        next(error);
    }
};

/**
 * @desc    Tworzenie nowego rozliczenia
 * @route   POST /api/settlements
 * @access  Private
 */
exports.createSettlement = async (req, res, next) => {
    try {
        const { groupId, toUserId, amount, currency, paymentMethod, paymentReference } = req.body;

        // Sprawdź, czy grupa istnieje i użytkownik jest członkiem
        const group = await Group.findById(groupId);
        if (!group) {
            return res.status(404).json({
                success: false,
                message: 'Grupa nie została znaleziona'
            });
        }

        const isMember = group.members.some(
            member => member.user.toString() === req.user._id.toString()
        );

        if (!isMember) {
            return res.status(403).json({
                success: false,
                message: 'Nie jesteś członkiem tej grupy'
            });
        }

        // Sprawdź, czy odbiorca jest członkiem grupy
        const isReceiverMember = group.members.some(
            member => member.user.toString() === toUserId
        );

        if (!isReceiverMember) {
            return res.status(400).json({
                success: false,
                message: 'Odbiorca musi być członkiem grupy'
            });
        }

        // Utwórz nowe rozliczenie
        const settlement = new Settlement({
            group: groupId,
            payer: req.user._id,
            receiver: toUserId,
            amount,
            currency: currency || group.defaultCurrency,
            status: 'pending',
            paymentMethod: paymentMethod || 'manual',
            paymentReference
        });

        await settlement.save();

        // Pobierz rozliczenie z populacją
        const populatedSettlement = await Settlement.findById(settlement._id)
            .populate('payer', 'firstName lastName email')
            .populate('receiver', 'firstName lastName email')
            .populate('group', 'name');

        res.status(201).json({
            success: true,
            message: 'Rozliczenie utworzone pomyślnie',
            settlement: populatedSettlement
        });

    } catch (error) {
        next(error);
    }
};