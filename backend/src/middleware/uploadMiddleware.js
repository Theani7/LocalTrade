const multer = require('multer');

// Store files in memory as buffers before uploading to Cloudinary
const storage = multer.memoryStorage();

const path = require('path');

// Filter to ensure only image files are uploaded
const fileFilter = (req, file, cb) => {
  const allowedTypes = /jpeg|jpg|png|webp|gif/;
  const mimetype = allowedTypes.test(file.mimetype);
  const extname = allowedTypes.test(path.extname(file.originalname).toLowerCase());

  if (mimetype && extname) {
    cb(null, true);
  } else {
    cb(new Error('Invalid file type. Only JPG, JPEG, PNG, WEBP, and GIF images are allowed.'), false);
  }
};

/**
 * Multer upload middleware
 * - memoryStorage: keeps file in RAM
 * - limits: 5MB per file
 * - fileFilter: allows images only
 */
const upload = multer({
  storage: storage,
  fileFilter: fileFilter,
  limits: {
    fileSize: 5 * 1024 * 1024, // 5MB limit per file
  },
});

module.exports = upload;
