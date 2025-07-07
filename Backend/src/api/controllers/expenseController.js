// Importy modeli danych
const Expense = require('../../models/Expense');
const Group = require('../../models/Group');
const User = require('../../models/User');

// Importy serwisów biznesowych
const expenseService = require('../services/expenseService');
const settlementService = require('../services/settlementService');

// Importy narzędzi pomocniczych
const { sendNotification } = require('../../utils/notifications');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const { v4: uuidv4 } = require('uuid');

/**
 * @desc    Tworzenie nowego wydatku
 * @route   POST /api/expenses
 * @access  Private
 */
exports.createExpense = async (req, res, next) => {
    try {
        // Wyodrębnij dane wydatku z body requestu
        const {
            group: groupId,
            description,
            amount,
            currency,
            paidBy,
            date,
            category,
            splitType,
            splits,
            flags
        } = req.body;

        // Sprawdź czy grupa o podanym ID istnieje
        const group = await Group.findById(groupId);
        if (!group) {
            return res.status(404).json({
                success: false,
                message: 'Grupa nie została znaleziona'
            });
        }

        // Zweryfikuj czy użytkownik jest członkiem tej grupy
        const isMember = group.members.some(
            member => member.user.toString() === req.user._id.toString()
        );

        if (!isMember) {
            return res.status(403).json({
                success: false,
                message: 'Nie jesteś członkiem tej grupy'
            });
        }

        // Sprawdź, czy płatnik jest członkiem grupy
        const isPaidByMember = group.members.some(
            member => member.user.toString() === paidBy
        );

        if (!isPaidByMember) {
            return res.status(400).json({
                success: false,
                message: 'Płatnik musi być członkiem grupy'
            });
        }

        // Sprawdź podziały kosztów
        for (const split of splits) {
            // Sprawdź, czy użytkownik jest członkiem grupy
            const isSplitUserMember = group.members.some(
                member => member.user.toString() === split.user
            );

            if (!isSplitUserMember) {
                return res.status(400).json({
                    success: false,
                    message: `Użytkownik przypisany do podziału kosztów nie jest członkiem grupy`
                });
            }
        }

        // Sprawdź czy suma podziałów zgadza się z kwotą całkowitą
        if (splitType === 'exact') {
            const totalSplitAmount = splits.reduce((sum, split) => sum + split.amount, 0);

            if (Math.abs(totalSplitAmount - amount) > 0.01) { // Mała tolerancja dla błędów zaokrąglenia
                return res.status(400).json({
                    success: false,
                    message: 'Suma kwot podziału musi być równa kwocie całkowitej'
                });
            }
        }

        // Sprawdź czy procenty sumują się do 100% dla podziału procentowego
        if (splitType === 'percentage') {
            const totalPercentage = splits.reduce((sum, split) => sum + split.percentage, 0);

            if (Math.abs(totalPercentage - 100) > 0.1) { // Mała tolerancja dla błędów zaokrąglenia
                return res.status(400).json({
                    success: false,
                    message: 'Suma procentów podziału musi wynosić 100%'
                });
            }
        }

        // Utwórz nowy wydatek
        const expense = new Expense({
            group: groupId,
            description,
            amount,
            currency: currency || group.defaultCurrency,
            paidBy,
            date: date || new Date(),
            category: category || 'other',
            splitType,
            splits,
            flags: flags || []
        });

        // Zapisz wydatek w bazie danych
        await expense.save();

        // Aktualizacja sald i obliczenie należności
        await settlementService.updateBalances(groupId);

        // Wyślij powiadomienia do członków grupy
        const groupMembers = group.members
            .filter(member => member.user.toString() !== req.user._id.toString());

        for (const member of groupMembers) {
            const user = await User.findById(member.user);

            if (user && user.notificationSettings.newExpense) {
                await sendNotification(
                    user._id,
                    'Nowy wydatek w grupie',
                    `${req.user.firstName} dodał nowy wydatek "${description}" w grupie "${group.name}"`,
                    {
                        type: 'NEW_EXPENSE',
                        expenseId: expense._id,
                        groupId: groupId
                    }
                );
            }
        }

        // Pobierz pełny wydatek z danymi użytkowników
        const populatedExpense = await Expense.findById(expense._id)
            .populate('paidBy', 'firstName lastName email avatar')
            .populate('splits.user', 'firstName lastName email avatar');

        res.status(201).json({
            success: true,
            message: 'Wydatek utworzony pomyślnie',
            expense: populatedExpense
        });
    } catch (error) {
        next(error);
    }
};

/**
 * @desc    Pobieranie wydatków grupy
 * @route   GET /api/groups/:groupId/expenses
 * @access  Private (tylko członkowie grupy)
 */
