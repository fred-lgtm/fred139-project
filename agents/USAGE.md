# How to Use Claude Subagents

A practical guide with real examples for invoking and working with Claude subagents.

## Quick Reference

### Basic Agent Invocation

```typescript
Task({
  subagent_type: "general-purpose",
  model: "sonnet", // or "haiku" or "opus"
  description: "Brief description of task",
  prompt: "Using the [agent-name] profile (agents/profiles/[agent-name].md), [detailed instructions]"
})
```

## Common Patterns

### Pattern 1: Code Review

**Use Case**: Review code before merging

```typescript
Task({
  subagent_type: "general-purpose",
  model: "sonnet",
  description: "Security review of payment flow",
  prompt: `
    Using the code-reviewer agent profile (agents/profiles/code-reviewer-agent.md):

    Review the payment processing code in src/payments/ for:
    - Security vulnerabilities
    - PCI compliance
    - Error handling
    - Transaction atomicity

    Focus on:
    - src/payments/processor.ts
    - src/payments/validator.ts
    - src/payments/webhook.ts

    This code handles real money transactions, so security is critical.
  `
})
```

### Pattern 2: Test Generation

**Use Case**: Generate tests for new feature

```typescript
Task({
  subagent_type: "general-purpose",
  model: "sonnet",
  description: "Generate tests for shopping cart",
  prompt: `
    Using the test-writer agent profile (agents/profiles/test-writer-agent.md):

    Create unit tests for src/cart/ShoppingCart.ts.

    Test scenarios:
    1. Adding items to cart
    2. Removing items
    3. Updating quantities
    4. Calculating totals with discounts
    5. Handling out-of-stock items
    6. Concurrent modifications

    Use Jest and include test fixtures for products and discounts.
    Target: 90%+ code coverage
  `
})
```

### Pattern 3: Documentation

**Use Case**: Document a new API

```typescript
Task({
  subagent_type: "general-purpose",
  model: "haiku", // Documentation is a good fit for Haiku
  description: "Document webhook API",
  prompt: `
    Using the documentation agent profile (agents/profiles/documentation-agent.md):

    Create API documentation for the webhook system in src/webhooks/.

    Audience: External developers integrating with our platform

    Include:
    - How to register webhooks
    - Available webhook events
    - Payload formats for each event
    - Security (signature verification)
    - Retry logic
    - Example implementations in JavaScript and Python

    Format: Markdown suitable for docs site
  `
})
```

## Advanced Usage

### Chaining Agents

Run multiple agents sequentially for complex workflows:

```typescript
// Step 1: Generate implementation
Task({
  subagent_type: "general-purpose",
  model: "sonnet",
  description: "Implement user search feature",
  prompt: "Implement a user search API endpoint with filters for name, email, role, and date range. Use TypeScript, Express, and PostgreSQL."
})

// Step 2: Generate tests (after implementation is done)
Task({
  subagent_type: "general-purpose",
  model: "sonnet",
  description: "Generate tests for user search",
  prompt: `
    Using the test-writer agent profile:
    Create comprehensive tests for the user search endpoint we just implemented.
    Include edge cases like empty results, invalid filters, and SQL injection attempts.
  `
})

// Step 3: Review everything
Task({
  subagent_type: "general-purpose",
  model: "sonnet",
  description: "Review user search implementation",
  prompt: `
    Using the code-reviewer agent profile:
    Review the user search feature we just implemented, including tests.
    Focus on security (SQL injection), performance (query optimization), and code quality.
  `
})

// Step 4: Document it
Task({
  subagent_type: "general-purpose",
  model: "haiku",
  description: "Document user search API",
  prompt: `
    Using the documentation agent profile:
    Create API documentation for the user search endpoint.
    Include all query parameters, response formats, and example requests.
  `
})
```

### Parallel Agent Execution

Run multiple independent agents at once:

```typescript
// Review multiple modules simultaneously
// Send all in a single message with multiple Task calls

Task({
  subagent_type: "general-purpose",
  description: "Review auth module",
  prompt: "Using code-reviewer agent, review src/auth/ for security issues"
})

Task({
  subagent_type: "general-purpose",
  description: "Review payment module",
  prompt: "Using code-reviewer agent, review src/payments/ for security issues"
})

Task({
  subagent_type: "general-purpose",
  description: "Review API module",
  prompt: "Using code-reviewer agent, review src/api/ for security issues"
})
```

