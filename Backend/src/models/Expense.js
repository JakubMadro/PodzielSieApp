// src/models/Expense.js
const mongoose = require('mongoose');

const ExpenseSchema = new mongoose.Schema({
    group: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Group',
        required: true
    },
    description: {
        type: String,
        required: true,
        trim: true
    },
    amount: {
        type: Number,
        required: true
    },
    currency: {
        type: String,
        required: true
    },
    paidBy: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    date: {
        type: Date,
        default: Date.now
    },
    category: {
        type: String,
        enum: ['food', 'transport', 'accommodation', 'entertainment', 'utilities', 'other'],
        default: 'other'
    },
    splitType: {
        type: String,
        enum: ['equal', 'percentage', 'exact', 'shares'],
        default: 'equal'
    },
    splits: [{
        user: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'User',
            required: true
        },
        amount: {
            type: Number,
            required: true
        },
        percentage: {
            type: Number
        },
        shares: {
            type: Number
        },
        settled: {
            type: Boolean,
            default: false
        }
    }],
    receipt: {
        type: String // URL do zdjęcia paragonu
    },
    flags: [{
        type: String,
        enum: ['pending', 'urgent', 'disputed']
    }],
    comments: [{
        user: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'User',
            required: true
        },
        text: {
            type: String,
            required: true
        },
        createdAt: {
            type: Date,
            default: Date.now
        }
    }]
}, { timestamps: true });

module.exports = mongoose.model('Expense', ExpenseSchema);