exports.getGroupExpenses = async (req, res, next) => {
    try {
        const { groupId } = req.params;
        const {
            page = 1,
            limit = 20,
            sortBy = 'date',
            order = 'desc',
            category,
            startDate,
            endDate,
            paidBy
        } = req.query;

        // Sprawdź, czy grupa istnieje
        const group = await Group.findById(groupId);
        if (!group) {
            return res.status(404).json({
                success: false,
                message: 'Grupa nie została znaleziona'
            });
        }

        // Sprawdź, czy użytkownik jest członkiem grupy
        const isMember = group.members.some(
            member => member.user.toString() === req.user._id.toString()
        );

        if (!isMember) {
            return res.status(403).json({
                success: false,
                message: 'Nie jesteś członkiem tej grupy'
            });
        }

        // Przygotuj filtrację
        const filter = { group: groupId };

        // Dodaj filtry opcjonalne
        if (category) {
            filter.category = category;
        }

        if (startDate && endDate) {
            filter.date = {
                $gte: new Date(startDate),
                $lte: new Date(endDate)
            };
        } else if (startDate) {
            filter.date = { $gte: new Date(startDate) };
        } else if (endDate) {
            filter.date = { $lte: new Date(endDate) };
        }

        if (paidBy) {
            filter.paidBy = paidBy;
        }

        // Przygotuj sortowanie
        const sort = {};
        sort[sortBy] = order === 'desc' ? -1 : 1;

        // Pobierz wydatki z paginacją
        const options = {
            page: parseInt(page, 10),
            limit: parseInt(limit, 10),
            sort,
            populate: [
                { path: 'paidBy', select: 'firstName lastName email avatar' },
                { path: 'splits.user', select: 'firstName lastName email avatar' }
            ]
        };

        const expenses = await expenseService.getExpenses(filter, options);

        res.json({
            success: true,
            expenses: expenses.docs,
            pagination: {
                totalDocs: expenses.totalDocs,
                limit: expenses.limit,
                totalPages: expenses.totalPages,
                page: expenses.page,
                hasPrevPage: expenses.hasPrevPage,
                hasNextPage: expenses.hasNextPage,
                prevPage: expenses.prevPage,
                nextPage: expenses.nextPage
            }
        });
    } catch (error) {
        next(error);
    }
};

/**
 * @desc    Pobieranie szczegółów wydatku
 * @route   GET /api/expenses/:id
 * @access  Private (tylko członkowie grupy)
 */
exports.getExpenseDetails = async (req, res, next) => {
    try {
        const { id } = req.params;

        // Pobierz wydatek z bazy danych
        const expense = await Expense.findById(id)
            .populate('paidBy', 'firstName lastName email avatar')
            .populate('splits.user', 'firstName lastName email avatar')
            .populate('comments.user', 'firstName lastName email avatar');

        if (!expense) {
            return res.status(404).json({
                success: false,
                message: 'Wydatek nie został znaleziony'
            });
        }

        // Sprawdź, czy użytkownik jest członkiem grupy
        const group = await Group.findById(expense.group);

        if (!group) {
            return res.status(404).json({
                success: false,
                message: 'Grupa nie została znaleziona'
            });
        }

        const isMember = group.members.some(
            member => member.user.toString() === req.user._id.toString()
        );

        if (!isMember) {
            return res.status(403).json({
                success: false,
                message: 'Nie masz dostępu do tego wydatku'
            });
        }

        res.json({
            success: true,
            expense
        });
    } catch (error) {
        next(error);
    }
};

/**
 * @desc    Aktualizacja wydatku
 * @route   PUT /api/expenses/:id
 * @access  Private (tylko twórca wydatku lub admin grupy)
 */
