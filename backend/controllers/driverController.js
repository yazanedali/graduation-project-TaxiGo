
const Driver = require('../models/Driver');
const User = require('../models/User');
const cloudinary = require('../utils/cloudinary');

const TaxiOffice = require('../models/TaxiOffice');

exports.getAllDrivers = async (req, res) => {
  try {
    // نستخدم find({}) بدون شروط لجلب كل السائقين
    const allDrivers = await Driver.find({})
      .populate({
        path: 'user',           
        select: 'fullName userId email phone' 
                                    
      })
      .select('user carDetails rating numberOfRatings profileImageUrl taxiOffice isAvailable')
      .lean();
    res.status(200).json(allDrivers);

  } catch (error) {
    console.error("Error fetching all drivers:", error);
    res.status(500).json({ message: "حدث خطأ أثناء جلب جميع السائقين", error: error.message });
  }
};

exports.getAvailableDrivers = async (req, res) => {
  try {
    const availableDrivers = await Driver.find({ isAvailable: true })
  
      .populate({
        path: 'user',           
        select: 'fullName userId email phone' 
                                    
      })
      .select('user carDetails rating numberOfRatings profileImageUrl taxiOffice isAvailable')
      .lean();

    res.status(200).json(availableDrivers);

  } catch (error) {
    console.error("Error fetching available drivers:", error);
    res.status(500).json({ message: "حدث خطأ أثناء جلب السائقين المتاحين", error: error.message });
  }
};


