// Router do obsługi tras związanych z autoryzacją i autentykacją
const express = require('express');
const userController = require('../controllers/userController');
const { authenticate } = require('../middleware/auth');
const {
    registerValidation,
    loginValidation
} = require('../middleware/validation');

// Utwórz nowy router Express
const router = express.Router();

/**
 * @swagger
 * /api/auth/register:
 *   post:
 *     summary: Rejestracja nowego użytkownika
 *     tags: [Auth]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/CreateUserDto'
 *     responses:
 *       201:
 *         description: Rejestracja zakończona pomyślnie
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
 *                   example: Rejestracja zakończona pomyślnie
 *                 token:
 *                   type: string
 *                   example: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
 *                 refreshToken:
 *                   type: string
 *                   example: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
 *                 user:
 *                   $ref: '#/components/schemas/UserDto'
 *       400:
 *         $ref: '#/components/responses/BadRequest'
 *       409:
 *         description: Konflikt - adres email jest już używany
 */
// Trasa rejestracji nowego użytkownika
router.post('/register', userController.register);

/**
 * @swagger
 * /api/auth/login:
 *   post:
 *     summary: Logowanie użytkownika
 *     tags: [Auth]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/LoginUserDto'
 *     responses:
 *       200:
 *         description: Logowanie zakończone pomyślnie
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
 *                   example: Logowanie zakończone pomyślnie
 *                 token:
 *                   type: string
 *                   example: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
 *                 refreshToken:
 *                   type: string
 *                   example: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
 *                 user:
 *                   $ref: '#/components/schemas/UserDto'
 *       400:
 *         $ref: '#/components/responses/BadRequest'
 *       401:
 *         description: Nieprawidłowe dane logowania
 */
// Trasa logowania użytkownika
router.post('/login', userController.login);

/**
 * @swagger
 * /api/auth/refresh-token:
 *   post:
 *     summary: Odświeżenie tokenu JWT
 *     tags: [Auth]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/RefreshTokenDto'
 *     responses:
 *       200:
 *         description: Token odświeżony pomyślnie
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: true
 *                 token:
 *                   type: string
 *                   example: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
 *                 refreshToken:
 *                   type: string
 *                   example: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
 *       400:
 *         $ref: '#/components/responses/BadRequest'
 *       401:
 *         description: Nieprawidłowy token odświeżający
 */
// Trasa odświeżania tokenu JWT
router.post('/refresh-token', userController.refreshToken);

/**
 * @swagger
 * /api/auth/logout:
 *   post:
 *     summary: Wylogowanie użytkownika
 *     tags: [Auth]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Wylogowanie zakończone pomyślnie
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
 *                   example: Wylogowanie zakończone pomyślnie
 *       401:
 *         $ref: '#/components/responses/Unauthorized'
 */
// Trasa wylogowania użytkownika (wymaga autoryzacji)
router.post('/logout', authenticate, userController.logout);

/**
 * @swagger
 * /api/auth/forgot-password:
 *   post:
 *     summary: Żądanie resetowania hasła
 *     description: Wysyła link do resetowania hasła na podany adres email
 *     tags: [Auth]
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
 *                 description: Adres email użytkownika
 *                 example: user@example.com
 *     responses:
 *       200:
 *         description: Link do resetowania hasła został wysłany (lub email nie istnieje)
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
 *                   example: Jeśli podany adres email istnieje w naszym systemie, zostanie wysłany link do resetowania hasła
 *       400:
 *         $ref: '#/components/responses/BadRequest'
 */
// Trasa żądania resetowania hasła
router.post('/forgot-password', userController.forgotPassword);

/**
 * @swagger
 * /api/auth/reset-password:
 *   post:
 *     summary: Resetowanie hasła
 *     description: Resetuje hasło użytkownika za pomocą tokenu otrzymanego w emailu
 *     tags: [Auth]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - token
 *               - newPassword
 *               - confirmPassword
 *             properties:
 *               token:
 *                 type: string
 *                 description: Token resetowania otrzymany w emailu
 *                 example: a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0u1v2w3x4y5z6
 *               newPassword:
 *                 type: string
 *                 format: password
 *                 description: Nowe hasło (minimum 8 znaków, wielka litera, mała litera, cyfra)
 *                 example: NoweHaslo123
 *               confirmPassword:
 *                 type: string
 *                 format: password
 *                 description: Potwierdzenie nowego hasła
 *                 example: NoweHaslo123
 *     responses:
 *       200:
 *         description: Hasło zostało pomyślnie zresetowane
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
 *                   example: Hasło zostało pomyślnie zresetowane
 *       400:
 *         description: Błąd walidacji lub nieprawidłowy/wygasły token
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
 *                   example: Token resetowania jest nieprawidłowy lub wygasł
 *                 errors:
 *                   type: array
 *                   items:
 *                     type: string
 */
// Trasa resetowania hasła za pomocą tokenu
router.post('/reset-password', userController.resetPassword);

module.exports = router;