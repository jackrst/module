--[[
    gamesense.win UI Library
    Complete, tested, no errors.
]]

-- ══════════════════════════════════════════════════════════════════════
-- SERVICES
-- ══════════════════════════════════════════════════════════════════════
local _cr = cloneref or clone_ref
local function cref(o)
    if not _cr then return o end
    local ok, r = pcall(_cr, o)
    return ok and r or o
end

local UIS     = game:GetService("UserInputService")
local Tween   = game:GetService("TweenService")
local TextSvc = game:GetService("TextService")
local Http    = game:GetService("HttpService")
local RS      = game:GetService("RunService")
local Players = game:GetService("Players")
local Teams   = game:GetService("Teams")
local Render  = RS.RenderStepped

local LP    = Players.LocalPlayer
local Mouse = cref(LP:GetMouse())

local GUI = cref(Instance.new("ScreenGui"))
GUI.Name = "gamesense_" .. tostring(math.random(100000, 999999))
GUI.ZIndexBehavior = Enum.ZIndexBehavior.Global
GUI.IgnoreGuiInset = true
GUI.ResetOnSpawn = false
GUI.DisplayOrder = 9999

local ok_cg, coreGui = pcall(function() return game:GetService("CoreGui") end)
if ok_cg and coreGui then
    GUI.Parent = coreGui
else
    GUI.Parent = LP:WaitForChild("PlayerGui")
end

-- ══════════════════════════════════════════════════════════════════════
-- THEMES
-- ══════════════════════════════════════════════════════════════════════
local Themes = {
    Gamesense = { Accent = Color3.fromRGB(150, 205, 90),  AccentDark = Color3.fromRGB(100, 150, 58), AccentHov = Color3.fromRGB(170, 222, 110) },
    Blood     = { Accent = Color3.fromRGB(215, 60, 60),   AccentDark = Color3.fromRGB(150, 35, 35),  AccentHov = Color3.fromRGB(235, 85, 85) },
    Ice       = { Accent = Color3.fromRGB(90, 175, 230),  AccentDark = Color3.fromRGB(55, 125, 175), AccentHov = Color3.fromRGB(120, 205, 250) },
    Amethyst  = { Accent = Color3.fromRGB(170, 115, 235), AccentDark = Color3.fromRGB(120, 75, 180), AccentHov = Color3.fromRGB(195, 145, 255) },
    Sunset    = { Accent = Color3.fromRGB(240, 145, 60),  AccentDark = Color3.fromRGB(180, 100, 38), AccentHov = Color3.fromRGB(255, 170, 90) },
    Mono      = { Accent = Color3.fromRGB(185, 185, 185), AccentDark = Color3.fromRGB(115, 115, 115), AccentHov = Color3.fromRGB(220, 220, 220) },
}

-- ══════════════════════════════════════════════════════════════════════
-- LIBRARY
-- ══════════════════════════════════════════════════════════════════════
local Toggles, Options = {}, {}

local Library = {
    Toggled = false,
    Toggles = Toggles, Options = Options,
    Registry = {}, RegistryMap = {}, HudRegistry = {},

    Font      = Enum.Font.Gotham,
    FontMed   = Enum.Font.GothamMedium,
    FontBold  = Enum.Font.GothamBold,
    FontSize  = 13,

    FontColor = Color3.fromRGB(232, 232, 232),
    FontMuted = Color3.fromRGB(160, 160, 160),
    FontDim   = Color3.fromRGB(105, 105, 105),

    WindowBG  = Color3.fromRGB(18, 18, 18),
    HeaderBG  = Color3.fromRGB(24, 24, 24),
    PanelBG   = Color3.fromRGB(24, 24, 24),
    SectionBG = Color3.fromRGB(32, 32, 32),
    SidebarBG = Color3.fromRGB(14, 14, 14),
    ControlBG = Color3.fromRGB(34, 34, 34),
    ControlHov = Color3.fromRGB(44, 44, 44),
    PopupBG   = Color3.fromRGB(28, 28, 28),
    Border    = Color3.fromRGB(8, 8, 8),
    Outline   = Color3.fromRGB(48, 48, 48),
    Divider   = Color3.fromRGB(40, 40, 40),

    RiskColor    = Color3.fromRGB(217, 83, 79),
    WarningColor = Color3.fromRGB(240, 173, 78),

    Accent     = Themes.Gamesense.Accent,
    AccentDark = Themes.Gamesense.AccentDark,
    AccentHov  = Themes.Gamesense.AccentHov,
    AccentColor = Themes.Gamesense.Accent,
    AccentColorDark = Themes.Gamesense.AccentDark,

    MainColor = Color3.fromRGB(24, 24, 24),
    BackgroundColor = Color3.fromRGB(32, 32, 32),
    OutlineColor = Color3.fromRGB(48, 48, 48),

    CornerRadius = 0,
    Animations = true,
    AnimOpen = 0.3,
    AnimClose = 0.2,

    OpenedFrames = {}, DependencyBoxes = {}, ModeSelectOuters = {},
    ScreenGui = GUI,
    NotifyOnError = false,
    Version = "3.1.0",
    Brand = "gamesense.win",

    Sounds = { Enabled = true, Click = "rbxassetid://6895079853", Volume = 0.28 },
}

-- ══════════════════════════════════════════════════════════════════════
-- HELPERS
-- ══════════════════════════════════════════════════════════════════════
local function GetPlayersString()
    local l = Players:GetPlayers()
    for i = 1, #l do l[i] = l[i].Name end
    table.sort(l, function(a,b) return a < b end)
    return l
end

local function GetTeamsString()
    local l = Teams:GetTeams()
    for i = 1, #l do l[i] = l[i].Name end
    table.sort(l, function(a,b) return a < b end)
    return l
end

function Library:Create(class, props)
    local inst = class
    if type(class) == "string" then inst = cref(Instance.new(class)) end
    for k, v in next, props or {} do inst[k] = v end
    if Library.CornerRadius > 0
       and (inst:IsA("Frame") or inst:IsA("ScrollingFrame")
       or inst:IsA("TextButton") or inst:IsA("TextBox") or inst:IsA("ImageLabel")) then
        local c = inst:FindFirstChildOfClass("UICorner")
        if not c then c = cref(Instance.new("UICorner")); c.Parent = inst end
        c.CornerRadius = UDim.new(0, Library.CornerRadius)
    end
    return inst
end

function Library:CreateLabel(props, isHud)
    local l = Library:Create("TextLabel", {
        BackgroundTransparency = 1, Font = Library.Font,
        TextColor3 = Library.FontColor, TextSize = Library.FontSize,
        TextStrokeTransparency = 1, Active = false, RichText = true,
    })
    Library:AddToRegistry(l, { TextColor3 = "FontColor" }, isHud)
    return Library:Create(l, props)
end

function Library:Tween(inst, props, speed, style, dir)
    if not Library.Animations then
        for k, v in next, props do inst[k] = v end
        return
    end
    local t = Tween:Create(inst, TweenInfo.new(
        speed or 0.14, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out
    ), props)
    t:Play()
    return t
end

-- SAFE color sequence builder (last keypoint always exactly 1.0)
function Library:ColorSeq(a, b)
    return ColorSequence.new({
        ColorSequenceKeypoint.new(0, a),
        ColorSequenceKeypoint.new(1, b),
    })
end

-- SAFE hue gradient (integer division guarantees last = 1.0)
function Library:HueGradient()
    local kps = {}
    for i = 0, 20 do
        local h = i / 20
        kps[#kps + 1] = ColorSequenceKeypoint.new(h, Color3.fromHSV(h, 1, 1))
    end
    return ColorSequence.new(kps)
end

function Library:GetTextBounds(text, font, size, res)
    local b = TextSvc:GetTextSize(text, size, font, res or Vector2.new(1920, 1080))
    return b.X, b.Y
end

function Library:GetDarkerColor(c)
    local h, s, v = Color3.toHSV(c)
    return Color3.fromHSV(h, s, math.max(0, v / 1.55))
end

function Library:MapValue(v, a, b, c, d)
    if b == a then return c end
    return (1 - ((v - a) / (b - a))) * c + ((v - a) / (b - a)) * d
end

function Library:MakeDraggable(inst, cutoff)
    inst.Active = true
    inst.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
        local p = Vector2.new(Mouse.X - inst.AbsolutePosition.X, Mouse.Y - inst.AbsolutePosition.Y)
        if p.Y > (cutoff or 40) then return end
        while UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
            inst.Position = UDim2.new(
                0, Mouse.X - p.X + inst.Size.X.Offset * inst.AnchorPoint.X,
                0, Mouse.Y - p.Y + inst.Size.Y.Offset * inst.AnchorPoint.Y
            )
            Render:Wait()
        end
    end)
end

function Library:MouseIsOverOpenedFrame()
    for f in next, Library.OpenedFrames do
        local ap, as = f.AbsolutePosition, f.AbsoluteSize
        if Mouse.X >= ap.X and Mouse.X <= ap.X + as.X
           and Mouse.Y >= ap.Y and Mouse.Y <= ap.Y + as.Y then
            return true
        end
    end
    return false
end

