# PasteDeck

> Lightweight, fast clipboard manager for macOS. Captures everything you copy, lists it, and lets you paste it back.

![Platform](https://img.shields.io/badge/macOS-14%2B-blue)
![Swift](https://img.shields.io/badge/Swift-6.2-orange)
![License](https://img.shields.io/badge/license-MIT-green)

## Install

```bash
brew tap EmirOzzturk/pastedeck
brew install --cask pastedeck
```

On first launch, grant **Accessibility** permission when prompted (needed for `Cmd+Shift+V`).

## Build from source

```bash
git clone https://github.com/EmirOzzturk/PasteDeck.git
cd PasteDeck

# Debug build
bash build_app.sh

# Release build
bash build_app.sh release

# Launch
open .build/PasteDeck.app
```

On first launch, macOS will ask for **Accessibility permission** for the `Cmd+Shift+V` shortcut — grant it.

## Usage

| Action | How |
|--------|-----|
| Open panel | Menu bar icon `📋` or `Cmd+Shift+V` |
| Select & paste | Arrow keys ↑↓ to navigate, `Enter` — auto-pastes |
| Search | Type in the search box, filters instantly |
| Pin | Right-click → Pin / Hover → 📌 icon |
| Delete | Right-click → Delete |
| Clear all | Footer "Clear All" (pinned items survive) |
| Close | `Esc` or click outside |

**Tip:** For HTML clips, right-click → **Copy Plain Text** to get just the text without formatting.

## Features

- 🚀 **Real-time** — 0.15s poll, near-instant capture
- 🖼️ **Image support** — Captures PNG/TIFF, displays thumbnails
- 📌 **Pin** — Frequently used clips are never pruned
- 🔍 **Live search** — Filter history as you type
- 🪟 **Position memory** — Drag the window, it remembers
- ⌨️ **Full keyboard** — Open, navigate, select, close — no mouse needed
- 🧹 **Self-cleaning** — 50-item LRU limit, auto-removes orphaned files

## Requirements

- macOS 14 Sonoma or later
- Swift 6.2

## License

MIT — free to use, fork, and distribute.
