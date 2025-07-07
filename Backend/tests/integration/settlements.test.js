// tests/integration/settlements.test.js
const request = require('supertest');
const mongoose = require('mongoose');
const app = require('../../src/server');
const Group = require('../../src/models/Group');
const Expense = require('../../src/models/Expense');
const Settlement = require('../../src/models/Settlement');
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

describe('Testy API rozliczeń', () => {
    let user1, token1, user2, token2, group, expense;
    
    // Przygotowanie użytkowników, grupy i wydatków przed każdym testem
    beforeEach(async () => {
        // Pierwszy użytkownik
        const testUser1 = await createTestUser({
            email: 'settlement.test1@example.com'
        });
        user1 = testUser1.user;
        token1 = testUser1.token;
        
        // Drugi użytkownik
        const testUser2 = await createTestUser({
            firstName: 'Second',
            lastName: 'User',
            email: 'settlement.test2@example.com',
            phoneNumber: '+48987654321'
        });
        user2 = testUser2.user;
        token2 = testUser2.token;
        
        // Stworzenie grupy z oboma użytkownikami
        group = new Group({
            name: 'Grupa testowa rozliczeń',
            description: 'Grupa do testowania rozliczeń',
            defaultCurrency: 'PLN',
            members: [
                {
                    user: user1._id,
                    role: 'admin',
                    joined: new Date()
                },
                {
                    user: user2._id,
                    role: 'member',
                    joined: new Date()
                }
            ]
        });
        
        await group.save();
        
        // Stworzenie wydatku
        expense = new Expense({
            group: group._id,
            description: 'Wydatek do rozliczenia',
            amount: 200,
            currency: 'PLN',
            paidBy: user1._id,
            category: 'food',
            splitType: 'equal',
            splits: [
                {
                    user: user1._id,
                    amount: 100
                },
                {
                    user: user2._id,
                    amount: 100
                }
            ]
        });
        
        await expense.save();
    });
    
    // Test pobierania sald grupy
    test('Powinno zwrócić salda grupy', async () => {
        // Stworzenie rozliczenia
        const settlement = new Settlement({
            group: group._id,
            payer: user2._id,
            receiver: user1._id,
            amount: 100,
            currency: 'PLN',
            relatedExpenses: [expense._id],
            status: 'pending'
        });
        
        await settlement.save();
        
        // Pobranie sald
        const response = await request(app)
            .get(`/api/groups/${group._id}/balances`)
            .set('Authorization', `Bearer ${token1}`)
            .expect(200);
        
        // Sprawdzenie odpowiedzi
        expect(response.body.success).toBeTruthy();
        expect(response.body.userSettlements).toBeDefined();
        expect(response.body.otherSettlements).toBeDefined();
        
        // Użytkownik 1 powinien mieć jedno rozliczenie, gdzie jest odbiorcą
        expect(response.body.userSettlements).toHaveLength(1);
        expect(response.body.userSettlements[0].receiver._id.toString()).toBe(user1._id.toString());
        expect(response.body.userSettlements[0].payer._id.toString()).toBe(user2._id.toString());
        expect(response.body.userSettlements[0].amount).toBe(100);
    });
    
    // Test odświeżania sald grupy
    test('Powinno odświeżyć salda grupy', async () => {
        // Odświeżenie sald
        const response = await request(app)
            .post(`/api/groups/${group._id}/balances/refresh`)
            .set('Authorization', `Bearer ${token1}`)
            .expect(200);
        
        // Sprawdzenie odpowiedzi
        expect(response.body.success).toBeTruthy();
        expect(response.body.message).toBeDefined();
        expect(response.body.userSettlements).toBeDefined();
        
        // Powinno utworzyć nowe rozliczenie, ponieważ użytkownik2 jest winien użytkownikowi1
        expect(response.body.userSettlements).toHaveLength(1);
        expect(response.body.userSettlements[0].receiver._id.toString()).toBe(user1._id.toString());
        expect(response.body.userSettlements[0].payer._id.toString()).toBe(user2._id.toString());
        expect(response.body.userSettlements[0].amount).toBe(100);
    });
    
    // Test pobierania szczegółów rozliczenia
    test('Powinno zwrócić szczegóły rozliczenia', async () => {
        // Stworzenie rozliczenia
        const settlement = new Settlement({
            group: group._id,
            payer: user2._id,
            receiver: user1._id,
            amount: 100,
            currency: 'PLN',
            relatedExpenses: [expense._id],
            status: 'pending'
        });
        
        await settlement.save();
        
        // Pobranie szczegółów rozliczenia
        const response = await request(app)
            .get(`/api/settlements/${settlement._id}`)
            .set('Authorization', `Bearer ${token1}`)
            .expect(200);
        
        // Sprawdzenie odpowiedzi
        expect(response.body.success).toBeTruthy();
        expect(response.body.settlement).toBeDefined();
        expect(response.body.settlement._id.toString()).toBe(settlement._id.toString());
        expect(response.body.settlement.amount).toBe(settlement.amount);
        expect(response.body.settlement.status).toBe(settlement.status);
    });
    
    // Test rozliczania długu
    test('Powinno oznaczyć dług jako rozliczony', async () => {
        // Stworzenie rozliczenia
        const settlement = new Settlement({
            group: group._id,
            payer: user2._id,
            receiver: user1._id,
            amount: 100,
            currency: 'PLN',
            relatedExpenses: [expense._id],
            status: 'pending'
        });
        
        await settlement.save();
        
        // Oznaczenie jako rozliczony przez płatnika
        const settleData = {
            paymentMethod: 'blik',
            paymentReference: 'BLIK12345'
        };
        
        const response = await request(app)
            .post(`/api/settlements/${settlement._id}/settle`)
            .set('Authorization', `Bearer ${token2}`) // Token drugiego użytkownika (płatnika)
            .send(settleData)
            .expect(200);
        
        // Sprawdzenie odpowiedzi
        expect(response.body.success).toBeTruthy();
        expect(response.body.message).toBeDefined();
        expect(response.body.settlement).toBeDefined();
        expect(response.body.settlement.status).toBe('completed');
        expect(response.body.settlement.paymentMethod).toBe(settleData.paymentMethod);
        expect(response.body.settlement.paymentReference).toBe(settleData.paymentReference);
        
        // Sprawdzenie, czy rozliczenie zostało zaktualizowane w bazie
        const settlementInDb = await Settlement.findById(settlement._id);
        expect(settlementInDb.status).toBe('completed');
        expect(settlementInDb.settledAt).toBeDefined();
    });
    
    // Test braku uprawnień do oznaczania długu jako rozliczony przez nieuprawnionego użytkownika
    test('Nie powinno pozwolić na rozliczenie długu przez nieuprawnionego użytkownika', async () => {
        // Stworzenie rozliczenia, gdzie płatnikiem jest user2
        const settlement = new Settlement({
            group: group._id,
            payer: user2._id,
            receiver: user1._id,
            amount: 100,
            currency: 'PLN',
            relatedExpenses: [expense._id],
            status: 'pending'
        });
        
        await settlement.save();
        
        // Próba oznaczenia jako rozliczony przez niewłaściwego użytkownika (odbiorcy zamiast płatnika)
        const settleData = {
            paymentMethod: 'manual',
            paymentReference: 'TEST123'
        };
        
        const response = await request(app)
            .post(`/api/settlements/${settlement._id}/settle`)
            .set('Authorization', `Bearer ${token1}`) // Token pierwszego użytkownika (odbiorcy, nie płatnika)
            .send(settleData)
            .expect(403);
        
        // Sprawdzenie odpowiedzi
        expect(response.body.success).toBeFalsy();
        expect(response.body.message).toBeDefined();
        
        // Sprawdzenie, czy rozliczenie nie zostało zmienione
        const settlementInDb = await Settlement.findById(settlement._id);
        expect(settlementInDb.status).toBe('pending');
    });
    
    // Test pobierania historii rozliczeń
    test('Powinno zwrócić historię rozliczeń użytkownika', async () => {
        // Stworzenie kilku rozliczeń
        const settlement1 = new Settlement({
            group: group._id,
            payer: user2._id,
            receiver: user1._id,
            amount: 100,
            currency: 'PLN',
            status: 'completed',
            paymentMethod: 'blik',
            settledAt: new Date(Date.now() - 3600000) // 1 godzina temu
        });
        
        const settlement2 = new Settlement({
            group: group._id,
            payer: user1._id,
            receiver: user2._id,
            amount: 50,
            currency: 'PLN',
            status: 'completed',
            paymentMethod: 'manual',
            settledAt: new Date()
        });
        
        const settlement3 = new Settlement({
            group: group._id,
            payer: user2._id,
            receiver: user1._id,
            amount: 200,
            currency: 'PLN',
            status: 'pending' // To nie powinno się pojawić w historii
        });
        
        await settlement1.save();
        await settlement2.save();
        await settlement3.save();
        
        // Pobranie historii rozliczeń
        const response = await request(app)
            .get('/api/settlements/history')
            .set('Authorization', `Bearer ${token1}`)
            .expect(200);
        
        // Sprawdzenie odpowiedzi
        expect(response.body.success).toBeTruthy();
        expect(response.body.settlements).toBeDefined();
        
        // Powinno zwrócić tylko zakończone rozliczenia
        expect(response.body.settlements).toHaveLength(2);
        expect(response.body.settlements.some(s => s.status === 'pending')).toBeFalsy();
        
        // Sprawdzenie paginacji
        expect(response.body.pagination).toBeDefined();
    });

    // Test pobierania oczekujących rozliczeń
    test('Powinno zwrócić tylko oczekujące rozliczenia użytkownika', async () => {
        // Stworzenie kilku rozliczeń
        const settlement1 = new Settlement({
            group: group._id,
            payer: user2._id,
            receiver: user1._id,
            amount: 100,
            currency: 'PLN',
            status: 'pending'
        });
        
        const settlement2 = new Settlement({
            group: group._id,
            payer: user1._id,
            receiver: user2._id,
            amount: 50,
            currency: 'PLN',
            status: 'pending'
        });
        
        const settlement3 = new Settlement({
            group: group._id,
            payer: user2._id,
            receiver: user1._id,
            amount: 200,
            currency: 'PLN',
            status: 'completed',
            settledAt: new Date()
        });
        
        await settlement1.save();
        await settlement2.save();
        await settlement3.save();
        
        // Pobranie oczekujących rozliczeń
        const response = await request(app)
            .get('/api/settlements/pending')
            .set('Authorization', `Bearer ${token1}`)
            .expect(200);
        
        // Sprawdzenie odpowiedzi
        expect(response.body.success).toBeTruthy();
        expect(response.body.settlements).toBeDefined();
        
        // Powinno zwrócić tylko oczekujące rozliczenia
        expect(response.body.settlements).toHaveLength(2);
        expect(response.body.settlements.every(s => s.status === 'pending')).toBeTruthy();
        
        // Sprawdzenie, że wszystkie rozliczenia dotyczą użytkownika
        response.body.settlements.forEach(settlement => {
            const isUserInvolved = settlement.payer._id === user1._id.toString() || 
                                 settlement.receiver._id === user1._id.toString();
            expect(isUserInvolved).toBeTruthy();
        });
        
        // Sprawdzenie paginacji
        expect(response.body.pagination).toBeDefined();
        expect(response.body.pagination.totalDocs).toBe(2);
    });

    // Test pobierania zakończonych rozliczeń
    test('Powinno zwrócić tylko zakończone rozliczenia użytkownika', async () => {
        // Stworzenie kilku rozliczeń
        const settlement1 = new Settlement({
            group: group._id,
            payer: user2._id,
            receiver: user1._id,
            amount: 100,
            currency: 'PLN',
            status: 'completed',
            paymentMethod: 'blik',
            settledAt: new Date(Date.now() - 3600000) // 1 godzina temu
        });
        
        const settlement2 = new Settlement({
            group: group._id,
            payer: user1._id,
            receiver: user2._id,
            amount: 50,
            currency: 'PLN',
            status: 'completed',
            paymentMethod: 'manual',
            settledAt: new Date()
        });
        
        const settlement3 = new Settlement({
            group: group._id,
            payer: user2._id,
            receiver: user1._id,
            amount: 200,
            currency: 'PLN',
            status: 'pending'
        });
        
        await settlement1.save();
        await settlement2.save();
        await settlement3.save();
        
        // Pobranie zakończonych rozliczeń
        const response = await request(app)
            .get('/api/settlements/completed')
            .set('Authorization', `Bearer ${token1}`)
            .expect(200);
        
        // Sprawdzenie odpowiedzi
        expect(response.body.success).toBeTruthy();
        expect(response.body.settlements).toBeDefined();
        
        // Powinno zwrócić tylko zakończone rozliczenia
        expect(response.body.settlements).toHaveLength(2);
        expect(response.body.settlements.every(s => s.status === 'completed')).toBeTruthy();
        
        // Sprawdzenie, że wszystkie rozliczenia dotyczą użytkownika
        response.body.settlements.forEach(settlement => {
            const isUserInvolved = settlement.payer._id === user1._id.toString() || 
                                 settlement.receiver._id === user1._id.toString();
            expect(isUserInvolved).toBeTruthy();
        });
        
        // Sprawdzenie sortowania (najnowsze najpierw)
        if (response.body.settlements.length > 1) {
            const firstSettlement = new Date(response.body.settlements[0].settledAt);
            const secondSettlement = new Date(response.body.settlements[1].settledAt);
            expect(firstSettlement.getTime()).toBeGreaterThanOrEqual(secondSettlement.getTime());
        }
        
        // Sprawdzenie paginacji
        expect(response.body.pagination).toBeDefined();
        expect(response.body.pagination.totalDocs).toBe(2);
    });

    // Test pobierania wszystkich rozliczeń użytkownika
    test('Powinno zwrócić wszystkie rozliczenia użytkownika', async () => {
        // Stworzenie kilku rozliczeń
        const settlement1 = new Settlement({
            group: group._id,
            payer: user2._id,
            receiver: user1._id,
            amount: 100,
            currency: 'PLN',
            status: 'pending'
        });
        
        const settlement2 = new Settlement({
            group: group._id,
            payer: user1._id,
            receiver: user2._id,
            amount: 50,
            currency: 'PLN',
            status: 'completed',
            paymentMethod: 'manual',
            settledAt: new Date()
        });
        
        const settlement3 = new Settlement({
            group: group._id,
            payer: user2._id,
            receiver: user1._id,
            amount: 200,
            currency: 'PLN',
            status: 'completed',
            paymentMethod: 'blik',
            settledAt: new Date(Date.now() - 3600000)
        });
        
        // Rozliczenie nie dotyczące użytkownika - nie powinno się pojawić
        const otherGroup = new Group({
            name: 'Inna grupa',
            defaultCurrency: 'PLN',
            members: [{ user: user2._id, role: 'admin' }]
        });
        await otherGroup.save();
        
        const testUser3 = await createTestUser({
            email: 'user3@test.com',
            phoneNumber: '+48555555555'
        });
        
        const settlement4 = new Settlement({
            group: otherGroup._id,
            payer: user2._id,
            receiver: testUser3.user._id,
            amount: 75,
            currency: 'PLN',
            status: 'pending'
        });
        
        await settlement1.save();
        await settlement2.save();
        await settlement3.save();
        await settlement4.save();
        
        // Pobranie wszystkich rozliczeń użytkownika
        const response = await request(app)
            .get('/api/settlements')
            .set('Authorization', `Bearer ${token1}`)
            .expect(200);
        
        // Sprawdzenie odpowiedzi
        expect(response.body.success).toBeTruthy();
        expect(response.body.settlements).toBeDefined();
        
        // Powinno zwrócić wszystkie rozliczenia użytkownika (zarówno pending jak i completed)
        expect(response.body.settlements).toHaveLength(3);
        
        // Sprawdzenie, że wszystkie rozliczenia dotyczą użytkownika
        response.body.settlements.forEach(settlement => {
            const isUserInvolved = settlement.payer._id === user1._id.toString() || 
                                 settlement.receiver._id === user1._id.toString();
            expect(isUserInvolved).toBeTruthy();
        });
        
        // Sprawdzenie, że zawiera zarówno pending jak i completed
        const hasPending = response.body.settlements.some(s => s.status === 'pending');
        const hasCompleted = response.body.settlements.some(s => s.status === 'completed');
        expect(hasPending).toBeTruthy();
        expect(hasCompleted).toBeTruthy();
        
        // Sprawdzenie paginacji
        expect(response.body.pagination).toBeDefined();
        expect(response.body.pagination.totalDocs).toBe(3);
    });

    // Test paginacji dla oczekujących rozliczeń
    test('Powinno obsługiwać paginację dla oczekujących rozliczeń', async () => {
        // Stworzenie wielu rozliczeń
        const settlements = [];
        for (let i = 0; i < 25; i++) {
            const settlement = new Settlement({
                group: group._id,
                payer: user2._id,
                receiver: user1._id,
                amount: 10 + i,
                currency: 'PLN',
                status: 'pending'
            });
            settlements.push(settlement);
        }
        
        await Settlement.insertMany(settlements);
        
        // Test pierwszej strony
        const response1 = await request(app)
            .get('/api/settlements/pending?page=1&limit=10')
            .set('Authorization', `Bearer ${token1}`)
            .expect(200);
        
        expect(response1.body.settlements).toHaveLength(10);
        expect(response1.body.pagination.page).toBe(1);
        expect(response1.body.pagination.totalDocs).toBe(25);
        expect(response1.body.pagination.totalPages).toBe(3);
        expect(response1.body.pagination.hasNextPage).toBeTruthy();
        expect(response1.body.pagination.hasPrevPage).toBeFalsy();
        
        // Test drugiej strony
        const response2 = await request(app)
            .get('/api/settlements/pending?page=2&limit=10')
            .set('Authorization', `Bearer ${token1}`)
            .expect(200);
        
        expect(response2.body.settlements).toHaveLength(10);
        expect(response2.body.pagination.page).toBe(2);
        expect(response2.body.pagination.hasNextPage).toBeTruthy();
        expect(response2.body.pagination.hasPrevPage).toBeTruthy();
        
        // Test ostatniej strony
        const response3 = await request(app)
            .get('/api/settlements/pending?page=3&limit=10')
            .set('Authorization', `Bearer ${token1}`)
            .expect(200);
        
        expect(response3.body.settlements).toHaveLength(5);
        expect(response3.body.pagination.page).toBe(3);
        expect(response3.body.pagination.hasNextPage).toBeFalsy();
        expect(response3.body.pagination.hasPrevPage).toBeTruthy();
    });

    // Test autoryzacji - użytkownik bez tokenów
    test('Nie powinno pozwolić na dostęp bez autoryzacji', async () => {
        // Test bez tokenu
        await request(app)
            .get('/api/settlements/pending')
            .expect(401);
        
        await request(app)
            .get('/api/settlements/completed')
            .expect(401);
        
        await request(app)
            .get('/api/settlements')
            .expect(401);
    });

    // Test pustej listy rozliczeń
    test('Powinno zwrócić pustą listę gdy użytkownik nie ma rozliczeń', async () => {
        // Pobranie oczekujących rozliczeń gdy nie ma żadnych
        const response = await request(app)
            .get('/api/settlements/pending')
            .set('Authorization', `Bearer ${token1}`)
            .expect(200);
        
        expect(response.body.success).toBeTruthy();
        expect(response.body.settlements).toHaveLength(0);
        expect(response.body.pagination.totalDocs).toBe(0);
    });
});
