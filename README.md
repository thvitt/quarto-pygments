# Pygments Extension For Quarto

A Quarto extension that provides syntax highlighting using
[Pygments](https://pygments.org/).

## Installing

``` bash
quarto add thvitt/quarto-pygments
```

This will install the extension under the `_extensions` subdirectory. If you're
using version control, you will want to check in this directory.

Make sure you have pygments, including the pygmentize binary, installed.

## Using

Enable the filter using

``` yaml
filters:
  - pygments
```

You can use the metadata fields `default-inline-lang` and `default-block-lang`
to define a default language for inline and block code fields that have no
language annotation.

## Example

Here is the source code for a minimal example: [example.qmd](example.qmd).

## AI note

The code has been developed with the help of Gemini. All code has been manually
reviewed by me.
