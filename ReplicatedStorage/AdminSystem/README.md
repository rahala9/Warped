# AdminSystem

`AdminController` creates its interface entirely from code, so it does not
depend on LocalScripts embedded in a Studio-only GUI model.

- Press `F8` to enter or leave Admin mode. The binding is owned by
  `ContextSwitchingContext.ShowAdminAction`, not a direct input listener.
- Click the target button to cycle through connected players.
- Effects can be searched, applied, and removed.
- Items can be searched and granted in a selected amount.
- Ships can be permanently granted to or revoked from a player's profile.
- Skills can be searched, inspected, and set from 0-5 directly on the selected player's profile.

The client allowlist only hides the UI. `AdminHandler` independently authorizes
every request using `Config.AdminUserIds`; Studio sessions are allowed for local
testing. Item/effect names, amounts, and target players are all validated by the
server.

The interface is generated as `PlayerGui.AdminTestGui` and registered with
`ModeManager`, so the former `SharedGUI.AdminGui` object is not required.
