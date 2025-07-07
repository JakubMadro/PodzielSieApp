// src/config/swagger.js
const swaggerJsdoc = require('swagger-jsdoc');
const path = require('path');

// Importuj definicje DTO do użycia jako schematy - dostosuj ścieżki według swojej struktury folderów
// Uwaga: Będziesz musiał utworzyć plik index.js w folderze dto, który eksportuje wszystkie DTO
const dtoImports = require('../api/dto');

/**
 * Generuj definicje schematów z DTO
 * @returns {Object} Obiekty schematów dla Swagger
 */
const generateDtoSchemas = () => {
    // Bazowe schematy, które już masz
    const schemas = {
        User: {
            type: 'object',
            properties: {
                _id: {
                    type: 'string',
                    description: 'Unikalny identyfikator użytkownika',
                    example: '60d21b4667d0d8992e610c85',
                },
                firstName: {
                    type: 'string',
                    description: 'Imię użytkownika',
                    example: 'Jan',
                },
                lastName: {
                    type: 'string',
                    description: 'Nazwisko użytkownika',
                    example: 'Kowalski',
                },
                email: {
                    type: 'string',
                    format: 'email',
                    description: 'Adres email użytkownika',
                    example: 'jan.kowalski@example.com',
                },
                avatar: {
                    type: 'string',
                    description: 'URL do awatara użytkownika',
                    example: 'https://dziel-sie.pl/avatars/default.png',
                },
                defaultCurrency: {
                    type: 'string',
                    description: 'Domyślna waluta użytkownika',
                    example: 'PLN',
                },
                language: {
                    type: 'string',
                    description: 'Preferowany język interfejsu',
                    example: 'pl',
                },
                notificationSettings: {
                    type: 'object',
                    properties: {
                        newExpense: {
                            type: 'boolean',
                            description: 'Powiadomienia o nowych wydatkach',
                            example: true,
                        },
                        settlementRequest: {
                            type: 'boolean',
                            description: 'Powiadomienia o prośbach o rozliczenie',
                            example: true,
                        },
                        groupInvite: {
                            type: 'boolean',
                            description: 'Powiadomienia o zaproszeniach do grupy',
                            example: true,
                        },
                    },
                },
            },
        },
    };

    // Dodaj schematy DTO
    try {
        // Funkcja pomocnicza do ekstrakcji pól z klasy DTO
        const extractDtoFields = (dtoClass) => {
            try {
                const instance = new dtoClass({});
                const properties = {};

                // Pozyskaj nazwy pól i ich typy
                Object.getOwnPropertyNames(instance).forEach(prop => {
                    // Pomiń pola zaczynające się od '_'
                    if (prop.startsWith('_')) return;

                    // Określ typ na podstawie wartości domyślnej
                    let type = typeof instance[prop];

                    // Obsługa wartości undefined i null
                    if (instance[prop] === undefined || instance[prop] === null) {
                        type = 'string'; // Domyślny typ
                    }

                    // Obsługa obiektów zagnieżdżonych (np. notificationSettings)
                    if (type === 'object' && instance[prop] !== null) {
                        const nestedProperties = {};

                        Object.keys(instance[prop]).forEach(nestedProp => {
                            nestedProperties[nestedProp] = {
                                type: typeof instance[prop][nestedProp]
                            };
                        });

                        properties[prop] = {
                            type: 'object',
                            properties: nestedProperties
                        };
                    } else {
                        properties[prop] = { type };
                    }
                });

                return {
                    type: 'object',
                    properties
                };
            } catch (error) {
                console.warn(`Nie można wygenerować schematu dla DTO: ${error.message}`);
                return {
                    type: 'object',
                    properties: {}
                };
            }
        };

        // Dodaj schematy dla każdego DTO
        for (const [name, dto] of Object.entries(dtoImports)) {
            if (typeof dto === 'function' && name.includes('Dto')) {
                schemas[name] = extractDtoFields(dto);
            }
        }

    } catch (error) {
        console.warn('Nie można wygenerować schematów DTO:', error.message);
    }

    return schemas;
};

