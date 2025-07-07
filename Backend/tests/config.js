// tests/config.js
const mongoose = require('mongoose');
const jwt = require('jsonwebtoken');
const User = require('../src/models/User');

// Globalna zmienna połączenia
let dbConnection = null;

// Wzorzec Singleton dla połączenia z bazą danych
const setupDatabase = async () => {
    try {
        // Zwróć istniejące połączenie, jeśli jest aktywne
        if (mongoose.connection.readyState === 1) {
            console.log('Używam istniejącego połączenia do bazy danych');
            return mongoose.connection;
        }

        // Użyj testowego URI połączenia
        const dbURI = process.env.MONGODB_URI_TEST || 

        await mongoose.connect(dbURI, {
            useNewUrlParser: true,
            useUnifiedTopology: true
        });

        console.log('Połączono z testową bazą danych MongoDB Atlas');
        return mongoose.connection;
    } catch (error) {
        console.error('Błąd połączenia z bazą danych:', error);
        throw error;
    }
};

// Nie zamykaj połączenia między testami
const closeDatabase = async () => {
    try {
        console.log('Zachowanie połączenia z bazą danych');
    } catch (error) {
        console.error('Błąd obsługi bazy danych:', error);
        throw error;
    }
};

// Czyszczenie bazy danych z poprawną obsługą błędów
const clearDatabase = async () => {
    try {
        const collections = mongoose.connection.collections;

        for (const key in collections) {
            try {
                // Użyj deleteMany z pustym obiektem filtrującym
                await collections[key].deleteMany({});
            } catch (err) {
                console.error(`Błąd czyszczenia kolekcji ${key}:`, err);
                // Kontynuuj z innymi kolekcjami, nawet jeśli jedna się nie powiedzie
            }
        }
    } catch (error) {
        console.error('Błąd czyszczenia bazy danych:', error);
        // Nie rzucaj błędu - tylko go zaloguj i kontynuuj
        // Pozwala to na uruchomienie testów, nawet jeśli czyszczenie nie powiodło się
    }
};

// Funkcja pomocnicza do tworzenia testowego użytkownika
const createTestUser = async (userData = {}) => {
    const defaultData = {
        firstName: 'Test',
        lastName: 'User',
        email: 'test@example.com',
        password: 'Password123',
        phoneNumber: '+48123456789',
        defaultCurrency: 'PLN',
        language: 'pl'
    };

    // Połącz domyślne dane z dostarczonymi danymi
    const mergedData = { ...defaultData, ...userData };

    const user = new User(mergedData);
    await user.save();

    // Wygeneruj token JWT dla użytkownika
    const token = jwt.sign(
        {
            id: user._id,
            email: user.email,
            firstName: user.firstName,
            lastName: user.lastName
        },
        process.env.JWT_SECRET || 'test-secret',
        { expiresIn: '1h' }
    );

    return { user, token };
};

// Eksportuj funkcje pomocnicze
module.exports = {
    setupDatabase,
    closeDatabase,
    clearDatabase,
    createTestUser
};