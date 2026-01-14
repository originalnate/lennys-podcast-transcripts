# Lenny's Podcast Transcripts Archive

A comprehensive archive of transcripts from [Lenny's Podcast](https://www.youtube.com/@LennysPodcast), organized for easy use with AI coding assistants and language models.

## About Lenny's Podcast

Lenny's Podcast features interviews with world-class product leaders and growth experts, providing concrete, actionable, and tactical advice to help you build, launch, and grow your own product.

## Quick Start

**Browse by topic:** Start with [index/README.md](index/README.md) to explore episodes by topic.

**Browse all episodes:** See [index/episodes.md](index/episodes.md) for a complete table with AI-generated summaries.

**Search transcripts:**
```bash
grep -r "product-market fit" episodes/
```

## Repository Structure

```
├── episodes/                    # 269 episode transcripts
│   └── {guest-name}/
│       └── transcript.md
├── index/                       # AI-generated topic index
│   ├── README.md                # Main entry point
│   ├── episodes.md              # Full episodes table
│   ├── product-management.md    # Episodes about product management
│   ├── leadership.md            # Episodes about leadership
│   └── ...                      # 50 topic files
└── scripts/
    └── build-index.sh           # Script to regenerate index
```

## Episode Format

Each episode has its own folder named after the guest(s), containing a `transcript.md` file with:

1. **YAML Frontmatter** - Structured metadata including:
   - `guest`: Name of the guest(s)
   - `title`: Full episode title
   - `youtube_url`: Link to the YouTube video
   - `video_id`: YouTube video ID
   - `description`: Episode description
   - `duration_seconds`: Episode length in seconds
   - `duration`: Human-readable duration
   - `view_count`: Number of views at time of archival
   - `channel`: Channel name

2. **Transcript Content** - Full text transcript of the episode

## Topic Index

The `index/` folder contains AI-generated summaries and keywords for each episode, organized by topic:

| Topic | Description |
|-------|-------------|
| [Product Management](index/product-management.md) | 57+ episodes on PM skills and practices |
| [Leadership](index/leadership.md) | Episodes on management and leadership |
| [Growth Strategy](index/growth-strategy.md) | Growth tactics and frameworks |
| [Product-Market Fit](index/product-market-fit.md) | Finding and measuring PMF |

See [index/README.md](index/README.md) for the complete list of 50 topics.

## Rebuilding the Index

The index is generated using Claude CLI. To regenerate:

```bash
./scripts/build-index.sh
```

This processes all transcripts through Claude to generate summaries and keywords. Takes approximately 45 minutes for all 269 episodes. The script supports resuming if interrupted.

## Usage with AI

### Loading Transcripts

Each transcript is a standalone markdown file that can be easily parsed by AI systems. The YAML frontmatter provides structured metadata that can be extracted programmatically.

### Example: Reading a Transcript

```python
import yaml

def read_transcript(filepath):
    with open(filepath, 'r') as f:
        content = f.read()

    # Split frontmatter and content
    parts = content.split('---')
    if len(parts) >= 3:
        frontmatter = yaml.safe_load(parts[1])
        transcript = '---'.join(parts[2:])
        return frontmatter, transcript
    return None, content

# Example usage
metadata, transcript = read_transcript('episodes/brian-chesky/transcript.md')
print(f"Guest: {metadata['guest']}")
print(f"Title: {metadata['title']}")
```

## Episode Count

This archive contains **269 transcripts** from Lenny's Podcast episodes.

## Data Sources

- **Transcripts**: Sourced from the Lenny's Podcast Transcripts Archive
- **Metadata**: Extracted from the [Lenny's Podcast YouTube channel](https://www.youtube.com/@LennysPodcast)

## Contributing

If you notice any issues with the transcripts or metadata, please open an issue or submit a pull request.

## Disclaimer

This archive is for educational and research purposes. All content belongs to Lenny's Podcast and the respective guests. Please visit the official YouTube channel to support the creators.

## License

The transcripts are provided for personal and educational use. Please respect the original content creators' rights.
