--[[
    Linoria (gamesense edition)
    Restyled to emulate the visual language of gamesense for CS:GO.
    API compatible with the original Linoria fork.
]]

-- ============================================================
-- Services & compat
-- ============================================================
local clonerefFunction = cloneref or clone_ref or clonereference or clone_reference
local ns__cloneref = clonerefFunction and function(Object)
    local Success, Result = pcall(clonerefFunction, Object)
    return Success and Result or Object
end or function(Object) return Object end

local UserInputService = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")
local TextService       = game:GetService("TextService")
local HttpService       = game:GetService("HttpService")
local RunService        = game:GetService("RunService")
local Players           = game:GetService("Players")
local Teams             = game:GetService("Teams")

local RenderStepped = RunService.RenderStepped
local LocalPlayer   = Players.LocalPlayer
local Mouse         = ns__cloneref(LocalPlayer:GetMouse())

local ScreenGui = ns__cloneref(Instance.new("ScreenGui"))
ScreenGui.Name = "gamesense_" .. tostring(math.random(1000, 9999))
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = ns__cloneref(game:GetService("CoreGui"))

local Toggles = {}
local Options = {}

-- ============================================================
-- gamesense palette + typography
-- ============================================================
local Library = {
    Toggled = true,
    Toggles = Toggles,
    Options = Options,

    Registry    = {},
    RegistryMap = {},
    HudRegistry = {},

    -- core colors
    FontColor     = Color3.fromRGB(220, 220, 220),
    FontMuted     = Color3.fromRGB(150, 150, 150),
    WindowBG      = Color3.fromRGB(12, 12, 12),   -- outer frame
    PanelBG       = Color3.fromRGB(24, 24, 24),   -- groupbox body
    SectionBG     = Color3.fromRGB(18, 18, 18),   -- inner section / header strip
    SidebarBG     = Color3.fromRGB(8, 8, 8),      -- left icon strip
    HeaderBG      = Color3.fromRGB(32, 32, 32),   -- header bar
    ControlBG     = Color3.fromRGB(32, 32, 32),
    ControlHover  = Color3.fromRGB(42, 42, 42),
    Border        = Color3.fromRGB(6, 6, 6),
    Outline       = Color3.fromRGB(52, 52, 52),
    Divider       = Color3.fromRGB(40, 40, 40),

    -- accent / status
    Accent        = Color3.fromRGB(144, 200, 83),   -- gamesense green
    AccentDark    = Color3.fromRGB(96, 145, 55),
    AccentHover   = Color3.fromRGB(160, 215, 100),
    RiskColor     = Color3.fromRGB(217, 83, 79),
    WarningColor  = Color3.fromRGB(240, 173, 78),
    Black         = Color3.new(0, 0, 0),

    -- legacy aliases (used throughout old code)
    MainColor       = Color3.fromRGB(24, 24, 24),
    BackgroundColor = Color3.fromRGB(18, 18, 18),

    -- typography
    Font        = Enum.Font.SourceSans,
    FontBold    = Enum.Font.SourceSansBold,
    FontSize    = 13,
    FontSizeSm  = 11,
    FontSizeHd  = 14,

    -- misc
    OpenedFrames    = {},
    DependencyBoxes = {},
    ModeSelectOuters= {},
    ScreenGui       = ScreenGui,

    -- behavior toggles
    Sounds = {
        Enabled = true,
        Click   = "rbxassetid://6895079853",
        Volume  = 0.35,
    },
    CornerRadius = 0, -- gamesense is squared-off
}

Library.AccentColor     = Library.Accent
Library.AccentColorDark = Library.AccentDark
Library.OutlineColor    = Library.Outline

-- ============================================================
-- Utilities
-- ============================================================
local function GetPlayersString()
    local l = Players:GetPlayers()
    for i = 1, #l do l[i] = l[i].Name end
    table.sort(l, function(a, b) return a < b end)
    return l
end

local function GetTeamsString()
    local l = Teams:GetTeams()
    for i = 1, #l do l[i] = l[i].Name end
    table.sort(l, function(a, b) return a < b end)
    return l
end

function Library:SafeCallback(f, ...)
    if not f then return end
    if not Library.NotifyOnError then return f(...) end
    local ok, err = pcall(f, ...)
    if not ok then
        local _, i = err:find(":%d+: ")
        return Library:Notify(i and err:sub(i + 1) or err, 3)
    end
end

function Library:AttemptSave()
    if Library.SaveManager then Library.SaveManager:Save() end
end

function Library:Create(Class, Properties)
    local inst = Class
    if type(Class) == "string" then inst = ns__cloneref(Instance.new(Class)) end
    for k, v in next, Properties or {} do inst[k] = v end
    if Library.CornerRadius > 0
       and (inst:IsA("Frame") or inst:IsA("ScrollingFrame")
       or inst:IsA("TextButton") or inst:IsA("TextBox") or inst:IsA("ImageLabel")) then
        local c = inst:FindFirstChildOfClass("UICorner")
        if not c then c = ns__cloneref(Instance.new("UICorner")); c.Parent = inst end
        c.CornerRadius = UDim.new(0, Library.CornerRadius)
    end
    return inst
end

function Library:ApplyTextStroke(inst)
    inst.TextStrokeTransparency = 1
end

function Library:CreateLabel(Properties, IsHud)
    local label = Library:Create("TextLabel", {
        BackgroundTransparency = 1,
        Font = Library.Font,
        TextColor3 = Library.FontColor,
        TextSize = Library.FontSize,
        TextStrokeTransparency = 1,
    })
    Library:AddToRegistry(label, { TextColor3 = "FontColor" }, IsHud)
    return Library:Create(label, Properties)
end

function Library:GetTextBounds(Text, Font, Size, Resolution)
    local b = TextService:GetTextSize(Text, Size, Font, Resolution or Vector2.new(1920, 1080))
    return b.X, b.Y
end

function Library:GetDarkerColor(Color)
    local H, S, V = Color3.toHSV(Color)
    return Color3.fromHSV(H, S, V / 1.5)
end

function Library:MapValue(Value, MinA, MaxA, MinB, MaxB)
    return (1 - ((Value - MinA) / (MaxA - MinA))) * MinB + ((Value - MinA) / (MaxA - MinA)) * MaxB
end

function Library:MakeDraggable(Instance, Cutoff)
    Instance.Active = true
    Instance.InputBegan:Connect(function(Input)
        if Input.UserInputType == Enum.UserInputType.MouseButton1 then
            local ObjPos = Vector2.new(
                Mouse.X - Instance.AbsolutePosition.X,
                Mouse.Y - Instance.AbsolutePosition.Y
            )
            if ObjPos.Y > (Cutoff or 40) then return end
            while UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                Instance.Position = UDim2.new(
                    0, Mouse.X - ObjPos.X + (Instance.Size.X.Offset * Instance.AnchorPoint.X),
                    0, Mouse.Y - ObjPos.Y + (Instance.Size.Y.Offset * Instance.AnchorPoint.Y)
                )
                RenderStepped:Wait()
            end
        end
    end)
end

function Library:MouseIsOverOpenedFrame()
    for Frame in next, Library.OpenedFrames do
        local ap, as = Frame.AbsolutePosition, Frame.AbsoluteSize
        if Mouse.X >= ap.X and Mouse.X <= ap.X + as.X
        and Mouse.Y >= ap.Y and Mouse.Y <= ap.Y + as.Y then return true end
    end
end

function Library:IsMouseOverFrame(Frame)
    local ap, as = Frame.AbsolutePosition, Frame.AbsoluteSize
    return Mouse.X >= ap.X and Mouse.X <= ap.X + as.X
       and Mouse.Y >= ap.Y and Mouse.Y <= ap.Y + as.Y
end

function Library:AddToRegistry(Instance, Properties, IsHud)
    local Index = #Library.Registry + 1
    local Data = { Instance = Instance, Properties = Properties, Index = Index }
    table.insert(Library.Registry, Data)
    Library.RegistryMap[Instance] = Data
    if IsHud then table.insert(Library.HudRegistry, Data) end
end

function Library:RemoveFromRegistry(Instance)
    local Data = Library.RegistryMap[Instance]
    if not Data then return end
    for i = #Library.Registry, 1, -1 do
        if Library.Registry[i] == Data then table.remove(Library.Registry, i) end
    end
    for i = #Library.HudRegistry, 1, -1 do
        if Library.HudRegistry[i] == Data then table.remove(Library.HudRegistry, i) end
    end
    Library.RegistryMap[Instance] = nil
end

function Library:UpdateColorsUsingRegistry()
    for _, Object in next, Library.Registry do
        for Property, ColorIdx in next, Object.Properties do
            if type(ColorIdx) == "string" then
                Object.Instance[Property] = Library[ColorIdx]
            elseif type(ColorIdx) == "function" then
                Object.Instance[Property] = ColorIdx()
            end
        end
    end
end

function Library:UpdateDependencyBoxes()
    for _, D in next, Library.DependencyBoxes do D:Update() end
end

function Library:PlaySound(id, pitch)
    if not Library.Sounds.Enabled or not id or id == "" then return end
    local s = ns__cloneref(Instance.new("Sound"))
    s.SoundId = id
    s.Volume = Library.Sounds.Volume
    s.PlaybackSpeed = pitch or 1
    s.Parent = ScreenGui
    s:Play()
    task.delay(2, function() pcall(function() s:Destroy() end) end)
end

ScreenGui.DescendantRemoving:Connect(function(inst)
    if Library.RegistryMap[inst] then Library:RemoveFromRegistry(inst) end
end)