function Library:AddToRegistry(inst, props, isHud)
    local d = { Instance = inst, Properties = props, Index = #Library.Registry + 1 }
    table.insert(Library.Registry, d)
    Library.RegistryMap[inst] = d
    if isHud then table.insert(Library.HudRegistry, d) end
end

function Library:RemoveFromRegistry(inst)
    local d = Library.RegistryMap[inst]
    if not d then return end
    for i = #Library.Registry, 1, -1 do
        if Library.Registry[i] == d then table.remove(Library.Registry, i) end
    end
    for i = #Library.HudRegistry, 1, -1 do
        if Library.HudRegistry[i] == d then table.remove(Library.HudRegistry, i) end
    end
    Library.RegistryMap[inst] = nil
end

function Library:UpdateColorsUsingRegistry()
    for _, o in next, Library.Registry do
        for prop, key in next, o.Properties do
            if type(key) == "string" then
                o.Instance[prop] = Library[key]
            elseif type(key) == "function" then
                o.Instance[prop] = key()
            end
        end
    end
end

function Library:UpdateDependencyBoxes()
    for _, d in next, Library.DependencyBoxes do d:Update() end
end

function Library:PlaySound(id, pitch)
    if not Library.Sounds.Enabled or not id or id == "" then return end
    local ok, s = pcall(function()
        local snd = cref(Instance.new("Sound"))
        snd.SoundId = id
        snd.Volume = Library.Sounds.Volume
        snd.PlaybackSpeed = pitch or 1
        snd.Parent = GUI
        snd:Play()
        return snd
    end)
    if ok and s then
        task.delay(2, function() pcall(function() s:Destroy() end) end)
    end
end

function Library:AttemptSave()
    if Library.SaveManager then
        pcall(function() Library.SaveManager:Save() end)
    end
end

function Library:SafeCallback(f, ...)
    if not f then return end
    local ok, err = pcall(f, ...)
    if not ok then
        warn("[gamesense] callback error:", err)
    end
end

function Library:SetTheme(name)
    local t = Themes[name]
    if not t then return end
    Library.Accent = t.Accent
    Library.AccentDark = t.AccentDark
    Library.AccentHov = t.AccentHov
    Library.AccentColor = t.Accent
    Library.AccentColorDark = t.AccentDark
    Library:UpdateColorsUsingRegistry()
end

function Library:SetAccent(c)
    Library.Accent = c
    Library.AccentColor = c
    Library.AccentDark = Library:GetDarkerColor(c)
    Library.AccentColorDark = Library.AccentDark
    Library.AccentHov = c:Lerp(Color3.new(1, 1, 1), 0.18)
    Library:UpdateColorsUsingRegistry()
end

function Library:AddToolTip(text, hover)
    local x, y = Library:GetTextBounds(text, Library.Font, 12)
    local tip = Library:Create("Frame", {
        BackgroundColor3 = Library.PopupBG,
        BorderColor3 = Library.Border,
        BorderMode = Enum.BorderMode.Inset,
        Size = UDim2.fromOffset(x + 16, y + 10),
        ZIndex = 500, Parent = GUI, Visible = false,
    })
    Library:AddToRegistry(tip, { BackgroundColor3 = "PopupBG", BorderColor3 = "Border" })
    Library:Create("Frame", {
        BackgroundColor3 = Library.Accent, BorderSizePixel = 0,
        Size = UDim2.new(0, 2, 1, 0), ZIndex = 501, Parent = tip,
    })
    Library:CreateLabel({
        Position = UDim2.fromOffset(9, 2), Size = UDim2.fromOffset(x, y),
        Text = text, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 502, Parent = tip,
    })
    local hov = false
    hover.MouseEnter:Connect(function()
        if Library:MouseIsOverOpenedFrame() then return end
        hov = true
        tip.Position = UDim2.fromOffset(Mouse.X + 15, Mouse.Y + 15)
        tip.Visible = true
        while hov do
            RS.Heartbeat:Wait()
            tip.Position = UDim2.fromOffset(Mouse.X + 15, Mouse.Y + 15)
        end
    end)
    hover.MouseLeave:Connect(function() hov = false; tip.Visible = false end)
end

GUI.DescendantRemoving:Connect(function(i)
    if Library.RegistryMap[i] then Library:RemoveFromRegistry(i) end
end)

-- ══════════════════════════════════════════════════════════════════════
-- ICON DRAWING (no asset IDs)
-- ══════════════════════════════════════════════════════════════════════
local function DrawIcon(name, size, parent, color)
    local holder = Library:Create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.fromOffset(size, size),
        Parent = parent,
    })
    local parts = {}
    local function add(i) table.insert(parts, i); return i end
    local function line(x, y, w, h, rot)
        return add(Library:Create("Frame", {
            BackgroundColor3 = color, BorderSizePixel = 0,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromOffset(x, y),
            Size = UDim2.fromOffset(w, h),
            Rotation = rot or 0, Parent = holder,
        }))
    end
    local function stroke(x, y, w, h)
        local f = Library:Create("Frame", {
            BackgroundTransparency = 1,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromOffset(x, y),
            Size = UDim2.fromOffset(w, h), Parent = holder,
        })
        Library:Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = f })
        local s = Library:Create("UIStroke", { Color = color, Thickness = 1.5, Parent = f })
        add(f); add(s)
        return f
    end
    local cx, cy = size / 2, size / 2

    if name == "Aiming" then
        line(cx, 3, 1.5, size * 0.22)
        line(cx, size - 3, 1.5, size * 0.22)
        line(3, cy, size * 0.22, 1.5)
        line(size - 3, cy, size * 0.22, 1.5)
        local dot = Library:Create("Frame", {
            BackgroundColor3 = color, BorderSizePixel = 0,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            Size = UDim2.fromOffset(3, 3), Parent = holder,
        })
        add(dot)
    elseif name == "Visuals" then
        stroke(cx, cy, size * 0.9, size * 0.5)
        local pupil = Library:Create("Frame", {
            BackgroundColor3 = color, BorderSizePixel = 0,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            Size = UDim2.fromOffset(4, 4), Parent = holder,
        })
        Library:Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = pupil })
        add(pupil)
    elseif name == "World" then
        stroke(cx, cy, size * 0.55, size * 0.55)
        for i = 0, 7 do
            local ang = math.rad(i * 45)
            local r1, r2 = size * 0.38, size * 0.47
            local x1, y1 = cx + math.cos(ang) * r1, cy + math.sin(ang) * r1
            local x2, y2 = cx + math.cos(ang) * r2, cy + math.sin(ang) * r2
            add(Library:Create("Frame", {
                BackgroundColor3 = color, BorderSizePixel = 0,
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.fromOffset((x1 + x2) / 2, (y1 + y2) / 2),
                Size = UDim2.fromOffset(1.5, 2.5),
                Rotation = math.deg(ang) - 90, Parent = holder,
            }))
        end
    elseif name == "Miscellaneous" then
        local q, gap = size * 0.28, size * 0.08
        local ps = {
            { cx - gap/2 - q, cy - gap/2 - q },
            { cx + gap/2, cy - gap/2 - q },
            { cx - gap/2 - q, cy + gap/2 },
            { cx + gap/2, cy + gap/2 },
        }
        for _, p in next, ps do
            add(Library:Create("Frame", {
                BackgroundColor3 = color, BorderSizePixel = 0,
                Position = UDim2.fromOffset(p[1], p[2]),
                Size = UDim2.fromOffset(q, q), Parent = holder,
            }))
        end
    elseif name == "Settings" then
        local rows = { { 3, 0.3 }, { 8, 0.7 }, { 13, 0.5 } }
        for _, r in ipairs(rows) do
            local yy = r[1] + 1
            line(cx, yy, size * 0.7, 1.2)
            local dotX = size * (0.15 + 0.7 * r[2])
            local dot = Library:Create("Frame", {
                BackgroundColor3 = color, BorderSizePixel = 0,
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.fromOffset(dotX, yy),
                Size = UDim2.fromOffset(3.5, 3.5), Parent = holder,
            })
            Library:Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = dot })
            add(dot)
        end
    else
        stroke(cx, cy, size * 0.5, size * 0.5)
    end
    return holder, parts
end

