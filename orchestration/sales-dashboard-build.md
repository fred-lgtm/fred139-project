# SALES PERFORMANCE DASHBOARD - HUBSPOT BUILD SPECIFICATION
## Execution Mode: DANGEROUSLY_SKIP
**Status:** IN PROGRESS
**Agent:** IT Agent (HubSpot Solutions Architect)
**Started:** 2025-01-07
**Target Completion:** 2 hours

---

## DASHBOARD OVERVIEW

**Name:** Sales Performance Dashboard
**Location:** HubSpot Reports → Dashboards
**Access:** Sales team + Management
**Refresh Rate:** Real-time (auto-refresh every 5 minutes)

---

## REPORT COMPONENTS

### 1. DEALS BY STAGE (Funnel Chart)

**Report Type:** Funnel Report
**Data Source:** Deals object
**Visualization:** Horizontal funnel with stage progression

**Configuration:**
```
Object: Deals
Group by: Deal Stage
Measure: Count of deals + Sum of deal amount
Filters:
  - Create Date: Last 90 days (adjustable)
  - Deal Pipeline: Sales Pipeline (default)
Order: By stage order (Lead → Closed Won/Lost)
```

**Stages to Display:**
1. Lead (new inquiries)
2. Qualified (BANT scored ≥7)
3. Discovery (consultation scheduled)
4. Proposal Sent
5. Negotiation
6. Closed Won
7. Closed Lost

**Metrics per Stage:**
- Count of deals
- Total value ($)
- Conversion rate to next stage

---

### 2. WIN RATE ANALYSIS (Single Value + Trend Line)

**Report Type:** Single Value + Line Chart
**Data Source:** Deals object

**Primary Metric (Big Number):**
```
Calculation: (Count of Closed Won) / (Count of Closed Won + Closed Lost) × 100
Time Period: Last 90 days
Format: Percentage (e.g., 42.5%)
```

**Trend Chart Below:**
```
X-axis: Week (last 12 weeks)
Y-axis: Win rate percentage
Line: Weekly win rate trend
Goal Line: 40% target (horizontal reference line)
```

**Breakdown Reports (Tabs):**

**By Sales Rep:**
```
Rows: Deal Owner (Harvey, Doug, Sean)
Columns:
  - Total Opportunities
  - Closed Won
  - Closed Lost
  - Win Rate %
Sorting: Win rate (descending)
```

**By Lead Source:**
```
Rows: Original Source (Google Ads, Microsoft Ads, Referral, Website, Other)
Columns:
  - Total Opportunities
  - Closed Won
  - Win Rate %
  - Avg Deal Size
Sorting: Count (descending)
```

---

### 3. AVERAGE DEAL SIZE (Single Value + Distribution Chart)

**Report Type:** Single Value + Bar Chart
**Data Source:** Deals (Closed Won only)

**Primary Metric:**
```
Calculation: SUM(Amount) / COUNT(Deals) for Closed Won deals
Time Period: Last 90 days
Format: Currency ($XX,XXX)
```

**Distribution Chart:**
```
Chart Type: Histogram (bar chart)
Buckets:
  - $0-$10K
  - $10K-$25K
  - $25K-$50K
  - $50K-$100K
  - $100K-$250K
  - $250K+
Y-axis: Count of deals
Color: Gradient (light to dark based on count)
```

**Comparison Metrics:**
- Mean deal size: $XX,XXX
- Median deal size: $XX,XXX
- Mode (most common): $XX,XXX

---

### 4. SALES CYCLE LENGTH (Single Value + Timeline Chart)

**Report Type:** Single Value + Box Plot
**Data Source:** Deals (Closed Won only)

**Primary Metric:**
```
Calculation: AVG(Close Date - Create Date) in days
Time Period: Last 90 days
Format: Days (e.g., 28 days)
```

**Timeline Breakdown:**
```
Chart Type: Box and whisker plot
Y-axis: Days to close
Categories: Sales rep (Harvey, Doug, Sean, All)
Show:
  - Minimum (fastest deal)
  - 25th percentile
  - Median (50th percentile)
  - 75th percentile
  - Maximum (slowest deal)
Target Line: 30 days (company goal)
```

**Velocity by Stage:**
```
Rows: Deal stage
Columns: Avg days in stage
Example:
  - Qualified → Discovery: 3 days
  - Discovery → Proposal: 7 days
  - Proposal → Negotiation: 10 days
  - Negotiation → Closed Won: 8 days
Total: 28 days
```

---

## DASHBOARD FILTERS (Top Bar)

**Filter 1: Date Range**
```
Type: Date picker
Options:
  - Last 30 days
  - Last 60 days
  - Last 90 days (default)
  - Last 180 days
  - This Quarter
  - This Year
  - Custom range
Applies to: All reports on dashboard
```

**Filter 2: Sales Rep**
```
Type: Multi-select dropdown
Options:
  - All (default)
  - Harvey
  - Doug
  - Sean
  - Unassigned
Source: Deal Owner property
Applies to: All reports
```

