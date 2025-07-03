const Trip = require('../models/Trip');
const Driver = require('../models/Driver');
const Client = require('../models/client');
const User = require('../models/User'); // افترض أن لديك نموذج User
const notificationController = require('./notificationController'); // تأكد من استيراد وحدة الإشعارات
const { scheduleTripStartCheck } = require('../services/tripScheduler'); // تأكد من استيراد وحدة جدولة الرحلات
const { updateDriverRating } = require('../services/ratingService'); // تأكد من استيراد وحدة تحديث تقييم السائق
const { calculateDistance } = require('../utils/geoUtils');

const RATE_PER_KM = 4.4;
const MAX_ACCEPTED_TRIPS = 1;


// إنشاء طلب رحلة جديدة من قبل المستخدم
exports.createTrip = async (req, res) => {
  try {
    const { 
      userId, 
      startLocation, 
      endLocation, 
      distance, 
      startTime, 
      paymentMethod,
      isScheduled
    } = req.body;
    
    // التحقق من وجود رحلة نشطة للمستخدم
    const activeTrip = await Trip.findOne({
      userId,
      status: { 
        $in: ['pending', 'accepted', 'in_progress'] 
      }
    });

    if (activeTrip) {
      return res.status(400).json({ 
        error: 'لديك رحلة نشطة بالفعل',
        activeTripId: activeTrip._id,
        currentStatus: activeTrip.status,
        message: 'يجب إكمال أو إلغاء الرحلة الحالية قبل إنشاء رحلة جديدة'
      });
    }

    const estimatedFare = distance * RATE_PER_KM;

    // التحقق من رصيد المحفظة إذا كانت طريقة الدفع بالمحفظة
    if (paymentMethod === 'wallet') {
      const client = await Client.findOne({ clientUserId: userId });
      if (!client) {
        return res.status(404).json({ error: 'العميل غير موجود' });
      }
      if (client.walletBalance < estimatedFare) {
        return res.status(400).json({ 
          error: 'رصيد المحفظة غير كافي لإنشاء الرحلة',
          requiredAmount: estimatedFare,
          currentBalance: client.walletBalance
        });
      }
    }

    const newTrip = new Trip({
      userId,
      startLocation: {
        type: "Point",
        coordinates: [startLocation.longitude, startLocation.latitude],
        address: startLocation.address
      },
      endLocation: {
        type: "Point",
        coordinates: [endLocation.longitude, endLocation.latitude],
        address: endLocation.address
      },
      paymentMethod,
      distance,
      estimatedFare,
      isScheduled: isScheduled || false,
      scheduledStartTime: isScheduled ? new Date(startTime) : undefined,
      paymentStatus: 'pending'
    });

    await newTrip.save();
    res.status(201).json(newTrip);
  } catch (err) {
    res.status(500).json({ 
      error: 'فشل إنشاء الرحلة', 
      details: err.message 
    });
  }
};


exports.getAllTrips = async (req, res) => {
  try {
    const { status } = req.query;
    
    const query = {};
    if (status) {
      query.status = status;
    }

    const trips = await Trip.find(query).sort({ createdAt: -1 });

    // استخراج كل userId و driverId الفريدة
    const userIds = [...new Set(trips.map(t => t.userId))];
    const driverIds = [...new Set(trips.map(t => t.driverId).filter(Boolean))];

    // جلب المستخدمين والسائقين
    const users = await User.find({ userId: { $in: userIds } });
    const drivers = await User.find({ userId: { $in: driverIds } });

    // عمل Map لسهولة الوصول
    const userMap = new Map(users.map(u => [u.userId, u]));
    const driverMap = new Map(drivers.map(d => [d.userId, d]));

    const enrichedTrips = trips.map(trip => {
      const user = userMap.get(trip.userId);
      const driver = driverMap.get(trip.driverId);

      return {
        ...trip.toObject(),
        userName: user?.fullName || 'Unknown',
        userPhone: user?.phone || 'N/A',
        driverName: driver?.fullName || 'Unknown',
        driverPhone: driver?.phone || 'N/A'
      };
    });

    res.status(200).json({
      success: true,
      count: enrichedTrips.length,
      data: enrichedTrips
    });
  } catch (err) {
    console.error('Error fetching trips:', err);
    res.status(500).json({ 
      success: false,
      error: err.message 
    });
  }
};


