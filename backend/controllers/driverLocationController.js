// controllers/driverLocationController.js
const Driver = require('../models/Driver'); // تأكد من المسار الصحيح لموديل Driver
const { getIo } = require('../config/socket'); // ✅ لاستخدام instance الـ Socket.IO

const updateDriverLocation = async (req, res) => {
  try {
    // ✅ استخراج driverUserId من req.params
    const { driverUserId } = req.params;
    // استخراج latitude, longitude, tripId من req.body (هذا صحيح)
    const { latitude, longitude, tripId } = req.body;

    // --- (اختياري لكن موصى به جداً لأغراض التصحيح) ---
    console.log('--- Received location update request ---');
    console.log('driverUserId from params:', driverUserId);
    console.log('Request body:', req.body);
    console.log('Latitude:', latitude, 'Type:', typeof latitude);
    console.log('Longitude:', longitude, 'Type:', typeof longitude);
    console.log('TripId:', tripId);
    // ---------------------------------------------------

    // ✅ التحقق من وجود driverUserId والإحداثيات (والتأكد أنها أرقام)
    // Flutter يرسل latitude و longitude كأرقام، لذا typeof 'number' هو التحقق الصحيح
    if (!driverUserId || typeof latitude !== 'number' || typeof longitude !== 'number') {
      console.error('Validation failed: driverUserId or coordinates are missing or not numbers.');
      return res.status(400).json({
        success: false,
        message: 'معرف السائق والإحداثيات مطلوبة'
      });
    }

    const driver = await Driver.findOneAndUpdate(
      { driverUserId: driverUserId }, // البحث باستخدام driverUserId من الـ params
      {
        currentLocation: {
          type: 'Point',
          coordinates: [longitude, latitude], // تأكد أن longitude يأتي أولاً
        },
        lastUpdated: new Date()
      },
      { new: true, runValidators: true } // ✅ إضافة runValidators: true لضمان تطبيق قيود الـ schema
    );

    if (!driver) {
      console.warn(`Driver with ID ${driverUserId} not found for location update.`);
      return res.status(404).json({
        success: false,
        message: 'السائق غير موجود'
      });
    }

    console.log(`Driver ${driverUserId} location updated successfully to (${latitude}, ${longitude}).`);

    // إرسال تحديث الموقع للرحلة المحددة إذا كان هناك tripId
    if (tripId) {
      const io = getIo();
      io.to(`trip_${tripId}`).emit('driverLocationUpdate', {
        driverId: driverUserId, // استخدم driverUserId الذي تم استخراجه من الـ params
        latitude,
        longitude,
        timestamp: new Date().toISOString()
      });
    }

    res.status(200).json({
      success: true,
      message: 'تم تحديث موقع السائق'
    });

  } catch (error) {
    console.error('خطأ في تحديث موقع السائق:', error);
    res.status(500).json({
      success: false,
      message: 'خطأ في الخادم',
      error: error.message // أضف error.message ليكون مفيداً في وضع التطوير
    });
  } finally {
    console.log('--- End of location update request ---');
  }
};

module.exports = {
  updateDriverLocation,
};