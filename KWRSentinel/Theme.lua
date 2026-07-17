local _, Sentinel = ...

local Theme = {}
Sentinel.Theme = Theme

local COLORS = {
    background = { 0.07, 0.09, 0.11, 0.96 },
    panel = { 0.11, 0.13, 0.16, 0.94 },
    border = { 0.25, 0.35, 0.40, 0.95 },
    active = { 0.90, 0.30, 0.18, 0.95 },
    forming = { 0.92, 0.65, 0.22, 0.95 },
    recovery = { 0.20, 0.62, 0.42, 0.95 },
    text = { 0.94, 0.96, 0.98, 1.0 },
    muted = { 0.63, 0.70, 0.78, 1.0 },
    accent = { 0.55, 0.84, 0.97, 1.0 },
}

function Theme:Color(name)
    local color = COLORS[name] or COLORS.text
    return color[1], color[2], color[3], color[4]
end

function Theme:Font(parent, size, tone, justify, flags)
    local font = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    font:SetFont("Fonts\\FRIZQT__.TTF", size or 10, flags or "")
    font:SetJustifyH(justify or "LEFT")
    font:SetJustifyV("TOP")
    font:SetTextColor(self:Color(tone or "text"))
    return font
end

function Theme:Style(frame, tone, borderTone)
    if not frame.SetBackdrop then return end
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    frame:SetBackdropColor(self:Color(tone or "panel"))
    frame:SetBackdropBorderColor(self:Color(borderTone or "border"))
end

function Theme:Button(parent, label, width, height, onClick)
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    button:SetSize(width or 58, height or 18)
    self:Style(button, "panel", "border")
    button.label = self:Font(button, 9, "accent", "CENTER", "OUTLINE")
    button.label:SetAllPoints()
    button.label:SetText(label or "BTN")
    if onClick then
        button:SetScript("OnClick", onClick)
    end
    button:SetScript("OnEnter", function(selfButton)
        Theme:Style(selfButton, "panel", "accent")
    end)
    button:SetScript("OnLeave", function(selfButton)
        Theme:Style(selfButton, "panel", "border")
    end)
    return button
end
