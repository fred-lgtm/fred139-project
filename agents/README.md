# Claude Subagents System

A comprehensive system for managing specialized Claude AI agents within your development workflow.

## Overview

This directory contains agent profiles that define specialized AI assistants for different aspects of software development. Each agent has specific expertise, responsibilities, and operating guidelines.

## Directory Structure

```
agents/
├── profiles/           # Agent personality and behavior definitions
│   ├── README.md
│   ├── agent-template.md
│   ├── code-reviewer-agent.md
│   ├── test-writer-agent.md
│   ├── documentation-agent.md
│   └── [custom-agent].md
├── config/             # Configuration files
│   └── agent-config.json
├── tools/              # Agent management utilities
├── logs/               # Agent execution logs
└── README.md           # This file
```

## Quick Start

### 1. Using an Existing Agent

In Claude Code, use the Task tool to invoke an agent:

```typescript
// Example: Code review
Task({
  subagent_type: "general-purpose",
  description: "Review authentication code",
  prompt: "Act as the code-reviewer agent (see agents/profiles/code-reviewer-agent.md). Review src/auth/login.ts for security vulnerabilities and best practices."
})
```

### 2. Creating a Custom Agent

1. Copy `profiles/agent-template.md`
2. Fill in all sections with your agent's specifics
3. Save as `profiles/your-agent-name.md`
4. Add to `config/agent-config.json`
5. Invoke using the Task tool

### 3. Agent Invocation Patterns

**Code Review:**
```typescript
Task({
  subagent_type: "general-purpose",
  model: "sonnet",
  description: "Security review of API",
  prompt: "Using the code-reviewer agent profile (agents/profiles/code-reviewer-agent.md), review the API endpoints in src/api/ for security issues, focusing on authentication and authorization."
})
```

**Test Writing:**
```typescript
Task({
  subagent_type: "general-purpose",
  model: "sonnet",
  description: "Write tests for user service",
  prompt: "Using the test-writer agent profile (agents/profiles/test-writer-agent.md), create comprehensive unit tests for src/services/UserService.ts. Include edge cases and error scenarios."
})
```

**Documentation:**
```typescript
Task({
  subagent_type: "general-purpose",
  model: "haiku",
  description: "Document API endpoints",
  prompt: "Using the documentation agent profile (agents/profiles/documentation-agent.md), create API documentation for all endpoints in src/routes/api.ts. Include examples and error codes."
})
```

## Available Agents

### 1. Code Reviewer Agent
**Profile**: [code-reviewer-agent.md](./profiles/code-reviewer-agent.md)
**Purpose**: Reviews code for quality, security, performance, and maintainability
**When to Use**: Before merging PRs, after significant refactoring, security audits

### 2. Test Writer Agent
**Profile**: [test-writer-agent.md](./profiles/test-writer-agent.md)
**Purpose**: Creates comprehensive test suites with good coverage
**When to Use**: New features, bug fixes, refactored code

### 3. Documentation Agent
**Profile**: [documentation-agent.md](./profiles/documentation-agent.md)
**Purpose**: Generates clear, comprehensive documentation
**When to Use**: New APIs, complex features, onboarding materials

## Agent Capabilities

### What Agents Can Do
- ✅ Read and analyze code across your codebase
- ✅ Suggest improvements and best practices
- ✅ Write new code (tests, docs, refactors)
- ✅ Identify security vulnerabilities
- ✅ Follow project-specific patterns and styles
- ✅ Escalate to humans when needed

### What Agents Cannot Do
- ❌ Make production deployments
- ❌ Access external systems (unless explicitly configured)
- ❌ Override explicit security policies
- ❌ Make business decisions
- ❌ Commit code without review (unless auto-approved)

## Configuration

### Agent Settings

Edit [config/agent-config.json](./config/agent-config.json) to configure:

```json
{
  "activeAgents": [
    {
      "name": "code-reviewer",
      "profile": "code-reviewer-agent.md",
      "status": "active",
      "model": "sonnet"
    }
  ],
  "settings": {
    "defaultModel": "sonnet",
    "maxTokens": 100000,
    "temperature": 0.7
  }
}
```

### Model Selection

- **Sonnet** - Best for complex tasks (code review, architecture)
- **Haiku** - Fast for simpler tasks (documentation, formatting)
- **Opus** - Most capable for critical decisions (use sparingly)

## Best Practices

### 1. Be Specific in Prompts
❌ Bad: "Review this code"
✅ Good: "Review src/auth.ts for SQL injection vulnerabilities and authentication bypass risks"

### 2. Provide Context
Include relevant information:
- Business requirements
- Technical constraints
- Existing patterns in codebase
- Target audience (if docs)

