const TaxiOffice = require('../models/TaxiOffice');

// الحصول على جميع مكاتب التكاسي للخريطة
exports.getOfficesForMap = async (req, res) => {
  try {
    const { minLat, maxLat, minLng, maxLng } = req.query;
    
    let filter = { isActive: true };
    
    // إذا كانت هناك حدود للخريطة، نضيفها للفلتر
    if (minLat && maxLat && minLng && maxLng) {
      filter.location = {
        $geoWithin: {
          $box: [
            [parseFloat(minLng), parseFloat(minLat)],
            [parseFloat(maxLng), parseFloat(maxLat)]
          ]
        }
      };
    }

    const offices = await TaxiOffice.find(filter)
      .select('name location latitude longitude contact imageUrl workingHours')
      .lean();

res.status(200).json({
  success: true,
  data: offices.map(office => ({
    id: office._id,
    name: office.name,
    address: office.location.address,
    coordinates: {
      latitude: office.location.coordinates[1],  // latitude = y
      longitude: office.location.coordinates[0]  // longitude = x
    },
    phone: office.contact.phone,
    imageUrl: office.imageUrl,
    workingHours: office.workingHours
  }))
});
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

// الحصول على تفاصيل مكتب معين
exports.getOfficeDetails = async (req, res) => {
  try {
    const officeId = parseInt(req.params.id); // تحويل إلى رقم
    
    if (isNaN(officeId)) {
      return res.status(400).json({
        success: false,
        message: 'معرف المكتب غير صالح'
      });
    }
    
    // البحث باستخدام officeId بدلاً من _id
    const office = await TaxiOffice.findOne({ officeId })
      .populate('manager', 'fullName phone')
      .select('-__v -createdAt -updatedAt');

    if (!office) {
      return res.status(404).json({
        success: false,
        message: 'المكتب غير موجود'
      });
    }

    res.status(200).json({
      success: true,
      data: office
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};