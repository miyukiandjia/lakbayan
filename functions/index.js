const functions = require('firebase-functions');
const { Storage } = require('@google-cloud/storage');
const path = require('path');
const os = require('os');
const fs = require('fs');
const im = require('imagemagick');

const gcs = new Storage();

exports.convertImage = functions.storage.object().onFinalize(async (object) => {
   const filePath = object.name;
   const contentType = object.contentType;

   // Check if contentType and filePath are defined
   if (!filePath || !contentType) return null;

   if (contentType === 'image/heic') {
      const bucketName = object.bucket;
      const bucket = gcs.bucket(bucketName);

      const tempLocalFile = path.join(os.tmpdir(), filePath);
      const tempLocalDir = path.dirname(tempLocalFile);

      await fs.promises.mkdir(tempLocalDir, { recursive: true });
      await bucket.file(filePath).download({ destination: tempLocalFile });

      const convertedTempLocalFile = tempLocalFile.replace(/\.heic$/, '.jpg');
      
      // Wrap the convert function in a Promise
      await new Promise((resolve, reject) => {
         im.convert([tempLocalFile, convertedTempLocalFile], (err) => {
            if (err) reject(err);
            else resolve();
         });
      });

      const destination = 'converted_images/' + path.basename(convertedTempLocalFile);
      await bucket.upload(convertedTempLocalFile, { destination });
      
      await fs.promises.unlink(tempLocalFile);
      await fs.promises.unlink(convertedTempLocalFile);
   }

   return null;
});
