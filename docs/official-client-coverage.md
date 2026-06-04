# TeamSpeak 3 Official Client Coverage Matrix

This document tracks progress toward covering most TeamSpeak 3 desktop client workflows on iOS and Mac Catalyst. It is an implementation checklist, not a completion claim.

Status legend:

- Done: implemented with visible iOS UI and Catalyst menu or shared sheet access where appropriate.
- Partial: useful support exists, but important official-client workflow pieces are missing or not easy to reach.
- Missing: no meaningful user-facing implementation yet.

## Core Connection And Server View

| Area | Status | Current Evidence | Remaining Work |
| --- | --- | --- | --- |
| Server connection with password | Done | `ConnectView`, `TS3AppModel.connect()`, bookmark and recent connection state | Add more connection diagnostics and reconnect policy controls. |
| Channel tree and online clients | Done | Main channel/client list, refresh actions, channel switching | Improve very large server navigation and persistent channel tree expansion state. |
| Channel join passwords | Done | Password prompts for protected channel join/move operations | Add saved per-channel password helpers if needed. |
| Invite links | Done | Copy current invite and full invite links, bookmark invite copy | Add incoming invite routing tests for more URL variants. |
| Recent connections | Done | Connection manager import/export and global entry | Add duplicate cleanup UX and richer connection notes. |

## Voice And Audio

| Area | Status | Current Evidence | Remaining Work |
| --- | --- | --- | --- |
| Receive voice | Done | Opus audio receive/playback pipeline and per-user playback preferences | Add jitter/packet loss diagnostics UI. |
| Push-to-talk | Done | PTT action, Catalyst menu shortcut, microphone permission flow | Add user-configurable shortcut capture beyond displayed defaults. |
| Continuous transmission | Done | Audio settings transmit mode presets and persistence | Add live input meter calibration view. |
| Voice activation | Partial | Mode and threshold settings exist | Verify end-to-end behavior on iOS hardware and Catalyst, then add tests/diagnostics. |
| Input/output mute | Done | Main UI and Catalyst menu actions | Add clearer global status indicators on compact layouts. |
| Audio devices and profiles | Partial | Audio routes, profile import/export, user playback backup | Catalyst route selection depends on system availability; add better unavailable-state messaging. |

## Messaging

| Area | Status | Current Evidence | Remaining Work |
| --- | --- | --- | --- |
| Channel/server/private text chat | Done | `ChatSheet`, send methods, local history | Add richer transcript formatting and per-conversation threading. |
| Chat history management | Done | Local history, filters, presets, transcript/history import/export, offline access | Add retention controls beyond fixed history limit. |
| Offline messages | Partial | Inbox, compose, read/delete, filters and presets | Add global offline history access without live refresh and better draft handling. |
| Pokes | Partial | Receive poke notifications/events, online client-row poke, poke-back, and online contact poke actions exist | Add broader real-server validation and any remaining context-menu entry points found in official-client audit. |
| Whisper | Partial | Whisper sheet, presets, targets, tests for protocol serialization | Verify full voice whisper routing against real servers and add hotkey-style activation UI. |
| Event log | Done | Events sheet and unread handling | Add export/import or persistent event archive if wanted. |

## Server And Channel Administration

| Area | Status | Current Evidence | Remaining Work |
| --- | --- | --- | --- |
| Server information | Done | Server info sheet and Catalyst entry | Add more raw virtual server fields where available. |
| Server edit/settings | Partial | Server settings editor, quotas, host fields, icon support | Audit all official server edit tabs and fill missing fields. |
| Channel create/edit/delete/move | Partial | Channel editor, draft import/export, icon import, password prompts | Add full channel permission inheritance visibility and richer codec controls. |
| Client actions | Partial | Client row menus, move/kick/ban/message style workflows in UI | Audit all official context-menu actions and fill missing poke/complaint/bookmark-contact actions. |
| Server logs | Partial | Query presets and log viewing | Add broader log filters and persistent exports per server. |
| Ban list | Partial | Ban list management entry | Audit ban edit/add fields and test against real servers. |
| Complaints | Partial | Complaint management entry | Add more direct complaint creation/removal paths from client context menus. |
| Privilege keys | Partial | Privilege key manager entry | Audit create/edit/delete flows and export coverage. |

## Permissions And Groups

| Area | Status | Current Evidence | Remaining Work |
| --- | --- | --- | --- |
| Permission viewer/editor | Partial | Permission scopes, filters, presets, backup structures | Validate complete server/channel/client/group permission editing against official semantics. |
| Server groups | Partial | Group management, member add by database id | Add all official group create/copy/delete/rename workflows if not present. |
| Channel groups | Partial | Channel group management, member add by database id | Add stronger channel-group member browsing by channel/client context. |
| Permission backup/import | Partial | Permission backup model and import/export code paths | Add guided restore UX and conflict reporting. |

## Files

| Area | Status | Current Evidence | Remaining Work |
| --- | --- | --- | --- |
| Channel file browser | Done | Browse by channel/path/password, bookmarks, search/sort/filter presets | Add quota/status summary near browser header. |
| Upload/download | Done | Transfer socket, upload importer, download queue, retry/cancel, queue export | Add folder upload/download if server protocol and platform sandbox allow it. |
| File operations | Done | Rename, move, delete, create directory, batch actions | Add conflict-resolution previews for batch move/rename. |
| Local downloaded files | Done | Last download export/open, queue row open local file | Add downloads folder management/history beyond last file. |

## Identity, Contacts, Bookmarks, And Migration

| Area | Status | Current Evidence | Remaining Work |
| --- | --- | --- | --- |
| Identity management | Done | Global identity sheet, import/export, snapshots, Catalyst entry | Add multi-identity switching if official-client parity requires it. |
| Bookmarks | Partial | Bookmark list/folders/import/export, connection manager | Add richer bookmark editing UI for all connection options. |
| Contacts | Partial | Contact manager entry | Audit friend/block/ignore behavior against real server data. |
| Client migration | Done | Client package import/export covering local settings groups | Add versioned migration preview before import. |

## Notifications, Shortcuts, And Platform Integration

| Area | Status | Current Evidence | Remaining Work |
| --- | --- | --- | --- |
| Local notifications | Done | Global notification settings, presets, import/export, event types | Add per-server/per-contact notification rules. |
| Keyboard shortcuts | Partial | Displayed Catalyst shortcut list and menu bindings | Add user-editable shortcuts/hotkeys and capture UI. |
| Catalyst menus | Partial | Global TeamSpeak menu for major connected workflows | Split into more native menus if the app grows beyond one command menu. |
| iOS accessibility and compact layout | Partial | SwiftUI shared sheets and forms | Audit dynamic type, VoiceOver labels, and compact split behavior. |

## Release And Diagnostics

| Area | Status | Current Evidence | Remaining Work |
| --- | --- | --- | --- |
| Debug logs | Done | Debug log page, copy/export/clear | Add structured log filtering and attach-to-bug-report package. |
| Build coverage | Done | README documents SwiftPM, iOS, Catalyst, CI artifact builds | Keep README feature list updated with current capabilities. |
| Protocol test coverage | Partial | Unit tests for command parsing, URLs, byte buffer, icons, whisper | Add more tests for admin command builders, file transfer states, notification settings, and import/export packages. |

## Next Implementation Priorities

1. Add global offline message history access that does not require a live server refresh.
2. Add poke sending UI from client rows and contacts.
3. Add retention controls for chat history and downloaded file history.
4. Audit server/channel settings fields against official-client tabs and fill missing fields.
5. Add user-configurable hotkey capture for PTT, mute, whisper, and common Catalyst actions.
