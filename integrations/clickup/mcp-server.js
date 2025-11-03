#!/usr/bin/env node

/**
 * ClickUp MCP Server
 * Provides ClickUp project management integration for Claude AI
 * Automatically creates tasks and subtasks for VS Code workflows
 */

const { Server } = require('@modelcontextprotocol/sdk/server/index.js');
const { StdioServerTransport } = require('@modelcontextprotocol/sdk/server/stdio.js');
const {
    CallToolRequestSchema,
    ListToolsRequestSchema,
} = require('@modelcontextprotocol/sdk/types.js');
const axios = require('axios');

class ClickUpMCPServer {
    constructor() {
        this.server = new Server(
            {
                name: 'clickup-mcp',
                version: '0.1.0',
            },
            {
                capabilities: {
                    tools: {},
                },
            }
        );

        this.clickupClient = axios.create({
            baseURL: 'https://api.clickup.com/api/v2',
            headers: {
                'Authorization': process.env.CLICKUP_API_TOKEN,
                'Content-Type': 'application/json',
            },
        });

        this.setupToolHandlers();
    }

    setupToolHandlers() {
        this.server.setRequestHandler(ListToolsRequestSchema, async () => ({
            tools: [
                {
                    name: 'create_dev_task',
                    description: 'Create a development task in ClickUp for VS Code workflows',
                    inputSchema: {
                        type: 'object',
                        properties: {
                            name: { type: 'string', description: 'Task name' },
                            description: { type: 'string', description: 'Task description' },
                            priority: { type: 'number', description: 'Priority (1=urgent, 2=high, 3=normal, 4=low)' },
                            assignees: { type: 'array', items: { type: 'string' }, description: 'User IDs to assign' },
                            tags: { type: 'array', items: { type: 'string' }, description: 'Task tags' },
                            subtasks: {
                                type: 'array',
                                items: {
                                    type: 'object',
                                    properties: {
                                        name: { type: 'string' },
                                        description: { type: 'string' }
                                    }
                                },
                                description: 'Subtasks to create'
                            }
                        },
                        required: ['name']
                    },
                },
                {
                    name: 'get_tasks',
                    description: 'Get tasks from the VS Code workflows space',
                    inputSchema: {
                        type: 'object',
                        properties: {
                            status: { type: 'string', description: 'Task status filter' },
                            assignee: { type: 'string', description: 'Assignee filter' },
                            limit: { type: 'number', default: 10 }
                        },
                    },
                },
                {
                    name: 'update_task_status',
                    description: 'Update task status (e.g., in progress, complete)',
                    inputSchema: {
                        type: 'object',
                        properties: {
                            task_id: { type: 'string', description: 'ClickUp task ID' },
                            status: { type: 'string', description: 'New status' },
                        },
                        required: ['task_id', 'status']
                    },
                },
                {
                    name: 'create_workflow_automation',
                    description: 'Create automated workflow tasks based on VS Code activity',
                    inputSchema: {
                        type: 'object',
                        properties: {
                            workflow_type: {
                                type: 'string',
                                enum: ['code_review', 'feature_development', 'bug_fix', 'deployment'],
                                description: 'Type of workflow'
                            },
                            project_name: { type: 'string', description: 'Project name' },
                            files_changed: { type: 'array', items: { type: 'string' }, description: 'Files modified' },
                            commit_message: { type: 'string', description: 'Git commit message' }
                        },
                        required: ['workflow_type', 'project_name']
                    },
                },
                {
                    name: 'get_team_workload',
                    description: 'Get team workload and capacity in the development space',
                    inputSchema: {
                        type: 'object',
                        properties: {
                            team_id: { type: 'string', description: 'Team ID' }
                        }
                    },
                }
            ],
        }));

        this.server.setRequestHandler(CallToolRequestSchema, async (request) => {
            const { name, arguments: args } = request.params;

            try {
                switch (name) {
                    case 'create_dev_task':
                        return await this.createDevTask(args);
                    case 'get_tasks':
                        return await this.getTasks(args);
                    case 'update_task_status':
                        return await this.updateTaskStatus(args);
                    case 'create_workflow_automation':
                        return await this.createWorkflowAutomation(args);
                    case 'get_team_workload':
                        return await this.getTeamWorkload(args);
                    default:
                        throw new Error(`Unknown tool: ${name}`);
                }
            } catch (error) {
                return {
                    content: [{
                        type: 'text',
                        text: `Error: ${error.message}`,
                    }],
                    isError: true,
                };
            }
        });
    }

