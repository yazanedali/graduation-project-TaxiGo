const schedule = require('node-schedule');
const Trip = require('../models/Trip');
const { updateDriverRating } = require('./ratingService');
const notificationController = require('../controllers/notificationController');
const { calculateDistance } = require('../utils/geoUtils');

// مهمة مجدولة للتحقق من الرحلات المقبولة ولم تبدأ
const scheduleTripStartCheck = async (tripId, driverId, driverLocation, clientLocation) => {
  try {
    // التحقق من وجود الإحداثيات
    if (!driverLocation || !clientLocation) {
      throw new Error('إحداثيات الموقع غير متوفرة');
    }

    const distance = calculateDistance(
      driverLocation.lat,
      driverLocation.lng,
      clientLocation.lat,
      clientLocation.lng
    );

    console.log(`[DEBUG] المسافة المحسوبة: ${distance.toFixed(2)} كم`);

    const minutesPerKm = 2;
    let requiredTime = distance * minutesPerKm;
    
    // تطبيق الحدود الزمنية
    requiredTime = Math.max(10, Math.min(30, requiredTime));

    console.log(`[DEBUG] الوقت المحدد للرحلة ${tripId}: ${requiredTime} دقيقة`);

    const checkTime = new Date(Date.now() + requiredTime * 60 * 1000);
    console.log(`[DEBUG] سيتم التحقق في: ${checkTime.toLocaleString()}`);

    const job = schedule.scheduleJob(checkTime, async () => {
      console.log(`[DEBUG] التحقق من الرحلة ${tripId}...`);
      
      try {
        const trip = await Trip.findOne({ tripId });
        
        if (!trip) {
          console.log(`[DEBUG] الرحلة ${tripId} غير موجودة`);
          return;
        }

        if (trip.status === 'accepted') {
          console.log(`[DEBUG] إعادة تعيين الرحلة ${tripId} إلى pending`);
          
         trip.status = 'pending';
          trip.driverId = null;
          trip.acceptedAt = null;
          trip.timeoutDuration = 0;
          await trip.save();
          
          await updateDriverRating(driverId, -5, 'failure_to_start_trip');
          
          await notificationController.createNotification({
            recipient: driverId,
            recipientType: 'Driver',
            title: 'تم إلغاء قبول الرحلة',
            message: `تم إلغاء قبولك للرحلة بسبب عدم البدء خلال ${requiredTime} دقيقة`,
            type: 'trip_auto_canceled'
          });

          console.log(`[DEBUG] تمت معالجة الرحلة ${tripId} بنجاح`);
        }
      } catch (jobErr) {
        console.error(`[ERROR] خطأ في معالجة الرحلة ${tripId}:`, jobErr);
      }
    });

    // تخزين المرجع للوظيفة المجدولة (اختياري)
    scheduledJobs[tripId] = job;

  } catch (err) {
    console.error('[ERROR] خطأ في جدولة التحقق:', err);
    throw err; // يمكنك التعامل مع الخطأ بشكل مختلف حسب احتياجاتك
  }
};

// كائن لتخزين الوظائف المجدولة (اختياري)
const scheduledJobs = {};
module.exports = {
  scheduleTripStartCheck
};