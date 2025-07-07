const Expense = require('../../models/Expense');
const Group = require('../../models/Group');
const mongoose = require('mongoose');

/**
 * Pobiera listę wydatków z paginacją i filtrowaniem
 *
 * @param {Object} filter - Obiekt filtru
 * @param {Object} options - Opcje paginacji i sortowania
 * @returns {Promise<Object>} - Obiekt z wydatkami i informacjami o paginacji
 */
exports.getExpenses = async (filter, options) => {
    try {
        // Obsługa paginacji
        const page = options.page || 1;
        const limit = options.limit || 20;
        const skip = (page - 1) * limit;

        // Obsługa sortowania
        const sort = options.sort || { date: -1 };

        // Przygotuj zapytanie
        const query = Expense.find(filter)
            .sort(sort)
            .skip(skip)
            .limit(limit);

        // Obsługa populacji (jeśli podano)
        if (options.populate) {
            options.populate.forEach(populateOption => {
                query.populate(populateOption);
            });
        }

        // Wykonaj zapytanie
        const expenses = await query.exec();

        // Pobierz całkowitą liczbę dokumentów
        const totalDocs = await Expense.countDocuments(filter);

        // Przygotuj obiekt odpowiedzi w formacie podobnym do mongoose-paginate-v2
        const result = {
            docs: expenses,
            totalDocs,
            limit,
            page,
            totalPages: Math.ceil(totalDocs / limit),
            hasPrevPage: page > 1,
            hasNextPage: page < Math.ceil(totalDocs / limit),
            prevPage: page > 1 ? page - 1 : null,
            nextPage: page < Math.ceil(totalDocs / limit) ? page + 1 : null
        };

        return result;
    } catch (error) {
        console.error('Błąd podczas pobierania wydatków:', error);
        throw error;
    }
};

/**
 * Pobiera szczegóły wydatku po ID
 *
 * @param {string} expenseId - ID wydatku
 * @returns {Promise<Object>} - Obiekt wydatku
 */
exports.getExpenseById = async (expenseId) => {
    try {
        const expense = await Expense.findById(expenseId)
            .populate('paidBy', 'firstName lastName email avatar')
            .populate('splits.user', 'firstName lastName email avatar')
            .populate('comments.user', 'firstName lastName email avatar');

        return expense;
    } catch (error) {
        console.error(`Błąd podczas pobierania wydatku o ID ${expenseId}:`, error);
        throw error;
    }
};

/**
 * Tworzy nowy wydatek
 *
 * @param {Object} expenseData - Dane nowego wydatku
 * @returns {Promise<Object>} - Utworzony wydatek
 */
exports.createExpense = async (expenseData) => {
    const session = await mongoose.startSession();
    session.startTransaction();

    try {
        // Utworzenie nowego wydatku
        const expense = new Expense(expenseData);
        await expense.save({ session });

        // Pobierz zapisany wydatek z populacją
        const populatedExpense = await Expense.findById(expense._id)
            .populate('paidBy', 'firstName lastName email avatar')
            .populate('splits.user', 'firstName lastName email avatar')
            .session(session);

        await session.commitTransaction();
        return populatedExpense;
    } catch (error) {
        await session.abortTransaction();
        console.error('Błąd podczas tworzenia wydatku:', error);
        throw error;
    } finally {
        session.endSession();
    }
};

/**
 * Aktualizuje istniejący wydatek
 *
 * @param {string} expenseId - ID wydatku do aktualizacji
 * @param {Object} updateData - Dane do aktualizacji
 * @returns {Promise<Object>} - Zaktualizowany wydatek
 */
exports.updateExpense = async (expenseId, updateData) => {
    try {
        const updatedExpense = await Expense.findByIdAndUpdate(
            expenseId,
            updateData,
            { new: true, runValidators: true }
        )
            .populate('paidBy', 'firstName lastName email avatar')
            .populate('splits.user', 'firstName lastName email avatar');

        return updatedExpense;
    } catch (error) {
        console.error(`Błąd podczas aktualizacji wydatku o ID ${expenseId}:`, error);
        throw error;
    }
};

/**
 * Usuwa wydatek
 *
 * @param {string} expenseId - ID wydatku do usunięcia
 * @returns {Promise<boolean>} - Informacja o sukcesie
 */
exports.deleteExpense = async (expenseId) => {
    try {
        const result = await Expense.findByIdAndDelete(expenseId);
        return !!result;
    } catch (error) {
        console.error(`Błąd podczas usuwania wydatku o ID ${expenseId}:`, error);
        throw error;
    }
};