    async createDevTask(args) {
        const taskData = {
            name: args.name,
            description: args.description,
            priority: args.priority || 3,
            assignees: args.assignees || [],
            tags: [...(args.tags || []), 'vscode-workflow', 'development'],
        };

        const response = await this.clickupClient.post(
            `/list/${process.env.CLICKUP_LIST_ID}/task`,
            taskData
        );

        const taskId = response.data.id;

        // Create subtasks if provided
        if (args.subtasks && args.subtasks.length > 0) {
            for (const subtask of args.subtasks) {
                await this.clickupClient.post(`/task/${taskId}/subtask`, {
                    name: subtask.name,
                    description: subtask.description,
                });
            }
        }

        return {
            content: [{
                type: 'text',
                text: `Development task created successfully: ${JSON.stringify(response.data, null, 2)}`,
            }],
        };
    }

    async getTasks(args) {
        const params = {
            include_closed: false,
            page: 0,
            limit: args.limit || 10,
        };

        if (args.status) params.statuses = [args.status];
        if (args.assignee) params.assignees = [args.assignee];

        const response = await this.clickupClient.get(
            `/list/${process.env.CLICKUP_LIST_ID}/task`,
            { params }
        );

        return {
            content: [{
                type: 'text',
                text: JSON.stringify(response.data, null, 2),
            }],
        };
    }

    async updateTaskStatus(args) {
        const response = await this.clickupClient.put(`/task/${args.task_id}`, {
            status: args.status,
        });

        return {
            content: [{
                type: 'text',
                text: `Task status updated: ${JSON.stringify(response.data, null, 2)}`,
            }],
        };
    }

    async createWorkflowAutomation(args) {
        const workflowTemplates = {
            code_review: {
                name: `Code Review: ${args.project_name}`,
                description: `Review code changes in ${args.project_name}\nFiles: ${args.files_changed?.join(', ') || 'Multiple files'}\nCommit: ${args.commit_message || 'No message'}`,
                subtasks: [
                    { name: 'Review code changes', description: 'Check for code quality and best practices' },
                    { name: 'Test functionality', description: 'Verify changes work as expected' },
                    { name: 'Approve/Request changes', description: 'Provide feedback or approval' }
                ]
            },
            feature_development: {
                name: `Feature: ${args.project_name}`,
                description: `Develop new feature for ${args.project_name}`,
                subtasks: [
                    { name: 'Design implementation', description: 'Plan the feature architecture' },
                    { name: 'Implement core functionality', description: 'Write the main feature code' },
                    { name: 'Add tests', description: 'Create unit and integration tests' },
                    { name: 'Documentation', description: 'Update docs and README' }
                ]
            },
            bug_fix: {
                name: `Bug Fix: ${args.project_name}`,
                description: `Fix bug in ${args.project_name}\nFiles affected: ${args.files_changed?.join(', ') || 'Multiple files'}`,
                subtasks: [
                    { name: 'Reproduce issue', description: 'Confirm and understand the bug' },
                    { name: 'Implement fix', description: 'Write code to resolve the issue' },
                    { name: 'Test fix', description: 'Verify the bug is resolved' },
                    { name: 'Regression testing', description: 'Ensure no new issues introduced' }
                ]
            },
            deployment: {
                name: `Deploy: ${args.project_name}`,
                description: `Deploy ${args.project_name} to production`,
                subtasks: [
                    { name: 'Pre-deployment checks', description: 'Verify all tests pass' },
                    { name: 'Deploy to staging', description: 'Deploy and test in staging environment' },
                    { name: 'Deploy to production', description: 'Execute production deployment' },
                    { name: 'Post-deployment monitoring', description: 'Monitor system health after deployment' }
                ]
            }
        };

        const template = workflowTemplates[args.workflow_type];
        if (!template) {
            throw new Error(`Unknown workflow type: ${args.workflow_type}`);
        }

        return await this.createDevTask({
            name: template.name,
            description: template.description,
            tags: [args.workflow_type, 'automated-workflow'],
            subtasks: template.subtasks
        });
    }

    async getTeamWorkload(args) {
        const response = await this.clickupClient.get(
            `/team/${process.env.CLICKUP_TEAM_ID}/task`,
            {
                params: {
                    include_closed: false,
                    statuses: ['open', 'in progress', 'review'],
                }
            }
        );

        // Analyze workload by assignee
        const workload = {};
        response.data.tasks.forEach(task => {
            task.assignees.forEach(assignee => {
                if (!workload[assignee.username]) {
                    workload[assignee.username] = { tasks: 0, high_priority: 0 };
                }
                workload[assignee.username].tasks++;
                if (task.priority && task.priority.priority <= 2) {
                    workload[assignee.username].high_priority++;
                }
            });
        });

        return {
            content: [{
                type: 'text',
                text: `Team workload analysis:\n${JSON.stringify(workload, null, 2)}`,
            }],
        };
    }

    async run() {
        const transport = new StdioServerTransport();
        await this.server.connect(transport);
        console.error('ClickUp MCP server running on stdio');
    }
}

const server = new ClickUpMCPServer();
server.run().catch(console.error);