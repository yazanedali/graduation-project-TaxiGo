const mongoose = require('mongoose');

const ratingHistorySchema = new mongoose.Schema({
  driverId: { type: Number, required: true },
  previousRating: { type: Number, required: true },
  newRating: { type: Number, required: true },
  impact: { type: Number, required: true },
  actionType: { 
    type: String,
    enum: [
      'trip_completed',
      'trip_canceled',
      'late_start',
      'quick_response',
      'customer_complaint',
      'failure_to_start_trip'
    ],
    required: true
  },
  tripId: { type: Number }, // مرتبط برحلة معينة إذا وجدت
  timestamp: { type: Date, default: Date.now }
});

module.exports = mongoose.model('RatingHistory', ratingHistorySchema);