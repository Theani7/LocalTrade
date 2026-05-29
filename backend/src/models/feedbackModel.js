const mongoose = require('mongoose');

const feedbackSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.ObjectId,
      ref: 'User',
      required: [true, 'Feedback must belong to a user'],
    },
    role: {
      type: String,
      required: [true, 'User role is required'],
      enum: ['customer', 'vendor', 'admin'],
    },
    rating: {
      type: Number,
      required: [true, 'Overall rating is required'],
      min: 1,
      max: 5,
    },
    usabilityRating: {
      type: Number,
      required: [true, 'Usability rating is required'],
      min: 1,
      max: 5,
    },
    designRating: {
      type: Number,
      required: [true, 'Design rating is required'],
      min: 1,
      max: 5,
    },
    performanceRating: {
      type: Number,
      required: [true, 'Performance rating is required'],
      min: 1,
      max: 5,
    },
    featureCompletenessRating: {
      type: Number,
      required: [true, 'Feature completeness rating is required'],
      min: 1,
      max: 5,
    },
    comment: {
      type: String,
      required: [true, 'Please provide a comment'],
      trim: true,
      maxlength: [1000, 'Comment cannot exceed 1000 characters'],
    },
  },
  {
    timestamps: true,
  }
);

// Index for performance
feedbackSchema.index({ userId: 1 });
feedbackSchema.index({ role: 1 });
feedbackSchema.index({ createdAt: -1 });

const Feedback = mongoose.model('Feedback', feedbackSchema);

module.exports = Feedback;
