-- ServerStorage/BuildModeRegistry.lua
local M = { PlayerShip = {} }

function M.SetPlayerShip(plr, ship) M.PlayerShip[plr] = ship end
function M.GetPlayerShip(plr) return M.PlayerShip[plr] end
function M.Clear(plr) M.PlayerShip[plr] = nil end

return M
