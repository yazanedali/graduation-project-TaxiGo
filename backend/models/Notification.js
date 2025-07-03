// models/Notification.js
const mongoose = require('mongoose');
const AutoIncrement = require('mongoose-sequence')(mongoose);

const notificationSchema = new mongoose.Schema({
  // ID تسلسلي (مثل باقي الجداول)
  notificationId: { type: Number, unique: true },
  
  // المستخدم المرسل إليه الإشعار (كنمبر بدل ObjectId)
  recipient: {
    type: Number,
    required: true
  },
  
  // نوع المستلم (سائق أو عميل)
  recipientType: {
    type: String,
    required: true,
    enum: ['Driver', 'Client', 'Manager']
  },
  
  // عنوان الإشعار
  title: {
    type: String,
    required: true
  },
  
  // محتوى الإشعار
  message: {
    type: String,
    required: true
  },
  
  // نوع الإشعار
  type: {
    type: String,
    required: true,
    enum: [
      'trip_request', 'trip_accepted', 'trip_rejected', 
      'trip_started', 'trip_completed', 'payment_received',
      'promotion', 'system', 'driver_assigned', 'arrival_notice',
      'trip_auto_canceled'
    ]
  },
  
  // بيانات إضافية مرتبطة بالإشعار
  data: {
    tripId: { type: Number }, // تغيير من ObjectId إلى Number
    amount: Number
  },
  
  // حالة الإشعار
  status: {
    type: String,
    enum: ['unread', 'read', 'deleted'],
    default: 'unread'
  },
  
  // صورة مصغرة للإشعار
  image: String,
  
  // تاريخ الإنشاء
  createdAt: {
    type: Date,
    default: Date.now
  },
  
  // تاريخ القراءة
  readAt: Date
}, {
  timestamps: true // إضافة created_at و updated_at تلقائياً
});

// توليد notificationId تلقائياً
notificationSchema.plugin(AutoIncrement, { inc_field: 'notificationId' });

// فهرسة لتحسين الأداء
notificationSchema.index({ recipient: 1, status: 1, createdAt: -1 });

const Notification = mongoose.model('Notification', notificationSchema);

module.exports = Notification;