// قبول الرحلة من قبل السائق
// تعديل دالة قبول الرحلة لإضافة الحد الأقصى
exports.acceptTrip = async (req, res) => {
  try {
    const { tripId } = req.params;
    const { driverId, driverLocation } = req.body;
    const { lat: driverLat, lng: driverLng } = driverLocation || {};

    if (driverLat === undefined || driverLng === undefined) {
      return res.status(400).json({ error: 'إحداثيات السائق غير متوفرة' });
    }

    const acceptedTripsCount = await Trip.countDocuments({ 
      driverId, 
      status: { $in: ['accepted', 'in_progress'] }
    });

    if (acceptedTripsCount >= MAX_ACCEPTED_TRIPS) {
      return res.status(400).json({ 
        error: `لا يمكنك قبول أكثر من ${MAX_ACCEPTED_TRIPS} رحلات في نفس الوقت` 
      });
    }

    const trip = await Trip.findOne({ tripId });
    if (!trip || trip.status !== 'pending') {
      return res.status(400).json({ error: 'الرحلة غير متاحة للقبول' });
    }

    const driver = await Driver.findOne({ driverUserId: driverId }).populate('user');

    const [clientLng, clientLat] = trip.startLocation.coordinates;
    const clientLocation = { lat: clientLat, lng: clientLng };
    const driverLoc = { lat: driverLat, lng: driverLng };
    const distance = calculateDistance(
      driverLocation.lat,
      driverLocation.lng,
      clientLocation.lat,
      clientLocation.lng
    );
    const minutesPerKm = 2;
    let requiredTime = distance * minutesPerKm;
    const checkTime = new Date(Date.now() + requiredTime * 60 * 1000);

    console.log(`[DEBUG] المسافة المحسوبة: ${distance.toFixed(2)} كم`);
        console.log(`[DEBUG]  التحقق في: ${checkTime.toLocaleString()}`);


    // تحديث حالة الرحلة
    trip.driverId = driverId;
    trip.status = 'accepted';
    trip.timeoutDuration = checkTime.toLocaleString(); // حفظ الوقت المطلوب للرحلة
    trip.acceptedAt = new Date();

    await scheduleTripStartCheck(tripId, driverId, driverLoc, clientLocation);

    


    await notificationController.createNotification({
      recipient: trip.userId,
      recipientType: 'Client',
      title: 'تم قبول الرحلة',
      message: `قام السائق ${driver.user.fullName} بقبول طلب رحلتك رقم ${trip.tripId}`,
      type: 'trip_accepted',
      data: { tripId: trip.tripId }
    });

    await trip.save();
    res.json(trip);
  } catch (err) {
    console.error('[ACCEPT_TRIP_ERROR]', err); // لتسهيل التتبع
    res.status(500).json({ 
      error: 'فشل قبول الرحلة', 
      details: err.message 
    });
  }
};

// بدء الرحلة (الانتقال من accepted إلى in_progress)
exports.startTrip = async (req, res) => {
  try {
    const { tripId } = req.params;

    const trip = await Trip.findOne({ tripId });
    const driver = await Driver.findOne({ driverUserId: trip.driverId }).populate('user');

    if (!trip || trip.status !== 'accepted') {
      return res.status(400).json({
        error: 'لا يمكن بدء الرحلة إلا إذا كانت مقبولة'
      });
    }

    const now = new Date();
    const acceptedTime = new Date(trip.acceptedAt);
    const responseTime = (now - acceptedTime) / (1000 * 60); // المدة بالدقائق
    
    // حساب تأثير وقت الاستجابة على التقييم
    let responseImpact = 0;
    if (responseTime < 5) {
      responseImpact = 2; // بدء سريع
    } else if (responseTime > 15) {
      responseImpact = -1; // بدء متأخر
    }
    
    // تحديث تقييم السائق بناءً على سرعة الاستجابة
    if (responseImpact !== 0) {
      await updateDriverRating(
        trip.driverId, 
        responseImpact, 
        responseImpact > 0 ? 'quick_response' : 'late_start'
      );
    }

    trip.status = 'in_progress';
    trip.startTime = now;

    await notificationController.createNotification({
      recipient: trip.userId,
      recipientType: 'Client',
      title: 'تم بدء الرحلة',
      message: `قام السائق ${driver.user.fullName} ببدء رحلتك رقم ${trip.tripId}`,
      type: 'trip_started',
      data: {
        tripId: trip.tripId,
        driverLocation: trip.startLocation
      }
    });

    await trip.save();
    res.json(trip);
  } catch (err) {
    res.status(500).json({
      error: 'فشل بدء الرحلة',
      details: err.message
    });
  }
};

