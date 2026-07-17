local _, Sentinel = ...

local HUD = {}
Sentinel.HUD = HUD

local WIN_TONES = {
    WINNING = "recovery",
    LOSING = "active",
    EVEN = "forming",
    SETUP = "border",
}

local TRUST_TONES = {
    ["RAID CMD ONLINE"] = "recovery",
    ["LOCAL KWR"] = "accent",
    ["NO COMMANDER"] = "border",
    STALE = "forming",
    MISMATCH = "active",
}

local function clean(value, fallback)
    value = value ~= nil and tostring(value) or ""
    if value == "" then
        return fallback or ""
    end
    return value
end

local function upper(value, fallback)
    return clean(value, fallback):upper()
end

local function shortName(value)
    value = clean(value, "")
    local dash = value:find("-", 1, true)
    return dash and value:sub(1, dash - 1) or value
end

local function setTone(frame, tone)
    Sentinel.Theme:Style(frame, "panel", tone or "border")
end

local function makeLabel(parent, text, x, y, width)
    local label = Sentinel.Theme:Font(parent, 8, "muted", "LEFT", "OUTLINE")
    label:SetPoint("TOPLEFT", x, y)
    label:SetWidth(width or 84)
    label:SetText(text)
    return label
end

local function makeValue(parent, x, y, width, size)
    local value = Sentinel.Theme:Font(parent, size or 12, "text", "LEFT", "OUTLINE")
    value:SetPoint("TOPLEFT", x, y)
    value:SetWidth(width or 180)
    value:SetHeight(18)
    return value
end

local function badge(parent, width, height)
    local frame = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    frame:SetSize(width or 82, height or 18)
    Sentinel.Theme:Style(frame, "panel", "border")
    frame.text = Sentinel.Theme:Font(frame, 8, "text", "CENTER", "OUTLINE")
    frame.text:SetAllPoints()
    return frame
end

local function deriveWinState(view)
    local score = view.score or {}
    local status = upper(score.status, "")
    if status == "WINNING" or status == "LOSING" or status == "EVEN" or status == "SETUP" then
        return status
    end
    local friendly = tonumber(score.friendly or 0) or 0
    local enemy = tonumber(score.enemy or 0) or 0
    if friendly > enemy then return "WINNING" end
    if enemy > friendly then return "LOSING" end
    if view.mode == "LIVE" then return "EVEN" end
    return "SETUP"
end

local function trustState(view)
    if view.trustState then
        return upper(view.trustState, "NO COMMANDER")
    end
    if view.source == "KWR" then
        return "LOCAL KWR"
    end
    return "NO COMMANDER"
end

local function movement(view)
    local assignment = view.assignment or {}
    local deathZone = view.deathZone or {}
    local raw = upper(assignment.movement or assignment.move or "", "")
    if raw ~= "" then return raw end
    if deathZone.state == "ACTIVE" then return "RESET" end
    if deathZone.state == "BUILDING" or deathZone.state == "FORMING" then return "COLLAPSE" end
    if assignment.connected == false then return "STAY" end
    return "STAY"
end

local function jobText(view)
    local assignment = view.assignment or {}
    local role = clean(assignment.shortRole, "")
    if role == "" or role == "NONE" then
        role = clean(assignment.role, "UNASSIGNED")
    end
    local location = clean(assignment.location, "")
    if location ~= "" and location ~= "unknown" then
        return upper(role .. " " .. location, "UNASSIGNED")
    end
    return upper(role, "UNASSIGNED")
end

local function targetText(view)
    local watch = view.watch or {}
    local mode = upper(watch.mode or watch.targetMode or "", "")
    if mode == "" or mode == "UNKNOWN" then
        if watch.castName and watch.castName ~= "" then
            mode = "KICK"
        elseif watch.name and watch.name ~= "No tracked enemy" and watch.name ~= "No local target" then
            mode = "WATCH"
        end
    end
    local name = shortName(watch.name or watch.target or "")
    if mode == "" or name == "" or name == "No tracked enemy" or name == "No local target" then
        return "NO REVIEWED TARGET"
    end
    return mode .. " " .. name
