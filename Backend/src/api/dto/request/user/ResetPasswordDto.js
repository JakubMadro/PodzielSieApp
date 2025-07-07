/**
 * Data Transfer Object dla resetowania hasła
 */
class ResetPasswordDto {
    constructor(data) {
        this.token = data.token;
        this.newPassword = data.newPassword;
        this.confirmPassword = data.confirmPassword;
    }

    /**
     * Waliduje DTO
     * @returns {Object} Obiekt z wynikiem walidacji { isValid: boolean, errors: string[] }
     */
    validate() {
        const errors = [];

        // Kod - wymagany
        if (!this.token) {
            errors.push('Kod weryfikacyjny jest wymagany');
        } else if (!/^\d{6}$/.test(this.token)) {
            errors.push('Kod weryfikacyjny musi być 6-cyfrowy');
        }

        // Nowe hasło - wymagane
        if (!this.newPassword) {
            errors.push('Nowe hasło jest wymagane');
        } else if (!this.validatePassword(this.newPassword)) {
            errors.push('Hasło musi mieć co najmniej 8 znaków, zawierać wielką literę, małą literę i cyfrę');
        }

        // Potwierdzenie hasła - wymagane
        if (!this.confirmPassword) {
            errors.push('Potwierdzenie hasła jest wymagane');
        } else if (this.newPassword !== this.confirmPassword) {
            errors.push('Hasła nie są identyczne');
        }

        return {
            isValid: errors.length === 0,
            errors
        };
    }

    /**
     * Waliduje siłę hasła
     * @param {string} password
     * @returns {boolean}
     */
    validatePassword(password) {
        // Minimum 8 znaków, co najmniej jedna wielka litera, jedna mała litera i jedna cyfra
        const re = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)[a-zA-Z\d@$!%*?&]{8,}$/;
        return re.test(password);
    }
}

module.exports = ResetPasswordDto;