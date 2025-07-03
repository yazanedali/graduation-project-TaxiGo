const mongoose = require('mongoose');

const managerSchema = new mongoose.Schema({
  user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  userId: { type: Number, required: true },
  office: { type: mongoose.Schema.Types.ObjectId, ref: 'TaxiOffice', required: true },
  officeId: { type: Number, required: true },
  position: { type: String, enum: ['General', 'Operations', 'Finance'], default: 'General' },
  isActive: { type: Boolean, default: true }
}, { timestamps: true });

module.exports = mongoose.model('Manager', managerSchema);