#!/usr/bin/env bash
# validate-taxonomy-terms.sh
# Validates taxonomy terms in staged content files against SSOT
# SSOT: data/taxonomy/{zh-TW,en}.yaml

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DATA_DIR="$REPO_ROOT/data/taxonomy"

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

# Get staged content files
staged_files=$(git diff --cached --name-only --diff-filter=AM "content/**/*.md" "content/*.md" || echo "")

if [ -z "$staged_files" ]; then
    echo "No staged content files to validate."
    exit 0
fi

echo "==================================="
echo "Taxonomy Term Validator"
echo "==================================="

# Check if term exists in SSOT and return missing translation info
# Returns: 0=exists, 1=missing zh-TW, 2=missing en, 3=not found
term_exists() {
    local taxonomy=$1
    local term=$2

    local exists_zh_tw exists_en
    exists_zh_tw=$(yq eval ".${taxonomy}.${term}" "$DATA_DIR/zh-TW.yaml" 2>/dev/null)
    exists_en=$(yq eval ".${taxonomy}.${term}" "$DATA_DIR/en.yaml" 2>/dev/null)

    # Check zh-TW translation
    if [ "$exists_zh_tw" = "null" ] || [ -z "$exists_zh_tw" ]; then
        return 1
    fi

    # Check en translation
    if [ "$exists_en" = "null" ] || [ -z "$exists_en" ]; then
        return 2
    fi

    return 0
}

# Extract taxonomy field from front matter (supports both inline and multi-line formats)
# Usage: extract_taxonomy_field <file> <field_name>
# Returns: comma-separated list of terms
extract_taxonomy_field() {
    local file=$1
    local field=$2
    local in_frontmatter=0
    local field_value=""
    local field_state="closed"

    while IFS= read -r line; do
        # Front matter boundary detection
        if [ $in_frontmatter -eq 0 ] && [ "$line" = "---" ]; then
            in_frontmatter=1
            continue
        elif [ $in_frontmatter -eq 1 ] && [ "$line" = "---" ]; then
            break
        elif [ $in_frontmatter -eq 0 ]; then
            continue
        fi

        # Inline format: field: [term1, term2]
        if [[ "$line" =~ ^${field}:[[:space:]]*\[(.+)\] ]]; then
            field_value="${BASH_REMATCH[1]}"
            field_state="closed"
        # Multi-line format start: field:
        elif [[ "$line" =~ ^${field}: ]]; then
            field_state="open"
        # Multi-line format items: - term
        elif [[ "$line" =~ ^[[:space:]]*-[[:space:]]+(.+)$ ]] && [ "$field_state" = "open" ]; then
            if [ -z "$field_value" ]; then
                field_value="${BASH_REMATCH[1]}"
            else
                field_value="${field_value},${BASH_REMATCH[1]}"
            fi
        # Close multi-line when next field starts
        elif [[ "$line" =~ ^[a-z]+: ]] && [ "$field_state" = "open" ]; then
            field_state="closed"
        fi
    done < "$file"

    echo "$field_value"
}

# Validate terms for a given taxonomy type
# Usage: validate_terms <file> <taxonomy> <terms_csv>
# Returns: number of errors found
validate_terms() {
    local file=$1
    local taxonomy=$2
    local terms_csv=$3
    local errors=0

    # Skip if no terms
    [ -z "$terms_csv" ] && return 0

    # Parse comma-separated terms
    IFS=',' read -ra term_array <<< "$terms_csv"

    for term in "${term_array[@]}"; do
        # Remove quotes and whitespace using Bash parameter expansion
        term="${term#"${term%%[![:space:]\"]*}"}"  # Remove leading whitespace and quotes
        term="${term%"${term##*[![:space:]\"]*}"}"  # Remove trailing whitespace and quotes

        # Validate lowercase (kebab-case)
        local lowercase_term
        lowercase_term=$(echo "$term" | tr '[:upper:]' '[:lower:]')
        if [ "$term" != "$lowercase_term" ]; then
            echo -e "${RED}✗${NC} $file: $taxonomy '$term' is not lowercase"
            ((errors++))
            continue
        fi

        # Validate existence in SSOT
        local error_code
        if ! term_exists "$taxonomy" "$term"; then
            error_code=$?
            case $error_code in
                1)
                    echo -e "${RED}✗${NC} $file: $taxonomy '$term' missing zh-TW translation in SSOT"
                    ;;
                2)
                    echo -e "${RED}✗${NC} $file: $taxonomy '$term' missing en translation in SSOT"
                    ;;
                *)
                    echo -e "${RED}✗${NC} $file: $taxonomy '$term' not found in SSOT"
                    ;;
            esac
            ((errors++))
        fi
    done

    return $errors
}

# Validate a single file
validate_file() {
    local file=$1
    local total_errors=0

    # Extract taxonomy fields
    local categories tags
    categories=$(extract_taxonomy_field "$file" "categories")
    tags=$(extract_taxonomy_field "$file" "tags")

    # Validate categories
    if ! validate_terms "$file" "category" "$categories"; then
        ((total_errors += $?))
    fi

    # Validate tags
    if ! validate_terms "$file" "tag" "$tags"; then
        ((total_errors += $?))
    fi

    return $total_errors
}

# Main validation loop
total_errors=0
file_count=0

while IFS= read -r file; do
    [ -z "$file" ] && continue
    [ ! -f "$file" ] && continue

    ((file_count++))

    if validate_file "$file"; then
        echo -e "${GREEN}✓${NC} $file"
    else
        ((total_errors++))
    fi
done <<< "$staged_files"

# Summary output
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
