const Expense = require('../../models/Expense');
const Group = require('../../models/Group');
const Settlement = require('../../models/Settlement');
const mongoose = require('mongoose');
const { simplifyDebts, calculateBalancesFromExpenses } = require('../../utils/debtSimplifier');

/**
 * Pobiera wszystkie aktywne rozliczenia dla grupy
 *
 * @param {string} groupId - ID grupy
 * @returns {Promise<Array>} Tablica rozliczeń
 */
exports.getGroupBalances = async (groupId) => {
    try {
        return await Settlement.find({
            group: groupId,
            status: 'pending'
        })
            .populate('payer', 'firstName lastName email avatar')
            .populate('receiver', 'firstName lastName email avatar');
    } catch (error) {
        console.error(`Błąd podczas pobierania sald grupy ${groupId}:`, error);
        throw error;
    }
};

/**
 * Pobiera wszystkie aktywne rozliczenia dla grupy
 *
 * @param {string} groupId - ID grupy
 * @returns {Promise<Array>} Tablica rozliczeń
 */
exports.getSettlementsByGroup = async (groupId) => {
    try {
        return await Settlement.find({
            group: groupId,
            status: 'pending'
        });
    } catch (error) {
        console.error('Błąd podczas pobierania rozliczeń:', error);
        throw error;
    }
};

/**
 * Pobiera rozliczenia z paginacją, filtrem i sortowaniem
 *
 * @param {Object} filter - Obiekt filtrujący zapytanie
 * @param {Object} options - Opcje zapytania (pagination, sort, populate)
 * @returns {Promise<Object>} Obiekt z paginacją i danymi
 */
exports.getPaginatedSettlements = async (filter, options) => {
    try {
        // Default pagination values
        const page = options.page || 1;
        const limit = options.limit || 20;
        const skip = (page - 1) * limit;

        // Handle sorting
        const sort = options.sort || {};

        // Build the query
        let query = Settlement.find(filter)
            .sort(sort)
            .skip(skip)
            .limit(limit);

        // Handle population
        if (options.populate) {
            options.populate.forEach(path => {
                query = query.populate(path);
            });
        }

        // Execute the query
        const docs = await query.exec();
        const totalDocs = await Settlement.countDocuments(filter);

        // Create pagination structure similar to mongoose-paginate-v2
        return {
            docs,
            totalDocs,
            limit,
            page,
            totalPages: Math.ceil(totalDocs / limit),
            hasPrevPage: page > 1,
            hasNextPage: page < Math.ceil(totalDocs / limit),
            prevPage: page > 1 ? page - 1 : null,
            nextPage: page < Math.ceil(totalDocs / limit) ? page + 1 : null
        };
    } catch (error) {
        console.error('Błąd podczas pobierania rozliczeń z paginacją:', error);
        throw error;
    }
};


/**
 * Aktualizuje salda użytkowników i tworzy propozycje rozliczeń dla grupy
 *
 * @param {string} groupId - ID grupy
 * @returns {Promise<Array>} Tablica propozycji rozliczeń
 */
