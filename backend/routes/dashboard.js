const express = require('express');
const router = express.Router();
const dashboardController = require('../controllers/dashboardController');

// جلب بيانات لوحة التحكم
router.get('/', dashboardController.getDashboardData);

module.exports = router;