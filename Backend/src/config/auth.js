const jwt = require('jsonwebtoken');

/**
 * Generuje token JWT na podstawie danych użytkownika
 * @param {Object} user - Obiekt użytkownika
 * @returns {string} Token JWT
 */
const generateToken = (user) => {
    return jwt.sign(
        {
            id: user._id,
            email: user.email,
            firstName: user.firstName,
            lastName: user.lastName
        },
        process.env.JWT_SECRET,
        {
            expiresIn: process.env.JWT_EXPIRES_IN || '1d'
        }
    );
};

/**
 * Generuje token odświeżania JWT
 * @param {Object} user - Obiekt użytkownika
 * @returns {string} Token odświeżania JWT
 */
const generateRefreshToken = (user) => {
    return jwt.sign(
        { id: user._id },
        process.env.JWT_REFRESH_SECRET,
        {
            expiresIn: process.env.JWT_REFRESH_EXPIRES_IN || '7d'
        }
    );
};

/**
 * Weryfikuje poprawność tokenu JWT
 * @param {string} token - Token JWT do weryfikacji
 * @returns {Object|null} Zdekodowany token lub null jeśli token jest nieprawidłowy
 */
const verifyToken = (token) => {
    try {
        const decoded = jwt.verify(token, process.env.JWT_SECRET);
        return decoded;
    } catch (error) {
        return null;
    }
};

/**
 * Weryfikuje poprawność tokenu odświeżania JWT
 * @param {string} token - Token odświeżania JWT do weryfikacji
 * @returns {Object|null} Zdekodowany token lub null jeśli token jest nieprawidłowy
 */
const verifyRefreshToken = (token) => {
    try {
        const decoded = jwt.verify(token, process.env.JWT_REFRESH_SECRET);
        return decoded;
    } catch (error) {
        return null;
    }
};

module.exports = {
    generateToken,
    generateRefreshToken,
    verifyToken,
    verifyRefreshToken
};