# Claude Subagents - Quick Start

Get up and running with Claude subagents in 5 minutes.

## What Are Subagents?

Subagents are specialized Claude AI assistants with specific roles, expertise, and behaviors. Think of them as team members you can invoke for specific tasks.

## Available Agents

| Agent | Purpose | Model | Use When |
|-------|---------|-------|----------|
| **Code Reviewer** | Reviews code for quality & security | Sonnet | Before merging, security audits |
| **Test Writer** | Creates comprehensive tests | Sonnet | New features, refactoring |
| **Documentation** | Generates clear documentation | Haiku | New APIs, onboarding docs |

## How to Use

### Step 1: Invoke an Agent

In Claude Code, use the Task tool:

```typescript
Task({
  subagent_type: "general-purpose",
  model: "sonnet",
  description: "Review authentication code",
  prompt: "Using the code-reviewer agent profile (agents/profiles/code-reviewer-agent.md), review src/auth.ts for security vulnerabilities"
})
```

### Step 2: Review the Output

The agent will:
1. Read your code
2. Apply its specialized knowledge
3. Provide detailed feedback
4. Suggest specific improvements

### Step 3: Take Action

- Fix critical issues immediately
- Plan for suggested improvements
- Update your code
- Re-run agent if needed

## Quick Examples

### Code Review
```typescript
Task({
  subagent_type: "general-purpose",
  model: "sonnet",
  description: "Security review",
  prompt: "Using code-reviewer agent (agents/profiles/code-reviewer-agent.md), review src/api/ for SQL injection and XSS vulnerabilities"
})
```

### Generate Tests
```typescript
Task({
  subagent_type: "general-purpose",
  model: "sonnet",
  description: "Create test suite",
  prompt: "Using test-writer agent (agents/profiles/test-writer-agent.md), create unit tests for src/services/UserService.ts with 90% coverage"
})
```

### Create Documentation
```typescript
Task({
  subagent_type: "general-purpose",
  model: "haiku",
  description: "Document API",
  prompt: "Using documentation agent (agents/profiles/documentation-agent.md), create API docs for src/routes/users.ts with examples"
})
```

## Best Practices

### ✅ Do This
- Be specific about what you want reviewed/created
- Provide context (tech stack, constraints, requirements)
- Reference the agent profile explicitly
- Review agent output before applying

### ❌ Don't Do This
- Don't be vague ("review this")
- Don't skip providing context
- Don't blindly apply suggestions without review
- Don't forget to test generated code

## File Structure

```
agents/
├── profiles/              # Agent definitions
│   ├── code-reviewer-agent.md
│   ├── test-writer-agent.md
│   ├── documentation-agent.md
│   └── agent-template.md
├── config/
│   └── agent-config.json  # Agent settings
├── README.md              # Full documentation
├── USAGE.md               # Detailed examples
└── QUICKSTART.md          # This file
```

## Creating Custom Agents

1. **Copy Template**
   ```bash
   cp agents/profiles/agent-template.md agents/profiles/my-agent.md
   ```

2. **Fill In Details**
   - Core identity and role
   - Goals and success metrics
   - Behavior guidelines
   - Knowledge base
   - Example interactions

3. **Add to Config**
   Edit `agents/config/agent-config.json`:
   ```json
   {
     "activeAgents": [
       {
         "name": "my-agent",
         "profile": "my-agent.md",
         "status": "active",
         "model": "sonnet"
       }
     ]
   }
   ```

4. **Use It**
   ```typescript
   Task({
     prompt: "Using my-agent profile (agents/profiles/my-agent.md), [task description]"
   })
   ```

## Common Workflows

### New Feature
1. Implement the feature
2. Use **test-writer** agent for tests
3. Use **code-reviewer** agent for review
4. Use **documentation** agent for docs

### Bug Fix
1. Fix the bug
2. Use **test-writer** agent for regression tests
3. Use **code-reviewer** agent to verify fix

### Refactoring
1. Use **code-reviewer** agent to analyze current code
2. Use **test-writer** agent for characterization tests
3. Refactor
4. Re-run agents to verify

### Security Audit
1. Use **code-reviewer** agent with security focus
2. Fix critical issues
3. Re-run review
4. Document security measures

## Model Selection Guide

| Model | Speed | Cost | Best For |
|-------|-------|------|----------|
| **Haiku** | Fast | Low | Documentation, simple tasks |
| **Sonnet** | Medium | Medium | Code review, test writing, complex tasks |
| **Opus** | Slow | High | Critical security audits, architecture |

**Recommendation**: Start with Sonnet for most tasks, use Haiku for docs.

## Next Steps

1. **Try It**: Run code-reviewer agent on one file
2. **Explore**: Read full [USAGE.md](./USAGE.md) for advanced patterns
3. **Customize**: Create your first custom agent
4. **Integrate**: Make agents part of your daily workflow

## Getting Help

- **Full Documentation**: [README.md](./README.md)
- **Detailed Examples**: [USAGE.md](./USAGE.md)
- **Agent Profiles**: [profiles/](./profiles/)
- **Brickface Examples**: `C:\Users\frede\Documents\brickface-enterprise\agents\profiles`

---

**You're ready to go!** Start with a simple code review and build from there.
