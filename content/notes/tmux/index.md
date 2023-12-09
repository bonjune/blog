---
title: "tmux 사용하기"
date: 2023-12-03T12:57:56-05:00
tags: programming
draft: true
---

`tmux` is a terminal multiplexer, which allows us to use multiple terminals in one terminal.

## Launching `tmux`

- `tmux`: creates a tmux session and attaches to it
- `tmux ls`: lists all tmux sessions

## Splitting a Panel

- `<C-b> "` : horizontally
- `<C-b> %` : vertically

## Managing Windows

- `<C-b> c` : create a new window
- `<C-b> n` : rename the current window
- `<C-b> {n}` : Go to `{n}`-th window
