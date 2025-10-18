const AWS = require('aws-sdk');
const fs = require('fs');

// ADD CREDENTIALS - THIS IS WHAT'S MISSING
if (process.env.AWS_WEB_IDENTITY_TOKEN_FILE && process.env.AWS_ROLE_ARN) {
  const token = fs.readFileSync(process.env.AWS_WEB_IDENTITY_TOKEN_FILE, 'utf8');
  AWS.config.credentials = new AWS.WebIdentityCredentials({
    RoleArn: process.env.AWS_ROLE_ARN,
    WebIdentityToken: token
  });
}

// YOUR ORIGINAL CODE
const s3 = new AWS.S3({
  region: process.env.AWS_REGION
});

const s3Config = {
  bucket: process.env.S3_BUCKET_NAME,
  region: process.env.AWS_REGION
};

module.exports = { s3, s3Config };