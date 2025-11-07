#!/bin/bash
# Pre-commit hook to prevent committing secrets
# Install: cp scripts/pre-commit-secret-check.sh .git/hooks/pre-commit && chmod +x .git/hooks/pre-commit

set -e

# Colors
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

echo "🔍 Checking for secrets in staged files..."

# Patterns to check for
PATTERNS=(
  "-----BEGIN PRIVATE KEY-----"
  "-----BEGIN RSA PRIVATE KEY-----"
  "client_secret"
  "private_key_id"
  "AIza[0-9A-Za-z\\-_]{35}"  # Google API keys
  "ya29\\.[0-9A-Za-z\\-_]+"   # OAuth tokens
  "[0-9]+-[0-9A-Za-z_]{32}\\.apps\\.googleusercontent\\.com"  # OAuth Client IDs
)

# Files to exclude from check
EXCLUDE_PATTERNS=(
  ".env.example"
  "README.md"
  "SECURITY-ISSUE-RESOLVED.md"
  "GMAIL-OAUTH-SETUP.md"
  "*.example"
  "scripts/pre-commit-secret-check.sh"
)

FOUND_SECRETS=0

# Get list of staged files
STAGED_FILES=$(git diff --cached --name-only --diff-filter=ACM)

if [ -z "$STAGED_FILES" ]; then
  echo -e "${GREEN}✓ No files staged${NC}"
  exit 0
fi

# Check each staged file
for FILE in $STAGED_FILES; do
  # Skip if file should be excluded
  SKIP=0
  for EXCLUDE in "${EXCLUDE_PATTERNS[@]}"; do
    if [[ "$FILE" == $EXCLUDE ]]; then
      SKIP=1
      break
    fi
  done

  if [ $SKIP -eq 1 ]; then
    continue
  fi

  # Check if file exists (could be deleted)
  if [ ! -f "$FILE" ]; then
    continue
  fi

  # Check for secret patterns
  for PATTERN in "${PATTERNS[@]}"; do
    if grep -E "$PATTERN" "$FILE" > /dev/null 2>&1; then
      echo -e "${RED}❌ BLOCKED: Found potential secret in $FILE${NC}"
      echo -e "${YELLOW}   Pattern: $PATTERN${NC}"
      FOUND_SECRETS=$((FOUND_SECRETS + 1))
    fi
  done
done

if [ $FOUND_SECRETS -gt 0 ]; then
  echo ""
  echo -e "${RED}===========================================${NC}"
  echo -e "${RED}  COMMIT BLOCKED - SECRETS DETECTED${NC}"
  echo -e "${RED}===========================================${NC}"
  echo ""
  echo -e "${YELLOW}Found $FOUND_SECRETS potential secret(s) in staged files.${NC}"
  echo ""
  echo "Please remove sensitive data before committing."
  echo ""
  echo "To store secrets securely:"
  echo "  • Use GCP Secret Manager: bash scripts/setup-gmail-oauth.sh"
  echo "  • Use environment variables: .env.local (already in .gitignore)"
  echo "  • Use 1Password: op item create ..."
  echo ""
  echo "To bypass this check (NOT RECOMMENDED):"
  echo "  git commit --no-verify"
  echo ""
  exit 1
fi

echo -e "${GREEN}✓ No secrets detected in staged files${NC}"
exit 0
