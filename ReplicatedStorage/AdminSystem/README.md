# AdminSystem

`AdminController` creates its interface entirely from code, so it does not
depend on LocalScripts embedded in a Studio-only GUI model.

- Press `F8` to show or hide the panel.
- Click the target button to cycle through connected players.
- Effects can be searched, applied, and removed.
- Items can be searched and granted in a selected amount.

The client allowlist only hides the UI. `AdminHandler` independently authorizes
every request using `Config.AdminUserIds`; Studio sessions are allowed for local
testing. Item/effect names, amounts, and target players are all validated by the
server.
