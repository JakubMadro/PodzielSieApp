// Importy zewnętrznych bibliotek
const bcrypt = require('bcrypt');

// Importy modeli danych
const User = require('../../models/User');
const Group = require('../../models/Group');
const Expense = require('../../models/Expense');

// Importy konfiguracji i serwisów
const { generateToken, generateRefreshToken } = require('../../config/auth');
const userService = require('../services/userService');

// Importy DTO dla walidacji danych wejściowych
const CreateUserDto = require('../dto/request/user/CreateUserDto');
const LoginUserDto = require('../dto/request/user/LoginUserDto');
const UpdateUserDto = require('../dto/request/user/UpdateUserDto');
const ChangePasswordDto = require('../dto/request/user/ChangePasswordDto');
const RefreshTokenDto = require('../dto/request/user/RefreshTokenDto');
const SearchQueryDto = require('../dto/request/user/SearchQueryDto');
const ForgotPasswordDto = require('../dto/request/user/ForgotPasswordDto');
const ResetPasswordDto = require('../dto/request/user/ResetPasswordDto');

// Importy mapperów do konwersji danych
const UserMapper = require('../dto/mappers/UserMapper');
const ActivityMapper = require('../dto/mappers/ActivityMapper');

// Importy narzędzi pomocniczych
const { sendEmailNotification } = require('../../utils/notifications');
const { generateResetToken, hashToken, isTokenValid, generateExpirationDate } = require('../../utils/tokenGenerator');

/**
 * @desc    Rejestracja nowego użytkownika
 * @route   POST /api/auth/register
 * @access  Public
 */
exports.register = async (req, res, next) => {
    try {
        // Utwórz DTO i zwaliduj dane wejściowe z body requestu
        const createUserDto = new CreateUserDto(req.body);
        const validation = createUserDto.validate();

        // Sprawdź czy dane przeszły walidację
        if (!validation.isValid) {
            return res.status(400).json({
                success: false,
                message: 'Błędy walidacji danych',
                errors: validation.errors
            });
        }

        // Sprawdź czy użytkownik o podanym emailu już istnieje w bazie
        const userExists = await User.findOne({ email: createUserDto.email });
        if (userExists) {
            return res.status(409).json({
                success: false,
                message: 'Użytkownik z tym adresem email już istnieje'
            });
        }

        // Utwórz nowy obiekt użytkownika na podstawie zwalidowanych danych
        const user = new User(createUserDto.toEntity());

        // Zapisz użytkownika w bazie danych (hasło zostanie automatycznie zahashowane)
        await user.save();

        // Wygeneruj tokeny JWT do autoryzacji
        const token = generateToken(user);
        const refreshToken = generateRefreshToken(user);

        // Zapisz refresh token w bazie danych dla przyszłych odświeżeń
        user.refreshToken = refreshToken;
        await user.save();

        // Mapuj dane użytkownika do DTO odpowiedzi
        const userDto = UserMapper.toDto(user);

        // Zwróć odpowiedź z danymi użytkownika i tokenami
        res.status(201).json({
            success: true,
            message: 'Rejestracja zakończona pomyślnie',
            ...userDto.getAuthInfo(token, refreshToken)
        });
    } catch (error) {
        // Przekaż błąd do middleware obsługi błędów
        next(error);
    }
};

/**
 * @desc    Logowanie użytkownika
 * @route   POST /api/auth/login
 * @access  Public
 */
exports.login = async (req, res, next) => {
    try {
        // Utwórz DTO i zwaliduj dane logowania z body requestu
        const loginUserDto = new LoginUserDto(req.body);
        const validation = loginUserDto.validate();

        // Sprawdź czy dane logowania są poprawne
        if (!validation.isValid) {
            return res.status(400).json({
                success: false,
                message: 'Błędy walidacji danych',
                errors: validation.errors
            });
        }

        // Poszukaj użytkownika po adresie email
        const user = await User.findOne({ email: loginUserDto.email });
        if (!user) {
            return res.status(401).json({
                success: false,
                message: 'Nieprawidłowy email lub hasło'
            });
        }

        // Sprawdź czy podane hasło jest poprawne
        const isPasswordValid = await user.comparePassword(loginUserDto.password);
        if (!isPasswordValid) {
            return res.status(401).json({
                success: false,
                message: 'Nieprawidłowy email lub hasło'
            });
        }

        // Wygeneruj nowe tokeny JWT dla sesji
        const token = generateToken(user);
        const refreshToken = generateRefreshToken(user);

        // Zapisz nowy refresh token w bazie danych
        user.refreshToken = refreshToken;
        await user.save();

        // Mapuj dane użytkownika do DTO odpowiedzi
        const userDto = UserMapper.toDto(user);

        // Zwróć odpowiedź z danymi użytkownika i tokenami
        res.json({
            success: true,
            message: 'Logowanie zakończone pomyślnie',
            ...userDto.getAuthInfo(token, refreshToken)
        });
    } catch (error) {
        // Przekaż błąd do middleware obsługi błędów
        next(error);
    }
};

