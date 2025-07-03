const User = require('../models/User');
const Driver = require('../models/Driver');
const Client = require('../models/client');
const TaxiOffice = require('../models/TaxiOffice');
const { sendWelcomeEmail } = require('../utils/emailService');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const nodemailer = require('nodemailer');


async function sendVerificationEmail(user) {
  // إنشاء رمز تحقق
  const token = crypto.randomBytes(20).toString('hex');
  const expires = Date.now() + 3600000; // صلاحية ساعة واحدة

  // حفظ الرمز في قاعدة البيانات
  user.verificationToken = token;
  user.verificationTokenExpires = expires;
  await user.save();

  // إعداد البريد الإلكتروني
  const transporter = nodemailer.createTransport({
    service: 'gmail',
    auth: {
      user: process.env.EMAIL,
      pass: process.env.EMAIL_PASSWORD
    }
  });

  const verificationUrl = `${process.env.APP_URL}/verify-email?token=${token}`;
console.log("Verification URL:", verificationUrl); // للتأكد من صحة الرابط
  const mailOptions = {
    from: process.env.EMAIL,
    to: user.email,
    subject: 'تفعيل حسابك في تطبيق التكسي - خطوتك الأولى نحو رحلة مريحة!', // عنوان موضوع أجمل
    html: `
      <div style="font-family: 'Arial', sans-serif; background-color: #f0f0f0; padding: 20px; direction: rtl; text-align: right;">
        <table width="100%" border="0" cellspacing="0" cellpadding="0">
          <tr>
            <td align="center">
              <table width="600" style="background-color: #ffffff; border-radius: 8px; overflow: hidden; box-shadow: 0 4px 12px rgba(0,0,0,0.08);">
                <!-- Header -->
                <tr>
                  <td style="background-color: #FFC107; padding: 25px; text-align: center;">
                    <h1 style="color: #333333; margin: 0; font-size: 28px; font-weight: bold; display: flex; align-items: center; justify-content: center;">
                      <span style="font-size: 35px; margin-left: 10px;">🚕</span>
                      تطبيق التكسي
                    </h1>
                    <p style="color: #333333; margin: 5px 0 0; font-size: 16px;">رحلتك تبدأ من هنا!</p>
                  </td>
                </tr>

                <!-- Body Content -->
                <tr>
                  <td style="padding: 30px; color: #555555; line-height: 1.8;">
                    <h2 style="color: #333333; margin-top: 0; font-size: 24px; font-weight: bold;">مرحباً ${user.fullName}!</h2>
                    <p style="margin-bottom: 20px;">
                      شكراً جزيلاً لتسجيلك في <strong style="color: #FFC107;">تطبيق التكسي</strong>. نحن متحمسون جداً لضمك إلى عائلتنا ونتطلع لمساعدتك في الحصول على رحلات سريعة وموثوقة.
                    </p>
                    <p style="margin-bottom: 25px;">
                      لتفعيل حسابك والبدء في استكشاف جميع ميزات تطبيقنا الرائعة، يرجى النقر على الزر الأصفر أدناه:
                    </p>
                    
                    <!-- Call to Action Button -->
                    <table border="0" cellspacing="0" cellpadding="0" style="margin: 30px auto;">
                      <tr>
                        <td align="center" style="border-radius: 7px;" bgcolor="#FFD700">
                          <a href="${verificationUrl}" target="_blank" 
                             style="font-size: 18px; font-family: Arial, sans-serif; color: #333333; text-decoration: none; padding: 15px 35px; border-radius: 7px; display: inline-block; font-weight: bold; background-color: #FFD700;">
                             🚀 تفعيل الحساب الآن 🚀
                          </a>
                        </td>
                      </tr>
                    </table>

                    <p style="font-size: 14px; color: #777777; margin-top: 20px;">
                      <strong style="color: #FFC107;">ملاحظة هامة:</strong> هذا الرابط سينتهي خلال ساعة واحدة من وقت استلام هذا البريد.
                    </p>
                    <p style="font-size: 14px; color: #777777;">
                      إذا لم تطلب هذا البريد، يرجى تجاهله بأمان. حسابك سيظل آمناً.
                    </p>
                  </td>
                </tr>

                <!-- Footer -->
                <tr>
                  <td style="background-color: #333333; padding: 20px; text-align: center;">
                    <p style="color: #f0f0f0; font-size: 12px; margin: 0;">
                      © ${new Date().getFullYear()} تطبيق التكسي. جميع الحقوق محفوظة.
                    </p>
                    <p style="color: #aaaaaa; font-size: 11px; margin: 5px 0 0;">
                      للاستفسارات، يرجى التواصل معنا عبر <a href="mailto:${process.env.EMAIL}" style="color: #FFC107; text-decoration: none;">الدعم الفني</a>.
                    </p>
                  </td>
                </tr>
              </table>
            </td>
          </tr>
        </table>
      </div>
    `
  };

  await transporter.sendMail(mailOptions);
}

