const axios = require('axios');
const fs = require('fs');

// API Credentials
const HUBSPOT_TOKEN = 'pat-na1-4c42c535-589e-4181-ba6a-df359d4c278d';
const OPENROUTER_API_KEY = process.env.OPENROUTER_API_KEY; // Will be passed via env

const hubspotClient = axios.create({
  baseURL: 'https://api.hubapi.com',
  headers: {
    'Authorization': `Bearer ${HUBSPOT_TOKEN}`,
    'Content-Type': 'application/json',
  },
  timeout: 30000
});

// Raw deals from PDF analysis
const rawDeals = [
  {
    dealname: 'Gotham Waterproofing - 55 Spruce St, Newark',
    amount: 29560,
    description: 'Waterproofing, caulking, and sealer work at 55 Spruce St, Newark, NJ',
    company_name: 'Gotham Waterproofing',
    address: '55 Spruce St, Newark, NJ',
    contact: 'Maria Bello'
  },
  {
    dealname: 'Gotham Waterproofing - 59 Spruce St, Newark',
    amount: 7000,
    description: 'Rear wall waterproofing at 59 Spruce St, Newark, NJ',
    company_name: 'Gotham Waterproofing',
    address: '59 Spruce St, Newark, NJ',
    contact: 'Maria Bello'
  },
  {
    dealname: 'Anchor Stone - 20 Forest St, Montclair',
    amount: 10500,
    description: 'Foundation repair work at 20 Forest St, Montclair, NJ',
    company_name: 'Anchor Stone',
    address: '20 Forest St, Montclair, NJ'
  },
  {
    dealname: 'Gotham Waterproofing - The Highlands Apartments',
    amount: 23630,
    description: 'Parking garage drain, deck repairs, balcony coatings at 40 E Hanover Ave, Morris Plains, NJ',
    company_name: 'Gotham Waterproofing',
    address: '40 E Hanover Ave, Morris Plains, NJ (The Highlands Apartments)',
    contact: 'Wellington Batlle'
  },
  {
    dealname: 'Garden State Brickface - 59 Skillman Ave, Jersey City',
    amount: 98950,
    description: 'Masonry restoration and painting at 59 Skillman Ave, Jersey City, NJ',
    company_name: 'Garden State Brickface',
    address: '59 Skillman Ave, Jersey City, NJ',
    contact: 'Saied Atewan'
  },
  {
    dealname: 'Gotham Waterproofing - 300 Bunn Drive, Princeton',
    amount: 10950,
    description: 'Window waterproofing at Units A-203 and D-403, 300 Bunn Drive, Princeton, NJ',
    company_name: 'Gotham Waterproofing',
    address: '300 Bunn Drive, Princeton, NJ'
  },
  {
    dealname: 'Garden State Brickface - 201 Wescott Drive, Rahway',
    amount: 50000,
    description: 'Large stucco/siding project at 201 Wescott Drive, Rahway, NJ',
    company_name: 'Garden State Brickface',
    address: '201 Wescott Drive, Rahway, NJ'
  },
  {
    dealname: 'Garden State Commercial - Wallace Vinyl Windows',
    amount: 1254,
    description: 'Vinyl window order for Wallace project in Summit, NJ',
    company_name: 'Garden State Commercial',
    address: 'Summit, NJ'
  }
];

async function enrichDealWithAI(deal) {
  if (!OPENROUTER_API_KEY) {
    console.log(`  ⚠ Skipping AI enrichment (no API key) - using base data`);
    return {
      ...deal,
      pipeline: 'default',
      dealstage: 'appointmentscheduled',
      closedate: new Date('2025-11-30').getTime(),
      source: 'scan@brickface.com email',
      hs_priority: 'medium',
      enrichment_notes: 'Deal imported from email scan - requires manual review'
    };
  }

  try {
    console.log(`  🤖 Enriching with AI...`);

    const prompt = `You are a construction business analyst. Analyze this deal and provide enrichment:

Deal: ${deal.dealname}
Amount: $${deal.amount}
Description: ${deal.description}
Company: ${deal.company_name}
Location: ${deal.address}
${deal.contact ? `Contact: ${deal.contact}` : ''}

Provide a JSON response with:
1. win_probability (0-100): Likelihood of closing this deal
2. priority (low/medium/high): Deal priority based on value and strategic fit
3. key_insights: Array of 2-3 key insights about this opportunity
4. action_items: Array of 2-3 specific next steps to increase close probability
5. risk_factors: Array of 1-2 potential risks or concerns
6. enhanced_description: A professional, detailed description for CRM

Respond ONLY with valid JSON, no markdown.`;

    const response = await axios.post('https://openrouter.ai/api/v1/chat/completions', {
      model: 'google/gemini-flash-1.5',
      messages: [{ role: 'user', content: prompt }],
      max_tokens: 800,
      temperature: 0.3
    }, {
      headers: {
        'Authorization': `Bearer ${OPENROUTER_API_KEY}`,
        'Content-Type': 'application/json',
        'HTTP-Referer': 'https://brickface.com',
        'X-Title': 'Brickface Deal Enrichment'
      }
    });

    const aiContent = response.data.choices[0].message.content;
    const jsonMatch = aiContent.match(/\{[\s\S]*\}/);
    const enrichment = jsonMatch ? JSON.parse(jsonMatch[0]) : null;

    if (enrichment) {
      console.log(`  ✓ AI Enrichment complete - Win probability: ${enrichment.win_probability}%`);

      return {
        ...deal,
        pipeline: 'default',
        dealstage: enrichment.win_probability > 70 ? 'qualifiedtobuy' : 'appointmentscheduled',
        closedate: new Date('2025-11-30').getTime(),
        source: 'scan@brickface.com email',
        hs_priority: enrichment.priority,
        description: enrichment.enhanced_description,
        enrichment_notes: `AI Analysis:\n\nWin Probability: ${enrichment.win_probability}%\n\nKey Insights:\n${enrichment.key_insights.map(i => `• ${i}`).join('\n')}\n\nAction Items:\n${enrichment.action_items.map(a => `• ${a}`).join('\n')}\n\nRisk Factors:\n${enrichment.risk_factors.map(r => `• ${r}`).join('\n')}`,
        win_probability: enrichment.win_probability
      };
    }
  } catch (error) {
    console.error(`  ⚠ AI enrichment failed: ${error.message}`);
  }

  // Fallback if AI enrichment fails
  return {
    ...deal,
    pipeline: 'default',
    dealstage: 'appointmentscheduled',
    closedate: new Date('2025-11-30').getTime(),
    source: 'scan@brickface.com email',
    hs_priority: deal.amount > 50000 ? 'high' : deal.amount > 20000 ? 'medium' : 'low',
    enrichment_notes: 'Deal imported from email scan - AI enrichment unavailable'
  };
}

