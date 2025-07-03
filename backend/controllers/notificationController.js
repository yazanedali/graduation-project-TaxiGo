const Notification = require('../models/Notification');
const User = require('../models/User');
const admin = require("../../firebase/servicefire");
const sendPushNotification = async (fcmToken, title, body, data = {}) => {
  if (!fcmToken) return;

  // تحويل جميع القيم في data إلى نصوص
  const stringData = {};
  for (const key in data) {
    if (data.hasOwnProperty(key)) {
      stringData[key] = String(data[key]);
    }
  }

  const message = {
    token: fcmToken,
    notification: {
      title,
      body,
    },
    data: stringData,
  };

  try {
    await admin.messaging().send(message);
    console.log("[FCM] Notification sent successfully.");
  } catch (error) {
    console.error("[FCM ERROR]", error.message);
  }
};



// إنشاء إشعار جديد
exports.createNotification = async (data) => {
  try {
    console.log('Notification data:', data);

    const notification = new Notification(data);
    await notification.save();

    // ابحث عن المستقبل في جدول User
    const recipient = await User.findOne({ userId: data.recipient });
    console.log('Recipient found:', recipient);

    if (recipient && recipient.fcmToken) {
      await sendPushNotification(
        recipient.fcmToken,
        data.title,
        data.message,
        data.data || {}
      );
    } else {
      console.warn('No recipient found or recipient has no fcmToken');
    }

    return notification;
  } catch (error) {
    console.error('Notification error:', error);
    throw new Error('Failed to create notification');
  }
};

// الحصول على إشعارات مستخدم معين
exports.getUserNotifications = async (userId, { limit = 10, page = 1 }) => {
  try {
    const skip = (page - 1) * limit;
    
    const notifications = await Notification.find({
      recipient: userId,
      status: { $ne: 'deleted' }
    })
    .sort({ createdAt: -1 })
    .skip(skip)
    .limit(limit)
    .lean();

    return notifications;
  } catch (error) {
    throw new Error('Failed to fetch notifications');
  }
};

// تحديث حالة الإشعار (مثلاً عند القراءة)
exports.markAsRead = async (notificationId, userId) => {
  try {
    console.log('Marking notification as read:', notificationId, 'for user:', userId);
    await Notification.findOneAndUpdate(
      {
        notificationId: notificationId,
        recipient: userId,
        status: 'unread'
      },
      {
        status: 'read',
        readAt: new Date()
      }
    );
  } catch (error) {
    throw new Error('Failed to mark notification as read');
  }
};

// جلب الإشعارات الغير مقروءة
exports.getUnreadNotifications = async (userId) => {
  try {
    console.log('Fetching unread notifications for user:', userId);
    return await Notification.find({
      recipient: userId,
      status: 'unread'
    }).sort({ createdAt: -1 });
  } catch (error) {
    throw new Error('Failed to fetch unread notifications');
  }
};

exports.deleteNotification = async (notificationId, userId) => {
  try {
    const notification = await Notification.findOneAndUpdate(
      {
        notificationId: Number(notificationId),
        recipient: userId
      },
      {
        status: 'deleted'
      },
      { new: true }
    );

    return notification;
  } catch (error) {
    throw new Error('Failed to delete notification');
  }
};

// عدد الإشعارات غير المقروءة
exports.getUnreadCount = async (userId, userType) => {
  try {
    const count = await Notification.countDocuments({
      recipient: userId,
      recipientType: userType,
      status: 'unread'
    });
    
    return count;
  } catch (error) {
    throw new Error('Failed to get unread count');
  }
};