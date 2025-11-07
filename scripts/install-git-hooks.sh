#!/bin/bash
# Install Git hooks to prevent committing secrets

echo "Installing Git hooks..."

# Create hooks directory if it doesn't exist
mkdir -p .git/hooks

# Install pre-commit hook
cp scripts/pre-commit-secret-check.sh .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit

echo "✓ Pre-commit hook installed"
echo ""
echo "This hook will automatically check for secrets before each commit."
echo "To test it, try committing a file with 'private_key' in it."
echo ""
