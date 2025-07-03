const Driver = require('../models/Driver');
const RatingHistory = require('../models/RatingHistory');

// معادلة حساب التقييم
const calculateNewRating = (currentRating, impact, actionType) => {
  let newRating = currentRating;
  const maxRating = 100;
  const minRating = 0;

  const weights = {
    trip_completed: 1.0,             
    trip_canceled: 1.8,              
    late_start: 1.3,                 
    quick_response: 0.8,             
    customer_complaint: 2.2,        
    failure_to_start_trip: 3.0 
  };

  const weight = weights[actionType] || 1.0;

  // معامل التعديل العام (كل القيم تضرب فيه لتقليل الحساسية)
  const adjustmentFactor = 0.8;

  newRating += impact * weight * adjustmentFactor;

  return Math.max(minRating, Math.min(maxRating, newRating));
};

// تحديث تقييم السائق
exports.updateDriverRating = async (driverId, impact, actionType) => {
  try {
    const driver = await Driver.findOne({ driverUserId: driverId });
    if (!driver) return;
    
    const currentRating = driver.rating || 80; // افتراضي 80 إذا لم يكن موجوداً
    const newRating = calculateNewRating(currentRating, impact, actionType);
    
    // تحديث تقييم السائق
    driver.rating = newRating;
    await driver.save();
    
    // تسجيل تاريخ التقييم
    await RatingHistory.create({
      driverId,
      previousRating: currentRating,
      newRating,
      impact,
      actionType,
      timestamp: new Date()
    });
    
    return newRating;
  } catch (err) {
    console.error('Error updating driver rating:', err);
    throw err;
  }
};