-- ══════════════════════════════════════════════════════════════════════
-- BASE ADDONS (ColorPicker, KeyPicker)
-- ══════════════════════════════════════════════════════════════════════
local BaseAddons = {}
do
    local Funcs = {}

    function Funcs:AddColorPicker(Index, Info)
        local parentLabel = self.TextLabel
        assert(Info.Default, "AddColorPicker: Missing default value.")
        local CP = {
            Value = Info.Default,
            Transparency = Info.Transparency or 0,
            Type = "ColorPicker",
            Title = type(Info.Title) == "string" and Info.Title or "Color",
            Callback = Info.Callback or function() end,
        }
        function CP:SetHSVFromRGB(c)
            local h, s, v = Color3.toHSV(c)
            CP.Hue, CP.Saturation, CP.Vib = h, s, v
        end
        CP:SetHSVFromRGB(CP.Value)

        local swatch = Library:Create("Frame", {
            BackgroundColor3 = CP.Value,
            BorderColor3 = Library:GetDarkerColor(CP.Value),
            BorderMode = Enum.BorderMode.Inset,
            Size = UDim2.new(0, 14, 0, 14),
            ZIndex = 6, Parent = parentLabel,
        })

        local pickerOuter = Library:Create("Frame", {
            Name = "Color",
            BackgroundColor3 = Library.Border,
            BorderColor3 = Library.Border,
            Position = UDim2.fromOffset(swatch.AbsolutePosition.X, swatch.AbsolutePosition.Y + 18),
            Size = UDim2.fromOffset(244, Info.Transparency and 288 or 268),
            Visible = false, ZIndex = 300, Parent = GUI,
        })

        swatch:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
            pickerOuter.Position = UDim2.fromOffset(swatch.AbsolutePosition.X, swatch.AbsolutePosition.Y + 18)
        end)

        local pickerInner = Library:Create("Frame", {
            BackgroundColor3 = Library.PopupBG,
            BorderColor3 = Library.Outline,
            BorderMode = Enum.BorderMode.Inset,
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 301, Parent = pickerOuter,
        })
        Library:AddToRegistry(pickerInner, { BackgroundColor3 = "PopupBG", BorderColor3 = "Outline" })

        Library:Create("Frame", {
            BackgroundColor3 = Library.Accent, BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 2), ZIndex = 302, Parent = pickerInner,
        })

        Library:CreateLabel({
            Size = UDim2.new(1, -8, 0, 14),
            Position = UDim2.fromOffset(6, 6),
            Text = CP.Title, TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 303, Parent = pickerInner,
        })

        local svOuter = Library:Create("Frame", {
            BorderColor3 = Library.Border,
            Position = UDim2.new(0, 6, 0, 28),
            Size = UDim2.fromOffset(200, 200),
            ZIndex = 303, Parent = pickerInner,
        })
        local svInner = Library:Create("Frame", {
            BackgroundColor3 = Library.PopupBG,
            BorderColor3 = Library.Outline,
            BorderMode = Enum.BorderMode.Inset,
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 304, Parent = svOuter,
        })
        local svMap = Library:Create("ImageLabel", {
            BorderSizePixel = 0, Size = UDim2.new(1, 0, 1, 0),
            Image = "rbxassetid://4155801252",
            ZIndex = 304, Parent = svInner,
        })
        local svCursor = Library:Create("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderColor3 = Color3.new(0, 0, 0),
            BorderMode = Enum.BorderMode.Outline,
            Size = UDim2.fromOffset(8, 8),
            ZIndex = 305, Parent = svMap,
        })

        local hueOuter = Library:Create("Frame", {
            BorderColor3 = Library.Border,
            Position = UDim2.new(0, 212, 0, 28),
            Size = UDim2.fromOffset(18, 200),
            ZIndex = 303, Parent = pickerInner,
        })
        local hueInner = Library:Create("Frame", {
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 304, Parent = hueOuter,
        })
        local hueCursor = Library:Create("Frame", {
            AnchorPoint = Vector2.new(0, 0.5),
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderColor3 = Color3.new(0, 0, 0),
            BorderMode = Enum.BorderMode.Outline,
            Size = UDim2.new(1, 0, 0, 2),
            ZIndex = 305, Parent = hueInner,
        })
        -- SAFE hue gradient
        Library:Create("UIGradient", {
            Color = Library:HueGradient(),
            Rotation = 90, Parent = hueInner,
        })

        local function mkInput(pos, width, ph, text)
            local o = Library:Create("Frame", {
                BorderColor3 = Library.Border,
                Position = pos, Size = UDim2.new(0, width, 0, 22),
                ZIndex = 303, Parent = pickerInner,
            })
            local i_ = Library:Create("Frame", {
                BackgroundColor3 = Library.ControlBG,
                BorderColor3 = Library.Outline,
                BorderMode = Enum.BorderMode.Inset,
                Size = UDim2.new(1, 0, 1, 0),
                ZIndex = 304, Parent = o,
            })
            local b = Library:Create("TextBox", {
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 6, 0, 0),
                Size = UDim2.new(1, -12, 1, 0),
                Font = Library.Font,
                PlaceholderColor3 = Library.FontMuted,
                PlaceholderText = ph,
                Text = text, TextColor3 = Library.FontColor,
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 305, Parent = i_,
            })
            Library:AddToRegistry(b, { TextColor3 = "FontColor" })
            return b
        end

        local hexBox = mkInput(UDim2.fromOffset(6, 236), 114, "Hex", "#FFFFFF")
        local rgbBox = mkInput(UDim2.fromOffset(124, 236), 106, "RGB", "255, 255, 255")

        local transInner, transCursor
        if Info.Transparency then
            local tOuter = Library:Create("Frame", {
                BorderColor3 = Library.Border,
                Position = UDim2.fromOffset(6, 264),
                Size = UDim2.new(1, -12, 0, 14),
                ZIndex = 303, Parent = pickerInner,
            })
            transInner = Library:Create("Frame", {
                BackgroundColor3 = CP.Value,
                BorderColor3 = Library.Outline,
                BorderMode = Enum.BorderMode.Inset,
                Size = UDim2.new(1, 0, 1, 0),
                ZIndex = 304, Parent = tOuter,
            })
            Library:Create("ImageLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 1, 0),
                Image = "rbxassetid://12978095818",
                ZIndex = 305, Parent = transInner,
            })
            transCursor = Library:Create("Frame", {
                AnchorPoint = Vector2.new(0.5, 0),
                BackgroundColor3 = Color3.new(1, 1, 1),
                BorderColor3 = Color3.new(0, 0, 0),
                BorderMode = Enum.BorderMode.Outline,
                Size = UDim2.new(0, 2, 1, 0),
                ZIndex = 306, Parent = transInner,
            })
        end

        function CP:Display()
            CP.Value = Color3.fromHSV(CP.Hue, CP.Saturation, CP.Vib)
            svMap.BackgroundColor3 = Color3.fromHSV(CP.Hue, 1, 1)
            swatch.BackgroundColor3 = CP.Value
            swatch.BackgroundTransparency = CP.Transparency
            swatch.BorderColor3 = Library:GetDarkerColor(CP.Value)
            if transInner then
                transInner.BackgroundColor3 = CP.Value
                transCursor.Position = UDim2.new(1 - CP.Transparency, 0, 0, 0)
            end
            svCursor.Position = UDim2.new(CP.Saturation, 0, 1 - CP.Vib, 0)
            hueCursor.Position = UDim2.new(0, 0, CP.Hue, 0)
            hexBox.Text = "#" .. CP.Value:ToHex()
            rgbBox.Text = table.concat({
                math.floor(CP.Value.R * 255),
                math.floor(CP.Value.G * 255),
                math.floor(CP.Value.B * 255),
            }, ", ")
            Library:SafeCallback(CP.Callback, CP.Value)
            Library:SafeCallback(CP.Changed, CP.Value)
        end

        function CP:OnChanged(f) CP.Changed = f; f(CP.Value) end

        function CP:Show()
            for f in next, Library.OpenedFrames do
                if f.Name == "Color" then f.Visible = false; Library.OpenedFrames[f] = nil end
            end
            pickerOuter.Visible = true
            Library.OpenedFrames[pickerOuter] = true
        end

        function CP:Hide()
            pickerOuter.Visible = false
            Library.OpenedFrames[pickerOuter] = nil
        end

        function CP:SetValue(hsv, t)
            CP.Transparency = t or 0
            CP:SetHSVFromRGB(Color3.fromHSV(hsv[1], hsv[2], hsv[3]))
            CP:Display()
            Library:UpdateDependencyBoxes()
        end

        function CP:SetValueRGB(c, t)
            CP.Transparency = t or 0
            CP:SetHSVFromRGB(c)
            CP:Display()
            Library:UpdateDependencyBoxes()
        end

        svMap.InputBegan:Connect(function(input)
            if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
            while UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                local x1 = svMap.AbsolutePosition.X
                local x2 = x1 + svMap.AbsoluteSize.X
                local y1 = svMap.AbsolutePosition.Y
                local y2 = y1 + svMap.AbsoluteSize.Y
                CP.Saturation = (math.clamp(Mouse.X, x1, x2) - x1) / (x2 - x1)
                CP.Vib = 1 - ((math.clamp(Mouse.Y, y1, y2) - y1) / (y2 - y1))
                CP:Display()
                Render:Wait()
            end
            Library:AttemptSave()
        end)

        hueInner.InputBegan:Connect(function(input)
            if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
            while UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                local y1 = hueInner.AbsolutePosition.Y
                local y2 = y1 + hueInner.AbsoluteSize.Y
                CP.Hue = (math.clamp(Mouse.Y, y1, y2) - y1) / (y2 - y1)
                CP:Display()
                Render:Wait()
            end
            Library:AttemptSave()
        end)

        if transInner then
            transInner.InputBegan:Connect(function(input)
                if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
                while UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                    local x1 = transInner.AbsolutePosition.X
                    local x2 = x1 + transInner.AbsoluteSize.X
                    CP.Transparency = 1 - ((math.clamp(Mouse.X, x1, x2) - x1) / (x2 - x1))
                    CP:Display()
                    Render:Wait()
                end
                Library:AttemptSave()
            end)
        end

        hexBox.FocusLost:Connect(function(enter)
            if enter then
                local ok, c = pcall(Color3.fromHex, hexBox.Text)
                if ok then
                    CP:SetHSVFromRGB(c)
                    CP:Display()
                end
            end
        end)

        rgbBox.FocusLost:Connect(function(enter)
            if enter then
                local r, g, b = rgbBox.Text:match("(%d+),%s*(%d+),%s*(%d+)")
                if r and g and b then
                    CP:SetHSVFromRGB(Color3.fromRGB(tonumber(r), tonumber(g), tonumber(b)))
                    CP:Display()
                end
            end
        end)

        swatch.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                if pickerOuter.Visible then CP:Hide() else CP:Show() end
            end
        end)

        UIS.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                local ap = pickerOuter.AbsolutePosition
                local as = pickerOuter.AbsoluteSize
                if Mouse.X < ap.X or Mouse.X > ap.X + as.X
                   or Mouse.Y < ap.Y - 21 or Mouse.Y > ap.Y + as.Y then
                    CP:Hide()
                end
            end
        end)

        Options[Index] = CP
        CP:Display()
        CP.DisplayFrame = swatch
        return CP
    end

    function Funcs:AddKeyPicker(Index, Info)
        local parentObj = self
        local parentLabel = self.TextLabel
        assert(Info.Default, "AddKeyPicker: Missing default value.")
        local KP = {
            Value = Info.Default,
            Toggled = false,
            Mode = Info.Mode or "Toggle",
            Type = "KeyPicker",
            Callback = Info.Callback or function() end,
            ChangedCallback = Info.ChangedCallback or function() end,
            SyncToggleState = Info.SyncToggleState or false,
        }
        if KP.SyncToggleState then
            Info.Modes = { "Toggle" }
            Info.Mode = "Toggle"
        end

        local outer = Library:Create("Frame", {
            BackgroundColor3 = Library.Border,
            BorderColor3 = Library.Border,
            Size = UDim2.new(0, 32, 0, 15),
            ZIndex = 6, Parent = parentLabel,
        })
        local inner = Library:Create("Frame", {
            BackgroundColor3 = Library.ControlBG,
            BorderColor3 = Library.Outline,
            BorderMode = Enum.BorderMode.Inset,
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 7, Parent = outer,
        })
        Library:AddToRegistry(inner, { BackgroundColor3 = "ControlBG", BorderColor3 = "Outline" })

        local disp = Library:CreateLabel({
            Size = UDim2.new(1, 0, 1, 0),
            TextSize = 11, Text = Info.Default,
            Font = Library.FontMed,
            ZIndex = 8, Parent = inner,
        })

        local modeOuter = Library:Create("Frame", {
            BorderColor3 = Library.Border,
            Position = UDim2.fromOffset(
                parentLabel.AbsolutePosition.X + parentLabel.AbsoluteSize.X + 4,
                parentLabel.AbsolutePosition.Y + 1
            ),
            Size = UDim2.fromOffset(64, 52),
            Visible = false, ZIndex = 300, Parent = GUI,
        })
        Library.ModeSelectOuters[modeOuter] = true

        parentLabel:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
            modeOuter.Position = UDim2.fromOffset(
                parentLabel.AbsolutePosition.X + parentLabel.AbsoluteSize.X + 4,
                parentLabel.AbsolutePosition.Y + 1
            )
        end)

        local modeInner = Library:Create("Frame", {
            BackgroundColor3 = Library.PopupBG,
            BorderColor3 = Library.Outline,
            BorderMode = Enum.BorderMode.Inset,
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 301, Parent = modeOuter,
        })
        Library:Create("UIListLayout", {
            FillDirection = Enum.FillDirection.Vertical,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = modeInner,
        })

        local containerLabel = Library:CreateLabel({
            TextXAlignment = Enum.TextXAlignment.Left,
            Size = UDim2.new(1, 0, 0, 18),
            TextSize = 12, Visible = false,
            ZIndex = 110, Parent = Library.KeybindContainer,
        }, true)

        local Modes = Info.Modes or { "Always", "Toggle", "Hold" }
        local ModeButtons = {}

        for _, mode in next, Modes do
            local b = {}
            local label = Library:CreateLabel({
                Active = false,
                Size = UDim2.new(1, 0, 0, 16),
                TextSize = 12, Text = mode,
                ZIndex = 302, Parent = modeInner,
            })

            function b:Select()
                for _, o in next, ModeButtons do o:Deselect() end
                KP.Mode = mode
                label.TextColor3 = Library.Accent
                Library.RegistryMap[label].Properties.TextColor3 = "Accent"
                modeOuter.Visible = false
            end

            function b:Deselect()
                KP.Mode = nil
                label.TextColor3 = Library.FontColor
                Library.RegistryMap[label].Properties.TextColor3 = "FontColor"
            end

            label.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    b:Select()
                    Library:AttemptSave()
                end
            end)

            if mode == KP.Mode then b:Select() end
            ModeButtons[mode] = b
        end

        function KP:Update()
            if Info.NoUI then return end
            local state = KP:GetState()
            containerLabel.Text = string.format("[%s] %s (%s)", KP.Value, Info.Text, KP.Mode)
            containerLabel.Visible = true
            containerLabel.TextColor3 = state and Library.Accent or Library.FontColor
            Library.RegistryMap[containerLabel].Properties.TextColor3 = state and "Accent" or "FontColor"

            local y, x = 0, 0
            for _, l in next, Library.KeybindContainer:GetChildren() do
                if l:IsA("TextLabel") and l.Visible then
                    y = y + 18
                    if l.TextBounds.X > x then x = l.TextBounds.X end
                end
            end
            Library.KeybindFrame.Size = UDim2.new(0, math.max(x + 14, 220), 0, y + 26)
        end

        function KP:GetState()
            if KP.Mode == "Always" then return true end
            if KP.Mode == "Hold" then
                if KP.Value == "None" then return false end
                if KP.Value == "MB2" then
                    return UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
                end
                return UIS:IsKeyDown(Enum.KeyCode[KP.Value])
            end
            return KP.Toggled
        end

        function KP:SetValue(data)
            if type(data) ~= "table" then data = { data, KP.Mode or "Toggle" } end
            local key = data[1]
            if typeof(key) ~= "string" or key == "" then key = Info.Default or "None" end
            local mode = data[2]
            if typeof(mode) ~= "string" or not ModeButtons[mode] then mode = KP.Mode or "Toggle" end
            disp.Text = key
            KP.Value = key
            ModeButtons[mode]:Select()
            Library:SafeCallback(KP.Callback, key)
            KP:Update()
            Library:UpdateDependencyBoxes()
        end

        function KP:OnClick(cb) KP.Clicked = cb end
        function KP:OnChanged(cb) KP.Changed = cb; cb(KP.Value) end

        if parentObj.Addons then
            table.insert(parentObj.Addons, KP)
        end

        function KP:DoClick()
            if parentObj.Type == "Toggle" and KP.SyncToggleState then
                parentObj:SetValue(not parentObj.Value)
            end
            Library:SafeCallback(KP.Callback, KP.Toggled)
            Library:SafeCallback(KP.Clicked, KP.Toggled)
        end

        local picking = false

        outer.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
               and not Library:MouseIsOverOpenedFrame() then
                picking = true
                disp.Text = ""
                local brk, txt = false, ""
                task.spawn(function()
                    while not brk do
                        if txt == "..." then txt = "" end
                        txt = txt .. "."
                        disp.Text = txt
                        task.wait(0.4)
                    end
                end)
                task.wait(0.2)
                local e
                e = UIS.InputBegan:Connect(function(i)
                    local key
                    if i.UserInputType == Enum.UserInputType.Keyboard then
                        key = i.KeyCode.Name
                    elseif i.UserInputType == Enum.UserInputType.MouseButton2 then
                        key = "MB2"
                    elseif i.UserInputType == Enum.UserInputType.MouseButton1 then
                        key = "None"
                    end
                    brk = true
                    picking = false
                    disp.Text = key
                    KP.Value = key
                    Library:SafeCallback(KP.Callback, key)
                    KP:Update()
                    Library:SafeCallback(KP.ChangedCallback, key)
                    Library:SafeCallback(KP.Changed, key)
                    Library:AttemptSave()
                    e:Disconnect()
                end)
            elseif input.UserInputType == Enum.UserInputType.MouseButton2
               and not Library:MouseIsOverOpenedFrame()
               and not picking then
                modeOuter.Visible = true
            end
        end)

        local c1 = UIS.InputBegan:Connect(function(input, processed)
            if processed then return end
            if not picking then
                if KP.Mode == "Toggle"
                   and input.UserInputType == Enum.UserInputType.Keyboard
                   and input.KeyCode.Name == KP.Value then
                    KP.Toggled = not KP.Toggled
                    KP:DoClick()
                elseif KP.Mode == "Hold" then
                    if (input.UserInputType == Enum.UserInputType.Keyboard
                       and input.KeyCode.Name == KP.Value)
                       or (KP.Value == "MB2"
                       and input.UserInputType == Enum.UserInputType.MouseButton2) then
                        Library:SafeCallback(KP.Callback, true)
                    end
                end
                KP:Update()
            end
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                local ap = modeOuter.AbsolutePosition
                local as = modeOuter.AbsoluteSize
                if Mouse.X < ap.X or Mouse.X > ap.X + as.X
                   or Mouse.Y < ap.Y - 21 or Mouse.Y > ap.Y + as.Y then
                    modeOuter.Visible = false
                end
            end
        end)

        local c2 = UIS.InputEnded:Connect(function(input, processed)
            if processed then return end
            if not picking then
                if KP.Mode == "Hold"
                   and ((input.UserInputType == Enum.UserInputType.Keyboard
                       and input.KeyCode.Name == KP.Value)
                       or (KP.Value == "MB2"
                       and input.UserInputType == Enum.UserInputType.MouseButton2)) then
                    Library:SafeCallback(KP.Callback, false)
                end
                KP:Update()
            end
        end)

        function KP:Destroy()
            c1:Disconnect()
            c2:Disconnect()
            Library.ModeSelectOuters[modeOuter] = nil
            modeOuter:Destroy()
        end

        outer.Destroying:Connect(function() KP:Destroy() end)

        KP:Update()
        Options[Index] = KP
        return KP
    end

    BaseAddons.__index = Funcs
    BaseAddons.__namecall = function(_, key, ...) return Funcs[key](...) end
