const Trip = require('../models/Trip');
const User = require('../models/User');

exports.getCompletedPayments = async (req, res) => {
  try {
    const completedTrips = await Trip.find({ status: 'completed' }).sort({ endTime: -1 });

    // جيب كل المستخدمين (driver + user) اللي إجا عليهم رحلات
    const userIds = completedTrips.map(trip => trip.userId);
    const driverIds = completedTrips.map(trip => trip.driverId).filter(Boolean); // استثني undefined/null

    // دمج الأرقام بدون تكرار
    const allIds = [...new Set([...userIds, ...driverIds])];

    // جيب بياناتهم من جدول المستخدمين
    const users = await User.find({ userId: { $in: allIds } }, 'userId fullName phone');

    // اعمل Map لسهولة الوصول
    const userMap = new Map();
    users.forEach(u => {
      userMap.set(u.userId, u);
    });

    // جهّز الرد
const data = completedTrips.map(trip => {
  const user = userMap.get(trip.userId);
  const driver = userMap.get(trip.driverId);

  return {
    id: trip._id,
    tripId: trip.tripId,
    user: {
      name: user?.fullName || 'Unknown',
      phone: user?.phone || 'N/A'
    },
    driver: {
      name: driver?.fullName || 'Unknown',
      phone: driver?.phone || 'N/A'
    },
    amount: trip.actualFare,
    date: trip.endTime,
    paymentMethod: trip.paymentMethod,
    status: 'completed'
  };
});


    res.json({ success: true, data });
  } catch (error) {
    console.error(error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch payments'
    });
  }
};
