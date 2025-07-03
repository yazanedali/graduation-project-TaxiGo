// bot.js
require('dotenv').config();
const { Telegraf, session, Markup } = require('telegraf');
const axios = require('axios');
const fs = require('fs').promises; // لإدارة ملف .json للمستخدمين المرتبطين

// تأكد من وجود المتغيرات البيئية
if (!process.env.BOT_TOKEN || !process.env.API_BASE_URL) {
  console.error('Environment variables BOT_TOKEN or API_BASE_URL are missing. Please check your .env file.');
  process.exit(1);
}

const bot = new Telegraf(process.env.BOT_TOKEN);
// تمكين الجلسات (session) لإدارة حالة المستخدم في المحادثة
bot.use(session());

// حالة أولية لجلسة المستخدم
const initState = {
  stage: 'start', // المرحلة الحالية للمستخدم في المحادثة
  email: '',
  password: '',
  token: '',      // توكن المصادقة من الـ Backend
  userId: '',     // معرف المستخدم في الـ Backend
  pickup: '',     // اسم موقع الانطلاق (نص)
  destination: '', // اسم الوجهة (نص)
  pickupLocation: null,      // إحداثيات الانطلاق {latitude, longitude}
  destinationLocation: null, // إحداثيات الوجهة {latitude, longitude}
  datetime: ''    // تاريخ ووقت الرحلة (نص)
};

// --- إدارة المستخدمين المرتبطين (Permanent Linked Users) ---
// لحفظ ربط معرف تيليجرام بمعرف المستخدم في تطبيقك بشكل دائم
// (للتطوير، نستخدم ملف JSON، في الإنتاج يجب استخدام قاعدة بيانات)
let linkedUsers = {}; 
const LINKED_USERS_FILE = 'linked_users.json'; // ملف لتخزين الروابط

// دالة لتحميل المستخدمين المرتبطين من الملف
async function loadLinkedUsers() {
  try {
    const data = await fs.readFile(LINKED_USERS_FILE, 'utf8');
    linkedUsers = JSON.parse(data);
    console.log(`Loaded ${Object.keys(linkedUsers).length} linked users from file.`);
  } catch (error) {
    if (error.code === 'ENOENT') {
      console.log('linked_users.json not found, starting with empty linked users.');
      linkedUsers = {};
    } else {
      console.error('Error loading linked users from file:', error);
    }
  }
}

// دالة لحفظ المستخدمين المرتبطين إلى الملف
async function saveLinkedUsers() {
  try {
    await fs.writeFile(LINKED_USERS_FILE, JSON.stringify(linkedUsers, null, 2), 'utf8');
    console.log('Linked users saved to file.');
  } catch (error) {
    console.error('Error saving linked users to file:', error);
  }
}

// تحميل المستخدمين عند بدء البوت
loadLinkedUsers();


// --- الأوامر الأساسية ---

bot.start(async (ctx) => {
  // تهيئة الجلسة لكل مستخدم جديد أو عند بدء محادثة جديدة
  ctx.session = { ...initState }; 

  const telegramUserId = ctx.from.id;
  const user = linkedUsers[telegramUserId]; // التحقق مما إذا كان المستخدم مسجل الدخول بالفعل

  if (user) {
    // المستخدم مسجل الدخول بالفعل، تهيئة الجلسة بمعلومات الدخول الدائمة
    ctx.session.token = user.appToken;
    ctx.session.userId = user.appUserId;
    ctx.session.stage = 'ready_for_booking'; // حالة جديدة للمستخدم المسجل دخوله

    const fullName = user.fullName || user.appUserId; // استخدام الاسم الكامل إن وجد
    return ctx.reply(
      `مرحباً ${fullName}! حسابك مرتبط بالفعل.\nالرجاء إدخال أمر لحجز رحلة جديدة /book_trip أو /my_bookings لعرض رحلاتك.`, 
      Markup.keyboard([
        ['حجز رحلة جديدة', 'رحلاتي'] // أزرار لعمليات مستقبلية
      ]).resize().oneTime()
    );
  } else {
    // المستخدم غير مسجل الدخول، بدء عملية تسجيل الدخول
    ctx.session.stage = 'awaiting_email';
    return ctx.reply('مرحبًا بك في TaxiGo 🚖\nيرجى إدخال بريدك الإلكتروني:');
  }
});

bot.command('cancel', (ctx) => {
  ctx.session = { ...initState }; // إعادة تعيين الجلسة بالكامل لإلغاء العملية
  return ctx.reply('❌ تم إلغاء العملية. يمكنك بدء محادثة جديدة بكتابة /start');
});

