// Główny plik serwera - punkt wejściowy aplikacji
const express = require('express');
const dotenv = require('dotenv');
const mongoose = require('mongoose');
const path = require('path');
const fs = require('fs');
const swaggerUi = require('swagger-ui-express');

// Załaduj zmienne środowiskowe z pliku .env
dotenv.config({ path: path.resolve(__dirname, '../.env') })

// Określ środowisko uruchomienia (development/production/test)
const NODE_ENV = process.env.NODE_ENV || 'development';
console.log(`Uruchamianie w środowisku: ${NODE_ENV}`);

// Utwórz katalog na uploadowane pliki (zdjęcia paragongonów, awatary)
const uploadDir = process.env.UPLOAD_DIR || 'uploads';
if (!fs.existsSync(uploadDir)) {
    fs.mkdirSync(uploadDir, { recursive: true });
}

// Importuj konfigurację
const { connectToDatabase } = require('./config/database');
const { setupApp } = require('./config/app');
const { swaggerSpec } = require('./config/swagger');

// Utwórz instancję aplikacji Express
const app = express();

// Zastosuj konfigurację aplikacji (middleware, rate limit, CORS, parsing JSON)
setupApp(app);

// Konfiguracja Swagger UI dla dokumentacji API
app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerSpec, {
    explorer: true,                                    // Włącz explorer
    customCss: '.swagger-ui .topbar { display: none }', // Ukryj górny pasek Swagger
    swaggerOptions: {
        docExpansion: 'none',    // Nie rozwijaj sekcji domyślnie
        filter: true,            // Włącz filtrowanie endpointów
        showRequestDuration: true, // Pokaż czas trwania zapytań
    }
}));


// Importuj pliki tras
const authRoutes = require('./api/routes/authRoutes');
const userRoutes = require('./api/routes/userRoutes');
const groupRoutes = require('./api/routes/groupRoutes');
const expenseRoutes = require('./api/routes/expenseRoutes');
const settlementRoutes = require('./api/routes/settlementRoutes');

// Używaj plików tras z odpowiednimi prefiksami
app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/groups', groupRoutes);
app.use('/api/expenses', expenseRoutes);
app.use('/api/settlements', settlementRoutes);

// Obsługa statycznych plików (np. uploads)
app.use('/uploads', express.static(path.join(__dirname, '..', uploadDir)));

// Dodaj podstawowy endpoint główny ze statusem API
app.get('/', (req, res) => {
    res.json({
        name: 'DzielSie API',
        version: '1.0.0',
        environment: NODE_ENV,
        status: 'OK',
        documentation: '/api-docs'
    });
});

// Endpoint diagnostyczny
app.get('/api/status', async (req, res) => {
    try {
        // Sprawdź połączenie z bazą danych
        const dbStatus = mongoose.connection.readyState === 1 ? 'connected' : 'disconnected';

        // Pobierz nazwę bazy danych
        const databaseName = mongoose.connection.db ? mongoose.connection.db.databaseName : 'Nie połączono';
        const databaseNameAlternative = mongoose.connection.client ? mongoose.connection.client.db().databaseName : 'Nie dostępne';

        res.json({
            status: 'ok',
            timestamp: new Date(),
            environment: process.env.NODE_ENV,
            port: process.env.PORT,
            database: {
                status: dbStatus,
                uri: process.env.MONGODB_URI ? 'Skonfigurowany (nie pokazany)' : 'Brak',
                readyState: mongoose.connection.readyState,
                databaseName: databaseName,
                databaseNameAlternative: databaseNameAlternative
            },
            variables: {
                NODE_ENV: process.env.NODE_ENV,
                PORT: process.env.PORT,
                MONGODB_URI: process.env.MONGODB_URI ? 'Istnieje' : 'Brak',
                JWT_SECRET: process.env.JWT_SECRET ? 'Istnieje' : 'Brak'
            }
        });
    } catch (error) {
        res.status(500).json({
            status: 'error',
            error: error.message
        });
    }
});

// Middleware do obsługi błędów
const errorHandler = require('./api/middleware/errorHandler');
app.use(errorHandler);


// Obsługa trasy 404
app.use((req, res) => {
    res.status(404).json({
        success: false,
        message: 'Endpoint nie został znaleziony'
    });
});

// Pobierz port z env lub użyj domyślnego
const PORT = process.env.PORT || 5545;

// Funkcja startująca aplikację - łączy z bazą i uruchamia serwer
(async () => {
    try {
        // Nawiąż połączenie z bazą danych MongoDB
        await connectToDatabase();

        // Uruchom serwer HTTP tylko jeśli nie jesteśmy w trybie testowym
        if (process.env.TEST_MODE !== 'true') {
            app.listen(PORT, () => {
                console.log(`Serwer uruchomiony na porcie ${PORT} w trybie ${process.env.NODE_ENV}`);
                console.log(`Dokumentacja API dostępna pod adresem: http://localhost:${PORT}/api-docs`);
            });
        } else {
            console.log('Serwer uruchomiony w trybie testowym - nie nasłuchuje na porcie');
        }
    } catch (error) {
        console.error('Nie udało się uruchomić serwera:', error);
        process.exit(1);
    }
})();

// Obsługa graceful shutdown przy otrzymaniu sygnału SIGINT (Ctrl+C)
process.on('SIGINT', async () => {
    try {
        // Zamknij połączenie z bazą danych
        await mongoose.connection.close();
        console.log('Połączenie z bazą danych zamknięte');
        process.exit(0);
    } catch (error) {
        console.error('Błąd podczas zamykania połączenia z bazą danych:', error);
        process.exit(1);
    }
});

// Eksportuj aplikację na potrzeby testów
module.exports = app;