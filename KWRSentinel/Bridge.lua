local _, Sentinel = ...

local Bridge = {}
Sentinel.Bridge = Bridge

local INTERRUPTS = {
    WARRIOR = { kick = 6552, cc = 5246 },
    PALADIN = { kick = 96231, cc = 853 },
    HUNTER = { kick = 147362, cc = 187650 },
    ROGUE = { kick = 1766, cc = 408 },
    PRIEST = { kick = 15487, cc = 8122 },
    DEATHKNIGHT = { kick = 47528, cc = 108194 },
    SHAMAN = { kick = 57994, cc = 51514 },
    MAGE = { kick = 2139, cc = 118 },
    WARLOCK = { kick = 19647, cc = 5782 },
    MONK = { kick = 116705, cc = 115078 },
    DRUID = { kick = 106839, cc = 33786 },
    DEMONHUNTER = { kick = 183752, cc = 217832 },
    EVOKER = { kick = 351338, cc = 360806 },
}

local function text(value, fallback, maximum)
    if type(_G.KWR) == "table" and _G.KWR.Util and _G.KWR.Util.Text then
        return _G.KWR.Util:Text(value, fallback or "", maximum or 180)
    end
    value = value ~= nil and tostring(value) or ""
    if value == "" then return fallback or "" end
    if maximum and #value > maximum then
        return value:sub(1, maximum)
    end
    return value
end

local function shortName(value)
    value = text(value, "", 64)
    local dash = value:find("-", 1, true)
    return dash and value:sub(1, dash - 1) or value
end

local function spellName(spellID)
    if type(C_Spell) == "table" and type(C_Spell.GetSpellName) == "function" then
        return C_Spell.GetSpellName(spellID)
    end
    if type(GetSpellInfo) == "function" then
        return GetSpellInfo(spellID)
    end
    return nil
end

local function playerSpells()
    local _, class = UnitClass("player")
    local profile = INTERRUPTS[class]
    if not profile then
        return { kickName = nil, ccName = nil }
    end
    return {
        kickName = spellName(profile.kick),
        ccName = spellName(profile.cc),
    }
end

local function inRangeForSpell(spell, unit)
    if not spell or not unit or not UnitExists(unit) or type(IsSpellInRange) ~= "function" then
        return nil
    end
    local result = IsSpellInRange(spell, unit)
    if result == 1 then return true end
    if result == 0 then return false end
    return nil
end

local function castInfo(unit)
    if not unit or not UnitExists(unit) then return nil end
    local name, _, _, _, endMS, _, _, notInterruptible = UnitCastingInfo(unit)
    local channel = false
    if not name then
        name, _, _, _, endMS, _, notInterruptible = UnitChannelInfo(unit)
        channel = name ~= nil
    end
    if not name then return nil end
    local nowMS = GetTime() * 1000
    local remaining = endMS and math.max(0, (endMS - nowMS) / 1000) or nil
    return {
        name = name,
        remaining = remaining,
        notInterruptible = notInterruptible == true,
        channel = channel,
    }
end

