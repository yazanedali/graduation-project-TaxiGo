// استيراد الحزم
const express = require('express');
const dotenv = require('dotenv');
const cors = require('cors');
const bodyParser = require('body-parser');
const http = require('http');

// ... (استيرادات Routes الأخرى)
const userRoutes = require('./routes/user.Routes');
const tripRoutes = require('./routes/trips.Routes');
const messageRoutes = require('./routes/messageRoutes');
const driverRoutes = require('./routes/driverRoutes'); // هذا هو الـ driver routes الأصلي
const clientRoutes = require('./routes/clientRoutes');
const dashboardRoutes = require('./routes/dashboard');
const paymentsRoutes = require('./routes/payments');
const notificationRoutes = require('./routes/notificationRoutes');
const taxiOfficeMapRoutes = require('./routes/taxiOfficeMapRoutes');
const taxiOfficeRoutes = require('./routes/taxiOfficeRouter');
const adminRoutes = require('./routes/adminRoutes'); // تأكد من استيراد مسار المدير

const driverLocationRoutes = require('./routes/driverLocationRoutes'); // ✅ استيراد راوتر الموقع الجديد
const { checkScheduledTrips } = require('./services/scheduledTasks');


const db = require('./config/db');

// إعداد السوكيت
const { init } = require('./config/socket'); // ✅ استخدام init من الملف المنفصل

// تحميل ملف البيئة
dotenv.config();

// إعداد السيرفر
const app = express();
const server = http.createServer(app);

// تهيئة السوكيت
init(server); // ✅ تهيئة السوكيت باستخدام السيرفر

// استدعاء التحقق من الرحلات المجدولة (يمكنك جدولة هذا بفاصل زمني)
setInterval(checkScheduledTrips, 60 * 1000); // كل دقيقة

// Middlewares
app.use(express.json());
app.use(bodyParser.urlencoded({ extended: true }));
app.use(cors({
  origin: process.env.CORS_ORIGIN || '*',
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH'] // أضف PATCH إذا كنت تستخدمها
}));

// الاتصال بقاعدة البيانات
db();

// مسارات API
app.use('/api/users', userRoutes);
app.use('/api/trips', tripRoutes);
app.use('/messages', messageRoutes);
app.use('/api/drivers', driverRoutes); // مسار drivers الأصلي
// app.use('/api/drivers', driverLocationRoutes); // ✅ ربط راوتر الموقع الجديد (يمكن أن يكون نفس المسار الأساسي إذا كنت تستخدمه بشكل جيد)
app.use('/api/clients', clientRoutes);
app.use('/api/dashboard', dashboardRoutes);
app.use('/api/payments', paymentsRoutes);
app.use('/api/notifications', notificationRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/map', taxiOfficeMapRoutes);
app.use('/api/offices', taxiOfficeRoutes);

// Route for health check
app.get('/api/health', (req, res) => {
  res.status(200).json({
    status: 'healthy',
    timestamp: new Date().toISOString()
  });
});

// معالجة الأخطاء المركزية
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({
    success: false,
    message: 'Internal Server Error',
    error: process.env.NODE_ENV === 'development' ? err.message : undefined
  });
});

// بدء السيرفر
const PORT = process.env.PORT || 5000;
server.listen(PORT, () => {
  console.log(`Server running in ${process.env.NODE_ENV || 'development'} mode on port ${PORT}`);
});