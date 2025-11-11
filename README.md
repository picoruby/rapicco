# Rapicco

[![Test](https://github.com/picoruby/rapicco/actions/workflows/test.yml/badge.svg)](https://github.com/picoruby/rapicco/actions/workflows/test.yml)

A wrapper tool of PicoRuby Rapicco terminal-based presentation.

## Overview

Rapicco is a tool that shows presentation slide on terminal emulator by running picoruby process.
It also converts Rapicco presentations  into PDF documents capturing the ANSI terminal output from Rapicco and renders it as a high-quality PDF.

## Requirements

- Ruby (you can see supported versions in [rapicco.gemspec](rapicco.gemspec))
- Cairo graphics library
- PicoRuby with Rapicco installed
  - `export PICORUBY_PATH=path/to/picoruby` needs to be set

## Installation

```bash
gem install rapicco
```

## Usage

### Create a presentation project (recommended)

1. Create a new presentation project along with `mkdir`:

```bash
rapicco new my-presentation
cd my-presentation
```

Or in existing directory,

```bash
cd my-presentation
rapicco new .
```

> [!WARNING]
> The above command will override existing files.

This generates:
- `Gemfile` with rapicco gem
- `Rakefile` with presentation tasks
- `slide.md` template
- `config.yaml` configuration
- `README.md` template
- `.gitignore`

2. Install dependencies:

```bash
bundle install
```

3. Use rake tasks to manage your presentation:

```bash
bundle exec rake -T
```

Available tasks:
```
rake gem      # Create gem package
rake pdf      # Generate PDF
rake publish  # Publish gem to RubyGems.org
rake run      # Run presentation
```

**Show presentation:**
```bash
bundle exec rake run
```

**Generate PDF:**
```bash
bundle exec rake pdf
```

**Create gem package:**
```bash
bundle exec rake gem
```

### Using CLI directly

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
