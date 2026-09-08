# omarchy-display-arrange

An [Omarchy](https://omarchy.org/) shell bar widget: brightness slider plus
one-click Left/Top/Right arrangement for a second monitor. A clone of the
stock `omarchy.monitor` widget with a monitor-position picker added.

Arrangement is only offered for the classic laptop-plus-one-external-monitor
pairing, and the current arrangement is derived from live monitor geometry
(not a remembered choice), so it stays honest if the layout changes some
other way.

## Install

```
omarchy plugin add https://github.com/Thomster/omarchy-display-arrange.git
```

## Requirements

- Hyprland (uses `hyprctl` for monitor geometry/positioning)

## How this came to be

This is a personal customization for my own Omarchy setup, built with the
help of [Claude Code](https://claude.com/claude-code) (Anthropic's AI coding
agent). I use it daily on my own machine, but I'm not a professional plugin
developer — please read through the source before installing, especially
anything that touches system or network state, and open an issue if
something looks off.

## License

MIT
