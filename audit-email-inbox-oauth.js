const { google } = require('googleapis');
const fs = require('fs');
const http = require('http');
const url = require('url');
const open = require('open');
const path = require('path');

// Load environment variables from both .env and .env.local
require('dotenv').config();
require('dotenv').config({ path: '.env.local' });

// OAuth 2.0 Client Configuration
const OAUTH_CONFIG = {
  client_id: process.env.GMAIL_OAUTH_CLIENT_ID || '',
  client_secret: process.env.GMAIL_OAUTH_CLIENT_SECRET || '',
  redirect_uri: 'http://localhost:3000/oauth2callback',
  token_path: './gmail-oauth-token.json'
};

const SCOPES = [
  'https://www.googleapis.com/auth/gmail.readonly',
  'https://www.googleapis.com/auth/gmail.labels'
];

// Spam/solicitation detection patterns (same as original)
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

async function getAuthClient() {
  const oauth2Client = new google.auth.OAuth2(
    OAUTH_CONFIG.client_id,
    OAUTH_CONFIG.client_secret,
    OAUTH_CONFIG.redirect_uri
  );

  // Check if we have a saved token
  if (fs.existsSync(OAUTH_CONFIG.token_path)) {
    const token = JSON.parse(fs.readFileSync(OAUTH_CONFIG.token_path, 'utf-8'));
    oauth2Client.setCredentials(token);
    return oauth2Client;
  }

  // If no token, start OAuth flow
  return await authenticateUser(oauth2Client);
}

async function authenticateUser(oauth2Client) {
  return new Promise((resolve, reject) => {
    const authUrl = oauth2Client.generateAuthUrl({
      access_type: 'offline',
      scope: SCOPES,
    });

    console.log('\n='.repeat(80));
    console.log('GMAIL OAUTH AUTHENTICATION REQUIRED');
    console.log('='.repeat(80));
    console.log('\nOpening browser for authentication...');
    console.log('If browser does not open, visit this URL:\n');
    console.log(authUrl);
    console.log('\n');

    // Create temporary server to receive OAuth callback
    const server = http.createServer(async (req, res) => {
      if (req.url.indexOf('/oauth2callback') > -1) {
        const qs = new url.URL(req.url, 'http://localhost:3000').searchParams;
        const code = qs.get('code');

        res.end('Authentication successful! You can close this window and return to the terminal.');

        server.close();

        try {
          const { tokens } = await oauth2Client.getToken(code);
          oauth2Client.setCredentials(tokens);

          // Save token for future use
          fs.writeFileSync(OAUTH_CONFIG.token_path, JSON.stringify(tokens, null, 2));
          console.log('\n✓ Authentication successful!');
          console.log(`✓ Token saved to ${OAUTH_CONFIG.token_path}\n`);

          resolve(oauth2Client);
        } catch (err) {
          reject(err);
        }
      }
    });

    server.listen(3000, () => {
      open(authUrl, { wait: false }).catch(() => {
        console.log('Could not automatically open browser. Please open the URL manually.');
      });
    });
  });
}

async function auditInbox() {
  try {
    console.log('\n' + '='.repeat(80));
    console.log('GMAIL INBOX AUDIT - fred@brickface.com (OAuth)');
    console.log('='.repeat(80) + '\n');

    // Get authenticated client
    const auth = await getAuthClient();
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

    // Generate insights (same as original)
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
      authMethod: 'oauth2',
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
        uncategorized: analysis.uncategorized.slice(0, 50)
      }
    };

    fs.writeFileSync(
      'email-audit-results-oauth.json',
      JSON.stringify(auditResults, null, 2)
    );

    console.log('\n\n' + '='.repeat(80));
    console.log('AUDIT COMPLETE');
    console.log('='.repeat(80));
    console.log(`\nDetailed results saved to: email-audit-results-oauth.json`);
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

// Check if OAuth credentials are configured
if (!OAUTH_CONFIG.client_id || !OAUTH_CONFIG.client_secret) {
  console.error('\n❌ ERROR: OAuth credentials not configured!');
  console.error('\nPlease set the following environment variables in your .env file:');
  console.error('  GMAIL_OAUTH_CLIENT_ID=your_client_id');
  console.error('  GMAIL_OAUTH_CLIENT_SECRET=your_client_secret');
  console.error('\nTo get these credentials:');
  console.error('1. Go to https://console.cloud.google.com/apis/credentials');
  console.error('2. Create OAuth 2.0 Client ID (Desktop app or Web application)');
  console.error('3. Add http://localhost:3000/oauth2callback as redirect URI');
  console.error('4. Download credentials and add to .env file\n');
  process.exit(1);
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
