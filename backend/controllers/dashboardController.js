// controllers/dashboardController.js
const Trip = require('../models/Trip');
const Driver = require('../models/Driver');
const User = require('../models/User');
const Client = require('../models/client');

exports.getDashboardData = async (req, res) => {
  try {
    // تاريخ اليوم
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    
    // تاريخ الأسبوع الماضي
    const lastWeek = new Date();
    lastWeek.setDate(lastWeek.getDate() - 7);
    lastWeek.setHours(0, 0, 0, 0);

    // جلب البيانات بشكل متوازي لتحسين الأداء
    const [
      todayTripsCount,
      availableDriversCount,
      newUsersCount,
      revenueToday,
      weeklyTripsData,
      activeDriversCount,
      totalDriversCount
    ] = await Promise.all([
      // عدد الرحلات اليوم
      Trip.countDocuments({
        createdAt: { $gte: today },
        status: { $in: ['completed', 'in_progress'] }
      }),
      
      // عدد السائقين المتاحين
      Driver.countDocuments({ isAvailable: true }),
      
      // عدد المستخدمين الجدد اليوم
      Client.countDocuments({ createdAt: { $gte: today } }),
      
      // إيرادات اليوم
      Trip.aggregate([
        {
          $match: {
            status: 'completed',
            endTime: { $gte: today }
          }
        },
        {
          $group: {
            _id: null,
            total: { $sum: '$actualFare' }
          }
        }
      ]),
      
      // بيانات الرحلات الأسبوعية
      Trip.aggregate([
        {
          $match: {
            createdAt: { $gte: lastWeek }
          }
        },
        {
          $group: {
            _id: { $dayOfWeek: '$createdAt' },
            count: { $sum: 1 }
          }
        },
        {
          $sort: { '_id': 1 }
        }
      ]),
      
      // عدد السائقين النشطين (الذين قبلوا رحلات اليوم)
      Trip.distinct('driverId', {
        createdAt: { $gte: today },
        status: { $in: ['accepted', 'in_progress', 'completed'] }
      }),
      
      // إجمالي عدد السائقين
      Driver.countDocuments()
    ]);

    // معالجة بيانات الإيرادات
    const revenue = revenueToday[0]?.total || 0;

    // معالجة بيانات الرحلات الأسبوعية
    const weeklyTrips = [0, 0, 0, 0, 0, 0, 0];
    weeklyTripsData.forEach(item => {
      // في MongoDB، يوم الأحد = 1، السبت = 7
      // نضبطها لتكون السبت = 0، الأحد = 1، ... الجمعة = 6
      const dayIndex = item._id === 1 ? 6 : item._id - 2;
      weeklyTrips[dayIndex] = item.count;
    });

    // حساب نسبة السائقين النشطين
    const activeDriversPercentage = totalDriversCount > 0 
      ? (activeDriversCount.length / totalDriversCount) * 100 
      : 0;

    res.json({
      todayTrips: todayTripsCount,
      availableDrivers: availableDriversCount,
      newUsers: newUsersCount,
      revenueToday: revenue,
      weeklyTrips,
      activeDriversPercentage: parseFloat(activeDriversPercentage.toFixed(2))
    });

  } catch (error) {
    console.error('Error fetching dashboard data:', error);
    res.status(500).json({ 
      error: 'Failed to load dashboard data',
      details: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};