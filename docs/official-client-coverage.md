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
| Channel join passwords | Done | Password prompts for protected channel join/move operations, optional saved per-server/channel passwords, migration package backup/restore, and forget controls | Monitor real-server password retry behavior. |
| Invite links | Done | Copy current invite and full invite links, bookmark invite copy, incoming `ts3server://`/`teamspeak://` URL handling, opaque host:port parsing, parameter-alias tests | Monitor additional invite variants found in real-world links. |
| Recent connections | Done | Connection manager import/export, global entry, local notes, filter presets, and duplicate cleanup | Add richer real-server diagnostics if future connection history fields are exposed. |

## Voice And Audio

| Area | Status | Current Evidence | Remaining Work |
| --- | --- | --- | --- |
| Receive voice | Done | Opus audio receive/playback pipeline, per-user playback preferences, and audio diagnostics snapshot with connection loss metrics | Add deeper jitter buffer diagnostics if exposed by the audio engine. |
| Push-to-talk | Done | PTT action, Catalyst menu shortcut, microphone permission flow, configurable shortcut recorder | Add lower-level global hotkey capture if platform APIs allow it. |
| Continuous transmission | Done | Audio settings transmit mode presets, persistence, live input meter, self-status profile row copy summaries with VoiceOver actions, and calibration diagnostics | Verify long-running capture behavior on iOS hardware and Catalyst. |
| Voice activation | Partial | Mode and threshold settings, presets, persisted profiles, diagnostics snapshot, live input meter, and threshold calibration action exist | Verify end-to-end behavior on iOS hardware and Catalyst. |
| Input/output mute | Done | Main UI, compact global voice status strip, VoiceOver-readable mic/sound state, and Catalyst menu actions | Monitor compact layout feedback on real devices. |
| Audio devices and profiles | Partial | Audio routes, route availability notes, input device row copy summaries with VoiceOver actions, profile import/export with merge/sanitize tests, profile and per-user playback row copy summaries with VoiceOver actions, user playback backup | Validate route switching behavior on real iOS and Mac Catalyst devices. |

## Messaging

| Area | Status | Current Evidence | Remaining Work |
| --- | --- | --- | --- |
| Channel/server/private text chat | Done | `ChatSheet`, send methods, local history, per-conversation filtering for server/channel/private threads, and metadata-rich grouped transcript export | Monitor real-user transcript formatting needs. |
| Chat history management | Done | Local history, filters, conversation selector, presets, metadata-rich transcript/history import/export, offline access, configurable retention settings | Add richer per-message restore choices if history formats expand. |
| Offline messages | Partial | Inbox, compose, send-draft validation and copyable recipient/subject/body summary, read/delete, local cached history, disconnected access, local archive import/export with restore preview, read-state/sender distribution summaries, copyable message summary, draft persistence, filters and presets, row copy summaries, and VoiceOver row values/actions | Validate server-side read/delete behavior against real servers. |
| Pokes | Partial | Receive poke notifications/events, online client-row poke with validated/copyable send draft summaries, database-record and group-member online poke, poke-back with UID fallback, offline reply, online contact poke actions, row copy summaries, and VoiceOver row actions exist | Add broader real-server validation and any remaining context-menu entry points found in official-client audit. |
| Whisper | Partial | Whisper sheet, presets, targets, configurable hold-to-whisper/tap-to-toggle activation, temporary activation controls, separate Catalyst start/stop shortcut bindings, route snapshots, recent activation log export, activation diagnostics, and tests for protocol serialization plus activation log behavior | Verify full voice whisper routing against real servers and add true key-up global hotkey capture if platform APIs allow it. |
| Event log | Done | Events sheet, unread handling, filter presets, visible snapshot export, activity row copy summaries with VoiceOver actions, persistent local event archive, and archive import/restore preview with activity-kind and poke-direction distributions plus copyable activity/poke summaries | Add richer per-event restore choices if archive formats expand. |

## Server And Channel Administration

