const express = require('express');
const router = express.Router();
const messageController = require('../controllers/messageController');

// إرسال رسالة
// router.post('/', messageController.sendMessage);

// جلب الرسائل بين المستخدم والسائق
router.get('/', messageController.getMessages);

// تحديث حالة القراءة للرسائل
router.post('/mark-read', messageController.markMessagesAsRead);

// الحصول على عدد الرسائل غير المقروءة
router.get('/unread/:receiver', messageController.getUnreadCount);

module.exports = router;
