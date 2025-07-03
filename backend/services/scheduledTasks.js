const Trip = require('../models/Trip'); // تأكد من المسار الصحيح

const checkScheduledTrips = async () => {
  try {
    const now = new Date();
    const tripsToActivate = await Trip.find({
      isScheduled: true,
      scheduledStartTime: { $lte: now },
      status: 'pending'
    });

    if (tripsToActivate.length > 0) {
      console.log(`Activating ${tripsToActivate.length} scheduled trips`);
      // هنا يمكنك إضافة إجراءات إضافية
    }
  } catch (err) {
    console.error('Error checking scheduled trips:', err);
  }
};

module.exports = {
  checkScheduledTrips
};