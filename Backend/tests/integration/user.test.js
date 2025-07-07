// tests/integration/user.test.js
const request = require('supertest');
const mongoose = require('mongoose');
const app = require('../../src/server');
const User = require('../../src/models/User');
const Group = require('../../src/models/Group');
const Expense = require('../../src/models/Expense');
const { setupDatabase, clearDatabase, closeDatabase, createTestUser } = require('../config');

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

describe('Testy API użytkownika', () => {
    let user, token;
    
    // Przygotowanie użytkownika przed każdym testem
    beforeEach(async () => {
        const testUser = await createTestUser({
            email: 'user.test@example.com'
        });
        user = testUser.user;
        token = testUser.token;
    });
    
    // Test pobierania profilu użytkownika
    test('Powinno zwrócić profil zalogowanego użytkownika', async () => {
        const response = await request(app)
            .get('/api/users/me')
            .set('Authorization', `Bearer ${token}`)
            .expect(200);
        
        // Sprawdzenie odpowiedzi
        expect(response.body.success).toBeTruthy();
        expect(response.body.user).toBeDefined();
        expect(response.body.user.email).toBe(user.email);
        expect(response.body.user.firstName).toBe(user.firstName);
        expect(response.body.user.lastName).toBe(user.lastName);
        
        // Sprawdzenie, czy wrażliwe dane nie są zwracane
        expect(response.body.user.password).toBeUndefined();
        expect(response.body.user.refreshToken).toBeUndefined();
    });
    
    // Test aktualizacji profilu użytkownika
    test('Powinno zaktualizować profil użytkownika', async () => {
        const updateData = {
            firstName: 'Nowe Imię',
            lastName: 'Nowe Nazwisko',
            defaultCurrency: 'EUR',
            language: 'en',
            notificationSettings: {
                newExpense: false,
                settlementRequest: true,
                groupInvite: false
            }
        };
        
        const response = await request(app)
            .put('/api/users/me')
            .set('Authorization', `Bearer ${token}`)
            .send(updateData)
            .expect(200);
        
        // Sprawdzenie odpowiedzi
        expect(response.body.success).toBeTruthy();
        expect(response.body.message).toBeDefined();
        expect(response.body.user).toBeDefined();
        expect(response.body.user.firstName).toBe(updateData.firstName);
        expect(response.body.user.lastName).toBe(updateData.lastName);
        expect(response.body.user.defaultCurrency).toBe(updateData.defaultCurrency);
        expect(response.body.user.language).toBe(updateData.language);
        expect(response.body.user.notificationSettings.newExpense).toBe(updateData.notificationSettings.newExpense);
        expect(response.body.user.notificationSettings.settlementRequest).toBe(updateData.notificationSettings.settlementRequest);
        expect(response.body.user.notificationSettings.groupInvite).toBe(updateData.notificationSettings.groupInvite);
        
        // Sprawdzenie, czy użytkownik został zaktualizowany w bazie
        const userInDb = await User.findById(user._id);
        expect(userInDb.firstName).toBe(updateData.firstName);
        expect(userInDb.lastName).toBe(updateData.lastName);
        expect(userInDb.defaultCurrency).toBe(updateData.defaultCurrency);
    });
    
    // Test zmiany hasła użytkownika
    test('Powinno zmienić hasło użytkownika', async () => {
        const passwordData = {
            currentPassword: 'Password123', // Domyślne hasło z createTestUser
            newPassword: 'NewPassword456'
        };
        
        const response = await request(app)
            .put('/api/users/me/password')
            .set('Authorization', `Bearer ${token}`)
            .send(passwordData)
            .expect(200);
        
        // Sprawdzenie odpowiedzi
        expect(response.body.success).toBeTruthy();
        expect(response.body.message).toBeDefined();
        
        // Sprawdzenie, czy można zalogować się nowym hasłem
        const loginResponse = await request(app)
            .post('/api/auth/login')
            .send({
                email: user.email,
                password: passwordData.newPassword
            })
            .expect(200);
        
        expect(loginResponse.body.success).toBeTruthy();
        expect(loginResponse.body.token).toBeDefined();
    });
    
    // Test niepowodzenia zmiany hasła przy podaniu błędnego obecnego hasła
    test('Nie powinno zmienić hasła przy błędnym obecnym haśle', async () => {
        const passwordData = {
            currentPassword: 'WrongPassword',
            newPassword: 'NewPassword456'
        };
        
        const response = await request(app)
            .put('/api/users/me/password')
            .set('Authorization', `Bearer ${token}`)
            .send(passwordData)
            .expect(401);
        
        // Sprawdzenie odpowiedzi
        expect(response.body.success).toBeFalsy();
        expect(response.body.message).toBeDefined();
    });
    
    // Test wyszukiwania użytkowników
    test('Powinno wyszukać użytkowników', async () => {
        // Stworzenie kilku dodatkowych użytkowników
        const user1 = new User({
            firstName: 'Jan',
            lastName: 'Kowalski',
            email: 'jan.kowalski@example.com',
            password: 'Password123',
            phoneNumber: '+48111222333'
        });
        
        const user2 = new User({
            firstName: 'Anna',
            lastName: 'Nowak',
            email: 'anna.nowak@example.com',
            password: 'Password123',
            phoneNumber: '+48444555666'
        });
        
        await user1.save();
        await user2.save();
        
        // Wyszukiwanie użytkowników po fragmencie emaila
        const response = await request(app)
            .get('/api/users/search?query=example.com')
            .set('Authorization', `Bearer ${token}`)
            .expect(200);
        
        // Sprawdzenie odpowiedzi
        expect(response.body.success).toBeTruthy();
        expect(response.body.users).toBeDefined();
        expect(response.body.users.length).toBeGreaterThanOrEqual(2);
        
        // Nie powinno zawierać bieżącego użytkownika
        const currentUserFound = response.body.users.some(u => u._id.toString() === user._id.toString());
        expect(currentUserFound).toBeFalsy();
        
        // Nie powinno zawierać wrażliwych danych
        expect(response.body.users[0].password).toBeUndefined();
        expect(response.body.users[0].refreshToken).toBeUndefined();
    });
    
    // Test wyszukiwania użytkowników po imieniu
    test('Powinno wyszukać użytkowników po imieniu', async () => {
        // Stworzenie dodatkowego użytkownika
        const user1 = new User({
            firstName: 'Tomasz',
            lastName: 'Kowalski',
            email: 'tomasz.kowalski@example.com',
            password: 'Password123',
            phoneNumber: '+48777888999'
        });
        
        await user1.save();
        
        // Wyszukiwanie użytkowników po imieniu
        const response = await request(app)
            .get('/api/users/search?query=Tomasz')
            .set('Authorization', `Bearer ${token}`)
            .expect(200);
        
        // Sprawdzenie odpowiedzi
        expect(response.body.success).toBeTruthy();
        expect(response.body.users).toBeDefined();
        expect(response.body.users.length).toBeGreaterThanOrEqual(1);
        expect(response.body.users[0].firstName).toBe('Tomasz');
    });
    
    // Test usuwania konta użytkownika
    test('Powinno usunąć konto użytkownika', async () => {
        const response = await request(app)
            .delete('/api/users/me')
            .set('Authorization', `Bearer ${token}`)
            .expect(200);
        
        // Sprawdzenie odpowiedzi
        expect(response.body.success).toBeTruthy();
        expect(response.body.message).toBeDefined();
        
        // Sprawdzenie, czy użytkownik został usunięty z bazy
        const userInDb = await User.findById(user._id);
        expect(userInDb).toBeNull();
    });

    // Test pobierania aktywności użytkownika
    test('Powinno zwrócić aktywności użytkownika', async () => {
        // Stworzenie grupy
        const group = new Group({
            name: 'Grupa testowa aktywności',
            members: [{
                user: user._id,
                role: 'admin',
                joined: new Date()
            }]
        });
        await group.save();

        // Stworzenie wydatku
        const expense = new Expense({
            group: group._id,
            description: 'Wydatek testowy',
            amount: 200,
            currency: 'PLN',
            paidBy: user._id,
            category: 'food',
            splitType: 'equal',
            splits: [{
                user: user._id,
                amount: 200
            }],
            date: new Date()
        });
        await expense.save();

        // Pobranie aktywności
        const response = await request(app)
            .get('/api/users/activities?limit=5')
            .set('Authorization', `Bearer ${token}`)
            .expect(200);

        // Sprawdzenie odpowiedzi
        expect(response.body.success).toBeTruthy();
        expect(response.body.activities).toBeDefined();
        expect(response.body.activities.length).toBeGreaterThan(0);

        // Sprawdzenie zawartości pierwszej aktywności
        const activity = response.body.activities[0];
        expect(activity.type).toBe('newExpense');
        expect(activity.title).toContain('Wydatek testowy');
        expect(activity.groupId).toBeDefined();
        expect(activity.expenseId).toBeDefined();
    });
});
