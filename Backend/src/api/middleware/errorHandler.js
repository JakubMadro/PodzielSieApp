/**
 * Middleware do globalnej obsługi błędów w aplikacji
 * Formatuje błędy i zwraca odpowiednią odpowiedź HTTP
 */
const errorHandler = (err, req, res, next) => {
    // Domyślny status błędu
    let statusCode = res.statusCode === 200 ? 500 : res.statusCode;
    let message = err.message || 'Wystąpił nieoczekiwany błąd';
    let errors = [];

    console.error(`[ERROR] ${err.stack}`);

    // Obsługa błędów walidacji Mongoose
    if (err.name === 'ValidationError') {
        statusCode = 400;

        // Pobierz wszystkie błędy walidacji z Mongoose
        Object.keys(err.errors).forEach((key) => {
            errors.push({
                field: key,
                message: err.errors[key].message
            });
        });
    }

    // Obsługa błędów castowania Mongoose (np. nieprawidłowy ID)
    if (err.name === 'CastError') {
        statusCode = 400;
        message = `Nieprawidłowy format pola ${err.path}`;
    }

    // Obsługa błędów duplikacji Mongoose (unique index violation)
    if (err.code === 11000) {
        statusCode = 409;
        const field = Object.keys(err.keyValue)[0];
        message = `Podany ${field} jest już używany`;
        errors.push({
            field,
            message: `Wartość '${err.keyValue[field]}' jest już używana`
        });
    }

    // Obsługa błędów JWT
    if (err.name === 'JsonWebTokenError') {
        statusCode = 401;
        message = 'Nieprawidłowy token uwierzytelniający';
    }

    // Obsługa wygaśnięcia tokenu JWT
    if (err.name === 'TokenExpiredError') {
        statusCode = 401;
        message = 'Token uwierzytelniający wygasł';
    }

    // Obsługa błędów multer (upload plików)
    if (err.code === 'LIMIT_FILE_SIZE') {
        statusCode = 400;
        message = 'Plik jest zbyt duży';
    }

    if (err.code === 'LIMIT_UNEXPECTED_FILE') {
        statusCode = 400;
        message = 'Nieprawidłowy typ pliku';
    }

    // Przygotuj obiekt odpowiedzi
    const errorResponse = {
        success: false,
        message,
        ...(errors.length > 0 && { errors }),
        ...(process.env.NODE_ENV === 'development' && { stack: err.stack })
    };

    // Wyślij odpowiedź
    res.status(statusCode).json(errorResponse);
};

module.exports = errorHandler;