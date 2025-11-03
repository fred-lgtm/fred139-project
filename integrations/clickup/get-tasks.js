require('dotenv').config();
const { makeRequest } = require('./api-client');

async function getTasks() {
  console.log('📋 Fetching ClickUp tasks...\n');

  try {
    const listId = process.env.CLICKUP_LIST_ID;

    if (!listId) {
      console.error('❌ CLICKUP_LIST_ID not found in .env');
      console.log('ℹ️  Get your list ID from ClickUp settings');
      process.exit(1);
    }

    const response = await makeRequest(`/list/${listId}/task`);

    console.log(`✅ Retrieved ${response.tasks.length} tasks\n`);

    response.tasks.forEach((task, index) => {
      console.log(`${index + 1}. ${task.name}`);
      console.log(`   Status: ${task.status.status}`);
      console.log(`   Assignees: ${task.assignees.map(a => a.username).join(', ') || 'None'}`);
      console.log(`   Due: ${task.due_date ? new Date(parseInt(task.due_date)).toLocaleDateString() : 'No due date'}`);
      console.log('');
    });
  } catch (error) {
    console.error('❌ Error:', error.message);
  }
}

getTasks();