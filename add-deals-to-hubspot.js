const axios = require('axios');

const HUBSPOT_TOKEN = 'pat-na1-f7742f9c-b5fb-49f2-8bf7-745ac72c8fe2';

const hubspotClient = axios.create({
  baseURL: 'https://api.hubapi.com',
  headers: {
    'Authorization': `Bearer ${HUBSPOT_TOKEN}`,
    'Content-Type': 'application/json',
  },
});

// Deals extracted from Gmail attachments (Nov 4-5, 2025)
const deals = [
  {
    dealname: 'Gotham Waterproofing - 55 Spruce St, Newark',
    amount: 29560,
    pipeline: 'default',
    dealstage: 'appointmentscheduled',
    closedate: new Date('2025-11-04').getTime(),
    description: 'Waterproofing, caulking, and sealer work at 55 Spruce St, Newark, NJ',
    source: 'scan@brickface.com email',
    company_name: 'Gotham Waterproofing',
    address: '55 Spruce St, Newark, NJ'
  },
  {
    dealname: 'Gotham Waterproofing - 59 Spruce St, Newark',
    amount: 7000,
    pipeline: 'default',
    dealstage: 'appointmentscheduled',
    closedate: new Date('2025-11-04').getTime(),
    description: 'Rear wall waterproofing at 59 Spruce St, Newark, NJ',
    source: 'scan@brickface.com email',
    company_name: 'Gotham Waterproofing',
    address: '59 Spruce St, Newark, NJ'
  },
  {
    dealname: 'Anchor Stone - 20 Forest St, Montclair',
    amount: 10500,
    pipeline: 'default',
    dealstage: 'appointmentscheduled',
    closedate: new Date('2025-11-04').getTime(),
    description: 'Foundation repair work at 20 Forest St, Montclair, NJ',
    source: 'scan@brickface.com email',
    company_name: 'Anchor Stone',
    address: '20 Forest St, Montclair, NJ'
  },
  {
    dealname: 'Gotham Waterproofing - The Highlands Apartments',
    amount: 23630,
    pipeline: 'default',
    dealstage: 'appointmentscheduled',
    closedate: new Date('2025-11-04').getTime(),
    description: 'Parking garage drain, deck repairs, balcony coatings at 40 E Hanover Ave, Morris Plains, NJ',
    source: 'scan@brickface.com email',
    company_name: 'Gotham Waterproofing',
    address: '40 E Hanover Ave, Morris Plains, NJ'
  },
  {
    dealname: 'Garden State Brickface - 59 Skillman Ave, Jersey City',
    amount: 98950,
    pipeline: 'default',
    dealstage: 'appointmentscheduled',
    closedate: new Date('2025-11-04').getTime(),
    description: 'Masonry restoration and painting at 59 Skillman Ave, Jersey City, NJ',
    source: 'scan@brickface.com email',
    company_name: 'Garden State Brickface',
    address: '59 Skillman Ave, Jersey City, NJ'
  },
  {
    dealname: 'Gotham Waterproofing - 300 Bunn Drive, Princeton',
    amount: 10950,
    pipeline: 'default',
    dealstage: 'appointmentscheduled',
    closedate: new Date('2025-11-04').getTime(),
    description: 'Window waterproofing at Units A-203 and D-403, 300 Bunn Drive, Princeton, NJ',
    source: 'scan@brickface.com email',
    company_name: 'Gotham Waterproofing',
    address: '300 Bunn Drive, Princeton, NJ'
  },
  {
    dealname: 'Garden State Brickface - 201 Wescott Drive, Rahway',
    amount: 50000,
    pipeline: 'default',
    dealstage: 'appointmentscheduled',
    closedate: new Date('2025-11-05').getTime(),
    description: 'Large stucco/siding project at 201 Wescott Drive, Rahway, NJ',
    source: 'scan@brickface.com email',
    company_name: 'Garden State Brickface',
    address: '201 Wescott Drive, Rahway, NJ'
  },
  {
    dealname: 'Garden State Commercial - Wallace Vinyl Windows',
    amount: 1254,
    pipeline: 'default',
    dealstage: 'appointmentscheduled',
    closedate: new Date('2025-11-05').getTime(),
    description: 'Vinyl window order for Wallace project in Summit, NJ',
    source: 'scan@brickface.com email',
    company_name: 'Garden State Commercial',
    address: 'Summit, NJ'
  }
];

async function addDealsToHubSpot() {
  try {
    console.log(`\nAdding ${deals.length} deals to HubSpot...\n`);
    console.log('='.repeat(80));

    const createdDeals = [];

    for (let i = 0; i < deals.length; i++) {
      const deal = deals[i];
      console.log(`\n[${i + 1}/${deals.length}] Creating deal: ${deal.dealname}`);
      console.log(`  Amount: $${deal.amount.toLocaleString()}`);
      console.log(`  Company: ${deal.company_name}`);

      try {
        const response = await hubspotClient.post('/crm/v3/objects/deals', {
          properties: deal
        });

        console.log(`  ✓ Created successfully (ID: ${response.data.id})`);
        createdDeals.push({
          id: response.data.id,
          name: deal.dealname,
          amount: deal.amount
        });
      } catch (error) {
        console.error(`  ✗ Failed to create deal: ${error.response?.data?.message || error.message}`);
        if (error.response?.data) {
          console.error(`  Error details:`, JSON.stringify(error.response.data, null, 2));
        }
      }

      console.log('-'.repeat(80));
    }

    console.log(`\n\n✓ Deal creation complete!`);
    console.log(`  Successfully created: ${createdDeals.length}/${deals.length} deals`);
    console.log(`  Total deal value: $${createdDeals.reduce((sum, d) => sum + d.amount, 0).toLocaleString()}`);

    // Save created deals info
    const fs = require('fs');
    fs.writeFileSync(
      'hubspot-deals-created.json',
      JSON.stringify(createdDeals, null, 2)
    );
    console.log(`  Details saved to: hubspot-deals-created.json`);

    return createdDeals;
  } catch (error) {
    console.error('Error adding deals to HubSpot:', error.message);
    if (error.response) {
      console.error('Response data:', error.response.data);
    }
    throw error;
  }
}

// Run the script
addDealsToHubSpot()
  .then(deals => {
    console.log(`\n\nSuccess! Created ${deals.length} deals in HubSpot`);
    process.exit(0);
  })
  .catch(error => {
    console.error('\nFailed to add deals to HubSpot:', error);
    process.exit(1);
  });
