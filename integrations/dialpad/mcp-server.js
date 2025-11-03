#!/usr/bin/env node

/**
 * Dialpad MCP Server
 * Provides Dialpad communication integration for Claude AI
 */

const { Server } = require('@modelcontextprotocol/sdk/server/index.js');
const { StdioServerTransport } = require('@modelcontextprotocol/sdk/server/stdio.js');
const {
    CallToolRequestSchema,
    ListToolsRequestSchema,
} = require('@modelcontextprotocol/sdk/types.js');
const axios = require('axios');

class DialpadMCPServer {
    constructor() {
        this.server = new Server(
            {
                name: 'dialpad-mcp',
                version: '0.1.0',
            },
            {
                capabilities: {
                    tools: {},
                },
            }
        );

        this.dialpadClient = axios.create({
            baseURL: process.env.DIALPAD_API_URL || 'https://dialpad.com/api/v2',
            headers: {
                'Authorization': `Bearer ${process.env.DIALPAD_API_KEY}`,
                'Content-Type': 'application/json',
            },
        });

        this.setupToolHandlers();
    }

    setupToolHandlers() {
        this.server.setRequestHandler(ListToolsRequestSchema, async () => ({
            tools: [
                {
                    name: 'get_call_history',
                    description: 'Get recent call history from Dialpad',
                    inputSchema: {
                        type: 'object',
                        properties: {
                            limit: { type: 'number', default: 10, description: 'Number of calls to retrieve' },
                            start_time: { type: 'string', description: 'Start time filter (ISO 8601)' },
                            end_time: { type: 'string', description: 'End time filter (ISO 8601)' },
                            direction: {
                                type: 'string',
                                enum: ['inbound', 'outbound'],
                                description: 'Call direction filter'
                            }
                        },
                    },
                },
                {
                    name: 'get_contacts',
                    description: 'Get contacts from Dialpad directory',
                    inputSchema: {
                        type: 'object',
                        properties: {
                            search: { type: 'string', description: 'Search term for contact name or phone' },
                            limit: { type: 'number', default: 10 }
                        },
                    },
                },
                {
                    name: 'make_call',
                    description: 'Initiate a call through Dialpad',
                    inputSchema: {
                        type: 'object',
                        properties: {
                            to_number: { type: 'string', description: 'Phone number to call' },
                            from_number: { type: 'string', description: 'Caller ID number' },
                            auto_answer: { type: 'boolean', default: false }
                        },
                        required: ['to_number']
                    },
                },
                {
                    name: 'send_sms',
                    description: 'Send SMS message via Dialpad',
                    inputSchema: {
                        type: 'object',
                        properties: {
                            to_number: { type: 'string', description: 'Recipient phone number' },
                            message: { type: 'string', description: 'SMS message content' },
                            from_number: { type: 'string', description: 'Sender phone number' }
                        },
                        required: ['to_number', 'message']
                    },
                },
                {
                    name: 'get_voicemails',
                    description: 'Get voicemail messages',
                    inputSchema: {
                        type: 'object',
                        properties: {
                            unread_only: { type: 'boolean', default: true },
                            limit: { type: 'number', default: 10 }
                        },
                    },
                },
                {
                    name: 'get_call_recordings',
                    description: 'Get call recordings with metadata',
                    inputSchema: {
                        type: 'object',
                        properties: {
                            call_id: { type: 'string', description: 'Specific call ID' },
                            start_time: { type: 'string', description: 'Start time filter' },
                            limit: { type: 'number', default: 10 }
                        },
                    },
                },
                {
                    name: 'create_contact',
                    description: 'Create a new contact in Dialpad',
                    inputSchema: {
                        type: 'object',
                        properties: {
                            name: { type: 'string', description: 'Contact name' },
                            phone: { type: 'string', description: 'Phone number' },
                            email: { type: 'string', description: 'Email address' },
                            company: { type: 'string', description: 'Company name' }
                        },
                        required: ['name', 'phone']
                    },
                }
            ],
        }));

        this.server.setRequestHandler(CallToolRequestSchema, async (request) => {
            const { name, arguments: args } = request.params;

            try {
                switch (name) {
                    case 'get_call_history':
                        return await this.getCallHistory(args);
                    case 'get_contacts':
                        return await this.getContacts(args);
                    case 'make_call':
                        return await this.makeCall(args);
                    case 'send_sms':
                        return await this.sendSMS(args);
                    case 'get_voicemails':
                        return await this.getVoicemails(args);
                    case 'get_call_recordings':
                        return await this.getCallRecordings(args);
                    case 'create_contact':
                        return await this.createContact(args);
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

    async getCallHistory(args) {
        const params = {
            limit: args.limit || 10,
        };

        if (args.start_time) params.start_time = args.start_time;
        if (args.end_time) params.end_time = args.end_time;
        if (args.direction) params.direction = args.direction;

        const response = await this.dialpadClient.get('/calls', { params });

        return {
            content: [{
                type: 'text',
                text: JSON.stringify(response.data, null, 2),
            }],
        };
    }

    async getContacts(args) {
        const params = {
            limit: args.limit || 10,
        };

        if (args.search) params.search = args.search;

        const response = await this.dialpadClient.get('/contacts', { params });

        return {
            content: [{
                type: 'text',
                text: JSON.stringify(response.data, null, 2),
            }],
        };
    }

    async makeCall(args) {
        const callData = {
            to: args.to_number,
            from: args.from_number,
            auto_answer: args.auto_answer || false,
        };

        const response = await this.dialpadClient.post('/calls', callData);

        return {
            content: [{
                type: 'text',
                text: `Call initiated: ${JSON.stringify(response.data, null, 2)}`,
            }],
        };
    }

    async sendSMS(args) {
        const smsData = {
            to: args.to_number,
            text: args.message,
            from: args.from_number,
        };

        const response = await this.dialpadClient.post('/sms', smsData);

        return {
            content: [{
                type: 'text',
                text: `SMS sent: ${JSON.stringify(response.data, null, 2)}`,
            }],
        };
    }

    async getVoicemails(args) {
        const params = {
            limit: args.limit || 10,
        };

        if (args.unread_only) params.is_read = false;

        const response = await this.dialpadClient.get('/voicemails', { params });

        return {
            content: [{
                type: 'text',
                text: JSON.stringify(response.data, null, 2),
            }],
        };
    }

    async getCallRecordings(args) {
        const params = {
            limit: args.limit || 10,
        };

        if (args.call_id) params.call_id = args.call_id;
        if (args.start_time) params.start_time = args.start_time;

        const response = await this.dialpadClient.get('/recordings', { params });

        return {
            content: [{
                type: 'text',
                text: JSON.stringify(response.data, null, 2),
            }],
        };
    }

    async createContact(args) {
        const contactData = {
            name: args.name,
            phone_numbers: [{ number: args.phone, type: 'work' }],
        };

        if (args.email) contactData.emails = [{ email: args.email, type: 'work' }];
        if (args.company) contactData.company = args.company;

        const response = await this.dialpadClient.post('/contacts', contactData);

        return {
            content: [{
                type: 'text',
                text: `Contact created: ${JSON.stringify(response.data, null, 2)}`,
            }],
        };
    }

    async run() {
        const transport = new StdioServerTransport();
        await this.server.connect(transport);
        console.error('Dialpad MCP server running on stdio');
    }
}

const server = new DialpadMCPServer();
server.run().catch(console.error);