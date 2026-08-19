import mongoose, { Schema } from 'mongoose';
import { INotificationDoc } from '../types';

const notificationSchema = new Schema<INotificationDoc>(
  {
    recipient: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      required: [true, 'Notification must have a recipient'],
    },
    title: {
      type: String,
      required: [true, 'Notification must have a title'],
    },
    message: {
      type: String,
      required: [true, 'Notification must have a message'],
    },
    data: {
      type: Map,
      of: String,
    },
    isRead: {
      type: Boolean,
      default: false,
    },
    type: {
      type: String,
      enum: ['Order', 'System', 'Account', 'Promotional'],
      default: 'System',
    },
  },
  {
    timestamps: true,
  }
);

notificationSchema.index({ recipient: 1, createdAt: -1 });
notificationSchema.index({ recipient: 1, isRead: 1 });

const Notification = mongoose.model<INotificationDoc>('Notification', notificationSchema);

export = Notification;
