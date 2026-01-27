#!/bin/bash

# Git Authorship Harmonization Script
# Standardizes all user commits to git config identity, preserving bot identities

set -e

# Target identity from git config
TARGET_NAME=$(git config user.name)
TARGET_EMAIL=$(git config user.email)

echo "Target identity: $TARGET_NAME <$TARGET_EMAIL>"
echo ""

# Check if git-filter-repo is installed
if ! command -v git-filter-repo &> /dev/null; then
    echo "Installing git-filter-repo via pip..."
    pip install git-filter-repo
    echo ""
fi

# Create backup branch
BACKUP_BRANCH="backup-before-authorship-fix-$(date +%Y%m%d-%H%M%S)"
echo "Creating backup branch: $BACKUP_BRANCH"
git branch "$BACKUP_BRANCH"
echo ""

# Create mailmap file
MAILMAP_FILE=".git-mailmap-tmp"
cat > "$MAILMAP_FILE" << EOF
$TARGET_NAME <$TARGET_EMAIL> Sean Thimons <141747936+seanthimons@users.noreply.github.com>
$TARGET_NAME <$TARGET_EMAIL> Sean Thimons <thimons.sean@epa.gov>
$TARGET_NAME <$TARGET_EMAIL> seanthimons <141747936+seanthimons@users.noreply.github.com>
$TARGET_NAME <$TARGET_EMAIL> seanthimons <thimons.sean@epa.gov>
$TARGET_NAME <$TARGET_EMAIL> seanthimons <thimons.sean@gmail.com>
$TARGET_NAME <$TARGET_EMAIL> sxthimons <101654772+sxthimons@users.noreply.github.com>
EOF

echo "Mailmap file created with the following mappings:"
cat "$MAILMAP_FILE"
echo ""

# Dry-run first
echo "Running dry-run to preview changes..."
git filter-repo --mailmap "$MAILMAP_FILE" --dry-run --force

echo ""
read -p "Dry-run complete. Proceed with actual rewrite? (y/n): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Running actual rewrite..."
    git filter-repo --mailmap "$MAILMAP_FILE" --force
    
    # Cleanup
    rm "$MAILMAP_FILE"
    
    echo ""
    echo "✓ Authorship harmonization complete!"
    echo "✓ Backup branch: $BACKUP_BRANCH"
    echo ""
    echo "Updated commit history:"
    git log --pretty=format:"%an <%ae>" | sort -u
    echo ""
    echo "If something went wrong, restore with: git reset --hard $BACKUP_BRANCH"
else
    echo "Operation cancelled. Backup branch preserved: $BACKUP_BRANCH"
    rm "$MAILMAP_FILE"
fi

# If something went wrong, restore with: git reset --hard backup-before-authorship-fix-20260127-140440