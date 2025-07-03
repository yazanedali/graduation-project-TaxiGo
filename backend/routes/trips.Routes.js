const express = require('express');
const router = express.Router();
const tripController = require('../controllers/tripsController');

// إنشاء رحلة جديدة من قبل المستخدم
router.post('/', tripController.createTrip);

//get all trips 
router.get('/', tripController.getAllTrips);

// قبول الرحلة من السائق
router.post('/:tripId/accept', tripController.acceptTrip);

// رفض الرحلة من السائق
router.post('/:tripId/reject', tripController.rejectTrip);

// إنهاء الرحلة
router.post('/:tripId/complete', tripController.completeTrip);

// جلب جميع الرحلات (اختياري - يمكن تخصيصه لاحقًا)
// router.get('/trips', tripController.getAllTrips);

// جلب تفاصيل رحلة واحدة (يمكنك تعديلها لاحقاً لجلب رحلة برقم ID مثلاً)
// router.get('/trips/:tripId', tripController.getTripById);

// ✅ جلب جميع الرحلات لسائق معيّن
// router.get('/driver/:driverId', tripController.getDriverTrips);

// ✅ جلب آخر 3 رحلات فقط لسائق معيّن
router.get('/driver/:driverId/recent', tripController.getDriverRecentTrips);

// بدأ الرحلة من قبل السائق
router.post('/:tripId/start', tripController.startTrip);

// جلب الرحلات بناءً على الحالة (مثلاً: قيد التنفيذ، مكتملة، ملغاة، إلخ)
router.get('/driver/:driverId/status', tripController.getDriverTripsByStatus);

// جلب رحلات المستخدم بناءً على الحالة
router.get('/user/:userId/status', tripController.getUserTripsByStatus);


// GET /api/trips/driver/:driverId
router.get('/driver/:driverId', tripController.getDriverTrips);

// PUT /api/trips/:tripId/status
router.put('/:tripId/status', tripController.updateTripStatus);

// GET /api/trips/pending
router.get('/pending', tripController.getPendingTrips);

// GET /api/trips/nearby    
router.get('/nearby', tripController.getNearbyTrips);


router.get('/PendingUserTrips', tripController.getPendingUserTrips);

router.delete('/:id', tripController.cancelTrip);

router.put('/:id', tripController.updateTrip);

module.exports = router;
