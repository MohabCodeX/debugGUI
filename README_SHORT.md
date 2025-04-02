# Debug GUI Script

## Overview

A script providing a customizable debug GUI for admins, enabling real-time debugging, message filtering, and persistence.

## Key Features

- **Real-time Debug Console**: View and manage debug messages.
- **Message Filtering**: Filter by severity (info, warn, error, debug, or all levels).
- **Copy Functionality**: Copy messages (double-click to copy any message, or select multiple messages to copy them, or copy last msg directly).
- **Send Debug Message**: Send custom debug messages from the GUI.
- **Customizable Settings**: Configure sound alerts, auto-copy, and more.
- **Admin Access Control**: Optional restriction to admin users.
- **Message Persistence**: Messages saved across sessions.

## Commands

- `/dinf [message]` - Info message.
- `/dwar [message]` - Warning message.
- `/derr [message]` - Error message.
- `/ddbg [message]` - Debug message.
- `/dhelp` - List commands.
- `/dtoggle` - Toggle debug commands.
- `/dtoggleadmin` - Toggle admin access requirement.

## Usage

1. Add the resource to your server.
2. Start the resource.
3. Use **F6** to toggle the Debug GUI.
4. Admins can customize settings and manage debug messages.

---

# Debug GUI

MTA:SA Debug Console with real-time message monitoring, filtering, and performance tracking.

## Core Features

- Real-time debug message monitoring
- Message filtering by severity (info/warn/error/debug)
- Performance monitoring (FPS/Memory)
- Variable watch system
- Message search and export
- Admin access control
- Sound alerts
- Message persistence

## Quick Start

1. Press F6 to toggle panel
2. Use filter dropdown to select message types
3. Double-click messages to copy
4. Watch variables in real-time
5. Export logs as needed

## Commands

- `/dinf [msg]` - Info message
- `/dwar [msg]` - Warning message
- `/derr [msg]` - Error message
- `/ddbg [msg]` - Debug message
- `/dhelp` - Show commands
- `/dtoggleadmin` - Toggle admin requirement

## Export Functions

```lua
exports.debuggui:clientDebugOutput(message, level)  -- Client debug
exports.debuggui:exportDebugOutput(message, level)  -- Server debug
exports.debuggui:updateDebugSetting(setting, value) -- Update settings
```

## Settings

- Auto-copy messages
- Sound alerts
- Message duplication
- Watch panel visibility
- Admin access requirement

For full documentation, see README.md
