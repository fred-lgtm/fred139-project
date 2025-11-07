# Complete Example: Building a Feature with Agents

This example shows a complete workflow using all three agents to build and ship a new feature.

## Scenario

You need to add a password reset feature to your application.

---

## Step 1: Planning (Optional)

First, think through what you need:
- API endpoint for password reset request
- Email sending logic
- Token generation and validation
- Database schema for reset tokens

---

## Step 2: Implementation

Implement the feature yourself or with Claude's help:

```typescript
// src/auth/passwordReset.ts
import { db } from '../db';
import { sendEmail } from '../email';
import { randomBytes } from 'crypto';

export async function requestPasswordReset(email: string) {
  const user = await db.users.findByEmail(email);
  if (!user) return; // Don't reveal if user exists

  const token = randomBytes(32).toString('hex');
  const expires = new Date(Date.now() + 3600000); // 1 hour

  await db.resetTokens.create({
    userId: user.id,
    token,
    expires
  });

  await sendEmail({
    to: email,
    subject: 'Password Reset Request',
    body: `Reset link: https://app.com/reset?token=${token}`
  });
}
```

---

## Step 3: Generate Tests

**Invoke the test-writer agent:**

```typescript
Task({
  subagent_type: "general-purpose",
  model: "sonnet",
  description: "Generate tests for password reset",
  prompt: `
    Using the test-writer agent profile (agents/profiles/test-writer-agent.md):

    Create comprehensive tests for src/auth/passwordReset.ts.

    Test cases to cover:
    1. Successful password reset request
    2. Non-existent email (should not reveal this)
    3. Multiple requests (should invalidate old tokens)
    4. Expired tokens
    5. Invalid tokens
    6. Email sending failure handling
    7. Database transaction handling

    Use Jest and include:
    - Unit tests with mocked dependencies
    - Integration tests with test database
    - Test fixtures for users and tokens

    Target: 95%+ coverage for this security-critical code
  `
})
```

**Agent Output:**

The agent creates:
- `tests/auth/passwordReset.test.ts` - Comprehensive test suite
- `tests/fixtures/users.ts` - Test user data
- `tests/fixtures/resetTokens.ts` - Test token data

---

## Step 4: Run Tests

```bash
npm test
```

Fix any failing tests and iterate.

---

## Step 5: Code Review

**Invoke the code-reviewer agent:**

```typescript
Task({
  subagent_type: "general-purpose",
  model: "sonnet",
  description: "Security review of password reset",
  prompt: `
    Using the code-reviewer agent profile (agents/profiles/code-reviewer-agent.md):

    Review src/auth/passwordReset.ts for security vulnerabilities.

    This is a password reset feature, so please focus on:
    1. Timing attacks (don't reveal if user exists)
    2. Token strength and randomness
    3. Token expiration handling
    4. Rate limiting (prevent abuse)
    5. Email injection vulnerabilities
    6. Token leakage in logs or errors

    Context:
    - This is for a financial services application
    - We've had issues with account takeovers in the past
    - Compliance requires audit logging for all password changes

    Provide:
    - Critical issues (must fix)
    - Security improvements (should fix)
    - Best practice suggestions
  `
})
```

**Agent Response:**

```markdown
# Code Review: Password Reset Feature

## Critical Issues 🚨

### 1. Token Should Be Hashed
**Location**: `passwordReset.ts:12`

**Issue**: Storing reset tokens in plain text. If database is compromised,
attacker can reset any user's password.

**Fix**:
\`\`\`typescript
import { hash } from 'bcrypt';

const token = randomBytes(32).toString('hex');
const hashedToken = await hash(token, 10);

await db.resetTokens.create({
  userId: user.id,
  token: hashedToken, // Store hashed version
  expires
});
\`\`\`

Send the plain token to user via email, but store only the hash.

### 2. Missing Rate Limiting
**Location**: `passwordReset.ts:8`

**Issue**: No rate limiting allows attacker to spam reset requests.

**Fix**: Add rate limiting middleware
\`\`\`typescript
import rateLimit from 'express-rate-limit';

const resetLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 3, // 3 requests per window
  message: 'Too many reset requests, please try again later'
});

app.post('/api/reset-password', resetLimiter, handleReset);
\`\`\`

## High Priority Issues ⚠️

### 3. Invalidate Old Tokens
**Location**: `passwordReset.ts:15`

**Issue**: Multiple requests create multiple valid tokens.

**Fix**:
\`\`\`typescript
// Invalidate any existing tokens first
await db.resetTokens.deleteMany({
  userId: user.id,
  expires: { $gt: new Date() }
});

// Then create new token
await db.resetTokens.create({ ... });
\`\`\`

### 4. Missing Audit Logging
**Issue**: No logging for password reset attempts.

**Fix**:
\`\`\`typescript
await auditLog.create({
  event: 'PASSWORD_RESET_REQUESTED',
  userId: user.id,
  email,
  ip: req.ip,
  timestamp: new Date()
});
\`\`\`

## Suggestions 💡

1. Add email template validation to prevent injection
2. Consider shorter expiration (15 minutes vs. 1 hour)
3. Send confirmation email after successful reset
4. Add "reset from new device" warning
```

