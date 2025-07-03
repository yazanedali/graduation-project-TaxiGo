// routes/driverRoutes.js
const express = require('express');
const driverController = require('../controllers/driverController');
const upload = require('../middleware/multerCloudinary');
const Driver = require('../models/Driver');
const TaxiOffice = require('../models/TaxiOffice');

// قد تحتاج إلى middleware للتحقق من المصادقة في مسارات أخرى
// const { protect, isUser } = require('../middleware/authMiddleware');

const router = express.Router();


// GET /api/drivers/
router.get('/', driverController.getAllDrivers);

// GET /api/drivers/available
router.get('/available', driverController.getAvailableDrivers);

router.get('/:id', driverController.getDriverById);
router.post('/get-manager', driverController.getManagerForDriver);


// في ملف routes/drivers.js
router.put('/:id/availability',driverController.updateAvailability);

// تحديث صورة السائق
router.put(
  '/:id/profile-image',
  (req, res, next) => {
    upload.single('image')(req, res, function (err) {
      if (err) {
        console.error('Multer error:', err);
        return res.status(400).json({ 
          success: false,
          message: err.message 
        });
      }
      next();
    });
  },
  driverController.uploadDriverImage
);

router.put('/:driverId', driverController.updateDriverProfile);
router.get('/status/:userId', driverController.getDriverStatusByUserId); // ✅ هذا هو الراوت الجديد

const { updateDriverLocation } = require('../controllers/driverLocationController'); // تأكد من المسار

// راوت لتحديث موقع السائق
// يجب أن يكون هذا الراوت محمياً بـ authMiddleware
router.post('/:driverUserId/location', updateDriverLocation);

// Get office manager for a specific driver
router.get('/:driverId/manager', async (req, res) => {
  try {
    const driverId = req.params.driverId;
    
    // Find the driver and get their office ID
    const driver = await Driver.findOne({ driverUserId: driverId });
    if (!driver) {
      return res.status(404).json({ message: 'Driver not found' });
    }

    // Find the office and get the manager's information
    const office = await TaxiOffice.findOne({ officeId: driver.officeId });
    if (!office) {
      return res.status(404).json({ message: 'Office not found' });
    }

    // Get manager's information
    const manager = {
      id: office.managerId,
      fullName: office.managerName,
      profileImage: office.managerImage,
      officeId: office.officeId
    };

    res.status(200).json(manager);
  } catch (error) {
    console.error('Error getting driver manager:', error);
    res.status(500).json({ message: 'Error getting driver manager' });
  }
});

module.exports = router;