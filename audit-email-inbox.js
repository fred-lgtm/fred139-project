const { google } = require('googleapis');
const fs = require('fs');

// Service account credentials
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

// Spam/solicitation detection patterns
const SPAM_PATTERNS = {
  coldOutreach: [
    /\b(reach(ing)? out|quick question|just wanted to connect|introduction|business development)\b/i,
    /\b(partnership opportunity|collaboration|work together|explore opportunities)\b/i,
    /\b(book a (call|meeting|demo)|schedule (a|some) time)\b/i,
    /\b(thought you('d| would) be interested|might be a good fit)\b/i,
    /\b(help (you|your business)|grow your business|increase (sales|revenue))\b/i
  ],
  marketing: [
    /unsubscribe/i,
    /\b(newsletter|promotional|special offer|limited time)\b/i,
    /\b(discount|sale|free trial|demo)\b/i,
    /click here/i
  ],
  automated: [
    /do not reply/i,
    /automated message/i,
    /no-reply@/i,
    /noreply@/i
  ],
  recruitment: [
    /\b(hiring|job opportunity|career|recruiting|position available)\b/i
  ],
  spam: [
    /\b(earn money|make money|cash|prize|winner|congratulations)\b/i,
    /\b(urgent|action required|verify your account)\b/i
  ]
};

// Business email patterns
const BUSINESS_PATTERNS = {
  leads: [
    /\b(quote|estimate|project|bid|proposal|rfp|request for)\b/i,
    /\b(masonry|brick|concrete|construction|commercial building)\b/i,
    /\b(interested in|looking for|need)\b/i
  ],
  customers: [
    /\b(invoice|payment|contract|agreement|work order)\b/i,
    /\b(project update|status|completion|schedule)\b/i
  ],
  vendors: [
    /\b(supplier|material|delivery|order|purchase)\b/i,
    /\b(brick|mortar|cement|supplies)\b/i
  ],
  projectManagement: [
    /\b(site visit|inspection|permit|drawings|plans)\b/i,
    /\b(architect|engineer|contractor|subcontractor)\b/i
  ],
  financial: [
    /\b(quickbooks|accounting|tax|bank|financial)\b/i,
    /\b(statement|transaction|deposit)\b/i
  ]
};

function detectEmailCategory(subject, from, body) {
  const text = `${subject} ${from} ${body}`.toLowerCase();

  // Check spam/solicitation patterns first
  for (const [category, patterns] of Object.entries(SPAM_PATTERNS)) {
    for (const pattern of patterns) {
      if (pattern.test(text)) {
        return { type: 'spam', subtype: category };
      }
    }
  }

  // Check business patterns
  for (const [category, patterns] of Object.entries(BUSINESS_PATTERNS)) {
    for (const pattern of patterns) {
      if (pattern.test(text)) {
        return { type: 'business', subtype: category };
      }
    }
  }

  return { type: 'uncategorized', subtype: 'other' };
}

function extractDomain(email) {
  const match = email.match(/@([^>]+)/);
  return match ? match[1].trim() : 'unknown';
}

async function auditInbox() {
  try {
    console.log('\n' + '='.repeat(80));
    console.log('GMAIL INBOX AUDIT - fred@brickface.com');
    console.log('='.repeat(80) + '\n');

    // Create auth client
    const auth = new google.auth.JWT({
      email: SERVICE_ACCOUNT_CREDS.client_email,
      key: SERVICE_ACCOUNT_CREDS.private_key,
      scopes: [
        'https://www.googleapis.com/auth/gmail.readonly',
        'https://www.googleapis.com/auth/gmail.labels'
      ],
      subject: 'fred@brickface.com'
    });

    const gmail = google.gmail({ version: 'v1', auth });

    // Get profile info
    const profile = await gmail.users.getProfile({ userId: 'me' });
    console.log(`Account: ${profile.data.emailAddress}`);
    console.log(`Total messages: ${profile.data.messagesTotal}`);
    console.log(`Total threads: ${profile.data.threadsTotal}\n`);

    // Get existing labels
    const labelsResponse = await gmail.users.labels.list({ userId: 'me' });
    console.log('\n--- EXISTING LABELS ---');
    console.log(`Total labels: ${labelsResponse.data.labels.length}`);
    const userLabels = labelsResponse.data.labels.filter(l => l.type === 'user');
    console.log(`User-created labels: ${userLabels.length}`);
    userLabels.forEach(l => console.log(`  - ${l.name}`));

    // Analyze recent emails (last 30 days)
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
    const afterDate = thirtyDaysAgo.toISOString().split('T')[0].replace(/-/g, '/');

    console.log(`\n--- ANALYZING RECENT EMAILS (after ${afterDate}) ---`);

    const queries = [
      { name: 'All Recent', query: `after:${afterDate}` },
      { name: 'Inbox Only', query: `in:inbox after:${afterDate}` },
      { name: 'Unread', query: `is:unread after:${afterDate}` },
      { name: 'Starred', query: `is:starred after:${afterDate}` }
    ];

    const queryResults = {};

    for (const q of queries) {
      const response = await gmail.users.messages.list({
        userId: 'me',
        q: q.query,
        maxResults: 500
      });
      queryResults[q.name] = response.data.messages || [];
      console.log(`${q.name}: ${queryResults[q.name].length} messages`);
    }

    // Deep analysis of inbox messages
    console.log('\n--- DETAILED INBOX ANALYSIS ---');
    console.log(`Analyzing ${Math.min(queryResults['Inbox Only'].length, 200)} most recent inbox messages...\n`);

    const analysis = {
      totalAnalyzed: 0,
      byCategory: {},
      bySender: {},
      byDomain: {},
      spam: [],
      business: [],
      uncategorized: [],
      topSenders: [],
      spamDomains: new Set(),
      businessDomains: new Set()
    };

    const messagesToAnalyze = queryResults['Inbox Only'].slice(0, 200);

    for (let i = 0; i < messagesToAnalyze.length; i++) {
      const messageId = messagesToAnalyze[i].id;

      if (i % 20 === 0) {
        console.log(`Progress: ${i}/${messagesToAnalyze.length} messages analyzed...`);
      }

      try {
        const msg = await gmail.users.messages.get({
          userId: 'me',
          id: messageId,
          format: 'full'
        });

        const headers = msg.data.payload.headers;
        const subject = headers.find(h => h.name === 'Subject')?.value || 'No Subject';
        const from = headers.find(h => h.name === 'From')?.value || '';
        const date = headers.find(h => h.name === 'Date')?.value || '';

        // Get email body snippet
        const snippet = msg.data.snippet || '';

        // Categorize email
        const category = detectEmailCategory(subject, from, snippet);
        const domain = extractDomain(from);

        // Update statistics
        analysis.totalAnalyzed++;

        const categoryKey = `${category.type}_${category.subtype}`;
        analysis.byCategory[categoryKey] = (analysis.byCategory[categoryKey] || 0) + 1;
        analysis.bySender[from] = (analysis.bySender[from] || 0) + 1;
        analysis.byDomain[domain] = (analysis.byDomain[domain] || 0) + 1;

        const emailData = {
          id: messageId,
          date,
          from,
          domain,
          subject,
          snippet,
          category: category.type,
          subcategory: category.subtype
        };

        if (category.type === 'spam') {
          analysis.spam.push(emailData);
          analysis.spamDomains.add(domain);
        } else if (category.type === 'business') {
          analysis.business.push(emailData);
          analysis.businessDomains.add(domain);
        } else {
          analysis.uncategorized.push(emailData);
        }
      } catch (error) {
        console.error(`Error processing message ${messageId}:`, error.message);
      }
    }

    console.log(`\nAnalysis complete: ${analysis.totalAnalyzed} messages processed\n`);

    // Generate insights
    console.log('\n' + '='.repeat(80));
    console.log('INBOX AUDIT RESULTS');
    console.log('='.repeat(80) + '\n');

    console.log('--- EMAIL CATEGORY BREAKDOWN ---');
    const sortedCategories = Object.entries(analysis.byCategory)
      .sort((a, b) => b[1] - a[1]);
    sortedCategories.forEach(([cat, count]) => {
      const percentage = ((count / analysis.totalAnalyzed) * 100).toFixed(1);
      console.log(`  ${cat.padEnd(30)} ${count.toString().padStart(4)} (${percentage}%)`);
    });

    console.log('\n--- SPAM/SOLICITATION SUMMARY ---');
    console.log(`Total spam/solicitation emails: ${analysis.spam.length}`);
    console.log(`Percentage of inbox: ${((analysis.spam.length / analysis.totalAnalyzed) * 100).toFixed(1)}%`);
    console.log(`Unique spam domains: ${analysis.spamDomains.size}`);

    console.log('\n--- TOP SPAM SENDERS ---');
    const spamSenders = {};
    analysis.spam.forEach(email => {
      spamSenders[email.from] = (spamSenders[email.from] || 0) + 1;
    });
    const topSpamSenders = Object.entries(spamSenders)
      .sort((a, b) => b[1] - a[1])
      .slice(0, 15);
    topSpamSenders.forEach(([sender, count]) => {
      console.log(`  ${count}x - ${sender}`);
    });

    console.log('\n--- BUSINESS EMAIL SUMMARY ---');
    console.log(`Total business emails: ${analysis.business.length}`);
    console.log(`Percentage of inbox: ${((analysis.business.length / analysis.totalAnalyzed) * 100).toFixed(1)}%`);

    const businessBreakdown = {};
    analysis.business.forEach(email => {
      businessBreakdown[email.subcategory] = (businessBreakdown[email.subcategory] || 0) + 1;
    });
    console.log('\nBusiness email breakdown:');
    Object.entries(businessBreakdown)
      .sort((a, b) => b[1] - a[1])
      .forEach(([cat, count]) => {
        console.log(`  ${cat.padEnd(20)} ${count}`);
      });

    console.log('\n--- TOP SENDERS (ALL) ---');
    const topSenders = Object.entries(analysis.bySender)
      .sort((a, b) => b[1] - a[1])
      .slice(0, 20);
    topSenders.forEach(([sender, count]) => {
      console.log(`  ${count}x - ${sender}`);
    });

    console.log('\n--- TOP DOMAINS ---');
    const topDomains = Object.entries(analysis.byDomain)
      .sort((a, b) => b[1] - a[1])
      .slice(0, 20);
    topDomains.forEach(([domain, count]) => {
      const type = analysis.spamDomains.has(domain) ? '[SPAM]' :
                   analysis.businessDomains.has(domain) ? '[BUSINESS]' : '';
      console.log(`  ${count}x - ${domain} ${type}`);
    });

    // Save detailed results
    const auditResults = {
      timestamp: new Date().toISOString(),
      profile: {
        email: profile.data.emailAddress,
        totalMessages: profile.data.messagesTotal,
        totalThreads: profile.data.threadsTotal
      },
      period: {
        from: afterDate,
        to: new Date().toISOString().split('T')[0]
      },
      summary: {
        totalAnalyzed: analysis.totalAnalyzed,
        spamCount: analysis.spam.length,
        businessCount: analysis.business.length,
        uncategorizedCount: analysis.uncategorized.length,
        spamPercentage: ((analysis.spam.length / analysis.totalAnalyzed) * 100).toFixed(1),
        businessPercentage: ((analysis.business.length / analysis.totalAnalyzed) * 100).toFixed(1)
      },
      categories: sortedCategories.map(([cat, count]) => ({
        category: cat,
        count,
        percentage: ((count / analysis.totalAnalyzed) * 100).toFixed(1)
      })),
      topSpamSenders: topSpamSenders.map(([sender, count]) => ({ sender, count })),
      topSenders: topSenders.map(([sender, count]) => ({ sender, count })),
      topDomains: topDomains.map(([domain, count]) => ({ domain, count })),
      spamDomains: Array.from(analysis.spamDomains),
      businessDomains: Array.from(analysis.businessDomains),
      existingLabels: userLabels.map(l => ({ name: l.name, id: l.id })),
      detailedEmails: {
        spam: analysis.spam,
        business: analysis.business,
        uncategorized: analysis.uncategorized.slice(0, 50) // Sample of uncategorized
      }
    };

    fs.writeFileSync(
      'email-audit-results.json',
      JSON.stringify(auditResults, null, 2)
    );

    console.log('\n\n' + '='.repeat(80));
    console.log('AUDIT COMPLETE');
    console.log('='.repeat(80));
    console.log(`\nDetailed results saved to: email-audit-results.json`);
    console.log(`\nKey findings:`);
    console.log(`  - ${analysis.spam.length} spam/solicitation emails (${((analysis.spam.length / analysis.totalAnalyzed) * 100).toFixed(1)}%)`);
    console.log(`  - ${analysis.business.length} business emails (${((analysis.business.length / analysis.totalAnalyzed) * 100).toFixed(1)}%)`);
    console.log(`  - ${analysis.spamDomains.size} spam domains identified`);
    console.log(`  - ${topSpamSenders.length} top spam senders identified`);

    return auditResults;
  } catch (error) {
    console.error('Error during inbox audit:', error.message);
    if (error.response) {
      console.error('Response data:', error.response.data);
    }
    throw error;
  }
}

// Run the audit
auditInbox()
  .then(results => {
    console.log('\n\nAudit successful!');
    process.exit(0);
  })
  .catch(error => {
    console.error('\nAudit failed:', error);
    process.exit(1);
  });
