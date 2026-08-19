import admin from '../config/firebase';
import Notification from '../models/notificationModel';
import User from '../models/userModel';
import { NotificationType } from '../types';

/**
 * Send a notification to a specific user
 * @param userId - Recipient user ID
 * @param title - Notification title
 * @param message - Notification body
 * @param data - Additional data for the notification
 * @param type - Notification type (Order, System, Account, Promotional)
 */
export const sendNotification = async (
  userId: any,
  title: string,
  message: string,
  data: Record<string, any> = {},
  type: NotificationType = 'System'
): Promise<void> => {
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
      const stringData: Record<string, string> = {};
      for (const [key, value] of Object.entries(data)) {
        stringData[key] = String(value);
      }

      const payload = {
        notification: {
          title,
          body: message,
        },
        data: {
          ...stringData,
          type,
          click_action: 'FLUTTER_NOTIFICATION_CLICK',
        },
        token: user.fcmToken,
      };

      // 3) Send via Firebase
      try {
        await admin.messaging().send(payload as any);
      } catch (fcmError) {
        // FCM send failed — notification already saved to DB
      }
    }
  } catch (error) {
    // Notification send failed silently
  }
};

/**
 * Send a promotional notification to all customers (fire-and-forget).
 * Resolves even if some sends fail; returns a promise for callers to .catch().
 * @param title - Notification title
 * @param message - Notification body
 * @param data - Additional data
 */
export const allCustomers = async (
  title: string,
  message: string,
  data: Record<string, any> = {}
): Promise<void> => {
  const customers = await User.find({ role: 'customer' }).select('_id').limit(2000);
  await Promise.all(
    customers.map((customer) =>
      sendNotification(customer._id, title, message, data, 'Promotional')
    )
  );
};

/**
 * Send a notification to all admin users
 * @param title - Notification title
 * @param message - Notification body
 * @param data - Additional data
 */
export const notifyAdmins = async (
  title: string,
  message: string,
  data: Record<string, any> = {}
): Promise<void> => {
  try {
    const admins = await User.find({ role: 'admin' }).select('_id');
    if (admins.length === 0) return;
    
    const notificationPromises = admins.map(adminUser => 
      sendNotification(adminUser._id, title, message, data, 'Account')
    );
    await Promise.all(notificationPromises);
  } catch (error) {
    // Admin notification failed silently
  }
};

export default {
  sendNotification,
  allCustomers,
  notifyAdmins,
};
