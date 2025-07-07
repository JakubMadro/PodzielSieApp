// Model użytkownika - reprezentuje dane użytkowników w systemie
const mongoose = require('mongoose');
const bcrypt = require('bcrypt');

// Schemat bazy danych dla użytkownika
const UserSchema = new mongoose.Schema({
    // Podstawowe dane identyfikacyjne
    email: {
        type: String,
        required: true,
        unique: true,    // Unikalny adres email
        trim: true       // Usuń białe znaki z początku i końca
    },
    phoneNumber: {
        type: String,
        unique: true,
        sparse: true,    // Pozwala na null/undefined przy wymaganiu unikalnosti
        trim: true
    },
    password: {
        type: String,
        required: true   // Hasło jest wymagane (zostanie zahashowane)
    },
    firstName: {
        type: String,
        required: true,
        trim: true
    },
    lastName: {
        type: String,
        required: true,
        trim: true
    },
    
    // Ustawienia użytkownika
    avatar: {
        type: String     // URL do awatara użytkownika
    },
    defaultCurrency: {
        type: String,
        default: 'PLN'   // Domyślna waluta to złoty polski
    },
    language: {
        type: String,
        default: 'pl'    // Domyślny język to polski
    },
    
    // Ustawienia bezpieczeństwa
    twoFactorEnabled: {
        type: Boolean,
        default: false   // Uwierzytelnianie dwuskładnikowe wyłączone domyślnie
    },
    twoFactorSecret: {
        type: String     // Sekret dla uwierzytelniania dwuskładnikowego
    },
    
    // Ustawienia powiadomień
    notificationSettings: {
        newExpense: { type: Boolean, default: true },        // Powiadomienia o nowych wydatkach
        settlementRequest: { type: Boolean, default: true }, // Powiadomienia o żądaniach rozliczenia
        groupInvite: { type: Boolean, default: true }       // Powiadomienia o zaproszeniach do grup
    },
    
    // Tokeny sesji i resetowania hasła
    refreshToken: {
        type: String     // Token do odświeżania sesji JWT
    },
    passwordResetToken: {
        type: String     // Token do resetowania hasła (hashowany)
    },
    passwordResetExpires: {
        type: Date       // Data wygaśnięcia tokenu resetowania hasła
    }
}, { 
    timestamps: true  // Automatycznie dodaje createdAt i updatedAt
});

// Middleware - hashuje hasło przed zapisaniem do bazy danych
UserSchema.pre('save', async function(next) {
    // Jeśli hasło nie zostało zmienione, przejdź dalej
    if (!this.isModified('password')) return next();
    
    try {
        // Wygeneruj sól do hashowania (siła 10)
        const salt = await bcrypt.genSalt(10);
        // Zahashuj hasło z użyciem wygenerowanej soli
        this.password = await bcrypt.hash(this.password, salt);
        next();
    } catch (error) {
        next(error);
    }
});

// Metoda instancji - porównuje podane hasło z zahashowanym hasłem w bazie
UserSchema.methods.comparePassword = async function(password) {
    // Użyj bcrypt do porównania hasła w formie tekstowej z hashem
    return await bcrypt.compare(password, this.password);
};

module.exports = mongoose.model('User', UserSchema);
