// tests/integration/groups.test.js
const request = require('supertest');
const mongoose = require('mongoose');
const app = require('../../src/server');
const Group = require('../../src/models/Group');
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

describe('Testy API grup', () => {
    let user, token, secondUser, secondToken;

    // Przygotowanie użytkowników przed każdym testem
    beforeEach(async () => {
        // Pierwszy użytkownik
        const testUser = await createTestUser({
            email: 'group.test@example.com'
        });
        user = testUser.user;
        token = testUser.token;

        // Drugi użytkownik (do testów dodawania członków)
        const secondTestUser = await createTestUser({
            firstName: 'Second',
            lastName: 'User',
            email: 'second.user@example.com',
            phoneNumber: '+48987654321'
        });
        secondUser = secondTestUser.user;
        secondToken = secondTestUser.token;
    });

    // Test tworzenia grupy
    test('Powinno utworzyć nową grupę', async () => {
        const groupData = {
            name: 'Grupa testowa',
            description: 'Opis grupy testowej',
            defaultCurrency: 'PLN'
        };

        const response = await request(app)
            .post('/api/groups')
            .set('Authorization', `Bearer ${token}`)
            .send(groupData)
            .expect(201);

        // Sprawdzenie odpowiedzi
        expect(response.body.success).toBeTruthy();
        expect(response.body.group).toBeDefined();
        expect(response.body.group.name).toBe(groupData.name);
        expect(response.body.group.description).toBe(groupData.description);
        expect(response.body.group.defaultCurrency).toBe(groupData.defaultCurrency);
        expect(response.body.group.members).toHaveLength(1);
        expect(response.body.group.members[0].role).toBe('admin');
        expect(response.body.group.members[0].user._id.toString()).toBe(user._id.toString());

        // Sprawdzenie, czy grupa została zapisana w bazie
        const groupInDb = await Group.findById(response.body.group._id);
        expect(groupInDb).toBeTruthy();
        expect(groupInDb.name).toBe(groupData.name);
    });

    // Test pobierania grup użytkownika
    test('Powinno zwrócić grupy użytkownika', async () => {
        // Stworzenie kilku grup dla użytkownika
        const group1 = new Group({
            name: 'Grupa 1',
            description: 'Opis grupy 1',
            members: [{
                user: user._id,
                role: 'admin',
                joined: new Date()
            }]
        });

        const group2 = new Group({
            name: 'Grupa 2',
            description: 'Opis grupy 2',
            members: [{
                user: user._id,
                role: 'member',
                joined: new Date()
            }]
        });

        await group1.save();
        await group2.save();

        // Pobranie grup użytkownika
        const response = await request(app)
            .get('/api/groups')
            .set('Authorization', `Bearer ${token}`)
            .expect(200);

        // Sprawdzenie odpowiedzi
        expect(response.body.success).toBeTruthy();
        expect(response.body.groups).toBeDefined();
        expect(response.body.groups).toHaveLength(2);
        expect(response.body.groups[0].name).toBeDefined();
        expect(response.body.groups[1].name).toBeDefined();
    });

    // Test pobierania szczegółów grupy
    test('Powinno zwrócić szczegóły grupy', async () => {
        // Stworzenie grupy
        const group = new Group({
            name: 'Grupa szczegółowa',
            description: 'Opis grupy szczegółowej',
            defaultCurrency: 'EUR',
            members: [{
                user: user._id,
                role: 'admin',
                joined: new Date()
            }]
        });

        await group.save();

        // Pobranie szczegółów grupy
        const response = await request(app)
            .get(`/api/groups/${group._id}`)
            .set('Authorization', `Bearer ${token}`)
            .expect(200);

        // Sprawdzenie odpowiedzi
        expect(response.body.success).toBeTruthy();
        expect(response.body.group).toBeDefined();
        expect(response.body.group.name).toBe(group.name);
        expect(response.body.group.description).toBe(group.description);
        expect(response.body.group.defaultCurrency).toBe(group.defaultCurrency);
        expect(response.body.group.members).toHaveLength(1);
    });

    // Test aktualizacji grupy
    test('Powinno zaktualizować dane grupy', async () => {
        // Stworzenie grupy z jawnie ustawionym adminem
        const group = new Group({
            name: 'Stara nazwa',
            description: 'Stary opis',
            defaultCurrency: 'PLN',
            members: [{
                user: user._id,
                role: 'admin',
                joined: new Date()
            }]
        });

        await group.save();

        // Upewnij się, że rola admina jest poprawnie ustawiona
        await Group.findOneAndUpdate(
            { _id: group._id, 'members.user': user._id },
            { $set: { 'members.$.role': 'admin' } }
        );

        // Aktualizacja grupy
        const updateData = {
            name: 'Nowa nazwa',
            description: 'Nowy opis',
            defaultCurrency: 'USD'
        };

        const response = await request(app)
            .put(`/api/groups/${group._id}`)
            .set('Authorization', `Bearer ${token}`)
            .send(updateData)
            .expect(200);

        // Sprawdzenie odpowiedzi
        expect(response.body.success).toBeTruthy();
        expect(response.body.message).toBeDefined();
        expect(response.body.group).toBeDefined();
        expect(response.body.group.name).toBe(updateData.name);
        expect(response.body.group.description).toBe(updateData.description);
        expect(response.body.group.defaultCurrency).toBe(updateData.defaultCurrency);

        // Sprawdzenie, czy grupa została zaktualizowana w bazie
        const groupInDb = await Group.findById(group._id);
        expect(groupInDb.name).toBe(updateData.name);
    });

    // Test dodawania członka do grupy
    test('Powinno dodać nowego członka do grupy', async () => {
        // Stworzenie grupy
        const group = new Group({
            name: 'Grupa dla dodania członka',
            description: 'Opis grupy',
            members: [{
                user: user._id,
                role: 'admin',
                joined: new Date()
            }]
        });

        await group.save();

        // Upewnij się, że rola admina jest poprawnie ustawiona
        await Group.findOneAndUpdate(
            { _id: group._id, 'members.user': user._id },
            { $set: { 'members.$.role': 'admin' } }
        );

        // Dodanie nowego członka
        const response = await request(app)
            .post(`/api/groups/${group._id}/members`)
            .set('Authorization', `Bearer ${token}`)
            .send({
                email: secondUser.email,
                role: 'member'
            })
            .expect(200);

        // Sprawdzenie odpowiedzi
        expect(response.body.success).toBeTruthy();
        expect(response.body.message).toBeDefined();
        expect(response.body.group).toBeDefined();
        expect(response.body.group.members).toHaveLength(2);

        // Sprawdzenie, czy członek został dodany do bazy
        const groupInDb = await Group.findById(group._id);
        expect(groupInDb.members).toHaveLength(2);

        // Sprawdzenie, czy członek jest poprawny
        const newMember = groupInDb.members.find(
            m => m.user.toString() === secondUser._id.toString()
        );
        expect(newMember).toBeDefined();
        expect(newMember.role).toBe('member');
    });

    // Test usuwania członka z grupy
    test('Powinno usunąć członka z grupy', async () => {
        // Stworzenie grupy z dwoma członkami
        const group = new Group({
            name: 'Grupa dla usunięcia członka',
            description: 'Opis grupy',
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

        // Upewnij się, że rola admina jest poprawnie ustawiona
        await Group.findOneAndUpdate(
            { _id: group._id, 'members.user': user._id },
            { $set: { 'members.$.role': 'admin' } }
        );

        // Usunięcie członka
        const response = await request(app)
            .delete(`/api/groups/${group._id}/members/${secondUser._id}`)
            .set('Authorization', `Bearer ${token}`)
            .expect(200);

        // Sprawdzenie odpowiedzi
        expect(response.body.success).toBeTruthy();
        expect(response.body.message).toBeDefined();
        expect(response.body.group).toBeDefined();
        expect(response.body.group.members).toHaveLength(1);

        // Sprawdzenie, czy członek został usunięty z bazy
        const groupInDb = await Group.findById(group._id);
        expect(groupInDb.members).toHaveLength(1);
        expect(groupInDb.members[0].user.toString()).toBe(user._id.toString());
    });

    // Test zmiany roli członka
    test('Powinno zmienić rolę członka w grupie', async () => {
        // Stworzenie grupy z dwoma administratorami
        const group = new Group({
            name: 'Grupa dla zmiany roli',
            description: 'Opis grupy',
            members: [
                {
                    user: user._id,
                    role: 'admin',
                    joined: new Date()
                },
                {
                    user: secondUser._id,
                    role: 'admin',
                    joined: new Date()
                }
            ]
        });

        await group.save();

        // Upewnij się, że role są poprawnie ustawione
        await Group.findOneAndUpdate(
            { _id: group._id, 'members.user': user._id },
            { $set: { 'members.$.role': 'admin' } }
        );

        await Group.findOneAndUpdate(
            { _id: group._id, 'members.user': secondUser._id },
            { $set: { 'members.$.role': 'admin' } }
        );

        // Zmiana roli członka
        const response = await request(app)
            .put(`/api/groups/${group._id}/members/${secondUser._id}`)
            .set('Authorization', `Bearer ${token}`)
            .send({
                role: 'member'
            })
            .expect(200);

        // Sprawdzenie odpowiedzi
        expect(response.body.success).toBeTruthy();
        expect(response.body.message).toBeDefined();
        expect(response.body.group).toBeDefined();

        // Sprawdzenie, czy rola została zmieniona w bazie
        const groupInDb = await Group.findById(group._id);
        const updatedMember = groupInDb.members.find(
            m => m.user.toString() === secondUser._id.toString()
        );
        expect(updatedMember).toBeDefined();
        expect(updatedMember.role).toBe('member');
    });

    // Test archiwizacji grupy
    test('Powinno zarchiwizować grupę', async () => {
        // Stworzenie grupy
        const group = new Group({
            name: 'Grupa do archiwizacji',
            description: 'Opis grupy',
            members: [{
                user: user._id,
                role: 'admin',
                joined: new Date()
            }],
            isArchived: false
        });

        await group.save();

        // Upewnij się, że rola admina jest poprawnie ustawiona
        await Group.findOneAndUpdate(
            { _id: group._id, 'members.user': user._id },
            { $set: { 'members.$.role': 'admin' } }
        );

        // Archiwizacja grupy
        const response = await request(app)
            .put(`/api/groups/${group._id}/archive`)
            .set('Authorization', `Bearer ${token}`)
            .send({
                archive: true
            })
            .expect(200);

        // Sprawdzenie odpowiedzi
        expect(response.body.success).toBeTruthy();
        expect(response.body.message).toBeDefined();
        expect(response.body.group).toBeDefined();
        expect(response.body.group.isArchived).toBe(true);

        // Sprawdzenie, czy grupa została zarchiwizowana w bazie
        const groupInDb = await Group.findById(group._id);
        expect(groupInDb.isArchived).toBe(true);
    });

    // Test usuwania grupy
    test('Powinno usunąć grupę', async () => {
        // Stworzenie grupy
        const group = new Group({
            name: 'Grupa do usunięcia',
            description: 'Opis grupy',
            members: [{
                user: user._id,
                role: 'admin',
                joined: new Date()
            }]
        });

        await group.save();

        // Upewnij się, że rola admina jest poprawnie ustawiona
        await Group.findOneAndUpdate(
            { _id: group._id, 'members.user': user._id },
            { $set: { 'members.$.role': 'admin' } }
        );

        // Usunięcie grupy
        const response = await request(app)
            .delete(`/api/groups/${group._id}`)
            .set('Authorization', `Bearer ${token}`)
            .expect(200);

        // Sprawdzenie odpowiedzi
        expect(response.body.success).toBeTruthy();
        expect(response.body.message).toBeDefined();

        // Sprawdzenie, czy grupa została usunięta z bazy
        const groupInDb = await Group.findById(group._id);
        expect(groupInDb).toBeNull();
    });
});