end

-- ══════════════════════════════════════════════════════════════════════
-- GROUPBOX ADDONS
-- ══════════════════════════════════════════════════════════════════════
local BaseGroupbox = {}
do
    local Funcs = {}

    function Funcs:AddBlank(size)
        Library:Create("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, size),
            ZIndex = 1, Parent = self.Container,
        })
    end

    function Funcs:AddLabel(text, wrap, tooltip)
        local L = {}
        local G = self
        local C = self.Container
        local tl = Library:CreateLabel({
            Size = UDim2.new(1, -4, 0, 15),
            TextSize = Library.FontSize,
            Text = text, TextWrapped = wrap or false,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 5, Parent = C,
        })
        if wrap then
            tl.Size = UDim2.new(1, -4, 0, select(2, Library:GetTextBounds(
                text, Library.Font, Library.FontSize,
                Vector2.new(tl.AbsoluteSize.X, math.huge)
            )))
        else
            Library:Create("UIListLayout", {
                Padding = UDim.new(0, 4),
                FillDirection = Enum.FillDirection.Horizontal,
                HorizontalAlignment = Enum.HorizontalAlignment.Right,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Parent = tl,
            })
        end
        L.TextLabel = tl
        L.Container = C
        function L:SetText(t)
            tl.Text = t
            if wrap then
                tl.Size = UDim2.new(1, -4, 0, select(2, Library:GetTextBounds(
                    t, Library.Font, Library.FontSize,
                    Vector2.new(tl.AbsoluteSize.X, math.huge)
                )))
            end
            G:Resize()
        end
        if not wrap then setmetatable(L, BaseAddons) end
        G:AddBlank(5)
        G:Resize()
        if type(tooltip) == "string" then Library:AddToolTip(tooltip, tl) end
        return L
    end

    function Funcs:AddButton(...)
        local B = {}
        local function parse(_, obj, ...)
            local p = select(1, ...)
            if type(p) == "table" then
                obj.Text = p.Text
                obj.Func = p.Func
                obj.Tooltip = p.Tooltip
            else
                obj.Text = select(1, ...)
                obj.Func = select(2, ...)
            end
            assert(type(obj.Func) == "function", "AddButton: Func missing.")
        end
        parse("Button", B, ...)

        local G, C = self, self.Container

        local function mk(b)
            local outer = Library:Create("Frame", {
                BackgroundColor3 = Library.Border,
                BorderColor3 = Library.Border,
                Size = UDim2.new(1, -4, 0, 24),
                ZIndex = 5,
            })
            local inner = Library:Create("Frame", {
                BackgroundColor3 = Library.ControlBG,
                BorderColor3 = Library.Outline,
                BorderMode = Enum.BorderMode.Inset,
                Size = UDim2.new(1, 0, 1, 0),
                ZIndex = 6, Parent = outer,
            })
            local lbl = Library:CreateLabel({
                Size = UDim2.new(1, 0, 1, 0),
                TextSize = Library.FontSize,
                Font = Library.FontMed,
                Text = b.Text, ZIndex = 6, Parent = inner,
            })
            Library:AddToRegistry(outer, { BorderColor3 = "Border" })
            Library:AddToRegistry(inner, { BackgroundColor3 = "ControlBG", BorderColor3 = "Outline" })
            outer.MouseEnter:Connect(function()
                Library:Tween(inner, { BackgroundColor3 = Library.ControlHov })
            end)
            outer.MouseLeave:Connect(function()
                Library:Tween(inner, { BackgroundColor3 = Library.ControlBG })
            end)
            return outer, inner, lbl
        end

        B.Outer, B.Inner, B.Label = mk(B)
        B.Outer.Parent = C

        B.Outer.InputBegan:Connect(function(input)
            if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
            if Library:MouseIsOverOpenedFrame() then return end
            Library:PlaySound(Library.Sounds.Click)
            Library:SafeCallback(B.Func)
        end)

        function B:AddTooltip(t)
            if type(t) == "string" then Library:AddToolTip(t, self.Outer) end
            return self
        end

        function B:AddButton(...)
            local S = {}
            parse("SubButton", S, ...)
            self.Outer.Size = UDim2.new(0.5, -2, 0, 24)
            S.Outer, S.Inner, S.Label = mk(S)
            S.Outer.Position = UDim2.new(1, 3, 0, 0)
            S.Outer.Size = UDim2.fromOffset(self.Outer.AbsoluteSize.X - 2, self.Outer.AbsoluteSize.Y)
            S.Outer.Parent = self.Outer
            S.Outer.InputBegan:Connect(function(input)
                if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
                if Library:MouseIsOverOpenedFrame() then return end
                Library:PlaySound(Library.Sounds.Click)
                Library:SafeCallback(S.Func)
            end)
            return S
        end

        G:AddBlank(6)
        G:Resize()
        return B
    end

    function Funcs:AddDivider()
        local G = self
        G:AddBlank(3)
        Library:Create("Frame", {
            BackgroundColor3 = Library.Divider,
            BorderSizePixel = 0,
            Size = UDim2.new(1, -4, 0, 1),
            ZIndex = 5, Parent = G.Container,
        })
        G:AddBlank(10)
        G:Resize()
    end

    function Funcs:AddInput(Index, Info)
        assert(Info.Text, "AddInput: Missing Text.")
        local TB = {
            Value = Info.Default or "",
            Numeric = Info.Numeric or false,
            Finished = Info.Finished or false,
            Type = "Input",
            Callback = Info.Callback or function() end,
        }
        local G, C = self, self.Container

        Library:CreateLabel({
            Size = UDim2.new(1, 0, 0, 13),
            TextSize = 12, Text = Info.Text,
            TextColor3 = Library.FontMuted,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 5, Parent = C,
        })
        G:AddBlank(2)

        local outer = Library:Create("Frame", {
            BackgroundColor3 = Library.Border,
            BorderColor3 = Library.Border,
            Size = UDim2.new(1, -4, 0, 24),
            ZIndex = 5, Parent = C,
        })
        local inner = Library:Create("Frame", {
            BackgroundColor3 = Library.ControlBG,
            BorderColor3 = Library.Outline,
            BorderMode = Enum.BorderMode.Inset,
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 6, Parent = outer,
        })
        Library:AddToRegistry(outer, { BorderColor3 = "Border" })
        Library:AddToRegistry(inner, { BackgroundColor3 = "ControlBG", BorderColor3 = "Outline" })

        outer.MouseEnter:Connect(function()
            Library:Tween(inner, { BorderColor3 = Library.Accent })
        end)
        outer.MouseLeave:Connect(function()
            Library:Tween(inner, { BorderColor3 = Library.Outline })
        end)

        local box = Library:Create("TextBox", {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 8, 0, 0),
            Size = UDim2.new(1, -16, 1, 0),
            Font = Library.Font,
            PlaceholderColor3 = Library.FontDim,
            PlaceholderText = Info.Placeholder or "",
            Text = Info.Default or "",
            TextColor3 = Library.FontColor,
            TextSize = Library.FontSize,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 7, Parent = inner,
        })
        Library:AddToRegistry(box, { TextColor3 = "FontColor" })

        function TB:SetValue(t)
            if Info.MaxLength and #t > Info.MaxLength then t = t:sub(1, Info.MaxLength) end
            if TB.Numeric and not tonumber(t) and #t > 0 then t = TB.Value end
            TB.Value = t
            box.Text = t
            Library:SafeCallback(TB.Callback, TB.Value)
            Library:SafeCallback(TB.Changed, TB.Value)
        end

        if TB.Finished then
            box.FocusLost:Connect(function(e)
                if e then TB:SetValue(box.Text); Library:AttemptSave() end
            end)
        else
            box:GetPropertyChangedSignal("Text"):Connect(function()
                TB:SetValue(box.Text)
                Library:AttemptSave()
            end)
        end

        function TB:OnChanged(f) TB.Changed = f; f(TB.Value) end

        G:AddBlank(6)
        G:Resize()
        Options[Index] = TB
        return TB
    end

    function Funcs:AddToggle(Index, Info)
        assert(Info.Text, "AddToggle: Missing Text.")
        local T = {
            Value = Info.Default or false,
            Type = "Toggle",
            Callback = Info.Callback or function() end,
            Addons = {}, Risky = Info.Risky,
        }
        local G, C = self, self.Container

        local row = Library:Create("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -4, 0, 20),
            ZIndex = 5, Parent = C,
        })

        local boxOuter = Library:Create("Frame", {
            BackgroundColor3 = Library.Border,
            BorderColor3 = Library.Border,
            Position = UDim2.new(0, 0, 0, 3),
            Size = UDim2.new(0, 14, 0, 14),
            ZIndex = 6, Parent = row,
        })
        local boxInner = Library:Create("Frame", {
            BackgroundColor3 = Library.ControlBG,
            BorderColor3 = Library.Outline,
            BorderMode = Enum.BorderMode.Inset,
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 7, Parent = boxOuter,
        })
        Library:AddToRegistry(boxOuter, { BorderColor3 = "Border" })
        Library:AddToRegistry(boxInner, { BackgroundColor3 = "ControlBG", BorderColor3 = "Outline" })

        local chk = Library:Create("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            Visible = false, ZIndex = 9, Parent = boxInner,
        })
        Library:Create("Frame", {
            BackgroundColor3 = Color3.fromRGB(15, 15, 15),
            BorderSizePixel = 0,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.32, 0, 0.55, 0),
            Size = UDim2.new(0, 2, 0, 4.5),
            Rotation = 45, ZIndex = 10, Parent = chk,
        })
        Library:Create("Frame", {
            BackgroundColor3 = Color3.fromRGB(15, 15, 15),
            BorderSizePixel = 0,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.62, 0, 0.45, 0),
            Size = UDim2.new(0, 2, 0, 8),
            Rotation = -45, ZIndex = 10, Parent = chk,
        })

        local label = Library:CreateLabel({
            Size = UDim2.new(1, -24, 1, 0),
            Position = UDim2.new(0, 24, 0, 0),
            TextSize = Library.FontSize,
            Text = Info.Text,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 6, Parent = row,
        })
        Library:Create("UIListLayout", {
            Padding = UDim.new(0, 4),
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = label,
        })

        local region = Library:Create("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 9, Parent = row,
        })

        row.MouseEnter:Connect(function()
            Library:Tween(boxInner, {
                BackgroundColor3 = T.Value and Library.AccentHov or Library.ControlHov,
            })
        end)
        row.MouseLeave:Connect(function()
            Library:Tween(boxInner, {
                BackgroundColor3 = T.Value and Library.Accent or Library.ControlBG,
            })
        end)

        function T:UpdateColors() T:Display() end

        function T:Display()
            local on = T.Value
            Library:Tween(boxInner, { BackgroundColor3 = on and Library.Accent or Library.ControlBG })
            Library:Tween(boxInner, { BorderColor3 = on and Library.AccentDark or Library.Outline })
            Library.RegistryMap[boxInner].Properties.BackgroundColor3 = on and "Accent" or "ControlBG"
            Library.RegistryMap[boxInner].Properties.BorderColor3 = on and "AccentDark" or "Outline"
            chk.Visible = on
        end

        function T:OnChanged(f) T.Changed = f; f(T.Value) end

        function T:SetValue(v)
            v = (not not v)
            T.Value = v
            T:Display()
            for _, a in next, T.Addons do
                if a.Type == "KeyPicker" and a.SyncToggleState then
                    a.Toggled = v
                    a:Update()
                end
            end
            Library:SafeCallback(T.Callback, T.Value)
            Library:SafeCallback(T.Changed, T.Value)
            Library:UpdateDependencyBoxes()
        end

        region.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
               and not Library:MouseIsOverOpenedFrame() then
                Library:PlaySound(Library.Sounds.Click)
                T:SetValue(not T.Value)
                Library:AttemptSave()
            end
        end)

        if T.Risky then
            Library:RemoveFromRegistry(label)
            label.TextColor3 = Library.RiskColor
            Library:AddToRegistry(label, { TextColor3 = "RiskColor" })
        end

        T:Display()
        G:AddBlank(Info.BlankSize or 6)
        G:Resize()

        T.TextLabel = label
        T.Container = C
        setmetatable(T, BaseAddons)

        Toggles[Index] = T
        Library:UpdateDependencyBoxes()
        return T
    end

    function Funcs:AddSlider(Index, Info)
        assert(Info.Default and Info.Text and Info.Min and Info.Max and Info.Rounding ~= nil,
            "AddSlider: missing field.")
        local S = {
            Value = Info.Default,
            Min = Info.Min, Max = Info.Max,
            Rounding = Info.Rounding,
            MaxSize = 200,
            Type = "Slider",
            Callback = Info.Callback or function() end,
        }
        local G, C = self, self.Container

        local headerRow = Library:Create("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 14),
            ZIndex = 5, Parent = C,
        })
        Library:CreateLabel({
            Size = UDim2.new(1, 0, 1, 0),
            TextSize = 12, Text = Info.Text,
            TextColor3 = Library.FontMuted,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 6, Parent = headerRow,
        })
        local valueLabel = Library:CreateLabel({
            Size = UDim2.new(1, 0, 1, 0),
            TextSize = 12,
            Text = tostring(S.Value),
            Font = Library.FontMed,
            TextXAlignment = Enum.TextXAlignment.Right,
            ZIndex = 6, Parent = headerRow,
        })
        Library:AddToRegistry(valueLabel, { TextColor3 = "AccentColor" })
        valueLabel.TextColor3 = Library.Accent

        G:AddBlank(4)

        local outer = Library:Create("Frame", {
            BackgroundColor3 = Library.Border,
            BorderColor3 = Library.Border,
            Size = UDim2.new(1, -4, 0, 20),
            ZIndex = 5, Parent = C,
        })
        local inner = Library:Create("Frame", {
            BackgroundColor3 = Library.ControlBG,
            BorderColor3 = Library.Outline,
            BorderMode = Enum.BorderMode.Inset,
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 6, Parent = outer,
        })
        local fill = Library:Create("Frame", {
            BackgroundColor3 = Library.Accent,
            BorderSizePixel = 0,
            Size = UDim2.new(0, 0, 1, 0),
            ZIndex = 7, Parent = inner,
        })
        Library:AddToRegistry(fill, { BackgroundColor3 = "Accent" })

        outer.MouseEnter:Connect(function()
            Library:Tween(inner, { BorderColor3 = Library.Accent })
        end)
        outer.MouseLeave:Connect(function()
            Library:Tween(inner, { BorderColor3 = Library.Outline })
        end)

        function S:UpdateColors()
            fill.BackgroundColor3 = Library.Accent
            valueLabel.TextColor3 = Library.Accent
        end

        function S:Display()
            valueLabel.Text = tostring(S.Value) .. (Info.Suffix or "")
            local x = math.ceil(Library:MapValue(S.Value, S.Min, S.Max, 0, S.MaxSize))
            fill.Size = UDim2.new(0, x, 1, 0)
        end

        inner:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
            S.MaxSize = math.max(1, inner.AbsoluteSize.X)
            S:Display()
        end)
        task.defer(function()
            S.MaxSize = math.max(1, inner.AbsoluteSize.X)
            S:Display()
        end)

        function S:OnChanged(f) S.Changed = f; f(S.Value) end

        local function rnd(v)
            if S.Rounding == 0 then return math.floor(v) end
            return tonumber(string.format("%." .. S.Rounding .. "f", v))
        end

        function S:GetValueFromXOffset(x)
            return rnd(Library:MapValue(x, 0, S.MaxSize, S.Min, S.Max))
        end

        function S:SetValue(str)
            local n = tonumber(str)
            if not n then return end
            n = math.clamp(n, S.Min, S.Max)
            S.Value = n
            S:Display()
            Library:SafeCallback(S.Callback, S.Value)
            Library:SafeCallback(S.Changed, S.Value)
            Library:UpdateDependencyBoxes()
        end

        inner.InputBegan:Connect(function(input)
            if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
            if Library:MouseIsOverOpenedFrame() then return end
            local mp = Mouse.X
            local gPos = fill.Size.X.Offset
            local diff = mp - (fill.AbsolutePosition.X + gPos)
            while UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                local nv = S:GetValueFromXOffset(math.clamp(gPos + (Mouse.X - mp) + diff, 0, S.MaxSize))
                local ov = S.Value
                S.Value = nv
                S:Display()
                if nv ~= ov then
                    Library:SafeCallback(S.Callback, S.Value)
                    Library:SafeCallback(S.Changed, S.Value)
                end
                Render:Wait()
            end
            Library:AttemptSave()
        end)

        S:Display()
        G:AddBlank(Info.BlankSize or 7)
        G:Resize()
        Options[Index] = S
        return S
    end

    function Funcs:AddDropdown(Index, Info)
        if Info.SpecialType == "Player" then
            Info.Values = GetPlayersString()
            Info.AllowNull = true
        elseif Info.SpecialType == "Team" then
            Info.Values = GetTeamsString()
            Info.AllowNull = true
        end
        assert(Info.Values, "AddDropdown: Missing Values.")
        assert(Info.AllowNull or Info.Default, "AddDropdown: Missing Default.")
        if not Info.Text then Info.Compact = true end

        local D = {
            Values = Info.Values,
            Value = Info.Multi and {} or nil,
            Multi = Info.Multi,
            Type = "Dropdown",
            SpecialType = Info.SpecialType,
            Callback = Info.Callback or function() end,
        }
        local G, C = self, self.Container

        if not Info.Compact then
            Library:CreateLabel({
                Size = UDim2.new(1, 0, 0, 13),
                TextSize = 12, Text = Info.Text,
                TextColor3 = Library.FontMuted,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 5, Parent = C,
            })
            G:AddBlank(2)
        end

        local outer = Library:Create("Frame", {
            BackgroundColor3 = Library.Border,
            BorderColor3 = Library.Border,
            Size = UDim2.new(1, -4, 0, 24),
            ZIndex = 5, Parent = C,
        })
        local inner = Library:Create("Frame", {
            BackgroundColor3 = Library.ControlBG,
            BorderColor3 = Library.Outline,
            BorderMode = Enum.BorderMode.Inset,
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 6, Parent = outer,
        })
        Library:AddToRegistry(outer, { BorderColor3 = "Border" })
        Library:AddToRegistry(inner, { BackgroundColor3 = "ControlBG", BorderColor3 = "Outline" })

        local chev = Library:Create("ImageLabel", {
            AnchorPoint = Vector2.new(0, 0.5),
            BackgroundTransparency = 1,
            Position = UDim2.new(1, -18, 0.5, 0),
            Size = UDim2.new(0, 10, 0, 10),
            Image = "rbxassetid://6282522798",
            ImageColor3 = Library.FontMuted,
            Active = false, ZIndex = 8, Parent = inner,
        })
        Library:AddToRegistry(chev, { ImageColor3 = "FontMuted" })

        local itemLabel = Library:CreateLabel({
            Position = UDim2.new(0, 8, 0, 0),
            Size = UDim2.new(1, -26, 1, 0),
            TextSize = Library.FontSize,
            Text = "--",
            TextXAlignment = Enum.TextXAlignment.Left,
            TextWrapped = false,
            ZIndex = 7, Parent = inner,
        })

        outer.MouseEnter:Connect(function()
            Library:Tween(inner, { BorderColor3 = Library.Accent })
        end)
        outer.MouseLeave:Connect(function()
            Library:Tween(inner, { BorderColor3 = Library.Outline })
        end)

        local MAX = 8
        local listOuter = Library:Create("Frame", {
            BackgroundColor3 = Library.Border,
            BorderColor3 = Library.Border,
            ZIndex = 300, Visible = false, Parent = GUI,
        })
        local listInner = Library:Create("Frame", {
            BackgroundColor3 = Library.PopupBG,
            BorderColor3 = Library.Outline,
            BorderMode = Enum.BorderMode.Inset,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 301, Parent = listOuter,
        })
        Library:AddToRegistry(listInner, { BackgroundColor3 = "PopupBG", BorderColor3 = "Outline" })

        local scroll = Library:Create("ScrollingFrame", {
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 302, Parent = listInner,
            TopImage = "", BottomImage = "",
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = Library.Accent,
        })
        Library:AddToRegistry(scroll, { ScrollBarImageColor3 = "AccentColor" })

        Library:Create("UIListLayout", {
            Padding = UDim.new(0, 0),
            FillDirection = Enum.FillDirection.Vertical,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = scroll,
        })

        local function rp()
            listOuter.Position = UDim2.fromOffset(
                outer.AbsolutePosition.X,
                outer.AbsolutePosition.Y + outer.Size.Y.Offset + 1
            )
        end
        local function rs(y)
            listOuter.Size = UDim2.fromOffset(outer.AbsoluteSize.X, y or (MAX * 24 + 2))
        end
        rp(); rs()
        outer:GetPropertyChangedSignal("AbsolutePosition"):Connect(rp)

        function D:Display()
            local s = ""
            if Info.Multi then
                for v in next, D.Values do
                    if D.Value[v] then s = s .. v .. ", " end
                end
                s = s:sub(1, #s - 2)
            else
                s = D.Value or ""
            end
            itemLabel.Text = (s == "" and "--" or s)
        end

        function D:GetActiveValues()
            if Info.Multi then
                local t = {}
                for v in next, D.Value do table.insert(t, v) end
                return t
            end
            return D.Value and 1 or 0
        end

        function D:BuildDropdownList()
            local btns = {}
            for _, e in next, scroll:GetChildren() do
                if not e:IsA("UIListLayout") then e:Destroy() end
            end
            local count = 0
            for _, value in next, D.Values do
                local t = {}
                count = count + 1
                local btn = Library:Create("Frame", {
                    BackgroundColor3 = Library.PopupBG,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, -1, 0, 24),
                    ZIndex = 303, Active = true, Parent = scroll,
                })
                Library:AddToRegistry(btn, { BackgroundColor3 = "PopupBG" })
                local bl = Library:CreateLabel({
                    Active = false,
                    Size = UDim2.new(1, -10, 1, 0),
                    Position = UDim2.new(0, 10, 0, 0),
                    TextSize = Library.FontSize,
                    Text = value,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 305, Parent = btn,
                })
                btn.MouseEnter:Connect(function()
                    Library:Tween(btn, { BackgroundColor3 = Library.ControlHov })
                end)
                btn.MouseLeave:Connect(function()
                    Library:Tween(btn, { BackgroundColor3 = Library.PopupBG })
                end)
                local sel
                if Info.Multi then sel = D.Value[value] else sel = D.Value == value end
                function t:Update()
                    if Info.Multi then sel = D.Value[value] else sel = D.Value == value end
                    bl.TextColor3 = sel and Library.Accent or Library.FontColor
                    Library.RegistryMap[bl].Properties.TextColor3 = sel and "AccentColor" or "FontColor"
                end
                btn.InputBegan:Connect(function(input)
                    if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
                    local try = not sel
                    if D:GetActiveValues() ~= 1 or try or Info.AllowNull then
                        if Info.Multi then
                            sel = try
                            if sel then D.Value[value] = true else D.Value[value] = nil end
                        else
                            sel = try
                            if sel then D.Value = value else D.Value = nil end
                            for _, o in next, btns do o:Update() end
                        end
                        t:Update()
                        D:Display()
                        Library:SafeCallback(D.Callback, D.Value)
                        Library:SafeCallback(D.Changed, D.Value)
                        Library:AttemptSave()
                        Library:UpdateDependencyBoxes()
                    end
                end)
                t:Update()
                D:Display()
                btns[btn] = t
            end
            scroll.CanvasSize = UDim2.fromOffset(0, (count * 24) + 1)
            rs(math.clamp(count * 24, 0, MAX * 24) + 1)
        end

        function D:SetValues(v)
            if v then D.Values = v end
            D:BuildDropdownList()
        end
        function D:OpenDropdown()
            listOuter.Visible = true
            Library.OpenedFrames[listOuter] = true
            Library:Tween(chev, { Rotation = 180 })
        end
        function D:CloseDropdown()
            listOuter.Visible = false
            Library.OpenedFrames[listOuter] = nil
            Library:Tween(chev, { Rotation = 0 })
        end
        function D:OnChanged(f) D.Changed = f; f(D.Value) end

        function D:SetValue(v)
            if D.Multi then
                local nt = {}
                if v then
                    for k in next, v do
                        if table.find(D.Values, k) then nt[k] = true end
                    end
                end
                D.Value = nt
            else
                if not v then
                    D.Value = nil
                elseif table.find(D.Values, v) then
                    D.Value = v
                end
            end
            D:BuildDropdownList()
            Library:SafeCallback(D.Callback, D.Value)
            Library:SafeCallback(D.Changed, D.Value)
            Library:UpdateDependencyBoxes()
        end

        outer.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
               and not Library:MouseIsOverOpenedFrame() then
                if listOuter.Visible then D:CloseDropdown() else D:OpenDropdown() end
            end
        end)

        UIS.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                local ap = listOuter.AbsolutePosition
                local as = listOuter.AbsoluteSize
                if Mouse.X < ap.X or Mouse.X > ap.X + as.X
                   or Mouse.Y < ap.Y - 21 or Mouse.Y > ap.Y + as.Y then
                    D:CloseDropdown()
                end
            end
        end)

        D:BuildDropdownList()
        D:Display()

        local defs = {}
        if type(Info.Default) == "string" then
            local i = table.find(D.Values, Info.Default)
            if i then table.insert(defs, i) end
        elseif type(Info.Default) == "table" then
            for i in next, Info.Default do table.insert(defs, i) end
        elseif type(Info.Default) == "number" and D.Values[Info.Default] ~= nil then
            table.insert(defs, Info.Default)
        end
        for i in next, defs do
            if Info.Multi then
                D.Value[D.Values[i]] = true
            else
                D.Value = D.Values[i]
                break
            end
        end
        D:BuildDropdownList()
        D:Display()

        G:AddBlank(Info.BlankSize or 6)
        G:Resize()
        Library:UpdateDependencyBoxes()
        Options[Index] = D
        return D
    end

    function Funcs:AddDependencyBox()
        local D = { Dependencies = {} }
        local G, C = self, self.Container

        local holder = Library:Create("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 0),
            Visible = false, Parent = C,
        })
        local f = Library:Create("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            Visible = true, Parent = holder,
        })
        local l = Library:Create("UIListLayout", {
            FillDirection = Enum.FillDirection.Vertical,
            SortOrder = Enum.SortOrder.LayoutOrder, Parent = f,
        })

        function D:Resize()
            holder.Size = UDim2.new(1, 0, 0, l.AbsoluteContentSize.Y)
            G:Resize()
        end

        l:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() D:Resize() end)
        holder:GetPropertyChangedSignal("Visible"):Connect(function() D:Resize() end)

        function D:Update()
            for _, dep in next, D.Dependencies do
                local e, v = dep[1], dep[2]
                local match = false
                if type(v) == "table" then
                    for _, vv in ipairs(v) do
                        if e.Value == vv then match = true; break end
                    end
                else
                    match = (e.Value == v)
                end
                if not match then
                    holder.Visible = false
                    D:Resize()
                    return
                end
            end
            holder.Visible = true
            D:Resize()
        end

        function D:SetupDependencies(deps)
            for _, dep in next, deps do
                assert(type(dep) == "table" and dep[1] and dep[2] ~= nil)
            end
            D.Dependencies = deps
            D:Update()
            return self
        end

        D.Container = f
        setmetatable(D, BaseGroupbox)
        table.insert(Library.DependencyBoxes, D)
        return D
    end

    BaseGroupbox.__index = Funcs
    BaseGroupbox.__namecall = function(_, k, ...) return Funcs[k](...) end
