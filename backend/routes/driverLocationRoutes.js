// routes/driverLocationRoutes.js
const express = require('express');
const router = express.Router();
const { updateDriverLocation } = require('../controllers/driverLocationController'); // تأكد من المسار

// راوت لتحديث موقع السائق
// يجب أن يكون هذا الراوت محمياً بـ authMiddleware
router.post('/:driverUserId/location', updateDriverLocation);

module.exports = router;