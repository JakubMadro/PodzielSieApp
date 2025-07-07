/**
 * Data Transfer Object dla żądania resetowania hasła
 */
class ForgotPasswordDto {
    constructor(data) {
        this.email = data.email;
    }

    /**
     * Waliduje DTO
     * @returns {Object} Obiekt z wynikiem walidacji { isValid: boolean, errors: string[] }
     */
    validate() {
        const errors = [];

        // Email - wymagany
        if (!this.email) {
            errors.push('Email jest wymagany');
        } else if (!this.validateEmail(this.email)) {
            errors.push('Podaj prawidłowy adres email');
        }

        return {
            isValid: errors.length === 0,
            errors
        };
    }

    /**
     * Waliduje format email
     * @param {string} email
     * @returns {boolean}
     */
    validateEmail(email) {
        const re = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        return re.test(email);
    }
}

module.exports = ForgotPasswordDto;