-- ============================================================
-- Base addons (AddColorPicker / AddKeyPicker)
-- ============================================================
local BaseAddons = {}
do
    local Funcs = {}

    function Funcs:AddColorPicker(Index, Info)
        local ToggleLabel = self.TextLabel
        assert(Info.Default, "AddColorPicker: Missing default value.")

        local ColorPicker = {
            Value = Info.Default,
            Transparency = Info.Transparency or 0,
            Type = "ColorPicker",
            Title = type(Info.Title) == "string" and Info.Title or "Color picker",
            Callback = Info.Callback or function() end,
        }

        function ColorPicker:SetHSVFromRGB(Color)
            local H, S, V = Color3.toHSV(Color)
            ColorPicker.Hue, ColorPicker.Saturation, ColorPicker.Vib = H, S, V
        end
        ColorPicker:SetHSVFromRGB(ColorPicker.Value)

        local DisplayFrame = Library:Create("Frame", {
            BackgroundColor3 = ColorPicker.Value,
            BorderColor3 = Library:GetDarkerColor(ColorPicker.Value),
            BorderMode = Enum.BorderMode.Inset,
            Size = UDim2.new(0, 14, 0, 14),
            ZIndex = 6, Parent = ToggleLabel,
        })

        local PickerFrameOuter = Library:Create("Frame", {
            Name = "Color",
            BackgroundColor3 = Color3.fromRGB(30, 30, 30),
            BorderColor3 = Library.Border,
            Position = UDim2.fromOffset(DisplayFrame.AbsolutePosition.X, DisplayFrame.AbsolutePosition.Y + 18),
            Size = UDim2.fromOffset(230, Info.Transparency and 271 or 253),
            Visible = false, ZIndex = 15, Parent = ScreenGui,
        })

        DisplayFrame:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
            PickerFrameOuter.Position = UDim2.fromOffset(DisplayFrame.AbsolutePosition.X, DisplayFrame.AbsolutePosition.Y + 18)
        end)

        local PickerFrameInner = Library:Create("Frame", {
            BackgroundColor3 = Library.SectionBG,
            BorderColor3 = Library.Outline,
            BorderMode = Enum.BorderMode.Inset,
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 16, Parent = PickerFrameOuter,
        })
        Library:AddToRegistry(PickerFrameInner, { BackgroundColor3 = "SectionBG", BorderColor3 = "Outline" })

        local Highlight = Library:Create("Frame", {
            BackgroundColor3 = Library.Accent,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 2),
            ZIndex = 17, Parent = PickerFrameInner,
        })
        Library:AddToRegistry(Highlight, { BackgroundColor3 = "Accent" })

        local SatVibMapOuter = Library:Create("Frame", {
            BorderColor3 = Library.Border,
            Position = UDim2.new(0, 4, 0, 25),
            Size = UDim2.new(0, 200, 0, 200),
            ZIndex = 17, Parent = PickerFrameInner,
        })
        local SatVibMapInner = Library:Create("Frame", {
            BackgroundColor3 = Library.SectionBG,
            BorderColor3 = Library.Outline,
            BorderMode = Enum.BorderMode.Inset,
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 18, Parent = SatVibMapOuter,
        })
        local SatVibMap = Library:Create("ImageLabel", {
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 18,
            Image = "rbxassetid://4155801252",
            Parent = SatVibMapInner,
        })
        local CursorOuter = Library:Create("ImageLabel", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Size = UDim2.new(0, 6, 0, 6),
            BackgroundTransparency = 1,
            Image = "http://www.roblox.com/asset/?id=9619665977",
            ImageColor3 = Color3.new(0, 0, 0),
            ZIndex = 19, Parent = SatVibMap,
        })
        local CursorInner = Library:Create("ImageLabel", {
            Size = UDim2.new(0, CursorOuter.Size.X.Offset - 2, 0, CursorOuter.Size.Y.Offset - 2),
            Position = UDim2.new(0, 1, 0, 1),
            BackgroundTransparency = 1,
            Image = "http://www.roblox.com/asset/?id=9619665977",
            ZIndex = 20, Parent = CursorOuter,
        })
        local HueSelectorOuter = Library:Create("Frame", {
            BorderColor3 = Library.Border,
            Position = UDim2.new(0, 208, 0, 25),
            Size = UDim2.new(0, 15, 0, 200),
            ZIndex = 17, Parent = PickerFrameInner,
        })
        local HueSelectorInner = Library:Create("Frame", {
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 18, Parent = HueSelectorOuter,
        })
        local HueCursor = Library:Create("Frame", {
            BackgroundColor3 = Color3.new(1, 1, 1),
            AnchorPoint = Vector2.new(0, 0.5),
            BorderColor3 = Color3.new(0, 0, 0),
            Size = UDim2.new(1, 0, 0, 1),
            ZIndex = 18, Parent = HueSelectorInner,
        })

        local SequenceTable = {}
        for H = 0, 1, 0.1 do
            table.insert(SequenceTable, ColorSequenceKeypoint.new(H, Color3.fromHSV(H, 1, 1)))
        end
        Library:Create("UIGradient", {
            Color = ColorSequence.new(SequenceTable),
            Rotation = 90, Parent = HueSelectorInner,
        })

        local HueBoxOuter = Library:Create("Frame", {
            BorderColor3 = Library.Border,
            Position = UDim2.fromOffset(4, 228),
            Size = UDim2.new(0.5, -6, 0, 20),
            ZIndex = 18, Parent = PickerFrameInner,
        })
        local HueBoxInner = Library:Create("Frame", {
            BackgroundColor3 = Library.ControlBG,
            BorderColor3 = Library.Outline,
            BorderMode = Enum.BorderMode.Inset,
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 18, Parent = HueBoxOuter,
        })
        local HueBox = Library:Create("TextBox", {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 5, 0, 0),
            Size = UDim2.new(1, -5, 1, 0),
            Font = Library.Font,
            PlaceholderColor3 = Library.FontMuted,
            PlaceholderText = "Hex color",
            Text = "#FFFFFF",
            TextColor3 = Library.FontColor,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 20, Parent = HueBoxInner,
        })
        Library:AddToRegistry(HueBoxInner, { BackgroundColor3 = "ControlBG", BorderColor3 = "Outline" })
        Library:AddToRegistry(HueBox, { TextColor3 = "FontColor" })

        local RGBBoxBase = Library:Create(HueBoxOuter:Clone(), {
            Position = UDim2.new(0.5, 2, 0, 228),
            Size = UDim2.new(0.5, -6, 0, 20),
            Parent = PickerFrameInner,
        })
        local RGBBox = Library:Create(RGBBoxBase.Frame:FindFirstChild("TextBox"), {
            Text = "255, 255, 255",
            PlaceholderText = "RGB color",
            TextColor3 = Library.FontColor,
        })

        local TransparencyBoxInner, TransparencyCursor
        if Info.Transparency then
            local TBOuter = Library:Create("Frame", {
                BorderColor3 = Library.Border,
                Position = UDim2.fromOffset(4, 251),
                Size = UDim2.new(1, -8, 0, 15),
                ZIndex = 19, Parent = PickerFrameInner,
            })
            TransparencyBoxInner = Library:Create("Frame", {
                BackgroundColor3 = ColorPicker.Value,
                BorderColor3 = Library.Outline,
                BorderMode = Enum.BorderMode.Inset,
                Size = UDim2.new(1, 0, 1, 0),
                ZIndex = 19, Parent = TBOuter,
            })
            Library:Create("ImageLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 1, 0),
                Image = "http://www.roblox.com/asset/?id=12978095818",
                ZIndex = 20, Parent = TransparencyBoxInner,
            })
            TransparencyCursor = Library:Create("Frame", {
                BackgroundColor3 = Color3.new(1, 1, 1),
                AnchorPoint = Vector2.new(0.5, 0),
                BorderColor3 = Color3.new(0, 0, 0),
                Size = UDim2.new(0, 1, 1, 0),
                ZIndex = 21, Parent = TransparencyBoxInner,
            })
        end

        Library:CreateLabel({
            Size = UDim2.new(1, 0, 0, 14),
            Position = UDim2.fromOffset(5, 5),
            TextXAlignment = Enum.TextXAlignment.Left,
            TextSize = 13,
            Text = ColorPicker.Title,
            ZIndex = 16, Parent = PickerFrameInner,
        })

        function ColorPicker:Display()
            ColorPicker.Value = Color3.fromHSV(ColorPicker.Hue, ColorPicker.Saturation, ColorPicker.Vib)
            SatVibMap.BackgroundColor3 = Color3.fromHSV(ColorPicker.Hue, 1, 1)
            DisplayFrame.BackgroundColor3 = ColorPicker.Value
            DisplayFrame.BackgroundTransparency = ColorPicker.Transparency
            DisplayFrame.BorderColor3 = Library:GetDarkerColor(ColorPicker.Value)
            if TransparencyBoxInner then
                TransparencyBoxInner.BackgroundColor3 = ColorPicker.Value
                TransparencyCursor.Position = UDim2.new(1 - ColorPicker.Transparency, 0, 0, 0)
            end
            CursorOuter.Position = UDim2.new(ColorPicker.Saturation, 0, 1 - ColorPicker.Vib, 0)
            HueCursor.Position = UDim2.new(0, 0, ColorPicker.Hue, 0)
            HueBox.Text = "#" .. ColorPicker.Value:ToHex()
            RGBBox.Text = table.concat({
                math.floor(ColorPicker.Value.R * 255),
                math.floor(ColorPicker.Value.G * 255),
                math.floor(ColorPicker.Value.B * 255)
            }, ", ")
            Library:SafeCallback(ColorPicker.Callback, ColorPicker.Value)
            Library:SafeCallback(ColorPicker.Changed, ColorPicker.Value)
        end

        function ColorPicker:OnChanged(Func) ColorPicker.Changed = Func; Func(ColorPicker.Value) end

        function ColorPicker:Show()
            for Frame in next, Library.OpenedFrames do
                if Frame.Name == "Color" then Frame.Visible = false; Library.OpenedFrames[Frame] = nil end
            end
            PickerFrameOuter.Visible = true
            Library.OpenedFrames[PickerFrameOuter] = true
        end
        function ColorPicker:Hide()
            PickerFrameOuter.Visible = false
            Library.OpenedFrames[PickerFrameOuter] = nil
        end

        function ColorPicker:SetValue(HSV, Transparency)
            ColorPicker.Transparency = Transparency or 0
            ColorPicker:SetHSVFromRGB(Color3.fromHSV(HSV[1], HSV[2], HSV[3]))
            ColorPicker:Display()
            Library:UpdateDependencyBoxes()
        end
        function ColorPicker:SetValueRGB(Color, Transparency)
            ColorPicker.Transparency = Transparency or 0
            ColorPicker:SetHSVFromRGB(Color)
            ColorPicker:Display()
            Library:UpdateDependencyBoxes()
        end

        SatVibMap.InputBegan:Connect(function(Input)
            if Input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
            while UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                local MinX, MaxX = SatVibMap.AbsolutePosition.X, SatVibMap.AbsolutePosition.X + SatVibMap.AbsoluteSize.X
                local MinY, MaxY = SatVibMap.AbsolutePosition.Y, SatVibMap.AbsolutePosition.Y + SatVibMap.AbsoluteSize.Y
                ColorPicker.Saturation = (math.clamp(Mouse.X, MinX, MaxX) - MinX) / (MaxX - MinX)
                ColorPicker.Vib = 1 - ((math.clamp(Mouse.Y, MinY, MaxY) - MinY) / (MaxY - MinY))
                ColorPicker:Display()
                RenderStepped:Wait()
            end
            Library:AttemptSave()
        end)

        HueSelectorInner.InputBegan:Connect(function(Input)
            if Input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
            while UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                local MinY, MaxY = HueSelectorInner.AbsolutePosition.Y, HueSelectorInner.AbsolutePosition.Y + HueSelectorInner.AbsoluteSize.Y
                ColorPicker.Hue = ((math.clamp(Mouse.Y, MinY, MaxY) - MinY) / (MaxY - MinY))
                ColorPicker:Display()
                RenderStepped:Wait()
            end
            Library:AttemptSave()
        end)

        DisplayFrame.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame() then
                if PickerFrameOuter.Visible then ColorPicker:Hide() else ColorPicker:Show() end
            end
        end)

        UserInputService.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                local ap, as = PickerFrameOuter.AbsolutePosition, PickerFrameOuter.AbsoluteSize
                if Mouse.X < ap.X or Mouse.X > ap.X + as.X or Mouse.Y < ap.Y - 21 or Mouse.Y > ap.Y + as.Y then
                    ColorPicker:Hide()
                end
            end
        end)

        Options[Index] = ColorPicker
        ColorPicker:Display()
        ColorPicker.DisplayFrame = DisplayFrame
        return ColorPicker
    end

    function Funcs:AddKeyPicker(Index, Info)
        local ParentObj = self
        local ToggleLabel = self.TextLabel
        local Container = self.Container
        assert(Info.Default, "AddKeyPicker: Missing default value.")

        local KeyPicker = {
            Value = Info.Default,
            Toggled = false,
            Mode = Info.Mode or "Toggle",
            Type = "KeyPicker",
            Callback = Info.Callback or function() end,
            ChangedCallback = Info.ChangedCallback or function() end,
            SyncToggleState = Info.SyncToggleState or false,
        }
        if KeyPicker.SyncToggleState then Info.Modes = {"Toggle"}; Info.Mode = "Toggle" end

        local PickOuter = Library:Create("Frame", {
            BackgroundColor3 = Library.Border,
            BorderColor3 = Library.Border,
            Size = UDim2.new(0, 30, 0, 14),
            ZIndex = 6, Parent = ToggleLabel,
        })
        local PickInner = Library:Create("Frame", {
            BackgroundColor3 = Library.ControlBG,
            BorderColor3 = Library.Outline,
            BorderMode = Enum.BorderMode.Inset,
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 7, Parent = PickOuter,
        })
        Library:AddToRegistry(PickInner, { BackgroundColor3 = "ControlBG", BorderColor3 = "Outline" })

        local DisplayLabel = Library:CreateLabel({
            Size = UDim2.new(1, 0, 1, 0),
            TextSize = 11,
            Text = Info.Default,
            ZIndex = 8, Parent = PickInner,
        })

        local ModeSelectOuter = Library:Create("Frame", {
            BorderColor3 = Library.Border,
            Position = UDim2.fromOffset(ToggleLabel.AbsolutePosition.X + ToggleLabel.AbsoluteSize.X + 4, ToggleLabel.AbsolutePosition.Y + 1),
            Size = UDim2.new(0, 60, 0, 45 + 2),
            Visible = false, ZIndex = 14, Parent = ScreenGui,
        })
        Library.ModeSelectOuters[ModeSelectOuter] = true

        ToggleLabel:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
            ModeSelectOuter.Position = UDim2.fromOffset(ToggleLabel.AbsolutePosition.X + ToggleLabel.AbsoluteSize.X + 4, ToggleLabel.AbsolutePosition.Y + 1)
        end)

        local ModeSelectInner = Library:Create("Frame", {
            BackgroundColor3 = Library.SectionBG,
            BorderColor3 = Library.Outline,
            BorderMode = Enum.BorderMode.Inset,
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 15, Parent = ModeSelectOuter,
        })
        Library:AddToRegistry(ModeSelectInner, { BackgroundColor3 = "SectionBG", BorderColor3 = "Outline" })
        Library:Create("UIListLayout", {
            FillDirection = Enum.FillDirection.Vertical,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = ModeSelectInner,
        })

        local ContainerLabel = Library:CreateLabel({
            TextXAlignment = Enum.TextXAlignment.Left,
            Size = UDim2.new(1, 0, 0, 18),
            TextSize = 12,
            Visible = false, ZIndex = 110, Parent = Library.KeybindContainer,
        }, true)

        local Modes = Info.Modes or {"Always", "Toggle", "Hold"}
        local ModeButtons = {}
        for _, Mode in next, Modes do
            local Button = {}
            local Label = Library:CreateLabel({
                Active = false,
                Size = UDim2.new(1, 0, 0, 15),
                TextSize = 12,
                Text = Mode,
                ZIndex = 16, Parent = ModeSelectInner,
            })
            function Button:Select()
                for _, B in next, ModeButtons do B:Deselect() end
                KeyPicker.Mode = Mode
                Label.TextColor3 = Library.Accent
                Library.RegistryMap[Label].Properties.TextColor3 = "Accent"
                ModeSelectOuter.Visible = false
            end
            function Button:Deselect()
                KeyPicker.Mode = nil
                Label.TextColor3 = Library.FontColor
                Library.RegistryMap[Label].Properties.TextColor3 = "FontColor"
            end
            Label.InputBegan:Connect(function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                    Button:Select(); Library:AttemptSave()
                end
            end)
            if Mode == KeyPicker.Mode then Button:Select() end
            ModeButtons[Mode] = Button
        end

        function KeyPicker:Update()
            if Info.NoUI then return end
            local State = KeyPicker:GetState()
            ContainerLabel.Text = string.format("[%s] %s (%s)", KeyPicker.Value, Info.Text, KeyPicker.Mode)
            ContainerLabel.Visible = true
            ContainerLabel.TextColor3 = State and Library.Accent or Library.FontColor
            Library.RegistryMap[ContainerLabel].Properties.TextColor3 = State and "Accent" or "FontColor"
            local YSize, XSize = 0, 0
            for _, Label in next, Library.KeybindContainer:GetChildren() do
                if Label:IsA("TextLabel") and Label.Visible then
                    YSize += 18
                    if Label.TextBounds.X > XSize then XSize = Label.TextBounds.X end
                end
            end
            Library.KeybindFrame.Size = UDim2.new(0, math.max(XSize + 10, 210), 0, YSize + 23)
        end

        function KeyPicker:GetState()
            if KeyPicker.Mode == "Always" then return true end
            if KeyPicker.Mode == "Hold" then
                if KeyPicker.Value == "None" then return false end
                if KeyPicker.Value == "MB2" then return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) end
                return UserInputService:IsKeyDown(Enum.KeyCode[KeyPicker.Value])
            end
            return KeyPicker.Toggled
        end

        function KeyPicker:SetValue(Data)
            if type(Data) ~= "table" then Data = {Data, KeyPicker.Mode or "Toggle"} end
            local Key = Data[1]
            if typeof(Key) ~= "string" or Key == "" then Key = Info.Default or "None" end
            local Mode = Data[2]
            if typeof(Mode) ~= "string" or not ModeButtons[Mode] then Mode = KeyPicker.Mode or "Toggle" end
            DisplayLabel.Text = Key
            KeyPicker.Value = Key
            ModeButtons[Mode]:Select()
            Library:SafeCallback(KeyPicker.Callback, Key)
            KeyPicker:Update()
            Library:UpdateDependencyBoxes()
        end

        function KeyPicker:OnClick(CB) KeyPicker.Clicked = CB end
        function KeyPicker:OnChanged(CB) KeyPicker.Changed = CB; CB(KeyPicker.Value) end

        if ParentObj.Addons then table.insert(ParentObj.Addons, KeyPicker) end

        function KeyPicker:DoClick()
            if ParentObj.Type == "Toggle" and KeyPicker.SyncToggleState then
                ParentObj:SetValue(not ParentObj.Value)
            end
            Library:SafeCallback(KeyPicker.Callback, KeyPicker.Toggled)
            Library:SafeCallback(KeyPicker.Clicked, KeyPicker.Toggled)
        end

        local Picking = false
        PickOuter.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame() then
                Picking = true
                DisplayLabel.Text = ""
                local Break, Text = false, ""
                task.spawn(function()
                    while not Break do
                        if Text == "..." then Text = "" end
                        Text = Text .. "."
                        DisplayLabel.Text = Text
                        task.wait(0.4)
                    end
                end)
                task.wait(0.2)
                local Event
                Event = UserInputService.InputBegan:Connect(function(Input)
                    local Key
                    if Input.UserInputType == Enum.UserInputType.Keyboard then Key = Input.KeyCode.Name
                    elseif Input.UserInputType == Enum.UserInputType.MouseButton2 then Key = Input.UserInputType.Name
                    elseif Input.UserInputType == Enum.UserInputType.MouseButton1 then Key = "None" end
                    Break = true; Picking = false
                    DisplayLabel.Text = Key
                    KeyPicker.Value = Key
                    Library:SafeCallback(KeyPicker.Callback, Key)
                    KeyPicker:Update()
                    Library:SafeCallback(KeyPicker.ChangedCallback, Key)
                    Library:SafeCallback(KeyPicker.Changed, Key)
                    Library:AttemptSave()
                    Event:Disconnect()
                end)
            elseif Input.UserInputType == Enum.UserInputType.MouseButton2 and not Library:MouseIsOverOpenedFrame() and not Picking then
                ModeSelectOuter.Visible = true
            end
        end)

        local InputBeganConnection = UserInputService.InputBegan:Connect(function(Input, Processed)
            if Processed then return end
            if not Picking then
                if KeyPicker.Mode == "Toggle" and Input.UserInputType == Enum.UserInputType.Keyboard and Input.KeyCode.Name == KeyPicker.Value then
                    KeyPicker.Toggled = not KeyPicker.Toggled
                    KeyPicker:DoClick()
                elseif KeyPicker.Mode == "Hold" then
                    if (Input.UserInputType == Enum.UserInputType.Keyboard and Input.KeyCode.Name == KeyPicker.Value)
                    or (KeyPicker.Value == "MB2" and Input.UserInputType == Enum.UserInputType.MouseButton2) then
                        Library:SafeCallback(KeyPicker.Callback, true)
                    end
                end
                KeyPicker:Update()
            end
            if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                local ap, as = ModeSelectOuter.AbsolutePosition, ModeSelectOuter.AbsoluteSize
                if Mouse.X < ap.X or Mouse.X > ap.X + as.X or Mouse.Y < ap.Y - 21 or Mouse.Y > ap.Y + as.Y then
                    ModeSelectOuter.Visible = false
                end
            end
        end)

        local InputEndedConnection = UserInputService.InputEnded:Connect(function(Input, Processed)
            if Processed then return end
            if not Picking then
                if KeyPicker.Mode == "Hold"
                and ((Input.UserInputType == Enum.UserInputType.Keyboard and Input.KeyCode.Name == KeyPicker.Value)
                or (KeyPicker.Value == "MB2" and Input.UserInputType == Enum.UserInputType.MouseButton2)) then
                    Library:SafeCallback(KeyPicker.Callback, false)
                end
                KeyPicker:Update()
            end
        end)

        function KeyPicker:Destroy()
            InputBeganConnection:Disconnect()
            InputEndedConnection:Disconnect()
            Library.ModeSelectOuters[ModeSelectOuter] = nil
            ModeSelectOuter:Destroy()
        end
        PickOuter.Destroying:Connect(function() KeyPicker:Destroy() end)

        KeyPicker:Update()
        Options[Index] = KeyPicker
        return KeyPicker
    end

    BaseAddons.__index = Funcs
    BaseAddons.__namecall = function(_, Key, ...) return Funcs[Key](...) end
