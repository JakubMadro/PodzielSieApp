const express = require('express');
const groupController = require('../controllers/groupController');
const expenseController = require('../controllers/expenseController');
const settlementController = require('../controllers/settlementController');
const {
    authenticate,
    isGroupMember,
    isGroupAdmin
} = require('../middleware/auth');
const {
    createGroupValidation,
    addGroupMemberValidation,
    validateObjectId
} = require('../middleware/validation');

const router = express.Router();

// Middleware autentykacji dla wszystkich tras grup
router.use(authenticate);

/**
 * @swagger
 * /api/groups:
 *   post:
 *     summary: Tworzenie nowej grupy
 *     tags: [Groups]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - name
 *             properties:
 *               name:
 *                 type: string
 *               description:
 *                 type: string
 *               defaultCurrency:
 *                 type: string
 *     responses:
 *       201:
 *         description: Grupa utworzona pomyślnie
 *       400:
 *         description: Błędne dane wejściowe
 */
router.post('/', createGroupValidation, groupController.createGroup);

/**
 * @swagger
 * /api/groups:
 *   get:
 *     summary: Pobieranie listy grup użytkownika
 *     tags: [Groups]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Lista grup użytkownika
 */
router.get('/', groupController.getUserGroups);

/**
 * @swagger
 * /api/groups/{id}:
 *   get:
 *     summary: Pobieranie szczegółów grupy
 *     tags: [Groups]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         schema:
 *           type: string
 *         required: true
 *         description: ID grupy
 *     responses:
 *       200:
 *         description: Szczegóły grupy
 *       404:
 *         description: Grupa nie została znaleziona
 */
router.get('/:id', validateObjectId('id'), isGroupMember, groupController.getGroupDetails);

/**
 * @swagger
 * /api/groups/{id}:
 *   put:
 *     summary: Aktualizacja grupy
 *     tags: [Groups]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         schema:
 *           type: string
 *         required: true
 *         description: ID grupy
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               name:
 *                 type: string
 *               description:
 *                 type: string
 *               defaultCurrency:
 *                 type: string
 *     responses:
 *       200:
 *         description: Grupa zaktualizowana pomyślnie
 *       403:
 *         description: Brak uprawnień
 *       404:
 *         description: Grupa nie została znaleziona
 */
router.put('/:id', validateObjectId('id'), isGroupMember,isGroupAdmin, groupController.updateGroup);

/**
 * @swagger
 * /api/groups/{id}/members:
 *   post:
 *     summary: Dodawanie nowego członka do grupy
 *     tags: [Groups]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         schema:
 *           type: string
 *         required: true
 *         description: ID grupy
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - email
 *             properties:
 *               email:
 *                 type: string
 *                 format: email
 *               role:
 *                 type: string
 *                 enum: [admin, member]
 *     responses:
 *       200:
 *         description: Członek dodany pomyślnie
 *       404:
 *         description: Użytkownik nie został znaleziony
 *       409:
 *         description: Użytkownik jest już członkiem grupy
 */
router.post('/:id/members', validateObjectId('id'), isGroupMember,isGroupAdmin, addGroupMemberValidation, groupController.addGroupMember);

/**
 * @swagger
 * /api/groups/{id}/members/{userId}:
 *   delete:
 *     summary: Usuwanie członka z grupy
 *     tags: [Groups]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         schema:
 *           type: string
 *         required: true
 *         description: ID grupy
 *       - in: path
 *         name: userId
 *         schema:
 *           type: string
 *         required: true
 *         description: ID użytkownika
 *     responses:
 *       200:
 *         description: Członek usunięty pomyślnie
 *       403:
 *         description: Brak uprawnień
 *       404:
 *         description: Członek nie został znaleziony
 */
router.delete('/:id/members/:userId', validateObjectId('id'), validateObjectId('userId'), groupController.removeGroupMember);

