// tests/unit/settlementService.test.js
const mongoose = require('mongoose');
const settlementService = require('../../src/api/services/settlementService');
const Settlement = require('../../src/models/Settlement');
const Group = require('../../src/models/Group');
const User = require('../../src/models/User');
const Expense = require('../../src/models/Expense');
const { setupDatabase, clearDatabase, closeDatabase } = require('../config');

describe('Testy jednostkowe settlementService', () => {
    let testUser1, testUser2, testUser3, testGroup;

    beforeAll(async () => {
        await setupDatabase();
    });

    afterAll(async () => {
        await closeDatabase();
    });

    beforeEach(async () => {
        await clearDatabase();

        // Tworzenie testowych użytkowników
        testUser1 = new User({
            firstName: 'User',
            lastName: 'One',
            email: 'user1.settlement@example.com',
            password: 'Password123',
            phoneNumber: '+48111111111'
        });
        await testUser1.save();

        testUser2 = new User({
            firstName: 'User',
            lastName: 'Two',
            email: 'user2.settlement@example.com',
            password: 'Password123',
            phoneNumber: '+48222222222'
        });
        await testUser2.save();

        testUser3 = new User({
            firstName: 'User',
            lastName: 'Three',
            email: 'user3.settlement@example.com',
            password: 'Password123',
            phoneNumber: '+48333333333'
        });
        await testUser3.save();

        // Tworzenie testowej grupy
        testGroup = await Group.create({
            name: 'Test Settlement Group',
            description: 'Test Group for Settlement Service',
            defaultCurrency: 'PLN',
            members: [
                {
                    user: testUser1._id,
                    role: 'admin',
                    joined: new Date()
                },
                {
                    user: testUser2._id,
                    role: 'member',
                    joined: new Date()
                }
            ]
        });
    });

    describe('getPendingSettlements', () => {
        test('powinno zwrócić tylko oczekujące rozliczenia użytkownika', async () => {
            // Tworzenie testowych rozliczeń
            const pendingSettlement1 = new Settlement({
                group: testGroup._id,
                payer: testUser1._id,
                receiver: testUser2._id,
                amount: 100,
                currency: 'PLN',
                status: 'pending'
            });

            const pendingSettlement2 = new Settlement({
                group: testGroup._id,
                payer: testUser2._id,
                receiver: testUser1._id,
                amount: 50,
                currency: 'PLN',
                status: 'pending'
            });

            const completedSettlement = new Settlement({
                group: testGroup._id,
                payer: testUser1._id,
                receiver: testUser2._id,
                amount: 75,
                currency: 'PLN',
                status: 'completed',
                settledAt: new Date()
            });

            // Rozliczenie nie dotyczące użytkownika
            const otherSettlement = new Settlement({
                group: testGroup._id,
                payer: testUser2._id,
                receiver: testUser3._id,
                amount: 25,
                currency: 'PLN',
                status: 'pending'
            });

            await Settlement.insertMany([
                pendingSettlement1,
                pendingSettlement2,
                completedSettlement,
                otherSettlement
            ]);

            // Test dla user1
            const result = await settlementService.getPendingSettlements(testUser1._id);

            expect(result).toBeDefined();
            expect(result.docs).toHaveLength(2);
            expect(result.docs.every(s => s.status === 'pending')).toBeTruthy();
            expect(result.totalDocs).toBe(2);

            // Sprawdź czy wszystkie rozliczenia dotyczą użytkownika
            result.docs.forEach(settlement => {
                // ID mogą być ObjectId lub string, więc konwertujemy do stringa
                const payerId = settlement.payer._id ? settlement.payer._id.toString() : settlement.payer.toString();
                const receiverId = settlement.receiver._id ? settlement.receiver._id.toString() : settlement.receiver.toString();
                const userId = testUser1._id.toString();
                
                const isUserInvolved = payerId === userId || receiverId === userId;
                expect(isUserInvolved).toBeTruthy();
            });
        });

        test('powinno obsługiwać paginację', async () => {
            // Tworzenie wielu rozliczeń
            const settlements = [];
            for (let i = 0; i < 15; i++) {
                settlements.push({
                    group: testGroup._id,
                    payer: testUser1._id,
                    receiver: testUser2._id,
                    amount: 10 + i,
                    currency: 'PLN',
                    status: 'pending'
                });
            }

            await Settlement.insertMany(settlements);

            // Test pierwszej strony
            const page1 = await settlementService.getPendingSettlements(testUser1._id, {
                page: 1,
                limit: 10
            });

            expect(page1.docs).toHaveLength(10);
            expect(page1.page).toBe(1);
            expect(page1.totalDocs).toBe(15);
            expect(page1.totalPages).toBe(2);
            expect(page1.hasNextPage).toBeTruthy();
            expect(page1.hasPrevPage).toBeFalsy();

            // Test drugiej strony
            const page2 = await settlementService.getPendingSettlements(testUser1._id, {
                page: 2,
                limit: 10
            });

            expect(page2.docs).toHaveLength(5);
            expect(page2.page).toBe(2);
            expect(page2.hasNextPage).toBeFalsy();
            expect(page2.hasPrevPage).toBeTruthy();
        });

        test('powinno zwrócić pustą listę gdy nie ma oczekujących rozliczeń', async () => {
            const result = await settlementService.getPendingSettlements(testUser1._id);

            expect(result).toBeDefined();
            expect(result.docs).toHaveLength(0);
            expect(result.totalDocs).toBe(0);
        });
    });

    describe('getCompletedSettlements', () => {
        test('powinno zwrócić tylko zakończone rozliczenia użytkownika', async () => {
            // Tworzenie testowych rozliczeń
            const completedSettlement1 = new Settlement({
                group: testGroup._id,
                payer: testUser1._id,
                receiver: testUser2._id,
                amount: 100,
                currency: 'PLN',
                status: 'completed',
                settledAt: new Date(Date.now() - 3600000) // 1 godzina temu
            });

            const completedSettlement2 = new Settlement({
                group: testGroup._id,
                payer: testUser2._id,
                receiver: testUser1._id,
                amount: 50,
                currency: 'PLN',
                status: 'completed',
                settledAt: new Date()
            });

            const pendingSettlement = new Settlement({
                group: testGroup._id,
                payer: testUser1._id,
                receiver: testUser2._id,
                amount: 75,
                currency: 'PLN',
                status: 'pending'
            });

            await Settlement.insertMany([
                completedSettlement1,
                completedSettlement2,
                pendingSettlement
            ]);

            // Test dla user1
            const result = await settlementService.getCompletedSettlements(testUser1._id);

            expect(result).toBeDefined();
            expect(result.docs).toHaveLength(2);
            expect(result.docs.every(s => s.status === 'completed')).toBeTruthy();
            expect(result.totalDocs).toBe(2);

            // Sprawdź sortowanie (najnowsze najpierw)
            if (result.docs.length > 1) {
                const first = new Date(result.docs[0].settledAt);
                const second = new Date(result.docs[1].settledAt);
                expect(first.getTime()).toBeGreaterThanOrEqual(second.getTime());
            }
        });

        test('powinno zwrócić pustą listę gdy nie ma zakończonych rozliczeń', async () => {
            const result = await settlementService.getCompletedSettlements(testUser1._id);

            expect(result).toBeDefined();
            expect(result.docs).toHaveLength(0);
            expect(result.totalDocs).toBe(0);
        });
    });

    describe('getAllUserSettlements', () => {
        test('powinno zwrócić wszystkie rozliczenia użytkownika', async () => {
            // Tworzenie testowych rozliczeń
            const pendingSettlement = new Settlement({
                group: testGroup._id,
                payer: testUser1._id,
                receiver: testUser2._id,
                amount: 100,
                currency: 'PLN',
                status: 'pending'
            });

            const completedSettlement = new Settlement({
                group: testGroup._id,
                payer: testUser2._id,
                receiver: testUser1._id,
                amount: 50,
                currency: 'PLN',
                status: 'completed',
                settledAt: new Date()
            });

            // Rozliczenie nie dotyczące użytkownika
            const otherSettlement = new Settlement({
                group: testGroup._id,
                payer: testUser2._id,
                receiver: testUser3._id,
                amount: 25,
                currency: 'PLN',
                status: 'pending'
            });

            await Settlement.insertMany([
                pendingSettlement,
                completedSettlement,
                otherSettlement
            ]);

            // Test dla user1
            const result = await settlementService.getAllUserSettlements(testUser1._id);

            expect(result).toBeDefined();
            expect(result.docs).toHaveLength(2);
            expect(result.totalDocs).toBe(2);

            // Sprawdź czy zawiera zarówno pending jak i completed
            const statuses = result.docs.map(s => s.status);
            expect(statuses).toContain('pending');
            expect(statuses).toContain('completed');

            // Sprawdź czy wszystkie rozliczenia dotyczą użytkownika
            result.docs.forEach(settlement => {
                // ID mogą być ObjectId lub string, więc konwertujemy do stringa
                const payerId = settlement.payer._id ? settlement.payer._id.toString() : settlement.payer.toString();
                const receiverId = settlement.receiver._id ? settlement.receiver._id.toString() : settlement.receiver.toString();
                const userId = testUser1._id.toString();
                
                const isUserInvolved = payerId === userId || receiverId === userId;
                expect(isUserInvolved).toBeTruthy();
            });
        });

        test('powinno sortować po dacie utworzenia (najnowsze najpierw)', async () => {
            // Tworzenie rozliczeń z różnymi datami
            const older = new Settlement({
                group: testGroup._id,
                payer: testUser1._id,
                receiver: testUser2._id,
                amount: 100,
                currency: 'PLN',
                status: 'pending'
            });
            older.createdAt = new Date(Date.now() - 7200000); // 2 godziny temu

            const newer = new Settlement({
                group: testGroup._id,
                payer: testUser2._id,
                receiver: testUser1._id,
                amount: 50,
                currency: 'PLN',
                status: 'pending'
            });
            newer.createdAt = new Date(); // teraz

            await older.save();
            await newer.save();

            const result = await settlementService.getAllUserSettlements(testUser1._id);

            expect(result.docs).toHaveLength(2);
            
            // Sprawdź sortowanie
            const firstCreated = new Date(result.docs[0].createdAt);
            const secondCreated = new Date(result.docs[1].createdAt);
            expect(firstCreated.getTime()).toBeGreaterThanOrEqual(secondCreated.getTime());
        });
    });

    describe('settleDebt', () => {
        test('powinno oznaczyć rozliczenie jako zakończone', async () => {
            const settlement = new Settlement({
                group: testGroup._id,
                payer: testUser1._id,
                receiver: testUser2._id,
                amount: 100,
                currency: 'PLN',
                status: 'pending'
            });
            await settlement.save();

            const result = await settlementService.settleDebt(
                settlement._id,
                testUser1._id.toString(),
                'blik',
                'BLIK12345'
            );

            expect(result).toBeDefined();
            expect(result.status).toBe('completed');
            expect(result.paymentMethod).toBe('blik');
            expect(result.paymentReference).toBe('BLIK12345');
            expect(result.settledAt).toBeDefined();

            // Sprawdź w bazie danych
            const updatedSettlement = await Settlement.findById(settlement._id);
            expect(updatedSettlement.status).toBe('completed');
        });

        test('powinno rzucić błąd gdy użytkownik nie jest płatnikiem', async () => {
            const settlement = new Settlement({
                group: testGroup._id,
                payer: testUser1._id,
                receiver: testUser2._id,
                amount: 100,
                currency: 'PLN',
                status: 'pending'
            });
            await settlement.save();

            await expect(
                settlementService.settleDebt(
                    settlement._id,
                    testUser2._id.toString(), // Nie jest płatnikiem
                    'manual'
                )
            ).rejects.toThrow('Tylko płatnik może oznaczyć dług jako spłacony');
        });

        test('powinno rzucić błąd gdy rozliczenie już zostało zakończone', async () => {
            const settlement = new Settlement({
                group: testGroup._id,
                payer: testUser1._id,
                receiver: testUser2._id,
                amount: 100,
                currency: 'PLN',
                status: 'completed',
                settledAt: new Date()
            });
            await settlement.save();

            await expect(
                settlementService.settleDebt(
                    settlement._id,
                    testUser1._id.toString(),
                    'manual'
                )
            ).rejects.toThrow('To rozliczenie zostało już zakończone');
        });

        test('powinno rzucić błąd gdy rozliczenie nie istnieje', async () => {
            const fakeId = new mongoose.Types.ObjectId();

            await expect(
                settlementService.settleDebt(
                    fakeId,
                    testUser1._id.toString(),
                    'manual'
                )
            ).rejects.toThrow('Rozliczenie nie istnieje');
        });
    });

    describe('getUserBalanceSummary', () => {
        test('powinno zwrócić podsumowanie bilansów użytkownika', async () => {
            // Rozliczenie gdzie user1 jest dłużnikiem
            const debtSettlement = new Settlement({
                group: testGroup._id,
                payer: testUser1._id,
                receiver: testUser2._id,
                amount: 100,
                currency: 'PLN',
                status: 'pending'
            });

            // Rozliczenie gdzie user1 jest wierzycielem
            const creditSettlement = new Settlement({
                group: testGroup._id,
                payer: testUser2._id,
                receiver: testUser1._id,
                amount: 50,
                currency: 'PLN',
                status: 'pending'
            });

            await Settlement.insertMany([debtSettlement, creditSettlement]);

            const result = await settlementService.getUserBalanceSummary(testUser1._id);

            expect(result).toBeDefined();
            expect(result.groups).toHaveLength(1);
            expect(result.totalBalance).toBe(-50); // -100 + 50

            const groupBalance = result.groups[0];
            expect(groupBalance.groupId).toBe(testGroup._id.toString());
            expect(groupBalance.balance).toBe(-50);
            expect(groupBalance.toPay).toBe(100);
            expect(groupBalance.toReceive).toBe(50);
        });

        test('powinno zwrócić pustą listę gdy użytkownik nie ma aktywnych rozliczeń', async () => {
            const result = await settlementService.getUserBalanceSummary(testUser1._id);

            expect(result).toBeDefined();
            expect(result.groups).toHaveLength(0);
            expect(result.totalBalance).toBe(0);
        });

        test('nie powinno uwzględniać zakończonych rozliczeń', async () => {
            // Oczekujące rozliczenie
            const pendingSettlement = new Settlement({
                group: testGroup._id,
                payer: testUser1._id,
                receiver: testUser2._id,
                amount: 100,
                currency: 'PLN',
                status: 'pending'
            });

            // Zakończone rozliczenie
            const completedSettlement = new Settlement({
                group: testGroup._id,
                payer: testUser1._id,
                receiver: testUser2._id,
                amount: 200,
                currency: 'PLN',
                status: 'completed',
                settledAt: new Date()
            });

            await Settlement.insertMany([pendingSettlement, completedSettlement]);

            const result = await settlementService.getUserBalanceSummary(testUser1._id);

            expect(result).toBeDefined();
            expect(result.totalBalance).toBe(-100); // Tylko pending settlement
        });
    });
});