end

-- ============================================================
-- Groupbox addons
-- ============================================================
local BaseGroupbox = {}
do
    local Funcs = {}

    function Funcs:AddBlank(Size)
        Library:Create("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, Size),
            ZIndex = 1, Parent = self.Container,
        })
    end

    function Funcs:AddLabel(Text, DoesWrap, ToolTip)
        local Label = {}
        local Groupbox = self
        local Container = Groupbox.Container
        local TextLabel = Library:CreateLabel({
            Size = UDim2.new(1, -4, 0, 15),
            TextSize = Library.FontSize,
            Text = Text,
            TextWrapped = DoesWrap or false,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 5, Parent = Container,
        })
        if DoesWrap then
            TextLabel.Size = UDim2.new(1, -4, 0, select(2, Library:GetTextBounds(Text, Library.Font, Library.FontSize, Vector2.new(TextLabel.AbsoluteSize.X, math.huge))))
        else
            Library:Create("UIListLayout", {
                Padding = UDim.new(0, 4),
                FillDirection = Enum.FillDirection.Horizontal,
                HorizontalAlignment = Enum.HorizontalAlignment.Right,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Parent = TextLabel,
            })
        end
        Label.TextLabel = TextLabel
        Label.Container = Container
        function Label:SetText(Text)
            TextLabel.Text = Text
            if DoesWrap then
                TextLabel.Size = UDim2.new(1, -4, 0, select(2, Library:GetTextBounds(Text, Library.Font, Library.FontSize, Vector2.new(TextLabel.AbsoluteSize.X, math.huge))))
            end
            Groupbox:Resize()
        end
        if not DoesWrap then setmetatable(Label, BaseAddons) end
        Groupbox:AddBlank(5)
        Groupbox:Resize()
        return Label
    end

    function Funcs:AddButton(...)
        local Button = {}
        local function ProcessButtonParams(_, Obj, ...)
            local Props = select(1, ...)
            if type(Props) == "table" then
                Obj.Text = Props.Text
                Obj.Func = Props.Func
                Obj.DoubleClick = Props.DoubleClick
                Obj.Tooltip = Props.Tooltip
            else
                Obj.Text = select(1, ...)
                Obj.Func = select(2, ...)
            end
            assert(type(Obj.Func) == "function", "AddButton: `Func` callback is missing.")
        end
        ProcessButtonParams("Button", Button, ...)

        local Groupbox = self
        local Container = Groupbox.Container

        local function CreateBaseButton(B)
            local Outer = Library:Create("Frame", {
                BackgroundColor3 = Library.Border,
                BorderColor3 = Library.Border,
                Size = UDim2.new(1, -4, 0, 20),
                ZIndex = 5,
            })
            local Inner = Library:Create("Frame", {
                BackgroundColor3 = Library.ControlBG,
                BorderColor3 = Library.Outline,
                BorderMode = Enum.BorderMode.Inset,
                Size = UDim2.new(1, 0, 1, 0),
                ZIndex = 6, Parent = Outer,
            })
            local Label = Library:CreateLabel({
                Size = UDim2.new(1, 0, 1, 0),
                TextSize = Library.FontSize,
                Text = B.Text,
                ZIndex = 6, Parent = Inner,
            })
            Library:AddToRegistry(Outer, { BorderColor3 = "Border" })
            Library:AddToRegistry(Inner, { BackgroundColor3 = "ControlBG", BorderColor3 = "Outline" })
            Outer.MouseEnter:Connect(function() Inner.BackgroundColor3 = Library.ControlHover end)
            Outer.MouseLeave:Connect(function() Inner.BackgroundColor3 = Library.ControlBG end)
            return Outer, Inner, Label
        end

        local function InitEvents(B)
            B.Outer.InputBegan:Connect(function(Input)
                if Input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
                if Library:MouseIsOverOpenedFrame() then return end
                Library:PlaySound(Library.Sounds.Click)
                Library:SafeCallback(B.Func)
            end)
        end

        Button.Outer, Button.Inner, Button.Label = CreateBaseButton(Button)
        Button.Outer.Parent = Container
        InitEvents(Button)

        function Button:AddTooltip(tip) if type(tip) == "string" then Library:AddToolTip(tip, self.Outer) end; return self end
        function Button:AddButton(...)
            local SubButton = {}
            ProcessButtonParams("SubButton", SubButton, ...)
            self.Outer.Size = UDim2.new(0.5, -2, 0, 20)
            SubButton.Outer, SubButton.Inner, SubButton.Label = CreateBaseButton(SubButton)
            SubButton.Outer.Position = UDim2.new(1, 3, 0, 0)
            SubButton.Outer.Size = UDim2.fromOffset(self.Outer.AbsoluteSize.X - 2, self.Outer.AbsoluteSize.Y)
            SubButton.Outer.Parent = self.Outer
            InitEvents(SubButton)
            return SubButton
        end

        Groupbox:AddBlank(5)
        Groupbox:Resize()
        return Button
    end

    function Funcs:AddDivider()
        local Groupbox = self
        Groupbox:AddBlank(2)
        local D = Library:Create("Frame", {
            BackgroundColor3 = Library.Divider,
            BorderSizePixel = 0,
            Size = UDim2.new(1, -4, 0, 1),
            ZIndex = 5, Parent = Groupbox.Container,
        })
        Library:AddToRegistry(D, { BackgroundColor3 = "Divider" })
        Groupbox:AddBlank(9)
        Groupbox:Resize()
    end

    function Funcs:AddInput(Index, Info)
        assert(Info.Text, "AddInput: Missing `Text` string.")
        local Textbox = {
            Value = Info.Default or "",
            Numeric = Info.Numeric or false,
            Finished = Info.Finished or false,
            Type = "Input",
            Callback = Info.Callback or function() end,
        }
        local Groupbox = self
        local Container = Groupbox.Container

        Library:CreateLabel({
            Size = UDim2.new(1, 0, 0, 13),
            TextSize = 12,
            Text = Info.Text,
            TextColor3 = Library.FontMuted,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 5, Parent = Container,
        })
        Groupbox:AddBlank(1)

        local Outer = Library:Create("Frame", {
            BackgroundColor3 = Library.Border,
            BorderColor3 = Library.Border,
            Size = UDim2.new(1, -4, 0, 20),
            ZIndex = 5, Parent = Container,
        })
        local Inner = Library:Create("Frame", {
            BackgroundColor3 = Library.ControlBG,
            BorderColor3 = Library.Outline,
            BorderMode = Enum.BorderMode.Inset,
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 6, Parent = Outer,
        })
        Library:AddToRegistry(Outer, { BorderColor3 = "Border" })
        Library:AddToRegistry(Inner, { BackgroundColor3 = "ControlBG", BorderColor3 = "Outline" })

        local Box = Library:Create("TextBox", {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 5, 0, 0),
            Size = UDim2.new(1, -10, 1, 0),
            Font = Library.Font,
            PlaceholderColor3 = Library.FontMuted,
            PlaceholderText = Info.Placeholder or "",
            Text = Info.Default or "",
            TextColor3 = Library.FontColor,
            TextSize = Library.FontSize,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 7, Parent = Inner,
        })
        Library:AddToRegistry(Box, { TextColor3 = "FontColor" })

        function Textbox:SetValue(Text)
            if Info.MaxLength and #Text > Info.MaxLength then Text = Text:sub(1, Info.MaxLength) end
            if Textbox.Numeric and not tonumber(Text) and Text:len() > 0 then Text = Textbox.Value end
            Textbox.Value = Text
            Box.Text = Text
            Library:SafeCallback(Textbox.Callback, Textbox.Value)
            Library:SafeCallback(Textbox.Changed, Textbox.Value)
        end

        if Textbox.Finished then
            Box.FocusLost:Connect(function(Enter) if Enter then Textbox:SetValue(Box.Text); Library:AttemptSave() end end)
        else
            Box:GetPropertyChangedSignal("Text"):Connect(function() Textbox:SetValue(Box.Text); Library:AttemptSave() end)
        end

        function Textbox:OnChanged(Func) Textbox.Changed = Func; Func(Textbox.Value) end
        Groupbox:AddBlank(5)
        Groupbox:Resize()
        Options[Index] = Textbox
        return Textbox
    end

    -- ========================================================
    -- Toggle  — gamesense-style small square checkbox
    -- ========================================================
    function Funcs:AddToggle(Index, Info)
        assert(Info.Text, "AddToggle: Missing `Text` string.")
        local Toggle = {
            Value = Info.Default or false,
            Type = "Toggle",
            Callback = Info.Callback or function() end,
            Addons = {},
            Risky = Info.Risky,
        }
        local Groupbox = self
        local Container = Groupbox.Container

        local Row = Library:Create("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -4, 0, 16),
            ZIndex = 5, Parent = Container,
        })

        local ToggleOuter = Library:Create("Frame", {
            BackgroundColor3 = Library.Border,
            BorderColor3 = Library.Border,
            Position = UDim2.new(0, 0, 0, 1),
            Size = UDim2.new(0, 13, 0, 13),
            ZIndex = 6, Parent = Row,
        })
        Library:AddToRegistry(ToggleOuter, { BorderColor3 = "Border" })

        local ToggleInner = Library:Create("Frame", {
            BackgroundColor3 = Library.ControlBG,
            BorderColor3 = Library.Outline,
            BorderMode = Enum.BorderMode.Inset,
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 7, Parent = ToggleOuter,
        })
        Library:AddToRegistry(ToggleInner, { BackgroundColor3 = "ControlBG", BorderColor3 = "Outline" })

        -- tick drawn as a small image so it looks like gamesense's checkmark
        local Check = Library:Create("ImageLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            Image = "rbxassetid://3926305904",
            ImageRectOffset = Vector2.new(4, 4),
            ImageRectSize = Vector2.new(36, 36),
            ImageColor3 = Library.FontColor,
            Visible = false,
            ZIndex = 8, Parent = ToggleInner,
        })
        Library:AddToRegistry(Check, { ImageColor3 = "FontColor" })

        local ToggleLabel = Library:CreateLabel({
            Size = UDim2.new(1, -22, 1, 0),
            Position = UDim2.new(0, 20, 0, 0),
            TextSize = Library.FontSize,
            Text = Info.Text,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 6, Parent = Row,
        })

        Library:Create("UIListLayout", {
            Padding = UDim.new(0, 4),
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = ToggleLabel,
        })

        local ToggleRegion = Library:Create("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 9, Parent = Row,
        })

        Row.MouseEnter:Connect(function()
            ToggleInner.BackgroundColor3 = Toggle.Value and Library.AccentHover or Library.ControlHover
        end)
        Row.MouseLeave:Connect(function()
            ToggleInner.BackgroundColor3 = Toggle.Value and Library.Accent or Library.ControlBG
        end)

        function Toggle:UpdateColors() Toggle:Display() end

        function Toggle:Display()
            local on = Toggle.Value
            ToggleInner.BackgroundColor3 = on and Library.Accent or Library.ControlBG
            ToggleInner.BorderColor3   = on and Library.AccentDark or Library.Outline
            Library.RegistryMap[ToggleInner].Properties.BackgroundColor3 = on and "Accent" or "ControlBG"
            Library.RegistryMap[ToggleInner].Properties.BorderColor3     = on and "AccentDark" or "Outline"
            Check.Visible = on
            if on then Check.ImageColor3 = Color3.fromRGB(20, 20, 20) else Check.ImageColor3 = Library.FontColor end
        end

        function Toggle:OnChanged(Func) Toggle.Changed = Func; Func(Toggle.Value) end

        function Toggle:SetValue(Bool)
            Bool = (not not Bool)
            Toggle.Value = Bool
            Toggle:Display()
            for _, Addon in next, Toggle.Addons do
                if Addon.Type == "KeyPicker" and Addon.SyncToggleState then
                    Addon.Toggled = Bool; Addon:Update()
                end
            end
            Library:SafeCallback(Toggle.Callback, Toggle.Value)
            Library:SafeCallback(Toggle.Changed, Toggle.Value)
            Library:UpdateDependencyBoxes()
        end

        ToggleRegion.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame() then
                Library:PlaySound(Library.Sounds.Click)
                Toggle:SetValue(not Toggle.Value)
                Library:AttemptSave()
            end
        end)

        if Toggle.Risky then
            Library:RemoveFromRegistry(ToggleLabel)
            ToggleLabel.TextColor3 = Library.RiskColor
            Library:AddToRegistry(ToggleLabel, { TextColor3 = "RiskColor" })
        end

        Toggle:Display()
        Groupbox:AddBlank(Info.BlankSize or 4)
        Groupbox:Resize()

        Toggle.TextLabel = ToggleLabel
        Toggle.Container = Container
        setmetatable(Toggle, BaseAddons)

        Toggles[Index] = Toggle
        Library:UpdateDependencyBoxes()
        return Toggle
    end

    -- ========================================================
    -- Slider  — gamesense-style thick bar with value overlay
    -- ========================================================
    function Funcs:AddSlider(Index, Info)
        assert(Info.Default, "AddSlider: Missing default value.")
        assert(Info.Text, "AddSlider: Missing slider Text.")
        assert(Info.Min, "AddSlider: Missing minimum value.")
        assert(Info.Max, "AddSlider: Missing maximum value.")
        assert(Info.Rounding, "AddSlider: Missing rounding value.")

        local Slider = {
            Value = Info.Default,
            Min = Info.Min, Max = Info.Max,
            Rounding = Info.Rounding,
            MaxSize = 232,
            Type = "Slider",
            Callback = Info.Callback or function() end,
        }
        local Groupbox = self
        local Container = Groupbox.Container

        if not Info.Compact then
            Library:CreateLabel({
                Size = UDim2.new(1, 0, 0, 13),
                TextSize = 12,
                Text = Info.Text,
                TextColor3 = Library.FontMuted,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Bottom,
                ZIndex = 5, Parent = Container,
            })
            Groupbox:AddBlank(2)
        end

        local SliderOuter = Library:Create("Frame", {
            BackgroundColor3 = Library.Border,
            BorderColor3 = Library.Border,
            Size = UDim2.new(1, -4, 0, 14),
            ZIndex = 5, Parent = Container,
        })
        Library:AddToRegistry(SliderOuter, { BorderColor3 = "Border" })

        local SliderInner = Library:Create("Frame", {
            BackgroundColor3 = Library.ControlBG,
            BorderColor3 = Library.Outline,
            BorderMode = Enum.BorderMode.Inset,
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 6, Parent = SliderOuter,
        })
        Library:AddToRegistry(SliderInner, { BackgroundColor3 = "ControlBG", BorderColor3 = "Outline" })

        local Fill = Library:Create("Frame", {
            BackgroundColor3 = Library.Accent,
            BorderSizePixel = 0,
            Size = UDim2.new(0, 0, 1, 0),
            ZIndex = 7, Parent = SliderInner,
        })
        Library:AddToRegistry(Fill, { BackgroundColor3 = "Accent" })

        local DisplayLabel = Library:CreateLabel({
            Size = UDim2.new(1, 0, 1, 0),
            TextSize = 12,
            Text = "0",
            TextColor3 = Color3.fromRGB(20, 20, 20),
            ZIndex = 9, Parent = SliderInner,
        })

        function Slider:UpdateColors()
            Fill.BackgroundColor3 = Library.Accent
        end

        function Slider:Display()
            local Suffix = Info.Suffix or ""
            if Info.HideMax then
                DisplayLabel.Text = string.format("%s", Slider.Value .. Suffix)
            else
                DisplayLabel.Text = string.format("%s/%s", Slider.Value .. Suffix, Slider.Max .. Suffix)
            end
            local X = math.ceil(Library:MapValue(Slider.Value, Slider.Min, Slider.Max, 0, Slider.MaxSize))
            Fill.Size = UDim2.new(0, X, 1, 0)
        end

        function Slider:OnChanged(Func) Slider.Changed = Func; Func(Slider.Value) end

        local function Round(Value)
            if Slider.Rounding == 0 then return math.floor(Value) end
            return tonumber(string.format("%." .. Slider.Rounding .. "f", Value))
        end

        function Slider:GetValueFromXOffset(X)
            return Round(Library:MapValue(X, 0, Slider.MaxSize, Slider.Min, Slider.Max))
        end

        function Slider:SetValue(String)
            local Number = tonumber(String)
            if not Number then return end
            Number = math.clamp(Number, Slider.Min, Slider.Max)
            Slider.Value = Number
            Slider:Display()
            Library:SafeCallback(Slider.Callback, Slider.Value)
            Library:SafeCallback(Slider.Changed, Slider.Value)
            Library:UpdateDependencyBoxes()
        end

        SliderInner.InputBegan:Connect(function(Input)
            if Input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
            if Library:MouseIsOverOpenedFrame() then return end
            local MousePosition = Mouse.X
            local gPos = Fill.Size.X.Offset
            local Diff = MousePosition - (Fill.AbsolutePosition.X + gPos)
            while UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                local nValue = Slider:GetValueFromXOffset(math.clamp(gPos + (Mouse.X - MousePosition) + Diff, 0, Slider.MaxSize))
                local OldValue = Slider.Value
                Slider.Value = nValue
                Slider:Display()
                if nValue ~= OldValue then
                    Library:SafeCallback(Slider.Callback, Slider.Value)
                    Library:SafeCallback(Slider.Changed, Slider.Value)
                end
                RenderStepped:Wait()
            end
            Library:AttemptSave()
        end)

        Slider:Display()
        Groupbox:AddBlank(Info.BlankSize or 5)
        Groupbox:Resize()
        Options[Index] = Slider
        return Slider
    end

    -- ========================================================
    -- Dropdown  — gamesense-style compact with chevron
    -- ========================================================
    function Funcs:AddDropdown(Index, Info)
        if Info.SpecialType == "Player" then Info.Values = GetPlayersString(); Info.AllowNull = true
        elseif Info.SpecialType == "Team" then Info.Values = GetTeamsString(); Info.AllowNull = true end

        assert(Info.Values, "AddDropdown: Missing dropdown value list.")
        assert(Info.AllowNull or Info.Default, "AddDropdown: Missing default value. Pass `AllowNull` as true if intentional.")
        if not Info.Text then Info.Compact = true end

        local Dropdown = {
            Values = Info.Values,
            Value = Info.Multi and {},
            Multi = Info.Multi,
            Type = "Dropdown",
            SpecialType = Info.SpecialType,
            Callback = Info.Callback or function() end,
        }
        local Groupbox = self
        local Container = Groupbox.Container

        if not Info.Compact then
            Library:CreateLabel({
                Size = UDim2.new(1, 0, 0, 13),
                TextSize = 12,
                Text = Info.Text,
                TextColor3 = Library.FontMuted,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Bottom,
                ZIndex = 5, Parent = Container,
            })
            Groupbox:AddBlank(2)
        end

        local Outer = Library:Create("Frame", {
            BackgroundColor3 = Library.Border,
            BorderColor3 = Library.Border,
            Size = UDim2.new(1, -4, 0, 20),
            ZIndex = 5, Parent = Container,
        })
        Library:AddToRegistry(Outer, { BorderColor3 = "Border" })

        local Inner = Library:Create("Frame", {
            BackgroundColor3 = Library.ControlBG,
            BorderColor3 = Library.Outline,
            BorderMode = Enum.BorderMode.Inset,
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 6, Parent = Outer,
        })
        Library:AddToRegistry(Inner, { BackgroundColor3 = "ControlBG", BorderColor3 = "Outline" })

        local Chevron = Library:Create("ImageLabel", {
            AnchorPoint = Vector2.new(0, 0.5),
            BackgroundTransparency = 1,
            Position = UDim2.new(1, -14, 0.5, 0),
            Size = UDim2.new(0, 8, 0, 8),
            Image = "rbxassetid://6282522798",
            ImageColor3 = Library.FontMuted,
            ZIndex = 8, Parent = Inner,
        })
        Library:AddToRegistry(Chevron, { ImageColor3 = "FontMuted" })

        local ItemList = Library:CreateLabel({
            Position = UDim2.new(0, 6, 0, 0),
            Size = UDim2.new(1, -20, 1, 0),
            TextSize = Library.FontSize,
            Text = "--",
            TextXAlignment = Enum.TextXAlignment.Left,
            TextWrapped = true,
            ZIndex = 7, Parent = Inner,
        })

        local MAX_ITEMS = 8
        local ListOuter = Library:Create("Frame", {
            BackgroundColor3 = Library.Border,
            BorderColor3 = Library.Border,
            ZIndex = 20,
            Visible = false,
            Parent = ScreenGui,
        })

        local function RecalcPos()
            ListOuter.Position = UDim2.fromOffset(Outer.AbsolutePosition.X, Outer.AbsolutePosition.Y + Outer.Size.Y.Offset + 1)
        end
        local function RecalcSize(Y)
            ListOuter.Size = UDim2.fromOffset(Outer.AbsoluteSize.X, Y or (MAX_ITEMS * 20 + 2))
        end
        RecalcPos(); RecalcSize()
        Outer:GetPropertyChangedSignal("AbsolutePosition"):Connect(RecalcPos)

        local ListInner = Library:Create("Frame", {
            BackgroundColor3 = Library.SectionBG,
            BorderColor3 = Library.Outline,
            BorderMode = Enum.BorderMode.Inset,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 21, Parent = ListOuter,
        })
        Library:AddToRegistry(ListInner, { BackgroundColor3 = "SectionBG", BorderColor3 = "Outline" })

        local Scrolling = Library:Create("ScrollingFrame", {
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 21, Parent = ListInner,
            TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
            BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = Library.Accent,
        })
        Library:AddToRegistry(Scrolling, { ScrollBarImageColor3 = "Accent" })
        Library:Create("UIListLayout", {
            Padding = UDim.new(0, 0),
            FillDirection = Enum.FillDirection.Vertical,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = Scrolling,
        })

        function Dropdown:Display()
            local Str = ""
            if Info.Multi then
                for Value in next, Dropdown.Values do
                    if Dropdown.Value[Value] then Str = Str .. Value .. ", " end
                end
                Str = Str:sub(1, #Str - 2)
            else
                Str = Dropdown.Value or ""
            end
            ItemList.Text = (Str == "" and "--" or Str)
        end

        function Dropdown:GetActiveValues()
            if Info.Multi then
                local T = {}
                for V in next, Dropdown.Value do table.insert(T, V) end
                return T
            end
            return Dropdown.Value and 1 or 0
        end

        function Dropdown:BuildDropdownList()
            local Buttons = {}
            for _, El in next, Scrolling:GetChildren() do
                if not El:IsA("UIListLayout") then El:Destroy() end
            end
            local Count = 0
            for _, Value in next, Dropdown.Values do
                local Table = {}
                Count += 1
                local Button = Library:Create("Frame", {
                    BackgroundColor3 = Library.SectionBG,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, -1, 0, 20),
                    ZIndex = 23, Active = true, Parent = Scrolling,
                })
                Library:AddToRegistry(Button, { BackgroundColor3 = "SectionBG" })

                local ButtonLabel = Library:CreateLabel({
                    Active = false,
                    Size = UDim2.new(1, -6, 1, 0),
                    Position = UDim2.new(0, 6, 0, 0),
                    TextSize = Library.FontSize,
                    Text = Value,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 25, Parent = Button,
                })

                Button.MouseEnter:Connect(function() Button.BackgroundColor3 = Library.ControlHover end)
                Button.MouseLeave:Connect(function() Button.BackgroundColor3 = Library.SectionBG end)

                local Selected
                if Info.Multi then Selected = Dropdown.Value[Value] else Selected = Dropdown.Value == Value end

                function Table:UpdateButton()
                    if Info.Multi then Selected = Dropdown.Value[Value] else Selected = Dropdown.Value == Value end
                    ButtonLabel.TextColor3 = Selected and Library.Accent or Library.FontColor
                    Library.RegistryMap[ButtonLabel].Properties.TextColor3 = Selected and "Accent" or "FontColor"
                end

                ButtonLabel.InputBegan:Connect(function(Input)
                    if Input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
                    local Try = not Selected
                    if Dropdown:GetActiveValues() ~= 1 or Try or Info.AllowNull then
                        if Info.Multi then
                            Selected = Try
                            if Selected then Dropdown.Value[Value] = true else Dropdown.Value[Value] = nil end
                        else
                            Selected = Try
                            if Selected then Dropdown.Value = Value else Dropdown.Value = nil end
                            for _, Other in next, Buttons do Other:UpdateButton() end
                        end
                        Table:UpdateButton()
                        Dropdown:Display()
                        Library:SafeCallback(Dropdown.Callback, Dropdown.Value)
                        Library:SafeCallback(Dropdown.Changed, Dropdown.Value)
                        Library:AttemptSave()
                        Library:UpdateDependencyBoxes()
                    end
                end)

                Table:UpdateButton()
                Dropdown:Display()
                Buttons[Button] = Table
            end
            Scrolling.CanvasSize = UDim2.fromOffset(0, (Count * 20) + 1)
            RecalcSize(math.clamp(Count * 20, 0, MAX_ITEMS * 20) + 1)
        end

        function Dropdown:SetValues(NewValues)
            if NewValues then Dropdown.Values = NewValues end
            Dropdown:BuildDropdownList()
        end
        function Dropdown:OpenDropdown()
            ListOuter.Visible = true
            Library.OpenedFrames[ListOuter] = true
            Chevron.Rotation = 180
        end
        function Dropdown:CloseDropdown()
            ListOuter.Visible = false
            Library.OpenedFrames[ListOuter] = nil
            Chevron.Rotation = 0
        end
        function Dropdown:OnChanged(Func) Dropdown.Changed = Func; Func(Dropdown.Value) end

        function Dropdown:SetValue(Value)
            if Dropdown.Multi then
                local nTable = {}
                for Index in next, Value do
                    if table.find(Dropdown.Values, Index) then nTable[Index] = true end
                end
                Dropdown.Value = nTable
            else
                if not Value then Dropdown.Value = nil
                elseif table.find(Dropdown.Values, Value) then Dropdown.Value = Value end
            end
            Dropdown:BuildDropdownList()
            Library:SafeCallback(Dropdown.Callback, Dropdown.Value)
            Library:SafeCallback(Dropdown.Changed, Dropdown.Value)
            Library:UpdateDependencyBoxes()
        end

        Outer.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame() then
                if ListOuter.Visible then Dropdown:CloseDropdown() else Dropdown:OpenDropdown() end
            end
        end)

        UserInputService.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                local ap, as = ListOuter.AbsolutePosition, ListOuter.AbsoluteSize
                if Mouse.X < ap.X or Mouse.X > ap.X + as.X or Mouse.Y < ap.Y - 21 or Mouse.Y > ap.Y + as.Y then
                    Dropdown:CloseDropdown()
                end
            end
        end)

        Dropdown:BuildDropdownList()
        Dropdown:Display()

        local Defaults = {}
        if type(Info.Default) == "string" then
            local Idx = table.find(Dropdown.Values, Info.Default)
            if Idx then table.insert(Defaults, Idx) end
        elseif type(Info.Default) == "table" then
            for Idx in next, Info.Default do table.insert(Defaults, Idx) end
        elseif type(Info.Default) == "number" and Dropdown.Values[Info.Default] ~= nil then
            table.insert(Defaults, Info.Default)
        end
        for Idx in next, Defaults do
            if Info.Multi then Dropdown.Value[Dropdown.Values[Idx]] = true
            else Dropdown.Value = Dropdown.Values[Idx]; break end
        end
        Dropdown:BuildDropdownList()
        Dropdown:Display()

        Groupbox:AddBlank(Info.BlankSize or 4)
        Groupbox:Resize()
        Library:UpdateDependencyBoxes()
        Options[Index] = Dropdown
        return Dropdown
    end

    function Funcs:AddPrioritySelector(Index, Info)
        -- (unchanged from original, kept for compatibility)
        assert(type(Info) == "table")
        assert(type(Info.Default) == "table")
        local Groupbox = self
        local Container = Groupbox.Container
        local ItemHeight, ItemGap = 20, 2
        local RowH = ItemHeight + ItemGap
        local TotalItems = #Info.Default
        local ListH = ItemHeight * TotalItems + ItemGap * math.max(0, TotalItems - 1)
        local TitleH = (Info.Text and Info.Text ~= "") and 15 or 0
        local WrapperH = TitleH + ListH
        local Items = {}
        local OrderedList = {}
        for i, v in ipairs(Info.Default) do OrderedList[i] = v end
        local PrioSelector = {
            Type = "PrioritySelector",
            Value = OrderedList,
            Callback = Info.Callback or function() end,
        }
        local Wrapper = Library:Create("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -4, 0, WrapperH),
            ZIndex = 5, Parent = Container,
        })
        if TitleH > 0 then
            Library:CreateLabel({
                Size = UDim2.new(1, 0, 0, TitleH - 1),
                TextSize = 13,
                Text = Info.Text,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 6, Parent = Wrapper,
            })
        end
        local ListFrame = Library:Create("Frame", {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 0, 0, TitleH),
            Size = UDim2.new(1, 0, 0, ListH),
            ZIndex = 5, Parent = Wrapper,
        })
        local function GetSlotY(i) return (i - 1) * RowH end
        local function SnapAll()
            for i, frm in ipairs(Items) do frm.Position = UDim2.new(0, 0, 0, GetSlotY(i)) end
        end
        local function FireCB()
            local Order = {}
            for i, f in ipairs(Items) do Order[i] = f.Name end
            OrderedList = Order
            PrioSelector.Value = Order
            Library:SafeCallback(PrioSelector.Callback, Order)
        end
        local Drag = { Active = false }
        local function MakeItem(Text, Index)
            local ItemFrame = Library:Create("Frame", {
                Name = Text,
                BackgroundColor3 = Library.ControlBG,
                BorderColor3 = Library.Outline,
                Position = UDim2.new(0, 0, 0, GetSlotY(Index)),
                Size = UDim2.new(1, 0, 0, ItemHeight),
                ZIndex = 6, Parent = ListFrame,
            })
            Library:AddToRegistry(ItemFrame, { BackgroundColor3 = "ControlBG", BorderColor3 = "Outline" })
            Library:CreateLabel({
                Name = "RankLabel", Size = UDim2.new(0, 16, 1, 0), Position = UDim2.new(0, 2, 0, 0),
                TextSize = 12, Text = tostring(Index) .. ".", ZIndex = 7, Parent = ItemFrame,
            })
            Library:CreateLabel({
                Size = UDim2.new(1, -30, 1, 0), Position = UDim2.new(0, 19, 0, 0),
                TextSize = 13, Text = Text, TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 7, Parent = ItemFrame,
            })
            ItemFrame.InputBegan:Connect(function(Input)
                if Input.UserInputType ~= Enum.UserInputType.MouseButton1 or Drag.Active then return end
                local selfIndex = table.find(Items, ItemFrame)
                if not selfIndex then return end
                Drag.Active = true
                Drag.StartMouseY = Mouse.Y
                Drag.StartSlotY = GetSlotY(selfIndex)
                local Move, EndC
                Move = UserInputService.InputChanged:Connect(function(Input)
                    if Input.UserInputType ~= Enum.UserInputType.MouseMovement then return end
                    local cy = math.clamp(Drag.StartSlotY + (Mouse.Y - Drag.StartMouseY), 0, ListH - ItemHeight)
                    ItemFrame.Position = UDim2.new(0, 0, 0, cy)
                    local Centre = cy + ItemHeight * 0.5
                    local TargetIndex = math.clamp(math.floor(Centre / RowH) + 1, 1, TotalItems)
                    local DragIndex = table.find(Items, ItemFrame)
                    if DragIndex and TargetIndex ~= DragIndex then
                        table.remove(Items, DragIndex)
                        table.insert(Items, TargetIndex, ItemFrame)
                        for i, f in ipairs(Items) do
                            if f ~= ItemFrame then f.Position = UDim2.new(0, 0, 0, GetSlotY(i)) end
                        end
                    end
                end)
                EndC = UserInputService.InputEnded:Connect(function(Input)
                    if Input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
                    Move:Disconnect(); EndC:Disconnect()
                    Drag.Active = false
                    SnapAll(); FireCB()
                end)
            end)
            Items[Index] = ItemFrame
        end
        for Index, Value in ipairs(OrderedList) do MakeItem(Value, Index) end
        if Index then Options[Index] = PrioSelector end
        Groupbox:AddBlank(5)
        Groupbox:Resize()
        return PrioSelector
    end

    function Funcs:AddDependencyBox()
        local Depbox = { Dependencies = {} }
        local Groupbox = self
        local Container = Groupbox.Container
        local Holder = Library:Create("Frame", {
            BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0),
            Visible = false, Parent = Container,
        })
        local Frame = Library:Create("Frame", {
            BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0),
            Visible = true, Parent = Holder,
        })
        local Layout = Library:Create("UIListLayout", {
            FillDirection = Enum.FillDirection.Vertical,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = Frame,
        })
        function Depbox:Resize()
            Holder.Size = UDim2.new(1, 0, 0, Layout.AbsoluteContentSize.Y)
            Groupbox:Resize()
        end
        Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() Depbox:Resize() end)
        Holder:GetPropertyChangedSignal("Visible"):Connect(function() Depbox:Resize() end)
        function Depbox:Update()
            for _, Dependency in next, Depbox.Dependencies do
                local Elem, Value = Dependency[1], Dependency[2]
                local Match = false
                if type(Value) == "table" then
                    for _, V in ipairs(Value) do if Elem.Value == V then Match = true; break end end
                else
                    Match = (Elem.Value == Value)
                end
                if not Match then Holder.Visible = false; Depbox:Resize(); return end
            end
            Holder.Visible = true
            Depbox:Resize()
            if not Holder.Visible then Library:UpdateDependencyBoxes() end
        end
        function Depbox:SetupDependencies(Dependencies)
            for _, D in next, Dependencies do
                assert(type(D) == "table", "SetupDependencies: Dependency is not of type `table`.")
                assert(D[1], "SetupDependencies: Dependency is missing element argument.")
                assert(D[2] ~= nil, "SetupDependencies: Dependency is missing value argument.")
            end
            Depbox.Dependencies = Dependencies
            Depbox:Update()
            return self
        end
        Depbox.Container = Frame
        setmetatable(Depbox, BaseGroupbox)
        table.insert(Library.DependencyBoxes, Depbox)
        return Depbox
    end

    -- ConfigManager: same shape as original, only cosmetic changes omitted
    function Funcs:CreateConfigurationManager(BasePath, Extension, TablesToSave)
        -- (identical to your current implementation -- omitted here for brevity,
        --  copy the version from your current library. It is UI-agnostic.)
        -- If you'd like the full body re-pasted, ask and I'll include it.
    end

    BaseGroupbox.__index = Funcs
    BaseGroupbox.__namecall = function(_, Key, ...) return Funcs[Key](...) end
