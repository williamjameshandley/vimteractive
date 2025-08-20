# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Vimteractive is a Vim plugin that provides a simple interface to send commands from text files to interactive programs (REPLs) via tmux. It's a complete rewrite on the vimteractive3 branch that uses tmux and vim-slime instead of vim's native terminal. Supports Python/IPython, Julia, R, bash/zsh, Maple, Mathematica, Clojure, APL, and AI assistants (sgpt, gpt-command-line, aichat).

## Architecture (vimteractive3 branch)

The plugin consists of three main components:

1. **plugin/vimteractive.vim** - Main plugin initialization:
   - Defines global configuration variables
   - Sets up REPL command mappings (`:Ipython`, `:Iaichat`, etc.)
   - Configures key mappings (Ctrl-S send, Ctrl-Y retrieve)
   - Integrates with vim-slime (sets `g:slime_target = 'tmux'`)
   - Default REPL is now 'gpt' instead of autodetect

2. **autoload/vimteractive.vim** - Core implementation:
   - Creates tmux sessions with unique names (pattern: `/tmp/RAND-NUM-REPL`)
   - Manages tmux pane connections via vim-slime
   - Implements REPL-specific response retrieval functions
   - Handles markdown code block extraction from AI responses
   - Opens external terminal windows (xterm) attached to tmux sessions


## Key Implementation Details

### REPL Management
- Each REPL runs in a tmux session with a unique name
- Sessions are named: `/tmp/{random}-{number}-{repl_type}`
- External terminal windows (xterm) are spawned to display the tmux session
- Uses xdotool to manage window focus

### Supported REPLs with Response Retrieval
- **ipython**: Reads from logfile, extracts `#[Out]#` prefixed lines
- **sgpt**: Reads JSON logfile, extracts last response
- **gpt**: Parses log for `gptcli-session - INFO - assistant:` entries
- **aichat**: Captures tmux pane output directly, finds text between prompts
- **zsh**: Reads script logfile, extracts text between shell prompts

### Command Placeholders
- `<LOGFILE>`: Replaced with log file path for output capture
- `<SESSION>`: Replaced with session name (for aichat)

## Dependencies

- Vim 8+ (though native terminal features not used in this branch)
- tmux (core multiplexing backend)
- vim-slime (handles text sending to tmux panes)
- xterm (or configurable terminal emulator)
- xdotool (window focus management)
- perl, col (for zsh output processing)
- Individual REPLs must be installed separately

## Configuration Variables

```vim
" Core configurations
g:vimteractive_terminal           " Terminal command (default: 'xterm -e')
g:vimteractive_default_repl       " Default REPL (default: 'gpt')
g:vimteractive_extract_markdown_code_blocks  " Extract code from markdown (default: 1)

" REPL definitions
g:vimteractive_commands            " Dict mapping REPL names to shell commands
g:vimteractive_bracketed_paste    " List of REPLs supporting bracketed paste
g:vimteractive_get_response       " Dict of response retrieval functions
g:vimteractive_default_repls      " Filetype to REPL mappings

" ZSH-specific
g:vimteractive_zsh_prompt          " Regex for zsh prompt (default: '^\$')
g:vimteractive_zsh_prompt_multiline  " Lines to skip for multiline prompts
```

## Key Mappings

- `Ctrl-S` - Send current line (normal), selection (visual), or line under edit (insert)
- `Alt-S` - Send all lines from start to current position
- `Ctrl-Y` - Retrieve last response (works for ipython, sgpt, gpt, aichat, zsh)
- `[v` / `]v` - Cycle backward/forward through connected terminals
- `[ok` / `]ok` / `yok` - Disable/enable/toggle markdown code block extraction

## Commands

- `:I<repl>` - Start specific REPL (e.g., `:Iipython`, `:Iaichat`)
- `:Iterm` - Start REPL based on filetype or default
- `:Iconn [buffer]` - Connect to existing REPL pane

## Current Branch Status

The vimteractive3 branch represents a major architectural change:
- Complete rewrite using tmux instead of vim's native terminal
- Added AI assistant support (sgpt, gpt-command-line, aichat)
- Implemented response retrieval for multiple REPLs
- Added markdown code block extraction
- Changed default REPL from autodetect to 'gpt'

Note: README.rst and doc/vimteractive.txt are outdated and don't reflect these changes.