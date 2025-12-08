# Advent of Code

Solutions for the [Advent of Code 2025](https://adventofcode.com/) using [Zig](https://ziglang.org/).

<!-- mdformat-toc start --slug=github --no-anchors --maxlevel=6 --minlevel=1 -->

- [Advent of Code](#project-name)
  - [Getting Started](#getting-started)
    - [Prerequisites](#prerequisites)
    - [Quick Start](#quick-start)
    - [Available Tools](#available-tools)
    - [Task Automation](#task-automation)
    - [Code Formatting](#code-formatting)
    - [Project Structure](#project-structure)
  - [Core Usage](#core-usage)

<!-- mdformat-toc end -->

## Getting Started

### Prerequisites

- [Nix](https://nixos.org/download.html) with flakes enabled
- [direnv](https://direnv.net/) for automatic environment loading

### Quick Start

1. Enter the development shell:

   ```bash
   nix develop
   ```

1. Or with direnv installed:

   ```bash
   direnv allow
   ```

### Task Automation

This project uses [mask](https://github.com/jacobdeichert/mask) for task automation. View available tasks:

```bash
mask --help
```

### Code Formatting

Use the nix formatter which is managed by `treefmt.nix`:

```bash
nix fmt
```

### Project Structure

```
.
├── flake.nix          # Nix flake configuration
├── treefmt.nix        # Formatter configuration
├── maskfile.md        # Task definitions
├── .envrc             # direnv configuration
└── README.md          # This file
```

## Core Usage

To run the solution for a specific day, run a command like:

```bash
zig build run -- --day [DAY]
```

Most days have a `--example` flag to run the example input instead of the actual input.