/**
 * @swagger
 * /api/groups/{id}/members/{userId}:
 *   put:
 *     summary: Zmiana roli członka w grupie
 *     tags: [Groups]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         schema:
 *           type: string
 *         required: true
 *         description: ID grupy
 *       - in: path
 *         name: userId
 *         schema:
 *           type: string
 *         required: true
 *         description: ID użytkownika
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - role
 *             properties:
 *               role:
 *                 type: string
 *                 enum: [admin, member]
 *     responses:
 *       200:
 *         description: Rola zaktualizowana pomyślnie
 *       400:
 *         description: Nie można zmienić roli ostatniego administratora
 *       403:
 *         description: Brak uprawnień
 *       404:
 *         description: Członek nie został znaleziony
 */
router.put('/:id/members/:userId', validateObjectId('id'), validateObjectId('userId'),isGroupMember, isGroupAdmin, groupController.updateMemberRole);

/**
 * @swagger
 * /api/groups/{id}/archive:
 *   put:
 *     summary: Archiwizacja / przywracanie grupy
 *     tags: [Groups]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         schema:
 *           type: string
 *         required: true
 *         description: ID grupy
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - archive
 *             properties:
 *               archive:
 *                 type: boolean
 *     responses:
 *       200:
 *         description: Grupa zarchiwizowana/przywrócona pomyślnie
 *       403:
 *         description: Brak uprawnień
 *       404:
 *         description: Grupa nie została znaleziona
 */
router.put('/:id/archive', validateObjectId('id'), isGroupMember,isGroupAdmin, groupController.toggleArchiveGroup);

/**
 * @swagger
 * /api/groups/{id}:
 *   delete:
 *     summary: Usunięcie grupy
 *     tags: [Groups]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         schema:
 *           type: string
 *         required: true
 *         description: ID grupy
 *     responses:
 *       200:
 *         description: Grupa usunięta pomyślnie
 *       403:
 *         description: Brak uprawnień
 *       404:
 *         description: Grupa nie została znaleziona
 */
router.delete('/:id', validateObjectId('id'),isGroupMember, isGroupAdmin, groupController.deleteGroup);

/**
 * @swagger
 * /api/groups/{groupId}/expenses:
 *   get:
 *     summary: Pobieranie wydatków grupy
 *     tags: [Expenses]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: groupId
 *         schema:
 *           type: string
 *         required: true
 *         description: ID grupy
 *       - in: query
 *         name: page
 *         schema:
 *           type: integer
 *         description: Numer strony paginacji
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *         description: Limit wyników na stronę
 *       - in: query
 *         name: sortBy
 *         schema:
 *           type: string
 *         description: Pole do sortowania
 *       - in: query
 *         name: order
 *         schema:
 *           type: string
 *           enum: [asc, desc]
 *         description: Kolejność sortowania
 *     responses:
 *       200:
 *         description: Lista wydatków grupy
 *       403:
 *         description: Brak uprawnień
 *       404:
 *         description: Grupa nie została znaleziona
 */
router.get('/:groupId/expenses', validateObjectId('groupId'), expenseController.getGroupExpenses);

/**
 * @swagger
 * /api/groups/{groupId}/balances:
 *   get:
 *     summary: Pobieranie sald grupy
 *     tags: [Settlements]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: groupId
 *         schema:
 *           type: string
 *         required: true
 *         description: ID grupy
 *     responses:
 *       200:
 *         description: Salda grupy
 *       403:
 *         description: Brak uprawnień
 *       404:
 *         description: Grupa nie została znaleziona
 */
router.get('/:groupId/balances', validateObjectId('groupId'), settlementController.getGroupBalances);

/**
 * @swagger
 * /api/groups/{groupId}/balances/refresh:
 *   post:
 *     summary: Aktualizacja sald grupy
 *     tags: [Settlements]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: groupId
 *         schema:
 *           type: string
 *         required: true
 *         description: ID grupy
 *     responses:
 *       200:
 *         description: Salda zaktualizowane pomyślnie
 *       403:
 *         description: Brak uprawnień
 *       404:
 *         description: Grupa nie została znaleziona
 */
router.post('/:groupId/balances/refresh', validateObjectId('groupId'), settlementController.refreshGroupBalances);

module.exports = router;