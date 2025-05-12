---
trigger: always_on
---

# Writing Format Guidelines

1. Use PascalCase for all file names (e.g., `PrepperGuidelines.asciidoc`, `UserStoryMetadata.asciidoc`).
1. Place narrative chapters in the `/Chapters` folder.
1. Place reference material and templates in the `/Appendices` folder.
1. Store all image assets in the `/Images` directory using PascalCase (e.g., `PipelineDiagram.png`).
1. CSS and styling assets go in the `/CSS` folder.
1. Font files go in the `/Fonts` folder.
1. The book cover image should reside in the `/Cover` folder.
1. AI agent YAML files go into the `/agents` folder (e.g., `Pepper.yaml`).
1. AsciiDoc is the preferred format for all content chapters (`.asciidoc`).
1. Markdown is used for documentation (`.md`) such as this guide and tone/style documents.
1. Use proper heading hierarchy: `= Title` for chapters, `== Section`, `=== Subsection`, etc.
1. Keep lines under 120 characters for readability and version control diffs.
1. Use code blocks for YAML, JSON, or CLI snippets.
1. Maintain UTF-8 encoding with no BOM and no trailing whitespace.
1. Don't rewrite vast chunks at a time. Small incremental updates, typically no more than a few paragraphs in a single edit.
1. Don't talk about tools that will go out of date.