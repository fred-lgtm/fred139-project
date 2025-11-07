#!/usr/bin/env node
/**
 * ClickUp Roadmap Import Script
 *
 * Imports comprehensive roadmap from clickup-roadmap-complete.json into ClickUp
 * Creates spaces, folders, lists, and tasks with full details
 *
 * Run: node import-roadmap.js
 */

require('dotenv').config({ path: '../../.env' });
const https = require('https');
const fs = require('fs');
const path = require('path');

// ClickUp API Configuration
const CLICKUP_API_KEY = process.env.CLICKUP_API_KEY || process.env.CLICKUP_TOKEN || '';
const TEAM_ID = process.env.CLICKUP_TEAM_ID || '';

// Load roadmap JSON
const ROADMAP_PATH = path.join(__dirname, '../../clickup-roadmap-complete.json');

/**
 * Make ClickUp API request
 */
function makeClickUpRequest(endpoint, method = 'GET', body = null) {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: 'api.clickup.com',
      path: `/api/v2${endpoint}`,
      method: method,
      headers: {
        'Authorization': CLICKUP_API_KEY,
        'Content-Type': 'application/json'
      }
    };

    const req = https.request(options, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        if (res.statusCode >= 200 && res.statusCode < 300) {
          try {
            resolve(JSON.parse(data));
          } catch (e) {
            resolve(data);
          }
        } else {
          reject(new Error(`ClickUp API error: ${res.statusCode} - ${data}`));
        }
      });
    });

    req.on('error', reject);

    if (body) {
      req.write(JSON.stringify(body));
    }

    req.end();
  });
}

/**
 * Convert status to ClickUp status format
 */
function mapStatus(status) {
  const statusMap = {
    'Complete': 'complete',
    'In Progress': 'in progress',
    'To Do': 'to do',
    'Blocked': 'blocked',
    'Review': 'review'
  };
  return statusMap[status] || 'to do';
}

/**
 * Convert priority to ClickUp priority value
 */
function mapPriority(priority) {
  const priorityMap = {
    'Urgent': 1,
    'High': 2,
    'Normal': 3,
    'Low': 4
  };
  return priorityMap[priority] || 3;
}

/**
 * Convert date string to Unix timestamp in milliseconds
 */
function dateToTimestamp(dateString) {
  if (!dateString) return null;
  const date = new Date(dateString);
  return date.getTime();
}

/**
 * Create a space in ClickUp
 */
async function createSpace(teamId, spaceName, description, color) {
  console.log(`  Creating space: ${spaceName}...`);

  try {
    const space = await makeClickUpRequest(`/team/${teamId}/space`, 'POST', {
      name: spaceName,
      multiple_assignees: true,
      features: {
        due_dates: { enabled: true, start_date: true, remap_due_dates: true, remap_closed_due_date: false },
        time_tracking: { enabled: true },
        tags: { enabled: true },
        time_estimates: { enabled: true },
        checklists: { enabled: true },
        custom_fields: { enabled: true },
        remap_dependencies: { enabled: true },
        dependency_warning: { enabled: true },
        portfolios: { enabled: true }
      }
    });

    console.log(`    ✅ Space created: ${space.id}`);
    return space;
  } catch (error) {
    console.error(`    ❌ Failed to create space: ${error.message}`);
    throw error;
  }
}

/**
 * Create a list in ClickUp (directly in space, no folder)
 */
async function createList(spaceId, listName, description) {
  console.log(`    Creating list: ${listName}...`);

  try {
    const list = await makeClickUpRequest(`/space/${spaceId}/list`, 'POST', {
      name: listName,
      content: description || '',
      priority: null,
      status: null
    });

    console.log(`      ✅ List created: ${list.id}`);
    return list;
  } catch (error) {
    console.error(`      ❌ Failed to create list: ${error.message}`);
    throw error;
  }
}

/**
 * Create a task in ClickUp
 */
async function createTask(listId, task) {
  console.log(`      Creating task: ${task.name}...`);

  try {
    const taskData = {
      name: task.name,
      description: task.description || '',
      status: mapStatus(task.status),
      priority: mapPriority(task.priority),
      due_date: dateToTimestamp(task.due_date),
      start_date: dateToTimestamp(task.start_date),
      tags: task.tags || [],
      assignees: [] // We'll use generic assignees since we don't have user IDs
    };

    // Add custom fields if provided
    if (task.custom_fields) {
      taskData.custom_fields = [];

      if (task.custom_fields.effort_hours) {
        taskData.custom_fields.push({
          id: 'effort_hours',
          value: task.custom_fields.effort_hours
        });
      }

      if (task.custom_fields.business_value) {
        taskData.custom_fields.push({
          id: 'business_value',
          value: task.custom_fields.business_value
        });
      }
    }

    const createdTask = await makeClickUpRequest(`/list/${listId}/task`, 'POST', taskData);

    console.log(`        ✅ Task created: ${createdTask.id}`);

    // Create subtasks if provided
    if (task.subtasks && task.subtasks.length > 0) {
      console.log(`        Creating ${task.subtasks.length} subtasks...`);

      for (const subtask of task.subtasks) {
        try {
          await makeClickUpRequest(`/task/${createdTask.id}/checklist`, 'POST', {
            name: 'Subtasks'
          }).then(async (checklist) => {
            await makeClickUpRequest(`/checklist/${checklist.id}/checklist_item`, 'POST', {
              name: subtask.name,
              resolved: subtask.status === 'Complete'
            });
          }).catch(async (err) => {
            // Checklist might already exist, try to get it
            const taskDetails = await makeClickUpRequest(`/task/${createdTask.id}`);
            if (taskDetails.checklists && taskDetails.checklists.length > 0) {
              const checklist = taskDetails.checklists[0];
              await makeClickUpRequest(`/checklist/${checklist.id}/checklist_item`, 'POST', {
                name: subtask.name,
                resolved: subtask.status === 'Complete'
              });
            }
          });
        } catch (subtaskError) {
          console.error(`          ⚠️ Failed to create subtask: ${subtaskError.message}`);
        }
      }

      console.log(`        ✅ Subtasks created`);
    }

    return createdTask;
  } catch (error) {
    console.error(`        ❌ Failed to create task: ${error.message}`);
    throw error;
  }
}

