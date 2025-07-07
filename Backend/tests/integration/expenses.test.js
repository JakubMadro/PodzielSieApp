// tests/integration/expenses.test.js
const request = require('supertest');
const mongoose = require('mongoose');
const app = require('../../src/server');
const Group = require('../../src/models/Group');
const Expense = require('../../src/models/Expense');
const User = require('../../src/models/User');
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

describe('Testy API wydatków', () => {
    let user, token, secondUser, secondToken, group;
    
    // Przygotowanie użytkowników i grupy przed każdym testem
    beforeEach(async () => {
        // Pierwszy użytkownik
        const testUser = await createTestUser({
            email: 'expense.test@example.com'
        });
        user = testUser.user;
        token = testUser.token;
        
        // Drugi użytkownik
        const secondTestUser = await createTestUser({
            firstName: 'Second',
            lastName: 'User',
            email: 'expense.second@example.com',
            phoneNumber: '+48987654321'
        });
        secondUser = secondTestUser.user;
        secondToken = secondTestUser.token;
        
        // Stworzenie grupy z oboma użytkownikami
        group = new Group({
            name: 'Grupa testowa wydatków',
            description: 'Grupa do testowania wydatków',
            defaultCurrency: 'PLN',
            members: [
                {
                    user: user._id,
                    role: 'admin',
                    joined: new Date()
                },
                {
                    user: secondUser._id,
                    role: 'member',
                    joined: new Date()
                }
            ]
        });
        
        await group.save();
    });
    
    // Test tworzenia wydatku
    test('Powinno utworzyć nowy wydatek', async () => {
        const expenseData = {
            group: group._id,
            description: 'Zakupy spożywcze',
            amount: 150.50,
            currency: 'PLN',
            paidBy: user._id,
            category: 'food',
            splitType: 'equal',
            splits: [
                {
                    user: user._id,
                    amount: 75.25
                },
                {
                    user: secondUser._id,
                    amount: 75.25
                }
            ]
        };
        
        const response = await request(app)
            .post('/api/expenses')
            .set('Authorization', `Bearer ${token}`)
            .send(expenseData)
            .expect(201);
        
        // Sprawdzenie odpowiedzi
        expect(response.body.success).toBeTruthy();
        expect(response.body.message).toBeDefined();
        expect(response.body.expense).toBeDefined();
        expect(response.body.expense.description).toBe(expenseData.description);
        expect(response.body.expense.amount).toBe(expenseData.amount);
        expect(response.body.expense.splits).toHaveLength(2);
        
        // Sprawdzenie, czy wydatek został zapisany w bazie
        const expenseInDb = await Expense.findById(response.body.expense._id);
        expect(expenseInDb).toBeTruthy();
        expect(expenseInDb.description).toBe(expenseData.description);
        expect(expenseInDb.amount).toBe(expenseData.amount);
    });
    
    // Test pobierania wydatków grupy
    test('Powinno zwrócić wydatki grupy', async () => {
        // Stworzenie kilku wydatków
        const expense1 = new Expense({
            group: group._id,
            description: 'Zakupy',
            amount: 100,
            currency: 'PLN',
            paidBy: user._id,
            category: 'food',
            splitType: 'equal',
            splits: [
                {
                    user: user._id,
                    amount: 50
                },
                {
                    user: secondUser._id,
                    amount: 50
                }
            ]
        });
        
        const expense2 = new Expense({
            group: group._id,
            description: 'Transport',
            amount: 50,
            currency: 'PLN',
            paidBy: secondUser._id,
            category: 'transport',
            splitType: 'equal',
            splits: [
                {
                    user: user._id,
                    amount: 25
                },
                {
                    user: secondUser._id,
                    amount: 25
                }
            ]
        });
        
        await expense1.save();
        await expense2.save();
        
        // Pobranie wydatków
        const response = await request(app)
            .get(`/api/groups/${group._id}/expenses`)
            .set('Authorization', `Bearer ${token}`)
            .expect(200);
        
        // Sprawdzenie odpowiedzi
        expect(response.body.success).toBeTruthy();
        expect(response.body.expenses).toBeDefined();
        expect(response.body.expenses).toHaveLength(2);
        expect(response.body.pagination).toBeDefined();
    });
    
    // Test pobierania szczegółów wydatku
    test('Powinno zwrócić szczegóły wydatku', async () => {
        // Stworzenie wydatku
        const expense = new Expense({
            group: group._id,
            description: 'Zakupy szczegółowe',
            amount: 200,
            currency: 'PLN',
            paidBy: user._id,
            category: 'food',
            splitType: 'equal',
            splits: [
                {
                    user: user._id,
                    amount: 100
                },
                {
                    user: secondUser._id,
                    amount: 100
                }
            ]
        });
        
        await expense.save();
        
        // Pobranie szczegółów wydatku
        const response = await request(app)
            .get(`/api/expenses/${expense._id}`)
            .set('Authorization', `Bearer ${token}`)
            .expect(200);
        
        // Sprawdzenie odpowiedzi
        expect(response.body.success).toBeTruthy();
        expect(response.body.expense).toBeDefined();
        expect(response.body.expense.description).toBe(expense.description);
        expect(response.body.expense.amount).toBe(expense.amount);
        expect(response.body.expense.splits).toHaveLength(2);
    });
    
    // Test aktualizacji wydatku
    test('Powinno zaktualizować wydatek', async () => {
        // Stworzenie wydatku
        const expense = new Expense({
            group: group._id,
            description: 'Stary opis',
            amount: 300,
            currency: 'PLN',
            paidBy: user._id,
            category: 'food',
            splitType: 'equal',
            splits: [
                {
                    user: user._id,
                    amount: 150
                },
                {
                    user: secondUser._id,
                    amount: 150
                }
            ]
        });
        
        await expense.save();
        
        // Aktualizacja wydatku
        const updateData = {
            description: 'Nowy opis',
            amount: 400,
            category: 'entertainment'
        };
        
        const response = await request(app)
            .put(`/api/expenses/${expense._id}`)
            .set('Authorization', `Bearer ${token}`)
            .send(updateData)
            .expect(200);
        
        // Sprawdzenie odpowiedzi
        expect(response.body.success).toBeTruthy();
        expect(response.body.message).toBeDefined();
        expect(response.body.expense).toBeDefined();
        expect(response.body.expense.description).toBe(updateData.description);
        expect(response.body.expense.amount).toBe(updateData.amount);
        expect(response.body.expense.category).toBe(updateData.category);
        
        // Sprawdzenie, czy wydatek został zaktualizowany w bazie
        const expenseInDb = await Expense.findById(expense._id);
        expect(expenseInDb.description).toBe(updateData.description);
        expect(expenseInDb.amount).toBe(updateData.amount);
    });
    
    // Test dodawania komentarza do wydatku
    test('Powinno dodać komentarz do wydatku', async () => {
        // Stworzenie wydatku
        const expense = new Expense({
            group: group._id,
            description: 'Wydatek do komentowania',
            amount: 150,
            currency: 'PLN',
            paidBy: user._id,
            category: 'food',
            splitType: 'equal',
            splits: [
                {
                    user: user._id,
                    amount: 75
                },
                {
                    user: secondUser._id,
                    amount: 75
                }
            ],
            comments: []
        });
        
        await expense.save();
        
        // Dodanie komentarza
        const commentData = {
            text: 'To jest testowy komentarz'
        };
        
        const response = await request(app)
            .post(`/api/expenses/${expense._id}/comments`)
            .set('Authorization', `Bearer ${token}`)
            .send(commentData)
            .expect(201);
        
        // Sprawdzenie odpowiedzi
        expect(response.body.success).toBeTruthy();
        expect(response.body.message).toBeDefined();
        expect(response.body.comment).toBeDefined();
        expect(response.body.comment.text).toBe(commentData.text);
        expect(response.body.comment.user._id.toString()).toBe(user._id.toString());
        
        // Sprawdzenie, czy komentarz został dodany w bazie
        const expenseInDb = await Expense.findById(expense._id);
        expect(expenseInDb.comments).toHaveLength(1);
        expect(expenseInDb.comments[0].text).toBe(commentData.text);
    });
    
    // Test usuwania wydatku
    test('Powinno usunąć wydatek', async () => {
        // Stworzenie wydatku
        const expense = new Expense({
            group: group._id,
            description: 'Wydatek do usunięcia',
            amount: 250,
            currency: 'PLN',
            paidBy: user._id,
            category: 'food',
            splitType: 'equal',
            splits: [
                {
                    user: user._id,
                    amount: 125
                },
                {
                    user: secondUser._id,
                    amount: 125
                }
            ]
        });
        
        await expense.save();
        
        // Usunięcie wydatku
        const response = await request(app)
            .delete(`/api/expenses/${expense._id}`)
            .set('Authorization', `Bearer ${token}`)
            .expect(200);
        
        // Sprawdzenie odpowiedzi
        expect(response.body.success).toBeTruthy();
        expect(response.body.message).toBeDefined();
        
        // Sprawdzenie, czy wydatek został usunięty z bazy
        const expenseInDb = await Expense.findById(expense._id);
        expect(expenseInDb).toBeNull();
    });
    
    // Test braku uprawnień do edycji wydatku
    test('Nie powinno pozwolić na edycję wydatku przez nieuprawnionego użytkownika', async () => {
        // Stworzenie wydatku, gdzie płatnikiem jest pierwszy użytkownik
        const expense = new Expense({
            group: group._id,
            description: 'Wydatek do testu uprawnień',
            amount: 350,
            currency: 'PLN',
            paidBy: user._id, // Pierwszy użytkownik
            category: 'food',
            splitType: 'equal',
            splits: [
                {
                    user: user._id,
                    amount: 175
                },
                {
                    user: secondUser._id,
                    amount: 175
                }
            ]
        });
        
        await expense.save();
        
        // Próba edycji przez drugiego użytkownika (nie admin, nie płatnik)
        const updateData = {
            description: 'Próba zmiany opisu'
        };
        
        const response = await request(app)
            .put(`/api/expenses/${expense._id}`)
            .set('Authorization', `Bearer ${secondToken}`)
            .send(updateData)
            .expect(403);
        
        // Sprawdzenie odpowiedzi
        expect(response.body.success).toBeFalsy();
        expect(response.body.message).toBeDefined();
        
        // Sprawdzenie, czy wydatek nie został zmieniony
        const expenseInDb = await Expense.findById(expense._id);
        expect(expenseInDb.description).toBe(expense.description);
    });
});
