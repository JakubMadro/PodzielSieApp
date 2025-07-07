// Import biblioteki express-validator do walidacji danych
const { body, param, validationResult } = require('express-validator');

/**
 * Ogólna funkcja sprawdzająca wyniki walidacji
 */
const validate = (req, res, next) => {
    // Pobierz wyniki walidacji z express-validator
    const errors = validationResult(req);

    // Jeśli są błędy walidacji, zwróć odpowiedź z błędami
    if (!errors.isEmpty()) {
        return res.status(400).json({
            success: false,
            message: 'Błędy walidacji danych',
            errors: errors.array().map(err => ({
                field: err.param,    // Nazwa pola z błędem
                message: err.msg     // Komunikat błędu
            }))
        });
    }

    // Jeśli walidacja przeszła pomyślnie, przejdź dalej
    next();
};

/**
 * Walidacja dla rejestracji użytkownika
 */
const registerValidation = [
    body('email')
        .isEmail().withMessage('Podaj prawidłowy adres email')
        .normalizeEmail(),

    body('password')
        .isLength({ min: 6 }).withMessage('Hasło musi mieć co najmniej 6 znaków')
        .matches(/\d/).withMessage('Hasło musi zawierać co najmniej jedną cyfrę'),

    body('firstName')
        .notEmpty().withMessage('Imię jest wymagane')
        .trim()
        .isLength({ min: 2 }).withMessage('Imię musi mieć co najmniej 2 znaki'),

    body('lastName')
        .notEmpty().withMessage('Nazwisko jest wymagane')
        .trim()
        .isLength({ min: 2 }).withMessage('Nazwisko musi mieć co najmniej 2 znaki'),

    body('phoneNumber')
        .optional()
        .isMobilePhone('any').withMessage('Podaj prawidłowy numer telefonu'),

    validate
];

/**
 * Walidacja dla logowania użytkownika
 */
const loginValidation = [
    body('email')
        .isEmail().withMessage('Podaj prawidłowy adres email')
        .normalizeEmail(),

    body('password')
        .notEmpty().withMessage('Hasło jest wymagane'),

    validate
];

/**
 * Walidacja dla tworzenia grupy
 */
const createGroupValidation = [
    body('name')
        .notEmpty().withMessage('Nazwa grupy jest wymagana')
        .trim()
        .isLength({ min: 3 }).withMessage('Nazwa grupy musi mieć co najmniej 3 znaki'),

    body('description')
        .optional()
        .trim(),

    body('defaultCurrency')
        .optional()
        .isISO4217().withMessage('Podaj prawidłowy kod waluty')
        .default('PLN'),

    validate
];

/**
 * Walidacja dla dodawania członków grupy
 */
const addGroupMemberValidation = [
    body('email')
        .isEmail().withMessage('Podaj prawidłowy adres email')
        .normalizeEmail(),

    body('role')
        .optional()
        .isIn(['admin', 'member']).withMessage('Rola musi być jedną z: admin, member')
        .default('member'),

    validate
];

/**
 * Walidacja dla tworzenia wydatku
 */
const createExpenseValidation = [
    body('group')
        .notEmpty().withMessage('ID grupy jest wymagane')
        .isMongoId().withMessage('Nieprawidłowy format ID grupy'),

    body('description')
        .notEmpty().withMessage('Opis wydatku jest wymagany')
        .trim()
        .isLength({ min: 3 }).withMessage('Opis musi mieć co najmniej 3 znaki'),

    body('amount')
        .notEmpty().withMessage('Kwota jest wymagana')
        .isFloat({ min: 0.01 }).withMessage('Kwota musi być liczbą większą od 0'),

    body('currency')
        .optional()
        .isISO4217().withMessage('Podaj prawidłowy kod waluty')
        .default('PLN'),

    body('paidBy')
        .notEmpty().withMessage('ID płatnika jest wymagane')
        .isMongoId().withMessage('Nieprawidłowy format ID płatnika'),

    body('date')
        .optional()
        .isISO8601().withMessage('Data musi być w formacie ISO 8601')
        .toDate(),

    body('category')
        .optional()
        .isIn(['food', 'transport', 'accommodation', 'entertainment', 'utilities', 'other'])
        .withMessage('Kategoria musi być jedną z: food, transport, accommodation, entertainment, utilities, other')
        .default('other'),

    body('splitType')
        .optional()
        .isIn(['equal', 'percentage', 'exact', 'shares'])
        .withMessage('Typ podziału musi być jednym z: equal, percentage, exact, shares')
        .default('equal'),

    body('splits')
        .isArray().withMessage('Podział musi być tablicą'),

    body('splits.*.user')
        .notEmpty().withMessage('ID użytkownika jest wymagane')
        .isMongoId().withMessage('Nieprawidłowy format ID użytkownika'),

    body('splits.*.amount')
        .notEmpty().withMessage('Kwota jest wymagana')
        .isFloat({ min: 0 }).withMessage('Kwota musi być liczbą większą lub równą 0'),

    body('splits.*.percentage')
        .optional()
        .isFloat({ min: 0, max: 100 }).withMessage('Procent musi być liczbą między 0 a 100'),

    body('splits.*.shares')
        .optional()
        .isInt({ min: 0 }).withMessage('Liczba udziałów musi być liczbą całkowitą większą lub równą 0'),

    validate
];

/**
 * Walidacja dla rozliczenia długu
 */
const settleDebtValidation = [
    body('paymentMethod')
        .notEmpty().withMessage('Metoda płatności jest wymagana')
        .isIn(['manual', 'paypal', 'blik', 'other'])
        .withMessage('Metoda płatności musi być jedną z: manual, paypal, blik, other'),

    body('paymentReference')
        .optional()
        .trim(),

    validate
];

/**
 * Walidacja ID w parametrach URL
 */
const validateObjectId = (paramName) => [
    param(paramName)
        .isMongoId().withMessage(`Nieprawidłowy format ID ${paramName}`),

    validate
];

module.exports = {
    validate,
    registerValidation,
    loginValidation,
    createGroupValidation,
    addGroupMemberValidation,
    createExpenseValidation,
    settleDebtValidation,
    validateObjectId
};