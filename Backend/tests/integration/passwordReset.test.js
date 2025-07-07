// tests/integration/passwordReset.test.js
const request = require('supertest');
const mongoose = require('mongoose');
const app = require('../../src/server');
const User = require('../../src/models/User');
const { setupDatabase, clearDatabase, closeDatabase, createTestUser } = require('../config');
const { generateResetToken, hashToken, generateExpirationDate } = require('../../src/utils/tokenGenerator');

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
});

describe('Testy API resetowania hasła', () => {
    let testUser;

    beforeEach(async () => {
        // Stworzenie testowego użytkownika
        const userData = await createTestUser({
            email: 'test.reset@example.com',
            password: 'OldPassword123'
        });
        testUser = userData.user;
    });

    describe('POST /api/auth/forgot-password', () => {
        test('powinno wysłać żądanie resetowania hasła dla istniejącego użytkownika', async () => {
            const response = await request(app)
                .post('/api/auth/forgot-password')
                .send({ email: testUser.email })
                .expect(200);

            expect(response.body.success).toBeTruthy();
            expect(response.body.message).toContain('zostanie wysłany link do resetowania hasła');

            // Sprawdź czy kod został zapisany w bazie danych
            const updatedUser = await User.findById(testUser._id);
            expect(updatedUser.passwordResetToken).toBeDefined();
            expect(updatedUser.passwordResetExpires).toBeDefined();
            expect(new Date(updatedUser.passwordResetExpires)).toBeInstanceOf(Date);
        });

        test('powinno zwrócić sukces dla nieistniejącego emaila (bezpieczeństwo)', async () => {
            const response = await request(app)
                .post('/api/auth/forgot-password')
                .send({ email: 'nonexistent@example.com' })
                .expect(200);

            expect(response.body.success).toBeTruthy();
            expect(response.body.message).toContain('zostanie wysłany link do resetowania hasła');
        });

        test('powinno odrzucić nieprawidłowy email', async () => {
            const response = await request(app)
                .post('/api/auth/forgot-password')
                .send({ email: 'invalid-email' })
                .expect(400);

            expect(response.body.success).toBeFalsy();
            expect(response.body.errors).toContain('Podaj prawidłowy adres email');
        });

        test('powinno odrzucić brak email', async () => {
            const response = await request(app)
                .post('/api/auth/forgot-password')
                .send({})
                .expect(400);

            expect(response.body.success).toBeFalsy();
            expect(response.body.errors).toContain('Email jest wymagany');
        });

        test('powinno zastąpić poprzedni kod resetowania', async () => {
            // Pierwsze żądanie
            await request(app)
                .post('/api/auth/forgot-password')
                .send({ email: testUser.email })
                .expect(200);

            const firstUpdate = await User.findById(testUser._id);
            const firstCode = firstUpdate.passwordResetToken;

            // Poczekaj chwilę, żeby kod był inny
            await new Promise(resolve => setTimeout(resolve, 100));

            // Drugie żądanie
            await request(app)
                .post('/api/auth/forgot-password')
                .send({ email: testUser.email })
                .expect(200);

            const secondUpdate = await User.findById(testUser._id);
            const secondCode = secondUpdate.passwordResetToken;

            expect(firstCode).not.toBe(secondCode);
        });
    });

    describe('POST /api/auth/reset-password', () => {
        let resetToken, hashedToken;

        beforeEach(async () => {
            // Przygotuj token resetowania
            resetToken = generateResetToken();
            hashedToken = hashToken(resetToken);
            const expirationDate = generateExpirationDate(1);

            testUser.passwordResetToken = hashedToken;
            testUser.passwordResetExpires = expirationDate;
            await testUser.save();
        });

        test('powinno zresetować hasło z prawidłowym kodem', async () => {
            const newPassword = 'NewPassword123';

            const response = await request(app)
                .post('/api/auth/reset-password')
                .send({
                    token: resetToken,
                    newPassword: newPassword,
                    confirmPassword: newPassword
                })
                .expect(200);

            expect(response.body.success).toBeTruthy();
            expect(response.body.message).toBe('Hasło zostało pomyślnie zresetowane');

            // Sprawdź czy kod został usunięty
            const updatedUser = await User.findById(testUser._id);
            expect(updatedUser.passwordResetToken).toBeUndefined();
            expect(updatedUser.passwordResetExpires).toBeUndefined();
            expect(updatedUser.refreshToken).toBeNull();

            // Sprawdź czy hasło zostało zmienione (spróbuj się zalogować)
            const loginResponse = await request(app)
                .post('/api/auth/login')
                .send({
                    email: testUser.email,
                    password: newPassword
                })
                .expect(200);

            expect(loginResponse.body.success).toBeTruthy();
        });

        test('powinno odrzucić nieprawidłowy kod', async () => {
            // Użyj poprawnej długości kodu ale nieprawidłowego
            const invalidCode = '999999'; // 6 cyfr, ale nieprawidłowy
            
            const response = await request(app)
                .post('/api/auth/reset-password')
                .send({
                    token: invalidCode,
                    newPassword: 'NewPassword123',
                    confirmPassword: 'NewPassword123'
                })
                .expect(400);

            expect(response.body.success).toBeFalsy();
            expect(response.body.message).toContain('Kod weryfikacyjny jest nieprawidłowy lub wygasł');
        });

        test('powinno odrzucić wygasły kod', async () => {
            // Ustaw kod jako wygasły
            testUser.passwordResetExpires = new Date(Date.now() - 3600000); // 1 hour ago
            await testUser.save();

            const response = await request(app)
                .post('/api/auth/reset-password')
                .send({
                    token: resetToken,
                    newPassword: 'NewPassword123',
                    confirmPassword: 'NewPassword123'
                })
                .expect(400);

            expect(response.body.success).toBeFalsy();
            expect(response.body.message).toContain('Kod weryfikacyjny jest nieprawidłowy lub wygasł');
        });

        test('powinno walidować siłę hasła', async () => {
            const response = await request(app)
                .post('/api/auth/reset-password')
                .send({
                    token: resetToken,
                    newPassword: 'weak',
                    confirmPassword: 'weak'
                })
                .expect(400);

            expect(response.body.success).toBeFalsy();
            expect(response.body.errors).toContain('Hasło musi mieć co najmniej 8 znaków, zawierać wielką literę, małą literę i cyfrę');
        });

        test('powinno odrzucić różne hasła', async () => {
            const response = await request(app)
                .post('/api/auth/reset-password')
                .send({
                    token: resetToken,
                    newPassword: 'Password123',
                    confirmPassword: 'Different123'
                })
                .expect(400);

            expect(response.body.success).toBeFalsy();
            expect(response.body.errors).toContain('Hasła nie są identyczne');
        });

        test('powinno odrzucić brak kodu', async () => {
            const response = await request(app)
                .post('/api/auth/reset-password')
                .send({
                    newPassword: 'Password123',
                    confirmPassword: 'Password123'
                })
                .expect(400);

            expect(response.body.success).toBeFalsy();
            expect(response.body.errors).toContain('Kod weryfikacyjny jest wymagany');
        });

        test('powinno unieważnić wszystkie sesje po zmianie hasła', async () => {
            // Ustaw refresh token
            testUser.refreshToken = 'some-refresh-token';
            await testUser.save();

            await request(app)
                .post('/api/auth/reset-password')
                .send({
                    token: resetToken,
                    newPassword: 'NewPassword123',
                    confirmPassword: 'NewPassword123'
                })
                .expect(200);

            // Sprawdź czy refresh token został usunięty
            const updatedUser = await User.findById(testUser._id);
            expect(updatedUser.refreshToken).toBeNull();
        });
    });

    describe('Pełny flow resetowania hasła', () => {
        test('powinno przejść przez cały proces resetowania hasła', async () => {
            const newPassword = 'NewCompletePassword123';

            // 1. Żądanie resetowania hasła
            await request(app)
                .post('/api/auth/forgot-password')
                .send({ email: testUser.email })
                .expect(200);

            // 2. Pobierz kod z bazy danych (symulacja odczytu z emaila)
            const userWithCode = await User.findById(testUser._id);
            expect(userWithCode.passwordResetToken).toBeDefined();

            // Znajdź oryginalny kod (w rzeczywistości byłby w emailu)
            // Dla testów musimy "odwrócić" hash - użyjemy nowego kodu
            const resetCode = generateResetToken();
            const hashedCode = hashToken(resetCode);
            
            userWithCode.passwordResetToken = hashedCode;
            await userWithCode.save();

            // 3. Reset hasła
            await request(app)
                .post('/api/auth/reset-password')
                .send({
                    token: resetCode,
                    newPassword: newPassword,
                    confirmPassword: newPassword
                })
                .expect(200);

            // 4. Sprawdź czy można się zalogować nowym hasłem
            const loginResponse = await request(app)
                .post('/api/auth/login')
                .send({
                    email: testUser.email,
                    password: newPassword
                })
                .expect(200);

            expect(loginResponse.body.success).toBeTruthy();
            expect(loginResponse.body.token).toBeDefined();

            // 5. Sprawdź czy stare hasło nie działa
            await request(app)
                .post('/api/auth/login')
                .send({
                    email: testUser.email,
                    password: 'OldPassword123'
                })
                .expect(401);
        });
    });
});