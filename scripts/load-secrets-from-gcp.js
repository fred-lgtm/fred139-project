#!/usr/bin/env node
/**
 * Load Secrets from GCP Secret Manager
 *
 * This script loads credentials from GCP Secret Manager and makes them
 * available to your application without storing them in files.
 *
 * Usage:
 *   node load-secrets-from-gcp.js [secret-name]
 *
 * Environment Variables:
 *   GCP_PROJECT_ID - Google Cloud Project ID (default: boxwood-charmer-467423-f0)
 */

const { execSync } = require('child_process');
const fs = require('fs');

const PROJECT_ID = process.env.GCP_PROJECT_ID || 'boxwood-charmer-467423-f0';

/**
 * Load a secret from GCP Secret Manager
 */
function loadSecret(secretName) {
  try {
    const command = `gcloud secrets versions access latest --secret=${secretName} --project=${PROJECT_ID}`;
    const secret = execSync(command, { encoding: 'utf-8' }).trim();
    return secret;
  } catch (error) {
    console.error(`Error loading secret '${secretName}':`, error.message);
    return null;
  }
}

/**
 * Load Gmail OAuth credentials from Secret Manager
 */
function loadGmailOAuthCredentials() {
  console.log('Loading Gmail OAuth credentials from GCP Secret Manager...\n');

  const clientId = loadSecret('gmail-oauth-client-id');
  const clientSecret = loadSecret('gmail-oauth-client-secret');

  if (!clientId || !clientSecret) {
    console.error('❌ Failed to load Gmail OAuth credentials');
    console.error('\nPlease ensure the secrets exist in GCP Secret Manager:');
    console.error('  • gmail-oauth-client-id');
    console.error('  • gmail-oauth-client-secret');
    console.error('\nRun setup: bash scripts/setup-gmail-oauth.sh');
    process.exit(1);
  }

  console.log('✓ Successfully loaded Gmail OAuth credentials');
  console.log(`  Client ID: ${clientId.substring(0, 20)}...`);

  // Set environment variables
  process.env.GMAIL_OAUTH_CLIENT_ID = clientId;
  process.env.GMAIL_OAUTH_CLIENT_SECRET = clientSecret;

  return { clientId, clientSecret };
}

/**
 * Load service account credentials from Secret Manager
 */
function loadServiceAccountCredentials() {
  console.log('Loading Service Account credentials from GCP Secret Manager...\n');

  const credentials = loadSecret('google-service-account-credentials');

  if (!credentials) {
    console.error('❌ Failed to load service account credentials');
    console.error('\nSecret not found: google-service-account-credentials');
    process.exit(1);
  }

  console.log('✓ Successfully loaded service account credentials');

  // Set environment variable
  process.env.GOOGLE_SERVICE_ACCOUNT_CREDENTIALS = credentials;

  return JSON.parse(credentials);
}

/**
 * List all secrets in the project
 */
function listSecrets() {
  try {
    const command = `gcloud secrets list --project=${PROJECT_ID} --format=json`;
    const output = execSync(command, { encoding: 'utf-8' });
    const secrets = JSON.parse(output);

    console.log(`\nAvailable secrets in project ${PROJECT_ID}:\n`);
    secrets.forEach(secret => {
      console.log(`  • ${secret.name}`);
    });
    console.log('');
  } catch (error) {
    console.error('Error listing secrets:', error.message);
  }
}

// CLI Usage
if (require.main === module) {
  const args = process.argv.slice(2);
  const command = args[0];

  if (command === 'list') {
    listSecrets();
  } else if (command === 'gmail-oauth') {
    loadGmailOAuthCredentials();
  } else if (command === 'service-account') {
    loadServiceAccountCredentials();
  } else if (command) {
    const secret = loadSecret(command);
    if (secret) {
      console.log(secret);
    }
  } else {
    console.log('Usage: node load-secrets-from-gcp.js <command>');
    console.log('');
    console.log('Commands:');
    console.log('  list                 List all secrets');
    console.log('  gmail-oauth          Load Gmail OAuth credentials');
    console.log('  service-account      Load service account credentials');
    console.log('  [secret-name]        Load specific secret');
    console.log('');
  }
}

module.exports = {
  loadSecret,
  loadGmailOAuthCredentials,
  loadServiceAccountCredentials,
  listSecrets
};