end

-- ============================================================
-- HUD: Keybind list / Watermark / Notifications
-- ============================================================
do
    Library.NotificationArea = Library:Create("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 40),
        Size = UDim2.new(0, 300, 0, 200),
        ZIndex = 100, Parent = ScreenGui,
    })
    Library:Create("UIListLayout", {
        Padding = UDim.new(0, 4),
        FillDirection = Enum.FillDirection.Vertical,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = Library.NotificationArea,
    })

    -- Watermark
    local WatermarkOuter = Library:Create("Frame", {
        BackgroundColor3 = Library.Border,
        BorderColor3 = Library.Border,
        Position = UDim2.new(0, 100, 0, -25),
        Size = UDim2.new(0, 213, 0, 18),
        ZIndex = 200, Visible = false, Parent = ScreenGui,
    })
    local WatermarkInner = Library:Create("Frame", {
        BackgroundColor3 = Library.SectionBG,
        BorderColor3 = Library.Accent,
        BorderMode = Enum.BorderMode.Inset,
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = 201, Parent = WatermarkOuter,
    })
    Library:AddToRegistry(WatermarkInner, { BorderColor3 = "Accent" })
    local WatermarkLabel = Library:CreateLabel({
        Position = UDim2.new(0, 6, 0, 0),
        Size = UDim2.new(1, -4, 1, 0),
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 203, Parent = WatermarkInner,
    })
    Library.Watermark = WatermarkOuter
    Library.WatermarkText = WatermarkLabel
    Library:MakeDraggable(Library.Watermark)

    -- Keybind list (bottom-left)
    local KeybindOuter = Library:Create("Frame", {
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundColor3 = Library.Border,
        BorderColor3 = Library.Border,
        Position = UDim2.new(0, 10, 0.5, 0),
        Size = UDim2.new(0, 210, 0, 20),
        Visible = false, ZIndex = 100, Parent = ScreenGui,
    })
    local KeybindInner = Library:Create("Frame", {
        BackgroundColor3 = Library.SectionBG,
        BorderColor3 = Library.Outline,
        BorderMode = Enum.BorderMode.Inset,
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = 101, Parent = KeybindOuter,
    })
    Library:AddToRegistry(KeybindInner, { BackgroundColor3 = "SectionBG", BorderColor3 = "Outline" }, true)

    Library:Create("Frame", {
        BackgroundColor3 = Library.Accent,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 2),
        ZIndex = 102, Parent = KeybindInner,
    })

    local KeybindLabel = Library:CreateLabel({
        Size = UDim2.new(1, 0, 0, 20),
        Position = UDim2.fromOffset(6, 2),
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = "Keybinds",
        TextColor3 = Library.FontMuted,
        ZIndex = 104, Parent = KeybindInner,
    })

    local KeybindContainer = Library:Create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, -20),
        Position = UDim2.new(0, 0, 0, 20),
        ZIndex = 1, Parent = KeybindInner,
    })
    Library:Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = KeybindContainer,
    })
    Library:Create("UIPadding", { PaddingLeft = UDim.new(0, 6), Parent = KeybindContainer })
    Library.KeybindFrame = KeybindOuter
    Library.KeybindContainer = KeybindContainer
    Library:MakeDraggable(KeybindOuter)
