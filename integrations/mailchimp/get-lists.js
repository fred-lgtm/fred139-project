require('dotenv').config();
const { makeRequest } = require('./api-client');

async function getLists() {
  console.log('📬 Fetching Mailchimp lists...\n');

  try {
    const response = await makeRequest('/lists');

    console.log(`✅ Retrieved ${response.lists.length} lists\n`);

    response.lists.forEach((list, index) => {
      console.log(`${index + 1}. ${list.name}`);
      console.log(`   Members: ${list.stats.member_count}`);
      console.log(`   Created: ${new Date(list.date_created).toLocaleDateString()}`);
      console.log('');
    });
  } catch (error) {
    console.error('❌ Error:', error.message);
  }
}

getLists();