/**
 * @desc    Odświeżenie tokenu JWT
 * @route   POST /api/auth/refresh-token
 * @access  Public (z refresh tokenem)
 */
exports.refreshToken = async (req, res, next) => {
    try {
        // Utwórz DTO i zwaliduj dane refresh tokenu
        const refreshTokenDto = new RefreshTokenDto(req.body);
        const validation = refreshTokenDto.validate();

        // Sprawdź czy refresh token został podany
        if (!validation.isValid) {
            return res.status(400).json({
                success: false,
                message: 'Refresh token jest wymagany',
                errors: validation.errors
            });
        }

        // Poszukaj użytkownika po refresh tokenie
        const user = await User.findOne({ refreshToken: refreshTokenDto.refreshToken });
        if (!user) {
            return res.status(401).json({
                success: false,
                message: 'Nieprawidłowy refresh token'
            });
        }

        // Wygeneruj nowe tokeny dla użytkownika
        const newToken = generateToken(user);
        const newRefreshToken = generateRefreshToken(user);

        // Zapisz nowy refresh token w bazie danych
        user.refreshToken = newRefreshToken;
        await user.save();

        // Zwróć nowe tokeny
        res.json({
            success: true,
            token: newToken,
            refreshToken: newRefreshToken
        });
    } catch (error) {
        // Przekaż błąd do middleware obsługi błędów
        next(error);
    }
};

/**
 * @desc    Wylogowanie użytkownika
 * @route   POST /api/auth/logout
 * @access  Private
 */
exports.logout = async (req, res, next) => {
    try {
        // Usuń refresh token z bazy danych aby unieważnić sesję
        req.user.refreshToken = null;
        await req.user.save();

        // Zwróć potwierdzenie wylogowania
        res.json({
            success: true,
            message: 'Wylogowanie zakończone pomyślnie'
        });
    } catch (error) {
        // Przekaż błąd do middleware obsługi błędów
        next(error);
    }
};

/**
 * @desc    Pobieranie danych zalogowanego użytkownika
 * @route   GET /api/users/me
 * @access  Private
 */
exports.getProfile = async (req, res, next) => {
    try {
        // Mapuj dane użytkownika do DTO profilu (bez wrażliwych danych)
        const profileDto = UserMapper.toProfileDto(req.user);

        // Zwróć dane profilu użytkownika
        res.json({
            success: true,
            user: profileDto.toResponse()
        });
    } catch (error) {
        // Przekaż błąd do middleware obsługi błędów
        next(error);
    }
};

/**
 * @desc    Aktualizacja danych użytkownika
 * @route   PUT /api/users/me
 * @access  Private
 */
exports.updateProfile = async (req, res, next) => {
    try {
        // Utwórz DTO i zwaliduj dane wejściowe
        const updateUserDto = new UpdateUserDto(req.body);
        const validation = updateUserDto.validate();

        if (!validation.isValid) {
            return res.status(400).json({
                success: false,
                message: 'Błędy walidacji danych',
                errors: validation.errors
            });
        }

        // Pobierz aktualne dane użytkownika
        const user = await User.findById(req.user._id);

        // Aktualizuj tylko te pola, które zostały przekazane
        const updateData = updateUserDto.toUpdateEntity();

        // Zastosuj aktualizacje do obiektu użytkownika
        Object.assign(user, updateData);

        // Zapisz zaktualizowane dane
        await user.save();

        // Mapuj odpowiedź przy użyciu DTO
        const profileDto = UserMapper.toProfileDto(user);

        res.json({
            success: true,
            message: 'Profil zaktualizowany pomyślnie',
            user: profileDto.toResponse()
        });
    } catch (error) {
        next(error);
    }
};

