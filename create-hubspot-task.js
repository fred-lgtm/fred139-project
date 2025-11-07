const axios = require('axios');

const HUBSPOT_TOKEN = 'pat-na1-4c42c535-589e-4181-ba6a-df359d4c278d';

const hubspotClient = axios.create({
  baseURL: 'https://api.hubapi.com',
  headers: {
    'Authorization': `Bearer ${HUBSPOT_TOKEN}`,
    'Content-Type': 'application/json',
  },
});

async function findOwnerByName(name) {
  try {
    const response = await hubspotClient.get('/crm/v3/owners');
    const owner = response.data.results.find(o =>
      o.firstName?.toLowerCase().includes(name.toLowerCase()) ||
      o.lastName?.toLowerCase().includes(name.toLowerCase()) ||
      o.email?.toLowerCase().includes(name.toLowerCase())
    );
    return owner ? owner.id : null;
  } catch (error) {
    console.error('Error finding owner:', error.message);
    return null;
  }
}

async function createDistributeDealsTask() {
  try {
    console.log('\n='.repeat(80));
    console.log('CREATING HUBSPOT TASK: "Distribute deals"');
    console.log('='.repeat(80) + '\n');

    // Find Frederick's owner ID
    console.log('Searching for Frederick in HubSpot owners...');
    const ownerId = await findOwnerByName('frederick');

    if (!ownerId) {
      console.log('⚠ Frederick not found, searching for fred@brickface.com...');
      const fredId = await findOwnerByName('fred@brickface.com');

      if (!fredId) {
        console.error('✗ Could not find Frederick or fred@brickface.com in HubSpot owners');
        console.log('\nAvailable owners:');
        const owners = await hubspotClient.get('/crm/v3/owners');
        owners.data.results.forEach(o => {
          console.log(`  - ${o.firstName} ${o.lastName} (${o.email}) - ID: ${o.id}`);
        });
        throw new Error('Owner not found');
      }

      console.log(`✓ Found owner ID: ${fredId}`);

      // Create task
      const dueDate = new Date();
      dueDate.setDate(dueDate.getDate() + 1); // Due tomorrow

      const taskData = {
        properties: {
          hs_task_subject: 'Distribute deals',
          hs_task_body: 'Distribute the 8 new deals from scan@brickface.com (Nov 4-5) to appropriate sales team members. Deals have been enriched with AI insights including win probability and recommended actions.',
          hs_task_status: 'NOT_STARTED',
          hs_task_priority: 'HIGH',
          hubspot_owner_id: fredId,
          hs_timestamp: dueDate.getTime()
        }
      };

      const response = await hubspotClient.post('/crm/v3/objects/tasks', taskData);

      console.log('\n✓ Task created successfully!');
      console.log(`  Task ID: ${response.data.id}`);
      console.log(`  Subject: Distribute deals`);
      console.log(`  Assigned to: fred@brickface.com (ID: ${fredId})`);
      console.log(`  Priority: HIGH`);
      console.log(`  Due: ${dueDate.toLocaleDateString()}`);
      console.log('='.repeat(80) + '\n');

      return response.data;
    }

    console.log(`✓ Found Frederick - Owner ID: ${ownerId}`);

    // Create task
    const dueDate = new Date();
    dueDate.setDate(dueDate.getDate() + 1); // Due tomorrow

    const taskData = {
      properties: {
        hs_task_subject: 'Distribute deals',
        hs_task_body: 'Distribute the 8 new deals from scan@brickface.com (Nov 4-5) to appropriate sales team members. Deals have been enriched with AI insights including win probability and recommended actions.',
        hs_task_status: 'NOT_STARTED',
        hs_task_priority: 'HIGH',
        hubspot_owner_id: ownerId,
        hs_timestamp: dueDate.getTime()
      }
    };

    const response = await hubspotClient.post('/crm/v3/objects/tasks', taskData);

    console.log('\n✓ Task created successfully!');
    console.log(`  Task ID: ${response.data.id}`);
    console.log(`  Subject: Distribute deals`);
    console.log(`  Assigned to: Frederick (ID: ${ownerId})`);
    console.log(`  Priority: HIGH`);
    console.log(`  Due: ${dueDate.toLocaleDateString()}`);
    console.log('='.repeat(80) + '\n');

    return response.data;
  } catch (error) {
    console.error('\n❌ Error creating task:', error.response?.data || error.message);
    throw error;
  }
}

createDistributeDealsTask()
  .then(() => {
    console.log('🎉 SUCCESS!\n');
    process.exit(0);
  })
  .catch(error => {
    console.error('💥 FAILED\n');
    process.exit(1);
  });