const verifyEmail = async (req, res) => {
  try {
    const { token } = req.query;

    const user = await User.findOne({
      verificationToken: token,
      verificationTokenExpires: { $gt: Date.now() }
    });

    if (!user) {
      return res.status(400).json({
        success: false,
        message: 'رابط التحقق غير صالح أو منتهي الصلاحية'
      });
    }

    user.isVerified = true;
    user.verificationToken = undefined;
    user.verificationTokenExpires = undefined;
    await user.save();

    res.status(200).json({
      success: true,
      message: 'تم تفعيل الحساب بنجاح!'
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'حدث خطأ أثناء تفعيل الحساب'
    });
  }
};



const createUser = async (req, res) => {
  const {
    fullName, email, phone, password, confirmPassword, role, gender,
    officeIdentifier, carModel, carPlateNumber, carColor, carYear,
    licenseNumber, licenseExpiry, profileImageUrl
  } = req.body;

  if (!fullName || !phone || !email || !password || !role || !gender) {
    return res.status(400).json({ message: 'الرجاء تقديم جميع الحقول المطلوبة' });
  }

  if (password !== confirmPassword) {
    return res.status(400).json({ message: 'كلمات المرور غير متطابقة' });
  }

  if (role === 'Driver') {
    const requiredDriverFields = ['officeIdentifier', 'licenseNumber', 'licenseExpiry', 'carPlateNumber', 'carModel'];
    const missingFields = requiredDriverFields.filter(field => !req.body[field]);

    if (missingFields.length > 0) {
      return res.status(400).json({
        message: `الحقول المطلوبة للسائق: ${missingFields.join(', ')}`,
        missingFields
      });
    }
  }

  try {
    // تحقق من وجود المستخدم مسبقًا
    const existingUser = await User.findOne({ $or: [{ phone }, { email }] });
    if (existingUser) {
      return res.status(400).json({
        success: false,
        message: 'رقم الهاتف أو البريد الإلكتروني موجود مسبقاً'
      });
    }

    // تحقق من وجود المكتب إذا كان سائقًا
    let office = null;
    if (role === 'Driver') {
      office = await TaxiOffice.findOne({ officeIdentifier: officeIdentifier });
      if (!office) {
        return res.status(404).json({
          success: false,
          message: 'مكتب التكاسي غير موجود'
        });
      }
    }

    // كل التحققات ناجحة – نبدأ بإنشاء الكائنات
    const hashedPassword = await bcrypt.hash(password, 12);

    const newUser = new User({
      fullName,
      email,
      phone,
      password: hashedPassword,
      role,
      gender,
      mustChangePassword: role === 'Driver',
      profileImageUrl: profileImageUrl || undefined,
      isVerified: false
    });

    let newDriver = null;
    let newClient = null;

    if (role === 'Driver') {
      newDriver = new Driver({
        user: newUser._id, // مؤقتًا، سيتم تعيينه بعد حفظ المستخدم
        driverUserId: newUser.userId,
        office: office._id,
        officeIdentifier: officeIdentifier,
        carDetails: {
          model: carModel,
          plateNumber: carPlateNumber,
          color: carColor || 'غير محدد',
          year: carYear || new Date().getFullYear()
        },
        licenseNumber,
        licenseExpiry: new Date(licenseExpiry),
        isAvailable: false,
        rating: 80,
        numberOfRatings: 0,
        profileImageUrl: profileImageUrl || undefined,
        earnings: 0
      });
    } else if (role === 'User') {
      newClient = new Client({
        user: newUser._id,
        clientUserId: newUser.userId
      });
    }

    // 🔒 نحفظ المستخدم أولاً
    const savedUser = await newUser.save();
    await sendVerificationEmail(savedUser);


    // 🧾 ثم نحفظ السائق أو العميل
    if (role === 'Driver') {
      newDriver.user = savedUser._id;
      newDriver.driverUserId = savedUser.userId;
      await newDriver.save();
      await sendWelcomeEmail(savedUser, {
        officeName: office.name,
        licenseNumber: licenseNumber
      });
    } else if (role === 'User') {
      newClient.user = savedUser._id;
      newClient.clientUserId = savedUser.userId;
      await newClient.save();
      await sendWelcomeEmail(savedUser);
    }

    // نجهز الرد النهائي
    const userResponse = savedUser.toObject();
    delete userResponse.password;

    res.status(201).json({
      success: true,
      message: 'تم إنشاء المستخدم بنجاح',
      user: userResponse,
      ...(role === 'Driver' && {
        driverDetails: {
          licenseNumber,
          carPlateNumber,
          officeName: office?.name
        }
      })
    });

  } catch (error) {
    console.error("Error during user creation:", error);
    res.status(500).json({
      success: false,
      message: 'حدث خطأ أثناء إنشاء المستخدم',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};


// تسجيل الدخول


const loginUser = async (req, res) => {
  const { email, password, fcmToken } = req.body;

  // تحقق من الحقول
  if (!email || !password) {
    return res.status(400).json({ message: 'يرجى إدخال البريد الإلكتروني وكلمة المرور' });
  }

  try {
    // البحث عن المستخدم بواسطة البريد الإلكتروني فقط
    const user = await User.findOne({ email });

    if (!user) {
      return res.status(404).json({ message: 'المستخدم غير موجود' });
    }

    // التحقق إذا تم تفعيل البريد الإلكتروني
    if (!user.isVerified) {
      return res.status(401).json({ message: 'يرجى تفعيل بريدك الإلكتروني قبل تسجيل الدخول' });
    }

    // التحقق من صحة كلمة المرور
    const isPasswordValid = await bcrypt.compare(password, user.password);
    if (!isPasswordValid) {
      return res.status(401).json({ message: 'كلمة المرور غير صحيحة' });
    }

    // إنشاء التوكن
    const token = jwt.sign(
      { id: user._id, role: user.role },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRES_IN || '1d' }
    );

    // حفظ التوكن وحالة تسجيل الدخول وFCM token
    user.token = token;
    user.isLoggedIn = true;
    if (fcmToken) {
      user.fcmToken = fcmToken;
    }
    await user.save();

    // إزالة كلمة المرور من الرد
    const userResponse = { ...user._doc };
    delete userResponse.password;

    res.status(200).json({
      success: true,
      message: 'تم تسجيل الدخول بنجاح',
      user: userResponse,
      token
    });

  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ message: 'فشل تسجيل الدخول', error: error.message });
  }
};



