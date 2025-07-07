/**
 * Data Transfer Object dla zmiany hasła użytkownika
 */
class ChangePasswordDto {
    constructor(data) {
        this.currentPassword = data.currentPassword;
        this.newPassword = data.newPassword;
    }

    /**
     * Waliduje DTO
     * @returns {Object} Obiekt z wynikiem walidacji { isValid: boolean, errors: string[] }
     */
    validate() {
        const errors = [];

        // Obecne hasło - wymagane
        if (!this.currentPassword) {
            errors.push('Obecne hasło jest wymagane');
        }

        // Nowe hasło - wymagane, min 6 znaków, zawiera cyfrę
        if (!this.newPassword) {
            errors.push('Nowe hasło jest wymagane');
        } else if (this.newPassword.length < 6) {
            errors.push('Nowe hasło musi mieć co najmniej 6 znaków');
        } else if (!/\d/.test(this.newPassword)) {
            errors.push('Nowe hasło musi zawierać co najmniej jedną cyfrę');
        }

        // Sprawdź, czy nowe hasło różni się od obecnego
        if (this.currentPassword && this.newPassword && this.currentPassword === this.newPassword) {
            errors.push('Nowe hasło musi być inne niż obecne');
        }

        return {
            isValid: errors.length === 0,
            errors
        };
    }
}

module.exports = ChangePasswordDto;