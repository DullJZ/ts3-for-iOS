# TeamSpeak 3 Official Client Coverage Matrix

This document tracks progress toward covering most TeamSpeak 3 desktop client workflows on iOS and Mac Catalyst. It is an implementation checklist, not a completion claim.

Status legend:

- Done: implemented with visible iOS UI and Catalyst menu or shared sheet access where appropriate.
- Partial: useful support exists, but important official-client workflow pieces are missing or not easy to reach.
- Missing: no meaningful user-facing implementation yet.

## Core Connection And Server View

| Area | Status | Current Evidence | Remaining Work |
| --- | --- | --- | --- |
| Server connection with password | Done | `ConnectView`, `TS3AppModel.connect()`, bookmark/recent connection state, connection diagnostics export, and reconnect policy controls | Expand real-server troubleshooting fields if additional protocol metrics are exposed. |
| Channel tree and online clients | Done | Main channel/client list, refresh actions, channel switching, persisted channel tree expansion state | Improve very large server navigation if real-server scale testing shows issues. |
| Channel join passwords | Done | Password prompts for protected channel join/move operations | Add saved per-channel password helpers if needed. |
| Invite links | Done | Copy current invite and full invite links, bookmark invite copy | Add incoming invite routing tests for more URL variants. |
| Recent connections | Done | Connection manager import/export, global entry, local notes, filter presets, and duplicate cleanup | Add richer real-server diagnostics if future connection history fields are exposed. |

## Voice And Audio

| Area | Status | Current Evidence | Remaining Work |
| --- | --- | --- | --- |
| Receive voice | Done | Opus audio receive/playback pipeline, per-user playback preferences, and audio diagnostics snapshot with connection loss metrics | Add deeper jitter buffer diagnostics if exposed by the audio engine. |
| Push-to-talk | Done | PTT action, Catalyst menu shortcut, microphone permission flow, configurable shortcut recorder | Add lower-level global hotkey capture if platform APIs allow it. |
| Continuous transmission | Done | Audio settings transmit mode presets, persistence, live input meter, and calibration diagnostics | Verify long-running capture behavior on iOS hardware and Catalyst. |
| Voice activation | Partial | Mode and threshold settings, presets, persisted profiles, diagnostics snapshot, live input meter, and threshold calibration action exist | Verify end-to-end behavior on iOS hardware and Catalyst. |
| Input/output mute | Done | Main UI and Catalyst menu actions | Add clearer global status indicators on compact layouts. |
| Audio devices and profiles | Partial | Audio routes, route availability notes, profile import/export, user playback backup | Validate route switching behavior on real iOS and Mac Catalyst devices. |

## Messaging

| Area | Status | Current Evidence | Remaining Work |
| --- | --- | --- | --- |
| Channel/server/private text chat | Done | `ChatSheet`, send methods, local history, per-conversation filtering for server/channel/private threads | Add richer transcript formatting. |
| Chat history management | Done | Local history, filters, conversation selector, presets, transcript/history import/export, offline access, configurable retention settings | Add richer transcript formatting if needed. |
| Offline messages | Partial | Inbox, compose, read/delete, local cached history, disconnected access, draft persistence, filters and presets | Validate server-side read/delete behavior against real servers. |
| Pokes | Partial | Receive poke notifications/events, online client-row poke, database-record online poke, poke-back, and online contact poke actions exist | Add broader real-server validation and any remaining context-menu entry points found in official-client audit. |
| Whisper | Partial | Whisper sheet, presets, targets, configurable hold-to-whisper/tap-to-toggle activation, temporary activation controls, separate Catalyst start/stop shortcut bindings, route snapshots, recent activation log export, activation diagnostics, and tests for protocol serialization plus activation log behavior | Verify full voice whisper routing against real servers and add true key-up global hotkey capture if platform APIs allow it. |
| Event log | Done | Events sheet, unread handling, filter presets, visible snapshot export, persistent local event archive, and archive import/restore preview | Add richer per-event restore choices if archive formats expand. |

## Server And Channel Administration

| Area | Status | Current Evidence | Remaining Work |
| --- | --- | --- | --- |
| Server information | Done | Server info sheet and Catalyst entry | Add more raw virtual server fields where available. |
| Server edit/settings | Partial | Server settings editor, port, autostart, machine id, quotas, total file-transfer bandwidth limits, host fields including banner mode/refresh interval, icon support, server-list visibility, server log option switches, default group editing, identity/client-version requirements, temporary password management with persistent recent results and filter/sort presets, complaint and anti-flood controls | Audit all official server edit tabs and fill missing fields. |
| Channel create/edit/delete/move | Partial | Channel editor with codec quality/latency/encryption controls, voice/music codec presets, needed talk/subscribe/description-view powers, codec configuration summaries, legacy/encryption codec diagnostics, official range validation, move preview, draft import/export, icon import, password prompts, and permission inheritance impact visibility | Validate advanced codec controls against real servers and add deeper inherited effective-value tracing if protocol data allows it. |
| Client actions | Partial | Client row menus, centralized talk request queue with grant/deny/copy and batch handling, online user complaint/contact shortcuts, database-record online/contact actions, move/kick/ban/message style workflows in UI | Audit all official context-menu actions and fill remaining bookmark-contact edge actions. |
| Server logs | Partial | Query presets, paged log viewing with begin position, level/channel/search filters, visible exports, and persistent recent log results for offline review | Validate broader log filters and real-server log permissions. |
| Ban list | Partial | Ban list management, add/delete/delete-visible/delete-all, add-rule fields for IP/name/UID/myTeamSpeak ID/last nickname, filters, presets, backup import/export, visible exports, and persistent recent ban results for offline review | Test advanced ban fields against real servers and audit edit behavior. |
| Complaints | Partial | Complaint management with target picker, direct create/delete, visible export, filter presets, complaint-source contact actions, and persistent recent results for offline review | Validate complaint add/remove flows against real servers and fill any remaining official-client context-menu edge cases. |
| Privilege keys | Partial | Privilege key manager with create/use/delete, generated-key actions, readable exports/backups, filter presets, and persistent recent results for offline review | Validate create/use/delete flows against real servers and audit any official-client edge fields. |

