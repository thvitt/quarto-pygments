# Pygments Quarto Extension

This project is a Quarto extension that provides syntax highlighting using the [Pygments](https://pygments.org/) library. It is designed to support languages that may not be available in Quarto's default highlighter (Skylighting).

## Project Overview

- **Purpose**: Enhanced syntax highlighting for Quarto documents using `pygmentize`.
- **Technologies**: Quarto, Lua (Pandoc filters), Pygments.
- **Key Files**:
    - `_extensions/pygments/pygments.lua`: The Lua filter that processes code blocks and inline code.
    - `_extensions/pygments/_extension.yml`: Extension metadata and configuration.
    - `example.qmd`: Demonstration document.

## Architecture

The extension works as a Pandoc filter. It identifies `Code` and `CodeBlock` elements that have a language class. It uses `quarto.doc.is_format()` to detect the output format and processes accordingly:

### HTML Support
For HTML output, the filter:
1. Calls `pygmentize` with `-f html`.
2. Replaces the element with a `RawInline` or `RawBlock` containing the highlighted HTML.
3. Checks for the existence of `pygments.css` in the extension directory.
4. If missing, it generates it using `pygmentize -S default -f html -a .sourceCode`.
5. Injects the stylesheet as a Quarto HTML dependency.

### LaTeX and Beamer Support
For LaTeX and Beamer output, the filter:
1. Calls `pygmentize` with `-f latex`.
2. Replaces the element with a `RawInline` or `RawBlock` containing the highlighted LaTeX.
3. For Beamer code blocks, it writes the LaTeX to a temporary `.tex` file and uses `\input{...}`. This avoids the requirement for `[fragile]` frames.
4. Injects the required Pygments LaTeX macros into the header using `quarto.doc.include_text`.
5. Adds dependencies for the `fancyvrb` and `color` LaTeX packages.

### Other Formats
For other formats (e.g., Markdown, Typst, etc.), the filter leaves the code elements untouched, allowing Quarto's default highlighter or other filters to process them.

## Requirements

- **Quarto**: Version 1.9.0 or higher.
- **Pygments**: The `pygmentize` command must be installed and available in your system's PATH (usually via `pip install Pygments`).

## Usage

### Installation

To install the extension in a Quarto project:

```bash
quarto add <github-organization>/pygments
```

### Configuration

Add the filter to your `_quarto.yml` or document front matter:

```yaml
filters:
  - pygments
```

You can optionally set a default language for inline code using `inline-code-lang`:

```yaml
title: "My Document"
inline-code-lang: python
filters:
  - pygments
```

## Development

### Running the Example

To test the extension, render the provided example:

```bash
quarto render example.qmd
```

### Conventions

- **Lua Filters**: The logic is contained within `_extensions/pygments/pygments.lua`.
- **HTML Output**: The filter generates HTML raw blocks/inlines. It attempts to use classes consistent with Quarto's default output (`sourceCode`) to maintain layout compatibility.
- **Error Handling**: If `pygmentize` is not found or fails, the filter falls back to the original unhighlighted code.
