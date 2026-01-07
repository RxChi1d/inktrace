#!/usr/bin/env bash
# update-edit-time.sh
# Updates lastmod field in staged content files

set -euo pipefail

# Get current time in ISO 8601 format with Asia/Taipei timezone
current_time=$(TZ="Asia/Taipei" date +"%Y-%m-%dT%H:%M:%S%z")
# Convert +0800 to +08:00 format
current_time=$(echo "$current_time" | sed 's/\([0-9][0-9]\)$/:\1/')
# Get current date only (YYYY-MM-DD)
current_date_only=$(TZ="Asia/Taipei" date +"%Y-%m-%d")

# Get all staged (modified or added) .md files in content/
staged_output=$(git diff --cached --name-only --diff-filter=AM "content/**/*.md" "content/*.md")

if [ -z "$staged_output" ]; then
  echo "No staged Markdown files found to process."
  exit 0
fi

echo "Processing staged Markdown files for lastmod update..."

echo "$staged_output" | while IFS= read -r raw_escaped_file_path; do
  if [ -z "$raw_escaped_file_path" ]; then
    continue
  fi

  # Remove potential quotes
  processed_escaped_file_path=$(echo "$raw_escaped_file_path" | sed 's/^"\(.*\)"$/\1/')

  # Convert octal escape sequences to actual characters
  file_path=$(printf '%b' "$processed_escaped_file_path")

  echo "Attempting to process file: '$file_path' (decoded from: '$raw_escaped_file_path' -> processed to: '$processed_escaped_file_path')"

  # Check if file exists
  if [ ! -f "$file_path" ]; then
    echo "ERROR: File '$file_path' not found. Skipping."
    dir_name=$(dirname "$file_path")
    if [ -d "$dir_name" ]; then
      echo "Contents of directory '$dir_name':"
      ls -la "$dir_name"
    else
      echo "Directory '$dir_name' does not exist."
    fi
    continue
  fi

  # 1. Add date if missing
  if ! grep -q '^date:' "$file_path"; then
    if grep -q '^slug:' "$file_path"; then
       awk -v time="$current_time" '/^slug:/ { print; print "date: " time; next }1' "$file_path" > "$file_path.tmp" && mv "$file_path.tmp" "$file_path"
       echo "Added date to $file_path (after slug)"
    elif grep -q '^title:' "$file_path"; then
       awk -v time="$current_time" '/^title:/ { print; print "date: " time; next }1' "$file_path" > "$file_path.tmp" && mv "$file_path.tmp" "$file_path"
       echo "Added date to $file_path (after title)"
    else
       # Insert after first ---
       awk -v time="$current_time" 'NR==1 && /^---/ { print; print "date: " time; next }1' "$file_path" > "$file_path.tmp" && mv "$file_path.tmp" "$file_path"
       echo "Added date to $file_path (after frontmatter start)"
    fi
  fi

  # 2. Update or add lastmod
  if grep -q '^lastmod:' "$file_path"; then
    # Update existing lastmod
    awk -v new_lastmod_value="$current_time" '
    /^lastmod:/ { print "lastmod: " new_lastmod_value; next }
    { print }
    ' "$file_path" > "$file_path.tmp" && mv "$file_path.tmp" "$file_path"
    echo "Updated lastmod in $file_path to $current_time"
  elif grep -q '^date:' "$file_path"; then
    # Extract date value (YYYY-MM-DD only)
    file_date_value=$(grep '^date:' "$file_path" | sed -E 's/^date: *"?([0-9]{4}-[0-9]{2}-[0-9]{2}).*/\1/')

    if [ -n "$file_date_value" ]; then
      # Compare dates
      if [ "$file_date_value" != "$current_date_only" ]; then
        # Add lastmod after date
        awk -v time="$current_time" '
        { print }
        /^date:/ { print "lastmod: " time }
        ' "$file_path" > "$file_path.tmp" && mv "$file_path.tmp" "$file_path"
        echo "Added lastmod in $file_path (date $file_date_value != current date $current_date_only) with value $current_time"
      else
        echo "Skipping lastmod addition for $file_path: date ($file_date_value) is current."
        continue
      fi
    else
      echo "Could not extract date from $file_path. Skipping lastmod addition based on date."
      continue
    fi
  else
    echo "No lastmod or date field found in $file_path. Skipping."
    continue
  fi

  # Re-add file to staging area
  git add "$file_path"
done

echo "Finished processing files."
exit 0