end

local function matchStateText(view, winState)
    local score = view.score or {}
    local condition = clean(score.condition, "")
    if condition ~= "" and condition ~= "Waiting for live battleground data." then
        return condition
    end
    if winState == "WINNING" then return "Ahead. Preserve the current objective edge." end
    if winState == "LOSING" then return "Behind. Recover the next objective window." end
    if winState == "EVEN" then return "Even. Follow the next commander move." end
    return "Setup. Waiting for reviewed battleground state."
end

local function holdLine(view, winState)
    local assignment = view.assignment or {}
    local score = view.score or {}
    if view.requirement and view.requirement.holdLine then
        return clean(view.requirement.holdLine, "Hold current assignment.")
    end
    if winState == "WINNING" then
        return clean(score.action or assignment.detail, "Hold current assignment.")
    end
    return clean(assignment.detail, "Do not leave without commander authority.")
end

local function winLine(view, winState)
    local command = view.command or {}
    local score = view.score or {}
    if view.requirement and view.requirement.winLine then
        return clean(view.requirement.winLine, "Win the next objective exchange.")
    end
    if winState == "LOSING" or winState == "EVEN" then
        return clean(command.action or score.action, "Win the next objective exchange.")
    end
    return clean(command.line2 or score.commandWhen, "Keep the lead stable.")
end

local function footerLine(view)
    local healer = view.healer or {}
    local watch = view.watch or {}
    if healer.range == "OUT OF RANGE" then
        return "HEALER OUT OF RANGE"
    end
    if watch.liveCast and watch.liveCast.name then
        return "CAST LIVE " .. clean(watch.liveCast.name, "")
    end
    if view.revision and view.revision > 0 then
        return "CARD LIVE"
    end
    return "LOCAL FALLBACK"
end

local function expectedTarget(view)
    local watch = view.watch or {}
    local name = watch.target or watch.name or watch.shortName
    name = shortName(name)
    if name == "" or name == "No tracked enemy" or name == "No local target" then
        return nil
    end
    return name:lower()
end

local function targetState(view)
    local expected = expectedTarget(view)
    if not expected then
        return "MUTED"
    end
    if not UnitExists or not UnitExists("target") or not UnitCanAttack("player", "target") then
        return "RED"
    end
    local actual = shortName(UnitName("target")):lower()
    return actual == expected and "WHITE" or "RED"
end

local function readinessSummary()
    if InCombatLockdown and InCombatLockdown() then
        return nil
    end
    local hard = "UNKNOWN"
    local fit = "NOT EVALUABLE"
    local total, equipped
    if type(GetAverageItemLevel) == "function" then
        equipped, total = GetAverageItemLevel()
    end
    if equipped and equipped > 0 then
        hard = "READY"
        if total and total - equipped > 25 then
            hard = "PVP GEAR WARNING"
        end
    end
    if type(C_SpecializationInfo) == "table"
        and type(C_SpecializationInfo.GetAllSelectedPvpTalentIDs) == "function" then
        local talents = C_SpecializationInfo.GetAllSelectedPvpTalentIDs()
        if type(talents) == "table" and #talents > 0 then
            fit = "MATCHED"
        elseif hard == "READY" then
            hard = "PVP TALENT WARNING"
        end
    end
    return hard, fit
end

