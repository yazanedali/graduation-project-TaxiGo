const express = require('express');
const router = express.Router();
const notificationController = require('../controllers/notificationController');

// إنشاء إشعار
router.post('/', async (req, res) => {
  try {
    const notification = await notificationController.createNotification(req.body);
    res.status(201).json({ success: true, data: notification });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// الحصول على إشعارات المستخدم
router.get('/', async (req, res) => {
  try {
    const userId = req.query.userId;

    if (!userId) {
      return res.status(400).json({ success: false, error: 'User ID is required' });
    }

    const notifications = await notificationController.getUserNotifications(
      userId,
      req.query
    );

    res.json({ success: true, data: notifications });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// تحديث الإشعار كمقروء
router.post('/:id/read', async (req, res) => {
  try {
    const { userId } = req.body;
    if (!userId) {
      return res.status(400).json({ error: 'User ID is required' });
    }

    await notificationController.markAsRead(req.params.id, userId);
    res.json({ success: true });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// حذف إشعار
router.delete('/:id', async (req, res) => {
  try {
    const { userId } = req.body;
    if (!userId) {
      return res.status(400).json({ error: 'User ID is required' });
    }

    const notification = await notificationController.deleteNotification(req.params.id, userId);
    res.json({ success: true, data: notification });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// إشعارات غير مقروءة
router.get('/unread', async (req, res) => {
  try {
    const userId = req.query.userId;
    if (!userId) {
      return res.status(400).json({ success: false, error: 'User ID is required' });
    }

    const notifications = await notificationController.getUnreadNotifications(userId);
    res.json({ success: true, data: notifications });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// عدد الإشعارات غير المقروءة
router.get('/unread-count', async (req, res) => {
  try {
    const userId = req.query.userId;
    const userType = req.query.userType;

    if (!userId || !userType) {
      return res.status(400).json({ success: false, error: 'userId and userType are required' });
    }

    const count = await notificationController.getUnreadCount(userId, userType);
    res.json({ success: true, count });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

module.exports = router;