// const logoutUser = (req, res) => {
//   res.clearCookie('token'); // اسم الكوكي اللي فيه التوكن
//   res.status(200).json({ message: 'Logged out successfully' });
// };




const logoutUser = async (req, res) => {
  try {
    const userId = req.body.Id; // استقبل userId من البودي
    if (!userId) {
      return res.status(400).json({ success: false, message: 'userId is required' });
    }

    const user = await User.findOneAndUpdate(
      { userId: userId },
      { token: null, isLoggedIn: false }, // ✅ تحديث isLoggedIn
      { new: true }
    );

    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    res.status(200).json({ success: true, message: 'تم تسجيل الخروج بنجاح.' });

  } catch (error) {
    console.error('خطأ في تسجيل الخروج:', error);
    res.status(500).json({ success: false, message: 'فشل تسجيل الخروج.' });
  }
};



module.exports = { logoutUser };


// استرجاع جميع المستخدمين
// const getUsers = async (req, res) => {
//   try {
//     const users = await User.find();
//     res.status(200).json(users);
//   } catch (error) {
//     console.error(error);
//     res.status(500).json({ message: 'Error fetching users', error });
//   }
// };
// const getUsers = async (filter = {}) => {
//   try {
//     const users = await User.find(filter);  // تطبيق الفلتر إن وجد
//     return users;
//   } catch (error) {
//     throw new Error('Error fetching users');
//   }
// };

// جلب الاسم الكامل للمستخدم بواسطة ID
const getPrintFullName = async (req, res) => {
  try {
    const { userId } = req.params;

    if (!userId) {
      return res.status(400).json({ message: 'User ID is required' });
    }

    const user = await User.findOne({userId: userId}).select('fullName');
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    res.status(200).json({ fullName: user.fullName });

  } catch (error) {
    console.error("Error fetching full name:", error);
    res.status(500).json({ message: 'Failed to get full name', error: error.message });
  }
};

