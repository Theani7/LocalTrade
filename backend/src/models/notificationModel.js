const mongoose = require('mongoose');

const notificationSchema = new mongoose.Schema(
  {
    recipient: {
      type: mongoose.Schema.ObjectId,
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
      enum: ['Order', 'System', 'Account'],
      default: 'System',
    },
  },
  {
    timestamps: true,
  }
);

notificationSchema.index({ recipient: 1, createdAt: -1 });

const Notification = mongoose.model('Notification', notificationSchema);

module.exports = Notification;