end

-- ============================================================
-- Watermark / Notify
-- ============================================================
function Library:SetWatermarkVisibility(v) Library.Watermark.Visible = v end
function Library:SetWatermark(Text)
    local X, Y = Library:GetTextBounds(Text, Library.Font, 12)
    Library.Watermark.Size = UDim2.new(0, X + 15, 0, (Y * 1.5) + 3)
    Library:SetWatermarkVisibility(true)
    Library.WatermarkText.Text = Text
end

function Library:Notify(Text, Time)
    local XSize, YSize = Library:GetTextBounds(Text, Library.Font, 12)
    YSize += 7
    local NotifyOuter = Library:Create("Frame", {
        BackgroundColor3 = Library.Border,
        BorderColor3 = Library.Border,
        Position = UDim2.new(0, 100, 0, 10),
        Size = UDim2.new(0, 0, 0, YSize),
        ClipsDescendants = true,
        ZIndex = 100, Parent = Library.NotificationArea,
    })
    local NotifyInner = Library:Create("Frame", {
        BackgroundColor3 = Library.SectionBG,
        BorderColor3 = Library.Outline,
        BorderMode = Enum.BorderMode.Inset,
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = 101, Parent = NotifyOuter,
    })
    Library:AddToRegistry(NotifyInner, { BackgroundColor3 = "SectionBG", BorderColor3 = "Outline" }, true)

    local NotifyLabel = Library:CreateLabel({
        Position = UDim2.new(0, 6, 0, 0),
        Size = UDim2.new(1, -4, 1, 0),
        Text = Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextSize = 12,
        ZIndex = 103, Parent = NotifyInner,
    })
    Library:Create("Frame", {
        BackgroundColor3 = Library.Accent,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(0, 3, 1, 0),
        ZIndex = 104, Parent = NotifyInner,
    })
    pcall(NotifyOuter.TweenSize, NotifyOuter, UDim2.new(0, XSize + 8 + 4, 0, YSize), "Out", "Quad", 0.4, true)
    task.spawn(function()
        task.wait(Time or 5)
        pcall(NotifyOuter.TweenSize, NotifyOuter, UDim2.new(0, 0, 0, YSize), "Out", "Quad", 0.4, true)
        task.wait(0.4)
        NotifyOuter:Destroy()
    end)
