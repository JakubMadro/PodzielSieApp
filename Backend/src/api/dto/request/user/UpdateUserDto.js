/**
 * Data Transfer Object dla aktualizacji użytkownika
 */
class UpdateUserDto {
    constructor(data) {
        this.firstName = data.firstName;
        this.lastName = data.lastName;
        this.defaultCurrency = data.defaultCurrency;
        this.language = data.language;
        this.notificationSettings = data.notificationSettings;
    }

    /**
     * Waliduje DTO
     * @returns {Object} Obiekt z wynikiem walidacji { isValid: boolean, errors: string[] }
     */
    validate() {
        const errors = [];

        // Imię - opcjonalne, ale jeśli podane, min 2 znaki
        if (this.firstName !== undefined && (this.firstName === null || this.firstName.trim().length < 2)) {
            errors.push('Imię musi mieć co najmniej 2 znaki');
        }

        // Nazwisko - opcjonalne, ale jeśli podane, min 2 znaki
        if (this.lastName !== undefined && (this.lastName === null || this.lastName.trim().length < 2)) {
            errors.push('Nazwisko musi mieć co najmniej 2 znaki');
        }

        // Waluta - format ISO 4217
        if (this.defaultCurrency !== undefined && !this.validateCurrency(this.defaultCurrency)) {
            errors.push('Podaj prawidłowy kod waluty (format ISO 4217)');
        }

        // Język - dostępne języki
        if (this.language !== undefined && !['pl', 'en'].includes(this.language)) {
            errors.push('Dostępne języki to: pl, en');
        }

        // Ustawienia powiadomień - opcjonalne, ale jeśli podane, muszą być obiektem
        if (this.notificationSettings !== undefined) {
            if (typeof this.notificationSettings !== 'object' || this.notificationSettings === null) {
                errors.push('Ustawienia powiadomień muszą być obiektem');
            } else {
                // Walidacja pól ustawień powiadomień
                ['newExpense', 'settlementRequest', 'groupInvite'].forEach(setting => {
                    if (this.notificationSettings[setting] !== undefined && typeof this.notificationSettings[setting] !== 'boolean') {
                        errors.push(`Ustawienie ${setting} musi być wartością logiczną`);
                    }
                });
            }
        }

        return {
            isValid: errors.length === 0,
            errors
        };
    }

    /**
     * Waliduje kod waluty
     * @param {string} currency
     * @returns {boolean}
     */
    validateCurrency(currency) {
        if (currency === undefined || currency === null) return false;
        // Prosta walidacja - format ISO 4217 (3 znaki)
        const re = /^[A-Z]{3}$/;
        return re.test(currency);
    }

    /**
     * Zwraca obiekt zawierający tylko zdefiniowane pola
     * @returns {Object} Obiekt do aktualizacji
     */
    toUpdateEntity() {
        const updateData = {};

        if (this.firstName !== undefined) updateData.firstName = this.firstName;
        if (this.lastName !== undefined) updateData.lastName = this.lastName;
        if (this.defaultCurrency !== undefined) updateData.defaultCurrency = this.defaultCurrency;
        if (this.language !== undefined) updateData.language = this.language;

        // Ustawienia powiadomień - aktualizujemy tylko przekazane pola
        if (this.notificationSettings !== undefined) {
            updateData.notificationSettings = {};

            if (this.notificationSettings.newExpense !== undefined) {
                updateData.notificationSettings.newExpense = this.notificationSettings.newExpense;
            }

            if (this.notificationSettings.settlementRequest !== undefined) {
                updateData.notificationSettings.settlementRequest = this.notificationSettings.settlementRequest;
            }

            if (this.notificationSettings.groupInvite !== undefined) {
                updateData.notificationSettings.groupInvite = this.notificationSettings.groupInvite;
            }
        }

        return updateData;
    }
}

module.exports = UpdateUserDto;