function HUD:Create()
    if self.frame then return self.frame end
    local profile = Sentinel.db.profile.hud
    local frame = CreateFrame("Frame", "KWRSentinel_HUD", UIParent, "BackdropTemplate")
    frame:SetSize(318, 236)
    frame:SetPoint(profile.point, UIParent, profile.relativePoint, profile.x, profile.y)
    frame:SetFrameStrata("HIGH")
    frame:SetClampedToScreen(true)
    Sentinel.Theme:Style(frame, "background", "border")

    frame.title = Sentinel.Theme:Font(frame, 13, "accent", "LEFT", "OUTLINE")
    frame.title:SetPoint("TOPLEFT", 10, -9)
    frame.title:SetText("KWR SENTINEL")

    frame.winBadge = badge(frame, 58, 18)
    frame.winBadge:SetPoint("TOPRIGHT", -116, -8)
    frame.trustBadge = badge(frame, 102, 18)
    frame.trustBadge:SetPoint("TOPRIGHT", -10, -8)

    frame.header = Sentinel.Theme:Font(frame, 9, "muted", "LEFT", "OUTLINE")
    frame.header:SetPoint("TOPLEFT", 10, -29)
    frame.header:SetSize(298, 16)

    frame.jobLabel = makeLabel(frame, "MY JOB", 10, -52)
    frame.job = makeValue(frame, 76, -50, 222, 14)
    frame.moveLabel = makeLabel(frame, "MOVE", 10, -78)
    frame.move = makeValue(frame, 76, -76, 222, 14)
    frame.targetLabel = makeLabel(frame, "TARGET", 10, -104)
    frame.target = makeValue(frame, 76, -102, 222, 14)
    frame.stateLabel = makeLabel(frame, "MATCH", 10, -132)
    frame.state = makeValue(frame, 76, -130, 222, 10)
    frame.holdLabel = makeLabel(frame, "TO HOLD", 10, -160)
    frame.hold = makeValue(frame, 76, -158, 222, 10)
    frame.winLabel = makeLabel(frame, "TO WIN", 10, -188)
    frame.win = makeValue(frame, 76, -186, 222, 10)
    frame.footer = Sentinel.Theme:Font(frame, 8, "muted", "LEFT", "OUTLINE")
    frame.footer:SetPoint("BOTTOMLEFT", 10, 8)
    frame.footer:SetSize(220, 12)

    frame.map = Sentinel.Theme:Button(frame, "MAP", 34, 17, function() Sentinel.NativeUI:ToggleMap() end)
    frame.map:SetPoint("BOTTOMRIGHT", -82, 6)
    frame.score = Sentinel.Theme:Button(frame, "SCORE", 48, 17, function() Sentinel.NativeUI:ToggleScore() end)
    frame.score:SetPoint("BOTTOMRIGHT", -30, 6)

    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(selfFrame)
        if Sentinel.db.profile.hud.locked then return end
        selfFrame:StartMoving()
    end)
    frame:SetScript("OnDragStop", function(selfFrame)
        selfFrame:StopMovingOrSizing()
        local point, _, relativePoint, x, y = selfFrame:GetPoint(1)
        profile.point, profile.relativePoint, profile.x, profile.y = point, relativePoint, x, y
    end)
    self.frame = frame
    return frame
end

function HUD:CreateTargetCue()
    if self.targetCue then return self.targetCue end
    local cue = CreateFrame("Frame", "KWRSentinel_TargetCue", UIParent, "BackdropTemplate")
    cue:SetSize(22, 22)
    cue:SetPoint("CENTER", UIParent, "CENTER", 0, -110)
    cue:SetFrameStrata("HIGH")
    Sentinel.Theme:Style(cue, "panel", "border")
    cue.mark = Sentinel.Theme:Font(cue, 18, "text", "CENTER", "OUTLINE")
    cue.mark:SetAllPoints()
    cue.mark:SetText("+")
    self.targetCue = cue
    return cue
end