| Area | Status | Current Evidence | Remaining Work |
| --- | --- | --- | --- |
| Server information | Done | Server info sheet and Catalyst entry | Add more raw virtual server fields where available. |
| Server edit/settings | Partial | Server settings editor, port, autostart, machine id, quotas, total file-transfer bandwidth limits, host fields including banner mode/refresh interval, icon support, server-list visibility, server log option switches, default group editing, identity/client-version requirements including platform-specific Android/iOS minimum versions, settings draft import preview with copyable summary and tri-state/log/server-list toggle validation, temporary password management with persistent recent results, create-draft validation and copyable target summary, filter/sort presets, row copy summaries, and VoiceOver actions, complaint controls, and anti-flood command/IP/plugin block controls | Audit all official server edit tabs and fill missing fields. |
| Channel create/edit/delete/move | Partial | Channel editor and info sheet with codec quality/latency/encryption controls and visibility, voice/music codec presets, needed talk/join/subscribe/description-view powers, create/edit channel sort order, codec configuration summaries, legacy/encryption codec diagnostics, official range validation including imported draft position checks, move preview, draft import/export with import preview and copyable draft summary, icon import, password prompts, and permission inheritance impact visibility | Validate advanced codec controls against real servers and add deeper inherited effective-value tracing if protocol data allows it. |
| Client actions | Partial | Client row menus, centralized talk request queue with grant/deny/copy and batch handling, online user complaint/contact shortcuts, database-record and group-member contact/note plus online poke/private-message actions, database-client row copy summaries with VoiceOver actions, auditable client-database backup import with field completeness summaries and copyable summaries, move/kick/ban/message style workflows in UI | Audit all official context-menu actions and fill remaining bookmark-contact edge actions. |
| Server logs | Partial | Query presets, reusable/copyable query summaries with input validation, paged log viewing with begin position, level/channel/search filters, visible exports, row copy summaries with VoiceOver copy actions, local archive import/export with restore preview, level/channel distribution summaries, copyable log summary, and persistent recent log results for offline review | Validate broader log filters and real-server log permissions. |
| Ban list | Partial | Ban list management, add/delete/delete-visible/delete-all, add-rule fields for IP/name/UID/myTeamSpeak ID/last nickname, create-draft validation and copyable rule summary, use-existing-entry-as-draft editing flow, filters, presets, row copy summaries with VoiceOver actions, backup import/export with import preview, target/duration distribution summaries, copyable rule summary, visible exports, and persistent recent ban results for offline review | Test advanced ban fields against real servers and audit edit behavior. |
| Complaints | Partial | Complaint management with target picker, direct create/delete, create-draft validation and copyable complaint summary, visible export, local archive import/export with restore preview, target/source distribution summaries, copyable complaint summary, filter presets, row copy summaries with VoiceOver actions, complaint-source contact actions, and persistent recent results for offline review | Validate complaint add/remove flows against real servers and fill any remaining official-client context-menu edge cases. |
| Privilege keys | Partial | Privilege key manager with create/use/delete, generated-key actions, existing-key invite-link/save-to-connection actions, readable exports/backups, backup import preview with type/target distribution summaries and copyable key summary, create-draft validation and copyable target/custom-set summary, filter presets, row copy summaries with VoiceOver actions, and persistent recent results for offline review | Validate create/use/delete flows against real servers and audit any official-client edge fields. |

## Permissions And Groups

| Area | Status | Current Evidence | Remaining Work |
| --- | --- | --- | --- |
| Permission viewer/editor | Partial | Permission scopes, direct/negated/skip filters, inheritance-impact labels, presets, backup structures, permission and directory row copy summaries, copyable add/update drafts with target/effective flag summaries, draft validation, and VoiceOver row actions | Validate complete server/channel/client/group permission editing against official semantics. |
| Server groups | Partial | Group management with create/copy/rename/delete, create/copy/rename draft validation and copyable group summary, member add/remove by database id, member-change draft validation and copyable summary, visible exports, local group-list archive import/export with restore preview, copyable group summary, and per-target type distributions, group/member row copy summaries with VoiceOver actions, member summary copy/export, copyable filter preset summaries with VoiceOver actions, and persistent recent group lists for offline review | Validate group mutation semantics and permission requirements against real servers. |
| Channel groups | Partial | Channel group management with create/copy/rename/delete, create/copy/rename draft validation and copyable group summary, member browsing with channel-context filters, set-by-database-id actions with draft validation and copyable summary, visible exports, local group-list archive import/export with restore preview, copyable group summary, and per-target type distributions, group/member row copy summaries with VoiceOver actions, member summary copy/export, copyable filter preset summaries with VoiceOver actions, and persistent recent group lists for offline review | Validate channel-group mutation semantics against real servers. |
| Permission backup/import | Partial | Permission backup export, guided restore preview with copyable backup summary, changed/unchanged/addition names, value/flag change details, selectable changed/new restore entries, auditable restore-plan preview/copy/export with selected options, target comparison, per-entry restore reasons/change summaries, upsert restore, unchanged-entry skip, and conflict/addition counts | Validate permission backup semantics against real servers. |

## Files