// رفض الرحلة من قبل السائق
exports.rejectTrip = async (req, res) => {
  try {
    const { tripId } = req.params;
    const { cancellationReason, driverId } = req.body;

    const trip = await Trip.findOne({ tripId });
    const driver = await Driver.findOne({ driverUserId: driverId }).populate('user');

    if (!trip || trip.status !== 'pending') {
      return res.status(400).json({ error: 'الرحلة غير متاحة للرفض' });
    }

    trip.status = 'rejected';
    trip.cancellationReason = cancellationReason || 'رفض من السائق';

    // إرسال إشعار للعميل برفض الرحلة
    await notificationController.createNotification({
      recipient: trip.userId,
      recipientType: 'Client',
      title: 'تم رفض الرحلة',
      message: `قام السائق ${driver.user.fullName} برفض طلب رحلتك رقم ${trip.tripId}`,
      type: 'trip_rejected',
      data: {
        tripId: trip.tripId,
        reason: cancellationReason
      }
    });

    await trip.save();
    res.json(trip);
  } catch (err) {
    res.status(500).json({ error: 'فشل رفض الرحلة', details: err.message });
  }
};

// إتمام الرحلة من قبل السائق (تحديث السعر الفعلي)
// إتمام الرحلة من قبل السائق (تحديث السعر الفعلي وإضافة الأرباح للسائق)
// إتمام الرحلة من قبل السائق (تحديث السعر الفعلي وإضافة الأرباح للسائق)
exports.completeTrip = async (req, res) => {
  try {
    const { tripId } = req.params;
    const trip = await Trip.findOne({ tripId });
    const driver = await Driver.findOne({ driverUserId: trip.driverId }).populate('user');

    if (!trip || trip.status !== 'in_progress') {
      return res.status(400).json({ error: 'لا يمكن إنهاء الرحلة في هذه الحالة' });
    }

    const fare = trip.distance * RATE_PER_KM;
    
    // إذا كانت طريقة الدفع بالمحفظة، نخصم المبلغ الآن
    if (trip.paymentMethod === 'wallet') {
      const client = await Client.findOne({ clientUserId: trip.userId });
      
      if (!client) {
        return res.status(404).json({ error: 'العميل غير موجود' });
      }

      if (client.walletBalance < fare) {
        return res.status(400).json({ 
          error: 'رصيد المحفظة غير كافي لإتمام الرحلة',
          requiredAmount: fare,
          currentBalance: client.walletBalance
        });
      }

      client.walletBalance -= fare;
      await client.save();
      trip.paymentStatus = 'paid';
    }

    // حساب وقت الرحلة
    const startTime = new Date(trip.startTime);
    const endTime = new Date();
    const tripDuration = (endTime - startTime) / (1000 * 60); // المدة بالدقائق
    
    // حساب تأثير إتمام الرحلة على التقييم
    let completionImpact = 5; // القيمة الأساسية لإتمام الرحلة
    
    // مكافأة الرحلات السريعة
    const expectedDuration = trip.distance * 3; // 3 دقائق لكل كم (تقديري)
    if (tripDuration < expectedDuration * 0.8) {
      completionImpact += 2; // مكافأة إضافية للرحلات السريعة
    }
    
    // تحديث تقييم السائق
    await updateDriverRating(
      trip.driverId, 
      completionImpact, 
      'trip_completed'
    );

    // تحديث حالة الرحلة
    trip.status = 'completed';
    trip.endTime = endTime;
    trip.actualFare = fare;

    // تحديث بيانات السائق
    if (driver) {
      driver.earnings += fare;
      driver.completedTrips += 1;
      await driver.save();
    }

    // تحديث بيانات العميل
    const client = await Client.findOne({ clientUserId: trip.userId });
    if (client) {
      client.tripsnumber += 1;
      client.totalSpending += fare;
      client.tripHistory.push(trip._id);
      await client.save();
    }

    await notificationController.createNotification({
      recipient: trip.userId,
      recipientType: 'Client',
      title: 'تم إتمام الرحلة',
      message: `تم إتمام رحلتك رقم ${trip.tripId} مع السائق ${driver.user.fullName}`,
      type: 'trip_completed',
      data: {
        tripId: trip.tripId,
        fare: fare,
        paymentMethod: trip.paymentMethod,
        paymentStatus: trip.paymentStatus
      }
    });

    await trip.save();
    res.json(trip);
  } catch (err) {
    res.status(500).json({ error: 'فشل إنهاء الرحلة', details: err.message });
  }
};

