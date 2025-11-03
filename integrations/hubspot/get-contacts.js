require('dotenv').config();
const https = require('https');

const accessToken = process.env.HUBSPOT_ACCESS_TOKEN;

if (!accessToken) {
  console.error('❌ Error: HUBSPOT_ACCESS_TOKEN not found in .env file');
  process.exit(1);
}

const limit = process.argv[2] || 10;

console.log(`📋 Fetching ${limit} contacts from HubSpot...\n`);

const options = {
  hostname: 'api.hubapi.com',
  path: `/crm/v3/objects/contacts?limit=${limit}&properties=firstname,lastname,email,phone,company`,
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
    if (res.statusCode === 200) {
      const parsed = JSON.parse(data);
      console.log(`✅ Retrieved ${parsed.results.length} contacts\n`);

      parsed.results.forEach((contact, index) => {
        const props = contact.properties;
        console.log(`${index + 1}. ${props.firstname || ''} ${props.lastname || ''}`);
        console.log(`   Email: ${props.email || 'N/A'}`);
        console.log(`   Phone: ${props.phone || 'N/A'}`);
        console.log(`   Company: ${props.company || 'N/A'}`);
        console.log('');
      });
    } else {
      console.error('❌ Failed to fetch contacts');
      console.error('Response:', data);
    }
  });
});

req.on('error', (error) => {
  console.error('❌ Error:', error.message);
});

req.end();