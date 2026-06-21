const cloudinary = require('../config/cloudinary');

/**
 * Uploads a file buffer to Cloudinary
 * @param {Buffer} fileBuffer - The file buffer from multer memoryStorage
 * @param {String} folder - Optional folder name in Cloudinary
 * @returns {Promise<String>} - The secure URL of the uploaded image
 */
exports.uploadToCloudinary = async (fileBuffer, folder = 'localtrade/products') => {
  return new Promise((resolve, reject) => {
    const uploadStream = cloudinary.uploader.upload_stream(
      {
        folder: folder,
        resource_type: 'auto',
      },
      (error, result) => {
        if (error) {
          console.error('Cloudinary Upload Error:', error);
          return reject(new Error('Failed to upload image to Cloudinary'));
        }
        resolve(result.secure_url);
      }
    );
    uploadStream.end(fileBuffer);
  });
};

/**
 * Deletes an image from Cloudinary using its public ID
 * @param {String} publicId - The public ID of the image
 */
exports.deleteFromCloudinary = async (publicId) => {
  try {
    await cloudinary.uploader.destroy(publicId);
  } catch (error) {
    console.error('Cloudinary Delete Error:', error);
  }
};