exports.getDriverById = async (req, res) => {
  try {
    const driverId = req.params.id;

    // البحث باستخدام driverUserId بدلاً من _id
    const driver = await Driver.findOne({ driverUserId: driverId })
      .populate({
        path: 'user',
        select: 'fullName userId email phone profilePhoto'
      })
      .select('user carDetails rating taxiOffice isAvailable currentLocation licenseNumber profileImageUrl')
      .lean();

    if (!driver) {
      return res.status(404).json({ message: "لم يتم العثور على السائق" });
    }

    // تحسين هيكل البيانات المرتجع
    const response = {
      ...driver,
      user: {
        ...driver.user,
        profilePhoto: driver.user.profilePhoto 
          ? `${req.protocol}://${req.get('host')}/uploads/${driver.user.profilePhoto}`
          : null
      }
    };

    res.status(200).json(response);

  } catch (error) {
    console.error("Error fetching driver by ID:", error);
    res.status(500).json({ 
      message: "حدث خطأ أثناء جلب بيانات السائق",
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// في ملف routes/drivers.js
exports.updateAvailability = async (req, res) => {
  try {
    const { id } = req.params;
    const { isAvailable } = req.body;
    console.log('تم استلام طلب تحديث حالة التوفر للسائق:', id, 'حالة التوفر:', isAvailable);

    // البحث باستخدام findById أولاً للتحقق
    // التحديث
    const updatedDriver = await Driver.findOneAndUpdate(
      {driverUserId: id},
      { isAvailable },
      { new: true }
    );
    if (!updatedDriver) {
      console.log('لم يتم العثور على السائق:', id);
      return res.status(404).json({ message: 'Driver not found' });
    }


    res.status(200).json(updatedDriver);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// controllers/driverController.js
exports.uploadDriverImage = async (req, res) => {
  try {
    const { id } = req.params;

    // التحقق من صحة الـ ID
    // if (!mongoose.Types.ObjectId.isValid(id)) {
    //   return res.status(400).json({
    //     success: false,
    //     message: 'معرف السائق غير صالح'
    //   });
    // }
    console.log('تم استلام طلب رفع صورة السائق:', id);
    console.log('req.file: ', req.file);
    // التحقق من وجود ملف مرفوع
    if (!req.file) {
      return res.status(400).json({
        success: false,
        message: 'لم يتم اختيار أي صورة للرفع'
      });
    }
    
        console.log('req.file: ', req.file);
// البحث عن السائق وتحديث الصورة
    const driver = await Driver.findOne({ driverUserId: id });
    
    if (!driver) {
      return res.status(404).json({
        success: false,
        message: 'السائق غير موجود'
      });
    }

    // حذف الصورة القديمة إذا كانت موجودة
    if (driver.profileImageUrl) {
      const publicId = driver.profileImageUrl
        .split('/')
        .pop()
        .split('.')[0];
      
      await cloudinary.uploader.destroy(`Taxi-Go/drivers/${publicId}`);
    }

    // تحديث بيانات السائق
    driver.profileImageUrl = req.file.path; // يحتوي على رابط Cloudinary
    await driver.save();

    res.status(200).json({
      success: true,
      message: 'تم تحديث صورة السائق بنجاح',
      imageUrl: req.file.path,
      driver: {
        id: driver._id,
        name: driver.fullName,
        image: driver.profileImageUrl
      }
    });

  } catch (error) {
    console.error('حدث خطأ أثناء تحديث الصورة:', error);
    res.status(500).json({
      success: false,
      message: 'فشل تحديث الصورة',
      error: error.message
    });
  }
};


exports.updateDriverProfile = async (req, res) => {
  try {
    const { driverId } = req.params;
    console.log('تم استلام طلب تحديث ملف السائق:', driverId);
    const {
      fullName,
      email,
      phone,
      carModel,
      carColor,
      carPlateNumber,
      licenseNumber,
      licenseExpiry,
      profileImageUrl,
    } = req.body;

    // البحث عن السائق والتأكد من وجوده
    const driver = await Driver.findOne({ driverUserId: driverId });
    if (!driver) {
      return res.status(404).json({ 
        success: false,
        message: 'السائق غير موجود' 
      });
    }

    // تحديث بيانات السائق (بدون taxiOfficeId)
    driver.fullName = fullName || driver.fullName;
    driver.email = email || driver.email;
    driver.phone = phone || driver.phone;
    driver.carModel = carModel || driver.carModel;
    driver.carColor = carColor || driver.carColor;
    driver.carPlateNumber = carPlateNumber || driver.carPlateNumber;
    driver.licenseNumber = licenseNumber || driver.licenseNumber;
    driver.licenseExpiry = licenseExpiry ? new Date(licenseExpiry) : driver.licenseExpiry;
    
    if (profileImageUrl) {
      driver.profileImageUrl = profileImageUrl;
    }
    console.log('تم تحديث بيانات السائق:', driver);

    await driver.save();

    res.status(200).json({
      success: true,
      message: 'تم تحديث الملف الشخصي بنجاح',
      driver: {
        id: driver._id,
        fullName: driver.fullName,
        phone: driver.phone,
        email: driver.email,
        carModel: driver.carModel,
        carColor: driver.carColor,
        carPlateNumber: driver.carPlateNumber,
        licenseNumber: driver.licenseNumber,
        licenseExpiry: driver.licenseExpiry,
        profileImageUrl: driver.profileImageUrl
      }
    });

  } catch (err) {
    console.error('حدث خطأ أثناء تحديث الملف الشخصي:', err);
    res.status(500).json({ 
      success: false,
      message: 'خطأ في السيرفر',
      error: err.message 
    });
  }
};

 exports.getDriverStatusByUserId = async (req, res) => {
  try {
    const userId = req.params.userId; // هذا هو الـ userId الرقمي من موديل User

    // ابحث عن وثيقة السائق التي ترتبط بهذا الـ userId الرقمي
    const driver = await Driver.findOne({ driverUserId: userId }).select('isAvailable fullName');

    if (!driver) {
      return res.status(404).json({ message: 'Driver details not found for this user ID.' });
    }

    // إرسال isAvailable وحقول أخرى قد تحتاجها في الـ frontend
    res.json({
      isAvailable: driver.isAvailable,
      fullName: driver.fullName // يمكنك إرجاع الاسم الكامل للسائق إذا أردت
    });

  } catch (error) {
    console.error("Error fetching driver status by user ID:", error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

// ✅ الدالة الجديدة: جلب مدير المكتب لسائق معين
exports.getManagerForDriver = async (req, res) => {
  try {
    const { driverUserId } = req.body;
console.log('تم استلام طلب جلب مدير المكتب للسائق:', driverUserId);
    if (!driverUserId) {
      return res.status(400).json({ message: 'Driver user ID is required in the body' });
    }

    // 1. البحث عن السائق باستخدام driverUserId
    const driver = await Driver.findOne({ driverUserId: driverUserId });
    if (!driver) {
      return res.status(404).json({ message: 'Driver not found' });
    }

    // 2. البحث عن مكتب التاكسي و "ملء" بيانات المدير المرتبط به، ثم "ملء" بيانات المستخدم للمدير
    //    هنا نستخدم populate المتعدد المستويات للحصول على كل البيانات المطلوبة في استعلام واحد
    const office = await TaxiOffice.findById(driver.office).populate({
      path: 'manager', // اسم الحقل في TaxiOffice schema
      model: 'Manager',
      populate: {
        path: 'user', // اسم الحقل في Manager schema
        model: 'User',
        select: 'fullName profileImageUrl' // نختار فقط الاسم والصورة لتخفيف حجم الاستجابة
      }
    });
console.log('تم العثور على المكتب:', office);
    if (!office || !office.manager || !office.manager.user) {
      return res.status(404).json({ message: 'Manager information for this driver could not be found.' });
    }
    
    // 3. تجهيز بيانات المدير لإرسالها
    const managerInfo = {
      id: office.manager.userId, // الـ ID الرقمي من جدول Manager
      fullName: office.manager.user.fullName, // الاسم من جدول User
      profileImageUrl: office.manager.user.profileImageUrl, // الصورة من جدول User
      role: 'Manager', // تحديد الدور ليكون واضحًا في الـ frontend
      officeId: office.officeId // ✅ أضف هذه المعلومة المهمة

    };

    res.status(200).json(managerInfo);

  } catch (error) {
    console.error('Error fetching driver manager:', error);
    res.status(500).json({ message: 'Server error while fetching manager data.' });
  }
};