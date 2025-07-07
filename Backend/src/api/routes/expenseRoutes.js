const express = require('express');
const expenseController = require('../controllers/expenseController');
const { authenticate } = require('../middleware/auth');
const {
    createExpenseValidation,
    validateObjectId
} = require('../middleware/validation');

const router = express.Router();

// Middleware autentykacji dla wszystkich tras wydatków
router.use(authenticate);

/**
 * @swagger
 * /api/expenses:
 *   post:
 *     summary: Tworzenie nowego wydatku
 *     description: Tworzy nowy wydatek w grupie wraz z podziałem kosztów między użytkowników
 *     tags: [Expenses]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - group
 *               - description
 *               - amount
 *               - paidBy
 *               - splits
 *             properties:
 *               group:
 *                 type: string
 *                 description: ID grupy, w której tworzony jest wydatek
 *                 example: 60d21b4667d0d8992e610c86
 *               description:
 *                 type: string
 *                 description: Opis wydatku
 *                 example: Zakupy spożywcze
 *               amount:
 *                 type: number
 *                 format: float
 *                 description: Kwota wydatku
 *                 example: 157.80
 *               currency:
 *                 type: string
 *                 description: Waluta wydatku (domyślnie waluta grupy)
 *                 example: PLN
 *               paidBy:
 *                 type: string
 *                 description: ID użytkownika, który zapłacił
 *                 example: 60d21b4667d0d8992e610c85
 *               date:
 *                 type: string
 *                 format: date-time
 *                 description: Data wydatku (domyślnie aktualna data)
 *                 example: 2023-08-15T14:30:00Z
 *               category:
 *                 type: string
 *                 enum: [food, transport, accommodation, entertainment, utilities, other]
 *                 description: Kategoria wydatku
 *                 example: food
 *               splitType:
 *                 type: string
 *                 enum: [equal, percentage, exact, shares]
 *                 description: Sposób podziału wydatku
 *                 example: equal
 *               splits:
 *                 type: array
 *                 description: Podział wydatku między użytkowników
 *                 items:
 *                   type: object
 *                   required:
 *                     - user
 *                     - amount
 *                   properties:
 *                     user:
 *                       type: string
 *                       description: ID użytkownika
 *                       example: 60d21b4667d0d8992e610c85
 *                     amount:
 *                       type: number
 *                       format: float
 *                       description: Kwota przypadająca na użytkownika
 *                       example: 52.60
 *                     percentage:
 *                       type: number
 *                       format: float
 *                       description: Procent kwoty przypadający na użytkownika
 *                       example: 33.33
 *                     shares:
 *                       type: integer
 *                       description: Liczba udziałów przypadających na użytkownika
 *                       example: 2
 *               flags:
 *                 type: array
 *                 description: Oznaczenia wydatku
 *                 items:
 *                   type: string
 *                   enum: [pending, urgent, disputed]
 *                 example: ['pending']
 *     responses:
 *       201:
 *         description: Wydatek utworzony pomyślnie
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: true
 *                 message:
 *                   type: string
 *                   example: Wydatek utworzony pomyślnie
 *                 expense:
 *                   $ref: '#/components/schemas/Expense'
 *       400:
 *         description: Błędne dane wejściowe lub błąd walidacji podziału kosztów
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: false
 *                 message:
 *                   type: string
 *                   example: Suma kwot podziału musi być równa kwocie całkowitej
 *       401:
 *         $ref: '#/components/responses/Unauthorized'
 *       403:
 *         description: Brak uprawnień do operacji
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: false
 *                 message:
 *                   type: string
 *                   example: Nie jesteś członkiem tej grupy
 *       404:
 *         description: Grupa nie została znaleziona
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: false
 *                 message:
 *                   type: string
 *                   example: Grupa nie została znaleziona
 */
router.post('/', createExpenseValidation, expenseController.createExpense);

