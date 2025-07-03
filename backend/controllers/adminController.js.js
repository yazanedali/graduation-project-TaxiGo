const TaxiOffice = require('../models/TaxiOffice');
const User = require('../models/User');
const Manager = require('../models/Manager');
const nodemailer = require('nodemailer');
const bcrypt = require('bcryptjs');

// إنشاء مكتب تكاسي ومدير معاً
exports.createTaxiOfficeWithManager = async (req, res) => {
  try {
    const { officeIdentifier, name, location, contact, managerData } = req.body;

    // ✅ 1. تحقق أولًا من عدم وجود مستخدم بنفس الإيميل أو رقم الهاتف
    const existingUser = await User.findOne({
      $or: [
        { email: managerData.email },
        { phone: managerData.phone }
      ]
    });

    if (existingUser) {
      return res.status(400).json({
        success: false,
        message: 'يوجد حساب مستخدم بالفعل بهذا البريد الإلكتروني أو رقم الهاتف.'
      });
    }

    // ✅ 2. تحقق من عدم تكرار رقم المكتب
    const existingOffice = await TaxiOffice.findOne({ officeIdentifier });
    if (existingOffice) {
      return res.status(400).json({
        success: false,
        message: 'رقم المكتب مستخدم من قبل، الرجاء اختيار رقم مختلف.'
      });
    }

    // ✅ 3. بعد التأكد، أنشئ كلمة مرور مشفرة مؤقتة
    const tempPassword = generateRandomPassword();
    const hashedPassword = await bcrypt.hash(tempPassword, 10);

    // ✅ 4. أنشئ الكائنات (ولكن لا تحفظ بعد)
    const newOffice = new TaxiOffice({
      officeIdentifier,
      name,
      location: {
        type: 'Point',
        coordinates: [location.longitude, location.latitude],
        address: location.address
      },
      contact
    });

    const newUser = new User({
      fullName: managerData.fullName,
      email: managerData.email,
      phone: managerData.phone,
      password: hashedPassword,
      role: 'Manager',
      gender: managerData.gender
    });

    // ✅ 5. الآن احفظ الـ user و office
    await newUser.save();
    await newOffice.save();

    const newManager = new Manager({
      user: newUser._id,
      userId: newUser.userId,
      office: newOffice._id,
      officeId: newOffice.officeId
    });

    await newManager.save();

    // ✅ 6. تحديث الـ office بربط المدير
    newOffice.manager = newManager._id;
    newOffice.managerId = newManager.userId;
    await newOffice.save();

    // ✅ 7. إرسال البريد الإلكتروني
    const transporter = nodemailer.createTransport({
      service: 'gmail',
      auth: {
        user: process.env.EMAIL,
        pass: process.env.EMAIL_PASSWORD
      }
    });

 const mailOptions = {
      from: process.env.EMAIL,
      to: contact.email, // إرسال إلى إيميل المكتب
      subject: `بيانات دخول مدير مكتب ${name}`,
      html: `
  <!DOCTYPE html>
  <html dir="rtl" lang="ar">
  <head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>تفعيل حساب المدير</title>
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
        <h1>مرحباً بكم في نظام TaxiGo</h1>
      </div>
      
      <div class="content">
        <h2 style="color: #1e3a8a;">تم إنشاء مكتب جديد بنجاح!</h2>
        
        <div class="card">
          <h3 style="color: #3b82f6; margin-top: 0;">معلومات المكتب</h3>
          <div class="info-grid">
            <div class="info-item blue">
              <strong>اسم المكتب:</strong><br>
              ${name}
            </div>
            <div class="info-item blue">
              <strong>رقم المكتب:</strong><br>
              ${officeIdentifier}
            </div>
            <div class="info-item blue">
              <strong>العنوان:</strong><br>
              ${location.address}
            </div>
            <div class="info-item blue">
              <strong>هاتف المكتب:</strong><br>
              ${contact.phone}
            </div>
          </div>
        </div>
        
        <div class="divider"></div>
        
        <div class="card">
          <h3 style="color: #d97706; margin-top: 0;">بيانات المدير</h3>
          <div class="info-grid">
            <div class="info-item yellow">
              <strong>الاسم الكامل:</strong><br>
              ${managerData.fullName}
            </div>
            <div class="info-item yellow">
              <strong>البريد الإلكتروني:</strong><br>
              ${managerData.email}
            </div>
            <div class="info-item yellow">
              <strong>كلمة المرور المؤقتة:</strong><br>
              <span class="highlight">${tempPassword}</span>
            </div>
            <div class="info-item yellow">
              <strong>رقم الهاتف:</strong><br>
              ${managerData.phone}
            </div>
          </div>
        </div>
        
        
        <p style="color: #64748b; text-align: center;">
          سيتم مطالبتك بتغيير كلمة المرور عند أول دخول
        </p>
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


    await transporter.sendMail(mailOptions);

    res.status(201).json({
      success: true,
      data: {
        office: newOffice,
        manager: newManager
      },
      message: 'تم إنشاء المكتب والمدير بنجاح وإرسال البيانات إلى البريد الإلكتروني'
    });

  } catch (error) {
    console.error('Error:', error);
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

// دالة مساعدة لإنشاء كلمة مرور عشوائية
function generateRandomPassword(length = 10) {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
  let result = '';
  for (let i = 0; i < length; i++) {
    result += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return result;
}

exports.getAllOfficesWithManagers = async (req, res) => {
  try {
    const offices = await TaxiOffice.find()
      .populate({
        path: 'manager',
        populate: {
          path: 'user',
          select: 'fullName email phone'
        }
      })
      .select('-__v -createdAt -updatedAt');

    res.status(200).json({
      success: true,
      count: offices.length,
      data: offices
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

exports.getTaxiOfficesForMap = async (req, res) => {
  try {
    const { latitude, longitude, radius } = req.query;
    
    let query = { isActive: true };
    
    // إذا كانت هناك إحداثيات ونصف قطر، نبحث في النطاق الجغرافي
    if (latitude && longitude && radius) {
      query.location = {
        $near: {
          $geometry: {
            type: "Point",
            coordinates: [parseFloat(longitude), parseFloat(latitude)]
          },
          $maxDistance: parseInt(radius) // بالمتر
        }
      };
    }

    const offices = await TaxiOffice.find(query)
      .select('name location latitude longitude contact imageUrl workingHours')
      .lean();

    // تحويل البيانات لتكون متوافقة مع الواجهة الأمامية
    const formattedOffices = offices.map(office => ({
      id: office._id,
      name: office.name,
      address: office.location.address,
      latitude: office.latitude,
      longitude: office.longitude,
      phone: office.contact.phone,
      imageUrl: office.imageUrl,
      workingHours: office.workingHours
    }));

    res.status(200).json({
      success: true,
      data: formattedOffices
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};