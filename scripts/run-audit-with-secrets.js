#!/usr/bin/env node
/**
 * Run Gmail Inbox Audit with Credentials from GCP Secret Manager
 *
 * This script loads credentials from GCP Secret Manager and runs the audit
 * without storing credentials in local files.
 */

const { execSync } = require('child_process');
const { loadGmailOAuthCredentials } = require('./load-secrets-from-gcp');

console.log('='.repeat(80));
console.log('Gmail Inbox Audit - Secure Mode (GCP Secret Manager)');
console.log('='.repeat(80));
console.log('');

// Load credentials from Secret Manager
const { clientId, clientSecret } = loadGmailOAuthCredentials();

// Set environment variables for the audit script
process.env.GMAIL_OAUTH_CLIENT_ID = clientId;
process.env.GMAIL_OAUTH_CLIENT_SECRET = clientSecret;

console.log('');
console.log('Starting inbox audit...');
console.log('');

// Run the audit script
try {
  execSync('node audit-email-inbox-oauth.js', {
    stdio: 'inherit',
    env: process.env
  });
} catch (error) {
  console.error('Audit failed:', error.message);
  process.exit(1);
}