end

-- ══════════════════════════════════════════════════════════════════════
-- HUD (notifications / watermark / keybinds)
-- ══════════════════════════════════════════════════════════════════════
do
    Library.NotificationArea = Library:Create("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 60),
        Size = UDim2.new(0, 340, 0, 300),
        ZIndex = 100, Parent = GUI,
    })
    Library:Create("UIListLayout", {
        Padding = UDim.new(0, 6),
        FillDirection = Enum.FillDirection.Vertical,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = Library.NotificationArea,
    })

    local wm = Library:Create("Frame", {
        BackgroundColor3 = Library.Border,
        BorderColor3 = Library.Border,
        Position = UDim2.new(0, 100, 0, 30),
        Size = UDim2.new(0, 220, 0, 22),
        ZIndex = 200, Visible = false, Parent = GUI,
    })
    local wmi = Library:Create("Frame", {
        BackgroundColor3 = Library.HeaderBG,
        BorderColor3 = Library.Accent,
        BorderMode = Enum.BorderMode.Inset,
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = 201, Parent = wm,
    })
    Library:AddToRegistry(wmi, { BorderColor3 = "Accent" })
    Library:Create("Frame", {
        BackgroundColor3 = Library.Accent,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 3, 1, 0),
        ZIndex = 202, Parent = wmi,
    })
    local wml = Library:CreateLabel({
        Position = UDim2.new(0, 10, 0, 0),
        Size = UDim2.new(1, -12, 1, 0),
        TextSize = 12, Font = Library.FontMed,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 203, Parent = wmi,
    })
    Library.Watermark = wm
    Library.WatermarkText = wml
    Library:MakeDraggable(wm)

    local kbO = Library:Create("Frame", {
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundColor3 = Library.Border,
        BorderColor3 = Library.Border,
        Position = UDim2.new(0, 14, 0.5, 0),
        Size = UDim2.new(0, 220, 0, 22),
        Visible = false, ZIndex = 100, Parent = GUI,
    })
    local kbI = Library:Create("Frame", {
        BackgroundColor3 = Library.PopupBG,
        BorderColor3 = Library.Outline,
        BorderMode = Enum.BorderMode.Inset,
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = 101, Parent = kbO,
    })
    Library:AddToRegistry(kbI, { BackgroundColor3 = "PopupBG", BorderColor3 = "Outline" }, true)
    Library:Create("Frame", {
        BackgroundColor3 = Library.Accent,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 2),
        ZIndex = 102, Parent = kbI,
    })
    Library:CreateLabel({
        Size = UDim2.new(1, 0, 0, 20),
        Position = UDim2.fromOffset(8, 2),
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = "Keybinds",
        TextColor3 = Library.FontMuted,
        Font = Library.FontMed,
        ZIndex = 104, Parent = kbI,
    })
    local kc = Library:Create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, -20),
        Position = UDim2.new(0, 0, 0, 20),
        ZIndex = 1, Parent = kbI,
    })
    Library:Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = kc,
    })
    Library:Create("UIPadding", { PaddingLeft = UDim.new(0, 8), Parent = kc })
    Library.KeybindFrame = kbO
    Library.KeybindContainer = kc
    Library:MakeDraggable(kbO)
