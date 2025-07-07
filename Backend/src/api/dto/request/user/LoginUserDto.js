/**
 * Data Transfer Object dla logowania użytkownika
 */
class LoginUserDto {
    constructor(data) {
        this.email = data.email;
        this.password = data.password;
    }

    /**
     * Waliduje DTO
     * @returns {Object} Obiekt z wynikiem walidacji { isValid: boolean, errors: string[] }
     */
    validate() {
        const errors = [];

        // Email - wymagany, format
        if (!this.email) {
            errors.push('Email jest wymagany');
        } else if (!this.validateEmail(this.email)) {
            errors.push('Podaj prawidłowy adres email');
        }

        // Hasło - wymagane
        if (!this.password) {
            errors.push('Hasło jest wymagane');
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
}

module.exports = LoginUserDto;