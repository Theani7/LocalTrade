const multer = require('multer');
const path = require('path');

// Store files in memory as buffers before uploading to Cloudinary
const storage = multer.memoryStorage();

// Magic byte signatures for allowed image formats
const IMAGE_SIGNATURES = [
  [0xff, 0xd8, 0xff], // jpeg
  [0x89, 0x50, 0x4e, 0x47], // png
  [0x52, 0x49, 0x46, 0x46], // webp (RIFF....WEBP)
  [0x47, 0x49, 0x46], // gif
];

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

// Reject uploaded files whose content doesn't match a known image signature.
// Runs after multer has populated req.files/req.file buffers.
const validateImageContent = (req, res, next) => {
  const files = req.files ? (Array.isArray(req.files) ? req.files : Object.values(req.files).flat()) : (req.file ? [req.file] : []);

  for (const file of files) {
    if (!file || !file.buffer || file.buffer.length < 4) {
      return next(new Error('File is empty or too small to be an image.'));
    }
    const matches = IMAGE_SIGNATURES.some((sig) =>
      sig.every((byte, i) => file.buffer[i] === byte)
    );
    if (!matches) {
      return next(new Error('File content is not a valid image.'));
    }
  }

  next();
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
module.exports.validateImageContent = validateImageContent;
