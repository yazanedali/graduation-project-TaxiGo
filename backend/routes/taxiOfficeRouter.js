const express = require('express');
const router = express.Router();
const taxiOfficeController = require('../controllers/taxiOfficeController');



router.get('/:id/drivers', taxiOfficeController.getOfficeDrivers);
router.get('/:id/earnings', taxiOfficeController.getTotalEarnings);
router.get('/:id/stats', taxiOfficeController.getOfficeStats);
router.get('/:id/daily-stats', taxiOfficeController.getDailyStats);
router.post('/:id/drivers', taxiOfficeController.createDriver);


module.exports = router;