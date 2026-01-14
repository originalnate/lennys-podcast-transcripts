# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a static content archive containing 269 episode transcripts from Lenny's Podcast, with an AI-generated topic index for easy discovery.

## Structure

```
├── episodes/
│   └── {guest-name}/
│       └── transcript.md    # YAML frontmatter + transcript content
├── index/
│   ├── README.md            # Main entry point with topic links
│   ├── episodes.md          # Full episodes table with summaries
│   └── {topic}.md           # Individual topic files (e.g., product-management.md)
└── scripts/
    └── build-index.sh       # Script to regenerate the index
```

## Transcript Format

Each transcript.md contains:
- **YAML frontmatter**: guest, title, youtube_url, video_id, description, duration_seconds, duration, view_count, channel
- **Transcript content**: Timestamped speaker dialogue

## Index

The `index/` folder contains AI-generated summaries and keyword tags for each episode:
- `episodes.md` - Table of all episodes with summaries and keywords
- Topic files (e.g., `product-management.md`) - Episodes grouped by topic

## Rebuilding the Index

```bash
./scripts/build-index.sh
```

This calls Claude CLI for each episode to generate summaries and keywords. Takes ~45 minutes for all episodes. Supports resume if interrupted.
