// tests/unit/groupService.test.js
const mongoose = require('mongoose');
const groupService = require('../../src/api/services/groupService');
const Group = require('../../src/models/Group');
const User = require('../../src/models/User');
const { setupDatabase, clearDatabase, closeDatabase } = require('../config');

describe('Testy jednostkowe groupService', () => {
    let testUser, secondUser, testGroup;

    beforeAll(async () => {
        await setupDatabase();
    });

    afterAll(async () => {
        await closeDatabase();
    });

    beforeEach(async () => {
        await clearDatabase();

        // Tworzenie testowych użytkowników
        testUser = new User({
            firstName: 'Test',
            lastName: 'User',
            email: 'test.group@example.com',
            password: 'Password123',
            phoneNumber: '+48123456789'
        });
        await testUser.save();

        secondUser = new User({
            firstName: 'Second',
            lastName: 'User',
            email: 'second.group@example.com',
            password: 'Password123',
            phoneNumber: '+48987654321'
        });
        await secondUser.save();

        // Bezpośrednio tworzę grupę z adminem
        testGroup = await Group.create({
            name: 'Test Group',
            description: 'Test Description',
            defaultCurrency: 'PLN',
            members: [{
                user: testUser._id,
                role: 'admin',
                joined: new Date()
            }]
        });

        // Dodaj logi debugujące
        console.log('Grupa utworzona:', testGroup);
        console.log('Członek grupy:', testGroup.members[0]);
    });

    test('getUserGroups powinno zwrócić grupy użytkownika', async () => {
        const result = await groupService.getUserGroups(testUser._id);
        expect(result).toBeDefined();
        expect(result.length).toBe(1);
        expect(result[0].name).toBe(testGroup.name);
    });

    test('createGroup powinno utworzyć nową grupę', async () => {
        const groupData = {
            name: 'Nowa grupa',
            description: 'Opis nowej grupy',
            defaultCurrency: 'EUR'
        };

        const result = await groupService.createGroup(testUser._id, groupData);
        expect(result).toBeDefined();
        expect(result.name).toBe(groupData.name);
        expect(result.members.length).toBe(1);
        const memberId = result.members[0].user._id || result.members[0].user;
        expect(memberId.toString()).toBe(testUser._id.toString());
    });

    test('getGroupDetails powinno zwrócić szczegóły grupy', async () => {
        // Pobierz grupę bezpośrednio z bazy danych
        const group = await Group.findById(testGroup._id);

        // Sprawdź, czy grupa zawiera członka
        const member = group.members.find(m => m.user.toString() === testUser._id.toString());
        console.log("Sprawdzenie członka przed testem:", {
            grupa: group._id.toString(),
            uzytkownik: testUser._id.toString(),
            czlonekGrupy: member ? "tak" : "nie",
            rola: member ? member.role : "brak"
        });

        const result = await groupService.getGroupDetails(testGroup._id, testUser._id);
        expect(result).toBeDefined();
        expect(result.name).toBe(testGroup.name);
    });

    test('getGroupDetails powinno zwrócić szczegóły grupy', async () => {
        const group = await Group.findById(testGroup._id).populate('members.user');

        // Użyj DOKŁADNIE TEGO SAMEGO ID, które zostało przypisane w beforeEach
        const result = await groupService.getGroupDetails(group._id, testUser._id);

        expect(result).toBeDefined();
        expect(result.name).toBe(group.name);
    });

    test('updateGroup powinno zaktualizować grupę', async () => {
        // Sprawdź implementację isAdmin w groupService.js - może porównuje ID jako stringi?
        const updateData = {
            name: 'Zaktualizowana nazwa',
            description: 'Zaktualizowany opis'
        };

        // Użyj metody z Mongoose dla pewności
        await Group.findOneAndUpdate(
            {
                _id: testGroup._id,
                'members.user': testUser._id
            },
            {
                $set: { 'members.$.role': 'admin' }
            }
        );

        const result = await groupService.updateGroup(
            testGroup._id,
            testUser._id,
            updateData
        );

        expect(result).toBeDefined();
        expect(result.name).toBe(updateData.name);
    });

    test('isGroupAdmin powinno zwrócić true dla administratora', async () => {
        // Zmiana roli bezpośrednio operacją bazodanową
        await Group.findOneAndUpdate(
            {
                _id: testGroup._id,
                'members.user': testUser._id
            },
            {
                $set: { 'members.$.role': 'admin' }
            }
        );

        // Pobierz zaktualizowaną grupę dla upewnienia
        const updatedGroup = await Group.findById(testGroup._id);
        console.log("Zaktualizowana grupa:", {
            id: updatedGroup._id.toString(),
            członkowie: updatedGroup.members.map(m => ({
                id: m.user.toString(),
                rola: m.role,
                userIdMatch: m.user.toString() === testUser._id.toString()
            }))
        });

        const result = await groupService.isGroupAdmin(testGroup._id, testUser._id);
        expect(result).toBe(true);
    });

    test('searchUserGroups powinno wyszukać grupy na podstawie tekstu', async () => {
        const result = await groupService.searchUserGroups(testUser._id, 'Test');

        expect(result).toBeDefined();
        expect(result.length).toBeGreaterThan(0);
        expect(result[0].name).toContain('Test');
    });
    test('DEBUG: Sprawdzenie mechanizmu weryfikacji członkostwa', async () => {
        // 1. Pobierz grupę z bazy danych
        const group = await Group.findById(testGroup._id);

        // 2. Wyświetl szczegóły ID dla analizy
        console.log('DEBUG userId:', {
            testUserId: testUser._id,
            testUserIdString: testUser._id.toString(),
            testUserIdType: typeof testUser._id
        });

        console.log('DEBUG member:', {
            memberUserId: group.members[0].user,
            memberUserIdString: group.members[0].user.toString(),
            memberUserIdType: typeof group.members[0].user
        });

        // 3. Wykonaj ręczne porównanie
        const isMemberManual = group.members.some(
            member => member.user.toString() === testUser._id.toString()
        );

        console.log('Wynik ręcznego porównania:', isMemberManual);

        // 4. Sprawdź funkcję z serwisu
        const isMemberResult = await groupService.isGroupMember(testGroup._id, testUser._id);
        console.log('Wynik funkcji isGroupMember:', isMemberResult);

        // 5. Sprawdź funkcję getGroupDetails bezpośrednio
        try {
            const details = await groupService.getGroupDetails(testGroup._id, testUser._id);
            console.log('getGroupDetails udane:', !!details);
        } catch (error) {
            console.log('getGroupDetails błąd:', error.message);
        }

        // 6. Weryfikacja
        expect(isMemberManual).toBe(true);
        expect(isMemberResult).toBe(true);
    });
});