exports.updateBalances = async (groupId) => {
    const session = await mongoose.startSession();
    session.startTransaction();

    try {
        // Pobierz wszystkie wydatki w grupie - KLUCZOWE: upewnij się, że otrzymujesz całe obiekty
        const expenses = await Expense.find({ group: groupId })
            .populate('splits.user')
            .populate('paidBy');

        // Pobierz informacje o grupie
        const group = await Group.findById(groupId);

        if (!group) {
            throw new Error('Grupa nie istnieje');
        }

        // Oblicz salda na podstawie wydatków - ta funkcja zwraca mapę ID -> saldo
        const balances = calculateBalancesFromExpenses(expenses);

        // Uproszczenie długów - ta funkcja zwraca transakcje z ID użytkowników
        const transactions = simplifyDebts(balances, group.defaultCurrency);

        // Usuń oczekujące propozycje rozliczeń
        await Settlement.deleteMany({
            group: groupId,
            status: 'pending'
        }).session(session);

        // Przygotuj nowe propozycje rozliczeń
        const settlementProposals = transactions.map(transaction => {
            return {
                group: groupId,
                payer: transaction.from,     // To są już stringi ID
                receiver: transaction.to,    // To są już stringi ID
                amount: transaction.amount,
                currency: transaction.currency,
                status: 'pending',
                relatedExpenses: []
            };
        });

        // Zapisz nowe propozycje rozliczeń, jeśli jakieś istnieją
        let createdSettlements = [];
        if (settlementProposals.length > 0) {
            createdSettlements = await Settlement.insertMany(
                settlementProposals,
                { session }
            );
        }

        // Przypisz powiązane wydatki do rozliczeń
        for (let settlement of createdSettlements) {
            const relatedExpenses = expenses.filter(expense => {
                // Pobierz ID płatnika (jako string)
                const paidById = expense.paidBy._id ? expense.paidBy._id.toString() : expense.paidBy.toString();

                // Sprawdź, czy płatnik jest jedną ze stron rozliczenia
                const isPaidByInvolved =
                    paidById === settlement.payer.toString() ||
                    paidById === settlement.receiver.toString();

                if (!isPaidByInvolved) return false;

                // Sprawdź, czy któryś z podziałów dotyczy drugiej strony rozliczenia
                return expense.splits.some(split => {
                    const userId = split.user._id ? split.user._id.toString() : split.user.toString();
                    return (
                        (userId === settlement.payer.toString() && paidById === settlement.receiver.toString()) ||
                        (userId === settlement.receiver.toString() && paidById === settlement.payer.toString())
                    );
                });
            });

            if (relatedExpenses.length > 0) {
                // Dodaj identyfikatory powiązanych wydatków do rozliczenia
                settlement.relatedExpenses = relatedExpenses.map(e => e._id);
                await settlement.save({ session });
            }
        }

        await session.commitTransaction();
        return createdSettlements;
    } catch (error) {
        await session.abortTransaction();
        console.error('Błąd podczas aktualizacji sald:', error);
        throw error;
    } finally {
        session.endSession();
    }
};

/**
 * Oznacza rozliczenie jako zakończone
 *
 * @param {string} settlementId - ID rozliczenia
 * @param {string} userId - ID użytkownika rozliczającego dług
 * @param {string} paymentMethod - Metoda płatności
 * @param {string} paymentReference - Referencja płatności (opcjonalna)
 * @returns {Promise<Object>} Zaktualizowane rozliczenie
 */
exports.settleDebt = async (settlementId, userId, paymentMethod, paymentReference = null) => {
    const session = await mongoose.startSession();
    session.startTransaction();

    try {
        const settlement = await Settlement.findById(settlementId).session(session);

        if (!settlement) {
            throw new Error('Rozliczenie nie istnieje');
        }

        // Sprawdź, czy użytkownik jest płatnikiem
        if (settlement.payer.toString() !== userId) {
            throw new Error('Tylko płatnik może oznaczyć dług jako spłacony');
        }

        // Sprawdź, czy rozliczenie nie jest już zakończone
        if (settlement.status === 'completed') {
            throw new Error('To rozliczenie zostało już zakończone');
        }

        // Aktualizuj status rozliczenia
        settlement.status = 'completed';
        settlement.paymentMethod = paymentMethod;
        if (paymentReference) {
            settlement.paymentReference = paymentReference;
        }
        settlement.settledAt = new Date();

        await settlement.save({ session });

        // Aktualizuj powiązane wydatki
        if (settlement.relatedExpenses && settlement.relatedExpenses.length > 0) {
            for (const expenseId of settlement.relatedExpenses) {
                const expense = await Expense.findById(expenseId);

                if (expense) {
                    // Znajdź podział dotyczący płatnika
                    const splitIndex = expense.splits.findIndex(
                        split => split.user.toString() === settlement.payer.toString()
                    );

                    if (splitIndex >= 0) {
                        expense.splits[splitIndex].settled = true;
                        await expense.save({ session });
                    }
                }
            }
        }

        await session.commitTransaction();

        return settlement;
    } catch (error) {
        await session.abortTransaction();
        console.error('Błąd podczas oznaczania długu jako spłaconego:', error);
        throw error;
    } finally {
        session.endSession();
    }
};

/**
 * Pobiera bilans danego użytkownika we wszystkich grupach
 *
 * @param {string} userId - ID użytkownika
 * @returns {Promise<Object>} Obiekt z bilansami pogrupowanymi według grup
 */
