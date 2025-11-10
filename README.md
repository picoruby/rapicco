# Rapicco

A wrapper tool of PicoRuby Rapicco terminal-based presentation.

## Overview

Rapicco is a tool that shows presentation slide on terminal emulator by running picoruby process.
It also converts Rapicco presentations  into PDF documents capturing the ANSI terminal output from Rapicco and renders it as a high-quality PDF.

## Requirements

- Ruby 3.0 or later
- Cairo graphics library
- PicoRuby with Rapicco installed

## Installation

```bash
gem install rapicco
```

Or add to your Gemfile:

```ruby
gem 'rapicco'
```

## Usage

**Show presentation:**
```bash
bundle exec rapicco input.md
```

**Generate PDF:**
```bash
bundle exec rapicco --print input.md
```

## How it generates PDF

1. Executes Rapicco with the input markdown file
2. Captures each page of the presentation via PTY
3. Parses ANSI escape sequences (colors, cursor positioning, block characters)
4. Renders each page to PDF using Cairo graphics library
5. Combines all pages into a single PDF document

## License

Copyright © 2025 HASUMI Hitoshi. See MIT-LICENSE for further details.
