// src/models/Group.js
const mongoose = require('mongoose');

const GroupSchema = new mongoose.Schema({
    name: {
        type: String,
        required: true,
        trim: true
    },
    description: {
        type: String,
        trim: true
    },
    defaultCurrency: {
        type: String,
        default: 'PLN'
    },
    members: [{
        user: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'User',
            required: true
        },
        role: {
            type: String,
            enum: ['admin', 'member'],
            default: 'member'
        },
        joined: {
            type: Date,
            default: Date.now
        }
    }],
    isArchived: {
        type: Boolean,
        default: false
    }
}, { timestamps: true });

module.exports = mongoose.model('Group', GroupSchema);
