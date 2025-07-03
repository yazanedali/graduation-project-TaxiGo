const mongoose = require('mongoose');

const clientSchema = new mongoose.Schema({
  user: { // العلاقة مع نموذج User
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    unique: true,
    index: true,
  },
  clientUserId: { // المعرّف الرقمي للعميل
    type: Number,
    required: true,
    index: true,
  },
    walletBalance: { // أضف هذا الحقل الجديد
    type: Number,
    default: 200,
    min: 0
  },

  tripHistory: [{ // تاريخ الرحلات (يمكن تفصيله أكثر)
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Trip',
  }],

  tripsnumber: { // عدد الرحلات التي قام بها العميل
    type: Number,
    default: 0,
  },

  profileImageUrl: {
    type: String,
    trim: true,
    default: null,
  },
  totalSpending: { // إجمالي ما أنفقه العميل
    type: Number,
    default: 0,
  },
  isAvailable: {
    type: Boolean,
    default: true,
    index: true,
  },
  // يمكن إضافة المزيد من الحقول حسب الحاجة
}, { timestamps: true });

const Client = mongoose.model('Client', clientSchema);

module.exports = Client;