---

## Step 6: Fix Issues

Address all critical and high-priority issues from the review.

```typescript
// Updated implementation after review
import { hash, compare } from 'bcrypt';
import { randomBytes } from 'crypto';
import rateLimit from 'express-rate-limit';

const resetLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 3
});

export async function requestPasswordReset(email: string, ipAddress: string) {
  const user = await db.users.findByEmail(email);

  // Audit all attempts, even for non-existent emails
  await auditLog.create({
    event: 'PASSWORD_RESET_REQUESTED',
    email,
    userId: user?.id,
    ip: ipAddress,
    timestamp: new Date()
  });

  if (!user) {
    // Wait same amount of time to prevent timing attacks
    await delay(200);
    return;
  }

  // Invalidate existing tokens
  await db.resetTokens.deleteMany({
    userId: user.id,
    expires: { $gt: new Date() }
  });

  // Generate and hash token
  const token = randomBytes(32).toString('hex');
  const hashedToken = await hash(token, 10);
  const expires = new Date(Date.now() + 900000); // 15 minutes

  await db.resetTokens.create({
    userId: user.id,
    token: hashedToken,
    expires
  });

  await sendEmail({
    to: email,
    subject: 'Password Reset Request',
    template: 'password-reset',
    data: {
      resetLink: `https://app.com/reset?token=${token}`,
      expiresIn: '15 minutes'
    }
  });
}
```

---

## Step 7: Update Tests

Update tests to match the new implementation:

```typescript
Task({
  subagent_type: "general-purpose",
  model: "sonnet",
  description: "Update tests after review fixes",
  prompt: `
    Using the test-writer agent:

    Update tests/auth/passwordReset.test.ts to cover the changes we made:
    1. Token hashing
    2. Rate limiting
    3. Audit logging
    4. Old token invalidation
    5. Timing attack prevention

    Ensure all tests still pass.
  `
})
```

---

## Step 8: Generate Documentation

**Invoke the documentation agent:**

```typescript
Task({
  subagent_type: "general-purpose",
  model: "haiku",
  description: "Document password reset API",
  prompt: `
    Using the documentation agent profile (agents/profiles/documentation-agent.md):

    Create API documentation for the password reset feature.

    Audience: Frontend developers who will integrate this

    Document:
    1. POST /api/auth/reset-request - Request reset
    2. POST /api/auth/reset-confirm - Confirm with token
    3. Rate limiting details
    4. Error codes and handling
    5. Security considerations

    Include:
    - Request/response examples
    - Error scenarios
    - Code examples in JavaScript
    - Security best practices for frontend
  `
})
```

**Agent Output:**

```markdown
# Password Reset API

## Overview

The password reset feature allows users to securely reset their passwords
via email verification.

## Endpoints

### 1. Request Password Reset

