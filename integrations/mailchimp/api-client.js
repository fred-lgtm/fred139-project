require('dotenv').config();
const https = require('https');

const apiKey = process.env.MAILCHIMP_API_KEY;
const serverPrefix = process.env.MAILCHIMP_SERVER_PREFIX; // e.g., 'us1', 'us2', etc.

if (!apiKey || !serverPrefix) {
  console.error('❌ Error: MAILCHIMP_API_KEY or MAILCHIMP_SERVER_PREFIX not found in .env');
  process.exit(1);
}

function makeRequest(path, method = 'GET', data = null) {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: `${serverPrefix}.api.mailchimp.com`,
      path: `/3.0${path}`,
      method: method,
      headers: {
        'Authorization': `Bearer ${apiKey}`,
        'Content-Type': 'application/json'
      }
    };

    const req = https.request(options, (res) => {
      let responseData = '';

      res.on('data', (chunk) => {
        responseData += chunk;
      });

      res.on('end', () => {
        if (res.statusCode >= 200 && res.statusCode < 300) {
          resolve(JSON.parse(responseData));
        } else {
          reject(new Error(`Request failed: ${res.statusCode} - ${responseData}`));
        }
      });
    });

    req.on('error', (error) => {
      reject(error);
    });

    if (data) {
      req.write(JSON.stringify(data));
    }

    req.end();
  });
}

module.exports = { makeRequest };