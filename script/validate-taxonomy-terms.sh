#!/usr/bin/env bash
# validate-taxonomy-terms.sh
# Validates taxonomy terms in staged content files against SSOT

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DATA_DIR="$REPO_ROOT/data/taxonomy"

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

# Get staged content files
staged_files=$(git diff --cached --name-only --diff-filter=AM "content/**/*.md" "content/*.md" || echo "")

if [ -z "$staged_files" ]; then
    echo "No staged content files to validate."
    exit 0
fi

echo "==================================="
echo "Taxonomy Term Validator"
echo "==================================="

# Function to check if term exists in SSOT
term_exists() {
    local taxonomy=$1
    local term=$2

    local exists_zh_tw
    local exists_en

    exists_zh_tw=$(yq eval ".${taxonomy}.${term}" "$DATA_DIR/zh-TW.yaml" 2>/dev/null)
    exists_en=$(yq eval ".${taxonomy}.${term}" "$DATA_DIR/en.yaml" 2>/dev/null)

    if [ "$exists_zh_tw" = "null" ] || [ -z "$exists_zh_tw" ]; then
        return 1
    fi

    if [ "$exists_en" = "null" ] || [ -z "$exists_en" ]; then
        return 2
    fi

    return 0
}

# Function to validate a file
validate_file() {
    local file=$1
    local has_errors=0

    # Extract front matter
    local in_frontmatter=0
    local line_num=0
    local categories=""
    local tags=""

    while IFS= read -r line; do
        ((line_num++)) || true

        if [ $in_frontmatter -eq 0 ] && [ "$line" = "---" ]; then
            in_frontmatter=1
            continue
        elif [ $in_frontmatter -eq 1 ] && [ "$line" = "---" ]; then
            break
        elif [ $in_frontmatter -eq 1 ]; then
            # Extract categories
            if [[ "$line" =~ ^categories:[[:space:]]*\[(.+)\] ]]; then
                categories="${BASH_REMATCH[1]}"
            elif [[ "$line" =~ ^[[:space:]]*-[[:space:]]+(.+)$ ]] && [ -n "$categories" ] && [ "$categories" != "closed" ]; then
                if [ "$categories" = "open" ]; then
                    categories="${BASH_REMATCH[1]}"
                else
                    categories="${categories},${BASH_REMATCH[1]}"
                fi
            elif [[ "$line" =~ ^categories: ]]; then
                categories="open"
            elif [[ "$line" =~ ^[a-z]+: ]] && [ "$categories" = "open" ]; then
                categories="closed"
            fi

            # Extract tags
            if [[ "$line" =~ ^tags:[[:space:]]*\[(.+)\] ]]; then
                tags="${BASH_REMATCH[1]}"
            elif [[ "$line" =~ ^[[:space:]]*-[[:space:]]+(.+)$ ]] && [ -n "$tags" ] && [ "$tags" != "closed" ]; then
                if [ "$tags" = "open" ]; then
                    tags="${BASH_REMATCH[1]}"
                else
                    tags="${tags},${BASH_REMATCH[1]}"
                fi
            elif [[ "$line" =~ ^tags: ]]; then
                tags="open"
            elif [[ "$line" =~ ^[a-z]+: ]] && [ "$tags" = "open" ]; then
                tags="closed"
            fi
        fi
    done < "$file"

    # Validate categories
    if [ -n "$categories" ] && [ "$categories" != "open" ] && [ "$categories" != "closed" ]; then
        IFS=',' read -ra category_array <<< "$categories"
        for category in "${category_array[@]}"; do
            # Remove quotes and whitespace
            category=$(echo "$category" | sed 's/^[[:space:]"]*//;s/[[:space:]"]*$//')

            # Check if lowercase
            if [ "$category" != "$(echo "$category" | tr '[:upper:]' '[:lower:]')" ]; then
                echo -e "${RED}✗${NC} $file: category '$category' is not lowercase"
                has_errors=1
            fi

            # Check if exists in SSOT
            if ! term_exists "categories" "$category"; then
                if [ $? -eq 1 ]; then
                    echo -e "${RED}✗${NC} $file: category '$category' missing zh-TW translation in SSOT"
                elif [ $? -eq 2 ]; then
                    echo -e "${RED}✗${NC} $file: category '$category' missing en translation in SSOT"
                else
                    echo -e "${RED}✗${NC} $file: category '$category' not found in SSOT"
                fi
                has_errors=1
            fi
        done
    fi

    # Validate tags
    if [ -n "$tags" ] && [ "$tags" != "open" ] && [ "$tags" != "closed" ]; then
        IFS=',' read -ra tag_array <<< "$tags"
        for tag in "${tag_array[@]}"; do
            # Remove quotes and whitespace
            tag=$(echo "$tag" | sed 's/^[[:space:]"]*//;s/[[:space:]"]*$//')

            # Check if lowercase
            if [ "$tag" != "$(echo "$tag" | tr '[:upper:]' '[:lower:]')" ]; then
                echo -e "${RED}✗${NC} $file: tag '$tag' is not lowercase"
                has_errors=1
            fi

            # Check if exists in SSOT
            if ! term_exists "tags" "$tag"; then
                if [ $? -eq 1 ]; then
                    echo -e "${RED}✗${NC} $file: tag '$tag' missing zh-TW translation in SSOT"
                elif [ $? -eq 2 ]; then
                    echo -e "${RED}✗${NC} $file: tag '$tag' missing en translation in SSOT"
                else
                    echo -e "${RED}✗${NC} $file: tag '$tag' not found in SSOT"
                fi
                has_errors=1
            fi
        done
    fi

    return $has_errors
}

# Validate all staged files
total_errors=0
file_count=0

while IFS= read -r file; do
    [ -z "$file" ] && continue
    [ ! -f "$file" ] && continue

    ((file_count++)) || true

    if validate_file "$file"; then
        echo -e "${GREEN}✓${NC} $file"
    else
        ((total_errors++)) || true
    fi
done <<< "$staged_files"

echo "-----------------------------------"
echo "Validated $file_count file(s)"

if [ $total_errors -gt 0 ]; then
    echo -e "${RED}✗ Found errors in $total_errors file(s)${NC}"
    echo ""
    echo "Please ensure:"
    echo "  1. All taxonomy terms are lowercase (kebab-case)"
    echo "  2. All terms exist in data/taxonomy/zh-TW.yaml and data/taxonomy/en.yaml"
    echo "  3. Both zh-TW and en translations are defined for each term"
    exit 1
else
    echo -e "${GREEN}✓ All terms are valid!${NC}"
    exit 0
fi
