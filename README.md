# Debug GUI Documentation

## Overview

The Debug GUI is a comprehensive server-side debugging tool for MTA:SA server administrators and developers. It provides a centralized graphical interface to view, filter, and manage debug messages with different severity levels, making it easier to troubleshoot scripts and track server behavior. All debug messages are shared across all admins, ensuring consistency and collaboration.

## Main Features

- **Real-time Debug Console**: View debug messages as they occur
- **Message Filtering**: Filter messages by severity level (info, warn, error, debug, or all levels)
- **Message Persistence**: Debug messages are saved between game sessions
- **Copy Functionality**: Easily copy individual messages, selected messages, or all messages
  - **Double-click to Copy**: Quickly copy any message by double-clicking it
- **Customizable Settings**: Configure sound alerts, auto-copy, and more
- **Admin Access Control**: Optional restriction to admin users
- **Keyboard Shortcuts**: Quick access through function keys
- **Duplicate Message Handling**: Automatically consolidates repeated messages with [DUP] counter
- **Send Debug Message**: Allows users to send custom debug messages directly from the GUI
- **Performance Stats**: Real-time FPS and memory usage monitoring
- **Watch Variables**: Monitor and track changes in variables/expressions in real-time
  - Support for any valid Lua expression
  - Automatic value updates
  - Color highlighting for changed values
- **Search Functionality**: Filter messages using the search bar
- **Export Logs**: Save debug messages to external files
- **Multi-Select**: Copy multiple selected messages at once

## Access Controls

- By default, the Debug GUI requires admin privileges
- Admins can toggle this requirement using the command `/dtoggleadmin`
- When a user logs out, the panel automatically closes if they no longer have privileges

## Keyboard Controls

- **F6**: Toggle the Debug GUI panel
  - Shows an error message if used without proper permissions
  - Opens/closes the panel for users with access

## Commands

### Debug Message Generation

- `/dinf [message]` - Generate an info message (Example: `/dinf Player connected`)
- `/dwar [message]` - Generate a warning message (Example: `/dwar Low server memory`)
- `/derr [message]` - Generate an error message (Example: `/derr Script execution failed`)
- `/ddbg [message]` - Generate a debug message (Example: `/ddbg Variable x = 5`)

### Admin Commands

- `/dhelp` - Display available debug commands
- `/dtoggle` - Toggle debug commands on/off
- `/dtoggleadmin` - Toggle whether admin access is required

## User Interface

### Main Debug Panel

- Message filtering dropdown
- Search functionality
- Clear messages button
- Copy options (last/selected/all messages)
- Export to file functionality
- Settings panel access
- Message grid with time, level, and content columns

### Performance Stats Panel

- Real-time FPS counter
- Memory usage monitor
- Automatically updates every second
- Linked to main debug panel visibility

### Watch Variables Panel

- Add/remove watch expressions
- Real-time value updates
- Expression validation
- Info panel with example expressions
- Highlighting for changed values
- Enable/disable feature through settings

### Settings Panel

- Auto-copy toggle
- Sound alerts toggle
- Duplicate message handling toggle
- Watch panel visibility toggle
- Watch feature enable/disable option

## Message Persistence

- Messages are automatically saved to a centralized XML file on the server
- Messages persist between server restarts and are shared among all admins
- The XML file location: `savedMessages.xml`

## Settings Persistence

All settings are saved per account including:

- Panel state
- Filter level
- Sound preferences
- Watch panel state
- Admin access requirements
- Duplicate handling preferences

## Export Functions

The Debug GUI provides several export functions for use in other resources:

- `clientDebugOutput` (Client) - Add a client-side debug message
- `exportDebugOutput` (Server) - Add a server-side debug message
- `getDebugLevels` (Shared) - Get the available debug levels
- `getDebugSounds` (Shared) - Get the sound IDs for each level
- `getDebugSettings` (Shared) - Get current debug settings
- `updateDebugSetting` (Shared) - Update a debug setting

## Example Usage in Scripts

```lua
-- Client-side debug message
exports.debuggui:clientDebugOutput("Testing client debug", "info")

-- Server-side debug message
exports.debuggui:exportDebugOutput("Database connected successfully", "debug")

-- Get current settings
local settings = exports.debuggui:getDebugSettings()

-- Update a setting
exports.debuggui:updateDebugSetting("soundAlertsEnabled", true)
```

## Troubleshooting

If the Debug GUI is not working as expected:

1. Ensure you have admin privileges if admin access is required
2. Check if debug commands are enabled with `/dtoggle`
3. Try restarting the debuggui resource
4. Verify the resource is correctly installed in your server