/**
 * @desc    Zmiana hasła użytkownika
 * @route   PUT /api/users/me/password
 * @access  Private
 */
exports.changePassword = async (req, res, next) => {
    try {
        // Utwórz DTO i zwaliduj dane wejściowe
        const changePasswordDto = new ChangePasswordDto(req.body);
        const validation = changePasswordDto.validate();

        if (!validation.isValid) {
            return res.status(400).json({
                success: false,
                message: 'Błędy walidacji danych',
                errors: validation.errors
            });
        }

        // Pobierz użytkownika z hasłem
        const user = await User.findById(req.user._id);

        // Sprawdź, czy obecne hasło jest poprawne
        const isPasswordValid = await user.comparePassword(changePasswordDto.currentPassword);
        if (!isPasswordValid) {
            return res.status(401).json({
                success: false,
                message: 'Obecne hasło jest nieprawidłowe'
            });
        }

        // Ustaw nowe hasło
        user.password = changePasswordDto.newPassword;

        // Zapisz zmiany
        await user.save();

        res.json({
            success: true,
            message: 'Hasło zostało zmienione pomyślnie'
        });
    } catch (error) {
        next(error);
    }
};

/**
 * @desc    Wyszukiwanie użytkowników (np. do dodania do grupy)
 * @route   GET /api/users/search
 * @access  Private
 */
exports.searchUsers = async (req, res, next) => {
    try {
        // Utwórz DTO i zwaliduj dane wejściowe
        const searchQueryDto = new SearchQueryDto(req.query);
        const validation = searchQueryDto.validate();

        if (!validation.isValid) {
            return res.status(400).json({
                success: false,
                message: 'Błędy walidacji danych',
                errors: validation.errors
            });
        }

        // Wyszukiwanie użytkowników po email, imieniu lub nazwisku
        const users = await userService.searchUsers(searchQueryDto.query, req.user._id);

        // Mapuj wyniki przy użyciu DTO
        const userDtos = UserMapper.toBasicInfoList(users);

        res.json({
            success: true,
            users: userDtos
        });
    } catch (error) {
        next(error);
    }
};

/**
 * @desc    Usunięcie konta użytkownika
 * @route   DELETE /api/users/me
 * @access  Private
 */
exports.deleteAccount = async (req, res, next) => {
    try {
        // W rzeczywistej aplikacji należałoby sprawdzić, czy użytkownik ma nierozliczone długi
        // oraz obsłużyć jego członkostwo w grupach

        // Usunięcie użytkownika
        await User.findByIdAndDelete(req.user._id);

        res.json({
            success: true,
            message: 'Konto zostało usunięte pomyślnie'
        });
    } catch (error) {
        next(error);
    }
};

/**
 * @desc    Pobieranie ostatnich aktywności użytkownika
 * @route   GET /api/users/activities
 * @access  Private
 */
exports.getUserActivities = async (req, res, next) => {
    try {
        const { limit = 10 } = req.query;
        const limitNum = parseInt(limit, 10);

        // Pobierz grupy użytkownika
        const groups = await Group.find({
            'members.user': req.user._id
        }).select('_id name defaultCurrency');

        // Pobierz wydatki ze wszystkich grup użytkownika
        const expenses = await Expense.find({
            group: { $in: groups.map(g => g._id) }
        })
            .populate('paidBy', 'firstName lastName email')
            .populate('group', 'name')
            .sort({ date: -1 })
            .limit(limitNum);

        // Przekształć wydatki na aktywności przy użyciu mappera
        const activities = ActivityMapper.fromExpenses(expenses, req.user._id);

        // Posortuj i ogranicz liczbę
        const sortedActivities = activities.sort((a, b) => b.date - a.date).slice(0, limitNum);

        res.json({
            success: true,
            activities: sortedActivities
        });
    } catch (error) {
        next(error);
    }
};

/**
 * @desc    Żądanie resetowania hasła
 * @route   POST /api/auth/forgot-password
 * @access  Public
 */
