/**
 * Data Transfer Object dla odświeżania tokenu
 */
class RefreshTokenDto {
    constructor(data) {
        this.refreshToken = data.refreshToken;
    }

    /**
     * Waliduje DTO
     * @returns {Object} Obiekt z wynikiem walidacji { isValid: boolean, errors: string[] }
     */
    validate() {
        const errors = [];

        // Refresh token - wymagany
        if (!this.refreshToken) {
            errors.push('Refresh token jest wymagany');
        }

        return {
            isValid: errors.length === 0,
            errors
        };
    }
}

module.exports = RefreshTokenDto;