\`\`\`
POST /api/auth/reset-request
\`\`\`

Initiates a password reset by sending a reset link to the user's email.

#### Request

\`\`\`json
{
  "email": "user@example.com"
}
\`\`\`

#### Response

**Success (200)**:
\`\`\`json
{
  "message": "If an account exists, a reset link has been sent"
}
\`\`\`

Note: Response is same whether user exists or not (security measure).

#### Rate Limiting

- Maximum 3 requests per 15 minutes per IP
- Returns 429 if limit exceeded

#### Example

\`\`\`javascript
async function requestReset(email) {
  const response = await fetch('/api/auth/reset-request', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email })
  });

  if (response.ok) {
    alert('Check your email for reset instructions');
  } else if (response.status === 429) {
    alert('Too many attempts. Please try again later.');
  }
}
\`\`\`

### 2. Confirm Password Reset

\`\`\`
POST /api/auth/reset-confirm
\`\`\`

Completes the password reset using the token from email.

#### Request

\`\`\`json
{
  "token": "abc123...",
  "newPassword": "NewSecurePass123!"
}
\`\`\`

#### Response

**Success (200)**:
\`\`\`json
{
  "message": "Password has been reset successfully"
}
\`\`\`

**Error (400)**:
\`\`\`json
{
  "error": "INVALID_TOKEN",
  "message": "Reset token is invalid or expired"
}
\`\`\`

## Security Considerations

### For Frontend Developers

1. **Always use HTTPS** - Never send tokens over HTTP
2. **Don't log tokens** - Exclude from error logging
3. **Clear form after success** - Don't keep sensitive data in state
4. **Show generic messages** - Don't reveal if email exists
5. **Implement client-side rate limiting** - Prevent accidental spam

### Token Expiration

- Tokens expire after 15 minutes
- Only one token is valid at a time per user
- Requesting a new reset invalidates previous tokens

### Example: Secure Implementation

\`\`\`javascript
import { useState } from 'react';

function PasswordResetForm() {
  const [email, setEmail] = useState('');
  const [status, setStatus] = useState('');

  async function handleSubmit(e) {
    e.preventDefault();

    try {
      const response = await fetch('/api/auth/reset-request', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email })
      });

      // Generic message regardless of outcome
      setStatus('If an account exists, check your email');

      // Clear form for security
      setEmail('');
    } catch (error) {
      // Don't reveal specific error
      setStatus('An error occurred. Please try again.');
      console.error('Reset error', error); // Log error, not email
    }
  }

  return (
    <form onSubmit={handleSubmit}>
      <input
        type="email"
        value={email}
        onChange={(e) => setEmail(e.target.value)}
        required
      />
      <button type="submit">Reset Password</button>
      {status && <p>{status}</p>}
    </form>
  );
}
\`\`\`

## Error Codes

| Code | Status | Meaning |
|------|--------|---------|
| INVALID_TOKEN | 400 | Token is invalid or expired |
| RATE_LIMIT_EXCEEDED | 429 | Too many requests |
| INVALID_PASSWORD | 400 | Password doesn't meet requirements |
| SERVER_ERROR | 500 | Internal server error |
```

---

## Step 9: Final Review

One more review to ensure everything is good:

```typescript
Task({
  subagent_type: "general-purpose",
  model: "sonnet",
  description: "Final review before merge",
  prompt: `
    Using the code-reviewer agent:

    Final review of the password reset feature before merging.

    Files to review:
    - src/auth/passwordReset.ts (implementation)
    - tests/auth/passwordReset.test.ts (tests)
    - docs/api/password-reset.md (documentation)

    Verify:
    - All security issues addressed
    - Tests cover all scenarios
    - Documentation is accurate
    - Code is ready for production

    Give go/no-go for merge.
  `
})
```

---

## Step 10: Ship It!

```bash
# Commit your changes
git add .
git commit -m "Add secure password reset feature

- Implement password reset with hashed tokens
- Add rate limiting (3 requests per 15 min)
- Add audit logging for security
- Include comprehensive tests (95% coverage)
- Add API documentation for frontend team

Reviewed by code-reviewer agent
Tests generated by test-writer agent
Docs created by documentation agent"

# Push and create PR
git push origin feature/password-reset
gh pr create --title "Add password reset feature" \
  --body "See commit message for details"
```

---

## Summary

**What We Built:**
- Secure password reset feature
- 95%+ test coverage
- Complete API documentation
- Security audit approved

**Agents Used:**
1. **Test Writer** - Generated comprehensive tests
2. **Code Reviewer** - Found 4 critical security issues
3. **Documentation** - Created API docs for frontend team

**Time Saved:**
- Writing tests manually: ~2 hours
- Security review: ~1 hour
- Documentation: ~1 hour
- **Total: ~4 hours**

**Quality Improvements:**
- Found security issues before production
- Better test coverage than typical manual tests
- Professional documentation ready for team

---

## Key Takeaways

1. **Agents catch issues early** - Found security problems before code review
2. **Tests are more comprehensive** - Agent considers edge cases you might miss
3. **Documentation is consistent** - Follows best practices automatically
4. **Workflow is repeatable** - Use same process for every feature

## Next Steps

- Use this workflow for your next feature
- Customize agents for your specific domain
- Create project-specific agent profiles
- Integrate agents into CI/CD pipeline

---

**This is the power of Claude subagents!** 🚀
