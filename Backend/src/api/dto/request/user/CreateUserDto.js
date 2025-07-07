/**
 * Data Transfer Object dla tworzenia nowego użytkownika
 */
class CreateUserDto {
    constructor(data) {
        this.firstName = data.firstName;
        this.lastName = data.lastName;
        this.email = data.email;
        this.password = data.password;
        this.phoneNumber = data.phoneNumber;
        this.defaultCurrency = data.defaultCurrency || 'PLN';
        this.language = data.language || 'pl';
        this.notificationSettings = {
            newExpense: data.notificationSettings?.newExpense ?? true,
            settlementRequest: data.notificationSettings?.settlementRequest ?? true,
            groupInvite: data.notificationSettings?.groupInvite ?? true
        };
    }

    /**
     * Waliduje DTO
     * @returns {Object} Obiekt z wynikiem walidacji { isValid: boolean, errors: string[] }
     */
    validate() {
        const errors = [];

        // Imię - wymagane, min 2 znaki
        if (!this.firstName || this.firstName.trim().length < 2) {
            errors.push('Imię jest wymagane i musi mieć co najmniej 2 znaki');
        }

        // Nazwisko - wymagane, min 2 znaki
        if (!this.lastName || this.lastName.trim().length < 2) {
            errors.push('Nazwisko jest wymagane i musi mieć co najmniej 2 znaki');
        }

        // Email - wymagany, format
        if (!this.email || !this.validateEmail(this.email)) {
            errors.push('Podaj prawidłowy adres email');
        }

        // Hasło - wymagane, min 6 znaków, zawiera cyfrę
        if (!this.password || this.password.length < 6 || !/\d/.test(this.password)) {
            errors.push('Hasło musi mieć co najmniej 6 znaków i zawierać cyfrę');
        }

        // Numer telefonu - opcjonalny, format
        if (this.phoneNumber && !this.validatePhoneNumber(this.phoneNumber)) {
            errors.push('Podaj prawidłowy numer telefonu');
        }

        // Waluta - format ISO 4217
        if (this.defaultCurrency && !this.validateCurrency(this.defaultCurrency)) {
            errors.push('Podaj prawidłowy kod waluty');
        }

        // Język - dostępne języki
        if (this.language && !['pl', 'en'].includes(this.language)) {
            errors.push('Dostępne języki to: pl, en');
        }

        return {
            isValid: errors.length === 0,
            errors
        };
    }

    /**
     * Waliduje format adresu email
     * @param {string} email
     * @returns {boolean}
     */
    validateEmail(email) {
        const re = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        return re.test(email);
    }

    /**
     * Waliduje numer telefonu
     * @param {string} phoneNumber
     * @returns {boolean}
     */
    validatePhoneNumber(phoneNumber) {
        // Prosta walidacja - można rozszerzyć dla różnych formatów
        const re = /^\+?[\d\s()-]{8,}$/;
        return re.test(phoneNumber);
    }

    /**
     * Waliduje kod waluty
     * @param {string} currency
     * @returns {boolean}
     */
    validateCurrency(currency) {
        // Prosta walidacja - format ISO 4217 (3 znaki)
        const re = /^[A-Z]{3}$/;
        return re.test(currency);
    }

    /**
     * Przekształca DTO do obiektu do zapisu w bazie danych
     * @returns {Object} Obiekt do zapisu
     */
    toEntity() {
        return {
            firstName: this.firstName,
            lastName: this.lastName,
            email: this.email,
            password: this.password,
            phoneNumber: this.phoneNumber,
            defaultCurrency: this.defaultCurrency,
            language: this.language,
            notificationSettings: this.notificationSettings
        };
    }
}
/**
 * @swagger
 * components:
 *   schemas:
 *     CreateUserDto:
 *       type: object
 *       required:
 *         - firstName
 *         - lastName
 *         - email
 *         - password
 *       properties:
 *         firstName:
 *           type: string
 *           description: Imię użytkownika
 *           example: Jan
 *           minLength: 2
 *         lastName:
 *           type: string
 *           description: Nazwisko użytkownika
 *           example: Kowalski
 *           minLength: 2
 *         email:
 *           type: string
 *           format: email
 *           description: Adres email (będzie służył jako login)
 *           example: jan.kowalski@example.com
 *         password:
 *           type: string
 *           format: password
 *           description: Hasło użytkownika (min. 6 znaków, zawierające cyfry)
 *           example: Secret123
 *         phoneNumber:
 *           type: string
 *           description: Numer telefonu użytkownika (opcjonalny)
 *           example: '+48123456789'
 *         defaultCurrency:
 *           type: string
 *           description: Domyślna waluta
 *           default: PLN
 *           example: PLN
 *         language:
 *           type: string
 *           description: Język interfejsu
 *           default: pl
 *           example: pl
 *         notificationSettings:
 *           type: object
 *           properties:
 *             newExpense:
 *               type: boolean
 *               default: true
 *             settlementRequest:
 *               type: boolean
 *               default: true
 *             groupInvite:
 *               type: boolean
 *               default: true
 */
module.exports = CreateUserDto;