const getUsers = async (req, res) => {
  try {
    const { loggedInOnly } = req.query;

    let filter = {};
    if (loggedInOnly === 'true') {
      filter.isLoggedIn = true;
    }

    const users = await User.find(filter);
    res.status(200).json(users);

  } catch (error) {
    console.error('Error fetching users:', error);
    res.status(500).json({ message: 'Error fetching users', error });
  }
};


const getUserById = async (req, res) => {
  try {
    const userId = req.params.id;
    const user = await User.findOne({userId: userId}).select('role _id isLoggedIn');

    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    res.json({
      user: {
        id: user._id,
        role: user.role,
        isLoggedIn: user.isLoggedIn
      }
    });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

const changePassword = async (req, res) => {
  try {
    const { currentPassword, newPassword, confirmNewPassword, id } = req.body;
    const user = await User.findOne({ userId: id });
    // التحقق من كلمة المرور الحالية
    const isMatch = await bcrypt.compare(currentPassword, user.password);
    if (!isMatch) {
      return res.status(400).json({ 
        success: false,
        message: 'كلمة المرور الحالية غير صحيحة' 
      });
    }

    // التحقق من تطابق كلمتي المرور الجديدتين
    if (newPassword !== confirmNewPassword) {
      return res.status(400).json({ 
        success: false,
        message: 'كلمتا المرور الجديدتان غير متطابقتين' 
      });
    }

    // تحديث كلمة المرور
    const hashedPassword = await bcrypt.hash(newPassword, 12);
    user.password = hashedPassword;
    await user.save();

    res.status(200).json({ 
      success: true,
      message: 'تم تغيير كلمة المرور بنجاح' 
    });

  } catch (error) {
    console.error(error);
    res.status(500).json({ 
      success: false,
      message: 'حدث خطأ أثناء تغيير كلمة المرور' 
    });
  }
};

// طلب إعادة تعيين كلمة المرور (نسيان كلمة المرور)
const forgotPassword = async (req, res) => {
  try {
    const { email } = req.body;
    const user = await User.findOne({ email });

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'لا يوجد حساب مرتبط بهذا البريد الإلكتروني'
      });
    }

    // إنشاء رمز إعادة تعيين
    const resetToken = crypto.randomBytes(20).toString('hex');
    const resetTokenExpires = Date.now() + 3600000; // صلاحية ساعة واحدة

    user.resetPasswordToken = resetToken;
    user.resetPasswordExpires = resetTokenExpires;
    await user.save();

    // إرسال البريد الإلكتروني
    // تأكد أن APP_URL في ملف .env الخاص بالـ Backend يشير إلى العنوان الأساسي لخادمك (مثلاً: http://localhost:5000)
    // وليس مع مسار /api/users
    const resetUrl = `${process.env.APP_URL}/reset-password/${resetToken}`; // المسار الصحيح بعد التعديل السابق

    const transporter = nodemailer.createTransport({
      service: 'gmail',
      auth: {
        user: process.env.EMAIL,
        pass: process.env.EMAIL_PASSWORD
      }
    });

    const mailOptions = {
      from: process.env.EMAIL,
      to: user.email,
      subject: 'تطبيق التكسي: طلب إعادة تعيين كلمة المرور 🔑', // عنوان موضوع أجمل
      html: `
        <div style="font-family: 'Arial', sans-serif; background-color: #f0f0f0; padding: 20px; direction: rtl; text-align: right;">
          <table width="100%" border="0" cellspacing="0" cellpadding="0">
            <tr>
              <td align="center">
                <table width="600" style="background-color: #ffffff; border-radius: 8px; overflow: hidden; box-shadow: 0 4px 12px rgba(0,0,0,0.08);">
                  <!-- Header -->
                  <tr>
                    <td style="background-color: #FFC107; padding: 25px; text-align: center;">
                      <h1 style="color: #333333; margin: 0; font-size: 28px; font-weight: bold; display: flex; align-items: center; justify-content: center;">
                        <span style="font-size: 35px; margin-left: 10px;">🚕</span>
                        تطبيق التكسي
                      </h1>
                      <p style="color: #333333; margin: 5px 0 0; font-size: 16px;">لرحلة سريعة ومريحة</p>
                    </td>
                  </tr>

                  <!-- Body Content -->
                  <tr>
                    <td style="padding: 30px; color: #555555; line-height: 1.8;">
                      <h2 style="color: #333333; margin-top: 0; font-size: 24px; font-weight: bold;">طلب إعادة تعيين كلمة المرور</h2>
                      <p style="margin-bottom: 20px;">
                        لقد تلقيت هذا البريد لأنك (أو شخص آخر) طلبت إعادة تعيين كلمة المرور لحسابك في <strong style="color: #FFC107;">تطبيق التكسي</strong>.
                      </p>
                      <p style="margin-bottom: 25px;">
                        الرجاء النقر على الزر الأصفر أدناه لإكمال عملية إعادة تعيين كلمة المرور:
                      </p>
                      
                      <!-- Call to Action Button -->
                      <table border="0" cellspacing="0" cellpadding="0" style="margin: 30px auto;">
                        <tr>
                          <td align="center" style="border-radius: 7px;" bgcolor="#FFD700">
                            <a href="${resetUrl}" target="_blank" 
                               style="font-size: 18px; font-family: Arial, sans-serif; color: #333333; text-decoration: none; padding: 15px 35px; border-radius: 7px; display: inline-block; font-weight: bold; background-color: #FFD700;">
                               🔑 إعادة تعيين كلمة المرور 🔑
                            </a>
                          </td>
                        </tr>
                      </table>

                      <p style="font-size: 14px; color: #777777; margin-top: 20px;">
                        <strong style="color: #FFC107;">ملاحظة هامة:</strong> هذا الرابط سينتهي خلال ساعة واحدة من وقت استلام هذا البريد.
                      </p>
                      <p style="font-size: 14px; color: #777777;">
                        إذا لم تطلب هذا التغيير، يرجى تجاهل هذا البريد بأمان. حسابك سيظل آمناً.
                      </p>
                    </td>
                  </tr>

                  <!-- Footer -->
                  <tr>
                    <td style="background-color: #333333; padding: 20px; text-align: center;">
                      <p style="color: #f0f0f0; font-size: 12px; margin: 0;">
                        © ${new Date().getFullYear()} تطبيق التكسي. جميع الحقوق محفوظة.
                      </p>
                      <p style="color: #aaaaaa; font-size: 11px; margin: 5px 0 0;">
                        للاستفسارات، يرجى التواصل معنا عبر <a href="mailto:${process.env.EMAIL}" style="color: #FFC107; text-decoration: none;">الدعم الفني</a>.
                      </p>
                    </td>
                  </tr>
                </table>
              </td>
            </tr>
          </table>
        </div>
      `
    };

    await transporter.sendMail(mailOptions);

    res.status(200).json({
      success: true,
      message: 'تم إرسال رابط إعادة تعيين كلمة المرور إلى بريدك الإلكتروني'
    });

  } catch (error) {
    console.error(error);
    res.status(500).json({
      success: false,
      message: 'حدث خطأ أثناء معالجة طلبك'
    });
  }
};

