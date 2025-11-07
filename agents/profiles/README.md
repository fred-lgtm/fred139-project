# Claude Subagent Profiles

> **Configure your AI subagents' personalities, goals, and behaviors**

---

## What Are Agent Profiles?

Agent profiles define specialized Claude subagents that can be invoked via the Task tool to handle specific responsibilities:

- **Identity**: Who the agent is and their role
- **Goals**: What they're trying to achieve
- **Behavior**: How they should act and communicate
- **Knowledge**: What they know about your domain
- **Tools**: What capabilities they have access to
- **Escalation**: When to hand off to other agents or humans

---

## Available Agent Profiles

- [Code Reviewer Agent](./code-reviewer-agent.md) - Reviews code for quality, security, and best practices
- [Test Writer Agent](./test-writer-agent.md) - Creates comprehensive test suites
- [Documentation Agent](./documentation-agent.md) - Generates and maintains documentation
- [Refactor Agent](./refactor-agent.md) - Improves code structure and patterns
- [Debug Agent](./debug-agent.md) - Investigates and fixes bugs

---

## How to Use Agent Profiles

### Method 1: Via Task Tool in Claude Code

```typescript
// In your Claude Code session, use the Task tool:
Task({
  subagent_type: "code-reviewer",
  description: "Review authentication code",
  prompt: "Please review the authentication implementation in src/auth.ts for security vulnerabilities and best practices"
})
```

### Method 2: Create Custom Agents

1. Copy [agent-template.md](./agent-template.md)
2. Customize for your specific use case
3. Reference it when invoking the Task tool

---

## Agent Profile Structure

Each profile contains:

```markdown
# Agent Name

## Core Identity
- Role, personality, expertise

## Objectives
- Primary goals, success metrics

## Behavior Guidelines
- Communication style, decision-making

## Knowledge Base
- Domain expertise, context

## Tools & Capabilities
- What the agent can access/modify

## Example Interactions
- Sample conversations
```

---

## Creating New Agents

### Step 1: Define the Purpose
What specific task or domain should this agent handle?

### Step 2: Use the Template
Copy `agent-template.md` and fill in all sections

### Step 3: Test the Agent
Invoke via Task tool with sample prompts

### Step 4: Iterate
Refine based on actual performance

---

## Best Practices

### DO:
- Be specific about the agent's scope and limitations
- Provide concrete examples of desired behavior
- Define clear escalation criteria
- Set measurable success metrics
- Update profiles based on real usage

### DON'T:
- Make profiles too vague or generic
- Give conflicting instructions
- Skip example interactions
- Forget edge cases
- Set unrealistic expectations

---

## Integration with Claude Code

These profiles work seamlessly with Claude Code's Task tool. When you invoke a subagent:

1. The agent receives these instructions as context
2. It operates within the defined scope
3. It follows the behavior guidelines
4. It escalates when criteria are met

---

**Start building your agent team today!**
