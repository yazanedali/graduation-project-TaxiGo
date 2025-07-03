const express = require('express');
const router = express.Router();
const taxiOfficeMapController = require('../controllers/taxiOfficeMapController');
const taxiOfficeController = require('../controllers/taxiOfficeController'); // إنشاء ملف جديد

// نقاط النهاية الحالية
router.get('/offices', taxiOfficeMapController.getOfficesForMap);
router.get('/offices/:id', taxiOfficeMapController.getOfficeDetails);


module.exports = router;