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

The extension works as a Pandoc filter. It identifies `Code` and `CodeBlock` elements that have a language class. For each element:
1. It calls the `pygmentize` command-line tool.
2. It passes the code and language to `pygmentize` to generate HTML.
3. It replaces the original element with a `RawInline` or `RawBlock` containing the highlighted HTML.

If any code is highlighted, the filter:
1. Checks for the existence of `pygments.css` in the working directory.
2. If missing, it generates it using `pygmentize -S default -f html -a .sourceCode`.
3. Injects a `<link rel="stylesheet" href="pygments.css">` into the document's header.

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
