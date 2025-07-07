/**
 * Data Transfer Object dla wyszukiwania użytkowników
 */
class SearchQueryDto {
    constructor(data) {
        this.query = data.query;
    }

    /**
     * Waliduje DTO
     * @returns {Object} Obiekt z wynikiem walidacji { isValid: boolean, errors: string[] }
     */
    validate() {
        const errors = [];

        // Query - wymagane, min 3 znaki
        if (!this.query) {
            errors.push('Zapytanie wyszukiwania jest wymagane');
        } else if (this.query.length < 3) {
            errors.push('Zapytanie wyszukiwania musi mieć co najmniej 3 znaki');
        }

        return {
            isValid: errors.length === 0,
            errors
        };
    }
}

module.exports = SearchQueryDto;