exports.updateExpense = async (req, res, next) => {
    try {
        const { id } = req.params;
        const {
            description,
            amount,
            currency,
            paidBy,
            date,
            category,
            splitType,
            splits,
            flags
        } = req.body;

        // Pobierz wydatek z bazy danych
        let expense = await Expense.findById(id);

        if (!expense) {
            return res.status(404).json({
                success: false,
                message: 'Wydatek nie został znaleziony'
            });
        }

        // Pobierz grupę
        const group = await Group.findById(expense.group);

        if (!group) {
            return res.status(404).json({
                success: false,
                message: 'Grupa nie została znaleziona'
            });
        }

        // Ensure we're comparing strings
        const currentUserId = req.user._id.toString();
        const expensePaidById = expense.paidBy.toString();

        // Sprawdź, czy użytkownik ma uprawnienia do edycji (admin grupy lub twórca wydatku)
        const isAdmin = group.members.some(
            member => member.user.toString() === currentUserId && member.role === 'admin'
        );

        const isPaidBy = expensePaidById === currentUserId;

        if (!isAdmin && !isPaidBy) {
            return res.status(403).json({
                success: false,
                message: 'Nie masz uprawnień do edycji tego wydatku'
            });
        }

        // Aktualizuj pola wydatku
        if (description) expense.description = description;
        if (amount) expense.amount = amount;
        if (currency) expense.currency = currency;
        if (paidBy) {
            // Sprawdź, czy nowy płatnik jest członkiem grupy
            const isPaidByMember = group.members.some(
                member => member.user.toString() === paidBy
            );

            if (!isPaidByMember) {
                return res.status(400).json({
                    success: false,
                    message: 'Płatnik musi być członkiem grupy'
                });
            }

            expense.paidBy = paidBy;
        }
        if (date) expense.date = date;
        if (category) expense.category = category;

        // Aktualizacja podziału kosztów
        if (splitType) {
            expense.splitType = splitType;

            if (splits) {
                // Sprawdź, czy wszyscy użytkownicy w podziale są członkami grupy
                for (const split of splits) {
                    const isSplitUserMember = group.members.some(
                        member => member.user.toString() === split.user
                    );

                    if (!isSplitUserMember) {
                        return res.status(400).json({
                            success: false,
                            message: `Użytkownik przypisany do podziału kosztów nie jest członkiem grupy`
                        });
                    }
                }

                // Sprawdź poprawność podziału
                if (splitType === 'exact' && amount) {
                    const totalSplitAmount = splits.reduce((sum, split) => sum + split.amount, 0);

                    if (Math.abs(totalSplitAmount - amount) > 0.01) {
                        return res.status(400).json({
                            success: false,
                            message: 'Suma kwot podziału musi być równa kwocie całkowitej'
                        });
                    }
                }

                if (splitType === 'percentage') {
                    const totalPercentage = splits.reduce((sum, split) => sum + split.percentage, 0);

                    if (Math.abs(totalPercentage - 100) > 0.1) {
                        return res.status(400).json({
                            success: false,
                            message: 'Suma procentów podziału musi wynosić 100%'
                        });
                    }
                }

                expense.splits = splits;
            }
        }

        if (flags) expense.flags = flags;

        // Zapisz zaktualizowany wydatek
        await expense.save();

        // Aktualizacja sald i należności
        await settlementService.updateBalances(expense.group);

        // Pobierz zaktualizowany wydatek z danymi użytkowników
        const updatedExpense = await Expense.findById(id)
            .populate('paidBy', 'firstName lastName email avatar')
            .populate('splits.user', 'firstName lastName email avatar');

        res.json({
            success: true,
            message: 'Wydatek zaktualizowany pomyślnie',
            expense: updatedExpense
        });
    } catch (error) {
        next(error);
    }
};

/**
 * @desc    Usuwanie wydatku
 * @route   DELETE /api/expenses/:id
 * @access  Private (tylko twórca wydatku lub admin grupy)
 */
exports.deleteExpense = async (req, res, next) => {
    try {
        const { id } = req.params;

        // Pobierz wydatek z bazy danych
        const expense = await Expense.findById(id);

        if (!expense) {
            return res.status(404).json({
                success: false,
                message: 'Wydatek nie został znaleziony'
            });
        }

        // Pobierz grupę
        const group = await Group.findById(expense.group);

        if (!group) {
            return res.status(404).json({
                success: false,
                message: 'Grupa nie została znaleziona'
            });
        }

        // Sprawdź, czy użytkownik ma uprawnienia do usunięcia (admin grupy lub twórca wydatku)
        const isAdmin = group.members.some(
            member => member.user.toString() === req.user._id.toString() && member.role === 'admin'
        );

        const isPaidBy = expense.paidBy.toString() === req.user._id.toString();

        if (!isAdmin && !isPaidBy) {
            return res.status(403).json({
                success: false,
                message: 'Nie masz uprawnień do usunięcia tego wydatku'
            });
        }

        // Usuń wydatek
        await Expense.findByIdAndDelete(id);

        // Aktualizacja sald i należności
        await settlementService.updateBalances(expense.group);

        res.json({
            success: true,
            message: 'Wydatek usunięty pomyślnie'
        });
    } catch (error) {
        next(error);
    }
};

/**
 * @desc    Dodawanie komentarza do wydatku
 * @route   POST /api/expenses/:id/comments
 * @access  Private (tylko członkowie grupy)
 */
