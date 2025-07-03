const mongoose = require('mongoose');
const AutoIncrement = require('mongoose-sequence')(mongoose);

const taxiOfficeSchema = new mongoose.Schema({
  officeIdentifier: {
    type: String,
    required: true,
    unique: true,
    trim: true
  },
  officeId: { type: Number, unique: true },
  name: { type: String, required: true },
  location: {
    type: { type: String, default: "Point" },
    coordinates: [Number],
    address: String
  },
  contact: {
    phone: String,
    email: String
  },
workingHours: {
  from: { type: String, default: "08:00" },
  to: { type: String, default: "16:00" }
},
  isActive: { type: Boolean, default: true },
  manager: { type: mongoose.Schema.Types.ObjectId, ref: 'Manager' },
  managerId: Number,
  createdAt: { type: Date, default: Date.now }
}, { timestamps: true });

taxiOfficeSchema.plugin(AutoIncrement, { inc_field: 'officeId' });
taxiOfficeSchema.index({ location: '2dsphere' });

module.exports = mongoose.model('TaxiOffice', taxiOfficeSchema);