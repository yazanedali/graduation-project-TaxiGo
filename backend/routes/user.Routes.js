const express = require('express');
const router = express.Router();
const authMiddleware = require('../middleware/authMiddleware');

// استيراد التحكم (controller)
const { createUser, loginUser, getUsers, logoutUser,getPrintFullName, getUserById, verifyEmail, changePassword, forgotPassword, resetPassword} = require('../controllers/userController');

// نقطة النهاية لإضافة مستخدم جديد
router.post('/signup', createUser);

// نقطة النهاية لتسجيل الدخول
router.post('/signin', loginUser);

// نقطة النهاية لاسترجاع جميع المستخدمين
router.get('/', getUsers);  // هذه ستظل كما هي

// router.post('/logout', logoutUser);
router.put('/logout', logoutUser);

router.get('/fullname/:userId', getPrintFullName);

// نقطة النهاية لاسترجاع السائقين فقط
router.get('/drivers', async (req, res) => {
  try {
    // تصفية السائقين فقط
    const users = await getUsers({ role: 'Driver' });
    res.json(users);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'حدث خطأ أثناء جلب السائقين' });
  }
});


router.get('/verify-email', verifyEmail);

router.get('/:id', getUserById);


// تغيير كلمة المرور (يتطلب تسجيل دخول)
router.put('/change-password', changePassword);

// نسيان كلمة المرور
router.post('/forgot-password', forgotPassword);

// إعادة تعيين كلمة المرور
router.get('/reset-password/:token', (req, res) => {
  const { token } = req.params;
  // هنا سنعرض صفحة HTML بسيطة لجمع كلمة المرور الجديدة
  // هذه الصفحة ستقوم بإرسال طلب POST إلى مسار resetPassword أدناه
  res.send(`
    <!DOCTYPE html>
    <html lang="ar" dir="rtl">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>إعادة تعيين كلمة المرور</title>
        <style>
            body { 
                font-family: 'Arial', sans-serif; 
                background-color: #f0f2f5; 
                margin: 0; 
                padding: 20px; 
                display: flex; 
                justify-content: center; 
                align-items: center; 
                min-height: 100vh; 
                color: #333;
            }
            .container { 
                background-color: #ffffff; 
                padding: 40px; 
                border-radius: 12px; 
                box-shadow: 0 4px 20px rgba(0,0,0,0.1); 
                width: 100%; 
                max-width: 450px; 
                text-align: center; 
                border-top: 5px solid #FFC107;
            }
            h2 { 
                color: #333333; 
                margin-bottom: 25px; 
                font-size: 26px; 
                font-weight: bold;
            }
            p {
                margin-bottom: 20px;
                color: #555;
                font-size: 16px;
            }
            label { 
                display: block; 
                margin-bottom: 8px; 
                color: #555; 
                text-align: right; 
                font-weight: bold;
            }
            input[type="password"] { 
                width: calc(100% - 22px); /* Adjust for padding and border */
                padding: 12px; 
                margin-bottom: 20px; 
                border: 1px solid #ddd; 
                border-radius: 6px; 
                box-sizing: border-box; 
                font-size: 16px;
            }
            button { 
                background-color: #FFC107; /* Taxi Yellow */
                color: #333333; /* Dark text for contrast */
                padding: 15px 25px; 
                border: none; 
                border-radius: 8px; 
                cursor: pointer; 
                font-size: 18px; 
                font-weight: bold;
                width: 100%; 
                transition: background-color 0.3s ease;
            }
            button:hover { 
                background-color: #e0b000; /* Slightly darker yellow on hover */
            }
            .message { 
                margin-top: 25px; 
                padding: 15px; 
                border-radius: 8px; 
                font-size: 15px;
                text-align: center;
            }
            .success { 
                background-color: #d4edda; 
                color: #155724; 
                border: 1px solid #c3e6cb; 
            }
            .error { 
                background-color: #f8d7da; 
                color: #721c24; 
                border: 1px solid #f5c6cb; 
            }
            .taxi-icon {
                font-size: 40px; /* Adjust size as needed */
                margin-bottom: 15px;
                color: #FFC107; /* Taxi Yellow */
            }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="taxi-icon">🚕</div>
            <h2>إعادة تعيين كلمة المرور</h2>
            <p>الرجاء إدخال كلمة المرور الجديدة لحسابك.</p>
            <form id="resetForm">
                <label for="newPassword">كلمة المرور الجديدة:</label>
                <input type="password" id="newPassword" name="newPassword" required minlength="6">
                <label for="confirmNewPassword">تأكيد كلمة المرور الجديدة:</label>
                <input type="password" id="confirmNewPassword" name="confirmNewPassword" required>
                <button type="submit">إعادة تعيين</button>
            </form>
            <div id="message" class="message" style="display: none;"></div>
        </div>

        <script>
            const form = document.getElementById('resetForm');
            const messageDiv = document.getElementById('message');
            // استخراج التوكن من مسار URL الحالي
            const urlToken = window.location.pathname.split('/').pop();

            form.addEventListener('submit', async (e) => {
                e.preventDefault(); // منع الإرسال الافتراضي للصفحة

                messageDiv.style.display = 'none'; // إخفاء الرسالة السابقة

                const newPassword = document.getElementById('newPassword').value;
                const confirmNewPassword = document.getElementById('confirmNewPassword').value;

                if (newPassword !== confirmNewPassword) {
                    messageDiv.className = 'message error';
                    messageDiv.textContent = 'كلمتا المرور غير متطابقتين!';
                    messageDiv.style.display = 'block';
                    return;
                }
                if (newPassword.length < 6) {
                    messageDiv.className = 'message error';
                    messageDiv.textContent = 'يجب أن تكون كلمة المرور 6 أحرف على الأقل.';
                    messageDiv.style.display = 'block';
                    return;
                }

                try {
                    // إرسال طلب POST إلى Backend لمعالجة إعادة تعيين كلمة المرور
                    const response = await fetch(\`${process.env.APP_URL}/reset-password/\${urlToken}\`, { // استخدم APP_URL هنا
                        method: 'POST',
                        headers: {
                            'Content-Type': 'application/json',
                        },
                        body: JSON.stringify({ newPassword, confirmNewPassword }),
                    });

                    const data = await response.json();

                    messageDiv.className = \`message \${data.success ? 'success' : 'error'}\`;
                    messageDiv.textContent = data.message;
                    messageDiv.style.display = 'block';

                    if (data.success) {
                        form.reset(); // مسح حقول النموذج بعد النجاح
                        // يمكنك إضافة إعادة توجيه المستخدم أو إظهار رسالة نجاح دائمة
                        // setTimeout(() => { window.location.href = '${process.env.APP_URL}/login'; }, 3000); // مثال: إعادة توجيه لصفحة تسجيل الدخول
                    }

                } catch (error) {
                    console.error('Error:', error);
                    messageDiv.className = 'message error';
                    messageDiv.textContent = 'حدث خطأ أثناء معالجة طلبك، يرجى المحاولة لاحقاً.';
                    messageDiv.style.display = 'block';
                }
            });
        </script>
    </body>
    </html>
  `);
});

// 2. مسار POST لمعالجة إعادة تعيين كلمة المرور (لديك هذا بالفعل)
router.post('/reset-password/:token', resetPassword);



module.exports = router;
