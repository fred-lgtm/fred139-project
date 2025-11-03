#!/usr/bin/env node
/**
 * ClickUp → Dendron Workspace Sync
 *
 * Syncs ClickUp tasks and projects to Dendron notes for unified knowledge management
 * Run: node clickup-sync.js
 */

require('dotenv').config({ path: '../../.env' });
const https = require('https');
const fs = require('fs');
const path = require('path');

// ClickUp API Configuration
const CLICKUP_API_TOKEN = process.env.CLICKUP_API_TOKEN || '';
const TEAM_ID = process.env.CLICKUP_TEAM_ID || '';

// Dendron paths
const DENDRON_ROOT = path.join(__dirname, '../..');
const PROJECTS_DIR = path.join(DENDRON_ROOT, 'projects');
const TASKS_DIR = path.join(DENDRON_ROOT, 'tasks');

// Ensure directories exist
[PROJECTS_DIR, TASKS_DIR].forEach(dir => {
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }
});

/**
 * Make ClickUp API request
 */
function makeClickUpRequest(endpoint) {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: 'api.clickup.com',
      path: `/api/v2${endpoint}`,
      method: 'GET',
      headers: {
        'Authorization': CLICKUP_API_TOKEN,
        'Content-Type': 'application/json'
      }
    };

    const req = https.request(options, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        if (res.statusCode >= 200 && res.statusCode < 300) {
          resolve(JSON.parse(data));
        } else {
          reject(new Error(`ClickUp API error: ${res.statusCode} - ${data}`));
        }
      });
    });

    req.on('error', reject);
    req.end();
  });
}

/**
 * Convert ClickUp task to Dendron note
 */
function taskToDendronNote(task, listName, folderName) {
  const id = `tasks.clickup-${task.id}`;
  const title = task.name;
  const status = task.status.status;
  const priority = task.priority ? task.priority.priority : 'none';
  const assignees = task.assignees.map(a => a.username).join(', ') || 'Unassigned';
  const dueDate = task.due_date ? new Date(parseInt(task.due_date)).toISOString() : 'No due date';
  const tags = task.tags.map(t => t.name).join(', ') || 'none';
  const description = task.description || 'No description';

  const frontmatter = {
    id,
    title,
    desc: `ClickUp Task: ${task.name}`,
    updated: Date.now(),
    created: parseInt(task.date_created),
    clickup_id: task.id,
    clickup_url: task.url,
    status,
    priority,
    assignees,
    due_date: dueDate,
    tags,
    folder: folderName,
    list: listName
  };

  let markdown = `---\n`;
  for (const [key, value] of Object.entries(frontmatter)) {
    if (typeof value === 'string' && value.includes('\n')) {
      markdown += `${key}: |\n  ${value.replace(/\n/g, '\n  ')}\n`;
    } else {
      markdown += `${key}: ${value}\n`;
    }
  }
  markdown += `---\n\n`;
  markdown += `# ${title}\n\n`;
  markdown += `**Status:** ${status} | **Priority:** ${priority} | **Assignees:** ${assignees}\n\n`;
  markdown += `**Due Date:** ${dueDate}\n\n`;
  if (tags !== 'none') {
    markdown += `**Tags:** ${tags}\n\n`;
  }
  markdown += `[View in ClickUp](${task.url})\n\n`;
  markdown += `## Description\n\n${description}\n\n`;

  if (task.custom_fields && task.custom_fields.length > 0) {
    markdown += `## Custom Fields\n\n`;
    task.custom_fields.forEach(field => {
      markdown += `- **${field.name}:** ${field.value || 'N/A'}\n`;
    });
    markdown += `\n`;
  }

  markdown += `## Activity\n\n`;
  markdown += `- Created: ${new Date(parseInt(task.date_created)).toLocaleString()}\n`;
  markdown += `- Updated: ${new Date(parseInt(task.date_updated)).toLocaleString()}\n`;

  return { filename: `${id}.md`, content: markdown };
}

/**
 * Convert ClickUp list to Dendron project note
 */
function listToDendronNote(list, folderName, tasks) {
  const id = `projects.clickup-list-${list.id}`;
  const title = `${folderName} - ${list.name}`;

  const frontmatter = {
    id,
    title,
    desc: `ClickUp List: ${list.name}`,
    updated: Date.now(),
    created: Date.now(),
    clickup_id: list.id,
    folder: folderName,
    task_count: list.task_count || 0
  };

  let markdown = `---\n`;
  for (const [key, value] of Object.entries(frontmatter)) {
    markdown += `${key}: ${value}\n`;
  }
  markdown += `---\n\n`;
  markdown += `# ${title}\n\n`;
  markdown += `**Total Tasks:** ${list.task_count || 0}\n\n`;

  // Group tasks by status
  const tasksByStatus = {};
  tasks.forEach(task => {
    const status = task.status.status;
    if (!tasksByStatus[status]) {
      tasksByStatus[status] = [];
    }
    tasksByStatus[status].push(task);
  });

  markdown += `## Tasks by Status\n\n`;
  for (const [status, statusTasks] of Object.entries(tasksByStatus)) {
    markdown += `### ${status} (${statusTasks.length})\n\n`;
    statusTasks.forEach(task => {
      const taskId = `tasks.clickup-${task.id}`;
      const priority = task.priority ? ` [${task.priority.priority}]` : '';
      const assignees = task.assignees.length > 0 ? ` (@${task.assignees[0].username})` : '';
      markdown += `- [[${taskId}|${task.name}]]${priority}${assignees}\n`;
    });
    markdown += `\n`;
  }

  return { filename: `${id}.md`, content: markdown };
}

