const mongoose = require('mongoose');
const AutoIncrement = require('mongoose-sequence')(mongoose);

const tripSchema = new mongoose.Schema({

  // معرّفات الأطراف
  tripId: { type: Number, unique: true },  // سيتم توليده تلقائياً
  userId: { type: Number, required: true }, // العميل
  driverId: { type: Number }, // السائق (يضاف عند القبول)


  // معلومات الرحلة الأساسية
  startLocation: {
    type: {
      type: String,
      default: "Point",
      enum: ["Point"]
    },
    coordinates: [Number], // [longitude, latitude]
    address: String // يمكن الاحتفاظ بالنص كعنوان
  },
  endLocation: {
    type: {
      type: String,
      default: "Point",
      enum: ["Point"]
    },
    coordinates: [Number],
    address: String
  },
  distance: { type: Number, required: true }, // بالكيلومتر
  
  // الحسابات المالية
  estimatedFare: { type: Number }, // السعر المقدر (distance * rate)
  actualFare: { type: Number }, // السعر النهائي (قد يتغير)
  
  // طريقة الدفع
  paymentMethod: {
    type: String,
    enum: ['cash', 'card', 'wallet'],
    default: 'cash',
    required: true
  },
  
  // التواريخ والأوقات
  requestedAt: { type: Date, default: Date.now }, // وقت الطلب
  startTime: { type: Date }, // وقت البدء الفعلي
  endTime: { type: Date }, // وقت الانتهاء الفعلي
  
  // حالة الرحلة (تغطي جميع المراحل)
  status: {
    type: String,
    enum: [
      'pending',    // في انتظار السائق
      'accepted',   // قبلها السائق
      'rejected',   // رفضها السائق
      'in_progress', // قيد التنفيذ
      'completed',   // انتهت بنجاح
      'cancelled',   // ألغيت
      'timeout'     // انتهى وقت الانتظار
    ],
    default: 'pending'
  },
   isScheduled: { type: Boolean, default: false }, // هل الرحلة مجدولة؟
  scheduledStartTime: { type: Date }, // وقت البدء المحدد للرحلة المجدولة

  
  // إمكانية إضافة أسباب للإلغاء/الرفض لاحقاً
  cancellationReason: { type: String },
  acceptedAt: { type: Date }, // وقت قبول الرحلة
  driverRatingImpact: { type: Number, default: 0 }, // تأثير الرحلة على تقييم السائق
  timeoutDuration: { type: Date } // المدة بالدقائق قبل إلغاء القبول تلقائياً
}, { 
  timestamps: true // يضيف created_at و updated_at تلقائياً
});

// توليد tripId تلقائياً
tripSchema.plugin(AutoIncrement, { inc_field: 'tripId' });

const Trip = mongoose.model('Trip', tripSchema);
module.exports = Trip;