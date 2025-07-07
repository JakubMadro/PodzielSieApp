/**
 * Data Transfer Object dla szczegółowych danych profilu użytkownika
 */
class UserProfileDto {
    constructor(user) {
        this._id = user._id;
        this.firstName = user.firstName;
        this.lastName = user.lastName;
        this.email = user.email;
        this.phoneNumber = user.phoneNumber;
        this.defaultCurrency = user.defaultCurrency;
        this.language = user.language;
        this.avatar = user.avatar;
        this.notificationSettings = {
            newExpense: user.notificationSettings?.newExpense ?? true,
            settlementRequest: user.notificationSettings?.settlementRequest ?? true,
            groupInvite: user.notificationSettings?.groupInvite ?? true
        };
        this.createdAt = user.createdAt;
        this.updatedAt = user.updatedAt;
    }

    /**
     * Formatuje dane do odpowiedzi API
     * @returns {Object} Sformatowane dane profilu
     */
    toResponse() {
        return {
            id: this._id,
            firstName: this.firstName,
            lastName: this.lastName,
            email: this.email,
            phoneNumber: this.phoneNumber,
            defaultCurrency: this.defaultCurrency,
            language: this.language,
            avatar: this.avatar || '/uploads/avatars/default.png',
            notificationSettings: this.notificationSettings,
            createdAt: this.createdAt,
            updatedAt: this.updatedAt
        };
    }
}

module.exports = UserProfileDto;