## Permissions And Groups

| Area | Status | Current Evidence | Remaining Work |
| --- | --- | --- | --- |
| Permission viewer/editor | Partial | Permission scopes, direct/negated/skip filters, inheritance-impact labels, presets, backup structures | Validate complete server/channel/client/group permission editing against official semantics. |
| Server groups | Partial | Group management with create/copy/rename/delete, member add/remove by database id, visible exports, filter presets, and persistent recent group lists for offline review | Validate group mutation semantics and permission requirements against real servers. |
| Channel groups | Partial | Channel group management with create/copy/rename/delete, member browsing with channel-context filters, set-by-database-id actions, visible exports, filter presets, and persistent recent group lists for offline review | Validate channel-group mutation semantics against real servers. |
| Permission backup/import | Partial | Permission backup export, guided restore preview with conflict/addition names, upsert restore, and conflict/addition counts | Add broader restore conflict handling and validate permission backup semantics against real servers. |

## Files

| Area | Status | Current Evidence | Remaining Work |
| --- | --- | --- | --- |
| Channel file browser | Done | Browse by channel/path/password, server file status summary, bookmarks, search/sort/filter presets, move/rename conflict previews | Add deeper cross-directory conflict previews if needed. |
| Upload/download | Done | Transfer socket, upload importer, download queue, retry/cancel, queue export | Add folder upload/download if server protocol and platform sandbox allow it. |
| File operations | Done | Rename, move, delete, create directory, batch actions, rename plus single/batch move conflict previews, and upload overwrite/resume conflict details | Validate conflict behavior against real servers and add cross-directory previews if server listing is expanded. |
| Local downloaded files | Done | Persistent recent download history, downloads folder open/copy/cleanup actions, export/open/copy/remove actions, queue row open local file | Add richer downloads folder organization if needed. |

## Identity, Contacts, Bookmarks, And Migration

| Area | Status | Current Evidence | Remaining Work |
| --- | --- | --- | --- |
| Identity management | Done | Global identity sheet, import/export, snapshots, Catalyst entry | Add multi-identity switching if official-client parity requires it. |
| Bookmarks | Done | Bookmark list/folders/import/export, connection manager, full bookmark editor for connection options, saved phonetic nickname, local notes, and duplicate cleanup | Audit official-client bookmark edge fields if future TS3 URL options are added. |
| Contacts | Partial | Contact manager entry, online-user bulk contact import/status actions, complaint-source shortcuts, online and database-client friend/block/ignore/note shortcuts, visible batch actions, and local ignore suppression for private messages and pokes | Audit contact behavior against real server data and fill any official-client edge actions. |
| Client migration | Done | Client package import/export covering local settings groups, channel layout state, schema metadata, notification/shortcut/audio preview details, and import preview confirmation | Add richer per-section restore choices if package formats expand. |

## Notifications, Shortcuts, And Platform Integration

| Area | Status | Current Evidence | Remaining Work |
| --- | --- | --- | --- |
| Local notifications | Done | Global notification settings, presets, import/export with overwrite preview, event types, per-server mute rules, per-contact mute rules, and quiet-hours scheduling | Add richer notification category-specific schedules if official-client parity requires them. |
| Keyboard shortcuts | Partial | User-editable shortcut bindings, structured recorder, duplicate warnings, import/export/reset controls, validation hints, and Catalyst menu bindings for messaging, voice, server info/settings, admin tools, permissions, complaints, temporary passwords, and files | Add true key-event capture/global hotkey support if platform APIs allow it. |
| Catalyst menus | Partial | Global TeamSpeak menu for major connected workflows including server settings/info, logs, files, permissions, groups, complaints, privilege keys, temporary passwords, and voice controls | Split into more native menus if the app grows beyond one command menu. |
| iOS accessibility and compact layout | Partial | SwiftUI shared sheets and forms | Audit dynamic type, VoiceOver labels, and compact split behavior. |

## Release And Diagnostics

| Area | Status | Current Evidence | Remaining Work |
| --- | --- | --- | --- |
| Debug logs | Done | Debug log page with level/search filtering, visible-log copy/export, clear, and diagnostic report export package | Add richer packaged attachments if platform sandbox requirements emerge. |
| Build coverage | Done | README documents SwiftPM, iOS, Catalyst, CI artifact builds | Keep README feature list updated with current capabilities. |
| Protocol test coverage | Partial | Unit tests for command parsing, admin command builders, file transfer init/response parameters, URLs, byte buffer, icons, whisper, notification import previews, and client migration preview details | Add more tests for package import/export edge cases. |

## Next Implementation Priorities

1. Audit remaining server/channel settings fields against official-client tabs and fill missing fields.
2. Validate file operation conflict behavior and advanced codec controls against real servers.
3. Verify full voice whisper routing against real servers and add true key-up global hotkey capture if platform APIs allow it.
