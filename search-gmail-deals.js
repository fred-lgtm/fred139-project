const { google } = require('googleapis');
const fs = require('fs');

// Service account credentials from 1Password
const SERVICE_ACCOUNT_CREDS = {
  "type": "service_account",
  "project_id": "boxwood-charmer-467423-f0",
  "private_key_id": "1ca33ef3f4006f2598c76ddc285c375989cf592f",
  "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQDxlNwN+t/Yjgvs\njJ9ypihYHBgoUfybbSF93LcPG6Sh1vo8BnnnO7oCgIhybfyqP/5lN0il3gYN0zmi\nbhN10w5hqcPsILYR6Nc98dIabJhJRhhuhDv90ap85CaEwb7KnV36PwHHuUf6A34/\nne7BIgXQsg8K8ONLALF2YUufjgVgjkFWHls4ZJ52f2xKESUK9bAycp9e9bQn2yaP\nASToz8yPB8hpKxogadxONKTxX7pKi6pu4YeSusFVnIHqkuFCZj+Kpqme98uTgK8V\nqKJ0C0iyXRdLgXOF2LdzrUWvkx2cfDlvkFBejskHnffwp1IaFaJEbc3kKac5eGdP\nsFEvz6HPAgMBAAECggEAVGUrpxqgfrfJBJ9vyI6xg251JgjWVbn/PEgSD44Zqow+\nqR+eEKD174/Vmxw/a36lsdhpYcC5nrTO6qbH156e5JF5J5GZ6ZHNOA+11ZNgdCCv\nwlQh3R8VD0JpDnHc5E2rmhPO3GYm9fmobjMPSJtJKso5pRnYXchlNrTwxVHJIRyD\ng3TMQKikLKIQEKlho2TI9Bl9YQ87MUTwD+r+uuaqYkc1LM/+56NM8ChfH0eyn1R1\nNU+erjmHrU0Ivy9DzdyEjMgjEAdQUN9Ytf9No9vYBg0RVHflKYLK3yc6pslQMjOq\n0VpsX4pxi5TNrV18dzH/mOH+VswKDlwqj4BudFQvkQKBgQD70bhOnIP2cpMDgM8K\nwX5SO2RuPTJOurBxLHchsi5tm5JZR/E8Q89CBMfsbPS569WHrS7EuDR+U5EAu7xF\nlOjvohhS2YE0/qtVxhSzLNAFCuFeL9//ceEB9MxuNS10Xf+Mu+vgMR1te6Ac42fL\nFD2PI9mSyYZE6nkONnzER2evqQKBgQD1l6CWamDalgpYc/6TCc4tGnCbIE2Hhjv4\nEqhw+NNtXVRdioUnm5Hz9QjbGCN2otyYE0fBJQNcezXwFBS1zrHk4D2Q0AOsGoi8\n7xqY6SJJQeBL1iV9DVwgJSsLULaDvFMuD19csEeD+pKT4TayKh9tEoonZLj0aZtd\nN4lsuBKQtwKBgAaERuDB7ChUjrloe/MrTrmSD+dKbiLbcfV70RluIwVzITZuRi/p\nEVQEC6hyqWKmV8BLGwq8OZ+LShVaxmSGlgCdkUOTnWRhss1lcuOwJTH8NhjZ5FIY\nAFqsmx2/Ao4gYJyjwFbs7nYG3P3iZK08uNsbcmX6ER93ceqMPm5V6rkBAoGBAIiA\nkGdKFS8pOfLT9ekwCAKVsYTnPXBYMbi+VhUEmC8vMpcTSNMs6sCXryZnkj58YvO7\ns6QsuGOMr/wSjThH/CRkZpO4qnHcBahNlZDr83yYOtyr2AZbiJrtTbFqWSd7Yxg0\nvyI7cGRwv0umX8pDE1iCd3tRxmNC13HGToG5BcidAoGAWjLpRh7FeQAWyXVPiT8O\nNiBpQYjhBwQaOgme9wn1XVeF7bbAJkb4yt/686FbfSC9TpBXLu2+nB/oRDlkIn8r\n8aGblRv8qQ1kOWIksj4sho17UA+p2Tpls60HYf/KP1PLjIbWOQ3qM+LZsr3rZooM\n7TAbgeJ11B40E48//i6GspE=\n-----END PRIVATE KEY-----\n",
  "client_email": "google-workspace-access@boxwood-charmer-467423-f0.iam.gserviceaccount.com",
  "client_id": "104951098191722372431",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/google-workspace-access%40boxwood-charmer-467423-f0.iam.gserviceaccount.com",
  "universe_domain": "googleapis.com"
};