/**
 * Konfiguracja Swagger dla dokumentacji API
 */
const swaggerOptions = {
    definition: {
        openapi: '3.0.0',
        info: {
            title: 'DzielSie API (TEST)',
            version: '1.0.0-test',
            description: `
API aplikacji do dzielenia wydatków grupowych - ŚRODOWISKO TESTOWE.

**UWAGA:** To jest środowisko testowe. Dane mogą być resetowane. Używaj tylko do celów testowych.

Przy korzystaniu z tej dokumentacji na Azure, użyj prawidłowego adresu:
\`https://dzielsieapp-aceua3ewcva9dkhw.canadacentral-01.azurewebsites.net\`
`,
            contact: {
                name: 'Zespół DzielSie',
                email: 'kontakt@dziel-sie.pl',
                url: 'https://dziel-sie.pl',
            },
            license: {
                name: 'MIT',
                url: 'https://opensource.org/licenses/MIT',
            },
        },
        servers: [
            {
                url: `https://dzielsieapp-aceua3ewcva9dkhw.canadacentral-01.azurewebsites.net`,
                description: 'Serwer testowy Azure',
            },
            {
                url: `http://localhost:${process.env.PORT || 5545}`,
                description: 'Serwer lokalny',
            }
        ],
        tags: [
            {
                name: 'Auth',
                description: 'Endpointy autoryzacji i uwierzytelniania',
            },
            {
                name: 'Users',
                description: 'Zarządzanie użytkownikami',
            },
            {
                name: 'Groups',
                description: 'Zarządzanie grupami rozliczeniowymi',
            },
            {
                name: 'Expenses',
                description: 'Zarządzanie wydatkami w grupach',
            },
            {
                name: 'Settlements',
                description: 'Rozliczenia między użytkownikami',
            },
        ],
        components: {
            securitySchemes: {
                bearerAuth: {
                    type: 'http',
                    scheme: 'bearer',
                    bearerFormat: 'JWT',
                },
            },
            schemas: generateDtoSchemas(),
            responses: {
                BadRequest: {
                    description: 'Nieprawidłowe dane wejściowe',
                    content: {
                        'application/json': {
                            schema: {
                                type: 'object',
                                properties: {
                                    success: {
                                        type: 'boolean',
                                        example: false
                                    },
                                    message: {
                                        type: 'string',
                                        example: 'Błędy walidacji danych'
                                    },
                                    errors: {
                                        type: 'array',
                                        items: {
                                            type: 'object',
                                            properties: {
                                                field: {
                                                    type: 'string',
                                                    example: 'email'
                                                },
                                                message: {
                                                    type: 'string',
                                                    example: 'Podaj prawidłowy adres email'
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                },
                Unauthorized: {
                    description: 'Nieautoryzowany dostęp',
                    content: {
                        'application/json': {
                            schema: {
                                type: 'object',
                                properties: {
                                    message: {
                                        type: 'string',
                                        example: 'Brak dostępu, wymagane uwierzytelnienie'
                                    }
                                }
                            }
                        }
                    }
                },
                NotFound: {
                    description: 'Zasób nie został znaleziony',
                    content: {
                        'application/json': {
                            schema: {
                                type: 'object',
                                properties: {
                                    success: {
                                        type: 'boolean',
                                        example: false
                                    },
                                    message: {
                                        type: 'string',
                                        example: 'Zasób nie został znaleziony'
                                    }
                                }
                            }
                        }
                    }
                }
            }
        },
        security: [
            {
                bearerAuth: [],
            },
        ],
    },
    // Używamy path.join dla bezpiecznego podania ścieżki niezależnej od systemu
    // Dodajemy również ścieżki do kontrolerów i DTO, aby uwzględnić komentarze JSDoc
    apis: [
        path.join(__dirname, '../api/routes/*.js'),
        path.join(__dirname, '../api/controllers/*.js'),
        path.join(__dirname, '../api/dto/**/*.js')
    ],
};

// Generowanie specyfikacji Swagger
const swaggerSpec = swaggerJsdoc(swaggerOptions);

module.exports = { swaggerSpec };