function HUD:ShowReadinessAlert()
    if self.readinessShown then
        return
    end
    local hard, fit = readinessSummary()
    if not hard then
        return
    end
    self.readinessShown = true
    local alert = self.readinessAlert
    if not alert then
        alert = CreateFrame("Frame", "KWRSentinel_ReadinessAlert", UIParent, "BackdropTemplate")
        alert:SetSize(260, 54)
        alert:SetPoint("TOP", UIParent, "TOP", 0, -140)
        alert:SetFrameStrata("DIALOG")
        Sentinel.Theme:Style(alert, "background", "forming")
        alert.title = Sentinel.Theme:Font(alert, 10, "accent", "CENTER", "OUTLINE")
        alert.title:SetPoint("TOPLEFT", 8, -8)
        alert.title:SetPoint("TOPRIGHT", -8, -8)
        alert.body = Sentinel.Theme:Font(alert, 9, "text", "CENTER", "OUTLINE")
        alert.body:SetPoint("TOPLEFT", 8, -26)
        alert.body:SetPoint("TOPRIGHT", -8, -26)
        self.readinessAlert = alert
    end
    alert.title:SetText("SENTINEL READINESS")
    alert.body:SetText(hard .. " | " .. fit)
    alert:Show()
    C_Timer.After(8, function()
        if alert then alert:Hide() end
    end)
end

function HUD:UpdateTargetCue(view)
    local cue = self:CreateTargetCue()
    local state = targetState(view)
    if state == "WHITE" then
        cue.mark:SetTextColor(1, 1, 1, 1)
        Sentinel.Theme:Style(cue, "panel", "text")
        cue:Show()
    elseif state == "RED" then
        cue.mark:SetTextColor(1, 0.22, 0.18, 1)
        Sentinel.Theme:Style(cue, "panel", "active")
        cue:Show()
    else
        cue.mark:SetTextColor(0.55, 0.60, 0.66, 0.50)
        Sentinel.Theme:Style(cue, "panel", "border")
        cue:Show()
    end
end

function HUD:Update()
    if Sentinel.db.profile.hud.enabled ~= true then
        if self.frame then self.frame:Hide() end
        if self.targetCue then self.targetCue:Hide() end
        return
    end
    local frame = self:Create()
    local view = Sentinel.Bridge:BuildView() or {}
    local winState = deriveWinState(view)
    local trust = trustState(view)
    local score = view.score or {}
    frame.header:SetText(string.format("%s | %d-%d | %s",
        clean(score.mapShort, "WORLD"),
        tonumber(score.friendly or 0) or 0,
        tonumber(score.enemy or 0) or 0,
        clean(score.timeToWin, "unknown")))
    frame.winBadge.text:SetText(winState)
    frame.trustBadge.text:SetText(trust)
    setTone(frame.winBadge, WIN_TONES[winState] or "border")
    setTone(frame.trustBadge, TRUST_TONES[trust] or "border")
    frame.job:SetText(jobText(view))
    frame.move:SetText(movement(view))
    frame.target:SetText(targetText(view))
    frame.state:SetText(matchStateText(view, winState))
    frame.hold:SetText(holdLine(view, winState))
    frame.win:SetText(winLine(view, winState))
    frame.footer:SetText(footerLine(view))
    self:UpdateTargetCue(view)
    frame:Show()
end

function HUD:Toggle()
    local frame = self:Create()
    if frame:IsShown() then
        frame:Hide()
        if self.targetCue then self.targetCue:Hide() end
    else
        self:Update()
    end
end

function HUD:OnInitialize()
    self.frame = self:Create()
    self.frame:Hide()
    self:CreateTargetCue():Hide()
    self.pulse = CreateFrame("Frame", "KWRSentinel_HUDPulse")
    self.pulse.elapsed = 0
    self.pulse:SetScript("OnUpdate", function(_, elapsed)
        if not HUD.frame or not HUD.frame:IsShown() then return end
        HUD.pulse.elapsed = HUD.pulse.elapsed + elapsed
        if HUD.pulse.elapsed >= 0.25 then
            HUD.pulse.elapsed = 0
            HUD:Update()
        end
    end)
end

function HUD:OnEnable()
    if Sentinel.db.profile.hud.enabled then
        self:Update()
    end
    if C_Timer and C_Timer.After then
        C_Timer.After(4, function()
            if select(2, IsInInstance()) == "pvp" then
                HUD:ShowReadinessAlert()
            end
        end)
    end
end

Sentinel:RegisterModule("HUD", HUD)