async function searchGmailDeals() {
  try {
    // Create auth client
    const auth = new google.auth.JWT({
      email: SERVICE_ACCOUNT_CREDS.client_email,
      key: SERVICE_ACCOUNT_CREDS.private_key,
      scopes: ['https://www.googleapis.com/auth/gmail.readonly'],
      subject: 'fred@brickface.com' // Impersonate fred@brickface.com
    });

    const gmail = google.gmail({ version: 'v1', auth });

    // Search for emails from scan@brickface.com between Nov 4-5, 2025
    const query = 'from:scan@brickface.com after:2025/11/03 before:2025/11/06';

    console.log(`\nSearching Gmail with query: ${query}\n`);

    const response = await gmail.users.messages.list({
      userId: 'me',
      q: query,
      maxResults: 50
    });

    if (!response.data.messages || response.data.messages.length === 0) {
      console.log('No messages found matching the criteria.');
      return [];
    }

    console.log(`Found ${response.data.messages.length} messages\n`);
    console.log('='  .repeat(80));

    const deals = [];

    // Fetch full message details
    for (const message of response.data.messages) {
      const msg = await gmail.users.messages.get({
        userId: 'me',
        id: message.id,
        format: 'full'
      });

      const headers = msg.data.payload.headers;
      const subject = headers.find(h => h.name === 'Subject')?.value || 'No Subject';
      const from = headers.find(h => h.name === 'From')?.value || '';
      const date = headers.find(h => h.name === 'Date')?.value || '';
      const to = headers.find(h => h.name === 'To')?.value || '';

      // Get email body
      let body = '';
      if (msg.data.payload.body.data) {
        body = Buffer.from(msg.data.payload.body.data, 'base64').toString('utf-8');
      } else if (msg.data.payload.parts) {
        for (const part of msg.data.payload.parts) {
          if (part.mimeType === 'text/plain' && part.body.data) {
            body += Buffer.from(part.body.data, 'base64').toString('utf-8');
          } else if (part.mimeType === 'text/html' && part.body.data && !body) {
            body = Buffer.from(part.body.data, 'base64').toString('utf-8');
          }
        }
      }

      deals.push({
        id: message.id,
        subject,
        from,
        to,
        date,
        body,
        snippet: msg.data.snippet
      });

      console.log(`\nEmail ${deals.length}:`);
      console.log(`  Subject: ${subject}`);
      console.log(`  From: ${from}`);
      console.log(`  To: ${to}`);
      console.log(`  Date: ${date}`);
      console.log(`  Snippet: ${msg.data.snippet}`);
      console.log('-'.repeat(80));
    }

    // Save to file for review
    fs.writeFileSync(
      'gmail-deals-export.json',
      JSON.stringify(deals, null, 2)
    );

    console.log(`\n\nExported ${deals.length} emails to gmail-deals-export.json`);

    return deals;
  } catch (error) {
    console.error('Error searching Gmail:', error.message);
    if (error.response) {
      console.error('Response data:', error.response.data);
    }
    throw error;
  }
}

// Run the search
searchGmailDeals()
  .then(deals => {
    console.log(`\n\nSuccess! Found ${deals.length} deals from scan@brickface.com`);
    process.exit(0);
  })
  .catch(error => {
    console.error('\nFailed to search Gmail:', error);
    process.exit(1);
  });