local function iterateGroupUnits()
    local units = { "player" }
    if IsInRaid() then
        for index = 1, GetNumGroupMembers() do
            units[#units + 1] = "raid" .. tostring(index)
        end
    elseif IsInGroup() then
        for index = 1, GetNumSubgroupMembers() do
            units[#units + 1] = "party" .. tostring(index)
        end
    end
    return units
end

local function healerStatus()
    local result = {
        name = "Unknown",
        range = "UNKNOWN",
        detail = "No friendly healer unit is available.",
    }
    for _, unit in ipairs(iterateGroupUnits()) do
        if UnitExists(unit)
            and UnitGroupRolesAssigned(unit) == "HEALER"
            and UnitIsConnected(unit)
            and not UnitIsDeadOrGhost(unit) then
            local inRange = UnitInRange(unit)
            result.name = shortName(UnitName(unit))
            if unit == "player" then
                result.range = "SELF"
                result.detail = "You are a healer."
            elseif inRange == true then
                result.range = "IN RANGE"
                result.detail = "Primary healer is in range."
            elseif inRange == false then
                result.range = "OUT OF RANGE"
                result.detail = "Primary healer is out of range."
            else
                result.range = "UNKNOWN"
                result.detail = "Primary healer range is not available."
            end
            return result
        end
    end
    return result
end

local function locateUnitByName(name)
    name = shortName(name):lower()
    if name == "" then return nil end
    for _, unit in ipairs({ "target", "focus", "mouseover" }) do
        if UnitExists(unit) and shortName(UnitName(unit)):lower() == name then
            return unit
        end
    end
    for index = 1, 40 do
        local unit = "nameplate" .. tostring(index)
        if UnitExists(unit) and shortName(UnitName(unit)):lower() == name then
            return unit
        end
    end
    return nil
end

local function fallbackView()
    local mapName = GetRealZoneText and GetRealZoneText() or "World"
    return {
        source = "STANDALONE",
        revision = 0,
        mode = select(2, IsInInstance()) == "pvp" and "LIVE" or "WORLD",
        mapKey = "WORLD",
        assignment = {
            role = "Standalone",
            shortRole = "SOLO",
            location = "Install KWR for commander assignment relay",
            detail = "Sentinel is running without a local KWR commander state.",
        },
        score = {
            mapKey = "WORLD",
            mapName = mapName,
            mapShort = "WORLD",
            status = select(2, IsInInstance()) == "pvp" and "LIVE" or "WORLD",
            friendly = 0,
            enemy = 0,
            max = 0,
            timeToWin = "unknown",
            friendlyTime = "unknown",
            enemyTime = "unknown",
            commandWhen = "WAIT",
            condition = "Install KWR on the same client for score pace and assignment relay.",
            action = "Use native map and scoreboard while Sentinel watches healer range and your target cast.",
        },
        deathZone = {
            state = "NONE",
            label = "current fight",
            score = 0,
            response = "WATCH",
            detail = "Standalone Sentinel has no commander collapse model.",
        },
        watch = {
            name = "No tracked enemy",
            role = "UNKNOWN",
            healthPercent = nil,
            castName = nil,
            castPriority = nil,
            reason = "Track your current target or run Sentinel beside KWR for local-target relay.",
            cooldownText = nil,
        },
        carriers = {},
        command = {
            line2 = "",
            line3 = "",
            action = "",
        },
    }
end

local function augmentWatch(view)
    view.watch = view.watch or {}
    local spells = playerSpells()
    view.watch.kickSpell = spells.kickName
    view.watch.ccSpell = spells.ccName
    local unit = view.watch.unit
    if (not unit or unit == "") and view.watch.name then
        unit = locateUnitByName(view.watch.name)
    end
    if unit then
        view.watch.unit = unit
        view.watch.liveCast = castInfo(unit)
        view.watch.inKickRange = inRangeForSpell(spells.kickName, unit)
        view.watch.inCCRange = inRangeForSpell(spells.ccName, unit)
        if type(_G.KWR) == "table" and _G.KWR.Util and _G.KWR.Util.IsSecret then
            local healthMax = UnitHealthMax(unit)
            local health = UnitHealth(unit)
            if not _G.KWR.Util:IsSecret(health) and not _G.KWR.Util:IsSecret(healthMax)
                and healthMax and healthMax > 0 then
                view.watch.healthPercent = math.floor((health / healthMax) * 100 + 0.5)
            end
        end
    elseif UnitExists("target") and UnitCanAttack("player", "target") then
        view.watch.name = shortName(UnitName("target"))
        view.watch.liveCast = castInfo("target")
        view.watch.inKickRange = inRangeForSpell(spells.kickName, "target")
        view.watch.inCCRange = inRangeForSpell(spells.ccName, "target")
        if type(_G.KWR) == "table" and _G.KWR.Util and _G.KWR.Util.IsSecret then
            local healthMax = UnitHealthMax("target")
            local health = UnitHealth("target")
            if not _G.KWR.Util:IsSecret(health) and not _G.KWR.Util:IsSecret(healthMax)
                and healthMax and healthMax > 0 then
                view.watch.healthPercent = math.floor((health / healthMax) * 100 + 0.5)
            end
        end
    end
    return view
end

function Bridge:BuildView()
    local kwr = _G.KWR
    local view = kwr and kwr.SentinelBridge and kwr.ready
        and kwr.SentinelBridge:BuildView(shortName(UnitName("player")))
        or fallbackView()
    view.healer = healerStatus()
    return augmentWatch(view)
end

Sentinel:RegisterModule("Bridge", Bridge)
