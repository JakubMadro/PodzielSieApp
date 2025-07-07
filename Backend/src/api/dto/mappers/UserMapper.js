const UserDto = require('../response/user/UserDto');
const UserProfileDto = require('../response/user/UserProfileDto');

/**
 * Mapper do konwersji między modelem User a DTO
 */
class UserMapper {
    /**
     * Konwertuje model User na UserDto
     * @param {Object} userModel - Model User z bazy danych
     * @returns {UserDto} DTO użytkownika
     */
    static toDto(userModel) {
        return new UserDto(userModel);
    }

    /**
     * Konwertuje model User na UserProfileDto
     * @param {Object} userModel - Model User z bazy danych
     * @returns {UserProfileDto} DTO profilu użytkownika
     */
    static toProfileDto(userModel) {
        return new UserProfileDto(userModel);
    }

    /**
     * Konwertuje kolekcję modeli User na tablicę UserDto
     * @param {Array} userModels - Tablica modeli User
     * @returns {Array} Tablica DTO użytkowników
     */
    static toDtoList(userModels) {
        return userModels.map(userModel => this.toDto(userModel));
    }

    /**
     * Konwertuje kolekcję modeli User na tablicę podstawowych informacji o użytkownikach
     * @param {Array} userModels - Tablica modeli User
     * @returns {Array} Tablica podstawowych informacji o użytkownikach
     */
    static toBasicInfoList(userModels) {
        return userModels.map(userModel => this.toDto(userModel).getBasicInfo());
    }
}

module.exports = UserMapper;