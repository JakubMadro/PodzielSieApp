// tests/setup.js
// Skrypt wywoływany przez Jest przed uruchomieniem testów

// Ustawienie zmiennych środowiskowych dla testów
process.env.JWT_SECRET = 'test-secret-key';
process.env.JWT_EXPIRES_IN = '1h';
process.env.JWT_REFRESH_SECRET = 'test-refresh-secret-key';
process.env.JWT_REFRESH_EXPIRES_IN = '7d';
process.env.NODE_ENV = 'test';

// Bardzo ważne: używamy tej samej bazy danych dla wszystkich testów
process.env.MONGODB_URI = process.env.MONGODB_URI_TEST;

// Zapobiegaj uruchomieniu serwera w trybie testowym
process.env.TEST_MODE = 'true';

// Wyciszenie konsoli podczas testów (odkomentuj, jeśli potrzebne)
/*
console.log = jest.fn();
console.info = jest.fn();
console.warn = jest.fn();
console.error = jest.fn();
*/