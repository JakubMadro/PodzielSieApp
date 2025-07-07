// src/models/Settlement.js
const mongoose = require('mongoose');
const mongoosePaginate = require('mongoose-paginate-v2');


const SettlementSchema = new mongoose.Schema({
    group: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Group',
        required: true
    },
    payer: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    receiver: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    amount: {
        type: Number,
        required: true
    },
    currency: {
        type: String,
        required: true
    },
    relatedExpenses: [{
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Expense'
    }],
    status: {
        type: String,
        enum: ['pending', 'completed'],
        default: 'pending'
    },
    paymentMethod: {
        type: String,
        enum: ['manual', 'paypal', 'blik', 'other'],
        default: 'manual'
    },
    paymentReference: {
        type: String
    },
    settledAt: {
        type: Date
    }
}, { timestamps: true });

// Dodaj plugin paginacji do schematu
SettlementSchema.plugin(mongoosePaginate);

module.exports = mongoose.model('Settlement', SettlementSchema);