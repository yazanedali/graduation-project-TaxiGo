const mongoose = require('mongoose');

const driverSchema = new mongoose.Schema({
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    unique: true,
    index: true,
  },
  driverUserId: {
    type: Number,
    required: true,
    index: true,
  },
  
  // الربط مع مكتب التاكسي
  office: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'TaxiOffice',
    required: true,
    index: true
  },
  
  carDetails: {
    model: {
      type: String,
      required: true,
      trim: true
    },
    plateNumber: {
      type: String,
      required: true,
      unique: true,
      trim: true,
      uppercase: true
    },
    color: {
      type: String,
      trim: true
    },
    year: {
      type: Number,
      min: 1990,
      max: new Date().getFullYear()
    }
  },
  
  isAvailable: {
    type: Boolean,
    default: true,
    index: true,
  },
  
  rating: {
    type: Number,
    default: 80,
    min: 0,
    max: 100 
  },
  
  numberOfRatings: {
    type: Number,
    default: 0,
    min: 0
  },
  
  profileImageUrl: {
    type: String,
    default: 'https://static.vecteezy.com/system/resources/previews/027/448/973/non_2x/avatar-account-icon-default-social-media-profile-photo-vector.jpg'
  },
  
  earnings: {
    type: Number,
    default: 0,
    min: 0
  },
  
  // معلومات إضافية
  licenseNumber: {
    type: String,
    required: true,
  },
  
  licenseExpiry: {
    type: Date,
    required: true
  },
  
  joinedAt: {
    type: Date,
    default: Date.now
  },
  
  // ✅ إضافة حقل الموقع الحالي للسائق
currentLocation: {
  type: {
    type: String, // لازم يكون "Point"
    enum: ['Point'],
    default: 'Point',
  },
  coordinates: {
    type: [Number],
    default: [35.2137, 31.7683] // ⚠️ مثال: القدس (longitude, latitude)
  }
}
}, { 
  timestamps: true,
  toJSON: { virtuals: true },
  toObject: { virtuals: true }
});

// ✅ إنشاء مؤشر 2dsphere للاستعلامات الجغرافية المكانية
driverSchema.index({ currentLocation: '2dsphere' });

// Middleware لتحديث عدد السائقين عند الحذف
driverSchema.post('save', async function(doc) {
  await updateDriversCount(doc.office);
});

driverSchema.post('remove', async function(doc) {
  await updateDriversCount(doc.office);
});

async function updateDriversCount(officeId) {
  const count = await mongoose.model('Driver').countDocuments({ office: officeId });
  await mongoose.model('TaxiOffice').findByIdAndUpdate(officeId, { driversCount: count });
}

const Driver = mongoose.model('Driver', driverSchema);

module.exports = Driver;