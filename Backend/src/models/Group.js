// Model grupy - reprezentuje grupy użytkowników do dzielenia wydatków
const mongoose = require('mongoose');

// Schemat bazy danych dla grupy
const GroupSchema = new mongoose.Schema({
    // Podstawowe informacje o grupie
    name: {
        type: String,
        required: true,  // Nazwa grupy jest wymagana
        trim: true      // Usuń białe znaki z początku i końca
    },
    description: {
        type: String,
        trim: true      // Opcjonalny opis grupy
    },
    defaultCurrency: {
        type: String,
        default: 'PLN'  // Domyślna waluta dla wydatków w grupie
    },
    
    // Lista członków grupy z ich rolami
    members: [{
        user: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'User',    // Referencja do modelu User
            required: true
        },
        role: {
            type: String,
            enum: ['admin', 'member'],  // Tylko admin lub member
            default: 'member'           // Domyślna rola to member
        },
        joined: {
            type: Date,
            default: Date.now           // Data dołączenia do grupy
        }
    }],
    
    // Status grupy
    isArchived: {
        type: Boolean,
        default: false  // Grupa nie jest zarchiwizowana domyślnie
    }
}, { 
    timestamps: true    // Automatycznie dodaje createdAt i updatedAt
});

module.exports = mongoose.model('Group', GroupSchema);