/**
 * @swagger
 * /api/expenses/{id}:
 *   get:
 *     summary: Pobieranie szczegółów wydatku
 *     description: Zwraca szczegółowe informacje o wydatku wraz z komentarzami
 *     tags: [Expenses]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         schema:
 *           type: string
 *         required: true
 *         description: ID wydatku
 *     responses:
 *       200:
 *         description: Szczegóły wydatku
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: true
 *                 expense:
 *                   $ref: '#/components/schemas/Expense'
 *       401:
 *         $ref: '#/components/responses/Unauthorized'
 *       403:
 *         description: Brak dostępu do wydatku
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: false
 *                 message:
 *                   type: string
 *                   example: Nie masz dostępu do tego wydatku
 *       404:
 *         description: Wydatek nie został znaleziony
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: false
 *                 message:
 *                   type: string
 *                   example: Wydatek nie został znaleziony
 */
router.get('/:id', validateObjectId('id'), expenseController.getExpenseDetails);

/**
 * @swagger
 * /api/expenses/{id}:
 *   put:
 *     summary: Aktualizacja wydatku
 *     description: Aktualizuje dane wydatku (tylko twórca wydatku lub admin grupy)
 *     tags: [Expenses]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         schema:
 *           type: string
 *         required: true
 *         description: ID wydatku
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               description:
 *                 type: string
 *                 description: Opis wydatku
 *                 example: Zakupy spożywcze w Biedronce
 *               amount:
 *                 type: number
 *                 format: float
 *                 description: Kwota wydatku
 *                 example: 162.50
 *               currency:
 *                 type: string
 *                 description: Waluta wydatku
 *                 example: PLN
 *               paidBy:
 *                 type: string
 *                 description: ID użytkownika, który zapłacił
 *                 example: 60d21b4667d0d8992e610c85
 *               date:
 *                 type: string
 *                 format: date-time
 *                 description: Data wydatku
 *                 example: 2023-08-15T14:30:00Z
 *               category:
 *                 type: string
 *                 enum: [food, transport, accommodation, entertainment, utilities, other]
 *                 description: Kategoria wydatku
 *                 example: food
 *               splitType:
 *                 type: string
 *                 enum: [equal, percentage, exact, shares]
 *                 description: Sposób podziału wydatku
 *                 example: exact
 *               splits:
 *                 type: array
 *                 description: Podział wydatku między użytkowników
 *                 items:
 *                   type: object
 *                   properties:
 *                     user:
 *                       type: string
 *                       description: ID użytkownika
 *                       example: 60d21b4667d0d8992e610c85
 *                     amount:
 *                       type: number
 *                       format: float
 *                       description: Kwota przypadająca na użytkownika
 *                       example: 54.17
 *                     percentage:
 *                       type: number
 *                       format: float
 *                       description: Procent kwoty przypadający na użytkownika
 *                       example: 33.33
 *                     shares:
 *                       type: integer
 *                       description: Liczba udziałów przypadających na użytkownika
 *                       example: 2
 *               flags:
 *                 type: array
 *                 description: Oznaczenia wydatku
 *                 items:
 *                   type: string
 *                   enum: [pending, urgent, disputed]
 *                 example: ['urgent']
 *     responses:
 *       200:
 *         description: Wydatek zaktualizowany pomyślnie
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: true
 *                 message:
 *                   type: string
 *                   example: Wydatek zaktualizowany pomyślnie
 *                 expense:
 *                   $ref: '#/components/schemas/Expense'
 *       400:
 *         description: Błędne dane wejściowe lub błąd walidacji podziału kosztów
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: false
 *                 message:
 *                   type: string
 *                   example: Suma kwot podziału musi być równa kwocie całkowitej
 *       401:
 *         $ref: '#/components/responses/Unauthorized'
 *       403:
 *         description: Brak uprawnień do edycji
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: false
 *                 message:
 *                   type: string
 *                   example: Nie masz uprawnień do edycji tego wydatku
 *       404:
 *         description: Wydatek nie został znaleziony
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: false
 *                 message:
 *                   type: string
 *                   example: Wydatek nie został znaleziony
 */
router.put('/:id', validateObjectId('id'), expenseController.updateExpense);

