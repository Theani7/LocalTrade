const admin = require('../config/firebase');
const Notification = require('../models/notificationModel');
const User = require('../models/userModel');

/**
 * Send a notification to a specific user
 * @param {string} userId - Recipient user ID
 * @param {string} title - Notification title
 * @param {string} message - Notification body
 * @param {Object} data - Additional data for the notification
 * @param {string} type - Notification type (Order, System, Account)
 */
exports.sendNotification = async (userId, title, message, data = {}, type = 'System') => {
  try {
    // 1) Save notification to database
    await Notification.create({
      recipient: userId,
      title,
      message,
      data,
      type,
    });

    // 2) Get user's FCM token
    const user = await User.findById(userId).select('fcmToken');
    
    if (user && user.fcmToken) {
      const payload = {
        notification: {
          title,
          body: message,
        },
        data: {
          ...data,
          type,
          click_action: 'FLUTTER_NOTIFICATION_CLICK',
        },
        token: user.fcmToken,
      };

      // 3) Send via Firebase
      try {
        await admin.messaging().send(payload);
        console.log(`Notification sent to user ${userId}`);
      } catch (fcmError) {
        console.error('FCM Send Error:', fcmError.message);
      }
    } else {
      console.log(`User ${userId} has no FCM token. Notification saved to DB only.`);
    }
  } catch (error) {
    console.error('Send Notification Error:', error.message);
  }
};

/**
 * Send a notification to all admin users
 * @param {string} title - Notification title
 * @param {string} message - Notification body
 * @param {Object} data - Additional data
 */
exports.notifyAdmins = async (title, message, data = {}) => {
  try {
    const admins = await User.find({ role: 'admin' }).select('_id');
    console.log(`DEBUG: Found ${admins.length} admins to notify.`);
    if (admins.length === 0) {
      console.log('DEBUG: No admins found in database!');
    }
    
    const notificationPromises = admins.map(adminUser => 
      exports.sendNotification(adminUser._id, title, message, data, 'Account')
    );
    await Promise.all(notificationPromises);
    console.log(`Admin notification sent to ${admins.length} admins: ${title}`);
  } catch (error) {
    console.error('Notify Admins Error:', error.message);
  }
};
