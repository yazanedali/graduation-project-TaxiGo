const nodemailer = require('nodemailer');
const path = require('path');
const fs = require('fs');
const handlebars = require('handlebars');

const sendWelcomeEmail = async (user, roleSpecificData = {}) => {
    if (!user.isVerified) return; // لا ترسل إذا لم يتم التحقق

  const transporter = nodemailer.createTransport({
    service: 'gmail',
    auth: {
      user: process.env.EMAIL,
      pass: process.env.EMAIL_PASSWORD
    }
  });

  // 1. قراءة قالب HBS
  const templatePath = path.join(__dirname, 'templates/welcomeEmail.hbs');
  const emailTemplate = fs.readFileSync(templatePath, 'utf8');

  // 2. تسجيل الـ if_eq helper
  handlebars.registerHelper('if_eq', function (a, b, opts) {
    return a === b ? opts.fn(this) : opts.inverse(this);
  });

  // 3. ترجمة القالب
  const compiledTemplate = handlebars.compile(emailTemplate);

  // 4. إعداد البيانات المراد تمريرها للقالب
  const htmlToSend = compiledTemplate({
    fullName: user.fullName,
    email: user.email,
    USER_ROLE: user.role === 'Driver' ? 'سائق' : 'عميل',
    OFFICE_NAME: roleSpecificData.officeName || 'غير محدد',
    LICENSE_NUMBER: roleSpecificData.licenseNumber || 'غير محدد',
    LOGIN_LINK: process.env.FRONTEND_URL
  });

  const mailOptions = {
    from: `"نظام TaxiGo" <${process.env.EMAIL}>`,
    to: user.email,
    subject: `مرحباً بك في TaxiGo - ${user.role === 'Driver' ? 'حساب سائق جديد' : 'حساب عميل جديد'}`,
    html: htmlToSend,
    attachments: [
      {
        filename: 'taxi.png',
        path: path.join(__dirname, '../public/images/taxi.png'),
        cid: 'logo'
      },
      {
        filename: 'welcome.png',
        path: path.join(__dirname, '../public/images/welcom.png'),
        cid: 'welcome'
      }
    ]
  };

  try {
    await transporter.sendMail(mailOptions);
    console.log(`✅ تم إرسال بريد ترحيبي إلى ${user.email}`);
  } catch (error) {
    console.error('❌ فشل إرسال البريد الترحيبي:', error);
  }
};

module.exports = { sendWelcomeEmail };
