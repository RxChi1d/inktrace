#!/usr/bin/env bash
# generate-taxonomy-index.sh
# Generates _index.<lang>.md files for taxonomy terms based on SSOT data files

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DATA_DIR="$REPO_ROOT/data/taxonomy"
CONTENT_DIR="$REPO_ROOT/content"

# Colors for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Check if yq is installed
if ! command -v yq &> /dev/null; then
    echo -e "${RED}Error: yq is required but not installed.${NC}"
    echo "Please install yq: brew install yq"
    exit 1
fi

# Check if data files exist
if [ ! -f "$DATA_DIR/zh-TW.yaml" ] || [ ! -f "$DATA_DIR/en.yaml" ]; then
    echo -e "${RED}Error: Required SSOT files not found in $DATA_DIR${NC}"
    echo "Expected: zh-TW.yaml and en.yaml"
    exit 1
fi

# Function to extract terms from SSOT
get_terms() {
    local lang=$1
    local taxonomy=$2
    local file="$DATA_DIR/$lang.yaml"

    yq eval ".${taxonomy} | keys | .[]" "$file" 2>/dev/null || echo ""
}

# Function to get translation for a term
get_translation() {
    local lang=$1
    local taxonomy=$2
    local term=$3
    local file="$DATA_DIR/$lang.yaml"

    yq eval ".${taxonomy}.${term}" "$file" 2>/dev/null || echo ""
}

# Function to generate or update _index file
generate_index_file() {
    local taxonomy=$1
    local term=$2
    local lang=$3
    local title=$4

    local term_dir="$CONTENT_DIR/$taxonomy/$term"
    local index_file="$term_dir/_index.$lang.md"

    # Create directory if it doesn't exist
    mkdir -p "$term_dir"

    # Check if file exists and has the same title
    if [ -f "$index_file" ]; then
        local existing_title
        existing_title=$(grep '^title:' "$index_file" | sed -E 's/^title: *"?([^"]*)"?$/\1/' || echo "")

        if [ "$existing_title" = "$title" ]; then
            echo -e "  ${GREEN}✓${NC} $index_file (unchanged)"
            return 0
        fi

        # Update only the title field
        awk -v new_title="$title" '
        /^title:/ { print "title: \"" new_title "\""; next }
        { print }
        ' "$index_file" > "$index_file.tmp" && mv "$index_file.tmp" "$index_file"

        echo -e "  ${YELLOW}↻${NC} $index_file (title updated)"
    else
        # Create new file
        cat > "$index_file" << EOF
---
title: "$title"
---
EOF
        echo -e "  ${GREEN}+${NC} $index_file (created)"
    fi
}

# Function to process a taxonomy
process_taxonomy() {
    local taxonomy=$1

    echo -e "\n${GREEN}Processing $taxonomy...${NC}"

    # Get all terms from zh-TW (SSOT for term list)
    local terms
    terms=$(get_terms "zh-TW" "$taxonomy")

    if [ -z "$terms" ]; then
        echo -e "${YELLOW}Warning: No terms found for $taxonomy in zh-TW.yaml${NC}"
        return 0
    fi

    # Process each term
    while IFS= read -r term; do
        [ -z "$term" ] && continue

        # Validate term format (lowercase kebab-case)
        if ! echo "$term" | grep -qE '^[a-z0-9]+(-[a-z0-9]+)*$'; then
            echo -e "${RED}Error: Term '$term' in $taxonomy is not in lowercase kebab-case${NC}"
            exit 1
        fi

        # Get translations
        local title_zh_tw
        local title_en
        title_zh_tw=$(get_translation "zh-TW" "$taxonomy" "$term")
        title_en=$(get_translation "en" "$taxonomy" "$term")

        # Check if both translations exist
        local missing_translation=0
        if [ -z "$title_zh_tw" ] || [ "$title_zh_tw" = "null" ]; then
            echo -e "${YELLOW}Warning: Missing zh-TW translation for $taxonomy/$term, using term as fallback${NC}"
            title_zh_tw="$term"
            missing_translation=1
        fi

        if [ -z "$title_en" ] || [ "$title_en" = "null" ]; then
            echo -e "${YELLOW}Warning: Missing en translation for $taxonomy/$term, using term as fallback${NC}"
            title_en="$term"
            missing_translation=1
        fi

        # Generate files
        generate_index_file "$taxonomy" "$term" "zh-TW" "$title_zh_tw"
        generate_index_file "$taxonomy" "$term" "en" "$title_en"

        if [ $missing_translation -eq 1 ]; then
            echo -e "${YELLOW}⚠${NC}  Term '$term' has missing translations"
        fi
    done <<< "$terms"
}

# Main execution
echo "==================================="
echo "Taxonomy Index Generator"
echo "==================================="
echo "Data source: $DATA_DIR"
echo "Content target: $CONTENT_DIR"

# Process categories and tags
process_taxonomy "categories"
process_taxonomy "tags"

echo -e "\n${GREEN}✓ Generation complete!${NC}"