/**
 * Dodaje komentarz do wydatku
 *
 * @param {string} expenseId - ID wydatku
 * @param {string} userId - ID użytkownika dodającego komentarz
 * @param {string} text - Treść komentarza
 * @returns {Promise<Object>} - Zaktualizowany wydatek
 */
exports.addComment = async (expenseId, userId, text) => {
    try {
        const expense = await Expense.findById(expenseId);

        if (!expense) {
            throw new Error('Wydatek nie został znaleziony');
        }

        // Dodaj komentarz
        expense.comments.push({
            user: userId,
            text,
            createdAt: new Date()
        });

        await expense.save();

        // Pobierz zaktualizowany wydatek z populacją
        const updatedExpense = await Expense.findById(expenseId)
            .populate('comments.user', 'firstName lastName email avatar');

        return updatedExpense;
    } catch (error) {
        console.error(`Błąd podczas dodawania komentarza do wydatku o ID ${expenseId}:`, error);
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
exports.checkGroupMembership = async (groupId, userId) => {
    try {
        const group = await Group.findById(groupId);

        if (!group) {
            return false;
        }

        return group.members.some(member => member.user.toString() === userId);
    } catch (error) {
        console.error(`Błąd podczas sprawdzania członkostwa w grupie ${groupId} dla użytkownika ${userId}:`, error);
        throw error;
    }
};

/**
 * Sprawdza, czy użytkownik może edytować wydatek
 *
 * @param {string} expenseId - ID wydatku
 * @param {string} userId - ID użytkownika
 * @returns {Promise<boolean>} - Czy użytkownik może edytować wydatek
 */
exports.canUserEditExpense = async (expenseId, userId) => {
    try {
        const expense = await Expense.findById(expenseId);

        if (!expense) {
            return false;
        }

        // Użytkownik może edytować wydatek, jeśli jest jego twórcą
        if (expense.paidBy.toString() === userId) {
            return true;
        }

        // Lub jeśli jest administratorem grupy
        const group = await Group.findById(expense.group);

        if (!group) {
            return false;
        }

        const member = group.members.find(m => m.user.toString() === userId);
        return member && member.role === 'admin';
    } catch (error) {
        console.error(`Błąd podczas sprawdzania uprawnień do edycji wydatku ${expenseId}:`, error);
        throw error;
    }
};

/**
 * Sprawdza, czy użytkownik może usunąć wydatek
 *
 * @param {string} expenseId - ID wydatku
 * @param {string} userId - ID użytkownika
 * @returns {Promise<boolean>} - Czy użytkownik może usunąć wydatek
 */
exports.canUserDeleteExpense = async (expenseId, userId) => {
    // W tej implementacji, warunki usuwania są takie same jak dla edycji
    return this.canUserEditExpense(expenseId, userId);
};

/**
 * Pobiera wydatki dla danej grupy
 *
 * @param {string} groupId - ID grupy
 * @param {number} page - Numer strony
 * @param {number} limit - Limit wyników na stronę
 * @param {string} sortBy - Pole do sortowania
 * @param {string} order - Kierunek sortowania (asc/desc)
 * @returns {Promise<Object>} - Obiekt z wydatkami i informacjami o paginacji
 */
exports.getExpensesByGroup = async (groupId, page = 1, limit = 20, sortBy = 'date', order = 'desc') => {
    const sort = {};
    sort[sortBy] = order === 'desc' ? -1 : 1;

    const options = {
        page,
        limit,
        sort,
        populate: [
            { path: 'paidBy', select: 'firstName lastName email avatar' },
            { path: 'splits.user', select: 'firstName lastName email avatar' }
        ]
    };

    return this.getExpenses({ group: groupId }, options);
};

/**
 * Wysyła powiadomienia o nowym wydatku do członków grupy
 *
 * @param {string} groupId - ID grupy
 * @param {Object} expense - Obiekt wydatku
 * @param {string} creatorId - ID twórcy wydatku
 * @returns {Promise<void>}
 */
exports.notifyGroupMembers = async (groupId, expense, creatorId) => {
    try {
        // Ta funkcja będzie implementowana w rzeczywistej aplikacji
        // z wykorzystaniem systemu powiadomień

        // Pusta implementacja dla uproszczenia
        console.log(`Powiadomienia o wydatku ${expense._id} w grupie ${groupId} wysłane do członków`);
    } catch (error) {
        console.error(`Błąd podczas wysyłania powiadomień o wydatku:`, error);
        // Nie rzucamy błędu, żeby nie przerywać głównej operacji
    }
};