Changelog v1.1.2

New Features:

Added dedicated VoiceChat tab with microphone icon

Implemented comprehensive voice bypass system with three methods

Added right-side groupbox explaining bypass techniques in plain language

Created automatic voice reconnection system with configurable delay

Added force unban functionality for all players in the server

Voice Bypass System:

Full Hook method: Deep system interception for maximum reliability

Network Only method: Packet-level modification for lower detection risk

Filter Only method: Content filtering bypass for lightweight operation

Visual status indicator showing when voice is active

Proper hook cleanup to prevent memory leaks

Interface Improvements:

Organized voice controls into logical groupboxes

Added explanatory labels for each bypass method

Implemented configurable rejoin delay (1-10 seconds)

Added clear voice data button for troubleshooting

Settings tab icon updated from "gear" to "settings"

Technical Enhancements:

Robust error handling with pcall throughout

Proper metatable hook management with restoration

Network packet interception for RemoteEvents

Data store manipulation for ban removal

Memory-efficient hook storage and cleanup

System Integration:

Automatic creation of fake UI to mimic legitimate voice system

Continuous connection maintenance with adjustable intervals

Full compatibility with Obsidian UI library and addons

Persistent configuration saving through SaveManager

Theme support through ThemeManager

Safety & Controls:

Clean unload system that removes all hooks

Visual warnings about detection risks

Separate unload buttons for script and UI

Configurable menu keybind (default: RightShift)

DPI scaling options for different screen resolutions