exports.getUserBalanceSummary = async (userId) => {
    try {
        // Pobierz wszystkie aktywne rozliczenia, w których użytkownik jest zaangażowany
        const settlements = await Settlement.find({
            $or: [
                { payer: userId },
                { receiver: userId }
            ],
            status: 'pending'
        }).populate('group', 'name defaultCurrency');

        // Grupuj według grup
        const groupBalances = {};
        let totalBalance = 0;

        settlements.forEach(settlement => {
            const groupId = settlement.group._id.toString();
            const groupName = settlement.group.name;
            const groupCurrency = settlement.group.defaultCurrency;

            if (!groupBalances[groupId]) {
                groupBalances[groupId] = {
                    groupId,
                    groupName,
                    currency: groupCurrency,
                    balance: 0,
                    toPay: 0,
                    toReceive: 0
                };
            }

            // Oblicz bilans dla użytkownika
            if (settlement.payer.toString() === userId.toString()) {
                // Użytkownik jest dłużnikiem
                groupBalances[groupId].balance -= settlement.amount;
                groupBalances[groupId].toPay += settlement.amount;
                totalBalance -= settlement.amount;
            } else {
                // Użytkownik jest wierzycielem
                groupBalances[groupId].balance += settlement.amount;
                groupBalances[groupId].toReceive += settlement.amount;
                totalBalance += settlement.amount;
            }
        });

        return {
            groups: Object.values(groupBalances),
            totalBalance
        };
    } catch (error) {
        console.error('Błąd podczas pobierania podsumowania bilansu użytkownika:', error);
        throw error;
    }
};

/**
 * Pobiera oczekujące rozliczenia użytkownika z paginacją
 *
 * @param {string} userId - ID użytkownika
 * @param {Object} options - Opcje zapytania (pagination, sort, populate)
 * @returns {Promise<Object>} Obiekt z paginacją i danymi
 */
exports.getPendingSettlements = async (userId, options = {}) => {
    try {
        const filter = {
            $or: [
                { payer: userId },
                { receiver: userId }
            ],
            status: 'pending'
        };

        const defaultOptions = {
            ...options,
            populate: options.populate || [
                { path: 'payer', select: 'firstName lastName email avatar' },
                { path: 'receiver', select: 'firstName lastName email avatar' },
                { path: 'group', select: 'name' }
            ],
            sort: options.sort || { createdAt: -1 }
        };

        return await exports.getPaginatedSettlements(filter, defaultOptions);
    } catch (error) {
        console.error('Błąd podczas pobierania oczekujących rozliczeń:', error);
        throw error;
    }
};

/**
 * Pobiera zakończone rozliczenia użytkownika z paginacją
 *
 * @param {string} userId - ID użytkownika
 * @param {Object} options - Opcje zapytania (pagination, sort, populate)
 * @returns {Promise<Object>} Obiekt z paginacją i danymi
 */
exports.getCompletedSettlements = async (userId, options = {}) => {
    try {
        const filter = {
            $or: [
                { payer: userId },
                { receiver: userId }
            ],
            status: 'completed'
        };

        const defaultOptions = {
            ...options,
            populate: options.populate || [
                { path: 'payer', select: 'firstName lastName email avatar' },
                { path: 'receiver', select: 'firstName lastName email avatar' },
                { path: 'group', select: 'name' }
            ],
            sort: options.sort || { settledAt: -1 }
        };

        return await exports.getPaginatedSettlements(filter, defaultOptions);
    } catch (error) {
        console.error('Błąd podczas pobierania zakończonych rozliczeń:', error);
        throw error;
    }
};

/**
 * Pobiera wszystkie rozliczenia użytkownika z paginacją
 *
 * @param {string} userId - ID użytkownika
 * @param {Object} options - Opcje zapytania (pagination, sort, populate)
 * @returns {Promise<Object>} Obiekt z paginacją i danymi
 */
exports.getAllUserSettlements = async (userId, options = {}) => {
    try {
        const filter = {
            $or: [
                { payer: userId },
                { receiver: userId }
            ]
        };

        const defaultOptions = {
            ...options,
            populate: options.populate || [
                { path: 'payer', select: 'firstName lastName email avatar' },
                { path: 'receiver', select: 'firstName lastName email avatar' },
                { path: 'group', select: 'name' }
            ],
            sort: options.sort || { createdAt: -1 }
        };

        return await exports.getPaginatedSettlements(filter, defaultOptions);
    } catch (error) {
        console.error('Błąd podczas pobierania wszystkich rozliczeń użytkownika:', error);
        throw error;
    }
};