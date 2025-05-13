---
trigger: always_on
---

# Writing Format Guidelines

1. Use kebab-case for all file names (e.g., `prepper-guidelines.asciidoc`, `user-story-metadata.asciidoc`).
1. Place narrative chapters in the `/chapters` folder.
1. Place reference material and templates in the `/appendices` folder.
1. Store all image assets in the `/images` directory using PascalCase (e.g., `pipeline-diagram.png`).
1. CSS and styling assets go in the `/css` folder.
1. Font files go in the `/fonts` folder.
1. The book cover image should reside in the `/cover` folder.
1. AI agent YAML files go into the `/agents` folder (e.g., `pepper.yaml`).
1. AsciiDoc is the preferred format for all content chapters (`.asciidoc`).
1. Markdown is used for documentation (`.md`) such as this guide and tone/style documents.
1. Use proper heading hierarchy: `= Title` for chapters, `== Section`, `=== Subsection`, etc.
1. Keep lines under 120 characters for readability and version control diffs.
1. Use code blocks for YAML, JSON, or CLI snippets.
1. Maintain UTF-8 encoding with no BOM and no trailing whitespace.
1. Don't rewrite vast chunks at a time. Small incremental updates, typically no more than a few paragraphs in a single edit.
1. Don't talk about tools that will go out of date.