const express = require('express');
const userController = require('../controllers/userController');
const { authenticate } = require('../middleware/auth');

const router = express.Router();

// Wszystkie trasy poniżej wymagają uwierzytelnienia
router.use(authenticate);

/**
 * @swagger
 * /api/users/me:
 *   get:
 *     summary: Pobieranie danych zalogowanego użytkownika
 *     tags: [Users]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Dane użytkownika pobrane pomyślnie
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: true
 *                 user:
 *                   $ref: '#/components/schemas/UserProfileDto'
 *       401:
 *         $ref: '#/components/responses/Unauthorized'
 */
router.get('/me', userController.getProfile);

/**
 * @swagger
 * /api/users/me:
 *   put:
 *     summary: Aktualizacja danych użytkownika
 *     tags: [Users]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/UpdateUserDto'
 *     responses:
 *       200:
 *         description: Dane użytkownika zaktualizowane pomyślnie
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
 *                   example: Profil zaktualizowany pomyślnie
 *                 user:
 *                   $ref: '#/components/schemas/UserProfileDto'
 *       400:
 *         $ref: '#/components/responses/BadRequest'
 *       401:
 *         $ref: '#/components/responses/Unauthorized'
 */
router.put('/me', userController.updateProfile);

/**
 * @swagger
 * /api/users/me/password:
 *   put:
 *     summary: Zmiana hasła użytkownika
 *     tags: [Users]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/ChangePasswordDto'
 *     responses:
 *       200:
 *         description: Hasło zmienione pomyślnie
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
 *                   example: Hasło zostało zmienione pomyślnie
 *       400:
 *         $ref: '#/components/responses/BadRequest'
 *       401:
 *         description: Nieprawidłowe obecne hasło
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
 *                   example: Obecne hasło jest nieprawidłowe
 */
router.put('/me/password', userController.changePassword);

/**
 * @swagger
 * /api/users/search:
 *   get:
 *     summary: Wyszukiwanie użytkowników
 *     description: Wyszukiwanie użytkowników po email, imieniu lub nazwisku, np. do dodania do grupy
 *     tags: [Users]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: query
 *         schema:
 *           type: string
 *         required: true
 *         description: Ciąg wyszukiwania (minimum 3 znaki)
 *         example: kowalski
 *     responses:
 *       200:
 *         description: Lista użytkowników spełniających kryteria wyszukiwania
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: true
 *                 users:
 *                   type: array
 *                   items:
 *                     $ref: '#/components/schemas/UserDto'
 *       400:
 *         $ref: '#/components/responses/BadRequest'
 *       401:
 *         $ref: '#/components/responses/Unauthorized'
 */
router.get('/search', userController.searchUsers);

/**
 * @swagger
 * /api/users/me:
 *   delete:
 *     summary: Usunięcie konta użytkownika
 *     tags: [Users]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Konto użytkownika usunięte pomyślnie
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
 *                   example: Konto zostało usunięte pomyślnie
 *       401:
 *         $ref: '#/components/responses/Unauthorized'
 */
router.delete('/me', userController.deleteAccount);

/**
 * @swagger
 * /api/users/activities:
 *   get:
 *     summary: Pobieranie ostatnich aktywności użytkownika
 *     description: Zwraca listę ostatnich aktywności użytkownika ze wszystkich jego grup
 *     tags: [Users]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *           minimum: 1
 *           maximum: 50
 *         description: Maksymalna liczba aktywności do zwrócenia (domyślnie 10)
 *     responses:
 *       200:
 *         description: Lista aktywności użytkownika
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: true
 *                 activities:
 *                   type: array
 *                   items:
 *                     type: object
 *                     properties:
 *                       id:
 *                         type: string
 *                       type:
 *                         type: string
 *                         enum: [newExpense, addedToGroup, settledExpense, groupCreated, memberAdded]
 *                       title:
 *                         type: string
 *                       subtitle:
 *                         type: string
 *                       amount:
 *                         type: number
 *                       currency:
 *                         type: string
 *                       date:
 *                         type: string
 *                         format: date-time
 *                       iconName:
 *                         type: string
 *                       groupId:
 *                         type: string
 *                       expenseId:
 *                         type: string
 *       401:
 *         $ref: '#/components/responses/Unauthorized'
 */
router.get('/activities', userController.getUserActivities);

module.exports = router;