// أمر لبدء حجز رحلة جديدة
bot.command('book_trip', async (ctx) => {
  if (!ctx.session) ctx.session = { ...initState }; // تأكد من تهيئة الجلسة

  const telegramUserId = ctx.from.id;
  const user = linkedUsers[telegramUserId];

  if (!user) {
    // إذا لم يكن المستخدم مسجلاً، اطلب منه تسجيل الدخول أولاً
    ctx.session.stage = 'awaiting_email'; 
    return ctx.reply('يجب عليك تسجيل الدخول أولاً قبل حجز رحلة. يرجى إدخال بريدك الإلكتروني:');
  }
  
  // المستخدم مسجل الدخول، بدء عملية حجز جديدة
  // إعادة تهيئة الجلسة لعملية الحجز مع الاحتفاظ بمعلومات الدخول
  ctx.session = { ...initState, token: user.appToken, userId: user.appUserId }; 
  ctx.session.stage = 'awaiting_pickup_location';
  return ctx.reply('📍 الرجاء إرسال موقعك الحالي:', Markup.keyboard([
    Markup.button.locationRequest('📍 مشاركة الموقع')
  ]).oneTime().resize()); // زر لطلب مشاركة الموقع
});

// أمر لعرض رحلات المستخدم
bot.command('my_bookings', async (ctx) => {
  const telegramUserId = ctx.from.id;
  const user = linkedUsers[telegramUserId];

  if (!user) {
    return ctx.reply('يجب عليك تسجيل الدخول وربط حسابك أولاً لعرض رحلاتك. استخدم أمر /start.');
  }
  
  await ctx.reply(`جاري جلب رحلاتك يا ${user.fullName || user.appUserId}.`);
  // هنا يمكنك استدعاء الـ API الخاص بك لجلب رحلات المستخدم
  // باستخدام user.appUserId و user.appToken
  // مثال (تحتاج إلى استبدال هذا بالمنطق الفعلي):
  // try {
  //   const response = await axios.get(`${process.env.API_BASE_URL}/bookings/user/${user.appUserId}`, {
  //     headers: { 'Authorization': `Bearer ${user.appToken}` }
  //   });
  //   const bookings = response.data; // افترض أن الـ API يعيد قائمة بالرحلات
  //   if (bookings && bookings.length > 0) {
  //     let bookingsText = 'رحلاتك:\n';
  //     bookings.forEach(booking => {
  //       bookingsText += `- من ${booking.pickup} إلى ${booking.destination} في ${new Date(booking.datetime).toLocaleString()}\n`;
  //     });
  //     ctx.reply(bookingsText);
  //   } else {
  //     ctx.reply('ليس لديك أي رحلات سابقة.');
  //   }
  // } catch (err) {
  //   console.error('Failed to fetch bookings:', err.response?.data || err.message);
  //   ctx.reply('فشل جلب رحلاتك. الرجاء المحاولة لاحقاً.');
  // }
  ctx.reply('جلب الرحلات قيد التطوير!');
});


// --- Reverse Geocoding: تحويل الإحداثيات إلى اسم موقع ---
async function reverseGeocode(lat, lon) {
  const url = `https://nominatim.openstreetmap.org/reverse?format=json&lat=${lat}&lon=${lon}&zoom=18&addressdetails=1`;
  try {
    // مهم: إضافة User-Agent لطلبات Nominatim لتجنب الحظر
    const res = await axios.get(url, {
      headers: { 'User-Agent': 'TaxiGoBot/1.0 (contact@example.com)' } 
    });
    
    if (res.data && res.data.address) {
      const address = res.data.address;
      // بناء اسم الموقع من مكونات العنوان الأكثر تفصيلاً
      return [
        address.road, 
        address.house_number, // رقم المنزل إن وجد
        address.suburb,     // الحي/الضاحية
        address.village || address.town || address.city, // القرية أو البلدة أو المدينة
        address.state,      // المحافظة/الولاية
        address.country     // الدولة
      ].filter(Boolean).join(', '); // تصفية العناصر الفارغة وضمها بفاصلة
    }
  } catch (error) {
    console.error('Nominatim reverse geocoding error:', error.response?.data || error.message);
  }
  return null;
}