end

-- ============================================================
-- Window & Tabs  — gamesense sidebar layout
-- ============================================================
local TabIcons = {
    -- fallback icons; user can pass their own
    ["Aiming"]  = "rbxassetid://6031090990", -- crosshair
    ["Visuals"] = "rbxassetid://6031094667", -- eye
    ["World"]   = "rbxassetid://6031094682", -- sun
    ["Miscellaneous"] = "rbxassetid://6031094660", -- gear
    ["Settings"]= "rbxassetid://6031280882", -- wrench
}

function Library:CreateWindow(Configuration, _IsParallel)
    if type(Configuration.Title) ~= "string" then Configuration.Title = "No title" end
    if type(Configuration.TabPadding) ~= "number" then Configuration.TabPadding = 0 end
    if type(Configuration.MenuFadeTime) ~= "number" then Configuration.MenuFadeTime = 0.2 end
    Configuration.AnchorPoint = Vector2.new(0.5, 0.5)
    Configuration.Position = UDim2.fromScale(0.5, 0.5)
    if typeof(Configuration.Size) ~= "UDim2" then Configuration.Size = UDim2.fromOffset(620, 520) end

    local Window = { Tabs = {} }

    -- Outer
    local Outer = Library:Create("Frame", {
        AnchorPoint = Configuration.AnchorPoint,
        BackgroundColor3 = Library.WindowBG,
        BorderSizePixel = 0,
        Position = Configuration.Position,
        Size = Configuration.Size,
        Visible = false,
        ZIndex = 1, Parent = ScreenGui,
    })
    Library:MakeDraggable(Outer, 26)

    -- Thin outer border like gamesense
    local Border = Library:Create("Frame", {
        BackgroundColor3 = Library.Border,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = 1, Parent = Outer,
    })
    local BorderInner = Library:Create("Frame", {
        BackgroundColor3 = Library.WindowBG,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 1, 0, 1),
        Size = UDim2.new(1, -2, 1, -2),
        ZIndex = 2, Parent = Border,
    })

    -- Header bar
    local Header = Library:Create("Frame", {
        BackgroundColor3 = Library.SectionBG,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(1, 0, 0, 24),
        ZIndex = 3, Parent = BorderInner,
    })

    local WindowLabel = Library:CreateLabel({
        Position = UDim2.new(0, 10, 0, 0),
        Size = UDim2.new(1, -80, 1, 0),
        Text = Configuration.Title,
        TextColor3 = Library.Accent,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 4, Parent = Header,
    })
    Library:AddToRegistry(WindowLabel, { TextColor3 = "Accent" })

    -- Body: sidebar + main
    local Body = Library:Create("Frame", {
        BackgroundColor3 = Library.WindowBG,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 24),
        Size = UDim2.new(1, 0, 1, -24),
        ZIndex = 3, Parent = BorderInner,
    })

    local Sidebar = Library:Create("Frame", {
        BackgroundColor3 = Library.SidebarBG,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(0, 44, 1, 0),
        ZIndex = 4, Parent = Body,
    })
    Library:Create("UIListLayout", {
        Padding = UDim.new(0, 4),
        FillDirection = Enum.FillDirection.Vertical,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = Sidebar,
    })
    Library:Create("UIPadding", { PaddingTop = UDim.new(0, 6), Parent = Sidebar })

    local Content = Library:Create("Frame", {
        BackgroundColor3 = Library.WindowBG,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 44, 0, 0),
        Size = UDim2.new(1, -44, 1, 0),
        ZIndex = 4, Parent = Body,
    })

    -- Sub-header (tab title bar like gamesense's "Weapon type / Aimbot / ..." strip)
    local SubHeader = Library:Create("Frame", {
        BackgroundColor3 = Library.SectionBG,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(1, 0, 0, 20),
        ZIndex = 5, Parent = Content,
    })

    local TabContainer = Library:Create("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 20),
        Size = UDim2.new(1, 0, 1, -20),
        ZIndex = 5, Parent = Content,
    })

    function Window:SetWindowTitle(Title) WindowLabel.Text = Title end

    function Window:AddTab(Name, Icon)
        local Tab = { Groupboxes = {}, Tabboxes = {} }

        -- Sidebar icon button
        local IconButton = Library:Create("Frame", {
            BackgroundColor3 = Library.SidebarBG,
            BorderSizePixel = 0,
            Size = UDim2.new(0, 32, 0, 32),
            ZIndex = 5, Parent = Sidebar,
        })
        local IconImage = Library:Create("ImageLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 6, 0, 6),
            Size = UDim2.new(0, 20, 0, 20),
            Image = Icon or TabIcons[Name] or "rbxassetid://6031090990",
            ImageColor3 = Library.FontMuted,
            ZIndex = 6, Parent = IconButton,
        })
        Library:AddToRegistry(IconImage, { ImageColor3 = "FontMuted" })

        local IconAccent = Library:Create("Frame", {
            BackgroundColor3 = Library.Accent,
            BorderSizePixel = 0,
            Position = UDim2.new(0, 0, 0, 0),
            Size = UDim2.new(0, 2, 1, 0),
            Visible = false,
            ZIndex = 7, Parent = IconButton,
        })
        Library:AddToRegistry(IconAccent, { BackgroundColor3 = "Accent" })

        -- Tab frame
        local TabFrame = Library:Create("Frame", {
            Name = "TabFrame",
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 0, 0, 0),
            Size = UDim2.new(1, 0, 1, 0),
            Visible = false,
            ZIndex = 2, Parent = TabContainer,
        })

        local LeftSide = Library:Create("ScrollingFrame", {
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Position = UDim2.new(0, 8, 0, 8),
            Size = UDim2.new(0.5, -12, 1, -16),
            CanvasSize = UDim2.new(0, 0, 0, 0),
            BottomImage = "", TopImage = "",
            ScrollBarThickness = 0, ZIndex = 2, Parent = TabFrame,
        })
        local RightSide = Library:Create("ScrollingFrame", {
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Position = UDim2.new(0.5, 4, 0, 8),
            Size = UDim2.new(0.5, -12, 1, -16),
            CanvasSize = UDim2.new(0, 0, 0, 0),
            BottomImage = "", TopImage = "",
            ScrollBarThickness = 0, ZIndex = 2, Parent = TabFrame,
        })
        Library:Create("UIListLayout", {
            Padding = UDim.new(0, 8), FillDirection = Enum.FillDirection.Vertical,
            SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Center,
            Parent = LeftSide,
        })
        Library:Create("UIListLayout", {
            Padding = UDim.new(0, 8), FillDirection = Enum.FillDirection.Vertical,
            SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Center,
            Parent = RightSide,
        })
        for _, Side in next, { LeftSide, RightSide } do
            Side:WaitForChild("UIListLayout"):GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                Side.CanvasSize = UDim2.fromOffset(0, Side.UIListLayout.AbsoluteContentSize.Y)
            end)
        end

        function Tab:ShowTab()
            for _, T in next, Window.Tabs do T:HideTab() end
            IconAccent.Visible = true
            IconButton.BackgroundColor3 = Library.ControlBG
            IconImage.ImageColor3 = Library.Accent
            Library.RegistryMap[IconImage].Properties.ImageColor3 = "Accent"
            TabFrame.Visible = true
            SubHeader.Title.Text = Name  -- placeholder; we attach below
        end
        function Tab:HideTab()
            IconAccent.Visible = false
            IconButton.BackgroundColor3 = Library.SidebarBG
            IconImage.ImageColor3 = Library.FontMuted
            Library.RegistryMap[IconImage].Properties.ImageColor3 = "FontMuted"
            TabFrame.Visible = false
        end
        function Tab:SetLayoutOrder(pos) IconButton.LayoutOrder = pos end

        -- Sub-header title (created once, reused)
        if not SubHeader.Title then
            SubHeader.Title = Library:CreateLabel({
                Position = UDim2.new(0, 10, 0, 0),
                Size = UDim2.new(1, -10, 1, 0),
                Text = "",
                TextXAlignment = Enum.TextXAlignment.Left,
                TextSize = 12,
                TextColor3 = Library.FontMuted,
                ZIndex = 6, Parent = SubHeader,
            })
            Library:AddToRegistry(SubHeader.Title, { TextColor3 = "FontMuted" })
        end

        function Tab:AddGroupbox(Info)
            local Groupbox = {}
            local BoxOuter = Library:Create("Frame", {
                BackgroundColor3 = Library.PanelBG,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 24),
                ZIndex = 2, Parent = Info.Side == 1 and LeftSide or RightSide,
            })
            Library:AddToRegistry(BoxOuter, { BackgroundColor3 = "PanelBG" })

            -- thin top border line
            local TopLine = Library:Create("Frame", {
                BackgroundColor3 = Library.Divider,
                BorderSizePixel = 0,
                Position = UDim2.new(0, 0, 0, 0),
                Size = UDim2.new(1, 0, 0, 1),
                ZIndex = 3, Parent = BoxOuter,
            })

            -- header strip
            local HeaderStrip = Library:Create("Frame", {
                BackgroundColor3 = Library.SectionBG,
                BorderSizePixel = 0,
                Position = UDim2.new(0, 1, 0, 1),
                Size = UDim2.new(1, -2, 0, 18),
                ZIndex = 4, Parent = BoxOuter,
            })
            Library:CreateLabel({
                Size = UDim2.new(1, 0, 1, 0),
                Position = UDim2.new(0, 6, 0, 0),
                TextSize = 12,
                Text = Info.Name,
                TextColor3 = Library.FontColor,
                Font = Library.FontBold,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 5, Parent = HeaderStrip,
            })

            local Container = Library:Create("Frame", {
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 6, 0, 22),
                Size = UDim2.new(1, -12, 1, -22),
                ZIndex = 1, Parent = BoxOuter,
            })
            Library:Create("UIListLayout", {
                FillDirection = Enum.FillDirection.Vertical,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Parent = Container,
            })

            function Groupbox:Resize()
                local Size = 0
                for _, Element in next, Groupbox.Container:GetChildren() do
                    if not Element:IsA("UIListLayout") and Element.Visible then
                        Size = Size + Element.Size.Y.Offset
                    end
                end
                BoxOuter.Size = UDim2.new(1, 0, 0, 22 + Size + 4)
            end

            Groupbox.Container = Container
            setmetatable(Groupbox, BaseGroupbox)
            Groupbox:AddBlank(3)
            Groupbox:Resize()
            Tab.Groupboxes[Info.Name] = Groupbox
            return Groupbox
        end

        function Tab:AddLeftGroupbox(Name) return Tab:AddGroupbox({ Side = 1, Name = Name }) end
        function Tab:AddRightGroupbox(Name) return Tab:AddGroupbox({ Side = 2, Name = Name }) end

        function Tab:AddTabbox(Info)
            local Tabbox = { Tabs = {} }
            local BoxOuter = Library:Create("Frame", {
                BackgroundColor3 = Library.PanelBG,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 24),
                ZIndex = 2, Parent = Info.Side == 1 and LeftSide or RightSide,
            })
            Library:AddToRegistry(BoxOuter, { BackgroundColor3 = "PanelBG" })

            local HeaderStrip = Library:Create("Frame", {
                BackgroundColor3 = Library.SectionBG,
                BorderSizePixel = 0,
                Position = UDim2.new(0, 1, 0, 1),
                Size = UDim2.new(1, -2, 0, 18),
                ZIndex = 4, Parent = BoxOuter,
            })

            local TabButtons = Library:Create("Frame", {
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 0, 0, 0),
                Size = UDim2.new(1, 0, 1, 0),
                ZIndex = 5, Parent = HeaderStrip,
            })
            Library:Create("UIListLayout", {
                FillDirection = Enum.FillDirection.Horizontal,
                HorizontalAlignment = Enum.HorizontalAlignment.Left,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Parent = TabButtons,
            })

            function Tabbox:AddTab(Name)
                local Tab = {}
                local Button = Library:Create("Frame", {
                    BackgroundColor3 = Library.SectionBG,
                    BorderSizePixel = 0,
                    Size = UDim2.new(0, 90, 1, 0),
                    ZIndex = 6, Parent = TabButtons,
                })
                Library:AddToRegistry(Button, { BackgroundColor3 = "SectionBG" })
                local ButtonLabel = Library:CreateLabel({
                    Size = UDim2.new(1, 0, 1, 0),
                    TextSize = 12,
                    Text = Name,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    ZIndex = 7, Parent = Button,
                })
                local Underline = Library:Create("Frame", {
                    BackgroundColor3 = Library.Accent,
                    BorderSizePixel = 0,
                    Position = UDim2.new(0, 0, 1, -1),
                    Size = UDim2.new(1, 0, 0, 1),
                    Visible = false,
                    ZIndex = 9, Parent = Button,
                })

                local Container = Library:Create("Frame", {
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 6, 0, 22),
                    Size = UDim2.new(1, -12, 1, -22),
                    ZIndex = 1, Visible = false, Parent = BoxOuter,
                })
                Library:Create("UIListLayout", {
                    FillDirection = Enum.FillDirection.Vertical,
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Parent = Container,
                })

                function Tab:Show()
                    for _, T in next, Tabbox.Tabs do T:Hide() end
                    Container.Visible = true
                    Underline.Visible = true
                    ButtonLabel.TextColor3 = Library.Accent
                    Library.RegistryMap[ButtonLabel].Properties.TextColor3 = "Accent"
                    Tab:Resize()
                end
                function Tab:Hide()
                    Container.Visible = false
                    Underline.Visible = false
                    ButtonLabel.TextColor3 = Library.FontColor
                    Library.RegistryMap[ButtonLabel].Properties.TextColor3 = "FontColor"
                end
                function Tab:Resize()
                    local Count = 0
                    for _ in next, Tabbox.Tabs do Count = Count + 1 end
                    for _, B in next, TabButtons:GetChildren() do
                        if not B:IsA("UIListLayout") then B.Size = UDim2.new(1 / Count, 0, 1, 0) end
                    end
                    if not Container.Visible then return end
                    local Size = 0
                    for _, Element in next, Tab.Container:GetChildren() do
                        if not Element:IsA("UIListLayout") and Element.Visible then
                            Size = Size + Element.Size.Y.Offset
                        end
                    end
                    BoxOuter.Size = UDim2.new(1, 0, 0, 22 + Size + 4)
                end

                Button.InputBegan:Connect(function(Input)
                    if Input.UserInputType == Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame() then
                        Tab:Show(); Tab:Resize()
                    end
                end)

                Tab.Container = Container
                Tabbox.Tabs[Name] = Tab
                setmetatable(Tab, BaseGroupbox)
                Tab:AddBlank(3)
                Tab:Resize()
                if #TabButtons:GetChildren() == 2 then Tab:Show() end
                return Tab
            end

            Tab.Tabboxes[Info.Name or ""] = Tabbox
            return Tabbox
        end
        function Tab:AddLeftTabbox(Name) return Tab:AddTabbox({ Name = Name, Side = 1 }) end
        function Tab:AddRightTabbox(Name) return Tab:AddTabbox({ Name = Name, Side = 2 }) end

        IconButton.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 then Tab:ShowTab() end
        end)
        IconButton.MouseEnter:Connect(function()
            if not IconAccent.Visible then IconButton.BackgroundColor3 = Library.ControlBG end
        end)
        IconButton.MouseLeave:Connect(function()
            if not IconAccent.Visible then IconButton.BackgroundColor3 = Library.SidebarBG end
        end)

        if #TabContainer:GetChildren() == 0 then Tab:ShowTab() end
        Window.Tabs[Name] = Tab
        return Tab
    end

    -- Custom gamesense-style cursor
    local ToggledState = false
    local Fading = false

    function Library:Toggle()
        if Fading then return end
        for ModeSelect in next, Library.ModeSelectOuters do ModeSelect.Visible = false end
        local FadeTime = Configuration.MenuFadeTime
        Fading = true
        ToggledState = not ToggledState
        Library.Toggled = ToggledState
        if ToggledState then
            Outer.Visible = true
            task.spawn(function()
                local State = UserInputService.MouseIconEnabled
                local Cursor = Drawing.new("Triangle")
                Cursor.Thickness = 1; Cursor.Filled = true; Cursor.Visible = true
                local Outline = Drawing.new("Triangle")
                Outline.Thickness = 1; Outline.Filled = false; Outline.Color = Color3.new(0, 0, 0); Outline.Visible = true
                while ToggledState and ScreenGui.Parent do
                    UserInputService.MouseIconEnabled = false
                    local mp = UserInputService:GetMouseLocation()
                    Cursor.Color = Library.Accent
                    Cursor.PointA = Vector2.new(mp.X, mp.Y)
                    Cursor.PointB = Vector2.new(mp.X + 14, mp.Y + 5)
                    Cursor.PointC = Vector2.new(mp.X + 5, mp.Y + 14)
                    Outline.PointA, Outline.PointB, Outline.PointC = Cursor.PointA, Cursor.PointB, Cursor.PointC
                    RenderStepped:Wait()
                end
                UserInputService.MouseIconEnabled = State
                Cursor:Remove(); Outline:Remove()
            end)
        end
        for _, Desc in next, Outer:GetDescendants() do
            if Desc:IsA("ImageLabel") then
                TweenService:Create(Desc, TweenInfo.new(FadeTime), { ImageTransparency = ToggledState and 0 or 1 }):Play()
            elseif Desc:IsA("TextLabel") or Desc:IsA("TextBox") then
                TweenService:Create(Desc, TweenInfo.new(FadeTime), { TextTransparency = ToggledState and 0 or 1 }):Play()
            elseif Desc:IsA("Frame") or Desc:IsA("ScrollingFrame") then
                TweenService:Create(Desc, TweenInfo.new(FadeTime), { BackgroundTransparency = ToggledState and 0 or 1 }):Play()
            end
        end
        task.wait(FadeTime)
        Outer.Visible = ToggledState
        Fading = false
    end

    UserInputService.InputBegan:Connect(function(Input, Processed)
        if type(Library.ToggleKeybind) == "table" and Library.ToggleKeybind.Type == "KeyPicker" then
            if Input.UserInputType == Enum.UserInputType.Keyboard and Input.KeyCode.Name == Library.ToggleKeybind.Value then
                task.spawn(Library.Toggle)
            end
        elseif Input.KeyCode == Enum.KeyCode.RightControl or (Input.KeyCode == Enum.KeyCode.RightShift and not Processed) then
            task.spawn(Library.Toggle)
        end
    end)

    Window.Holder = Outer
    return Window
end

-- ============================================================
-- Player / team dropdown refreshers
-- ============================================================
local function OnPlayerChange()
    local PlayerList = GetPlayersString()
    for _, Value in next, Options do
        if Value.Type == "Dropdown" and Value.SpecialType == "Player" then
            Value:SetValues(PlayerList)
        end
    end
end
Players.PlayerAdded:Connect(OnPlayerChange)
Players.PlayerRemoving:Connect(OnPlayerChange)

getgenv().Library = Library
return Library
