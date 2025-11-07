const { google } = require('googleapis');
const fs = require('fs');
const path = require('path');

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

async function extractAttachments() {
  try {
    // Create auth client
    const auth = new google.auth.JWT({
      email: SERVICE_ACCOUNT_CREDS.client_email,
      key: SERVICE_ACCOUNT_CREDS.private_key,
      scopes: ['https://www.googleapis.com/auth/gmail.readonly'],
      subject: 'fred@brickface.com'
    });

    const gmail = google.gmail({ version: 'v1', auth });

    // Create output directory
    const outputDir = path.join(__dirname, 'deal-attachments');
    if (!fs.existsSync(outputDir)) {
      fs.mkdirSync(outputDir);
    }

    // Read the exported emails
    const deals = JSON.parse(fs.readFileSync('gmail-deals-export.json', 'utf-8'));

    console.log(`\nExtracting attachments from ${deals.length} emails...\n`);
    console.log('='.repeat(80));

    const attachmentInfo = [];

    for (let i = 0; i < deals.length; i++) {
      const deal = deals[i];
      console.log(`\nProcessing email ${i + 1}/${deals.length}`);
      console.log(`  Date: ${deal.date}`);
      console.log(`  Subject: ${deal.subject}`);

      // Get full message with attachments
      const msg = await gmail.users.messages.get({
        userId: 'me',
        id: deal.id,
        format: 'full'
      });

      // Process parts to find attachments
      const parts = msg.data.payload.parts || [];
      let attachmentCount = 0;

      for (const part of parts) {
        if (part.filename && part.body.attachmentId) {
          attachmentCount++;

          const attachment = await gmail.users.messages.attachments.get({
            userId: 'me',
            messageId: deal.id,
            id: part.body.attachmentId
          });

          const data = Buffer.from(attachment.data.data, 'base64');
          const filename = `deal_${i + 1}_${part.filename}`;
          const filepath = path.join(outputDir, filename);

          fs.writeFileSync(filepath, data);

          console.log(`  ✓ Saved: ${filename} (${(data.length / 1024).toFixed(2)} KB)`);

          attachmentInfo.push({
            emailIndex: i + 1,
            emailId: deal.id,
            date: deal.date,
            filename: filename,
            filepath: filepath,
            size: data.length,
            mimeType: part.mimeType
          });
        }
      }

      if (attachmentCount === 0) {
        console.log(`  ⚠ No attachments found`);
      }

      console.log('-'.repeat(80));
    }

    // Save attachment info
    fs.writeFileSync(
      path.join(outputDir, 'attachment-index.json'),
      JSON.stringify(attachmentInfo, null, 2)
    );

    console.log(`\n\n✓ Extraction complete!`);
    console.log(`  Total attachments: ${attachmentInfo.length}`);
    console.log(`  Saved to: ${outputDir}`);
    console.log(`  Index file: ${path.join(outputDir, 'attachment-index.json')}`);

    return attachmentInfo;
  } catch (error) {
    console.error('Error extracting attachments:', error.message);
    if (error.response) {
      console.error('Response data:', error.response.data);
    }
    throw error;
  }
}

// Run the extraction
extractAttachments()
  .then(attachments => {
    console.log(`\n\nSuccess! Extracted ${attachments.length} attachments`);
    process.exit(0);
  })
  .catch(error => {
    console.error('\nFailed to extract attachments:', error);
    process.exit(1);
  });