### Agent with Custom Instructions

Extend agent behavior for specific contexts:

```typescript
Task({
  subagent_type: "general-purpose",
  model: "sonnet",
  description: "Review with custom security requirements",
  prompt: `
    Using the code-reviewer agent profile (agents/profiles/code-reviewer-agent.md):

    Review src/admin/users.ts

    In addition to your standard review checklist, also verify:
    1. Admin-only functions require SuperAdmin role (not just Admin)
    2. All user deletions are soft deletes (set deleted_at, don't actually delete)
    3. Audit logs are created for all admin actions
    4. Rate limiting is applied (max 100 requests/min per admin)

    This is for a financial services platform, so compliance is critical.
  `
})
```

## Real-World Scenarios

### Scenario 1: Onboarding New Developer

Create comprehensive documentation for your codebase:

```typescript
Task({
  subagent_type: "general-purpose",
  model: "sonnet",
  description: "Create onboarding documentation",
  prompt: `
    Using the documentation agent profile:

    Create a comprehensive onboarding guide for new developers.

    Cover:
    1. Architecture overview (see src/architecture.md)
    2. Development environment setup
    3. Running tests and linting
    4. Database migrations
    5. Common development workflows
    6. Code style and conventions
    7. How to submit PRs

    Make it friendly for junior developers but comprehensive enough for seniors.
    Include troubleshooting for common setup issues.
  `
})
```

### Scenario 2: Security Audit

Comprehensive security review:

```typescript
Task({
  subagent_type: "general-purpose",
  model: "opus", // Use Opus for critical security review
  description: "Comprehensive security audit",
  prompt: `
    Using the code-reviewer agent profile with security focus:

    Perform a comprehensive security audit of our application.

    Review:
    - Authentication and authorization (src/auth/)
    - Payment processing (src/payments/)
    - User input handling (all controllers)
    - Data encryption (src/crypto/)
    - API security (src/api/)

    Check for:
    - SQL injection
    - XSS vulnerabilities
    - Authentication bypass
    - Authorization flaws
    - Insecure cryptography
    - Sensitive data exposure
    - CSRF vulnerabilities
    - Insecure dependencies

    Prioritize findings by severity (Critical, High, Medium, Low).
    Provide specific remediation steps for each issue.
  `
})
```

### Scenario 3: Legacy Code Refactoring

Improve old code while maintaining behavior:

```typescript
// Step 1: Review current state
Task({
  subagent_type: "general-purpose",
  model: "sonnet",
  description: "Analyze legacy code",
  prompt: `
    Using the code-reviewer agent profile:

    Analyze src/legacy/order-processor.js (800 lines, no tests, written in 2015).

    Identify:
    1. Main responsibilities (what does it actually do?)
    2. Dependencies and side effects
    3. Business logic that must be preserved
    4. Code smells and technical debt
    5. Testing strategy before refactoring

    Do NOT suggest changes yet, just analyze.
  `
})

// Step 2: Generate tests for current behavior
Task({
  subagent_type: "general-purpose",
  model: "sonnet",
  description: "Create characterization tests",
  prompt: `
    Using the test-writer agent profile:

    Create "characterization tests" for src/legacy/order-processor.js.

    These tests should:
    1. Document current behavior (even if buggy)
    2. Cover all code paths
    3. Use real-world test data
    4. Serve as regression tests during refactoring

    Do NOT fix bugs yet, just test what currently exists.
  `
})

// Step 3: Plan refactoring
Task({
  subagent_type: "general-purpose",
  model: "sonnet",
  description: "Plan refactoring strategy",
  prompt: `
    Based on the analysis and tests, create a refactoring plan for src/legacy/order-processor.js.

    Plan should:
    1. Break file into smaller modules
    2. Extract business logic from infrastructure
    3. Modernize to TypeScript
    4. Improve naming and structure
    5. Add proper error handling

    Provide step-by-step approach that can be done incrementally (no big bang rewrite).
  `
})
```

### Scenario 4: API Design Review

Review API design before implementation:

```typescript
Task({
  subagent_type: "general-purpose",
  model: "sonnet",
  description: "Review API design",
  prompt: `
    Using the code-reviewer agent profile:

    Review the proposed API design in docs/api-spec.md.

    Evaluate:
    1. RESTful design principles
    2. Naming consistency
    3. Error handling approach
    4. Pagination strategy
    5. Versioning strategy
    6. Authentication/authorization model
    7. Rate limiting approach
    8. Backward compatibility

    Consider:
    - Ease of use for frontend developers
    - Performance implications
    - Future extensibility

    Suggest improvements before we start implementation.
  `
})
```

## Tips & Tricks

### 1. Be Specific About Context

❌ **Vague**: "Review this code"
```typescript
Task({
  prompt: "Review src/auth.ts"
})
```

✅ **Specific**: Provide context
```typescript
Task({
  prompt: `
    Using code-reviewer agent:
    Review src/auth.ts for a financial services application.
    We've had issues with session fixation attacks in the past.
    Focus on session management and cookie security.
  `
})
```

### 2. Specify Output Format

```typescript
Task({
  prompt: `
    Using code-reviewer agent:
    Review src/payments/ and provide output in this format:

    ## Critical Issues (Block Merge)
    - [Issue with file:line reference]

    ## High Priority
    - [Issue with file:line reference]

    ## Suggestions
    - [Improvement ideas]

    Include code snippets for suggested fixes.
  `
})
```

### 3. Use Appropriate Model

- **Haiku** - Documentation, simple refactoring, formatting
- **Sonnet** - Code review, test generation, complex refactoring
- **Opus** - Security audits, architecture decisions, critical reviews

### 4. Provide Examples

```typescript
Task({
  prompt: `
    Using test-writer agent:
    Create tests for src/calculator.ts.

    Follow this style:
    describe('Calculator', () => {
      describe('add', () => {
        it('should return sum of positive numbers', () => {
          expect(calculator.add(2, 3)).toBe(5);
        });
      });
    });

    Use this fixture pattern:
    const testData = { /* ... */ };
  `
})
```

### 5. Iterate on Agent Profiles

If an agent consistently misses something, update its profile:

```markdown
## Common Mistakes to Avoid
- Forgetting to validate user input
- Not checking for null/undefined
- Missing error handling in async functions
```

## Troubleshooting

### Agent Output Not Helpful

**Problem**: Agent gives generic advice

**Solution**: Add more context
```typescript
Task({
  prompt: `
    Context: This is a real-time bidding system handling $1M+/day.
    Latency must be under 50ms. We use Redis for caching.

    Using code-reviewer agent:
    Review src/bidding/auction.ts for performance issues.
  `
})
```

### Agent Suggests Unrealistic Changes

**Problem**: Agent suggests complete rewrites

**Solution**: Set constraints
```typescript
Task({
  prompt: `
    Using code-reviewer agent:
    Review with these constraints:
    - Must maintain backward compatibility
    - No breaking API changes
    - Changes must be deployable incrementally
    - Can't add new dependencies

    Review src/api/v1/users.ts
  `
})
```

### Agent Misses Domain-Specific Issues

**Problem**: Agent doesn't know your domain

**Solution**: Update agent profile or provide domain context
```typescript
Task({
  prompt: `
    Domain context:
    - We're a healthcare app (HIPAA compliant)
    - Patient data must be encrypted at rest
    - All access must be logged for auditing
    - Data retention is 7 years

    Using code-reviewer agent:
    Review src/patients/ with healthcare compliance in mind.
  `
})
```

## Next Steps

1. **Start Simple**: Use code-reviewer agent on one file
2. **Refine Prompts**: Note what works and what doesn't
3. **Update Profiles**: Add examples and context as you learn
4. **Create Custom Agents**: Build agents for your specific domain
5. **Integrate into Workflow**: Make agents part of your daily development

---

**More Examples**: See [examples/](./examples/) directory for full workflow examples

**Questions?**: Open an issue or check the main [README.md](./README.md)