/**
 * Main sync function
 */
async function sync() {
  console.log('🔄 Starting ClickUp → Dendron sync...\n');

  if (!CLICKUP_API_TOKEN) {
    console.error('❌ Error: CLICKUP_API_TOKEN not found in .env file');
    console.log('\nPlease add to .env:');
    console.log('CLICKUP_API_TOKEN=pk_your_token_here');
    console.log('\nGet your API token from: https://app.clickup.com/settings/apps');
    process.exit(1);
  }

  try {
    // Get team info
    let teamId = TEAM_ID;
    if (!teamId) {
      console.log('📡 Fetching team information...');
      const teams = await makeClickUpRequest('/team');
      if (teams.teams && teams.teams.length > 0) {
        teamId = teams.teams[0].id;
        console.log(`✅ Using team: ${teams.teams[0].name} (${teamId})\n`);
      } else {
        throw new Error('No teams found');
      }
    }

    // Get spaces
    console.log('📁 Fetching spaces...');
    const spacesData = await makeClickUpRequest(`/team/${teamId}/space?archived=false`);
    const spaces = spacesData.spaces || [];
    console.log(`✅ Found ${spaces.length} spaces\n`);

    let totalTasks = 0;
    let totalLists = 0;

    // Process each space
    for (const space of spaces) {
      console.log(`📂 Processing space: ${space.name}`);

      // Get folders in space
      const foldersData = await makeClickUpRequest(`/space/${space.id}/folder?archived=false`);
      const folders = foldersData.folders || [];

      // Also get folderless lists
      const listsData = await makeClickUpRequest(`/space/${space.id}/list?archived=false`);
      const folderlessLists = listsData.lists || [];

      // Process folderless lists
      for (const list of folderlessLists) {
        console.log(`  📋 Processing list: ${list.name}`);

        // Get tasks in list
        const tasksData = await makeClickUpRequest(`/list/${list.id}/task?archived=false&include_closed=true`);
        const tasks = tasksData.tasks || [];

        console.log(`    ✅ Found ${tasks.length} tasks`);
        totalTasks += tasks.length;
        totalLists++;

        // Create task notes
        tasks.forEach(task => {
          const note = taskToDendronNote(task, list.name, space.name);
          fs.writeFileSync(path.join(TASKS_DIR, note.filename), note.content);
        });

        // Create list project note
        const listNote = listToDendronNote(list, space.name, tasks);
        fs.writeFileSync(path.join(PROJECTS_DIR, listNote.filename), listNote.content);
      }

      // Process folders
      for (const folder of folders) {
        console.log(`  📁 Processing folder: ${folder.name}`);

        // Get lists in folder
        const folderListsData = await makeClickUpRequest(`/folder/${folder.id}/list?archived=false`);
        const folderLists = folderListsData.lists || [];

        for (const list of folderLists) {
          console.log(`    📋 Processing list: ${list.name}`);

          // Get tasks in list
          const tasksData = await makeClickUpRequest(`/list/${list.id}/task?archived=false&include_closed=true`);
          const tasks = tasksData.tasks || [];

          console.log(`      ✅ Found ${tasks.length} tasks`);
          totalTasks += tasks.length;
          totalLists++;

          // Create task notes
          tasks.forEach(task => {
            const note = taskToDendronNote(task, list.name, `${space.name} / ${folder.name}`);
            fs.writeFileSync(path.join(TASKS_DIR, note.filename), note.content);
          });

          // Create list project note
          const listNote = listToDendronNote(list, `${space.name} / ${folder.name}`, tasks);
          fs.writeFileSync(path.join(PROJECTS_DIR, listNote.filename), listNote.content);
        }
      }
    }

    console.log('\n✅ Sync complete!');
    console.log(`\n📊 Summary:`);
    console.log(`   Spaces: ${spaces.length}`);
    console.log(`   Lists: ${totalLists}`);
    console.log(`   Tasks: ${totalTasks}`);
    console.log(`\n📂 Notes created in:`);
    console.log(`   Projects: ${PROJECTS_DIR}`);
    console.log(`   Tasks: ${TASKS_DIR}`);
    console.log(`\n💡 Open VS Code workspace and use Dendron to explore your ClickUp data!`);

  } catch (error) {
    console.error('❌ Sync failed:', error.message);
    if (error.message.includes('401')) {
      console.log('\n🔑 Authentication failed. Please check your CLICKUP_API_TOKEN in .env');
      console.log('Get your API token from: https://app.clickup.com/settings/apps');
    }
    process.exit(1);
  }
}

// Run sync
sync();
