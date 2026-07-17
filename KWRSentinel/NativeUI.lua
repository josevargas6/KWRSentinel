local _, Sentinel = ...

local NativeUI = {}
Sentinel.NativeUI = NativeUI

function NativeUI:ToggleMap()
    if BattlefieldMapFrame and BattlefieldMapFrame:IsShown() then
        BattlefieldMapFrame:Hide()
    elseif BattlefieldMapFrame then
        BattlefieldMapFrame:Show()
    end
end

function NativeUI:ToggleScore()
    if type(ToggleScoreFrame) == "function" then
        ToggleScoreFrame()
    end
end

function NativeUI:ToggleRaidFrames()
    if InCombatLockdown and InCombatLockdown() then
        return false
    end
    if type(CompactRaidFrameManager_SetSetting) == "function" then
        local manager = CompactRaidFrameManager
        local shown = manager and manager:IsShown()
        CompactRaidFrameManager_SetSetting("IsShown", not shown)
        if manager then
            if shown then manager:Hide() else manager:Show() end
        end
    elseif CompactRaidFrameManager then
        if CompactRaidFrameManager:IsShown() then
            CompactRaidFrameManager:Hide()
        else
            CompactRaidFrameManager:Show()
        end
    end
    return true
end

function NativeUI:ToggleKWRRoster()
    if type(_G.KWR) == "table" and _G.KWR.CombatRoster and _G.KWR.CombatRoster.Show then
        local frame = _G.KWR.CombatRoster.frame
        if frame and frame:IsShown() then
            _G.KWR.CombatRoster:Hide(false)
        else
            _G.KWR.CombatRoster:Show("BOTH", false)
        end
    end
end

Sentinel:RegisterModule("NativeUI", NativeUI)
