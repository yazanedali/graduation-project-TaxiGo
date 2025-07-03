const express = require('express');
const clientController = require('../controllers/clientController');
const upload = require('../middleware/multerCloudinary');

const router = express.Router();

// GET /api/clients/
router.get('/', clientController.getAllClients);

// GET /api/ /:id
router.get('/:id', clientController.getClientById);

// PUT /api/clients/:id/status
router.put('/:id/availability', clientController.updateAvailability);

// تحديث صورة العميل
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
  clientController.uploadClientImage
);

router.put('/:id', clientController.editClientProfile);

module.exports = router;
