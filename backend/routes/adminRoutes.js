const express = require('express');
const router = express.Router();
const adminController = require('../controllers/adminController.js');

// إضافة نقطة نهاية جديدة
router.post('/offices/with-manager', adminController.createTaxiOfficeWithManager);
router.get('/offices', adminController.getAllOfficesWithManagers);

module.exports = router;