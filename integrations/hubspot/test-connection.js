require('dotenv').config();
const https = require('https');

const accessToken = process.env.HUBSPOT_ACCESS_TOKEN;

if (!accessToken) {
  console.error('❌ Error: HUBSPOT_ACCESS_TOKEN not found in .env file');
  process.exit(1);
}

console.log('🔍 Testing HubSpot API connection...\n');

const options = {
  hostname: 'api.hubapi.com',
  path: '/crm/v3/objects/contacts?limit=1',
  method: 'GET',
  headers: {
    'Authorization': `Bearer ${accessToken}`,
    'Content-Type': 'application/json'
  }
};

const req = https.request(options, (res) => {
  let data = '';

  res.on('data', (chunk) => {
    data += chunk;
  });

  res.on('end', () => {
    console.log(`Status Code: ${res.statusCode}`);

    if (res.statusCode === 200) {
      console.log('✅ HubSpot connection successful!\n');
      const parsed = JSON.parse(data);
      console.log('Sample contact data:', JSON.stringify(parsed, null, 2));
    } else {
      console.error('❌ HubSpot connection failed');
      console.error('Response:', data);
    }
  });
});

req.on('error', (error) => {
  console.error('❌ Connection error:', error.message);
});

req.end();