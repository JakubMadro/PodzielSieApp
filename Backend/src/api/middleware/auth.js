// Importy narzędzi autoryzacji i modelu użytkownika
const { verifyToken } = require('../../config/auth');
const User = require('../../models/User');

/**
 * Middleware do ochrony tras wymagających autentykacji
 * Weryfikuje token JWT i dodaje dane użytkownika do obiektu req
 */
const authenticate = async (req, res, next) => {
    try {
        // Pobierz nagłówek Authorization z requestu
        const authHeader = req.headers.authorization;

        // Sprawdź czy nagłówek istnieje i ma prawidłowy format "Bearer TOKEN"
        if (!authHeader || !authHeader.startsWith('Bearer ')) {
            return res.status(401).json({
                message: 'Brak dostępu, wymagane uwierzytelnienie'
            });
        }

        // Wyciągnij token JWT z nagłówka (usuwając "Bearer ")
        const token = authHeader.split(' ')[1];

        // Zweryfikuj token JWT i zdekoduj dane użytkownika
        const decoded = verifyToken(token);
        if (!decoded) {
            return res.status(401).json({
                message: 'Nieprawidłowy token, wymagane ponowne zalogowanie'
            });
        }

        // Sprawdź czy użytkownik o ID z tokenu nadal istnieje w bazie
        const user = await User.findById(decoded.id).select('-password');
        if (!user) {
            return res.status(401).json({
                message: 'Nieprawidłowy token, użytkownik nie istnieje'
            });
        }

        // Dodaj dane użytkownika do obiektu request dla kolejnych middleware
        req.user = user;

        // Przejdź do następnego middleware
        next();
    } catch (error) {
        console.error('Błąd autentykacji:', error);
        return res.status(500).json({
            message: 'Błąd autoryzacji, spróbuj ponownie później'
        });
    }
};

/**
 * Middleware do sprawdzania roli administratora
 * Wymaga wcześniejszego użycia middleware authenticate
 */
const isAdmin = (req, res, next) => {
    if (!req.user) {
        return res.status(401).json({
            message: 'Brak autentykacji, wymagane zalogowanie'
        });
    }

    if (!req.user.isAdmin) {
        return res.status(403).json({
            message: 'Brak uprawnień do wykonania tej operacji'
        });
    }

    next();
};

/**
 * Middleware do sprawdzania członkostwa w grupie
 * Wymaga wcześniejszego użycia middleware authenticate
 */
const isGroupMember = async (req, res, next) => {
    try {
        if (!req.user) {
            return res.status(401).json({
                message: 'Brak autentykacji, wymagane zalogowanie'
            });
        }

        const groupId = req.params.groupId || req.body.groupId || req.params.id;

        if (!groupId) {
            return res.status(400).json({
                message: 'Brak identyfikatora grupy'
            });
        }

        // Pobierz grupę z bazy danych
        const Group = require('../../models/Group');
        const group = await Group.findById(groupId);

        if (!group) {
            return res.status(404).json({
                message: 'Grupa nie istnieje'
            });
        }

        // Sprawdź, czy użytkownik jest członkiem grupy
        const isMember = group.members.some(
            member => member.user.toString() === req.user._id.toString()
        );

        if (!isMember) {
            return res.status(403).json({
                message: 'Nie jesteś członkiem tej grupy'
            });
        }

        // Dodaj grupę do obiektu req
        req.group = group;

        next();
    } catch (error) {
        console.error('Błąd sprawdzania członkostwa w grupie:', error);
        return res.status(500).json({
            message: 'Błąd podczas sprawdzania członkostwa w grupie'
        });
    }
};

/**
 * Middleware do sprawdzania roli administratora grupy
 * Wymaga wcześniejszego użycia middleware isGroupMember
 */
const isGroupAdmin = (req, res, next) => {
    if (!req.user || !req.group) {
        return res.status(401).json({
            message: 'Wymagane zalogowanie i dostęp do grupy'
        });
    }

    // Znajdź członkostwo użytkownika w grupie
    const membership = req.group.members.find(
        member => member.user.toString() === req.user._id.toString()
    );

    if (!membership || membership.role !== 'admin') {
        return res.status(403).json({
            message: 'Wymagane uprawnienia administratora grupy'
        });
    }

    next();
};

module.exports = {
    authenticate,
    isAdmin,
    isGroupMember,
    isGroupAdmin
};