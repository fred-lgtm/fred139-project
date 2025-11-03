#!/usr/bin/env python3
"""
Google Sheets MCP Server
Provides access to Google Sheets API for reading and updating spreadsheets
"""

import os
import json
from typing import Any
from mcp.server import Server
from mcp.types import Tool, TextContent
from google.oauth2 import service_account
from googleapiclient.discovery import build
from googleapiclient.errors import HttpError

# Initialize MCP server
app = Server("google-sheets")

# Google Sheets API setup
SCOPES = [
    'https://www.googleapis.com/auth/spreadsheets',
    'https://www.googleapis.com/auth/drive.readonly'
]

SERVICE_ACCOUNT_FILE = os.getenv(
    'GOOGLE_SERVICE_ACCOUNT_FILE',
    'c:\\Users\\frede\\Documents\\brickface-enterprise\\config\\google-service-account.json'
)

def get_sheets_service():
    """Initialize Google Sheets API service"""
    credentials = service_account.Credentials.from_service_account_file(
        SERVICE_ACCOUNT_FILE, scopes=SCOPES)
    return build('sheets', 'v4', credentials=credentials)

@app.list_tools()
async def list_tools() -> list[Tool]:
    """List available Google Sheets tools"""
    return [
        Tool(
            name="sheets_read_range",
            description="Read data from a Google Sheets range",
            inputSchema={
                "type": "object",
                "properties": {
                    "spreadsheet_id": {
                        "type": "string",
                        "description": "The Google Sheets spreadsheet ID"
                    },
                    "range": {
                        "type": "string",
                        "description": "The A1 notation range (e.g., 'Sheet1!A1:D10')"
                    }
                },
                "required": ["spreadsheet_id", "range"]
            }
        ),
        Tool(
            name="sheets_update_range",
            description="Update data in a Google Sheets range",
            inputSchema={
                "type": "object",
                "properties": {
                    "spreadsheet_id": {
                        "type": "string",
                        "description": "The Google Sheets spreadsheet ID"
                    },
                    "range": {
                        "type": "string",
                        "description": "The A1 notation range (e.g., 'Sheet1!A1:D10')"
                    },
                    "values": {
                        "type": "array",
                        "description": "2D array of values to write",
                        "items": {
                            "type": "array",
                            "items": {"type": "string"}
                        }
                    }
                },
                "required": ["spreadsheet_id", "range", "values"]
            }
        ),
        Tool(
            name="sheets_append_row",
            description="Append a new row to a Google Sheet",
            inputSchema={
                "type": "object",
                "properties": {
                    "spreadsheet_id": {
                        "type": "string",
                        "description": "The Google Sheets spreadsheet ID"
                    },
                    "range": {
                        "type": "string",
                        "description": "The range to append to (e.g., 'Sheet1!A:D')"
                    },
                    "values": {
                        "type": "array",
                        "description": "Array of values for the new row",
                        "items": {"type": "string"}
                    }
                },
                "required": ["spreadsheet_id", "range", "values"]
            }
        ),
        Tool(
            name="sheets_get_info",
            description="Get spreadsheet metadata and sheet information",
            inputSchema={
                "type": "object",
                "properties": {
                    "spreadsheet_id": {
                        "type": "string",
                        "description": "The Google Sheets spreadsheet ID"
                    }
                },
                "required": ["spreadsheet_id"]
            }
        ),
        Tool(
            name="sheets_batch_update",
            description="Update multiple ranges in a Google Sheet",
            inputSchema={
                "type": "object",
                "properties": {
                    "spreadsheet_id": {
                        "type": "string",
                        "description": "The Google Sheets spreadsheet ID"
                    },
                    "updates": {
                        "type": "array",
                        "description": "Array of range updates",
                        "items": {
                            "type": "object",
                            "properties": {
                                "range": {"type": "string"},
                                "values": {
                                    "type": "array",
                                    "items": {
                                        "type": "array",
                                        "items": {"type": "string"}
                                    }
                                }
                            }
                        }
                    }
                },
                "required": ["spreadsheet_id", "updates"]
            }
        )
    ]

@app.call_tool()
async def call_tool(name: str, arguments: Any) -> list[TextContent]:
    """Handle tool calls"""
    try:
        service = get_sheets_service()

        if name == "sheets_read_range":
            spreadsheet_id = arguments["spreadsheet_id"]
            range_name = arguments["range"]

            result = service.spreadsheets().values().get(
                spreadsheetId=spreadsheet_id,
                range=range_name
            ).execute()

            values = result.get('values', [])
            return [TextContent(
                type="text",
                text=json.dumps({"values": values}, indent=2)
            )]

        elif name == "sheets_update_range":
            spreadsheet_id = arguments["spreadsheet_id"]
            range_name = arguments["range"]
            values = arguments["values"]

            body = {'values': values}
            result = service.spreadsheets().values().update(
                spreadsheetId=spreadsheet_id,
                range=range_name,
                valueInputOption='USER_ENTERED',
                body=body
            ).execute()

            return [TextContent(
                type="text",
                text=f"Updated {result.get('updatedCells')} cells in range {range_name}"
            )]

        elif name == "sheets_append_row":
            spreadsheet_id = arguments["spreadsheet_id"]
            range_name = arguments["range"]
            values = [arguments["values"]]  # Wrap in array for single row

            body = {'values': values}
            result = service.spreadsheets().values().append(
                spreadsheetId=spreadsheet_id,
                range=range_name,
                valueInputOption='USER_ENTERED',
                insertDataOption='INSERT_ROWS',
                body=body
            ).execute()

            return [TextContent(
                type="text",
                text=f"Appended row to {range_name}. Updated range: {result.get('updates', {}).get('updatedRange')}"
            )]

        elif name == "sheets_get_info":
            spreadsheet_id = arguments["spreadsheet_id"]

            spreadsheet = service.spreadsheets().get(
                spreadsheetId=spreadsheet_id
            ).execute()

            info = {
                "title": spreadsheet.get('properties', {}).get('title'),
                "sheets": [
                    {
                        "title": sheet['properties']['title'],
                        "sheetId": sheet['properties']['sheetId'],
                        "index": sheet['properties']['index']
                    }
                    for sheet in spreadsheet.get('sheets', [])
                ]
            }

            return [TextContent(
                type="text",
                text=json.dumps(info, indent=2)
            )]

        elif name == "sheets_batch_update":
            spreadsheet_id = arguments["spreadsheet_id"]
            updates = arguments["updates"]

            data = [
                {
                    'range': update['range'],
                    'values': update['values']
                }
                for update in updates
            ]

            body = {'data': data, 'valueInputOption': 'USER_ENTERED'}
            result = service.spreadsheets().values().batchUpdate(
                spreadsheetId=spreadsheet_id,
                body=body
            ).execute()

            return [TextContent(
                type="text",
                text=f"Batch updated {result.get('totalUpdatedCells')} cells across {len(updates)} ranges"
            )]

        else:
            return [TextContent(
                type="text",
                text=f"Unknown tool: {name}"
            )]

    except HttpError as error:
        return [TextContent(
            type="text",
            text=f"Google Sheets API error: {error}"
        )]
    except Exception as error:
        return [TextContent(
            type="text",
            text=f"Error: {str(error)}"
        )]

if __name__ == "__main__":
    import asyncio
    import mcp.server.stdio

    async def main():
        async with mcp.server.stdio.stdio_server() as (read_stream, write_stream):
            await app.run(
                read_stream,
                write_stream,
                app.create_initialization_options()
            )

    asyncio.run(main())