/**
 * Main import function
 */
async function importRoadmap() {
  console.log('🚀 Starting ClickUp Roadmap Import...\n');
  console.log('📋 This will create:');
  console.log('   - Multiple Spaces for different work areas');
  console.log('   - Lists organized by functionality');
  console.log('   - 66 Tasks with full details, priorities, and subtasks');
  console.log('   - Custom fields for effort tracking and business value\n');

  if (!CLICKUP_API_KEY) {
    console.error('❌ Error: CLICKUP_API_KEY not found in .env file');
    console.log('\nPlease ensure .env contains:');
    console.log('CLICKUP_API_KEY=pk_your_token_here');
    process.exit(1);
  }

  // Load roadmap
  console.log('📂 Loading roadmap JSON...');
  let roadmap;
  try {
    const roadmapContent = fs.readFileSync(ROADMAP_PATH, 'utf8');
    roadmap = JSON.parse(roadmapContent);
    console.log(`✅ Roadmap loaded: ${roadmap.workspace.name}\n`);
  } catch (error) {
    console.error(`❌ Failed to load roadmap: ${error.message}`);
    process.exit(1);
  }

  try {
    // Use existing Brickface workspace
    const teamId = '90131096188'; // Brickface workspace
    console.log(`✅ Using existing Brickface workspace (${teamId})\n`);

    // Import statistics
    let stats = {
      spaces: 0,
      lists: 0,
      tasks: 0,
      subtasks: 0
    };

    // Process each space
    console.log(`🏗️  Creating ${roadmap.spaces.length} spaces...\n`);

    for (const spaceData of roadmap.spaces) {
      const space = await createSpace(teamId, spaceData.name, spaceData.description, spaceData.color);
      stats.spaces++;

      // Process each list in the space
      console.log(`\n  📋 Creating ${spaceData.lists.length} lists in ${spaceData.name}...\n`);

      for (const listData of spaceData.lists) {
        const list = await createList(space.id, listData.name, listData.description);
        stats.lists++;

        // Process each task in the list
        console.log(`\n    ⚡ Creating ${listData.tasks.length} tasks in ${listData.name}...\n`);

        for (const taskData of listData.tasks) {
          await createTask(list.id, taskData);
          stats.tasks++;

          if (taskData.subtasks) {
            stats.subtasks += taskData.subtasks.length;
          }

          // Rate limiting - wait 100ms between tasks
          await new Promise(resolve => setTimeout(resolve, 100));
        }
      }

      // Wait between spaces to avoid rate limiting
      await new Promise(resolve => setTimeout(resolve, 500));
    }

    console.log('\n\n✅ ========================================');
    console.log('✅ ROADMAP IMPORT COMPLETE!');
    console.log('✅ ========================================\n');

    console.log('📊 Import Summary:');
    console.log(`   ✅ Spaces Created: ${stats.spaces}`);
    console.log(`   ✅ Lists Created: ${stats.lists}`);
    console.log(`   ✅ Tasks Created: ${stats.tasks}`);
    console.log(`   ✅ Subtasks Created: ${stats.subtasks}`);

    console.log('\n🔗 Access your ClickUp workspace at:');
    console.log(`   https://app.clickup.com/${teamId}\n`);

    console.log('💡 Next Steps:');
    console.log('   1. Open ClickUp and navigate to your workspace');
    console.log('   2. Review the newly created spaces and lists');
    console.log('   3. Assign tasks to team members');
    console.log('   4. Customize statuses and priorities as needed');
    console.log('   5. Set up automations and integrations\n');

    // Save workspace URL to file
    const workspaceUrl = `https://app.clickup.com/${teamId}`;
    fs.writeFileSync(
      path.join(__dirname, '../../CLICKUP-WORKSPACE-URL.txt'),
      `Brickface Enterprise Development Workspace\n\nWorkspace URL: ${workspaceUrl}\n\nCreated: ${new Date().toISOString()}\n\nSpaces: ${stats.spaces}\nLists: ${stats.lists}\nTasks: ${stats.tasks}\nSubtasks: ${stats.subtasks}\n`
    );

    console.log('📝 Workspace URL saved to: CLICKUP-WORKSPACE-URL.txt\n');

  } catch (error) {
    console.error('\n❌ Import failed:', error.message);
    if (error.message.includes('401')) {
      console.log('\n🔑 Authentication failed. Please check your CLICKUP_API_KEY in .env');
    }
    process.exit(1);
  }
}

// Run import
importRoadmap();
