const express = require('express');
const settlementController = require('../controllers/settlementController');
const { authenticate } = require('../middleware/auth');
const {
    settleDebtValidation,
    validateObjectId
} = require('../middleware/validation');

const router = express.Router();

// Middleware autentykacji dla wszystkich tras rozliczeń
router.use(authenticate);

/**
 * @swagger
 * /api/settlements/pending:
 *   get:
 *     summary: Pobieranie oczekujących rozliczeń użytkownika
 *     description: Zwraca oczekujące rozliczenia zalogowanego użytkownika
 *     tags: [Settlements]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: page
 *         schema:
 *           type: integer
 *           minimum: 1
 *         description: Numer strony paginacji (domyślnie 1)
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *           minimum: 1
 *           maximum: 100
 *         description: Liczba wyników na stronę (domyślnie 20)
 *     responses:
 *       200:
 *         description: Oczekujące rozliczenia
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: true
 *                 settlements:
 *                   type: array
 *                   items:
 *                     $ref: '#/components/schemas/Settlement'
 *                 pagination:
 *                   $ref: '#/components/schemas/Pagination'
 *       401:
 *         $ref: '#/components/responses/Unauthorized'
 */
router.get('/pending', settlementController.getPendingSettlements);

/**
 * @swagger
 * /api/settlements/completed:
 *   get:
 *     summary: Pobieranie zakończonych rozliczeń użytkownika
 *     description: Zwraca zakończone rozliczenia zalogowanego użytkownika
 *     tags: [Settlements]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: page
 *         schema:
 *           type: integer
 *           minimum: 1
 *         description: Numer strony paginacji (domyślnie 1)
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *           minimum: 1
 *           maximum: 100
 *         description: Liczba wyników na stronę (domyślnie 20)
 *     responses:
 *       200:
 *         description: Zakończone rozliczenia
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: true
 *                 settlements:
 *                   type: array
 *                   items:
 *                     $ref: '#/components/schemas/Settlement'
 *                 pagination:
 *                   $ref: '#/components/schemas/Pagination'
 *       401:
 *         $ref: '#/components/responses/Unauthorized'
 */
router.get('/completed', settlementController.getCompletedSettlements);

/**
 * @swagger
 * /api/settlements/history:
 *   get:
 *     summary: Pobieranie historii rozliczeń użytkownika
 *     description: Zwraca historię zakończonych rozliczeń zalogowanego użytkownika
 *     tags: [Settlements]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: page
 *         schema:
 *           type: integer
 *           minimum: 1
 *         description: Numer strony paginacji (domyślnie 1)
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *           minimum: 1
 *           maximum: 100
 *         description: Liczba wyników na stronę (domyślnie 20)
 *     responses:
 *       200:
 *         description: Historia rozliczeń
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: true
 *                 settlements:
 *                   type: array
 *                   items:
 *                     $ref: '#/components/schemas/Settlement'
 *                 pagination:
 *                   type: object
 *                   properties:
 *                     totalDocs:
 *                       type: integer
 *                       example: 45
 *                     limit:
 *                       type: integer
 *                       example: 20
 *                     totalPages:
 *                       type: integer
 *                       example: 3
 *                     page:
 *                       type: integer
 *                       example: 1
 *                     hasPrevPage:
 *                       type: boolean
 *                       example: false
 *                     hasNextPage:
 *                       type: boolean
 *                       example: true
 *                     prevPage:
 *                       type: integer
 *                       example: null
 *                     nextPage:
 *                       type: integer
 *                       example: 2
 *       401:
 *         $ref: '#/components/responses/Unauthorized'
 */
router.get('/history', settlementController.getSettlementHistory);