// جميع رحلات سائق معيّن
// exports.getDriverTrips = async (req, res) => {
//   try {
//     const { driverId } = req.params;
//     const trips = await Trip.find({ driverId })
//     res.json(trips);
//   } catch (err) {
//     res.status(500).json({ error: 'فشل جلب الرحلات', details: err.message });
//   }
// };

// آخر 3 رحلات فقط لسائق معيّن
exports.getDriverRecentTrips = async (req, res) => {
  try {
    const { driverId } = req.params;
    const trips = await Trip.find({ driverId })
                            .sort({ createdAt: -1 })
                            .limit(3);
    res.json(trips);
  } catch (err) {
    res.status(500).json({ error: 'فشل جلب الرحلات الأخيرة', details: err.message });
  }
};
exports.getDriverTripsByStatus = async (req, res) => {
  try {
    const { driverId } = req.params;
    const { status } = req.query;

    const query = { driverId };
    if (status) query.status = status;

    const trips = await Trip.find(query).sort({ createdAt: -1 });
    res.json(trips);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

exports.getUserTripsByStatus = async (req, res) => {
  try {
    const { userId } = req.params;
    const { status } = req.query;
    console.log('User ID:', userId, 'Status:', status); // Log the userId and status for debugging

    const query = { userId };
    if (status) query.status = status;

    const trips = await Trip.find(query)
      .populate('driverId', 'name phone carModel licensePlate')
      .sort({ createdAt: -1 });
      
    res.json(trips);
    console.log('User trips:', trips); // Log the trips for debugging
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};



exports.getDriverTrips = async (req, res) => {
  try {
    const query = { driverId: req.params.driverId };
    // Add status filter if provided
    if (req.query.status) {
      query.status = req.query.status;
    }


    const trips = await Trip.find(query) // Sort by newest first

    res.json(trips);
  } catch (error) {
    console.error('Error getting trips:', error);
    res.status(500).json({ error: 'فشل جلب الرحلات', details: err.message });
  }
};
////////////////////////////
////////////////////////////
// exports.getDriverTrips = async (req, res) => {
//   try {
//     const { driverId } = req.params;
//     const trips = await Trip.find({ driverId })
//     res.json(trips);
//   } catch (err) {
//     res.status(500).json({ error: 'فشل جلب الرحلات', details: err.message });
//   }
// };

exports.updateTripStatus = async (req, res) => {
  try {
    const { status } = req.body;
    const validStatuses = ['pending', 'accepted', 'rejected', 'in_progress', 'completed', 'canceled'];

    // Validate status
    if (!validStatuses.includes(status)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid status value'
      });
    }

    const trip = await Trip.findByIdAndUpdate(
      req.params.tripId,
      { status },
      { new: true, runValidators: true }
    );

    if (!trip) {
      return res.status(404).json({
        success: false,
        message: 'Trip not found'
      });
    }

    res.status(200).json({
      success: true,
      data: trip
    });
  } catch (error) {
    console.error('Error updating trip status:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

 exports.getPendingTrips = async (req, res) => {
  try {
    const trips = await Trip.find({ 
      status: 'pending',
        $or: [
    { driverId: { $exists: false } },
    { driverId: null }
  ]
      
    })
    res.json(trips);
  } catch (error) {
    console.error('Error getting pending trips:', error);
    res.status(500).json({ error: 'فشل جلب الرحلات', details: err.message });
  }
};

// دالة مساعدة لحساب المسافة بين نقطتين
// function calculateDistance(lat1, lon1, lat2, lon2) {
//   const R = 6371; // نصف قطر الأرض بالكيلومترات
//   const dLat = (lat2 - lat1) * Math.PI / 180;
//   const dLon = (lon2 - lon1) * Math.PI / 180;
//   const a = 
//     Math.sin(dLat/2) * Math.sin(dLat/2) +
//     Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) * 
//     Math.sin(dLon/2) * Math.sin(dLon/2);
//   const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
//   return R * c;
// }


// الحصول على الرحلات القريبة من موقع السائق
exports.getNearbyTrips = async (req, res) => {
  try {
    const { latitude, longitude } = req.query;
    console.log('Latitude:', latitude, 'Longitude:', longitude);

    if (!latitude || !longitude) {
      return res.status(400).json({ error: 'يجب توفير خط الطول والعرض' });
    }

    // مستويات المسافات التدريجية (بالكيلومترات)
    const distanceLevels = [5, 15, 30, 100];
    let foundTrips = [];
    let currentDistance = 0;

    // جلب جميع الرحلات المعلقة غير المجدولة أو المجدولة التي حان وقتها
    const pendingTrips = await Trip.find({ 
      status: 'pending',
      $or: [
        { driverId: { $exists: false } },
        { driverId: null }
      ],
      $or: [
        { isScheduled: false }, // الرحلات العادية
        { 
          isScheduled: true,
          scheduledStartTime: { $lte: new Date() } // الرحلات المجدولة التي حان وقتها
        }
      ]
    });

    // البحث التدريجي ضمن مستويات المسافة
    for (const distance of distanceLevels) {
      currentDistance = distance;
      foundTrips = pendingTrips.filter(trip => {
        if (!trip.startLocation || !trip.startLocation.coordinates) return false;
        
        const [tripLon, tripLat] = trip.startLocation.coordinates;
        return calculateDistance(
          parseFloat(latitude),
          parseFloat(longitude),
          tripLat,
          tripLon
        ) <= distance;
      });

      // إذا وجدنا رحلات في هذا المستوى، نتوقف عن البحث
      if (foundTrips.length > 0) break;
    }

    // إذا لم نجد أي رحلات في جميع المستويات
    if (foundTrips.length === 0) {
      console.log('No trips found in any distance level');
      return res.json({
        message: 'لا توجد رحلات متاحة حالياً',
        trips: []
      });
    }

    console.log(`Found ${foundTrips.length} trips within ${currentDistance} km`);

    res.json({
      message: `تم العثور على ${foundTrips.length} رحلة ضمن ${currentDistance} كم`,
      trips: foundTrips,
      searchDistance: currentDistance
    });
  } catch (err) {
    console.error('Error fetching nearby trips:', err);
    res.status(500).json({ 
      error: 'فشل جلب الرحلات القريبة', 
      details: err.message 
    });
  }
};
exports.getPendingUserTrips = async (req, res) => {
  try {
    const { userId } = req.query;
    const trips = await Trip.find({ 
      userId,
      status: 'pending'
    });
    res.json(trips);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

exports.cancelTrip = async (req, res) => {
  try {
    const { id } = req.params;
    const trip = await Trip.findOneAndDelete({ tripId: id });
    if (!trip) {
      return res.status(404).json({ message: 'الرحلة غير موجودة' });
    }
    
    res.json({ message: 'تم إلغاء الرحلة' });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

exports.updateTrip = async (req, res) => {
  try {
    const { id } = req.params;
    const { startLocation, endLocation } = req.body;


    const updateData = {
      updatedAt: new Date()
    };

    if (startLocation.address) {
      updateData['startLocation.address'] = startLocation.address;
    }

    // تحديث موقع النهاية إذا وجد
    if (endLocation.address) {
      updateData['endLocation.address'] = endLocation.address;
    }

    const trip = await Trip.findOneAndUpdate(
      { tripId: id }, 
      { $set: updateData }, 
      { 
        new: true,
        runValidators: true 
      }
    );

    if (!trip) {
      return res.status(404).json({ message: 'الرحلة غير موجودة' });
    }

    console.log('Trip updated successfully:', trip);
    res.json({ 
      success: true,
      message: 'تم تحديث الرحلة بنجاح',
      data: trip 
    });

  } catch (error) {
    console.error('Error updating trip:', error);
    res.status(500).json({ 
      success: false,
      message: 'فشل في تحديث الرحلة',
      error: error.message 
    });
  }
};