/**
 * @swagger
 * /api/expenses/{id}:
 *   delete:
 *     summary: Usuwanie wydatku
 *     description: Usuwa wydatek (tylko twórca wydatku lub admin grupy)
 *     tags: [Expenses]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         schema:
 *           type: string
 *         required: true
 *         description: ID wydatku
 *     responses:
 *       200:
 *         description: Wydatek usunięty pomyślnie
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: true
 *                 message:
 *                   type: string
 *                   example: Wydatek usunięty pomyślnie
 *       401:
 *         $ref: '#/components/responses/Unauthorized'
 *       403:
 *         description: Brak uprawnień do usunięcia
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: false
 *                 message:
 *                   type: string
 *                   example: Nie masz uprawnień do usunięcia tego wydatku
 *       404:
 *         description: Wydatek nie został znaleziony
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: false
 *                 message:
 *                   type: string
 *                   example: Wydatek nie został znaleziony
 */
router.delete('/:id', validateObjectId('id'), expenseController.deleteExpense);

/**
 * @swagger
 * /api/expenses/{id}/comments:
 *   post:
 *     summary: Dodawanie komentarza do wydatku
 *     description: Dodaje komentarz do wydatku (tylko członkowie grupy)
 *     tags: [Expenses]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         schema:
 *           type: string
 *         required: true
 *         description: ID wydatku
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - text
 *             properties:
 *               text:
 *                 type: string
 *                 description: Treść komentarza
 *                 example: Proszę o dodanie zdjęcia paragonu.
 *     responses:
 *       201:
 *         description: Komentarz dodany pomyślnie
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: true
 *                 message:
 *                   type: string
 *                   example: Komentarz dodany pomyślnie
 *                 comment:
 *                   type: object
 *                   properties:
 *                     user:
 *                       type: object
 *                       properties:
 *                         _id:
 *                           type: string
 *                           example: 60d21b4667d0d8992e610c85
 *                         firstName:
 *                           type: string
 *                           example: Jan
 *                         lastName:
 *                           type: string
 *                           example: Kowalski
 *                         email:
 *                           type: string
 *                           example: jan.kowalski@example.com
 *                         avatar:
 *                           type: string
 *                           example: /uploads/avatars/default.png
 *                     text:
 *                       type: string
 *                       example: Proszę o dodanie zdjęcia paragonu.
 *                     createdAt:
 *                       type: string
 *                       format: date-time
 *                       example: 2023-08-16T10:15:00Z
 *       401:
 *         $ref: '#/components/responses/Unauthorized'
 *       403:
 *         description: Brak dostępu do wydatku
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: false
 *                 message:
 *                   type: string
 *                   example: Nie masz dostępu do tego wydatku
 *       404:
 *         description: Wydatek nie został znaleziony
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: false
 *                 message:
 *                   type: string
 *                   example: Wydatek nie został znaleziony
 */
router.post('/:id/comments', validateObjectId('id'), expenseController.addComment);

/**
 * @swagger
 * /api/expenses/{id}/receipt:
 *   post:
 *     summary: Dodawanie zdjęcia paragonu do wydatku
 *     description: Dodaje zdjęcie paragonu do wydatku (tylko twórca wydatku lub admin grupy)
 *     tags: [Expenses]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         schema:
 *           type: string
 *         required: true
 *         description: ID wydatku
 *     requestBody:
 *       required: true
 *       content:
 *         multipart/form-data:
 *           schema:
 *             type: object
 *             required:
 *               - receipt
 *             properties:
 *               receipt:
 *                 type: string
 *                 format: binary
 *                 description: Plik zdjęcia paragonu (max 5MB, tylko obrazy)
 *     responses:
 *       200:
 *         description: Paragon dodany pomyślnie
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: true
 *                 message:
 *                   type: string
 *                   example: Paragon dodany pomyślnie
 *                 receipt:
 *                   type: string
 *                   example: /uploads/receipts/receipt-123.jpg
 *       400:
 *         description: Błędny format pliku lub za duży plik
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: false
 *                 message:
 *                   type: string
 *                   example: Można przesyłać tylko pliki graficzne
 *       401:
 *         $ref: '#/components/responses/Unauthorized'
 *       403:
 *         description: Brak uprawnień do edycji
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: false
 *                 message:
 *                   type: string
 *                   example: Nie masz uprawnień do edycji tego wydatku
 *       404:
 *         description: Wydatek nie został znaleziony
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: false
 *                 message:
 *                   type: string
 *                   example: Wydatek nie został znaleziony
 */
router.post('/:id/receipt', validateObjectId('id'), expenseController.uploadReceipt);

module.exports = router;