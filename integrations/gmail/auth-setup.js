require('dotenv').config();

/**
 * Gmail API Authentication Setup
 *
 * Setup Instructions:
 * 1. Go to https://console.cloud.google.com/
 * 2. Create a new project or select existing
 * 3. Enable Gmail API
 * 4. Create OAuth 2.0 credentials
 * 5. Download credentials and save as gmail-credentials.json
 * 6. Run this script to authenticate
 */

console.log('📧 Gmail API Setup');
console.log('==================\n');
console.log('Setup steps:');
console.log('1. Visit: https://console.cloud.google.com/');
console.log('2. Enable Gmail API');
console.log('3. Create OAuth 2.0 credentials');
console.log('4. Download and save as gmail-credentials.json');
console.log('5. Add credentials to .env file\n');

console.log('Required .env variables:');
console.log('GMAIL_CLIENT_ID=your_client_id');
console.log('GMAIL_CLIENT_SECRET=your_client_secret');
console.log('GMAIL_REDIRECT_URI=http://localhost:3000/oauth2callback');