// --- Geocoding: تحويل اسم الموقع إلى إحداثيات ---
async function geocodeLocationByName(name) {
  // إضافة ', فلسطين' لتحسين دقة البحث الجغرافي داخل فلسطين
  const url = `https://nominatim.openstreetmap.org/search?format=json&q=${encodeURIComponent(name + ', فلسطين')}&limit=1`;
  try {
    // مهم: إضافة User-Agent لطلبات Nominatim لتجنب الحظر
    const res = await axios.get(url, {
      headers: { 'User-Agent': 'TaxiGoBot/1.0 (contact@example.com)' } 
    });
    
    if (res.data.length > 0) {
      const result = res.data[0];
      return {
        latitude: parseFloat(result.lat),
        longitude: parseFloat(result.lon),
        displayName: result.display_name // اسم الموقع الذي تعرف عليه Nominatim
      };
    }
  } catch (error) {
    console.error('Nominatim geocoding error:', error.response?.data || error.message);
  }
  throw new Error('❌ لم يتم العثور على الموقع');
}


// --- التعامل مع رسائل الموقع (Location Messages) ---
bot.on('location', async (ctx) => {
  if (!ctx.session) ctx.session = { ...initState }; // تأكد من تهيئة الجلسة
  const stage = ctx.session.stage;
  const loc = ctx.message.location; // بيانات الموقع من تيليجرام

  if (stage === 'awaiting_pickup_location') {
    ctx.session.pickupLocation = { 
      latitude: loc.latitude, 
      longitude: loc.longitude 
    };
    
    try {
      // محاولة الحصول على اسم الموقع من الإحداثيات
      const locationName = await reverseGeocode(loc.latitude, loc.longitude);
      ctx.session.pickup = locationName || `إحداثيات: ${loc.latitude.toFixed(4)}, ${loc.longitude.toFixed(4)}`; // استخدم الإحداثيات إذا لم يجد اسم
      
      ctx.session.stage = 'awaiting_destination_text'; // الانتقال للمرحلة التالية
      return ctx.reply(`📍 تم تحديد موقع الانطلاق: ${ctx.session.pickup}\n\n🚩 الرجاء إدخال الوجهة (مثال: نابلس):`);
    } catch (error) {
      console.error('Error during pickup location reverse geocoding:', error);
      ctx.session.pickup = `إحداثيات: ${loc.latitude.toFixed(4)}, ${loc.longitude.toFixed(4)}`;
      ctx.session.stage = 'awaiting_destination_text';
      return ctx.reply('📍 تم تحديد موقعك الحالي (من خلال الإحداثيات).\n🚩 الرجاء إدخال الوجهة (مثال: نابلس):');
    }
  } else {
    // رسالة للمستخدم إذا أرسل موقعاً في غير وقته
    return ctx.reply('تلقيت موقعاً ولكنني لا أنتظر تحديد موقع حالياً. يرجى البدء من جديد باستخدام /start أو /book_trip.');
  }
});


