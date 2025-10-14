const AWS = require('aws-sdk');

const s3 = new AWS.S3({
  region: process.env.AWS_REGION
});

const s3Config = {
  bucket: process.env.S3_BUCKET_NAME,
  region: process.env.AWS_REGION
};

module.exports = { s3, s3Config };