exports.addComment = async (req, res, next) => {
    try {
        const { id } = req.params;
        const { text } = req.body;

        // Pobierz wydatek z bazy danych
        const expense = await Expense.findById(id);

        if (!expense) {
            return res.status(404).json({
                success: false,
                message: 'Wydatek nie został znaleziony'
            });
        }

        // Pobierz grupę
        const group = await Group.findById(expense.group);

        if (!group) {
            return res.status(404).json({
                success: false,
                message: 'Grupa nie została znaleziona'
            });
        }

        // Sprawdź, czy użytkownik jest członkiem grupy
        const isMember = group.members.some(
            member => member.user.toString() === req.user._id.toString()
        );

        if (!isMember) {
            return res.status(403).json({
                success: false,
                message: 'Nie masz dostępu do tego wydatku'
            });
        }

        // Dodaj komentarz
        const comment = {
            user: req.user._id,
            text,
            createdAt: new Date()
        };

        expense.comments.push(comment);
        await expense.save();

        // Powiadom twórcę wydatku (jeśli to nie on dodał komentarz)
        if (expense.paidBy.toString() !== req.user._id.toString()) {
            const paidByUser = await User.findById(expense.paidBy);

            if (paidByUser && paidByUser.notificationSettings.newExpense) {
                await sendNotification(
                    paidByUser._id,
                    'Nowy komentarz do wydatku',
                    `${req.user.firstName} dodał komentarz do wydatku "${expense.description}"`,
                    {
                        type: 'NEW_COMMENT',
                        expenseId: expense._id,
                        groupId: expense.group
                    }
                );
            }
        }

        // Pobierz zaktualizowany wydatek z danymi użytkowników
        const updatedExpense = await Expense.findById(id)
            .populate('comments.user', 'firstName lastName email avatar');

        // Znajdź nowy komentarz w zaktualizowanym wydatku
        const newComment = updatedExpense.comments[updatedExpense.comments.length - 1];

        res.status(201).json({
            success: true,
            message: 'Komentarz dodany pomyślnie',
            comment: newComment
        });
    } catch (error) {
        next(error);
    }
};

// Konfiguracja multera do obsługi zdjęć
const storage = multer.diskStorage({
    destination: (req, file, cb) => {
        const uploadDir = process.env.UPLOAD_DIR || 'uploads';
        cb(null, uploadDir);
    },
    filename: (req, file, cb) => {
        const uniqueName = `${uuidv4()}-${Date.now()}${path.extname(file.originalname)}`;
        cb(null, uniqueName);
    }
});

const fileFilter = (req, file, cb) => {
    // Akceptuj tylko obrazy
    if (file.mimetype.startsWith('image/')) {
        cb(null, true);
    } else {
        cb(new Error('Można przesyłać tylko pliki graficzne'), false);
    }
};

const upload = multer({
    storage,
    fileFilter,
    limits: {
        fileSize: parseInt(process.env.MAX_FILE_SIZE, 10) || 5 * 1024 * 1024 // 5MB domyślnie
    }
});

/**
 * @desc    Dodawanie zdjęcia paragonu do wydatku
 * @route   POST /api/expenses/:id/receipt
 * @access  Private (tylko twórca wydatku lub admin grupy)
 */
exports.uploadReceipt = [
    upload.single('receipt'),
    async (req, res, next) => {
        try {
            const { id } = req.params;

            // Pobierz wydatek z bazy danych
            const expense = await Expense.findById(id);

            if (!expense) {
                // Jeśli wydatek nie istnieje, usuń przesłany plik
                if (req.file) {
                    fs.unlinkSync(req.file.path);
                }

                return res.status(404).json({
                    success: false,
                    message: 'Wydatek nie został znaleziony'
                });
            }

            // Pobierz grupę
            const group = await Group.findById(expense.group);

            if (!group) {
                if (req.file) {
                    fs.unlinkSync(req.file.path);
                }

                return res.status(404).json({
                    success: false,
                    message: 'Grupa nie została znaleziona'
                });
            }

            // Sprawdź, czy użytkownik ma uprawnienia do edycji (admin grupy lub twórca wydatku)
            const isAdmin = group.members.some(
                member => member.user.toString() === req.user._id.toString() && member.role === 'admin'
            );

            const isPaidBy = expense.paidBy.toString() === req.user._id.toString();

            if (!isAdmin && !isPaidBy) {
                if (req.file) {
                    fs.unlinkSync(req.file.path);
                }

                return res.status(403).json({
                    success: false,
                    message: 'Nie masz uprawnień do edycji tego wydatku'
                });
            }

            // Usuń stary paragon jeśli istnieje
            if (expense.receipt) {
                const oldReceiptPath = path.join(
                    __dirname,
                    '../../../',
                    process.env.UPLOAD_DIR || 'uploads',
                    path.basename(expense.receipt)
                );

                if (fs.existsSync(oldReceiptPath)) {
                    fs.unlinkSync(oldReceiptPath);
                }
            }

            // Aktualizuj ścieżkę do paragonu
            expense.receipt = `/uploads/${req.file.filename}`;
            await expense.save();

            res.json({
                success: true,
                message: 'Paragon dodany pomyślnie',
                receipt: expense.receipt
            });
        } catch (error) {
            next(error);
        }
    }
];