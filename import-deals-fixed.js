const axios = require('axios');
const fs = require('fs');
require('dotenv').config();

const HUBSPOT_TOKEN = process.env.HUBSPOT_ACCESS_TOKEN || process.env.HUBSPOT_API_KEY;

const hubspotClient = axios.create({
  baseURL: 'https://api.hubapi.com',
  headers: {
    'Authorization': `Bearer ${HUBSPOT_TOKEN}`,
    'Content-Type': 'application/json',
  },
  timeout: 30000
});

// Deals using ONLY standard HubSpot properties
const deals = [
  {
    dealname: 'Gotham Waterproofing - 55 Spruce St, Newark, NJ',
    amount: '29560',
    pipeline: 'default',
    dealstage: 'appointmentscheduled',
    closedate: new Date('2025-12-31').getTime(),
    description: 'Waterproofing, caulking, and sealer work. Contact: Maria Bello. Location: 55 Spruce St, Newark, NJ. Source: scan@brickface.com Nov 4-5, 2025.',
    hs_priority: 'high'
  },
  {
    dealname: 'Gotham Waterproofing - 59 Spruce St, Newark, NJ',
    amount: '7000',
    pipeline: 'default',
    dealstage: 'appointmentscheduled',
    closedate: new Date('2025-12-31').getTime(),
    description: 'Rear wall waterproofing. Contact: Maria Bello. Adjacent to 55 Spruce project - bundle opportunity. Location: 59 Spruce St, Newark, NJ. Source: scan@brickface.com.',
    hs_priority: 'medium'
  },
  {
    dealname: 'Anchor Stone - 20 Forest St, Montclair, NJ',
    amount: '10500',
    pipeline: 'default',
    dealstage: 'appointmentscheduled',
    closedate: new Date('2025-12-31').getTime(),
    description: 'Foundation repair work. Company: Anchor Stone. Location: 20 Forest St, Montclair, NJ. Source: scan@brickface.com.',
    hs_priority: 'medium'
  },
  {
    dealname: 'Gotham Waterproofing - The Highlands Apartments',
    amount: '23630',
    pipeline: 'default',
    dealstage: 'appointmentscheduled',
    closedate: new Date('2025-12-31').getTime(),
    description: 'Parking garage drain, deck repairs, balcony coatings. Contact: Wellington Batlle. Commercial property. Location: 40 E Hanover Ave, Morris Plains, NJ (The Highlands Apartments). Source: scan@brickface.com.',
    hs_priority: 'high'
  },
  {
    dealname: 'Garden State Brickface - 59 Skillman Ave, Jersey City',
    amount: '98950',
    pipeline: 'default',
    dealstage: 'qualifiedtobuy',
    closedate: new Date('2025-12-15').getTime(),
    description: 'HIGHEST VALUE DEAL ($98,950). Masonry restoration and painting. Contact: Saied Atewan. Comprehensive facade renovation project. Location: 59 Skillman Ave, Jersey City, NJ. Source: scan@brickface.com. PRIORITY FOLLOW-UP REQUIRED.',
    hs_priority: 'high'
  },
  {
    dealname: 'Gotham Waterproofing - 300 Bunn Drive, Princeton',
    amount: '10950',
    pipeline: 'default',
    dealstage: 'appointmentscheduled',
    closedate: new Date('2025-12-31').getTime(),
    description: 'Window waterproofing at Units A-203 and D-403. Multi-unit property - potential for expansion. Location: 300 Bunn Drive, Princeton, NJ. Source: scan@brickface.com.',
    hs_priority: 'medium'
  },
  {
    dealname: 'Garden State Brickface - 201 Wescott Drive, Rahway',
    amount: '50000',
    pipeline: 'default',
    dealstage: 'qualifiedtobuy',
    closedate: new Date('2025-12-15').getTime(),
    description: 'SECOND HIGHEST VALUE ($50,000). Large stucco/siding project. Company: Garden State Brickface. Significant exterior restoration work. Location: 201 Wescott Drive, Rahway, NJ. Source: scan@brickface.com.',
    hs_priority: 'high'
  },
  {
    dealname: 'Garden State Commercial - Wallace Vinyl Windows',
    amount: '1254',
    pipeline: 'default',
    dealstage: 'appointmentscheduled',
    closedate: new Date('2025-11-30').getTime(),
    description: 'Vinyl window order for Wallace project. Quick turnaround materials order. Location: Summit, NJ. Source: scan@brickface.com.',
    hs_priority: 'low'
  }
];

async function importDeals() {
  try {
    console.log('\n' + '='.repeat(80));
    console.log('HUBSPOT DEAL IMPORT - Using Standard Properties');
    console.log('='.repeat(80) + '\n');
    console.log(`Importing ${deals.length} deals to HubSpot CRM...\n`);

    const createdDeals = [];

    for (let i = 0; i < deals.length; i++) {
      const deal = deals[i];
      console.log(`\n[${i + 1}/${deals.length}] ${deal.dealname}`);
      console.log(`  Amount: $${Number(deal.amount).toLocaleString()}`);
      console.log(`  Priority: ${deal.hs_priority}`);

      try {
        const response = await hubspotClient.post('/crm/v3/objects/deals', {
          properties: deal
        });

        console.log(`  ✓ Created successfully`);
        console.log(`  ✓ Deal ID: ${response.data.id}`);
        console.log(`  ✓ View: https://app.hubspot.com/contacts/50101406/deal/${response.data.id}`);

        createdDeals.push({
          id: response.data.id,
          name: deal.dealname,
          amount: Number(deal.amount),
          priority: deal.hs_priority,
          url: `https://app.hubspot.com/contacts/50101406/deal/${response.data.id}`
        });
      } catch (error) {
        console.error(`  ✗ Failed: ${error.response?.data?.message || error.message}`);
        if (error.response?.data?.validationResults) {
          console.error(`  Details:`, error.response.data.validationResults);
        }
      }

      console.log('-'.repeat(80));
    }

    // Summary
    console.log('\n' + '='.repeat(80));
    console.log('IMPORT COMPLETE');
    console.log('='.repeat(80) + '\n');
    console.log(`✓ Successfully created: ${createdDeals.length}/${deals.length} deals`);
    console.log(`✓ Total pipeline value: $${createdDeals.reduce((sum, d) => sum + d.amount, 0).toLocaleString()}`);

    const highPriority = createdDeals.filter(d => d.priority === 'HIGH').length;
    console.log(`✓ High priority deals: ${highPriority}`);

    // Save results
    fs.writeFileSync(
      'hubspot-deals-imported.json',
      JSON.stringify(createdDeals, null, 2)
    );
    console.log(`\n✓ Deal details saved to: hubspot-deals-imported.json\n`);

    // Show URLs
    if (createdDeals.length > 0) {
      console.log('\nDIRECT LINKS TO DEALS IN HUBSPOT:\n');
      createdDeals.forEach((d, idx) => {
        console.log(`${idx + 1}. ${d.name}`);
        console.log(`   ${d.url}\n`);
      });
    }

    return createdDeals;
  } catch (error) {
    console.error('\n❌ ERROR:', error.message);
    throw error;
  }
}

// Execute
importDeals()
  .then(deals => {
    console.log(`\n🎉 SUCCESS! ${deals.length} deals imported to HubSpot CRM\n`);
    process.exit(0);
  })
  .catch(error => {
    console.error('\n💥 FAILED\n');
    process.exit(1);
  });