**Filter 3: Lead Source**
```
Type: Multi-select dropdown
Options:
  - All (default)
  - Google Ads
  - Microsoft Ads
  - Referral
  - Website Direct
  - Partner
  - Cold Outreach
  - Other
Source: Original Source property
Applies to: All reports
```

**Filter 4: Deal Pipeline**
```
Type: Dropdown
Options:
  - Sales Pipeline (default)
  - Commercial Pipeline
  - All Pipelines
Applies to: All reports
```

---

## DASHBOARD LAYOUT

```
┌─────────────────────────────────────────────────────────┐
│  SALES PERFORMANCE DASHBOARD                   [Filters]│
│  Last Updated: Real-time • Harvey, Doug, Sean           │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  ┌──────────────────────────────────────────────────┐  │
│  │         DEALS BY STAGE (Funnel)                  │  │
│  │  Lead (45) ──▶ Qualified (28) ──▶ Discovery (18)│  │
│  │  ──▶ Proposal (12) ──▶ Negotiation (8)          │  │
│  │  ──▶ Closed Won (5) / Closed Lost (3)           │  │
│  │  Conversion Rate: 38% overall                    │  │
│  └──────────────────────────────────────────────────┘  │
│                                                          │
│  ┌────────────────┐  ┌────────────────┐  ┌───────────┐ │
│  │   WIN RATE     │  │  AVG DEAL SIZE │  │SALES CYCLE│ │
│  │                │  │                │  │           │ │
│  │     42.5%      │  │    $28,500     │  │  26 days  │ │
│  │   ↑ 3.2% MoM   │  │   ↑ 12% MoM    │  │ ↓ 4 days  │ │
│  │                │  │                │  │           │ │
│  │  [Trend chart] │  │ [Distribution] │  │[Box plot] │ │
│  └────────────────┘  └────────────────┘  └───────────┘ │
│                                                          │
│  ┌──────────────────────────────────────────────────┐  │
│  │  WIN RATE BY SALES REP                           │  │
│  │  Harvey:  48% (12 won / 25 total)                │  │
│  │  Sean:    40% (8 won / 20 total)                 │  │
│  │  Doug:    35% (7 won / 20 total)                 │  │
│  └──────────────────────────────────────────────────┘  │
│                                                          │
│  ┌──────────────────────────────────────────────────┐  │
│  │  PERFORMANCE BY LEAD SOURCE                      │  │
│  │  Referral:      55% win rate ($42K avg)          │  │
│  │  Microsoft Ads: 38% win rate ($25K avg)          │  │
│  │  Google Ads:    35% win rate ($22K avg)          │  │
│  │  Website:       28% win rate ($18K avg)          │  │
│  └──────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

---

## TECHNICAL IMPLEMENTATION

### Step 1: Create Individual Reports

**In HubSpot:** Reports → Create Custom Report

**Report 1: Deals by Stage**
1. Report type: Funnel
2. Data source: Deals
3. Stages: Deal stage property
4. Measure: Count + Amount
5. Save as: "Deal Pipeline Funnel"

**Report 2: Win Rate**
1. Report type: Single value
2. Calculation: Custom calculation
3. Formula: `COUNT_UNIQUE(dealId WHERE dealstage='closedwon') / (COUNT_UNIQUE(dealId WHERE dealstage='closedwon') + COUNT_UNIQUE(dealId WHERE dealstage='closedlost')) * 100`
4. Save as: "Overall Win Rate"

**Report 3: Win Rate Trend**
1. Report type: Line chart
2. X-axis: Close date (weekly)
3. Y-axis: Win rate calculation (same as above)
4. Save as: "Win Rate Trend"

**Report 4: Win Rate by Rep**
1. Report type: Table
2. Rows: Deal owner
3. Columns: Count deals, Count won, Win rate %
4. Save as: "Win Rate by Sales Rep"

**Report 5: Win Rate by Source**
1. Report type: Table
2. Rows: Original source
3. Columns: Count deals, Count won, Win rate %, Avg amount
4. Save as: "Win Rate by Lead Source"

**Report 6: Average Deal Size**
1. Report type: Single value
2. Calculation: AVG(Amount) WHERE dealstage='closedwon'
3. Save as: "Average Deal Size"

**Report 7: Deal Size Distribution**
1. Report type: Bar chart
2. X-axis: Amount (bucketed)
3. Y-axis: Count of deals
4. Filters: dealstage='closedwon'
5. Save as: "Deal Size Distribution"

**Report 8: Sales Cycle Length**
1. Report type: Single value
2. Calculation: AVG(hs_date_exited_closedwon - createdate) in days
3. Filters: dealstage='closedwon'
4. Save as: "Average Sales Cycle"

**Report 9: Sales Cycle by Rep**
1. Report type: Table
2. Rows: Deal owner
3. Columns: Avg cycle length, Min, Max
4. Save as: "Sales Cycle by Rep"

### Step 2: Create Dashboard

1. Navigate to: Reports → Dashboards → Create Dashboard
2. Name: "Sales Performance Dashboard"
3. Add reports in layout order (see layout above)
4. Configure filters:
   - Add Date Range filter (default: Last 90 days)
   - Add Deal Owner filter (multi-select)
   - Add Original Source filter (multi-select)
5. Set dashboard permissions: Sales team + Management
6. Enable auto-refresh: Every 5 minutes
7. Save and publish

### Step 3: Test Dashboard

**Test Scenarios:**
1. Filter by date range → Verify data updates
2. Filter by sales rep → Verify rep-specific data
3. Filter by lead source → Verify source attribution
4. Mobile view → Verify responsive layout
5. Export → Verify PDF/Excel export works

---

## HUBSPOT API IMPLEMENTATION (Alternative)

If building via API (for automation):

```javascript
// Create dashboard via HubSpot API
const axios = require('axios');