exports.forgotPassword = async (req, res, next) => {
    try {
        // Utwórz DTO i zwaliduj dane wejściowe
        const forgotPasswordDto = new ForgotPasswordDto(req.body);
        const validation = forgotPasswordDto.validate();

        if (!validation.isValid) {
            return res.status(400).json({
                success: false,
                message: 'Błędy walidacji danych',
                errors: validation.errors
            });
        }

        // Sprawdź, czy użytkownik istnieje
        const user = await User.findOne({ email: forgotPasswordDto.email });
        
        // Zawsze zwracamy sukces ze względów bezpieczeństwa
        // (nie ujawniamy czy email istnieje w systemie)
        if (!user) {
            return res.json({
                success: true,
                message: 'Jeśli podany adres email istnieje w naszym systemie, zostanie wysłany link do resetowania hasła'
            });
        }

        // Generuj 6-cyfrowy kod weryfikacyjny
        const resetCode = generateResetToken();
        const hashedCode = hashToken(resetCode);
        const expirationDate = generateExpirationDate(15); // 15 minut

        // Zapisz kod w bazie danych
        user.passwordResetToken = hashedCode;
        user.passwordResetExpires = expirationDate;
        await user.save();

        // Wyślij email z kodem weryfikacyjnym
        const emailSubject = 'Kod resetowania hasła - DzielSie App';
        const emailText = `
Otrzymaliśmy żądanie resetowania hasła dla Twojego konta.

Twój kod weryfikacyjny to: ${resetCode}

Kod jest ważny przez 15 minut.

Jeśli nie żądałeś resetowania hasła, zignoruj tę wiadomość.
        `.trim();

        const emailData = {
            type: 'PASSWORD_RESET',
            resetCode: resetCode,
            expiresIn: '15 minut'
        };

        await sendEmailNotification(user.email, emailSubject, emailText, emailData);

        res.json({
            success: true,
            message: 'Jeśli podany adres email istnieje w naszym systemie, zostanie wysłany link do resetowania hasła'
        });
    } catch (error) {
        console.error('Błąd podczas żądania resetowania hasła:', error);
        next(error);
    }
};

/**
 * @desc    Resetowanie hasła
 * @route   POST /api/auth/reset-password
 * @access  Public
 */
exports.resetPassword = async (req, res, next) => {
    try {
        // Utwórz DTO i zwaliduj dane wejściowe
        const resetPasswordDto = new ResetPasswordDto(req.body);
        const validation = resetPasswordDto.validate();

        if (!validation.isValid) {
            return res.status(400).json({
                success: false,
                message: 'Błędy walidacji danych',
                errors: validation.errors
            });
        }

        // Zahashuj kod z requestu
        const hashedCode = hashToken(resetPasswordDto.token);

        // Znajdź użytkownika z tym kodem
        const user = await User.findOne({
            passwordResetToken: hashedCode,
            passwordResetExpires: { $gt: new Date() } // Kod nie wygasł
        });

        if (!user) {
            return res.status(400).json({
                success: false,
                message: 'Kod weryfikacyjny jest nieprawidłowy lub wygasł'
            });
        }

        // Sprawdź ponownie czy kod nie wygasł (dodatkowa walidacja)
        if (!isTokenValid(user.passwordResetExpires)) {
            return res.status(400).json({
                success: false,
                message: 'Kod weryfikacyjny wygasł'
            });
        }

        // Ustaw nowe hasło
        user.password = resetPasswordDto.newPassword;
        
        // Usuń kod resetowania
        user.passwordResetToken = undefined;
        user.passwordResetExpires = undefined;
        
        // Unieważnij wszystkie sesje (usuń refresh token)
        user.refreshToken = null;

        // Zapisz zmiany (hasło zostanie automatycznie zahashowane przez pre('save'))
        await user.save();

        // Wyślij potwierdzenie na email
        const emailSubject = 'Hasło zostało zmienione - DzielSie App';
        const emailText = `
Twoje hasło zostało pomyślnie zmienione.

Jeśli to nie Ty zmieniałeś hasło, natychmiast skontaktuj się z naszym wsparciem.

Dla bezpieczeństwa wszystkie aktywne sesje zostały zakończone.
        `.trim();

        await sendEmailNotification(user.email, emailSubject, emailText, {
            type: 'PASSWORD_CHANGED'
        });

        res.json({
            success: true,
            message: 'Hasło zostało pomyślnie zresetowane'
        });
    } catch (error) {
        console.error('Błąd podczas resetowania hasła:', error);
        next(error);
    }
};