end

function Library:SetWatermarkVisibility(v) Library.Watermark.Visible = v end
function Library:SetWatermark(t)
    local x, y = Library:GetTextBounds(t, Library.FontMed, 12)
    Library.Watermark.Size = UDim2.new(0, x + 22, 0, (y * 1.5) + 3)
    Library:SetWatermarkVisibility(true)
    Library.WatermarkText.Text = t
end

function Library:Notify(text, time)
    local xs, ys = Library:GetTextBounds(text, Library.Font, 12)
    ys = ys + 10
    local o = Library:Create("Frame", {
        BackgroundColor3 = Library.Border,
        BorderColor3 = Library.Border,
        Position = UDim2.new(0, 100, 0, 10),
        Size = UDim2.new(0, 0, 0, ys),
        ClipsDescendants = true,
        ZIndex = 100, Parent = Library.NotificationArea,
    })
    local i_ = Library:Create("Frame", {
        BackgroundColor3 = Library.PopupBG,
        BorderColor3 = Library.Outline,
        BorderMode = Enum.BorderMode.Inset,
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = 101, Parent = o,
    })
    Library:AddToRegistry(i_, { BackgroundColor3 = "PopupBG", BorderColor3 = "Outline" }, true)
    Library:CreateLabel({
        Position = UDim2.new(0, 10, 0, 0),
        Size = UDim2.new(1, -6, 1, 0),
        Text = text,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextSize = 12, ZIndex = 103, Parent = i_,
    })
    Library:Create("Frame", {
        BackgroundColor3 = Library.Accent,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 3, 1, 0),
        ZIndex = 104, Parent = i_,
    })
    pcall(o.TweenSize, o, UDim2.new(0, xs + 18, 0, ys), "Out", "Quad", 0.35, true)
    task.spawn(function()
        task.wait(time or 5)
        pcall(o.TweenSize, o, UDim2.new(0, 0, 0, ys), "Out", "Quad", 0.35, true)
        task.wait(0.35)
        o:Destroy()
    end)
end