// --- التعامل مع الرسائل النصية (Text Messages) ---
bot.on('text', async (ctx) => {
  if (!ctx.session) ctx.session = { ...initState }; // تأكد من تهيئة الجلسة
  const stage = ctx.session.stage || 'start'; // تحديد المرحلة الحالية للمستخدم
  const msg = ctx.message.text.trim(); // الرسالة النصية من المستخدم

  // لو كان المستخدم مسجل دخول بالفعل واستخدم لوحة المفاتيح
  if (linkedUsers[ctx.from.id]) {
      const user = linkedUsers[ctx.from.id];
      // في هذه الحالة، المستخدم مسجل دخول بالفعل
      // ويمكنه استخدام الأزرار المعروضة في لوحة المفاتيح
      if (msg === 'حجز رحلة جديدة') {
          // استدعاء أمر /book_trip برمجياً
          // يجب عليك التأكد من أن هذا يعمل بشكل صحيح مع Telegraf
          // الأسهل هو توجيه المستخدم لكتابة الأمر
          await ctx.reply(`تمام ${user.fullName || user.appUserId}! يرجى كتابة الأمر /book_trip لبدء حجز جديد.`);
          return;
      } else if (msg === 'رحلاتي') {
          // استدعاء أمر /my_bookings برمجياً
          await ctx.reply(`جاري جلب رحلاتك يا ${user.fullName || user.appUserId}. يرجى كتابة الأمر /my_bookings.`);
          return;
      }
      // إذا كان المستخدم في حالة 'ready_for_booking' ويرسل نصًا غير الأزرار
      if (stage === 'ready_for_booking') {
        return ctx.reply('لم أفهم طلبك. يرجى استخدام الأزرار في لوحة المفاتيح أو الأوامر مثل /book_trip.');
      }
  }


  switch (stage) {
    case 'awaiting_email':
      ctx.session.email = msg;
      ctx.session.stage = 'awaiting_password';
      return ctx.reply('🔒 الرجاء إدخال كلمة المرور:');

    case 'awaiting_password':
      ctx.session.password = msg;
      try {
        await ctx.reply('جاري التحقق من معلومات تسجيل الدخول...');
        
        // استدعاء الـ API الخاص بك لتسجيل الدخول
        const res = await axios.post(`${process.env.API_BASE_URL}/users/signin`, {
          email: ctx.session.email,
          password: ctx.session.password
        });

        // تسجيل الدخول ناجح!
        ctx.session.token = res.data.token;
        ctx.session.userId = res.data.user.userId; // <--- التعديل الرئيسي هنا: استخدام _id

        // حفظ ربط المستخدمين بشكل دائم
        linkedUsers[ctx.from.id] = {
            appUserId: ctx.session.userId,
            fullName: res.data.user.fullName || res.data.user.email.split('@')[0],
            appToken: ctx.session.token
        };
        await saveLinkedUsers();

        ctx.session.stage = 'ready_for_booking'; // الانتقال إلى حالة جاهزة لاستقبال الأوامر/الحجز
        
        const fullName = linkedUsers[ctx.from.id].fullName || linkedUsers[ctx.from.id].appUserId;
        return ctx.reply(
          `✅ مرحباً ${fullName}! تم تسجيل الدخول بنجاح.\n\n` +
          `الآن يمكنك البدء في حجز رحلة جديدة بكتابة /book_trip أو عرض رحلاتك السابقة بكتابة /my_bookings.`, 
          Markup.keyboard([
            ['حجز رحلة جديدة', 'رحلاتي']
          ]).resize().oneTime()
        );
        
      } catch (err) {
        console.error('Login error:', err.response?.data || err.message);
        ctx.session = { ...initState }; // إعادة تعيين الجلسة بعد الفشل
        let errorMessage = '❌ فشل تسجيل الدخول. معلومات غير صحيحة أو حساب غير مفعل.';
        if (err.response && err.response.data && err.response.data.message) {
            errorMessage = `❌ ${err.response.data.message}`; // استخدام رسالة الخطأ من الـ API
        }
        return ctx.reply(errorMessage + '\nالرجاء المحاولة مجددًا.\nأدخل بريدك الإلكتروني:');
      }

    case 'awaiting_destination_text':
      ctx.session.destination = msg; // تخزين اسم الوجهة كنص
      try {
        // تحويل اسم الوجهة إلى إحداثيات
        const location = await geocodeLocationByName(msg);
        ctx.session.destinationLocation = {
          latitude: location.latitude,
          longitude: location.longitude
        };
        
        ctx.session.stage = 'awaiting_datetime';
        return ctx.reply(
          `📍 تم تحديد الوجهة: ${location.displayName || msg}\n\n` + 
          '🕓 متى تريد الرحلة؟ (مثال: 2025-06-20 14:00)\nصيغة الوقت: YYYY-MM-DD HH:MM'
        );
      } catch (e) {
        console.error('Geocoding error:', e);
        return ctx.reply('❌ لم أتمكن من تحديد موقع الوجهة. الرجاء إدخال اسم آخر (مثال: نابلس):');
      }

    case 'awaiting_datetime':
      // التحقق من صيغة التاريخ والوقت
      if (!/^\d{4}-\d{2}-\d{2} \d{2}:\d{2}$/.test(msg)) {
        return ctx.reply('⚠️ صيغة التاريخ غير صحيحة. الرجاء إدخال التاريخ بالشكل: 2025-06-20 14:00');
      }

      ctx.session.datetime = msg; // تخزين تاريخ ووقت الرحلة كنص

      // التحقق من وجود جميع البيانات المطلوبة قبل إرسال الطلب
      if (!ctx.session.userId || !ctx.session.token || 
          !ctx.session.pickupLocation || !ctx.session.destinationLocation ||
          !ctx.session.pickup || !ctx.session.destination || !ctx.session.datetime) {
        console.error('Missing session data for booking:', ctx.session);
        ctx.session = { ...initState, token: ctx.session.token, userId: ctx.session.userId }; // إعادة تعيين الجلسة مع الاحتفاظ بمعلومات الدخول
        return ctx.reply('❌ حدث خطأ في جمع معلومات الرحلة. الرجاء البدء من جديد بكتابة /book_trip');
      }

      try {
        const dist = getDistance(ctx.session.pickupLocation, ctx.session.destinationLocation);
        const estimatedFare = +(dist * 4.4).toFixed(2); // 4.4 شيكل لكل كم، قم بتغيير هذا حسب نظام تسعيرك

        await ctx.reply('جاري تأكيد حجز رحلتك...');

        // بناء جسم طلب الـ API ليطابق ما يتوقعه الـ Backend
        const tripData = {
          userId: ctx.session.userId, 
          startLocation: {
            latitude: ctx.session.pickupLocation.latitude,
            longitude: ctx.session.pickupLocation.longitude,
            address: ctx.session.pickup 
          },
          endLocation: {
            latitude: ctx.session.destinationLocation.latitude,
            longitude: ctx.session.destinationLocation.longitude,
            address: ctx.session.destination 
          },
          distance: dist,
          estimatedFare: estimatedFare,
          paymentMethod: 'cash', // يمكن جعل هذا ديناميكياً لاحقاً
          startTime: ctx.session.datetime // الـ Backend يتوقع 'startTime'
          // 'source': 'telegram' يمكن إضافته إلى الـ Trip model كحقل اختياري لتتبع المصدر
        };

        const config = {
          headers: { Authorization: `Bearer ${ctx.session.token}` } // توكن المصادقة للمستخدم
        };

        const bookRes = await axios.post(`${process.env.API_BASE_URL}/trips`, tripData, config);

        await ctx.replyWithMarkdown(`
          ✅ *تم حجز الرحلة بنجاح!*
          \n*رقم الرحلة:* \`${bookRes.data.tripId}\`
          \n*من:* ${ctx.session.pickup}
          \n*إلى:* ${ctx.session.destination}
          \n*المسافة:* ${dist.toFixed(2)} كم
          \n*الأجرة التقديرية:* ${estimatedFare} شيكل
          \n*الوقت المطلوب:* ${ctx.session.datetime}
        `);
        
        ctx.session = { ...initState, token: ctx.session.token, userId: ctx.session.userId }; // إعادة تعيين الجلسة مع الاحتفاظ بمعلومات الدخول
        ctx.session.stage = 'ready_for_booking'; // العودة للحالة التي تسمح بحجز جديد أو غيرها
        
      } catch (err) {
        console.error('Booking error details:', err.response?.data || err.message);
        let errorMsg = '❌ حدث خطأ أثناء الحجز. الرجاء المحاولة لاحقًا.';
        if (err.response && err.response.data && err.response.data.details) {
          errorMsg += `\nالتفاصيل: ${err.response.data.details}`;
        } else if (err.response && err.response.data && err.response.data.error) {
          errorMsg += `\nالخطأ: ${err.response.data.error}`;
        }
        ctx.reply(errorMsg + '\nيمكنك البدء من جديد بكتابة /book_trip');
        ctx.session = { ...initState, token: ctx.session.token, userId: ctx.session.userId }; // إعادة تعيين الحالة مع الاحتفاظ بمعلومات الدخول
      }
      break;

    // حالة 'ready_for_booking' هي للمستخدمين المسجلين دخولاً وينتظرون أمراً جديداً
    case 'ready_for_booking': 
      return ctx.reply('لم أفهم طلبك. يرجى استخدام الأزرار في لوحة المفاتيح أو الأوامر مثل /book_trip أو /my_bookings.');
      
    case 'start': // حالة افتراضية قبل بدء أي محادثة فعلية
    case 'IDLE': // حالة خاملة إذا لم يكن المستخدم في أي عملية محددة
    default:
      return ctx.reply('📝 الرجاء بدء المحادثة بكتابة /start');
  }
});

// --- دالة حساب المسافة بين نقطتين (بالكيلومترات) باستخدام صيغة هافرسين ---
function getDistance(loc1, loc2) {
  const toRad = (val) => (val * Math.PI) / 180;
  const R = 6371; // نصف قطر الأرض بالكيلومترات
  const dLat = toRad(loc2.latitude - loc1.latitude);
  const dLon = toRad(loc2.longitude - loc1.longitude);
  const a = Math.sin(dLat / 2) ** 2 +
    Math.cos(toRad(loc1.latitude)) * Math.cos(toRad(loc2.latitude)) *
    Math.sin(dLon / 2) ** 2;
  return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

// --- بدء تشغيل البوت ---
bot.launch().then(() => console.log('🚀 TaxiGo Bot started')).catch(console.error);

// تمكين إيقاف البوت بشكل جيد عند تلقي إشارات الإيقاف
process.once('SIGINT', () => bot.stop('SIGINT')); // Ctrl+C
process.once('SIGTERM', () => bot.stop('SIGTERM')); // أمر kill