| Area | Status | Current Evidence | Remaining Work |
| --- | --- | --- | --- |
| Channel file browser | Done | Browse by channel/path/password, server file status summary, bookmarks, search/sort/filter presets, move/rename conflict previews, row copy summaries, and VoiceOver file-entry actions | Add deeper cross-directory conflict previews if needed. |
| Upload/download | Done | Transfer socket, upload importer, download queue, retry/cancel, queue export, row copy summaries, and VoiceOver queue actions | Add folder upload/download if server protocol and platform sandbox allow it. |
| File operations | Done | Rename, move, delete, create directory, batch actions, rename plus single/batch move conflict previews, and upload overwrite/resume conflict details | Validate conflict behavior against real servers and add cross-directory previews if server listing is expanded. |
| Local downloaded files | Done | Persistent recent download history, downloads folder open/copy/cleanup actions, export/open/copy/remove actions, queue row open local file | Add richer downloads folder organization if needed. |

## Identity, Contacts, Bookmarks, And Migration

| Area | Status | Current Evidence | Remaining Work |
| --- | --- | --- | --- |
| Identity management | Done | Global identity sheet, import/export, snapshots, saved identity profiles with row copy summaries and VoiceOver actions, disconnected identity switching, and Catalyst entry | Validate identity switching against real servers. |
| Bookmarks | Done | Bookmark list/folders/import/export, connection manager, full bookmark editor for connection options, saved phonetic nickname, local notes, and duplicate cleanup | Audit official-client bookmark edge fields if future TS3 URL options are added. |
| Contacts | Partial | Contact manager entry, online-user bulk contact import/status actions, complaint-source shortcuts, online, database-client, and group-member friend/block/ignore/note shortcuts, visible batch status/delete/note actions with copyable status and note drafts, row copy summaries with VoiceOver actions, full and visible contact backup export, contact backup import preview with selectable new/update restore entries and friend/block/ignore status distribution summaries, and local ignore suppression for private messages and pokes | Audit contact behavior against real server data and fill any official-client edge actions. |
| Client migration | Done | Client package import/export covering local settings groups, saved identities, saved channel passwords, channel layout state, schema metadata, notification/shortcut/audio preview details, import preview confirmation, and selectable per-section restore choices | Add richer per-item restore choices if package formats expand. |

## Notifications, Shortcuts, And Platform Integration

| Area | Status | Current Evidence | Remaining Work |
| --- | --- | --- | --- |
| Local notifications | Done | Global notification settings, presets, import/export with overwrite preview and copyable summary, event types, per-server mute rules, per-contact mute rules, and quiet-hours scheduling | Add richer notification category-specific schedules if official-client parity requires them. |
| Keyboard shortcuts | Partial | User-editable shortcut bindings, structured recorder, duplicate warnings, import/export/reset controls, validation hints, row-level copyable shortcut summaries with VoiceOver actions, and Catalyst menu bindings for global settings, connection actions, messaging, voice, server info/settings, admin tools, permissions, complaints, temporary passwords, and files | Add true key-event capture/global hotkey support if platform APIs allow it. |
| Catalyst menus | Done | Native Catalyst/macOS command menus split into TeamSpeak, Connection, Messaging, Administration, and Voice workflows with shortcuts for major connected tools | Add new command groups as future workflows are added. |
| iOS accessibility and compact layout | Partial | SwiftUI shared sheets/forms, compact voice status strip, VoiceOver labels/values for global mic/output/transmit/whisper state, and readable row summaries/actions for dense permission, group, complaint, ban, privilege-key, temporary-password, database-client, contact, poke, activity-event, file-browser, file-transfer, server-log, and offline-message administration lists | Continue auditing dynamic type and remaining dense administration sheets. |

## Release And Diagnostics

| Area | Status | Current Evidence | Remaining Work |
| --- | --- | --- | --- |
| Debug logs | Done | Debug log page with level/search filtering, visible-log copy/export, clear, and diagnostic report export package | Add richer packaged attachments if platform sandbox requirements emerge. |
| Build coverage | Done | README documents SwiftPM, iOS, Catalyst, CI artifact builds | Keep README feature list updated with current capabilities. |
| Protocol test coverage | Partial | Unit tests for command parsing, admin command builders, file transfer init/response parameters, broader invite URL variants, byte buffer, icons, whisper, notification import previews, client migration preview details, selective migration restore options, legacy migration-package decoding with missing newer sections, and migration-package edge cases for channel layout, files, server administration presets, self status, and whisper | Add broader tests for real-server validated restore semantics. |

## Next Implementation Priorities

1. Audit remaining server/channel settings fields against official-client tabs and fill missing fields.
2. Validate file operation conflict behavior and advanced codec controls against real servers.
3. Verify full voice whisper routing against real servers and add true key-up global hotkey capture if platform APIs allow it.
