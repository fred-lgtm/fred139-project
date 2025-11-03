require('dotenv').config();
const https = require('https');

const accessToken = process.env.HUBSPOT_ACCESS_TOKEN;

if (!accessToken) {
  console.error('❌ Error: HUBSPOT_ACCESS_TOKEN not found in .env file');
  process.exit(1);
}

const limit = process.argv[2] || 10;

console.log(`🏢 Fetching ${limit} companies from HubSpot...\n`);

const options = {
  hostname: 'api.hubapi.com',
  path: `/crm/v3/objects/companies?limit=${limit}&properties=name,domain,city,state,industry`,
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
      console.log(`✅ Retrieved ${parsed.results.length} companies\n`);

      parsed.results.forEach((company, index) => {
        const props = company.properties;
        console.log(`${index + 1}. ${props.name || 'Unnamed Company'}`);
        console.log(`   Domain: ${props.domain || 'N/A'}`);
        console.log(`   Location: ${props.city || ''} ${props.state || ''}`);
        console.log(`   Industry: ${props.industry || 'N/A'}`);
        console.log('');
      });
    } else {
      console.error('❌ Failed to fetch companies');
      console.error('Response:', data);
    }
  });
});

req.on('error', (error) => {
  console.error('❌ Error:', error.message);
});

req.end();