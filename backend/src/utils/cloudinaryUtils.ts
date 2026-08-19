import cloudinary from '../config/cloudinary';

/**
 * Uploads a file buffer to Cloudinary
 * @param fileBuffer - The file buffer from multer memoryStorage
 * @param folder - Optional folder name in Cloudinary
 * @returns The secure URL of the uploaded image
 */
export const uploadToCloudinary = async (
  fileBuffer: Buffer,
  folder: string = 'localtrade/products'
): Promise<string> => {
  return new Promise((resolve, reject) => {
    const uploadStream = cloudinary.uploader.upload_stream(
      {
        folder: folder,
        resource_type: 'auto',
      },
      (error, result) => {
        if (error || !result) {
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
 * @param publicId - The public ID of the image
 */
export const deleteFromCloudinary = async (publicId: string): Promise<void> => {
  try {
    await cloudinary.uploader.destroy(publicId);
  } catch (error) {
    console.error('Cloudinary Delete Error:', error);
  }
};

export default { uploadToCloudinary, deleteFromCloudinary };
