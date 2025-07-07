// Importy modeli danych
const User = require('../../models/User');
const Group = require('../../models/Group');
const mongoose = require('mongoose');

/**
 * Wyszukuje użytkowników na podstawie zapytania
 *
 * @param {string} query - Zapytanie (email, imię, nazwisko)
 * @param {string} currentUserId - ID bieżącego użytkownika (do wykluczenia z wyników)
 * @returns {Promise<Array>} - Tablica znalezionych użytkowników
 */
exports.searchUsers = async (query, currentUserId) => {
    try {
        // Utwórz wyrażenie regularne dla wyszukiwania bez uwzględniania wielkości liter
        const searchRegex = new RegExp(query, 'i');

        // Znajdź użytkowników pasujących do zapytania w różnych polach
        const users = await User.find({
            $and: [
                { _id: { $ne: currentUserId } }, // Wyklucz bieżącego użytkownika z wyników
                {
                    $or: [
                        { email: searchRegex },        // Wyszukaj po emailu
                        { firstName: searchRegex },    // Wyszukaj po imieniu
                        { lastName: searchRegex },     // Wyszukaj po nazwisku
                        { phoneNumber: searchRegex }   // Wyszukaj po numerze telefonu
                    ]
                }
            ]
        })
            .select('firstName lastName email avatar') // Pobierz tylko niezbędne pola (bez wrażliwych danych)
            .limit(10); // Ogranicz wyniki do maksymalnie 10 użytkowników

        return users;
    } catch (error) {
        console.error('Błąd podczas wyszukiwania użytkowników:', error);
        throw error;
    }
};

/**
 * Pobiera szczegóły użytkownika
 *
 * @param {string} userId - ID użytkownika
 * @returns {Promise<Object>} - Obiekt użytkownika
 */
exports.getUserById = async (userId) => {
    try {
        // Pobierz użytkownika po ID, wykluczając wrażliwe informacje
        const user = await User.findById(userId)
            .select('-password -refreshToken'); // Usuń hasło i token odświeżania z odpowiedzi

        return user;
    } catch (error) {
        console.error(`Błąd podczas pobierania użytkownika o ID ${userId}:`, error);
        throw error;
    }
};

/**
 * Aktualizuje dane użytkownika
 *
 * @param {string} userId - ID użytkownika
 * @param {Object} updateData - Dane do aktualizacji
 * @returns {Promise<Object>} - Zaktualizowany użytkownik
 */
exports.updateUser = async (userId, updateData) => {
    try {
        // Sprawdź, czy próbujemy zaktualizować email i czy nowy email jest już zajęty
        if (updateData.email) {
            const existingUser = await User.findOne({
                email: updateData.email,
                _id: { $ne: userId }
            });

            if (existingUser) {
                throw new Error('Ten adres email jest już używany przez innego użytkownika');
            }
        }

        // Zrób to samo dla numeru telefonu, jeśli jest aktualizowany
        if (updateData.phoneNumber) {
            const existingUser = await User.findOne({
                phoneNumber: updateData.phoneNumber,
                _id: { $ne: userId }
            });

            if (existingUser) {
                throw new Error('Ten numer telefonu jest już używany przez innego użytkownika');
            }
        }

        // Zaktualizuj użytkownika
        const updatedUser = await User.findByIdAndUpdate(
            userId,
            updateData,
            { new: true, runValidators: true }
        )
            .select('-password -refreshToken'); // Wyklucz wrażliwe dane

        return updatedUser;
    } catch (error) {
        console.error(`Błąd podczas aktualizacji użytkownika o ID ${userId}:`, error);
        throw error;
    }
};

/**
 * Zmienia hasło użytkownika
 *
 * @param {string} userId - ID użytkownika
 * @param {string} currentPassword - Obecne hasło
 * @param {string} newPassword - Nowe hasło
 * @returns {Promise<boolean>} - Informacja o sukcesie
 */
exports.changePassword = async (userId, currentPassword, newPassword) => {
    try {
        // Pobierz użytkownika z hasłem
        const user = await User.findById(userId);
        if (!user) {
            throw new Error('Użytkownik nie istnieje');
        }

        // Sprawdź, czy obecne hasło jest poprawne
        const isPasswordValid = await user.comparePassword(currentPassword);
        if (!isPasswordValid) {
            throw new Error('Obecne hasło jest nieprawidłowe');
        }

        // Zaktualizuj hasło
        user.password = newPassword;
        await user.save();

        return true;
    } catch (error) {
        console.error(`Błąd podczas zmiany hasła użytkownika o ID ${userId}:`, error);
        throw error;
    }
};

/**
 * Usuwa konto użytkownika
 *
 * @param {string} userId - ID użytkownika
 * @returns {Promise<boolean>} - Informacja o sukcesie
 */
exports.deleteUser = async (userId) => {
    const session = await mongoose.startSession();
    session.startTransaction();

    try {
        // Sprawdź, czy użytkownik istnieje
        const user = await User.findById(userId);
        if (!user) {
            throw new Error('Użytkownik nie istnieje');
        }

        // W rzeczywistej implementacji należy:
        // 1. Obsłużyć członkostwo w grupach (np. usunąć użytkownika z grup lub przekazać uprawnienia)
        // 2. Obsłużyć wydatki i rozliczenia (np. oznaczyć jako obsłużone lub usunąć)

        // Znajdź grupy, w których użytkownik jest jedynym administratorem
        const adminGroups = await Group.find({
            'members': {
                $elemMatch: {
                    'user': userId,
                    'role': 'admin'
                }
            }
        }).session(session);

        for (const group of adminGroups) {
            // Sprawdź, czy jest jedynym administratorem
            const adminMembers = group.members.filter(m => m.role === 'admin');
            if (adminMembers.length === 1 && adminMembers[0].user.toString() === userId) {
                // Znajdź innego członka, któremu można przekazać uprawnienia administratora
                const otherMember = group.members.find(m => m.user.toString() !== userId);

                if (otherMember) {
                    // Przekaż uprawnienia administratora
                    otherMember.role = 'admin';
                    await group.save({ session });
                } else {
                    // Jeśli nie ma innych członków, usuń grupę
                    await Group.findByIdAndDelete(group._id).session(session);
                }
            }
        }

        // Usuń użytkownika ze wszystkich grup
        await Group.updateMany(
            { 'members.user': userId },
            { $pull: { members: { user: userId } } }
        ).session(session);

        // Usuń użytkownika
        await User.findByIdAndDelete(userId).session(session);

        await session.commitTransaction();
        return true;
    } catch (error) {
        await session.abortTransaction();
        console.error(`Błąd podczas usuwania użytkownika o ID ${userId}:`, error);
        throw error;
    } finally {
        session.endSession();
    }
};