### 3. Use Appropriate Model
- Use Haiku for straightforward tasks to save costs
- Use Sonnet for complex reasoning
- Reserve Opus for critical decisions

### 4. Review Agent Output
- Agents are assistants, not replacements
- Always review suggested changes
- Test generated code
- Verify documentation accuracy

### 5. Update Profiles
- Refine based on actual performance
- Add examples of good/bad interactions
- Update domain knowledge as project evolves

## Workflow Integration

### In Pull Requests

```bash
# 1. Make your changes
git checkout -b feature/new-endpoint

# 2. Use test-writer agent
# [Invoke via Claude Code Task tool]

# 3. Use code-reviewer agent
# [Invoke via Claude Code Task tool]

# 4. Address feedback and commit
git add .
git commit -m "Add new endpoint with tests"

# 5. Push and create PR
git push origin feature/new-endpoint
```

### In Development Cycle

1. **Planning**: Discuss with agents for approach
2. **Implementation**: Write code yourself or with agent assistance
3. **Testing**: Use test-writer agent
4. **Review**: Use code-reviewer agent
5. **Documentation**: Use documentation agent
6. **Deploy**: Human review and approval

## Troubleshooting

### Agent Not Following Profile
- Ensure you're referencing the profile in your prompt
- Check that profile path is correct
- Verify profile has clear instructions

### Agent Responses Too Verbose
- Use Haiku model for simpler tasks
- Add "be concise" to your prompt
- Update agent profile to specify brevity

### Agent Missing Context
- Provide more background in prompt
- Update agent's Knowledge Base section
- Include relevant file paths or code snippets

## Examples

### Full Code Review Workflow

```typescript
// Step 1: Request comprehensive review
Task({
  subagent_type: "general-purpose",
  model: "sonnet",
  description: "Full review of authentication module",
  prompt: `
    Using the code-reviewer agent profile (agents/profiles/code-reviewer-agent.md):

    Review the authentication module (src/auth/*) for:
    1. Security vulnerabilities (especially SQL injection, XSS, auth bypass)
    2. Code quality and maintainability
    3. Performance issues
    4. Missing error handling
    5. Test coverage gaps

    Context:
    - This handles user login for a financial application
    - Security is critical (PCI compliance required)
    - Expected load: 1000 requests/second

    Provide:
    - Critical issues (must fix before merge)
    - Important improvements (should fix soon)
    - Nice-to-have suggestions (backlog)
  `
})
```

### Test Generation Workflow

```typescript
// Step 2: Generate comprehensive tests
Task({
  subagent_type: "general-purpose",
  model: "sonnet",
  description: "Create test suite for UserService",
  prompt: `
    Using the test-writer agent profile (agents/profiles/test-writer-agent.md):

    Create a comprehensive test suite for src/services/UserService.ts.

    Requirements:
    - Unit tests for all public methods
    - Integration tests for database operations
    - Test fixtures for common scenarios
    - Edge cases: null values, invalid input, race conditions
    - Target: 90%+ coverage

    Testing framework: Jest
    Database: PostgreSQL (use test container)

    Include:
    - Happy path tests
    - Error scenarios
    - Boundary conditions
    - Concurrent operation handling
  `
})
```

### Documentation Workflow

```typescript
// Step 3: Generate documentation
Task({
  subagent_type: "general-purpose",
  model: "haiku",
  description: "Document API endpoints",
  prompt: `
    Using the documentation agent profile (agents/profiles/documentation-agent.md):

    Create API documentation for src/routes/user.ts.

    Audience: Frontend developers integrating with our API

    Include:
    - Endpoint descriptions
    - Request/response examples
    - Error codes and handling
    - Authentication requirements
    - Rate limiting info

    Format: OpenAPI 3.0 spec + Markdown guide
  `
})
```

## Contributing

### Adding New Agent Profiles

1. Identify a recurring need or specialized domain
2. Copy `profiles/agent-template.md`
3. Fill in all sections thoroughly
4. Test with real prompts
5. Iterate based on results
6. Add to `config/agent-config.json`
7. Update this README

### Improving Existing Agents

1. Note issues or limitations in usage
2. Update profile with clearer instructions
3. Add examples of desired behavior
4. Test changes
5. Update version history in profile

## Resources

- [Agent Profile Template](./profiles/agent-template.md)
- [Agent Configuration](./config/agent-config.json)
- [Claude Code Documentation](https://docs.claude.com/claude-code)
- [Brickface Enterprise Agent Examples](C:\Users\frede\Documents\brickface-enterprise\agents\profiles)

---

**Need help?** Open an issue or consult the individual agent profile READMEs.

**Last Updated**: 2025-01-06
