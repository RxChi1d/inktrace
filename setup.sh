#!/bin/bash

# Setup script for Inktrace Blog
# This script configures Git hooks and initializes submodules

set -e  # Exit on error

echo "🚀 Starting setup for Inktrace Blog..."
echo ""

# Configure Git hooks path
echo "📝 Configuring Git hooks..."
if git config core.hooksPath script/git-hooks; then
    echo "✅ Git hooks path configured successfully"
    echo "   Hooks location: script/git-hooks"
else
    echo "❌ Failed to configure Git hooks path"
    exit 1
fi

echo ""

# Initialize submodules
echo "📦 Initializing Git submodules..."
if git submodule update --init --recursive; then
    echo "✅ Submodules initialized successfully"
    echo "   Theme: Blowfish"
else
    echo "❌ Failed to initialize submodules"
    exit 1
fi

echo ""
echo "✨ Setup completed successfully!"
echo ""
echo "Next steps:"
echo "  1. Run 'hugo server' to start the development server"
echo "  2. Visit http://localhost:1313 to view your blog"
echo ""
echo "Note: The pre-commit hook will automatically update the 'lastmod'"
echo "      field in your Markdown files when you commit changes."
