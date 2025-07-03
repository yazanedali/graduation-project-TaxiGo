const mongoose = require('mongoose');
const TaxiOffice = require('../models/TaxiOffice');
const Driver = require('../models/Driver');
const Trip = require('../models/Trip');
const User = require('../models/User');
const Manager = require('../models/Manager');
const bcrypt = require('bcryptjs');
const nodemailer = require('nodemailer');

// الحصول على جميع السائقين التابعين لمكتب التاكسي باستخدام managerId
exports.getOfficeDrivers = async (req, res) => {
  try {
    console.log('Fetching drivers for manager with ID:', req.params.id);
    const managerId = parseInt(req.params.id);
    
    if (isNaN(managerId)) {
      return res.status(400).json({ success: false, message: 'معرف المدير غير صالح' });
    }
    
    const manager = await Manager.findOne({ userId: managerId });
    if (!manager) {
      return res.status(404).json({ success: false, message: 'المدير غير موجود' });
    }
    
    const office = await TaxiOffice.findById(manager.office);
    if (!office) {
      return res.status(404).json({ success: false, message: 'المكتب غير موجود' });
    }
    
    const drivers = await Driver.find({ office: office._id })
      .populate({
        path: 'user',
        select: 'fullName phone email userId' // تأكد من تضمين userId هنا
      })
      .select('driverUserId carDetails isAvailable rating profileImageUrl earnings licenseNumber licenseExpiry joinedAt');
    
    res.status(200).json({
      success: true,
      data: drivers
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

// حساب إجمالي الأرباح لجميع السائقين في المكتب
exports.getTotalEarnings = async (req, res) => {
  try {
    const managerId = parseInt(req.params.id);
    
    if (isNaN(managerId)) {
      return res.status(400).json({ success: false, message: 'معرف المدير غير صالح' });
    }
    
    // البحث عن المدير
    const manager = await Manager.findOne({ userId: managerId });
    
    if (!manager) {
      return res.status(404).json({ success: false, message: 'المدير غير موجود' });
    }
    
    // البحث عن المكتب
    const office = await TaxiOffice.findById(manager.office);
    
    if (!office) {
      return res.status(404).json({ success: false, message: 'المكتب غير موجود' });
    }
    
    const result = await Driver.aggregate([
      { $match: { office: office._id } },
      { $group: { _id: null, totalEarnings: { $sum: "$earnings" } } }
    ]);
    
    const totalEarnings = result.length > 0 ? result[0].totalEarnings : 0;
    
    res.status(200).json({
      success: true,
      data: { totalEarnings }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

// الحصول على إحصائيات المكتب (عدد السائقين وعدد الرحلات)
exports.getOfficeStats = async (req, res) => {
  console.log('Fetching stats for manager with ID:', req.params.id);
  try {
    const managerId = parseInt(req.params.id);
    
    if (isNaN(managerId)) {
      return res.status(400).json({ success: false, message: 'معرف المدير غير صالح' });
    }
    
    // البحث عن المدير
    const manager = await Manager.findOne({ userId: managerId });
    
    if (!manager) {
      return res.status(404).json({ success: false, message: 'المدير غير موجود' });
    }
    
    // البحث عن المكتب
    const office = await TaxiOffice.findById(manager.office);
    
    if (!office) {
      return res.status(404).json({ success: false, message: 'المكتب غير موجود' });
    }
    
    // عدد السائقين
    const driversCount = await Driver.countDocuments({ office: office._id });
    
    // عدد الرحلات
    const drivers = await Driver.find({ office: office._id }).select('_id');
    const driverIds = drivers.map(driver => driver._id);
    
    const tripsCount = await Trip.countDocuments({ driver: { $in: driverIds } });
    
    res.status(200).json({
      success: true,
      data: { driversCount, tripsCount }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

// الحصول على إحصائيات اليوم (أرباح اليوم وعدد الرحلات اليومية)
exports.getDailyStats = async (req, res) => {
  console.log('Fetching daily stats for manager with ID:', req.params.id);
  try {
    const managerId = parseInt(req.params.id);
    
    if (isNaN(managerId)) {
      return res.status(400).json({ success: false, message: 'معرف المدير غير صالح' });
    }
    
    // البحث عن المدير
    const manager = await Manager.findOne({ userId: managerId });
    
    if (!manager) {
      return res.status(404).json({ success: false, message: 'المدير غير موجود' });
    }
    
    // البحث عن المكتب
    const office = await TaxiOffice.findById(manager.office);
    
    if (!office) {
      return res.status(404).json({ success: false, message: 'المكتب غير موجود' });
    }
    
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);
    
    // الحصول على سائقي المكتب
    const drivers = await Driver.find({ office: office._id }).select('_id');
    const driverIds = drivers.map(driver => driver._id);
    
    // تجميع رحلات اليوم
    const tripsAggregate = await Trip.aggregate([
      {
        $match: {
          driver: { $in: driverIds },
          createdAt: { $gte: today, $lt: tomorrow }
        }
      },
      {
        $group: {
          _id: null,
          dailyTripsCount: { $sum: 1 },
          dailyEarnings: { $sum: "$fare" }
        }
      }
    ]);
    
    const dailyStats = tripsAggregate.length > 0 
      ? { 
          dailyTripsCount: tripsAggregate[0].dailyTripsCount, 
          dailyEarnings: tripsAggregate[0].dailyEarnings 
        }
      : { dailyTripsCount: 0, dailyEarnings: 0 };
    
    res.status(200).json({
      success: true,
      data: dailyStats
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};


function generateRandomPassword(length = 10) {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
  let result = '';
  for (let i = 0; i < length; i++) {
    result += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return result;
}

// إنشاء سائق جديد من قبل مدير المكتب

exports.createDriver = async (req, res) => {
  let newUser = null;
  let newDriver = null;
  let officeToUpdate = null; // للمساعدة في التراجع عن تحديث المكتب

  try {
    console.log('Creating driver for manager with ID:', req.params.id);
    const managerId = parseInt(req.params.id);

    if (isNaN(managerId)) {
      return res.status(400).json({ success: false, message: 'معرف المدير غير صالح' });
    }

    const manager = await Manager.findOne({ userId: managerId });

    if (!manager) {
      return res.status(404).json({ success: false, message: 'المدير غير موجود' });
    }

    const {
      fullName, email, phone, gender,
      carModel, carPlateNumber, carColor, carYear,
      licenseNumber, licenseExpiry, profileImageUrl
    } = req.body;

    // ✅ 1. التحقق من وجود المكتب
    const office = await TaxiOffice.findById(manager.office);
    if (!office) {
      return res.status(404).json({
        success: false,
        message: 'مكتب التكاسي غير موجود'
      });
    }
    officeToUpdate = office; // احتفظ بالمكتب للتعويض إذا لزم الأمر

    // ✅ 2. التحقق من عدم وجود مستخدم بنفس الإيميل أو رقم الهاتف
    const existingUser = await User.findOne({
      $or: [
        { email: email },
        { phone: phone }
      ]
    });

    if (existingUser) {
      return res.status(400).json({
        success: false,
        message: 'يوجد حساب مستخدم بالفعل بهذا البريد الإلكتروني أو رقم الهاتف.'
      });
    }

    // ✅ 3. إنشاء كلمة مرور مؤقتة
    const tempPassword = generateRandomPassword();
    const hashedPassword = await bcrypt.hash(tempPassword, 10);

    // --- بدء العمليات التي تحتاج للتعويض ---

    // ✅ 4. إنشاء المستخدم (السائق)
    // إذا فشلت هذه الخطوة، فلا يوجد شيء للتراجع عنه بعد.
    newUser = new User({
      fullName,
      email,
      phone,
      password: hashedPassword,
      role: 'Driver',
      gender
    });
    await newUser.save();
    console.log('User created:', newUser._id);

    // ✅ 5. إنشاء سجل السائق
    // إذا فشلت هذه الخطوة، يجب التراجع عن إنشاء المستخدم.
    newDriver = new Driver({
      user: newUser._id,
      driverUserId: newUser.userId, // تأكد أن لديك هذا الحقل في موديل Driver أو قم بإزالته
      office: office._id,
      officeIdentifier: office.officeIdentifier,
      carDetails: {
        model: carModel,
        plateNumber: carPlateNumber,
        color: carColor || 'غير محدد',
        year: carYear || new Date().getFullYear()
      },
      licenseNumber,
      licenseExpiry: new Date(licenseExpiry),
      isAvailable: false,
      rating: 0,
      numberOfRatings: 0,
      profileImageUrl: profileImageUrl || undefined,
      earnings: 0
    });
    await newDriver.save();
    console.log('Driver record created:', newDriver._id);

    // ✅ 6. تحديث المكتب بإضافة السائق
    // إذا فشلت هذه الخطوة، يجب التراجع عن إنشاء المستخدم والسائق.
    await TaxiOffice.findByIdAndUpdate(office._id, {
      $addToSet: { drivers: newDriver._id }
    });
    console.log('TaxiOffice updated with new driver.');

    // --- انتهت العمليات الأساسية على قاعدة البيانات ---

    // ✅ 7. إرسال البريد الإلكتروني (هذه عملية خارجية، فشلها لا يستدعي التراجع عن DB)
    const transporter = nodemailer.createTransport({
      service: 'gmail',
      auth: {
        user: process.env.EMAIL,
        pass: process.env.EMAIL_PASSWORD
      }
    });

    const mailOptions = {
      from: process.env.EMAIL,
      to: email,
      subject: `مرحباً بك كسائق في مكتب ${office.name}`,
      html: `
<!DOCTYPE html>
<html dir="rtl" lang="ar">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>تفعيل حساب السائق</title>
  <style>
    @import url('https://fonts.googleapis.com/css2?family=Tajawal:wght@400;700&display=swap');
    body {
      font-family: 'Tajawal', sans-serif;
      background-color: #f5f7fa;
      margin: 0;
      padding: 0;
    }
    .container {
      max-width: 600px;
      margin: 0 auto;
      background: white;
      border-radius: 16px;
      overflow: hidden;
      box-shadow: 0 8px 24px rgba(0, 0, 0, 0.08);
    }
    .header {
      background: linear-gradient(135deg, #1e3a8a 0%, #3b82f6 100%);
      padding: 30px;
      text-align: center;
    }
    .header h1 {
      color: white;
      margin: 0;
      font-size: 28px;
    }
    .logo {
      height: 60px;
      margin-bottom: 20px;
    }
    .content {
      padding: 30px;
    }
    .card {
      background: #fff9e6;
      border-left: 4px solid #facc15;
      border-radius: 8px;
      padding: 20px;
      margin: 20px 0;
    }
    .info-grid {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 15px;
      margin: 20px 0;
    }
    .info-item {
      background: #f0f4f8;
      padding: 12px;
      border-radius: 8px;
    }
    .info-item.blue {
      background: #dbeafe;
      border-left: 3px solid #3b82f6;
    }
    .info-item.yellow {
      background: #fef9c3;
      border-left: 3px solid #facc15;
    }
    .info-item.green {
      background: #dcfce7;
      border-left: 3px solid #22c55e;
    }
    .btn {
      display: inline-block;
      background: linear-gradient(to right, #3b82f6, #1e40af);
      color: white !important;
      padding: 12px 30px;
      border-radius: 50px;
      text-decoration: none;
      font-weight: bold;
      margin: 15px 0;
      text-align: center;
      box-shadow: 0 4px 12px rgba(59, 130, 246, 0.3);
    }
    .footer {
      background: #1e3a8a;
      color: white;
      padding: 20px;
      text-align: center;
      font-size: 12px;
    }
    .highlight {
      color: #1e40af;
      font-weight: bold;
    }
    .divider {
      height: 2px;
      background: linear-gradient(to right, #3b82f6, #facc15);
      margin: 25px 0;
      opacity: 0.3;
    }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <img src="https://banner2.cleanpng.com/20181130/qpi/kisspng-taxi-vector-graphics-clip-art-computer-icons-illus-8-5c0113fad858b8.9638408115435745228862.jpg" alt="TaxiGo Logo" class="logo">
      <h1>مرحباً بك كسائق في نظام TaxiGo</h1>
    </div>
    
    <div class="content">
      <h2 style="color: #1e3a8a;">تم إنشاء حسابك بنجاح!</h2>
      
      <div class="card">
        <h3 style="color: #3b82f6; margin-top: 0;">معلومات المكتب</h3>
        <div class="info-grid">
          <div class="info-item blue">
            <strong>اسم المكتب:</strong><br>
            ${office.name}
          </div>
          <div class="info-item blue">
            <strong>رقم المكتب:</strong><br>
            ${office.officeIdentifier}
          </div>
          <div class="info-item blue">
            <strong>العنوان:</strong><br>
            ${office.location.address}
          </div>
          <div class="info-item blue">
            <strong>هاتف المكتب:</strong><br>
            ${office.contact.phone}
          </div>
        </div>
      </div>
      
      <div class="divider"></div>
      
      <div class="card">
        <h3 style="color: #d97706; margin-top: 0;">بيانات الحساب</h3>
        <div class="info-grid">
          <div class="info-item yellow">
            <strong>الاسم الكامل:</strong><br>
            ${fullName}
          </div>
          <div class="info-item yellow">
            <strong>البريد الإلكتروني:</strong><br>
            ${email}
          </div>
          <div class="info-item yellow">
            <strong>كلمة المرور المؤقتة:</strong><br>
            <span class="highlight">${tempPassword}</span>
          </div>
          <div class="info-item yellow">
            <strong>رقم الهاتف:</strong><br>
            ${phone}
          </div>
        </div>
      </div>
      
      <div class="divider"></div>
      
      <div class="card">
        <h3 style="color: #22c55e; margin-top: 0;">بيانات السيارة</h3>
        <div class="info-grid">
          <div class="info-item green">
            <strong>موديل السيارة:</strong><br>
            ${carModel}
          </div>
          <div class="info-item green">
            <strong>رقم اللوحة:</strong><br>
            ${carPlateNumber}
          </div>
          <div class="info-item green">
            <strong>لون السيارة:</strong><br>
            ${carColor || 'غير محدد'}
          </div>
          <div class="info-item green">
            <strong>سنة الصنع:</strong><br>
            ${carYear || new Date().getFullYear()}
          </div>
        </div>
      </div>
      
      <p style="color: #64748b; text-align: center;">
        سيتم مطالبتك بتغيير كلمة المرور عند أول دخول إلى التطبيق
      </p>
      
      <div style="text-align: center; margin: 25px 0;">
        <a href="${process.env.APP_URL}/driver/login" class="btn">الدخول إلى حسابك</a>
      </div>
    </div>
    
    <div class="footer">
      <p>© ${new Date().getFullYear()} TaxiGo. جميع الحقوق محفوظة</p>
      <p>هذه الرسالة تلقائية، يرجى عدم الرد عليها</p>
    </div>
  </div>
</body>
</html>
`
    };

    let emailSent = true;
    try {
      await transporter.sendMail(mailOptions);
      console.log('Welcome email sent successfully.');
    } catch (emailError) {
      emailSent = false;
      console.error('Failed to send welcome email:', emailError);
      // لا نرجع هنا، لأن العمليات الأساسية في قاعدة البيانات نجحت.
      // يمكن أن نضيف تحذيرًا إلى الرد.
    }

    res.status(201).json({
      success: true,
      data: {
        driver: newDriver,
        user: {
          _id: newUser._id,
          fullName: newUser.fullName,
          email: newUser.email,
          phone: newUser.phone,
          role: newUser.role
        }
      },
      message: emailSent
        ? 'تم إنشاء السائق بنجاح وإرسال البيانات إلى بريده الإلكتروني.'
        : 'تم إنشاء السائق بنجاح، ولكن فشل إرسال البريد الإلكتروني.'
    });

  } catch (error) {
    console.error('Error during driver creation:', error);

    // --- منطق التعويض (Rollback/Cleanup) ---
    console.log('Attempting to rollback due to error...');
    if (newDriver && newDriver._id) {
      try {
        await Driver.deleteOne({ _id: newDriver._id });
        console.log('Rolled back: Driver record deleted.');
      } catch (rollbackError) {
        console.error('Failed to rollback Driver:', rollbackError);
      }
    }

    if (newUser && newUser._id) {
      try {
        await User.deleteOne({ _id: newUser._id });
        console.log('Rolled back: User record deleted.');
      } catch (rollbackError) {
        console.error('Failed to rollback User:', rollbackError);
      }
    }

    if (officeToUpdate && newDriver && newDriver._id) {
        try {
            // قم بإزالة معرف السائق من مصفوفة drivers في المكتب
            await TaxiOffice.findByIdAndUpdate(officeToUpdate._id, {
                $pull: { drivers: newDriver._id }
            });
            console.log('Rolled back: Driver removed from TaxiOffice.');
        } catch (rollbackError) {
            console.error('Failed to rollback TaxiOffice update:', rollbackError);
        }
    }

    res.status(500).json({
      success: false,
      message: 'فشل في إنشاء السائق: ' + error.message
    });
  }
};