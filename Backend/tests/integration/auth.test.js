// tests/integration/auth.test.js
const request = require('supertest');
const mongoose = require('mongoose');
const app = require('../../src/server');
const User = require('../../src/models/User');
const { setupDatabase, clearDatabase, closeDatabase } = require('../config');

// Uruchomienie serwera przed wszystkimi testami
beforeAll(async () => {
    await setupDatabase();
});

// Wyczyszczenie bazy danych przed każdym testem
beforeEach(async () => {
    await clearDatabase();
});

// Zamknięcie połączenia po wszystkich testach
afterAll(async () => {
    await closeDatabase();
    // Zamykamy serwer Express
    if (app.close) {
        await new Promise((resolve) => app.close(resolve));
    }
});

describe('Testy API autoryzacji', () => {
    // Test rejestracji użytkownika
    // tests/integration/auth.test.js - poprawiony test rejestracji

    test('Powinno zarejestrować nowego użytkownika', async () => {
        // Generuj unikalne dane testowe
        const timestamp = Date.now();
        const random = Math.floor(Math.random() * 10000);

        const userData = {
            firstName: 'Jan',
            lastName: 'Kowalski',
            email: `jan.kowalski.${timestamp}.${random}@example.com`, // Unikalny email
            password: 'StrongPass123', // Hasło spełnia wszystkie wymagania
            phoneNumber: `${timestamp % 1000000000}` // Unikalny numer telefonu
        };

        // Upewnij się, że nie ma użytkownika o tym emailu
        await User.deleteOne({ email: userData.email }).catch(e => console.error('Błąd czyszczenia:', e));

        console.log('Test rejestracji - dane:', userData);

        const response = await request(app)
            .post('/api/auth/register')
            .send(userData)
            .expect(201);

        // Sprawdzenie odpowiedzi
        expect(response.body.success).toBeTruthy();
        expect(response.body.token).toBeDefined();
        expect(response.body.refreshToken).toBeDefined();
        expect(response.body.user).toBeDefined();
        expect(response.body.user.email).toBe(userData.email);

        // Sprawdzenie, czy użytkownik został zapisany w bazie
        const userInDb = await User.findOne({ email: userData.email });
        expect(userInDb).toBeTruthy();
        expect(userInDb.firstName).toBe(userData.firstName);
    });

    // Test logowania użytkownika
    test('Powinno zalogować istniejącego użytkownika', async () => {
        // Stworzenie testowego użytkownika
        const userData = {
            firstName: 'Anna',
            lastName: 'Nowak',
            email: 'anna.nowak@example.com',
            password: 'StrongPass123',
            phoneNumber: '+48987654321'
        };

        const user = new User(userData);
        await user.save();

        // Próba logowania
        const response = await request(app)
            .post('/api/auth/login')
            .send({
                email: userData.email,
                password: userData.password
            })
            .expect(200);

        // Sprawdzenie odpowiedzi
        expect(response.body.success).toBeTruthy();
        expect(response.body.token).toBeDefined();
        expect(response.body.refreshToken).toBeDefined();
        expect(response.body.user).toBeDefined();
        expect(response.body.user.email).toBe(userData.email);
    });

    // Test niepoprawnego logowania
    test('Nie powinno zalogować z niepoprawnym hasłem', async () => {
        // Stworzenie testowego użytkownika
        const userData = {
            firstName: 'Tomasz',
            lastName: 'Wiśniewski',
            email: 'tomasz.wisniewski@example.com',
            password: 'StrongPass123',
            phoneNumber: '+48555666777'
        };

        const user = new User(userData);
        await user.save();

        // Próba logowania z niepoprawnym hasłem
        const response = await request(app)
            .post('/api/auth/login')
            .send({
                email: userData.email,
                password: 'WrongPassword123'
            })
            .expect(401);

        // Sprawdzenie odpowiedzi
        expect(response.body.success).toBeFalsy();
        expect(response.body.message).toBeDefined();
    });

    // Test odświeżania tokenu
    test('Powinno odświeżyć token JWT', async () => {
        // Stworzenie testowego użytkownika
        const userData = {
            firstName: 'Katarzyna',
            lastName: 'Kowalczyk',
            email: 'katarzyna.kowalczyk@example.com',
            password: 'StrongPass123',
            phoneNumber: '+48333444555'
        };

        // Zapisanie użytkownika i zalogowanie
        const user = new User(userData);
        await user.save();

        const loginResponse = await request(app)
            .post('/api/auth/login')
            .send({
                email: userData.email,
                password: userData.password
            });

        // Odświeżenie tokenu
        const response = await request(app)
            .post('/api/auth/refresh-token')
            .send({
                refreshToken: loginResponse.body.refreshToken
            })
            .expect(200);

        // Sprawdzenie odpowiedzi
        expect(response.body.success).toBeTruthy();
        expect(response.body.token).toBeDefined();
        expect(response.body.refreshToken).toBeDefined();
    });

    // Test wylogowania użytkownika
    test('Powinno wylogować użytkownika', async () => {
        // Stworzenie testowego użytkownika
        const userData = {
            firstName: 'Marek',
            lastName: 'Zieliński',
            email: 'test123@example.com',
            password: 'StrongPass123',
            phoneNumber: '123123123'
        };

        const user = new User(userData);
        await user.save();

        const loginResponse = await request(app)
            .post('/api/auth/login')
            .send({
                email: userData.email,
                password: userData.password
            });

        // Wylogowanie
        const response = await request(app)
            .post('/api/auth/logout')
            .set('Authorization', `Bearer ${loginResponse.body.token}`)
            .expect(200);

        // Sprawdzenie odpowiedzi
        expect(response.body.success).toBeTruthy();
        expect(response.body.message).toBeDefined();
    });
});
