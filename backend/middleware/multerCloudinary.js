const multer = require('multer');
const { CloudinaryStorage } = require('multer-storage-cloudinary');
const cloudinary = require('../utils/cloudinary');

const storage = new CloudinaryStorage({
  cloudinary: cloudinary,
  params: async (req, file) => {
    let folder = 'Taxi-Go/others'; // fallback default

    // مثال: بناءً على المسار، نحدد الفولدر
    if (req.baseUrl.includes('/drivers')) {
      folder = 'Taxi-Go/drivers';
    } else if (req.baseUrl.includes('/clients')) {
      folder = 'Taxi-Go/clients';
    } else if (req.baseUrl.includes('/users')) {
      folder = 'Taxi-Go/users';
    }
    else {
      folder = 'Taxi-Go';
    }

    return {
      folder: folder,
      public_id: `img_${req.params.id}_${Date.now()}`,
      allowed_formats: ['jpg', 'jpeg', 'png', 'webp'],
      transformation: [
        { width: 800, height: 800, crop: 'limit' },
        { quality: 'auto:best' },
        { format: 'webp' }
      ]
    };
  }
});

const fileFilter = (req, file, cb) => {
        console.log('⏺️ multer fileFilter called');

  console.log('Mimetype:', file.mimetype);
  if (file.mimetype.startsWith('image/')) {
    cb(null, true);
  } else {
    cb(new Error('الملف المرفوع ليس صورة! يرجى رفع ملف صالح'), false);
  }
};


const upload = multer({
  storage: storage,
  fileFilter: fileFilter,
  limits: {
    fileSize: 5 * 1024 * 1024 // 5MB كحد أقصى
  }
});

module.exports = upload;