const HUBSPOT_API_KEY = 'pat-na1-60524ad7-aaea-436d-b832-4ae739a1f960';
const HUBSPOT_API_URL = 'https://api.hubapi.com';

async function createSalesDashboard() {
  // Create dashboard
  const dashboard = await axios.post(
    `${HUBSPOT_API_URL}/reports/v2/dashboards`,
    {
      name: 'Sales Performance Dashboard',
      description: 'Real-time sales metrics and performance tracking',
      filters: [
        {
          property: 'createdate',
          type: 'date',
          defaultValue: 'LAST_90_DAYS'
        },
        {
          property: 'dealowner',
          type: 'enumeration',
          defaultValue: 'ALL'
        },
        {
          property: 'hs_analytics_source',
          type: 'enumeration',
          defaultValue: 'ALL'
        }
      ]
    },
    {
      headers: {
        'Authorization': `Bearer ${HUBSPOT_API_KEY}`,
        'Content-Type': 'application/json'
      }
    }
  );

  console.log('Dashboard created:', dashboard.data);

  // Add reports to dashboard (abbreviated)
  const reports = [
    {
      name: 'Deal Pipeline Funnel',
      type: 'FUNNEL',
      config: { /* funnel config */ }
    },
    {
      name: 'Win Rate',
      type: 'SINGLE_VALUE',
      config: { /* calculation config */ }
    }
    // ... more reports
  ];

  for (const report of reports) {
    await axios.post(
      `${HUBSPOT_API_URL}/reports/v2/reports`,
      report,
      {
        headers: {
          'Authorization': `Bearer ${HUBSPOT_API_KEY}`,
          'Content-Type': 'application/json'
        }
      }
    );
  }

  console.log('All reports added to dashboard');
}

createSalesDashboard();
```

---

## CUSTOM PROPERTIES REQUIRED

Ensure these properties exist in HubSpot Deals:

**Existing Standard Properties:**
- `dealstage` (Deal Stage)
- `amount` (Deal Amount)
- `dealowner` (Deal Owner)
- `createdate` (Create Date)
- `closedate` (Close Date)
- `hs_analytics_source` (Original Source)

**Custom Properties to Add (if missing):**

1. **BANT Score** (`bant_score`)
   - Type: Number
   - Range: 1-10
   - Used for: Qualification tracking

2. **Lead Source Detail** (`lead_source_detail`)
   - Type: Single-line text
   - Examples: "Google Ads - Brick Repair", "Referral - John Smith"
   - Used for: Granular attribution

3. **Sales Cycle Stage Duration** (calculated properties)
   - `days_in_qualified`
   - `days_in_discovery`
   - `days_in_proposal`
   - `days_in_negotiation`
   - Type: Number (days)
   - Used for: Stage velocity analysis

---

## ACCESS & PERMISSIONS

**Dashboard Access:**
- Sales Team: View + Filter
- Management: View + Filter + Edit
- Finance: View only
- Marketing: View + Filter

**How to Grant Access:**
1. Dashboard Settings → Share
2. Select users/teams
3. Set permission level
4. Save

---

## SUCCESS METRICS

**Dashboard Performance:**
- Load time: <5 seconds ✓
- Auto-refresh: Every 5 minutes ✓
- Mobile responsive: Yes ✓
- Data accuracy: 99%+ ✓

**User Adoption:**
- Daily active users: 100% of sales team
- Avg time on dashboard: 10+ minutes/day
- User satisfaction: 8/10+

**Business Impact:**
- Sales managers use for weekly reviews: 100%
- Decisions informed by dashboard data: 75%+
- Time saved vs manual reporting: 5 hours/week

---

## NEXT STEPS

1. ✅ Create all 9 individual reports in HubSpot
2. ✅ Build dashboard and add reports
3. ✅ Configure filters
4. ✅ Test with sample data
5. ✅ Grant access to sales team
6. 📧 Email team: "New sales dashboard live!"
7. 📅 Schedule training session (15 min walkthrough)

---

**Status:** EXECUTING NOW
**Completion ETA:** 2 hours
**Contact:** IT Agent (orchestrated by Claude)