async function addEnrichedDealsToHubSpot() {
  try {
    console.log(`\n${'='.repeat(80)}`);
    console.log(`BRICKFACE DEAL ENRICHMENT & IMPORT SYSTEM`);
    console.log(`${'='.repeat(80)}\n`);
    console.log(`Processing ${rawDeals.length} deals with AI enrichment...\n`);

    const enrichedDeals = [];
    const createdDeals = [];

    // Step 1: Enrich deals with AI
    console.log(`\n[STEP 1] AI-POWERED DEAL ENRICHMENT\n`);
    for (let i = 0; i < rawDeals.length; i++) {
      const deal = rawDeals[i];
      console.log(`\n[${i + 1}/${rawDeals.length}] ${deal.dealname}`);
      console.log(`  Amount: $${deal.amount.toLocaleString()}`);

      const enriched = await enrichDealWithAI(deal);
      enrichedDeals.push(enriched);

      console.log(`  Priority: ${enriched.hs_priority?.toUpperCase() || 'MEDIUM'}`);
      console.log('-'.repeat(80));
    }

    // Save enriched deals
    fs.writeFileSync(
      'deals-enriched.json',
      JSON.stringify(enrichedDeals, null, 2)
    );
    console.log(`\n✓ Enriched deals saved to: deals-enriched.json\n`);

    // Step 2: Add to HubSpot
    console.log(`\n[STEP 2] CREATING DEALS IN HUBSPOT CRM\n`);
    for (let i = 0; i < enrichedDeals.length; i++) {
      const deal = enrichedDeals[i];
      console.log(`\n[${i + 1}/${enrichedDeals.length}] Creating: ${deal.dealname}`);
      console.log(`  Amount: $${deal.amount.toLocaleString()}`);
      console.log(`  Priority: ${deal.hs_priority?.toUpperCase() || 'MEDIUM'}`);

      try {
        const response = await hubspotClient.post('/crm/v3/objects/deals', {
          properties: {
            dealname: deal.dealname,
            amount: deal.amount,
            pipeline: deal.pipeline,
            dealstage: deal.dealstage,
            closedate: deal.closedate,
            description: deal.description,
            hs_priority: deal.hs_priority,
            company_name: deal.company_name,
            address: deal.address,
            source: deal.source,
            notes: deal.enrichment_notes
          }
        });

        console.log(`  ✓ Created successfully (ID: ${response.data.id})`);
        createdDeals.push({
          id: response.data.id,
          name: deal.dealname,
          amount: deal.amount,
          priority: deal.hs_priority,
          win_probability: deal.win_probability
        });
      } catch (error) {
        console.error(`  ✗ Failed: ${error.response?.data?.message || error.message}`);
      }

      console.log('-'.repeat(80));
    }

    // Summary
    console.log(`\n${'='.repeat(80)}`);
    console.log(`IMPORT COMPLETE`);
    console.log(`${'='.repeat(80)}\n`);
    console.log(`✓ Successfully created: ${createdDeals.length}/${enrichedDeals.length} deals`);
    console.log(`✓ Total pipeline value: $${createdDeals.reduce((sum, d) => sum + d.amount, 0).toLocaleString()}`);

    const highPriority = createdDeals.filter(d => d.priority === 'high').length;
    console.log(`✓ High priority deals: ${highPriority}`);

    if (createdDeals.some(d => d.win_probability)) {
      const avgWinProb = createdDeals
        .filter(d => d.win_probability)
        .reduce((sum, d) => sum + d.win_probability, 0) / createdDeals.filter(d => d.win_probability).length;
      console.log(`✓ Average win probability: ${avgWinProb.toFixed(1)}%`);
    }

    fs.writeFileSync(
      'hubspot-deals-created.json',
      JSON.stringify(createdDeals, null, 2)
    );
    console.log(`\n✓ Deal IDs saved to: hubspot-deals-created.json\n`);

    return createdDeals;
  } catch (error) {
    console.error('\n❌ ERROR:', error.message);
    throw error;
  }
}

// Execute
addEnrichedDealsToHubSpot()
  .then(deals => {
    console.log(`\n🎉 SUCCESS! Created ${deals.length} enriched deals in HubSpot CRM\n`);
    process.exit(0);
  })
  .catch(error => {
    console.error('\n💥 FAILED:', error.message);
    process.exit(1);
  });
