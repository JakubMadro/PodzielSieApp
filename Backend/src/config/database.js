const mongoose = require('mongoose');

/**
 * Konfiguracja i połączenie z bazą danych MongoDB
 */
const connectToDatabase = async () => {
    try {
        const dbURI = process.env.NODE_ENV === 'test'
            ? process.env.MONGODB_URI_TEST
            : process.env.MONGODB_URI;

        if (!dbURI) {
            throw new Error('Brak URI bazy danych w zmiennych środowiskowych');
        }

        const options = {
            useNewUrlParser: true,
            useUnifiedTopology: true,
        };

        await mongoose.connect(dbURI, options);
        console.log('Połączono z bazą danych MongoDB');

        // Emituj zdarzenie gdy baza danych jest gotowa
        mongoose.connection.once('open', () => {
            console.log('Połączenie z bazą danych ustanowione');
        });

        // Obsługa błędów
        mongoose.connection.on('error', (err) => {
            console.error('Błąd bazy danych MongoDB:', err);
        });

        mongoose.connection.on('disconnected', () => {
            console.log('Rozłączono z bazą danych MongoDB');
        });

        return mongoose.connection;
    } catch (error) {
        console.error('Nie można połączyć się z bazą danych:', error.message);
        process.exit(1);
    }
};

/**
 * Zamyka połączenie z bazą danych
 */
const disconnectFromDatabase = async () => {
    try {
        await mongoose.connection.close();
        console.log('Połączenie z bazą danych zamknięte');
    } catch (error) {
        console.error('Błąd podczas zamykania połączenia z bazą danych:', error);
        throw error;
    }
};

module.exports = { connectToDatabase, disconnectFromDatabase };