// إعادة تعيين كلمة المرور باستخدام الرمز
const resetPassword = async (req, res) => {
  try {
    const { token } = req.params;
    const { newPassword, confirmNewPassword } = req.body;

    // التحقق من تطابق كلمتي المرور الجديدتين
    if (newPassword !== confirmNewPassword) {
      return res.status(400).json({ 
        success: false,
        message: 'كلمتا المرور غير متطابقتين' 
      });
    }

    const user = await User.findOne({
      resetPasswordToken: token,
      resetPasswordExpires: { $gt: Date.now() }
    });

    if (!user) {
      return res.status(400).json({ 
        success: false,
        message: 'رابط إعادة التعيين غير صالح أو منتهي الصلاحية' 
      });
    }

    // تحديث كلمة المرور
    const hashedPassword = await bcrypt.hash(newPassword, 12);
    user.password = hashedPassword;
    user.resetPasswordToken = undefined;
    user.resetPasswordExpires = undefined;
    await user.save();

    res.status(200).json({ 
      success: true,
      message: 'تم تحديث كلمة المرور بنجاح' 
    });

  } catch (error) {
    console.error(error);
    res.status(500).json({ 
      success: false,
      message: 'حدث خطأ أثناء إعادة تعيين كلمة المرور' 
    });
  }
};



module.exports = { createUser, loginUser, getUsers, logoutUser,getPrintFullName, getUserById, verifyEmail, changePassword, forgotPassword, resetPassword };