#!/usr/bin/env bash
# generate-taxonomy-index.sh
# Generates _index.<lang>.md files for taxonomy terms based on SSOT data files
# SSOT: data/taxonomy/{zh-TW,en}.yaml

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DATA_DIR="$REPO_ROOT/data/taxonomy"
CONTENT_DIR="$REPO_ROOT/content"

# Colors for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

# Dependency check: yq required for YAML processing
if ! command -v yq &> /dev/null; then
    echo -e "${RED}✗ Error: yq is required but not installed.${NC}"
    echo "Install: brew install yq"
    exit 1
fi

# Validate SSOT files exist
if [ ! -f "$DATA_DIR/zh-TW.yaml" ] || [ ! -f "$DATA_DIR/en.yaml" ]; then
    echo -e "${RED}✗ Error: Required SSOT files not found in $DATA_DIR${NC}"
    echo "Expected: zh-TW.yaml and en.yaml"
    exit 1
fi

# Extract all terms for a given taxonomy from SSOT
get_terms() {
    local lang=$1
    local taxonomy=$2
    local file="$DATA_DIR/$lang.yaml"

    yq eval ".${taxonomy} | keys | .[]" "$file" 2>/dev/null || echo ""
}

# Retrieve translation for a specific term from SSOT
get_translation() {
    local lang=$1
    local taxonomy=$2
    local term=$3
    local file="$DATA_DIR/$lang.yaml"

    yq eval ".${taxonomy}.${term}" "$file" 2>/dev/null || echo ""
}

# Validate and retrieve translation with fallback
# Returns: translation value (or term as fallback)
# Sets: missing_flag=1 if translation is missing
validate_translation() {
    local lang=$1
    local value=$2
    local term=$3
    local taxonomy=$4

    if [ -z "$value" ] || [ "$value" = "null" ]; then
        echo -e "${YELLOW}⚠ Warning: Missing $lang translation for $taxonomy/$term, using term as fallback${NC}" >&2
        echo "$term"
        return 1
    fi
    echo "$value"
    return 0
}

# Generate or update _index file for a term
generate_index_file() {
    local taxonomy=$1
    local term=$2
    local lang=$3
    local title=$4

    local term_dir="$CONTENT_DIR/$taxonomy/$term"
    local index_file="$term_dir/_index.$lang.md"

    # Ensure term directory exists
    mkdir -p "$term_dir"

    # Check if file exists with same title (avoid unnecessary writes)
    if [ -f "$index_file" ]; then
        local existing_title
        existing_title=$(grep '^title:' "$index_file" | sed -E 's/^title: *"?([^"]*)"?$/\1/' || echo "")

        if [ "$existing_title" = "$title" ]; then
            echo -e "  ${GREEN}✓${NC} $index_file (unchanged)"
            return 0
        fi

        # Update title field only (preserve other front matter)
        awk -v new_title="$title" '
        /^title:/ { print "title: \"" new_title "\""; next }
        { print }
        ' "$index_file" > "$index_file.tmp" && mv "$index_file.tmp" "$index_file"

        echo -e "  ${YELLOW}↻${NC} $index_file (title updated)"
    else
        # Create new file with minimal front matter
        cat > "$index_file" << EOF
---
title: "$title"
---
EOF
        echo -e "  ${GREEN}+${NC} $index_file (created)"
    fi
}

# Process all terms for a given taxonomy
process_taxonomy() {
    local taxonomy=$1

    echo -e "\n${GREEN}Processing $taxonomy...${NC}"

    # Get all terms from zh-TW SSOT (authoritative term list)
    local terms
    terms=$(get_terms "zh-TW" "$taxonomy")

    if [ -z "$terms" ]; then
        echo -e "${YELLOW}⚠ Warning: No terms found for $taxonomy in zh-TW.yaml${NC}"
        return 0
    fi

    # Process each term
    while IFS= read -r term; do
        [ -z "$term" ] && continue

        # Validate term format: lowercase kebab-case only
        if ! echo "$term" | grep -qE '^[a-z0-9]+(-[a-z0-9]+)*$'; then
            echo -e "${RED}✗ Error: Term '$term' in $taxonomy is not lowercase kebab-case${NC}"
            exit 1
        fi

        # Retrieve translations from SSOT
        local title_zh_tw title_en
        title_zh_tw=$(get_translation "zh-TW" "$taxonomy" "$term")
        title_en=$(get_translation "en" "$taxonomy" "$term")

        # Validate and apply fallbacks
        local missing_translation=0
        title_zh_tw=$(validate_translation "zh-TW" "$title_zh_tw" "$term" "$taxonomy") || missing_translation=1
        title_en=$(validate_translation "en" "$title_en" "$term" "$taxonomy") || missing_translation=1

        # Generate index files for both languages
        generate_index_file "$taxonomy" "$term" "zh-TW" "$title_zh_tw"
        generate_index_file "$taxonomy" "$term" "en" "$title_en"

        # Report missing translations
        if [ $missing_translation -eq 1 ]; then
            echo -e "${YELLOW}⚠${NC}  Term '$term' has incomplete translations"
        fi
    done <<< "$terms"
}

# Main execution
echo "==================================="
echo "Taxonomy Index Generator"
echo "==================================="
echo "Data source: $DATA_DIR"
echo "Content target: $CONTENT_DIR"

# Process both taxonomies
process_taxonomy "categories"
process_taxonomy "tags"

echo -e "\n${GREEN}✓ Generation complete!${NC}"
