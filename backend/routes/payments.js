const express = require('express');
const router = express.Router();
const paymentsController = require('../controllers/paymentsController');

router.get('/completed', paymentsController.getCompletedPayments);

module.exports = router;