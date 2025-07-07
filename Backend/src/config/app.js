const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const compression = require('compression');
const rateLimit = require('express-rate-limit');
const path = require('path');
const swaggerUi = require('swagger-ui-express');
const { swaggerSpec } = require('./swagger');

/**
 * Konfiguruje aplikację Express, dodając niezbędne middleware i ustawienia
 * @param {express.Application} app - Instancja aplikacji Express
 */
const setupApp = (app) => {
    // Middleware bezpieczeństwa
    app.use(helmet({
        // Wyłącz contentSecurityPolicy dla Swagger UI
        contentSecurityPolicy: false
    }));

    // Konfiguracja CORS
    app.use(cors({
        origin: process.env.NODE_ENV === 'production'
            ? ['https://yourdomain.com', 'https://www.yourdomain.com']
            : '*',
        methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH'],
        allowedHeaders: ['Content-Type', 'Authorization']
    }));

    // Parsowanie JSON i URL-encoded bodies
    app.use(express.json({ limit: '1mb' }));
    app.use(express.urlencoded({ extended: true, limit: '1mb' }));

    // Kompresja odpowiedzi
    app.use(compression());

    // Logowanie requestów
    const morganFormat = process.env.NODE_ENV === 'production' ? 'combined' : 'dev';
    app.use(morgan(morganFormat));

    // Ograniczenie tempa requestów (rate limiting)
    const limiter = rateLimit({
        windowMs: 15 * 60 * 1000, // 15 minut
        max: 100, // 100 requestów na okno czasowe
        standardHeaders: true,
        legacyHeaders: false,
        message: {
            status: 429,
            message: 'Zbyt wiele requestów, spróbuj ponownie później'
        }
    });
    app.use('/api/', limiter);

    // Swagger UI dla dokumentacji API
    // Zawsze włączaj Swagger w trybie development lub gdy explicite ustawione
    if (process.env.NODE_ENV !== 'production' || process.env.ENABLE_SWAGGER === 'true') {
        // Opcje konfiguracji Swagger UI
        const swaggerUiOptions = {
            explorer: true,
            customCss: '.swagger-ui .topbar { display: none }',
            swaggerOptions: {
                persistAuthorization: true,
                docExpansion: 'none', // 'list', 'full' lub 'none'
                filter: true,
                tagsSorter: 'alpha',
                operationsSorter: 'alpha',
            }
        };

        // Dodaj trasę dla dokumentacji Swagger
        app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerSpec, swaggerUiOptions));

        // Dodaj trasę dla pobrania specyfikacji OpenAPI w formacie JSON
        app.get('/api-docs.json', (req, res) => {
            res.setHeader('Content-Type', 'application/json');
            res.send(swaggerSpec);
        });

        console.log(`Dokumentacja API dostępna pod adresem: /api-docs`);
    }

    // Poinformuj Express o proxy jeśli jest w środowisku produkcyjnym
    if (process.env.NODE_ENV === 'production') {
        app.set('trust proxy', 1);
    }

    return app;
};

module.exports = { setupApp };