/**
 * @swagger
 * /api/settlements/{id}:
 *   get:
 *     summary: Pobieranie szczegółów rozliczenia
 *     description: Zwraca szczegółowe informacje o rozliczeniu (tylko płatnik lub odbiorca)
 *     tags: [Settlements]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         schema:
 *           type: string
 *         required: true
 *         description: ID rozliczenia
 *     responses:
 *       200:
 *         description: Szczegóły rozliczenia
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: true
 *                 settlement:
 *                   $ref: '#/components/schemas/Settlement'
 *       401:
 *         $ref: '#/components/responses/Unauthorized'
 *       403:
 *         description: Brak dostępu do tego rozliczenia
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
 *                   example: Nie masz dostępu do tego rozliczenia
 *       404:
 *         description: Rozliczenie nie zostało znalezione
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
 *                   example: Rozliczenie nie zostało znalezione
 */
router.get('/:id', validateObjectId('id'), settlementController.getSettlementDetails);

/**
 * @swagger
 * /api/settlements/{id}/settle:
 *   post:
 *     summary: Oznaczenie rozliczenia jako zakończone
 *     description: Oznacza rozliczenie jako zakończone (tylko płatnik)
 *     tags: [Settlements]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         schema:
 *           type: string
 *         required: true
 *         description: ID rozliczenia
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - paymentMethod
 *             properties:
 *               paymentMethod:
 *                 type: string
 *                 enum: [manual, paypal, blik, other]
 *                 description: Metoda płatności
 *                 example: blik
 *               paymentReference:
 *                 type: string
 *                 description: Referencja płatności (opcjonalna)
 *                 example: 'BLIK12345'
 *     responses:
 *       200:
 *         description: Dług oznaczony jako spłacony
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
 *                   example: Dług oznaczony jako spłacony
 *                 settlement:
 *                   $ref: '#/components/schemas/Settlement'
 *       400:
 *         description: Rozliczenie już zakończone
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
 *                   example: To rozliczenie zostało już zakończone
 *       401:
 *         $ref: '#/components/responses/Unauthorized'
 *       403:
 *         description: Tylko płatnik może oznaczyć dług jako spłacony
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
 *                   example: Tylko płatnik może oznaczyć dług jako spłacony
 *       404:
 *         description: Rozliczenie nie zostało znalezione
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
 *                   example: Rozliczenie nie zostało znalezione
 */
router.post('/:id/settle', validateObjectId('id'), settleDebtValidation, settlementController.settleDebt);


/**
 * @swagger
 * /api/settlements:
 *   get:
 *     summary: Pobieranie wszystkich rozliczeń użytkownika
 *     description: Zwraca wszystkie rozliczenia zalogowanego użytkownika (zarówno oczekujące jak i zakończone)
 *     tags: [Settlements]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: page
 *         schema:
 *           type: integer
 *           minimum: 1
 *         description: Numer strony paginacji (domyślnie 1)
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *           minimum: 1
 *           maximum: 100
 *         description: Liczba wyników na stronę (domyślnie 20)
 *     responses:
 *       200:
 *         description: Wszystkie rozliczenia użytkownika
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: true
 *                 settlements:
 *                   type: array
 *                   items:
 *                     $ref: '#/components/schemas/Settlement'
 *                 pagination:
 *                   $ref: '#/components/schemas/Pagination'
 *       401:
 *         $ref: '#/components/responses/Unauthorized'
 *   post:
 *     summary: Tworzenie nowego rozliczenia
 *     tags: [Settlements]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - groupId
 *               - toUserId
 *               - amount
 *             properties:
 *               groupId:
 *                 type: string
 *                 description: ID grupy
 *               toUserId:
 *                 type: string
 *                 description: ID użytkownika, któremu płacimy
 *               amount:
 *                 type: number
 *                 description: Kwota rozliczenia
 *               currency:
 *                 type: string
 *                 description: Waluta (opcjonalna, domyślnie waluta grupy)
 *               paymentMethod:
 *                 type: string
 *                 enum: [manual, paypal, blik, other]
 *               paymentReference:
 *                 type: string
 *                 description: Referencja płatności
 *     responses:
 *       201:
 *         description: Rozliczenie utworzone pomyślnie
 */
router.get('/', settlementController.getAllUserSettlements);
router.post('/', settlementController.createSettlement);


module.exports = router;