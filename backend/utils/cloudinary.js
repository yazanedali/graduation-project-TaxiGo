const cloudinary = require('cloudinary').v2;

cloudinary.config({
  cloud_name: 'dc66alhhk',
  api_key: '373385376931459',
  api_secret: 'Zk7gUsacxT5ewG5HAcfv3nuw1SY',
  secure: true // لتفعيل HTTPS
});

module.exports = cloudinary;