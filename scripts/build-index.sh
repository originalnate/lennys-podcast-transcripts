#!/bin/bash

# Build index/ folder from podcast transcripts using Claude CLI
# Usage: ./scripts/build-index.sh

set -e

EPISODES_DIR="${EPISODES_DIR:-episodes}"
OUTPUT_DIR="${OUTPUT_DIR:-index}"
TEMP_DIR="${TEMP_DIR:-$(mktemp -d)}"
PROCESSED_FILE="$TEMP_DIR/processed.txt"
KEYWORDS_FILE="$TEMP_DIR/keywords.txt"
EPISODES_FILE="$TEMP_DIR/episodes.tsv"

# Track progress
TOTAL=$(ls -d "$EPISODES_DIR"/*/ 2>/dev/null | wc -l | tr -d ' ')
CURRENT=0

echo "Building index for $TOTAL episodes..."
echo "Temp directory: $TEMP_DIR"

# Initialize files
mkdir -p "$OUTPUT_DIR"
touch "$PROCESSED_FILE" "$KEYWORDS_FILE" "$EPISODES_FILE"

# Process each episode
for dir in "$EPISODES_DIR"/*/; do
    slug=$(basename "$dir")
    transcript="$dir/transcript.md"

    # Skip if already processed (for resume support)
    if grep -q "^$slug$" "$PROCESSED_FILE" 2>/dev/null; then
        echo "[$CURRENT/$TOTAL] Skipping $slug (already processed)"
        ((CURRENT++)) || true
        continue
    fi

    ((CURRENT++)) || true

    if [[ ! -f "$transcript" ]]; then
        echo "[$CURRENT/$TOTAL] Skipping $slug (no transcript.md)"
        continue
    fi

    echo "[$CURRENT/$TOTAL] Processing $slug..."

    # Extract YAML frontmatter fields
    frontmatter=$(sed -n '/^---$/,/^---$/p' "$transcript" | sed '1d;$d')
    guest=$(echo "$frontmatter" | grep '^guest:' | sed 's/^guest: *//' | sed 's/^"//' | sed 's/"$//')
    title=$(echo "$frontmatter" | grep '^title:' | sed 's/^title: *//' | sed 's/^"//' | sed 's/"$//')

    # Write transcript to temp file to avoid shell limits
    # Skip frontmatter (from line 1 to closing ---)
    transcript_temp="$TEMP_DIR/transcript_temp.txt"
    sed '1,/^---$/d' "$transcript" > "$transcript_temp"

    # Create prompt file
    prompt_file="$TEMP_DIR/prompt.txt"
    cat > "$prompt_file" << 'PROMPT_END'
Analyze this podcast transcript and provide:
1. A 2-3 sentence summary of the key topics discussed
2. 8-12 keyword tags (topics, concepts, frameworks, company names if relevant)

Output ONLY valid JSON, no markdown, no code blocks: {"summary": "...", "keywords": ["...", "..."]}

TRANSCRIPT:
PROMPT_END
    cat "$transcript_temp" >> "$prompt_file"

    # Call Claude for summary/keywords
    raw_response=$(claude --model claude-sonnet-4-20250514 -p < "$prompt_file" 2>/dev/null || echo '{"summary": "Error", "keywords": []}')

    # Strip markdown code blocks if present and extract JSON
    response=$(echo "$raw_response" | grep -o '{.*}' | head -1 || echo '{"summary": "Error", "keywords": []}')

    # Parse JSON response
    summary=$(echo "$response" | jq -r '.summary // "Summary not available"' 2>/dev/null || echo "Summary not available")
    keywords_json=$(echo "$response" | jq -r '.keywords // []' 2>/dev/null || echo "[]")
    keywords_formatted=$(echo "$keywords_json" | jq -r 'join(", ")' 2>/dev/null || echo "")

    # Escape pipe characters in summary for table
    summary_escaped=$(echo "$summary" | tr '\n' ' ' | sed 's/|/\\|/g')

    # Append to episodes file (tab-separated)
    printf "%s\t%s\t%s\t%s\n" "$guest" "$slug" "$summary_escaped" "$keywords_formatted" >> "$EPISODES_FILE"

    # Track keywords with slug for reverse index
    echo "$keywords_json" | jq -r '.[]' 2>/dev/null | while read -r keyword; do
        if [[ -n "$keyword" ]]; then
            echo "$keyword|$slug|$guest" >> "$KEYWORDS_FILE"
        fi
    done

    # Mark as processed
    echo "$slug" >> "$PROCESSED_FILE"

    # Small delay to avoid rate limiting
    sleep 1
done

echo ""
echo "Building index files..."

# Count episodes
episode_count=$(wc -l < "$PROCESSED_FILE" | tr -d ' ')

# Write episodes.md with header and table
cat > "$OUTPUT_DIR/episodes.md" << EOF
# Lenny's Podcast Episode Index

*Generated: $(date +%Y-%m-%d) | $episode_count episodes indexed*

## Episodes

| Guest | Summary | Keywords |
|-------|---------|----------|
EOF

# Append table rows from episodes file
while IFS=$'\t' read -r guest slug summary keywords; do
    echo "| [$guest](../episodes/$slug/transcript.md) | $summary | $keywords |" >> "$OUTPUT_DIR/episodes.md"
done < "$EPISODES_FILE"

# Build individual keyword files
echo "Creating keyword files..."
if [[ -s "$KEYWORDS_FILE" ]]; then
    # Get unique keywords sorted by frequency
    cut -d'|' -f1 "$KEYWORDS_FILE" | sort | uniq -c | sort -rn | head -50 | while read -r count keyword; do
        # Create filename from keyword (lowercase, spaces to hyphens, remove special chars)
        filename=$(echo "$keyword" | tr '[:upper:]' '[:lower:]' | tr ' /' '-' | tr -cd 'a-z0-9-')

        # Write keyword file
        cat > "$OUTPUT_DIR/${filename}.md" << EOF
# $keyword

Episodes discussing **$keyword**:

EOF
        # Add episode links
        grep "^${keyword}|" "$KEYWORDS_FILE" | cut -d'|' -f2,3 | sort -u | while IFS='|' read -r slug guest; do
            echo "- [$guest](../episodes/$slug/transcript.md)" >> "$OUTPUT_DIR/${filename}.md"
        done

        echo "  Created ${filename}.md ($count episodes)"
    done
fi

# Build README.md with links to all files
echo "Creating README.md..."
cat > "$OUTPUT_DIR/README.md" << EOF
# Lenny's Podcast Index

*Generated: $(date +%Y-%m-%d) | $episode_count episodes indexed*

## Browse

- [All Episodes](episodes.md) - Complete table with summaries and keywords

## Topics

EOF

# Add links to all keyword files sorted alphabetically
ls "$OUTPUT_DIR"/*.md 2>/dev/null | grep -v episodes.md | grep -v README.md | sort | while read -r file; do
    name=$(basename "$file" .md)
    # Convert filename to title case
    title=$(echo "$name" | tr '-' ' ' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) tolower(substr($i,2))}1')
    count=$(grep -c "^- \[" "$file" 2>/dev/null || echo "0")
    echo "- [$title]($name.md) ($count episodes)" >> "$OUTPUT_DIR/README.md"
done

echo ""
echo "Done! Index created in $OUTPUT_DIR/ with $episode_count episodes."
echo "  - README.md (main entry point)"
echo "  - episodes.md (full episodes table)"
echo "  - $(ls "$OUTPUT_DIR"/*.md | grep -v episodes.md | grep -v README.md | wc -l | tr -d ' ') keyword files"
echo ""
echo "Temp files preserved at: $TEMP_DIR"
