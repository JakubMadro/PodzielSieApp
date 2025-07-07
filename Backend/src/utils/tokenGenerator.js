const crypto = require('crypto');

/**
 * Generuje 6-cyfrowy kod weryfikacyjny
 * @returns {string} Losowy 6-cyfrowy kod
 */
const generateResetToken = () => {
    return Math.floor(100000 + Math.random() * 900000).toString();
};

/**
 * Tworzy hash kodu do bezpiecznego przechowywania w bazie danych
 * @param {string} code - Kod do zahashowania
 * @returns {string} Zahashowany kod
 */
const hashToken = (code) => {
    return crypto.createHash('sha256').update(code).digest('hex');
};

/**
 * Sprawdza czy kod nie wygasł
 * @param {Date} expiresAt - Data wygaśnięcia
 * @returns {boolean} True jeśli kod jest nadal ważny
 */
const isTokenValid = (expiresAt) => {
    return new Date() < new Date(expiresAt);
};

/**
 * Generuje datę wygaśnięcia kodu (domyślnie 15 minut od teraz)
 * @param {number} minutesFromNow - Liczba minut od teraz (domyślnie 15)
 * @returns {Date} Data wygaśnięcia
 */
const generateExpirationDate = (minutesFromNow = 15) => {
    const expiration = new Date();
    expiration.setMinutes(expiration.getMinutes() + minutesFromNow);
    return expiration;
};

module.exports = {
    generateResetToken,
    hashToken,
    isTokenValid,
    generateExpirationDate
};