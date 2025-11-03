#!/usr/bin/env node

/**
 * HubSpot MCP Server
 * Provides HubSpot CRM integration for Claude AI
 */

const { Server } = require('@modelcontextprotocol/sdk/server/index.js');
const { StdioServerTransport } = require('@modelcontextprotocol/sdk/server/stdio.js');
const {
    CallToolRequestSchema,
    ListToolsRequestSchema,
} = require('@modelcontextprotocol/sdk/types.js');
const axios = require('axios');

class HubSpotMCPServer {
    constructor() {
        this.server = new Server(
            {
                name: 'hubspot-mcp',
                version: '0.1.0',
            },
            {
                capabilities: {
                    tools: {},
                },
            }
        );

        this.hubspotClient = axios.create({
            baseURL: 'https://api.hubapi.com',
            headers: {
                'Authorization': `Bearer ${process.env.HUBSPOT_ACCESS_TOKEN}`,
                'Content-Type': 'application/json',
            },
        });

        this.setupToolHandlers();
    }

    setupToolHandlers() {
        this.server.setRequestHandler(ListToolsRequestSchema, async () => ({
            tools: [
                {
                    name: 'get_contacts',
                    description: 'Get HubSpot contacts with optional filters',
                    inputSchema: {
                        type: 'object',
                        properties: {
                            limit: { type: 'number', default: 10 },
                            properties: { type: 'array', items: { type: 'string' } },
                        },
                    },
                },
                {
                    name: 'get_companies',
                    description: 'Get HubSpot companies with optional filters',
                    inputSchema: {
                        type: 'object',
                        properties: {
                            limit: { type: 'number', default: 10 },
                            properties: { type: 'array', items: { type: 'string' } },
                        },
                    },
                },
                {
                    name: 'create_contact',
                    description: 'Create a new contact in HubSpot',
                    inputSchema: {
                        type: 'object',
                        properties: {
                            properties: {
                                type: 'object',
                                required: ['email'],
                                properties: {
                                    email: { type: 'string' },
                                    firstname: { type: 'string' },
                                    lastname: { type: 'string' },
                                    phone: { type: 'string' },
                                    company: { type: 'string' },
                                },
                            },
                        },
                    },
                },
                {
                    name: 'get_deals',
                    description: 'Get HubSpot deals/opportunities',
                    inputSchema: {
                        type: 'object',
                        properties: {
                            limit: { type: 'number', default: 10 },
                            properties: { type: 'array', items: { type: 'string' } },
                        },
                    },
                },
            ],
        }));

        this.server.setRequestHandler(CallToolRequestSchema, async (request) => {
            const { name, arguments: args } = request.params;

            try {
                switch (name) {
                    case 'get_contacts':
                        return await this.getContacts(args);
                    case 'get_companies':
                        return await this.getCompanies(args);
                    case 'create_contact':
                        return await this.createContact(args);
                    case 'get_deals':
                        return await this.getDeals(args);
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

    async getContacts(args) {
        const response = await this.hubspotClient.get('/crm/v3/objects/contacts', {
            params: {
                limit: args.limit || 10,
                properties: args.properties?.join(',') || 'email,firstname,lastname,phone',
            },
        });

        return {
            content: [{
                type: 'text',
                text: JSON.stringify(response.data, null, 2),
            }],
        };
    }

    async getCompanies(args) {
        const response = await this.hubspotClient.get('/crm/v3/objects/companies', {
            params: {
                limit: args.limit || 10,
                properties: args.properties?.join(',') || 'name,domain,industry',
            },
        });

        return {
            content: [{
                type: 'text',
                text: JSON.stringify(response.data, null, 2),
            }],
        };
    }

    async createContact(args) {
        const response = await this.hubspotClient.post('/crm/v3/objects/contacts', {
            properties: args.properties,
        });

        return {
            content: [{
                type: 'text',
                text: `Contact created successfully: ${JSON.stringify(response.data, null, 2)}`,
            }],
        };
    }

    async getDeals(args) {
        const response = await this.hubspotClient.get('/crm/v3/objects/deals', {
            params: {
                limit: args.limit || 10,
                properties: args.properties?.join(',') || 'dealname,amount,dealstage',
            },
        });

        return {
            content: [{
                type: 'text',
                text: JSON.stringify(response.data, null, 2),
            }],
        };
    }

    async run() {
        const transport = new StdioServerTransport();
        await this.server.connect(transport);
        console.error('HubSpot MCP server running on stdio');
    }
}

const server = new HubSpotMCPServer();
server.run().catch(console.error);