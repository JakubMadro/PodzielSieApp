/**
 * Data Transfer Object dla odpowiedzi z danymi użytkownika
 */
class UserDto {
    constructor(user) {
        this._id = user._id;
        this.firstName = user.firstName;
        this.lastName = user.lastName;
        this.email = user.email;
        this.phoneNumber = user.phoneNumber;
        this.defaultCurrency = user.defaultCurrency;
        this.language = user.language;
        this.avatar = user.avatar;
        this.notificationSettings = user.notificationSettings;
        this.createdAt = user.createdAt;
        this.updatedAt = user.updatedAt;
    }

    /**
     * Zwraca podstawowe informacje o użytkowniku (bez wrażliwych danych)
     * @returns {Object} Podstawowe dane użytkownika
     */
    getBasicInfo() {
        return {
            _id: this._id,
            firstName: this.firstName,
            lastName: this.lastName,
            email: this.email,
            avatar: this.avatar
        };
    }

    /**
     * Zwraca pełne informacje o użytkowniku
     * @returns {Object} Pełne dane użytkownika
     */
    getFullInfo() {
        return {
            _id: this._id,
            firstName: this.firstName,
            lastName: this.lastName,
            email: this.email,
            phoneNumber: this.phoneNumber,
            defaultCurrency: this.defaultCurrency,
            language: this.language,
            avatar: this.avatar,
            notificationSettings: this.notificationSettings,
            createdAt: this.createdAt,
            updatedAt: this.updatedAt
        };
    }

    /**
     * Zwraca dane użytkownika do autentykacji
     * @param {string} token - Token JWT
     * @param {string} refreshToken - Token odświeżający
     * @returns {Object} Dane użytkownika z tokenami
     */
    getAuthInfo(token, refreshToken) {
        return {
            user: this.getBasicInfo(),
            token,
            refreshToken
        };
    }
}

module.exports = UserDto;