-- ══════════════════════════════════════════════════════════════════════
-- LOADING SCREEN
-- ══════════════════════════════════════════════════════════════════════
function Library:ShowLoadingScreen(duration, onComplete)
    duration = duration or 3.0

    local ls = Library:Create("Frame", {
        Name = "LoadingScreen",
        BackgroundColor3 = Color3.fromRGB(10, 10, 10),
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1),
        ZIndex = 10000, Parent = GUI,
    })

    local stack = Library:Create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(600, 220),
        ZIndex = 10002, Parent = ls,
    })

    local gs = Library:Create("TextLabel", {
        BackgroundTransparency = 1,
        Font = Library.FontBold,
        TextSize = 52, Text = "gamesense",
        TextColor3 = Library.Accent,
        TextXAlignment = Enum.TextXAlignment.Right,
        TextYAlignment = Enum.TextYAlignment.Center,
        Position = UDim2.new(0.5, 0, 0, 30),
        AnchorPoint = Vector2.new(1, 0.5),
        Size = UDim2.new(0, 300, 0, 70),
        TextTransparency = 1,
        ZIndex = 10003, Parent = stack,
    })

    local win = Library:Create("TextLabel", {
        BackgroundTransparency = 1,
        Font = Library.FontBold,
        TextSize = 52, Text = ".win",
        TextColor3 = Color3.fromRGB(240, 240, 240),
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        Position = UDim2.new(0.5, 0, 0, 30),
        AnchorPoint = Vector2.new(0, 0.5),
        Size = UDim2.new(0, 200, 0, 70),
        TextTransparency = 1,
        ZIndex = 10003, Parent = stack,
    })

    local underline = Library:Create("Frame", {
        BackgroundColor3 = Library.Accent,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0, 78),
        Size = UDim2.new(0, 0, 0, 2),
        ZIndex = 10003, Parent = stack,
    })

    local status = Library:Create("TextLabel", {
        BackgroundTransparency = 1,
        Font = Library.FontMed,
        TextSize = 13, Text = "initializing",
        TextColor3 = Library.FontMuted,
        TextXAlignment = Enum.TextXAlignment.Center,
        TextYAlignment = Enum.TextYAlignment.Center,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0, 130),
        Size = UDim2.new(0, 400, 0, 20),
        TextTransparency = 1,
        ZIndex = 10003, Parent = stack,
    })

    local barOuter = Library:Create("Frame", {
        BackgroundColor3 = Color3.fromRGB(28, 28, 28),
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0, 168),
        Size = UDim2.new(0, 360, 0, 3),
        BackgroundTransparency = 1,
        ZIndex = 10003, Parent = stack,
    })
    local barFill = Library:Create("Frame", {
        BackgroundColor3 = Library.Accent,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 0, 1, 0),
        ZIndex = 10004, Parent = barOuter,
    })

    local ver = Library:Create("TextLabel", {
        BackgroundTransparency = 1,
        Font = Library.FontMed,
        TextSize = 12, Text = "v" .. Library.Version,
        TextColor3 = Library.FontDim,
        TextXAlignment = Enum.TextXAlignment.Right,
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, -24, 1, -20),
        Size = UDim2.new(0, 120, 0, 20),
        TextTransparency = 1,
        ZIndex = 10003, Parent = ls,
    })

    local msgs = { "initializing", "loading library", "preparing interface", "ready" }

    task.spawn(function()
        task.wait(0.1)
        Tween:Create(gs, TweenInfo.new(0.5, Enum.EasingStyle.Quart), { TextTransparency = 0 }):Play()
        Tween:Create(win, TweenInfo.new(0.5, Enum.EasingStyle.Quart), { TextTransparency = 0 }):Play()
        task.wait(0.35)
        local totalWidth = gs.TextBounds.X + win.TextBounds.X
        Tween:Create(underline, TweenInfo.new(0.7, Enum.EasingStyle.Quart), {
            Size = UDim2.new(0, totalWidth, 0, 2),
        }):Play()
        Tween:Create(barOuter, TweenInfo.new(0.4), { BackgroundTransparency = 0 }):Play()
        Tween:Create(status, TweenInfo.new(0.4), { TextTransparency = 0 }):Play()
        Tween:Create(ver, TweenInfo.new(0.4), { TextTransparency = 0 }):Play()
    end)

    task.spawn(function()
        local start = tick()
        local lastIdx = 1
        while true do
            local elapsed = tick() - start
            if elapsed >= duration then break end
            local pct = math.clamp(elapsed / duration, 0, 1)
            local eased = 1 - (1 - pct) ^ 3
            barFill.Size = UDim2.new(eased, 0, 1, 0)
            local idx = math.min(#msgs, math.floor(pct * #msgs) + 1)
            if idx ~= lastIdx then
                lastIdx = idx
                status.Text = msgs[idx]
            end
            Render:Wait()
        end
        barFill.Size = UDim2.new(1, 0, 1, 0)
        status.Text = "ready"
    end)

    task.spawn(function()
        task.wait(duration + 0.2)
        local ft = 0.45
        Tween:Create(gs, TweenInfo.new(ft, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { TextTransparency = 1 }):Play()
        Tween:Create(win, TweenInfo.new(ft, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { TextTransparency = 1 }):Play()
        Tween:Create(status, TweenInfo.new(ft, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { TextTransparency = 1 }):Play()
        Tween:Create(ver, TweenInfo.new(ft, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { TextTransparency = 1 }):Play()
        Tween:Create(underline, TweenInfo.new(ft, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Size = UDim2.new(0, 0, 0, 2) }):Play()
        Tween:Create(barOuter, TweenInfo.new(ft * 0.6), { BackgroundTransparency = 1 }):Play()
        Tween:Create(barFill, TweenInfo.new(ft * 0.6), { BackgroundTransparency = 1 }):Play()
        Tween:Create(ls, TweenInfo.new(ft, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { BackgroundTransparency = 1 }):Play()
        task.wait(ft + 0.05)
        ls:Destroy()
        if onComplete then onComplete() end
    end)
end

-- ══════════════════════════════════════════════════════════════════════
-- WINDOW
-- ══════════════════════════════════════════════════════════════════════
function Library:CreateWindow(cfg)
    if type(cfg.Title) ~= "string" then cfg.Title = Library.Brand end
    if type(cfg.MenuFadeTime) ~= "number" then cfg.MenuFadeTime = 0.25 end
    cfg.AnchorPoint = Vector2.new(0.5, 0.5)
    cfg.Position = UDim2.fromScale(0.5, 0.5)
    if typeof(cfg.Size) ~= "UDim2" then cfg.Size = UDim2.fromOffset(660, 540) end

    local Window = { Tabs = {}, Size = cfg.Size }

    local Outer = Library:Create("Frame", {
        AnchorPoint = cfg.AnchorPoint,
        BackgroundColor3 = Library.Border,
        BorderSizePixel = 0,
        Position = cfg.Position,
        Size = cfg.Size,
        Visible = false,
        ZIndex = 1, Parent = GUI,
    })
    Library:MakeDraggable(Outer, 36)

    local Inner = Library:Create("Frame", {
        BackgroundColor3 = Library.WindowBG,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 1, 0, 1),
        Size = UDim2.new(1, -2, 1, -2),
        ZIndex = 2, Parent = Outer,
    })

    -- HEADER
    local Header = Library:Create("Frame", {
        BackgroundColor3 = Library.HeaderBG,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 36),
        ZIndex = 3, Parent = Inner,
    })
    Library:Create("Frame", {
        BackgroundColor3 = Library.Divider,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 1, -1),
        Size = UDim2.new(1, 0, 0, 1),
        ZIndex = 4, Parent = Header,
    })
    Library:Create("Frame", {
        BackgroundColor3 = Library.Accent,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 14, 0.5, -5),
        Size = UDim2.new(0, 10, 0, 10),
        ZIndex = 5, Parent = Header,
    })
    local TitleLbl = Library:CreateLabel({
        Position = UDim2.new(0, 32, 0, 0),
        Size = UDim2.new(0, 200, 1, 0),
        Text = cfg.Title,
        Font = Library.FontBold, TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 5, Parent = Header,
    })
    Library:AddToRegistry(TitleLbl, { TextColor3 = "FontColor" })
    local SubtitleLbl = Library:CreateLabel({
        Position = UDim2.new(0, 200, 0, 0),
        Size = UDim2.new(1, -280, 1, 0),
        Text = "",
        Font = Library.Font, TextSize = 12,
        TextColor3 = Library.FontMuted,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 5, Parent = Header,
    })
    local VerLbl = Library:CreateLabel({
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -52, 0, 0),
        Size = UDim2.new(0, 80, 1, 0),
        Text = "v" .. Library.Version,
        Font = Library.FontMed, TextSize = 11,
        TextColor3 = Library.FontDim,
        TextXAlignment = Enum.TextXAlignment.Right,
        ZIndex = 5, Parent = Header,
    })
    -- Close button
    local closeBtn = Library:Create("Frame", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -10, 0.5, 0),
        Size = UDim2.fromOffset(22, 22),
        BackgroundColor3 = Library.ControlBG,
        BorderColor3 = Library.Outline,
        BorderMode = Enum.BorderMode.Inset,
        ZIndex = 6, Parent = Header, Active = true,
    })
    Library:AddToRegistry(closeBtn, { BackgroundColor3 = "ControlBG", BorderColor3 = "Outline" })
    for _, rot in ipairs({ 45, -45 }) do
        Library:Create("Frame", {
            BackgroundColor3 = Library.FontMuted,
            BorderSizePixel = 0,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            Size = UDim2.fromOffset(1.5, 10),
            Rotation = rot, ZIndex = 7, Parent = closeBtn,
        })
    end
    closeBtn.MouseEnter:Connect(function()
        Library:Tween(closeBtn, { BackgroundColor3 = Library.RiskColor })
    end)
    closeBtn.MouseLeave:Connect(function()
        Library:Tween(closeBtn, { BackgroundColor3 = Library.ControlBG })
    end)
    closeBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            Library:Toggle(false)
        end
    end)

    -- BODY
    local Body = Library:Create("Frame", {
        BackgroundColor3 = Library.WindowBG,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 36),
        Size = UDim2.new(1, 0, 1, -36),
        ZIndex = 3, Parent = Inner,
    })
    local Sidebar = Library:Create("Frame", {
        BackgroundColor3 = Library.SidebarBG,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 52, 1, 0),
        ZIndex = 4, Parent = Body,
    })
    Library:Create("UIListLayout", {
        Padding = UDim.new(0, 6),
        FillDirection = Enum.FillDirection.Vertical,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = Sidebar,
    })
    Library:Create("UIPadding", { PaddingTop = UDim.new(0, 10), Parent = Sidebar })

    local Content = Library:Create("Frame", {
        BackgroundColor3 = Library.WindowBG,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 52, 0, 0),
        Size = UDim2.new(1, -52, 1, 0),
        ZIndex = 4, Parent = Body,
    })
    local SubHeader = Library:Create("Frame", {
        BackgroundColor3 = Library.HeaderBG,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 24),
        ZIndex = 5, Parent = Content,
    })
    Library:Create("Frame", {
        BackgroundColor3 = Library.Accent,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(0, 2, 1, 0),
        ZIndex = 6, Parent = SubHeader,
    })
    Library:Create("Frame", {
        BackgroundColor3 = Library.Divider,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 1, -1),
        Size = UDim2.new(1, 0, 0, 1),
        ZIndex = 6, Parent = SubHeader,
    })
    local SubHeaderTitle = Library:CreateLabel({
        Position = UDim2.new(0, 14, 0, 0),
        Size = UDim2.new(1, -20, 1, 0),
        Text = "",
        Font = Library.FontMed, TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 6, Parent = SubHeader,
    })
    local TabContainer = Library:Create("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 24),
        Size = UDim2.new(1, 0, 1, -24),
        ZIndex = 5, Parent = Content,
    })

    function Window:SetWindowTitle(t) TitleLbl.Text = t end
    function Window:SetSubtitle(t)
        SubtitleLbl.Text = (t and t ~= "") and t or ""
    end

    function Window:AddTab(name, icon)
        local Tab = { Groupboxes = {}, Tabboxes = {}, IconParts = {}, IconName = name }
        local IB = Library:Create("Frame", {
            BackgroundColor3 = Library.SidebarBG,
            BorderSizePixel = 0,
            Size = UDim2.new(0, 40, 0, 40),
            ZIndex = 5, Parent = Sidebar,
        })
        local iconFrame, parts = DrawIcon(name, 22, IB, Library.FontMuted)
        iconFrame.Position = UDim2.new(0, 9, 0, 9)
        Tab.IconParts = parts
        Tab.IconButton = IB

        local IAcc = Library:Create("Frame", {
            BackgroundColor3 = Library.Accent,
            BorderSizePixel = 0,
            Position = UDim2.new(0, 0, 0.5, -8),
            Size = UDim2.new(0, 2, 0, 16),
            Visible = false, ZIndex = 7, Parent = IB,
        })
        Library:AddToRegistry(IAcc, { BackgroundColor3 = "Accent" })

        local TabFrame = Library:Create("Frame", {
            Name = "TabFrame",
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            Visible = false,
            ZIndex = 2, Parent = TabContainer,
        })
        local LS = Library:Create("ScrollingFrame", {
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Position = UDim2.new(0, 12, 0, 12),
            Size = UDim2.new(0.5, -16, 1, -24),
            CanvasSize = UDim2.new(0, 0, 0, 0),
            BottomImage = "", TopImage = "",
            ScrollBarThickness = 0,
            ZIndex = 2, Parent = TabFrame,
        })
        local RSc = Library:Create("ScrollingFrame", {
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Position = UDim2.new(0.5, 4, 0, 12),
            Size = UDim2.new(0.5, -16, 1, -24),
            CanvasSize = UDim2.new(0, 0, 0, 0),
            BottomImage = "", TopImage = "",
            ScrollBarThickness = 0,
            ZIndex = 2, Parent = TabFrame,
        })
        Library:Create("UIListLayout", {
            Padding = UDim.new(0, 10),
            FillDirection = Enum.FillDirection.Vertical,
            SortOrder = Enum.SortOrder.LayoutOrder,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            Parent = LS,
        })
        Library:Create("UIListLayout", {
            Padding = UDim.new(0, 10),
            FillDirection = Enum.FillDirection.Vertical,
            SortOrder = Enum.SortOrder.LayoutOrder,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            Parent = RSc,
        })
        for _, S in ipairs({ LS, RSc }) do
            local layout = S:WaitForChild("UIListLayout")
            layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                S.CanvasSize = UDim2.fromOffset(0, layout.AbsoluteContentSize.Y)
            end)
        end

        function Tab:ShowTab()
            for _, T in next, Window.Tabs do T:HideTab() end
            IAcc.Visible = true
            Library:Tween(IB, { BackgroundColor3 = Library.ControlBG })
            for _, p in next, Tab.IconParts do
                pcall(function()
                    if p:IsA("UIStroke") then
                        p.Color = Library.Accent
                    else
                        p.BackgroundColor3 = Library.Accent
                    end
                end)
            end
            TabFrame.Visible = true
            SubHeaderTitle.Text = name
        end

        function Tab:HideTab()
            IAcc.Visible = false
            Library:Tween(IB, { BackgroundColor3 = Library.SidebarBG })
            for _, p in next, Tab.IconParts do
                pcall(function()
                    if p:IsA("UIStroke") then
                        p.Color = Library.FontMuted
                    else
                        p.BackgroundColor3 = Library.FontMuted
                    end
                end)
            end
            TabFrame.Visible = false
        end

        function Tab:SetLayoutOrder(p) IB.LayoutOrder = p end

        function Tab:AddGroupbox(Info)
            local GB = {}
            local BO = Library:Create("Frame", {
                BackgroundColor3 = Library.PanelBG,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 26),
                ZIndex = 2,
                Parent = Info.Side == 1 and LS or RSc,
            })
            Library:AddToRegistry(BO, { BackgroundColor3 = "PanelBG" })

            local HS = Library:Create("Frame", {
                BackgroundColor3 = Library.HeaderBG,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 24),
                ZIndex = 4, Parent = BO,
            })
            Library:Create("Frame", {
                BackgroundColor3 = Library.Accent,
                BorderSizePixel = 0,
                Position = UDim2.new(0, 0, 0, 0),
                Size = UDim2.new(0, 2, 1, 0),
                ZIndex = 5, Parent = HS,
            })
            Library:Create("Frame", {
                BackgroundColor3 = Library.Divider,
                BorderSizePixel = 0,
                Position = UDim2.new(0, 0, 1, -1),
                Size = UDim2.new(1, 0, 0, 1),
                ZIndex = 5, Parent = HS,
            })
            Library:CreateLabel({
                Size = UDim2.new(1, 0, 1, 0),
                Position = UDim2.new(0, 12, 0, 0),
                TextSize = 12, Text = Info.Name,
                Font = Library.FontMed,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 5, Parent = HS,
            })

            local C = Library:Create("Frame", {
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 12, 0, 32),
                Size = UDim2.new(1, -24, 1, -32),
                ZIndex = 1, Parent = BO,
            })
            Library:Create("UIListLayout", {
                FillDirection = Enum.FillDirection.Vertical,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Parent = C,
            })

            function GB:Resize()
                local s = 0
                for _, e in next, GB.Container:GetChildren() do
                    if not e:IsA("UIListLayout") and e.Visible then
                        s = s + e.Size.Y.Offset
                    end
                end
                BO.Size = UDim2.new(1, 0, 0, 32 + s + 12)
            end

            GB.Container = C
            setmetatable(GB, BaseGroupbox)
            GB:AddBlank(4)
            GB:Resize()
            Tab.Groupboxes[Info.Name] = GB
            return GB
        end

        function Tab:AddLeftGroupbox(n)
            return Tab:AddGroupbox({ Side = 1, Name = n })
        end
        function Tab:AddRightGroupbox(n)
            return Tab:AddGroupbox({ Side = 2, Name = n })
        end

        function Tab:AddTabbox(Info)
            local Tabbox = { Tabs = {} }
            local BO = Library:Create("Frame", {
                BackgroundColor3 = Library.PanelBG,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 26),
                ZIndex = 2,
                Parent = Info.Side == 1 and LS or RSc,
            })
            Library:AddToRegistry(BO, { BackgroundColor3 = "PanelBG" })

            local HS = Library:Create("Frame", {
                BackgroundColor3 = Library.HeaderBG,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 24),
                ZIndex = 4, Parent = BO,
            })
            local TB = Library:Create("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 1, 0),
                ZIndex = 5, Parent = HS,
            })
            Library:Create("UIListLayout", {
                FillDirection = Enum.FillDirection.Horizontal,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Parent = TB,
            })

            function Tabbox:AddTab(Name)
                local T = {}
                local B = Library:Create("Frame", {
                    BackgroundColor3 = Library.HeaderBG,
                    BorderSizePixel = 0,
                    Size = UDim2.new(0, 110, 1, 0),
                    ZIndex = 6, Parent = TB,
                })
                Library:AddToRegistry(B, { BackgroundColor3 = "HeaderBG" })
                local BL = Library:CreateLabel({
                    Size = UDim2.new(1, 0, 1, 0),
                    TextSize = 12, Text = Name,
                    Font = Library.FontMed,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    ZIndex = 7, Parent = B,
                })
                local UL = Library:Create("Frame", {
                    BackgroundColor3 = Library.Accent,
                    BorderSizePixel = 0,
                    Position = UDim2.new(0, 0, 1, -1),
                    Size = UDim2.new(1, 0, 0, 1),
                    Visible = false, ZIndex = 9, Parent = B,
                })
                local C = Library:Create("Frame", {
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 12, 0, 32),
                    Size = UDim2.new(1, -24, 1, -32),
                    ZIndex = 1, Visible = false, Parent = BO,
                })
                Library:Create("UIListLayout", {
                    FillDirection = Enum.FillDirection.Vertical,
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Parent = C,
                })

                function T:Show()
                    for _, o in next, Tabbox.Tabs do o:Hide() end
                    C.Visible = true
                    UL.Visible = true
                    BL.TextColor3 = Library.Accent
                    Library.RegistryMap[BL].Properties.TextColor3 = "AccentColor"
                    T:Resize()
                end
                function T:Hide()
                    C.Visible = false
                    UL.Visible = false
                    BL.TextColor3 = Library.FontColor
                    Library.RegistryMap[BL].Properties.TextColor3 = "FontColor"
                end
                function T:Resize()
                    local ct = 0
                    for _ in next, Tabbox.Tabs do ct = ct + 1 end
                    for _, b in next, TB:GetChildren() do
                        if not b:IsA("UIListLayout") then
                            b.Size = UDim2.new(1 / ct, 0, 1, 0)
                        end
                    end
                    if not C.Visible then return end
                    local s = 0
                    for _, e in next, T.Container:GetChildren() do
                        if not e:IsA("UIListLayout") and e.Visible then
                            s = s + e.Size.Y.Offset
                        end
                    end
                    BO.Size = UDim2.new(1, 0, 0, 32 + s + 12)
                end

                B.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1
                       and not Library:MouseIsOverOpenedFrame() then
                        T:Show(); T:Resize()
                    end
                end)

                T.Container = C
                Tabbox.Tabs[Name] = T
                setmetatable(T, BaseGroupbox)
                T:AddBlank(3)
                T:Resize()
                if #TB:GetChildren() == 2 then T:Show() end
                return T
            end

            Tab.Tabboxes[Info.Name or ""] = Tabbox
            return Tabbox
        end

        function Tab:AddLeftTabbox(n)
            return Tab:AddTabbox({ Name = n, Side = 1 })
        end
        function Tab:AddRightTabbox(n)
            return Tab:AddTabbox({ Name = n, Side = 2 })
        end

        IB.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then Tab:ShowTab() end
        end)
        IB.MouseEnter:Connect(function()
            if not IAcc.Visible then
                Library:Tween(IB, { BackgroundColor3 = Library.ControlBG })
            end
        end)
        IB.MouseLeave:Connect(function()
            if not IAcc.Visible then
                Library:Tween(IB, { BackgroundColor3 = Library.SidebarBG })
            end
        end)

        if #TabContainer:GetChildren() == 1 then Tab:ShowTab() end
        Window.Tabs[name] = Tab
        return Tab
    end

    -- ═══════════════════════════════════════════════════════════
    -- TOGGLE
    -- ═══════════════════════════════════════════════════════════
    local menuOpen = false
    local animGeneration = 0
    local cursorActive = false
    local lastKeyToggle = 0
    local KEY_DEBOUNCE = 0.25

    function Library:Toggle(force)
        local target = (force ~= nil) and force or (not menuOpen)
        if target == menuOpen then return end
        menuOpen = target
        Library.Toggled = target
        animGeneration = animGeneration + 1
        local gen = animGeneration

        if target then
            -- OPEN
            Outer.Visible = true
            Outer.Size = UDim2.fromOffset(
                math.floor(cfg.Size.X.Offset * 0.92),
                math.floor(cfg.Size.Y.Offset * 0.92)
            )
            Tween:Create(Outer,
                TweenInfo.new(Library.AnimOpen, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
                { Size = cfg.Size }
            ):Play()

            if not cursorActive then
                cursorActive = true
                task.spawn(function()
                    local st = UIS.MouseIconEnabled
                    local c = Drawing.new("Triangle")
                    c.Thickness = 1
                    c.Filled = true
                    c.Visible = true
                    while menuOpen and GUI.Parent do
                        UIS.MouseIconEnabled = false
                        local mp = UIS:GetMouseLocation()
                        c.Color = Library.Accent
                        c.PointA = Vector2.new(mp.X, mp.Y)
                        c.PointB = Vector2.new(mp.X + 14, mp.Y + 5)
                        c.PointC = Vector2.new(mp.X + 5, mp.Y + 14)
                        Render:Wait()
                    end
                    UIS.MouseIconEnabled = st
                    c:Remove()
                    cursorActive = false
                end)
            end
        else
            -- CLOSE
            for m in next, Library.ModeSelectOuters do m.Visible = false end
            Tween:Create(Outer,
                TweenInfo.new(Library.AnimClose, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
                {
                    Size = UDim2.fromOffset(
                        math.floor(cfg.Size.X.Offset * 0.92),
                        math.floor(cfg.Size.Y.Offset * 0.92)
                    )
                }
            ):Play()
            UIS.MouseIconEnabled = true
            task.delay(Library.AnimClose + 0.02, function()
                if animGeneration == gen and not menuOpen then
                    Outer.Visible = false
                end
            end)
        end
    end

    local function isToggleKey(kc)
        if kc == Enum.KeyCode.RightShift
           or kc == Enum.KeyCode.RightControl
           or kc == Enum.KeyCode.Insert then
            return true
        end
        if type(Library.ToggleKeybind) == "table"
           and Library.ToggleKeybind.Type == "KeyPicker"
           and kc.Name == Library.ToggleKeybind.Value then
            return true
        end
        return false
    end

    UIS.InputBegan:Connect(function(input)
        -- Only accept real keyboard events.
        -- Roblox fires InputBegan once per bound device (Keyboard, Gamepad1..8, executor mirror),
        -- so filtering to Keyboard only + a debounce prevents duplicate toggles.
        if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
        if not isToggleKey(input.KeyCode) then return end
        local now = os.clock()
        if now - lastKeyToggle < KEY_DEBOUNCE then return end
        lastKeyToggle = now
        Library:Toggle()
    end)

    Window.Holder = Outer
    return Window
end

-- ══════════════════════════════════════════════════════════════════════
-- CUSTOMIZATION TAB
-- ══════════════════════════════════════════════════════════════════════
function Library:BuildCustomizationTab(tab)
    local ui = tab:AddLeftGroupbox("Interface")
    local names = {}
    for k in next, Themes do table.insert(names, k) end
    table.sort(names)
    ui:AddDropdown("UI_Theme", {
        Text = "Theme",
        Default = "Gamesense",
        Values = names,
        Callback = function(v) Library:SetTheme(v) end,
    })
    local acc = ui:AddLabel("Accent Color")
    acc:AddColorPicker("UI_AccentColor", {
        Default = Library.Accent,
        Title = "Custom Accent",
        Callback = function(c) Library:SetAccent(c) end,
    })
    ui:AddSlider("UI_CornerRadius", {
        Text = "Corner Radius",
        Default = 0, Min = 0, Max = 12, Rounding = 0,
        Callback = function(v)
            Library.CornerRadius = v
            for _, obj in next, Library.Registry do
                local i = obj.Instance
                if i:IsA("Frame") or i:IsA("ScrollingFrame")
                   or i:IsA("TextButton") or i:IsA("TextBox")
                   or i:IsA("ImageLabel") then
                    local c = i:FindFirstChildOfClass("UICorner")
                    if not c then
                        c = cref(Instance.new("UICorner"))
                        c.Parent = i
                    end
                    c.CornerRadius = UDim.new(0, v)
                end
            end
        end,
    })

    local beh = tab:AddRightGroupbox("Behavior")
    beh:AddToggle("UI_Animations", {
        Text = "UI Animations",
        Default = true,
        Callback = function(v) Library.Animations = v end,
    })
    beh:AddToggle("UI_Sounds", {
        Text = "Click Sounds",
        Default = true,
        Callback = function(v) Library.Sounds.Enabled = v end,
    })
    beh:AddSlider("UI_AnimOpen", {
        Text = "Open Speed",
        Default = 30, Min = 10, Max = 60, Rounding = 0, Suffix = "ms",
        Callback = function(v) Library.AnimOpen = v / 100 end,
    })
    beh:AddSlider("UI_AnimClose", {
        Text = "Close Speed",
        Default = 20, Min = 10, Max = 60, Rounding = 0, Suffix = "ms",
        Callback = function(v) Library.AnimClose = v / 100 end,
    })
end

-- ══════════════════════════════════════════════════════════════════════
-- PLAYER DROPDOWN REFRESH
-- ══════════════════════════════════════════════════════════════════════
local function OnPlayerChange()
    local pl = GetPlayersString()
    for _, v in next, Options do
        if v.Type == "Dropdown" and v.SpecialType == "Player" then
            v:SetValues(pl)
        end
    end
end
Players.PlayerAdded:Connect(OnPlayerChange)
Players.PlayerRemoving:Connect(OnPlayerChange)

-- ══════════════════════════════════════════════════════════════════════
-- EXPORTS
-- ══════════════════════════════════════════════════════════════════════
getgenv().Library = Library
getgenv().gamesense = Library
getgenv().openMenu   = function() Library:Toggle(true)  end
getgenv().closeMenu  = function() Library:Toggle(false) end
getgenv().toggleMenu = function() Library:Toggle()      end

return Library
