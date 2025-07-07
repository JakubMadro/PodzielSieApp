// Model wydatku - reprezentuje wydatki w grupach
const mongoose = require('mongoose');

// Schemat bazy danych dla wydatku
const ExpenseSchema = new mongoose.Schema({
    // Podstawowe informacje o wydatku
    group: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Group',    // Referencja do grupy, w której został utworzony wydatek
        required: true
    },
    description: {
        type: String,
        required: true,  // Opis wydatku jest wymagany
        trim: true
    },
    amount: {
        type: Number,
        required: true   // Kwota wydatku jest wymagana
    },
    currency: {
        type: String,
        required: true   // Waluta wydatku jest wymagana
    },
    paidBy: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',     // Referencja do użytkownika, który zapłacił
        required: true
    },
    date: {
        type: Date,
        default: Date.now // Domyślnie data utworzenia
    },
    
    // Kategoryzacja wydatku
    category: {
        type: String,
        enum: ['food', 'transport', 'accommodation', 'entertainment', 'utilities', 'other'],
        default: 'other' // Domyślna kategoria
    },
    
    // Sposób podziału wydatku
    splitType: {
        type: String,
        enum: ['equal', 'percentage', 'exact', 'shares'], // Równo, procentowo, dokładnie, udziały
        default: 'equal'
    },
    
    // Szczegóły podziału między użytkowników
    splits: [{
        user: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'User',     // Użytkownik uczestniczący w podziale
            required: true
        },
        amount: {
            type: Number,
            required: true   // Kwota przypadająca na tego użytkownika
        },
        percentage: {
            type: Number     // Procent (jeśli splitType = 'percentage')
        },
        shares: {
            type: Number     // Liczba udziałów (jeśli splitType = 'shares')
        },
        settled: {
            type: Boolean,
            default: false   // Czy użytkownik już spłacił swoją część
        }
    }],
    
    // Dodatkowe dane
    receipt: {
        type: String     // URL do zdjęcia paragonu
    },
    flags: [{
        type: String,
        enum: ['pending', 'urgent', 'disputed'] // Flagi statusu wydatku
    }],
    
    // Komentarze do wydatku
    comments: [{
        user: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'User',     // Autor komentarza
            required: true
        },
        text: {
            type: String,
            required: true   // Treść komentarza
        },
        createdAt: {
            type: Date,
            default: Date.now // Data utworzenia komentarza
        }
    }]
}, { 
    timestamps: true     // Automatycznie dodaje createdAt i updatedAt
});

module.exports = mongoose.model('Expense', ExpenseSchema);
