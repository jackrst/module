--[[
    Linoria (gamesense edition) — fixed
    No transparency corruption, brighter labels, safe icons.
]]

local clonerefFunction = cloneref or clone_ref or clonereference or clone_reference
local ns__cloneref = clonerefFunction and function(O)
    local s, r = pcall(clonerefFunction, O); return s and r or O
end or function(O) return O end

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
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = ns__cloneref(game:GetService("CoreGui"))

local Toggles, Options = {}, {}

-- ============================================================
-- Palette
-- ============================================================
local Library = {
    Toggled = true,
    Toggles = Toggles, Options = Options,
    Registry = {}, RegistryMap = {}, HudRegistry = {},

    -- text (bright enough to read on dark)
    FontColor   = Color3.fromRGB(228, 228, 228),
    FontMuted   = Color3.fromRGB(175, 175, 175),

    -- backgrounds
    WindowBG    = Color3.fromRGB(14, 14, 14),
    PanelBG     = Color3.fromRGB(22, 22, 22),
    SectionBG   = Color3.fromRGB(30, 30, 30),
    SidebarBG   = Color3.fromRGB(10, 10, 10),
    HeaderBG    = Color3.fromRGB(20, 20, 20),
    ControlBG   = Color3.fromRGB(30, 30, 30),
    ControlHover= Color3.fromRGB(42, 42, 42),
    Border      = Color3.fromRGB(6, 6, 6),
    Outline     = Color3.fromRGB(52, 52, 52),
    Divider     = Color3.fromRGB(40, 40, 40),

    -- accent
    Accent      = Color3.fromRGB(144, 200, 83),
    AccentDark  = Color3.fromRGB(96, 145, 55),
    AccentHover = Color3.fromRGB(160, 215, 100),
    RiskColor   = Color3.fromRGB(217, 83, 79),
    WarningColor= Color3.fromRGB(240, 173, 78),

    -- aliases
    MainColor = Color3.fromRGB(22, 22, 22),
    BackgroundColor = Color3.fromRGB(30, 30, 30),

    Font = Enum.Font.SourceSans,
    FontBold = Enum.Font.SourceSansBold,
    FontSize = 13,
    FontSizeSm = 11,
    FontSizeHd = 14,

    OpenedFrames = {}, DependencyBoxes = {}, ModeSelectOuters = {},
    ScreenGui = ScreenGui,

    Sounds = { Enabled = true, Click = "rbxassetid://6895079853", Volume = 0.35 },
    CornerRadius = 0,
    NotifyOnError = false,
}
Library.AccentColor = Library.Accent
Library.AccentColorDark = Library.AccentDark
Library.OutlineColor = Library.Outline

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
        local _, i = string.find(tostring(err), ":%d+: ")
        Library:Notify(i and string.sub(err, i + 1) or tostring(err), 3)
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
function Library:GetDarkerColor(C)
    local H, S, V = Color3.toHSV(C)
    return Color3.fromHSV(H, S, V / 1.5)
end
function Library:MapValue(V, a, b, c, d)
    return (1 - ((V - a) / (b - a))) * c + ((V - a) / (b - a)) * d
end

function Library:MakeDraggable(Instance, Cutoff)
    Instance.Active = true
    Instance.InputBegan:Connect(function(Input)
        if Input.UserInputType == Enum.UserInputType.MouseButton1 then
            local ObjPos = Vector2.new(Mouse.X - Instance.AbsolutePosition.X, Mouse.Y - Instance.AbsolutePosition.Y)
            if ObjPos.Y > (Cutoff or 40) then return end
            while UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                Instance.Position = UDim2.new(
                    0, Mouse.X - ObjPos.X + (Instance.Size.X.Offset * Instance.AnchorPoint.X),
                    0, Mouse.Y - ObjPos.Y + (Instance.Size.Y.Offset * Instance.AnchorPoint.Y))
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
            if type(ColorIdx) == "string" then Object.Instance[Property] = Library[ColorIdx]
            elseif type(ColorIdx) == "function" then Object.Instance[Property] = ColorIdx() end
        end
    end
end
function Library:UpdateDependencyBoxes()
    for _, D in next, Library.DependencyBoxes do D:Update() end
end
function Library:PlaySound(id, pitch)
    if not Library.Sounds.Enabled or not id or id == "" then return end
    local s = ns__cloneref(Instance.new("Sound"))
    s.SoundId = id; s.Volume = Library.Sounds.Volume; s.PlaybackSpeed = pitch or 1
    s.Parent = ScreenGui; s:Play()
    task.delay(2, function() pcall(function() s:Destroy() end) end)
end

function Library:AddToolTip(InfoStr, HoverInstance)
    local X, Y = Library:GetTextBounds(InfoStr, Library.Font, 12)
    local Tooltip = Library:Create("Frame", {
        BackgroundColor3 = Library.SectionBG,
        BorderColor3 = Library.Border,
        BorderMode = Enum.BorderMode.Inset,
        Size = UDim2.fromOffset(X + 10, Y + 8),
        ZIndex = 100, Parent = ScreenGui, Visible = false,
    })
    Library:AddToRegistry(Tooltip, { BackgroundColor3 = "SectionBG", BorderColor3 = "Border" })
    Library:CreateLabel({
        Position = UDim2.fromOffset(5, 3), Size = UDim2.fromOffset(X, Y),
        TextSize = 12, Text = InfoStr, TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = Tooltip.ZIndex + 1, Parent = Tooltip,
    })
    local IsHovering = false
    HoverInstance.MouseEnter:Connect(function()
        if Library:MouseIsOverOpenedFrame() then return end
        IsHovering = true
        Tooltip.Position = UDim2.fromOffset(Mouse.X + 15, Mouse.Y + 12)
        Tooltip.Visible = true
        while IsHovering do
            RunService.Heartbeat:Wait()
            Tooltip.Position = UDim2.fromOffset(Mouse.X + 15, Mouse.Y + 12)
        end
    end)
    HoverInstance.MouseLeave:Connect(function() IsHovering = false; Tooltip.Visible = false end)
end

ScreenGui.DescendantRemoving:Connect(function(i)
    if Library.RegistryMap[i] then Library:RemoveFromRegistry(i) end
end)

-- ============================================================
-- Base addons
-- ============================================================
local BaseAddons = {}
do
    local Funcs = {}

    function Funcs:AddColorPicker(Index, Info)
        local ToggleLabel = self.TextLabel
        assert(Info.Default, "AddColorPicker: Missing default value.")
        local ColorPicker = {
            Value = Info.Default, Transparency = Info.Transparency or 0,
            Type = "ColorPicker",
            Title = type(Info.Title) == "string" and Info.Title or "Color picker",
            Callback = Info.Callback or function() end,
        }
        function ColorPicker:SetHSVFromRGB(C)
            local H, S, V = Color3.toHSV(C)
            ColorPicker.Hue, ColorPicker.Saturation, ColorPicker.Vib = H, S, V
        end
        ColorPicker:SetHSVFromRGB(ColorPicker.Value)

        local DisplayFrame = Library:Create("Frame", {
            BackgroundColor3 = ColorPicker.Value,
            BorderColor3 = Library:GetDarkerColor(ColorPicker.Value),
            BorderMode = Enum.BorderMode.Inset,
            Size = UDim2.new(0, 14, 0, 14), ZIndex = 6, Parent = ToggleLabel,
        })

        local PickerFrameOuter = Library:Create("Frame", {
            Name = "Color", BackgroundColor3 = Library.Border, BorderColor3 = Library.Border,
            Position = UDim2.fromOffset(DisplayFrame.AbsolutePosition.X, DisplayFrame.AbsolutePosition.Y + 18),
            Size = UDim2.fromOffset(230, Info.Transparency and 271 or 253),
            Visible = false, ZIndex = 15, Parent = ScreenGui,
        })
        DisplayFrame:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
            PickerFrameOuter.Position = UDim2.fromOffset(DisplayFrame.AbsolutePosition.X, DisplayFrame.AbsolutePosition.Y + 18)
        end)

        local PickerFrameInner = Library:Create("Frame", {
            BackgroundColor3 = Library.SectionBG, BorderColor3 = Library.Outline,
            BorderMode = Enum.BorderMode.Inset, Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 16, Parent = PickerFrameOuter,
        })
        Library:AddToRegistry(PickerFrameInner, { BackgroundColor3 = "SectionBG", BorderColor3 = "Outline" })
        Library:Create("Frame", {
            BackgroundColor3 = Library.Accent, BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 2), ZIndex = 17, Parent = PickerFrameInner,
        })

        local SatVibMapOuter = Library:Create("Frame", {
            BorderColor3 = Library.Border, Position = UDim2.new(0, 4, 0, 25),
            Size = UDim2.new(0, 200, 0, 200), ZIndex = 17, Parent = PickerFrameInner,
        })
        local SatVibMapInner = Library:Create("Frame", {
            BackgroundColor3 = Library.SectionBG, BorderColor3 = Library.Outline,
            BorderMode = Enum.BorderMode.Inset, Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 18, Parent = SatVibMapOuter,
        })
        local SatVibMap = Library:Create("ImageLabel", {
            BorderSizePixel = 0, Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 18, Image = "rbxassetid://4155801252", Parent = SatVibMapInner,
        })
        local CursorOuter = Library:Create("ImageLabel", {
            AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.new(0, 6, 0, 6),
            BackgroundTransparency = 1, Image = "rbxassetid://9619665977",
            ImageColor3 = Color3.new(0, 0, 0), ZIndex = 19, Parent = SatVibMap,
        })
        Library:Create("ImageLabel", {
            Size = UDim2.new(0, 4, 0, 4), Position = UDim2.new(0, 1, 0, 1),
            BackgroundTransparency = 1, Image = "rbxassetid://9619665977",
            ZIndex = 20, Parent = CursorOuter,
        })
        local HueOuter = Library:Create("Frame", {
            BorderColor3 = Library.Border, Position = UDim2.new(0, 208, 0, 25),
            Size = UDim2.new(0, 15, 0, 200), ZIndex = 17, Parent = PickerFrameInner,
        })
        local HueInner = Library:Create("Frame", {
            BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 1, 0), ZIndex = 18, Parent = HueOuter,
        })
        local HueCursor = Library:Create("Frame", {
            BackgroundColor3 = Color3.new(1, 1, 1), AnchorPoint = Vector2.new(0, 0.5),
            BorderColor3 = Color3.new(0, 0, 0), Size = UDim2.new(1, 0, 0, 1),
            ZIndex = 18, Parent = HueInner,
        })
        local Seq = {}
        for H = 0, 1, 0.1 do Seq[#Seq+1] = ColorSequenceKeypoint.new(H, Color3.fromHSV(H, 1, 1)) end
        Library:Create("UIGradient", { Color = ColorSequence.new(Seq), Rotation = 90, Parent = HueInner })

        local HueBoxOuter = Library:Create("Frame", {
            BorderColor3 = Library.Border, Position = UDim2.fromOffset(4, 228),
            Size = UDim2.new(0.5, -6, 0, 20), ZIndex = 18, Parent = PickerFrameInner,
        })
        local HueBoxInner = Library:Create("Frame", {
            BackgroundColor3 = Library.ControlBG, BorderColor3 = Library.Outline,
            BorderMode = Enum.BorderMode.Inset, Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 18, Parent = HueBoxOuter,
        })
        local HueBox = Library:Create("TextBox", {
            BackgroundTransparency = 1, Position = UDim2.new(0, 5, 0, 0),
            Size = UDim2.new(1, -5, 1, 0), Font = Library.Font,
            PlaceholderColor3 = Library.FontMuted, PlaceholderText = "Hex",
            Text = "#FFFFFF", TextColor3 = Library.FontColor, TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 20, Parent = HueBoxInner,
        })
        Library:AddToRegistry(HueBoxInner, { BackgroundColor3 = "ControlBG", BorderColor3 = "Outline" })
        Library:AddToRegistry(HueBox, { TextColor3 = "FontColor" })
        local RGBBoxBase = Library:Create(HueBoxOuter:Clone(), {
            Position = UDim2.new(0.5, 2, 0, 228), Size = UDim2.new(0.5, -6, 0, 20),
            Parent = PickerFrameInner,
        })
        local RGBBox = Library:Create(RGBBoxBase.Frame:FindFirstChild("TextBox"), {
            Text = "255, 255, 255", PlaceholderText = "RGB", TextColor3 = Library.FontColor,
        })
        local TransparencyBoxInner, TransparencyCursor
        if Info.Transparency then
            local TB = Library:Create("Frame", {
                BorderColor3 = Library.Border, Position = UDim2.fromOffset(4, 251),
                Size = UDim2.new(1, -8, 0, 15), ZIndex = 19, Parent = PickerFrameInner,
            })
            TransparencyBoxInner = Library:Create("Frame", {
                BackgroundColor3 = ColorPicker.Value, BorderColor3 = Library.Outline,
                BorderMode = Enum.BorderMode.Inset, Size = UDim2.new(1, 0, 1, 0),
                ZIndex = 19, Parent = TB,
            })
            Library:Create("ImageLabel", {
                BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0),
                Image = "rbxassetid://12978095818", ZIndex = 20, Parent = TransparencyBoxInner,
            })
            TransparencyCursor = Library:Create("Frame", {
                BackgroundColor3 = Color3.new(1, 1, 1), AnchorPoint = Vector2.new(0.5, 0),
                BorderColor3 = Color3.new(0, 0, 0), Size = UDim2.new(0, 1, 1, 0),
                ZIndex = 21, Parent = TransparencyBoxInner,
            })
        end
        Library:CreateLabel({
            Size = UDim2.new(1, 0, 0, 14), Position = UDim2.fromOffset(5, 5),
            TextXAlignment = Enum.TextXAlignment.Left, TextSize = 13,
            Text = ColorPicker.Title, ZIndex = 16, Parent = PickerFrameInner,
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
                math.floor(ColorPicker.Value.R*255), math.floor(ColorPicker.Value.G*255), math.floor(ColorPicker.Value.B*255)
            }, ", ")
            Library:SafeCallback(ColorPicker.Callback, ColorPicker.Value)
            Library:SafeCallback(ColorPicker.Changed, ColorPicker.Value)
        end
        function ColorPicker:OnChanged(Func) ColorPicker.Changed = Func; Func(ColorPicker.Value) end
        function ColorPicker:Show()
            for F in next, Library.OpenedFrames do if F.Name == "Color" then F.Visible = false; Library.OpenedFrames[F] = nil end end
            PickerFrameOuter.Visible = true; Library.OpenedFrames[PickerFrameOuter] = true
        end
        function ColorPicker:Hide()
            PickerFrameOuter.Visible = false; Library.OpenedFrames[PickerFrameOuter] = nil
        end
        function ColorPicker:SetValue(HSV, T)
            ColorPicker.Transparency = T or 0
            ColorPicker:SetHSVFromRGB(Color3.fromHSV(HSV[1], HSV[2], HSV[3]))
            ColorPicker:Display(); Library:UpdateDependencyBoxes()
        end
        function ColorPicker:SetValueRGB(C, T)
            ColorPicker.Transparency = T or 0
            ColorPicker:SetHSVFromRGB(C); ColorPicker:Display(); Library:UpdateDependencyBoxes()
        end

        SatVibMap.InputBegan:Connect(function(Input)
            if Input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
            while UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                local x1, x2 = SatVibMap.AbsolutePosition.X, SatVibMap.AbsolutePosition.X + SatVibMap.AbsoluteSize.X
                local y1, y2 = SatVibMap.AbsolutePosition.Y, SatVibMap.AbsolutePosition.Y + SatVibMap.AbsoluteSize.Y
                ColorPicker.Saturation = (math.clamp(Mouse.X, x1, x2) - x1) / (x2 - x1)
                ColorPicker.Vib = 1 - ((math.clamp(Mouse.Y, y1, y2) - y1) / (y2 - y1))
                ColorPicker:Display(); RenderStepped:Wait()
            end
            Library:AttemptSave()
        end)
        HueInner.InputBegan:Connect(function(Input)
            if Input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
            while UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                local y1, y2 = HueInner.AbsolutePosition.Y, HueInner.AbsolutePosition.Y + HueInner.AbsoluteSize.Y
                ColorPicker.Hue = ((math.clamp(Mouse.Y, y1, y2) - y1) / (y2 - y1))
                ColorPicker:Display(); RenderStepped:Wait()
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
        assert(Info.Default, "AddKeyPicker: Missing default value.")
        local KP = {
            Value = Info.Default, Toggled = false, Mode = Info.Mode or "Toggle",
            Type = "KeyPicker",
            Callback = Info.Callback or function() end,
            ChangedCallback = Info.ChangedCallback or function() end,
            SyncToggleState = Info.SyncToggleState or false,
        }
        if KP.SyncToggleState then Info.Modes = {"Toggle"}; Info.Mode = "Toggle" end

        local PickOuter = Library:Create("Frame", {
            BackgroundColor3 = Library.Border, BorderColor3 = Library.Border,
            Size = UDim2.new(0, 30, 0, 14), ZIndex = 6, Parent = ToggleLabel,
        })
        local PickInner = Library:Create("Frame", {
            BackgroundColor3 = Library.ControlBG, BorderColor3 = Library.Outline,
            BorderMode = Enum.BorderMode.Inset, Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 7, Parent = PickOuter,
        })
        Library:AddToRegistry(PickInner, { BackgroundColor3 = "ControlBG", BorderColor3 = "Outline" })
        local DisplayLabel = Library:CreateLabel({
            Size = UDim2.new(1, 0, 1, 0), TextSize = 11, Text = Info.Default,
            ZIndex = 8, Parent = PickInner,
        })
        local ModeSelectOuter = Library:Create("Frame", {
            BorderColor3 = Library.Border,
            Position = UDim2.fromOffset(ToggleLabel.AbsolutePosition.X + ToggleLabel.AbsoluteSize.X + 4, ToggleLabel.AbsolutePosition.Y + 1),
            Size = UDim2.new(0, 60, 0, 45 + 2), Visible = false, ZIndex = 14, Parent = ScreenGui,
        })
        Library.ModeSelectOuters[ModeSelectOuter] = true
        ToggleLabel:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
            ModeSelectOuter.Position = UDim2.fromOffset(ToggleLabel.AbsolutePosition.X + ToggleLabel.AbsoluteSize.X + 4, ToggleLabel.AbsolutePosition.Y + 1)
        end)
        local ModeSelectInner = Library:Create("Frame", {
            BackgroundColor3 = Library.SectionBG, BorderColor3 = Library.Outline,
            BorderMode = Enum.BorderMode.Inset, Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 15, Parent = ModeSelectOuter,
        })
        Library:AddToRegistry(ModeSelectInner, { BackgroundColor3 = "SectionBG", BorderColor3 = "Outline" })
        Library:Create("UIListLayout", { FillDirection = Enum.FillDirection.Vertical, SortOrder = Enum.SortOrder.LayoutOrder, Parent = ModeSelectInner })
        local ContainerLabel = Library:CreateLabel({
            TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, 0, 0, 18),
            TextSize = 12, Visible = false, ZIndex = 110, Parent = Library.KeybindContainer,
        }, true)

        local Modes = Info.Modes or {"Always", "Toggle", "Hold"}
        local ModeButtons = {}
        for _, Mode in next, Modes do
            local B = {}
            local Label = Library:CreateLabel({
                Active = false, Size = UDim2.new(1, 0, 0, 15),
                TextSize = 12, Text = Mode, ZIndex = 16, Parent = ModeSelectInner,
            })
            function B:Select()
                for _, O in next, ModeButtons do O:Deselect() end
                KP.Mode = Mode
                Label.TextColor3 = Library.Accent
                Library.RegistryMap[Label].Properties.TextColor3 = "Accent"
                ModeSelectOuter.Visible = false
            end
            function B:Deselect()
                KP.Mode = nil
                Label.TextColor3 = Library.FontColor
                Library.RegistryMap[Label].Properties.TextColor3 = "FontColor"
            end
            Label.InputBegan:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 then B:Select(); Library:AttemptSave() end
            end)
            if Mode == KP.Mode then B:Select() end
            ModeButtons[Mode] = B
        end

        function KP:Update()
            if Info.NoUI then return end
            local State = KP:GetState()
            ContainerLabel.Text = string.format("[%s] %s (%s)", KP.Value, Info.Text, KP.Mode)
            ContainerLabel.Visible = true
            ContainerLabel.TextColor3 = State and Library.Accent or Library.FontColor
            Library.RegistryMap[ContainerLabel].Properties.TextColor3 = State and "Accent" or "FontColor"
            local Y, X = 0, 0
            for _, L in next, Library.KeybindContainer:GetChildren() do
                if L:IsA("TextLabel") and L.Visible then
                    Y += 18
                    if L.TextBounds.X > X then X = L.TextBounds.X end
                end
            end
            Library.KeybindFrame.Size = UDim2.new(0, math.max(X + 10, 210), 0, Y + 23)
        end
        function KP:GetState()
            if KP.Mode == "Always" then return true end
            if KP.Mode == "Hold" then
                if KP.Value == "None" then return false end
                if KP.Value == "MB2" then return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) end
                return UserInputService:IsKeyDown(Enum.KeyCode[KP.Value])
            end
            return KP.Toggled
        end
        function KP:SetValue(Data)
            if type(Data) ~= "table" then Data = {Data, KP.Mode or "Toggle"} end
            local Key = Data[1]
            if typeof(Key) ~= "string" or Key == "" then Key = Info.Default or "None" end
            local Mode = Data[2]
            if typeof(Mode) ~= "string" or not ModeButtons[Mode] then Mode = KP.Mode or "Toggle" end
            DisplayLabel.Text = Key; KP.Value = Key
            ModeButtons[Mode]:Select()
            Library:SafeCallback(KP.Callback, Key); KP:Update(); Library:UpdateDependencyBoxes()
        end
        function KP:OnClick(CB) KP.Clicked = CB end
        function KP:OnChanged(CB) KP.Changed = CB; CB(KP.Value) end
        if ParentObj.Addons then table.insert(ParentObj.Addons, KP) end
        function KP:DoClick()
            if ParentObj.Type == "Toggle" and KP.SyncToggleState then ParentObj:SetValue(not ParentObj.Value) end
            Library:SafeCallback(KP.Callback, KP.Toggled)
            Library:SafeCallback(KP.Clicked, KP.Toggled)
        end

        local Picking = false
        PickOuter.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame() then
                Picking = true; DisplayLabel.Text = ""
                local Break, Text = false, ""
                task.spawn(function()
                    while not Break do
                        if Text == "..." then Text = "" end
                        Text = Text .. "."; DisplayLabel.Text = Text; task.wait(0.4)
                    end
                end)
                task.wait(0.2)
                local E
                E = UserInputService.InputBegan:Connect(function(Input)
                    local Key
                    if Input.UserInputType == Enum.UserInputType.Keyboard then Key = Input.KeyCode.Name
                    elseif Input.UserInputType == Enum.UserInputType.MouseButton2 then Key = Input.UserInputType.Name
                    elseif Input.UserInputType == Enum.UserInputType.MouseButton1 then Key = "None" end
                    Break = true; Picking = false; DisplayLabel.Text = Key; KP.Value = Key
                    Library:SafeCallback(KP.Callback, Key); KP:Update()
                    Library:SafeCallback(KP.ChangedCallback, Key); Library:SafeCallback(KP.Changed, Key)
                    Library:AttemptSave(); E:Disconnect()
                end)
            elseif Input.UserInputType == Enum.UserInputType.MouseButton2 and not Library:MouseIsOverOpenedFrame() and not Picking then
                ModeSelectOuter.Visible = true
            end
        end)

        local IC = UserInputService.InputBegan:Connect(function(Input, Processed)
            if Processed then return end
            if not Picking then
                if KP.Mode == "Toggle" and Input.UserInputType == Enum.UserInputType.Keyboard and Input.KeyCode.Name == KP.Value then
                    KP.Toggled = not KP.Toggled; KP:DoClick()
                elseif KP.Mode == "Hold" then
                    if (Input.UserInputType == Enum.UserInputType.Keyboard and Input.KeyCode.Name == KP.Value)
                    or (KP.Value == "MB2" and Input.UserInputType == Enum.UserInputType.MouseButton2) then
                        Library:SafeCallback(KP.Callback, true)
                    end
                end
                KP:Update()
            end
            if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                local ap, as = ModeSelectOuter.AbsolutePosition, ModeSelectOuter.AbsoluteSize
                if Mouse.X < ap.X or Mouse.X > ap.X + as.X or Mouse.Y < ap.Y - 21 or Mouse.Y > ap.Y + as.Y then
                    ModeSelectOuter.Visible = false
                end
            end
        end)
        local IE = UserInputService.InputEnded:Connect(function(Input, Processed)
            if Processed then return end
            if not Picking then
                if KP.Mode == "Hold"
                and ((Input.UserInputType == Enum.UserInputType.Keyboard and Input.KeyCode.Name == KP.Value)
                or (KP.Value == "MB2" and Input.UserInputType == Enum.UserInputType.MouseButton2)) then
                    Library:SafeCallback(KP.Callback, false)
                end
                KP:Update()
            end
        end)
        function KP:Destroy()
            IC:Disconnect(); IE:Disconnect()
            Library.ModeSelectOuters[ModeSelectOuter] = nil
            ModeSelectOuter:Destroy()
        end
        PickOuter.Destroying:Connect(function() KP:Destroy() end)

        KP:Update()
        Options[Index] = KP
        return KP
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
        local TL = Library:CreateLabel({
            Size = UDim2.new(1, -4, 0, 15), TextSize = Library.FontSize,
            Text = Text, TextWrapped = DoesWrap or false,
            TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 5, Parent = Container,
        })
        if DoesWrap then
            TL.Size = UDim2.new(1, -4, 0, select(2, Library:GetTextBounds(Text, Library.Font, Library.FontSize, Vector2.new(TL.AbsoluteSize.X, math.huge))))
        else
            Library:Create("UIListLayout", {
                Padding = UDim.new(0, 4), FillDirection = Enum.FillDirection.Horizontal,
                HorizontalAlignment = Enum.HorizontalAlignment.Right,
                SortOrder = Enum.SortOrder.LayoutOrder, Parent = TL,
            })
        end
        Label.TextLabel = TL; Label.Container = Container
        function Label:SetText(Text)
            TL.Text = Text
            if DoesWrap then
                TL.Size = UDim2.new(1, -4, 0, select(2, Library:GetTextBounds(Text, Library.Font, Library.FontSize, Vector2.new(TL.AbsoluteSize.X, math.huge))))
            end
            Groupbox:Resize()
        end
        if not DoesWrap then setmetatable(Label, BaseAddons) end
        Groupbox:AddBlank(5); Groupbox:Resize()
        if type(ToolTip) == "string" then Library:AddToolTip(ToolTip, TL) end
        return Label
    end

    function Funcs:AddButton(...)
        local Button = {}
        local function PBP(_, Obj, ...)
            local Props = select(1, ...)
            if type(Props) == "table" then
                Obj.Text = Props.Text; Obj.Func = Props.Func
                Obj.DoubleClick = Props.DoubleClick; Obj.Tooltip = Props.Tooltip
            else
                Obj.Text = select(1, ...); Obj.Func = select(2, ...)
            end
            assert(type(Obj.Func) == "function", "AddButton: `Func` callback is missing.")
        end
        PBP("Button", Button, ...)
        local Groupbox = self
        local Container = Groupbox.Container
        local function CBB(B)
            local Outer = Library:Create("Frame", {
                BackgroundColor3 = Library.Border, BorderColor3 = Library.Border,
                Size = UDim2.new(1, -4, 0, 20), ZIndex = 5,
            })
            local Inner = Library:Create("Frame", {
                BackgroundColor3 = Library.ControlBG, BorderColor3 = Library.Outline,
                BorderMode = Enum.BorderMode.Inset, Size = UDim2.new(1, 0, 1, 0),
                ZIndex = 6, Parent = Outer,
            })
            local L = Library:CreateLabel({
                Size = UDim2.new(1, 0, 1, 0), TextSize = Library.FontSize,
                Text = B.Text, ZIndex = 6, Parent = Inner,
            })
            Library:AddToRegistry(Outer, { BorderColor3 = "Border" })
            Library:AddToRegistry(Inner, { BackgroundColor3 = "ControlBG", BorderColor3 = "Outline" })
            Outer.MouseEnter:Connect(function() Inner.BackgroundColor3 = Library.ControlHover end)
            Outer.MouseLeave:Connect(function() Inner.BackgroundColor3 = Library.ControlBG end)
            return Outer, Inner, L
        end
        Button.Outer, Button.Inner, Button.Label = CBB(Button)
        Button.Outer.Parent = Container
        Button.Outer.InputBegan:Connect(function(Input)
            if Input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
            if Library:MouseIsOverOpenedFrame() then return end
            Library:PlaySound(Library.Sounds.Click)
            Library:SafeCallback(Button.Func)
        end)
        function Button:AddTooltip(tip)
            if type(tip) == "string" then Library:AddToolTip(tip, self.Outer) end
            return self
        end
        function Button:AddButton(...)
            local Sub = {}
            PBP("SubButton", Sub, ...)
            self.Outer.Size = UDim2.new(0.5, -2, 0, 20)
            Sub.Outer, Sub.Inner, Sub.Label = CBB(Sub)
            Sub.Outer.Position = UDim2.new(1, 3, 0, 0)
            Sub.Outer.Size = UDim2.fromOffset(self.Outer.AbsoluteSize.X - 2, self.Outer.AbsoluteSize.Y)
            Sub.Outer.Parent = self.Outer
            Sub.Outer.InputBegan:Connect(function(Input)
                if Input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
                if Library:MouseIsOverOpenedFrame() then return end
                Library:PlaySound(Library.Sounds.Click)
                Library:SafeCallback(Sub.Func)
            end)
            return Sub
        end
        Groupbox:AddBlank(5); Groupbox:Resize()
        return Button
    end

    function Funcs:AddDivider()
        local G = self
        G:AddBlank(2)
        Library:Create("Frame", {
            BackgroundColor3 = Library.Divider, BorderSizePixel = 0,
            Size = UDim2.new(1, -4, 0, 1), ZIndex = 5, Parent = G.Container,
        })
        G:AddBlank(9); G:Resize()
    end

    function Funcs:AddInput(Index, Info)
        assert(Info.Text, "AddInput: Missing `Text` string.")
        local TB = {
            Value = Info.Default or "", Numeric = Info.Numeric or false,
            Finished = Info.Finished or false, Type = "Input",
            Callback = Info.Callback or function() end,
        }
        local G = self
        local C = G.Container
        Library:CreateLabel({
            Size = UDim2.new(1, 0, 0, 13), TextSize = 12, Text = Info.Text,
            TextColor3 = Library.FontMuted, TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 5, Parent = C,
        })
        G:AddBlank(1)
        local Outer = Library:Create("Frame", {
            BackgroundColor3 = Library.Border, BorderColor3 = Library.Border,
            Size = UDim2.new(1, -4, 0, 20), ZIndex = 5, Parent = C,
        })
        local Inner = Library:Create("Frame", {
            BackgroundColor3 = Library.ControlBG, BorderColor3 = Library.Outline,
            BorderMode = Enum.BorderMode.Inset, Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 6, Parent = Outer,
        })
        Library:AddToRegistry(Outer, { BorderColor3 = "Border" })
        Library:AddToRegistry(Inner, { BackgroundColor3 = "ControlBG", BorderColor3 = "Outline" })
        local Box = Library:Create("TextBox", {
            BackgroundTransparency = 1, Position = UDim2.new(0, 5, 0, 0),
            Size = UDim2.new(1, -10, 1, 0), Font = Library.Font,
            PlaceholderColor3 = Library.FontMuted, PlaceholderText = Info.Placeholder or "",
            Text = Info.Default or "", TextColor3 = Library.FontColor,
            TextSize = Library.FontSize, TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 7, Parent = Inner,
        })
        Library:AddToRegistry(Box, { TextColor3 = "FontColor" })
        function TB:SetValue(Text)
            if Info.MaxLength and #Text > Info.MaxLength then Text = Text:sub(1, Info.MaxLength) end
            if TB.Numeric and not tonumber(Text) and Text:len() > 0 then Text = TB.Value end
            TB.Value = Text; Box.Text = Text
            Library:SafeCallback(TB.Callback, TB.Value)
            Library:SafeCallback(TB.Changed, TB.Value)
        end
        if TB.Finished then
            Box.FocusLost:Connect(function(Enter) if Enter then TB:SetValue(Box.Text); Library:AttemptSave() end end)
        else
            Box:GetPropertyChangedSignal("Text"):Connect(function() TB:SetValue(Box.Text); Library:AttemptSave() end)
        end
        function TB:OnChanged(F) TB.Changed = F; F(TB.Value) end
        G:AddBlank(5); G:Resize()
        Options[Index] = TB
        return TB
    end

    -- ========================================================
    -- Toggle
    -- ========================================================
    function Funcs:AddToggle(Index, Info)
        assert(Info.Text, "AddToggle: Missing `Text` string.")
        local Toggle = {
            Value = Info.Default or false, Type = "Toggle",
            Callback = Info.Callback or function() end,
            Addons = {}, Risky = Info.Risky,
        }
        local G = self
        local C = G.Container

        local Row = Library:Create("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -4, 0, 16),
            ZIndex = 5, Parent = C,
        })

        local ToggleOuter = Library:Create("Frame", {
            BackgroundColor3 = Library.Border, BorderColor3 = Library.Border,
            Position = UDim2.new(0, 0, 0, 1),
            Size = UDim2.new(0, 14, 0, 14),
            ZIndex = 6, Parent = Row,
        })
        Library:AddToRegistry(ToggleOuter, { BorderColor3 = "Border" })

        local ToggleInner = Library:Create("Frame", {
            BackgroundColor3 = Library.ControlBG, BorderColor3 = Library.Outline,
            BorderMode = Enum.BorderMode.Inset,
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 7, Parent = ToggleOuter,
        })
        Library:AddToRegistry(ToggleInner, { BackgroundColor3 = "ControlBG", BorderColor3 = "Outline" })

        -- check mark (drawn with two lines so we don't depend on asset ids)
        local CheckA = Library:Create("Frame", {
            BackgroundColor3 = Color3.fromRGB(20, 20, 20), BorderSizePixel = 0,
            Position = UDim2.new(0, 3, 0, 5),
            Size = UDim2.new(0, 4, 0, 2),
            Rotation = 45, Visible = false, ZIndex = 8, Parent = ToggleInner,
        })
        local CheckB = Library:Create("Frame", {
            BackgroundColor3 = Color3.fromRGB(20, 20, 20), BorderSizePixel = 0,
            Position = UDim2.new(0, 5, 0, 3),
            Size = UDim2.new(0, 7, 0, 2),
            Rotation = -45, Visible = false, ZIndex = 8, Parent = ToggleInner,
        })

        local ToggleLabel = Library:CreateLabel({
            Size = UDim2.new(1, -22, 1, 0), Position = UDim2.new(0, 22, 0, 0),
            TextSize = Library.FontSize, Text = Info.Text,
            TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 6, Parent = Row,
        })
        Library:Create("UIListLayout", {
            Padding = UDim.new(0, 4), FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
            SortOrder = Enum.SortOrder.LayoutOrder, Parent = ToggleLabel,
        })

        local Region = Library:Create("Frame", {
            BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0),
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
            ToggleInner.BorderColor3 = on and Library.AccentDark or Library.Outline
            Library.RegistryMap[ToggleInner].Properties.BackgroundColor3 = on and "Accent" or "ControlBG"
            Library.RegistryMap[ToggleInner].Properties.BorderColor3 = on and "AccentDark" or "Outline"
            CheckA.Visible = on; CheckB.Visible = on
        end
        function Toggle:OnChanged(F) Toggle.Changed = F; F(Toggle.Value) end
        function Toggle:SetValue(Bool)
            Bool = (not not Bool)
            Toggle.Value = Bool
            Toggle:Display()
            for _, A in next, Toggle.Addons do
                if A.Type == "KeyPicker" and A.SyncToggleState then
                    A.Toggled = Bool; A:Update()
                end
            end
            Library:SafeCallback(Toggle.Callback, Toggle.Value)
            Library:SafeCallback(Toggle.Changed, Toggle.Value)
            Library:UpdateDependencyBoxes()
        end
        Region.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame() then
                Library:PlaySound(Library.Sounds.Click)
                Toggle:SetValue(not Toggle.Value); Library:AttemptSave()
            end
        end)
        if Toggle.Risky then
            Library:RemoveFromRegistry(ToggleLabel)
            ToggleLabel.TextColor3 = Library.RiskColor
            Library:AddToRegistry(ToggleLabel, { TextColor3 = "RiskColor" })
        end
        Toggle:Display()
        G:AddBlank(Info.BlankSize or 4)
        G:Resize()
        Toggle.TextLabel = ToggleLabel
        Toggle.Container = C
        setmetatable(Toggle, BaseAddons)
        Toggles[Index] = Toggle
        Library:UpdateDependencyBoxes()
        return Toggle
    end

    -- ========================================================
    -- Slider (dynamic width)
    -- ========================================================
    function Funcs:AddSlider(Index, Info)
        assert(Info.Default, "AddSlider: Missing default value.")
        assert(Info.Text, "AddSlider: Missing slider Text.")
        assert(Info.Min, "AddSlider: Missing minimum value.")
        assert(Info.Max, "AddSlider: Missing maximum value.")
        assert(Info.Rounding, "AddSlider: Missing rounding value.")

        local Slider = {
            Value = Info.Default, Min = Info.Min, Max = Info.Max,
            Rounding = Info.Rounding, MaxSize = 200, -- updated on layout
            Type = "Slider", Callback = Info.Callback or function() end,
        }
        local G = self
        local C = G.Container

        if not Info.Compact then
            Library:CreateLabel({
                Size = UDim2.new(1, 0, 0, 13), TextSize = 12, Text = Info.Text,
                TextColor3 = Library.FontMuted, TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Bottom, ZIndex = 5, Parent = C,
            })
            G:AddBlank(2)
        end

        local SliderOuter = Library:Create("Frame", {
            BackgroundColor3 = Library.Border, BorderColor3 = Library.Border,
            Size = UDim2.new(1, -4, 0, 15), ZIndex = 5, Parent = C,
        })
        Library:AddToRegistry(SliderOuter, { BorderColor3 = "Border" })

        local SliderInner = Library:Create("Frame", {
            BackgroundColor3 = Library.ControlBG, BorderColor3 = Library.Outline,
            BorderMode = Enum.BorderMode.Inset, Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 6, Parent = SliderOuter,
        })
        Library:AddToRegistry(SliderInner, { BackgroundColor3 = "ControlBG", BorderColor3 = "Outline" })

        local Fill = Library:Create("Frame", {
            BackgroundColor3 = Library.Accent, BorderSizePixel = 0,
            Size = UDim2.new(0, 0, 1, 0), ZIndex = 7, Parent = SliderInner,
        })
        Library:AddToRegistry(Fill, { BackgroundColor3 = "Accent" })

        local DisplayLabel = Library:CreateLabel({
            Size = UDim2.new(1, -6, 1, 0), Position = UDim2.new(0, 4, 0, 0),
            TextSize = 12, Text = "0",
            TextColor3 = Color3.fromRGB(20, 20, 20),
            TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 9, Parent = SliderInner,
        })

        function Slider:UpdateColors() Fill.BackgroundColor3 = Library.Accent end

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

        SliderInner:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
            Slider.MaxSize = math.max(1, SliderInner.AbsoluteSize.X)
            Slider:Display()
        end)
        task.defer(function()
            Slider.MaxSize = math.max(1, SliderInner.AbsoluteSize.X)
            Slider:Display()
        end)

        function Slider:OnChanged(F) Slider.Changed = F; F(Slider.Value) end
        local function Round(V)
            if Slider.Rounding == 0 then return math.floor(V) end
            return tonumber(string.format("%." .. Slider.Rounding .. "f", V))
        end
        function Slider:GetValueFromXOffset(X)
            return Round(Library:MapValue(X, 0, Slider.MaxSize, Slider.Min, Slider.Max))
        end
        function Slider:SetValue(Str)
            local N = tonumber(Str)
            if not N then return end
            N = math.clamp(N, Slider.Min, Slider.Max)
            Slider.Value = N; Slider:Display()
            Library:SafeCallback(Slider.Callback, Slider.Value)
            Library:SafeCallback(Slider.Changed, Slider.Value)
            Library:UpdateDependencyBoxes()
        end
        SliderInner.InputBegan:Connect(function(Input)
            if Input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
            if Library:MouseIsOverOpenedFrame() then return end
            local mp = Mouse.X
            local gPos = Fill.Size.X.Offset
            local Diff = mp - (Fill.AbsolutePosition.X + gPos)
            while UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                local nV = Slider:GetValueFromXOffset(math.clamp(gPos + (Mouse.X - mp) + Diff, 0, Slider.MaxSize))
                local oldV = Slider.Value
                Slider.Value = nV; Slider:Display()
                if nV ~= oldV then
                    Library:SafeCallback(Slider.Callback, Slider.Value)
                    Library:SafeCallback(Slider.Changed, Slider.Value)
                end
                RenderStepped:Wait()
            end
            Library:AttemptSave()
        end)

        Slider:Display()
        G:AddBlank(Info.BlankSize or 5)
        G:Resize()
        Options[Index] = Slider
        return Slider
    end

    -- ========================================================
    -- Dropdown
    -- ========================================================
    function Funcs:AddDropdown(Index, Info)
        if Info.SpecialType == "Player" then Info.Values = GetPlayersString(); Info.AllowNull = true
        elseif Info.SpecialType == "Team" then Info.Values = GetTeamsString(); Info.AllowNull = true end
        assert(Info.Values, "AddDropdown: Missing dropdown value list.")
        assert(Info.AllowNull or Info.Default, "AddDropdown: Missing default value.")
        if not Info.Text then Info.Compact = true end
        local Dropdown = {
            Values = Info.Values, Value = Info.Multi and {}, Multi = Info.Multi,
            Type = "Dropdown", SpecialType = Info.SpecialType,
            Callback = Info.Callback or function() end,
        }
        local G = self
        local C = G.Container
        if not Info.Compact then
            Library:CreateLabel({
                Size = UDim2.new(1, 0, 0, 13), TextSize = 12, Text = Info.Text,
                TextColor3 = Library.FontMuted, TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Bottom, ZIndex = 5, Parent = C,
            })
            G:AddBlank(2)
        end
        local Outer = Library:Create("Frame", {
            BackgroundColor3 = Library.Border, BorderColor3 = Library.Border,
            Size = UDim2.new(1, -4, 0, 20), ZIndex = 5, Parent = C,
        })
        Library:AddToRegistry(Outer, { BorderColor3 = "Border" })
        local Inner = Library:Create("Frame", {
            BackgroundColor3 = Library.ControlBG, BorderColor3 = Library.Outline,
            BorderMode = Enum.BorderMode.Inset, Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 6, Parent = Outer,
        })
        Library:AddToRegistry(Inner, { BackgroundColor3 = "ControlBG", BorderColor3 = "Outline" })
        local Chevron = Library:Create("ImageLabel", {
            AnchorPoint = Vector2.new(0, 0.5), BackgroundTransparency = 1,
            Position = UDim2.new(1, -14, 0.5, 0), Size = UDim2.new(0, 8, 0, 8),
            Image = "rbxassetid://6282522798", ImageColor3 = Library.FontMuted,
            ZIndex = 8, Parent = Inner,
        })
        Library:AddToRegistry(Chevron, { ImageColor3 = "FontMuted" })
        local ItemList = Library:CreateLabel({
            Position = UDim2.new(0, 6, 0, 0), Size = UDim2.new(1, -20, 1, 0),
            TextSize = Library.FontSize, Text = "--",
            TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true,
            ZIndex = 7, Parent = Inner,
        })
        local MAX_ITEMS = 8
        local ListOuter = Library:Create("Frame", {
            BackgroundColor3 = Library.Border, BorderColor3 = Library.Border,
            ZIndex = 20, Visible = false, Parent = ScreenGui,
        })
        local function RP()
            ListOuter.Position = UDim2.fromOffset(Outer.AbsolutePosition.X, Outer.AbsolutePosition.Y + Outer.Size.Y.Offset + 1)
        end
        local function RS(Y)
            ListOuter.Size = UDim2.fromOffset(Outer.AbsoluteSize.X, Y or (MAX_ITEMS * 20 + 2))
        end
        RP(); RS()
        Outer:GetPropertyChangedSignal("AbsolutePosition"):Connect(RP)
        local ListInner = Library:Create("Frame", {
            BackgroundColor3 = Library.SectionBG, BorderColor3 = Library.Outline,
            BorderMode = Enum.BorderMode.Inset, BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 1, 0), ZIndex = 21, Parent = ListOuter,
        })
        Library:AddToRegistry(ListInner, { BackgroundColor3 = "SectionBG", BorderColor3 = "Outline" })
        local Scrolling = Library:Create("ScrollingFrame", {
            BackgroundTransparency = 1, BorderSizePixel = 0,
            CanvasSize = UDim2.new(0, 0, 0, 0), Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 21, Parent = ListInner,
            TopImage = "", BottomImage = "",
            ScrollBarThickness = 3, ScrollBarImageColor3 = Library.Accent,
        })
        Library:AddToRegistry(Scrolling, { ScrollBarImageColor3 = "Accent" })
        Library:Create("UIListLayout", {
            Padding = UDim.new(0, 0), FillDirection = Enum.FillDirection.Vertical,
            SortOrder = Enum.SortOrder.LayoutOrder, Parent = Scrolling,
        })
        function Dropdown:Display()
            local S = ""
            if Info.Multi then
                for V in next, Dropdown.Values do
                    if Dropdown.Value[V] then S = S .. V .. ", " end
                end
                S = S:sub(1, #S - 2)
            else
                S = Dropdown.Value or ""
            end
            ItemList.Text = (S == "" and "--" or S)
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
            for _, E in next, Scrolling:GetChildren() do
                if not E:IsA("UIListLayout") then E:Destroy() end
            end
            local Count = 0
            for _, Value in next, Dropdown.Values do
                local Table = {}
                Count += 1
                local Btn = Library:Create("Frame", {
                    BackgroundColor3 = Library.SectionBG, BorderSizePixel = 0,
                    Size = UDim2.new(1, -1, 0, 20), ZIndex = 23, Active = true, Parent = Scrolling,
                })
                Library:AddToRegistry(Btn, { BackgroundColor3 = "SectionBG" })
                local BL = Library:CreateLabel({
                    Active = false, Size = UDim2.new(1, -6, 1, 0), Position = UDim2.new(0, 6, 0, 0),
                    TextSize = Library.FontSize, Text = Value,
                    TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 25, Parent = Btn,
                })
                Btn.MouseEnter:Connect(function() Btn.BackgroundColor3 = Library.ControlHover end)
                Btn.MouseLeave:Connect(function() Btn.BackgroundColor3 = Library.SectionBG end)
                local Sel
                if Info.Multi then Sel = Dropdown.Value[Value] else Sel = Dropdown.Value == Value end
                function Table:UpdateButton()
                    if Info.Multi then Sel = Dropdown.Value[Value] else Sel = Dropdown.Value == Value end
                    BL.TextColor3 = Sel and Library.Accent or Library.FontColor
                    Library.RegistryMap[BL].Properties.TextColor3 = Sel and "Accent" or "FontColor"
                end
                BL.InputBegan:Connect(function(Input)
                    if Input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
                    local Try = not Sel
                    if Dropdown:GetActiveValues() ~= 1 or Try or Info.AllowNull then
                        if Info.Multi then
                            Sel = Try
                            if Sel then Dropdown.Value[Value] = true else Dropdown.Value[Value] = nil end
                        else
                            Sel = Try
                            if Sel then Dropdown.Value = Value else Dropdown.Value = nil end
                            for _, O in next, Buttons do O:UpdateButton() end
                        end
                        Table:UpdateButton(); Dropdown:Display()
                        Library:SafeCallback(Dropdown.Callback, Dropdown.Value)
                        Library:SafeCallback(Dropdown.Changed, Dropdown.Value)
                        Library:AttemptSave(); Library:UpdateDependencyBoxes()
                    end
                end)
                Table:UpdateButton(); Dropdown:Display()
                Buttons[Btn] = Table
            end
            Scrolling.CanvasSize = UDim2.fromOffset(0, (Count * 20) + 1)
            RS(math.clamp(Count * 20, 0, MAX_ITEMS * 20) + 1)
        end
        function Dropdown:SetValues(NV) if NV then Dropdown.Values = NV end; Dropdown:BuildDropdownList() end
        function Dropdown:OpenDropdown() ListOuter.Visible = true; Library.OpenedFrames[ListOuter] = true; Chevron.Rotation = 180 end
        function Dropdown:CloseDropdown() ListOuter.Visible = false; Library.OpenedFrames[ListOuter] = nil; Chevron.Rotation = 0 end
        function Dropdown:OnChanged(F) Dropdown.Changed = F; F(Dropdown.Value) end
        function Dropdown:SetValue(Value)
            if Dropdown.Multi then
                local nT = {}
                for K in next, Value do if table.find(Dropdown.Values, K) then nT[K] = true end end
                Dropdown.Value = nT
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
        Dropdown:BuildDropdownList(); Dropdown:Display()
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
        Dropdown:BuildDropdownList(); Dropdown:Display()
        G:AddBlank(Info.BlankSize or 4); G:Resize()
        Library:UpdateDependencyBoxes()
        Options[Index] = Dropdown
        return Dropdown
    end

    function Funcs:AddPrioritySelector(Index, Info)
        assert(type(Info) == "table"); assert(type(Info.Default) == "table")
        local G = self; local C = G.Container
        local IH, IG = 20, 2
        local RowH = IH + IG
        local Total = #Info.Default
        local ListH = IH * Total + IG * math.max(0, Total - 1)
        local TitleH = (Info.Text and Info.Text ~= "") and 15 or 0
        local WH = TitleH + ListH
        local Items, Ordered = {}, {}
        for i, v in ipairs(Info.Default) do Ordered[i] = v end
        local PS = { Type = "PrioritySelector", Value = Ordered, Callback = Info.Callback or function() end }
        local W = Library:Create("Frame", {
            BackgroundTransparency = 1, Size = UDim2.new(1, -4, 0, WH),
            ZIndex = 5, Parent = C,
        })
        if TitleH > 0 then
            Library:CreateLabel({
                Size = UDim2.new(1, 0, 0, TitleH - 1), TextSize = 12,
                Text = Info.Text, TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 6, Parent = W,
            })
        end
        local LF = Library:Create("Frame", {
            BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0, TitleH),
            Size = UDim2.new(1, 0, 0, ListH), ZIndex = 5, Parent = W,
        })
        local function SlotY(i) return (i - 1) * RowH end
        local function Snap()
            for i, f in ipairs(Items) do f.Position = UDim2.new(0, 0, 0, SlotY(i)) end
        end
        local function Fire()
            local Ord = {}
            for i, f in ipairs(Items) do Ord[i] = f.Name end
            Ordered = Ord; PS.Value = Ord
            Library:SafeCallback(PS.Callback, Ord)
        end
        local Drag = { Active = false }
        for i, v in ipairs(Ordered) do
            local Item = Library:Create("Frame", {
                Name = v, BackgroundColor3 = Library.ControlBG, BorderColor3 = Library.Outline,
                Position = UDim2.new(0, 0, 0, SlotY(i)), Size = UDim2.new(1, 0, 0, IH),
                ZIndex = 6, Parent = LF,
            })
            Library:AddToRegistry(Item, { BackgroundColor3 = "ControlBG", BorderColor3 = "Outline" })
            Library:CreateLabel({
                Size = UDim2.new(0, 16, 1, 0), Position = UDim2.new(0, 2, 0, 0),
                TextSize = 12, Text = tostring(i) .. ".", ZIndex = 7, Parent = Item,
            })
            Library:CreateLabel({
                Size = UDim2.new(1, -30, 1, 0), Position = UDim2.new(0, 19, 0, 0),
                TextSize = 13, Text = v, TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 7, Parent = Item,
            })
            Item.InputBegan:Connect(function(Input)
                if Input.UserInputType ~= Enum.UserInputType.MouseButton1 or Drag.Active then return end
                local SI = table.find(Items, Item)
                if not SI then return end
                Drag.Active = true
                Drag.SY = Mouse.Y
                Drag.SSlot = SlotY(SI)
                local M, E
                M = UserInputService.InputChanged:Connect(function(Input)
                    if Input.UserInputType ~= Enum.UserInputType.MouseMovement then return end
                    local cy = math.clamp(Drag.SSlot + (Mouse.Y - Drag.SY), 0, ListH - IH)
                    Item.Position = UDim2.new(0, 0, 0, cy)
                    local Cc = cy + IH * 0.5
                    local TI = math.clamp(math.floor(Cc / RowH) + 1, 1, Total)
                    local DI = table.find(Items, Item)
                    if DI and TI ~= DI then
                        table.remove(Items, DI)
                        table.insert(Items, TI, Item)
                        for j, f in ipairs(Items) do
                            if f ~= Item then f.Position = UDim2.new(0, 0, 0, SlotY(j)) end
                        end
                    end
                end)
                E = UserInputService.InputEnded:Connect(function(Input)
                    if Input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
                    M:Disconnect(); E:Disconnect()
                    Drag.Active = false; Snap(); Fire()
                end)
            end)
            Items[i] = Item
        end
        if Index then Options[Index] = PS end
        G:AddBlank(5); G:Resize()
        return PS
    end

    function Funcs:AddDependencyBox()
        local D = { Dependencies = {} }
        local G = self
        local C = G.Container
        local Holder = Library:Create("Frame", {
            BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0),
            Visible = false, Parent = C,
        })
        local F = Library:Create("Frame", {
            BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0),
            Visible = true, Parent = Holder,
        })
        local L = Library:Create("UIListLayout", {
            FillDirection = Enum.FillDirection.Vertical,
            SortOrder = Enum.SortOrder.LayoutOrder, Parent = F,
        })
        function D:Resize()
            Holder.Size = UDim2.new(1, 0, 0, L.AbsoluteContentSize.Y)
            G:Resize()
        end
        L:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() D:Resize() end)
        Holder:GetPropertyChangedSignal("Visible"):Connect(function() D:Resize() end)
        function D:Update()
            for _, Dep in next, D.Dependencies do
                local E, V = Dep[1], Dep[2]
                local Match = false
                if type(V) == "table" then
                    for _, v in ipairs(V) do if E.Value == v then Match = true; break end end
                else
                    Match = (E.Value == V)
                end
                if not Match then Holder.Visible = false; D:Resize(); return end
            end
            Holder.Visible = true; D:Resize()
            if not Holder.Visible then Library:UpdateDependencyBoxes() end
        end
        function D:SetupDependencies(Deps)
            for _, Dep in next, Deps do
                assert(type(Dep) == "table"); assert(Dep[1]); assert(Dep[2] ~= nil)
            end
            D.Dependencies = Deps; D:Update()
            return self
        end
        D.Container = F
        setmetatable(D, BaseGroupbox)
        table.insert(Library.DependencyBoxes, D)
        return D
    end

    function Funcs:CreateConfigurationManager(BasePath, Extension, TablesToSave)
        local CF = BasePath .. "/Configs"
        local AF = BasePath .. "/Autoload" .. Extension
        local CM = { CurrentConfigurationProfile = "", Buttons = {} }
        local function SV(v)
            if type(v) == "table" then
                local D = {}
                for k, vv in next, v do D[k] = SV(vv) end
                return D
            end
            return typeof(v) == "Color3" and { Type = "Color3", Hex = v:ToHex() } or v
        end
        local function DR(c, d)
            if type(d) == "table" and d.Type == "Color3" and d.Hex then
                return Color3.fromHex(d.Hex)
            elseif type(c) == "table" and type(d) == "table" then
                table.clear(c)
                for k, v in next, d do c[k] = DR(c[k], v) end
                return c
            else return d end
        end
        local function GC()
            if not isfolder(CF) then makefolder(CF) end
            local t = {}
            for _, fp in ipairs(listfiles(CF)) do
                local n = fp:match("([^/\\]+)$")
                if n and n:match("%" .. Extension .. "$") then
                    table.insert(t, (n:gsub("%" .. Extension .. "$", "")))
                end
            end
            return t
        end
        local function LP(Name)
            local P = CF .. "/" .. Name .. Extension
            local Content = isfile(P) and readfile(P)
            if not Content or #Content <= 0 then return end
            local ok, Data = pcall(HttpService.JSONDecode, HttpService, Content)
            if ok then
                for _, Conf in ipairs(TablesToSave) do
                    for Setting in next, Conf do
                        if string.find(string.lower(Setting), "inactive") then continue end
                        local V = Data[Setting]
                        if V == nil then continue end
                        Conf[Setting] = DR(Conf[Setting], V)
                        task.defer(function()
                            if Toggles[Setting] then Toggles[Setting]:SetValue(Conf[Setting])
                            elseif Options[Setting] then
                                if Options[Setting].Type == "ColorPicker" then
                                    Options[Setting]:SetValueRGB(Conf[Setting], Data[Setting .. "Transparency"])
                                elseif Options[Setting].Type == "KeyPicker" then
                                    Options[Setting]:SetValue({Conf[Setting], Data[Setting .. "Mode"] or "Toggle"})
                                else Options[Setting]:SetValue(Conf[Setting]) end
                            end
                        end)
                    end
                end
            end
        end
        self:AddInput("ConfigurationInput", {
            Text = "Configuration Profile", Default = "", Placeholder = "Name",
            Numeric = false, Finished = false,
            Callback = function(V) CM.CurrentConfigurationProfile = V end,
        })
        self:AddDropdown("ConfigurationDropdown", {
            Text = "Profiles", Default = "", Values = GC(),
            Callback = function(V)
                CM.CurrentConfigurationProfile = V
                if Options.ConfigurationInput then Options.ConfigurationInput:SetValue(V) end
                if CM.Buttons.SetAutoload and CM.Buttons.RemoveAutoload then
                    local A = isfile(AF) and readfile(AF) == V
                    CM.Buttons.SetAutoload.Outer.Visible = not A
                    CM.Buttons.RemoveAutoload.Outer.Visible = A
                end
            end,
        })
        local function Save()
            local N = CM.CurrentConfigurationProfile
            if N == "" then return end
            local Data = {}
            for _, T in ipairs(TablesToSave) do
                for S, V in next, T do
                    if S == "MenuToggleKeybind" then continue end
                    Data[S] = SV(V)
                end
            end
            for I, O in next, Library.Options do
                if type(O) == "table" and type(O.Type) == "string" then
                    if O.Type == "KeyPicker" and type(O.Mode) == "string" then Data[I .. "Mode"] = O.Mode
                    elseif O.Type == "ColorPicker" then Data[I .. "Transparency"] = O.Transparency or 0 end
                end
            end
            if not isfolder(CF) then makefolder(CF) end
            writefile(CF .. "/" .. N .. Extension, HttpService:JSONEncode(Data))
            Library:Notify("Saved Configuration Profile: " .. N, 3)
            Options.ConfigurationDropdown:SetValues(GC())
            Options.ConfigurationDropdown:SetValue(N)
        end
        self:AddButton({ Text = "Save", Func = Save }):AddButton({
            Text = "Load",
            Func = function()
                local N = CM.CurrentConfigurationProfile
                if N == "" then return end
                LP(N)
                Library:Notify("Loaded Configuration Profile: " .. N, 3)
            end,
        })
        self:AddButton({ Text = "Delete", Func = function()
            local N = CM.CurrentConfigurationProfile
            if N == "" then return end
            local P = CF .. "/" .. N .. Extension
            if isfile(P) then
                delfile(P)
                Library:Notify("Deleted config: " .. N, 3)
                if isfile(AF) and readfile(AF) == N then delfile(AF) end
                CM.CurrentConfigurationProfile = ""
                Options.ConfigurationInput:SetValue("")
                Options.ConfigurationDropdown:SetValues(GC())
                Options.ConfigurationDropdown:SetValue(nil)
            end
        end }):AddButton({ Text = "Refresh List", Func = function() Options.ConfigurationDropdown:SetValues(GC()) end })
        CM.Buttons.SetAutoload = self:AddButton({ Text = "Set as Autoload", Func = function()
            local N = CM.CurrentConfigurationProfile
            if N == "" then return end
            writefile(AF, N)
            Library:Notify("Set " .. N .. " as Autoload.", 3)
            CM.Buttons.SetAutoload.Outer.Visible = false
            CM.Buttons.RemoveAutoload.Outer.Visible = true
        end })
        CM.Buttons.RemoveAutoload = self:AddButton({ Text = "Remove Autoload", Func = function()
            if isfile(AF) then
                delfile(AF)
                Library:Notify("Removed Configuration Profile from Autoload.", 3)
            end
            CM.Buttons.SetAutoload.Outer.Visible = true
            CM.Buttons.RemoveAutoload.Outer.Visible = false
        end })
        CM.Buttons.RemoveAutoload.Outer.Visible = false
        return function()
            if isfile(AF) then
                local N = readfile(AF)
                if N and N ~= "" then
                    LP(N)
                    Library:Notify("Profile '" .. N .. "' was loaded successfully.", 3)
                    Options.ConfigurationDropdown:SetValue(N)
                end
            end
        end
    end

    BaseGroupbox.__index = Funcs
    BaseGroupbox.__namecall = function(_, K, ...) return Funcs[K](...) end
end

-- ============================================================
-- HUD (Notifications / Watermark / Keybind list)
-- ============================================================
do
    Library.NotificationArea = Library:Create("Frame", {
        BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0, 40),
        Size = UDim2.new(0, 300, 0, 200), ZIndex = 100, Parent = ScreenGui,
    })
    Library:Create("UIListLayout", {
        Padding = UDim.new(0, 4), FillDirection = Enum.FillDirection.Vertical,
        SortOrder = Enum.SortOrder.LayoutOrder, Parent = Library.NotificationArea,
    })

    local WOuter = Library:Create("Frame", {
        BackgroundColor3 = Library.Border, BorderColor3 = Library.Border,
        Position = UDim2.new(0, 100, 0, -25), Size = UDim2.new(0, 213, 0, 18),
        ZIndex = 200, Visible = false, Parent = ScreenGui,
    })
    local WInner = Library:Create("Frame", {
        BackgroundColor3 = Library.SectionBG, BorderColor3 = Library.Accent,
        BorderMode = Enum.BorderMode.Inset, Size = UDim2.new(1, 0, 1, 0),
        ZIndex = 201, Parent = WOuter,
    })
    Library:AddToRegistry(WInner, { BorderColor3 = "Accent" })
    local WLabel = Library:CreateLabel({
        Position = UDim2.new(0, 6, 0, 0), Size = UDim2.new(1, -4, 1, 0),
        TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 203, Parent = WInner,
    })
    Library.Watermark = WOuter
    Library.WatermarkText = WLabel
    Library:MakeDraggable(WOuter)

    local KOuter = Library:Create("Frame", {
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundColor3 = Library.Border, BorderColor3 = Library.Border,
        Position = UDim2.new(0, 10, 0.5, 0), Size = UDim2.new(0, 210, 0, 20),
        Visible = false, ZIndex = 100, Parent = ScreenGui,
    })
    local KInner = Library:Create("Frame", {
        BackgroundColor3 = Library.SectionBG, BorderColor3 = Library.Outline,
        BorderMode = Enum.BorderMode.Inset, Size = UDim2.new(1, 0, 1, 0),
        ZIndex = 101, Parent = KOuter,
    })
    Library:AddToRegistry(KInner, { BackgroundColor3 = "SectionBG", BorderColor3 = "Outline" }, true)
    Library:Create("Frame", {
        BackgroundColor3 = Library.Accent, BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 2), ZIndex = 102, Parent = KInner,
    })
    Library:CreateLabel({
        Size = UDim2.new(1, 0, 0, 20), Position = UDim2.fromOffset(6, 2),
        TextXAlignment = Enum.TextXAlignment.Left, Text = "Keybinds",
        TextColor3 = Library.FontMuted, ZIndex = 104, Parent = KInner,
    })
    local KC = Library:Create("Frame", {
        BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, -20),
        Position = UDim2.new(0, 0, 0, 20), ZIndex = 1, Parent = KInner,
    })
    Library:Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        SortOrder = Enum.SortOrder.LayoutOrder, Parent = KC,
    })
    Library:Create("UIPadding", { PaddingLeft = UDim.new(0, 6), Parent = KC })
    Library.KeybindFrame = KOuter
    Library.KeybindContainer = KC
    Library:MakeDraggable(KOuter)
end

function Library:SetWatermarkVisibility(v) Library.Watermark.Visible = v end
function Library:SetWatermark(Text)
    local X, Y = Library:GetTextBounds(Text, Library.Font, 12)
    Library.Watermark.Size = UDim2.new(0, X + 15, 0, (Y * 1.5) + 3)
    Library:SetWatermarkVisibility(true)
    Library.WatermarkText.Text = Text
end

function Library:Notify(Text, Time)
    local XS, YS = Library:GetTextBounds(Text, Library.Font, 12)
    YS += 7
    local NO = Library:Create("Frame", {
        BackgroundColor3 = Library.Border, BorderColor3 = Library.Border,
        Position = UDim2.new(0, 100, 0, 10), Size = UDim2.new(0, 0, 0, YS),
        ClipsDescendants = true, ZIndex = 100, Parent = Library.NotificationArea,
    })
    local NI = Library:Create("Frame", {
        BackgroundColor3 = Library.SectionBG, BorderColor3 = Library.Outline,
        BorderMode = Enum.BorderMode.Inset, Size = UDim2.new(1, 0, 1, 0),
        ZIndex = 101, Parent = NO,
    })
    Library:AddToRegistry(NI, { BackgroundColor3 = "SectionBG", BorderColor3 = "Outline" }, true)
    Library:CreateLabel({
        Position = UDim2.new(0, 8, 0, 0), Size = UDim2.new(1, -4, 1, 0),
        Text = Text, TextXAlignment = Enum.TextXAlignment.Left,
        TextSize = 12, ZIndex = 103, Parent = NI,
    })
    Library:Create("Frame", {
        BackgroundColor3 = Library.Accent, BorderSizePixel = 0,
        Size = UDim2.new(0, 3, 1, 0), ZIndex = 104, Parent = NI,
    })
    pcall(NO.TweenSize, NO, UDim2.new(0, XS + 12, 0, YS), "Out", "Quad", 0.4, true)
    task.spawn(function()
        task.wait(Time or 5)
        pcall(NO.TweenSize, NO, UDim2.new(0, 0, 0, YS), "Out", "Quad", 0.4, true)
        task.wait(0.4)
        NO:Destroy()
    end)
end

-- ============================================================
-- Window & Tabs
-- ============================================================
local TabIcons = {
    ["Aiming"]        = "rbxassetid://6031090990",
    ["Visuals"]       = "rbxassetid://6031094667",
    ["World"]         = "rbxassetid://6031094682",
    ["Miscellaneous"] = "rbxassetid://6031094660",
    ["Settings"]      = "rbxassetid://6031280882",
}

function Library:CreateWindow(Configuration, _IsParallel)
    if type(Configuration.Title) ~= "string" then Configuration.Title = "No title" end
    if type(Configuration.MenuFadeTime) ~= "number" then Configuration.MenuFadeTime = 0.2 end
    Configuration.AnchorPoint = Vector2.new(0.5, 0.5)
    Configuration.Position = UDim2.fromScale(0.5, 0.5)
    if typeof(Configuration.Size) ~= "UDim2" then Configuration.Size = UDim2.fromOffset(620, 520) end

    local Window = { Tabs = {} }

    local Outer = Library:Create("Frame", {
        AnchorPoint = Configuration.AnchorPoint,
        BackgroundColor3 = Library.Border, BorderSizePixel = 0,
        Position = Configuration.Position, Size = Configuration.Size,
        Visible = false, ZIndex = 1, Parent = ScreenGui,
    })
    Library:MakeDraggable(Outer, 26)

    local BorderInner = Library:Create("Frame", {
        BackgroundColor3 = Library.WindowBG, BorderSizePixel = 0,
        Position = UDim2.new(0, 1, 0, 1), Size = UDim2.new(1, -2, 1, -2),
        ZIndex = 2, Parent = Outer,
    })

    local Header = Library:Create("Frame", {
        BackgroundColor3 = Library.HeaderBG, BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 24), ZIndex = 3, Parent = BorderInner,
    })
    local WL = Library:CreateLabel({
        Position = UDim2.new(0, 10, 0, 0), Size = UDim2.new(1, -80, 1, 0),
        Text = Configuration.Title, TextColor3 = Library.Accent,
        TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 4, Parent = Header,
    })
    Library:AddToRegistry(WL, { TextColor3 = "Accent" })

    local Body = Library:Create("Frame", {
        BackgroundColor3 = Library.WindowBG, BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 24), Size = UDim2.new(1, 0, 1, -24),
        ZIndex = 3, Parent = BorderInner,
    })

    local Sidebar = Library:Create("Frame", {
        BackgroundColor3 = Library.SidebarBG, BorderSizePixel = 0,
        Size = UDim2.new(0, 44, 1, 0), ZIndex = 4, Parent = Body,
    })
    Library:Create("UIListLayout", {
        Padding = UDim.new(0, 4), FillDirection = Enum.FillDirection.Vertical,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        SortOrder = Enum.SortOrder.LayoutOrder, Parent = Sidebar,
    })
    Library:Create("UIPadding", { PaddingTop = UDim.new(0, 6), Parent = Sidebar })

    local Content = Library:Create("Frame", {
        BackgroundColor3 = Library.WindowBG, BorderSizePixel = 0,
        Position = UDim2.new(0, 44, 0, 0), Size = UDim2.new(1, -44, 1, 0),
        ZIndex = 4, Parent = Body,
    })

    local SubHeader = Library:Create("Frame", {
        BackgroundColor3 = Library.SectionBG, BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 20), ZIndex = 5, Parent = Content,
    })
    local SubHeaderTitle = Library:CreateLabel({
        Position = UDim2.new(0, 10, 0, 0), Size = UDim2.new(1, -10, 1, 0),
        Text = "", TextXAlignment = Enum.TextXAlignment.Left,
        TextSize = 12, TextColor3 = Library.FontColor,
        ZIndex = 6, Parent = SubHeader,
    })

    local TabContainer = Library:Create("Frame", {
        BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0, 20),
        Size = UDim2.new(1, 0, 1, -20), ZIndex = 5, Parent = Content,
    })

    function Window:SetWindowTitle(T) WL.Text = T end

    function Window:AddTab(Name, Icon)
        local Tab = { Groupboxes = {}, Tabboxes = {} }

        local IB = Library:Create("Frame", {
            BackgroundColor3 = Library.SidebarBG, BorderSizePixel = 0,
            Size = UDim2.new(0, 32, 0, 32), ZIndex = 5, Parent = Sidebar,
        })
        local II = Library:Create("ImageLabel", {
            BackgroundTransparency = 1, Position = UDim2.new(0, 6, 0, 6),
            Size = UDim2.new(0, 20, 0, 20),
            Image = Icon or TabIcons[Name] or "rbxassetid://6031090990",
            ImageColor3 = Library.FontMuted, ZIndex = 6, Parent = IB,
        })
        Library:AddToRegistry(II, { ImageColor3 = "FontMuted" })
        local IAcc = Library:Create("Frame", {
            BackgroundColor3 = Library.Accent, BorderSizePixel = 0,
            Position = UDim2.new(0, 0, 0, 0), Size = UDim2.new(0, 2, 1, 0),
            Visible = false, ZIndex = 7, Parent = IB,
        })
        Library:AddToRegistry(IAcc, { BackgroundColor3 = "Accent" })

        local TabFrame = Library:Create("Frame", {
            Name = "TabFrame", BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0), Visible = false,
            ZIndex = 2, Parent = TabContainer,
        })
        local LS = Library:Create("ScrollingFrame", {
            BackgroundTransparency = 1, BorderSizePixel = 0,
            Position = UDim2.new(0, 8, 0, 8), Size = UDim2.new(0.5, -12, 1, -16),
            CanvasSize = UDim2.new(0, 0, 0, 0), BottomImage = "", TopImage = "",
            ScrollBarThickness = 0, ZIndex = 2, Parent = TabFrame,
        })
        local RS = Library:Create("ScrollingFrame", {
            BackgroundTransparency = 1, BorderSizePixel = 0,
            Position = UDim2.new(0.5, 4, 0, 8), Size = UDim2.new(0.5, -12, 1, -16),
            CanvasSize = UDim2.new(0, 0, 0, 0), BottomImage = "", TopImage = "",
            ScrollBarThickness = 0, ZIndex = 2, Parent = TabFrame,
        })
        Library:Create("UIListLayout", {
            Padding = UDim.new(0, 8), FillDirection = Enum.FillDirection.Vertical,
            SortOrder = Enum.SortOrder.LayoutOrder,
            HorizontalAlignment = Enum.HorizontalAlignment.Center, Parent = LS,
        })
        Library:Create("UIListLayout", {
            Padding = UDim.new(0, 8), FillDirection = Enum.FillDirection.Vertical,
            SortOrder = Enum.SortOrder.LayoutOrder,
            HorizontalAlignment = Enum.HorizontalAlignment.Center, Parent = RS,
        })
        for _, S in next, { LS, RS } do
            S:WaitForChild("UIListLayout"):GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                S.CanvasSize = UDim2.fromOffset(0, S.UIListLayout.AbsoluteContentSize.Y)
            end)
        end

        function Tab:ShowTab()
            for _, T in next, Window.Tabs do T:HideTab() end
            IAcc.Visible = true
            IB.BackgroundColor3 = Library.ControlBG
            II.ImageColor3 = Library.Accent
            Library.RegistryMap[II].Properties.ImageColor3 = "Accent"
            TabFrame.Visible = true
            SubHeaderTitle.Text = Name
        end
        function Tab:HideTab()
            IAcc.Visible = false
            IB.BackgroundColor3 = Library.SidebarBG
            II.ImageColor3 = Library.FontMuted
            Library.RegistryMap[II].Properties.ImageColor3 = "FontMuted"
            TabFrame.Visible = false
        end
        function Tab:SetLayoutOrder(p) IB.LayoutOrder = p end

        function Tab:AddGroupbox(Info)
            local GB = {}
            local BO = Library:Create("Frame", {
                BackgroundColor3 = Library.PanelBG, BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 24), ZIndex = 2,
                Parent = Info.Side == 1 and LS or RS,
            })
            Library:AddToRegistry(BO, { BackgroundColor3 = "PanelBG" })

            local HS = Library:Create("Frame", {
                BackgroundColor3 = Library.SectionBG, BorderSizePixel = 0,
                Position = UDim2.new(0, 0, 0, 0), Size = UDim2.new(1, 0, 0, 20),
                ZIndex = 4, Parent = BO,
            })
            Library:CreateLabel({
                Size = UDim2.new(1, 0, 1, 0), Position = UDim2.new(0, 8, 0, 0),
                TextSize = 12, Text = Info.Name, TextColor3 = Library.FontColor,
                Font = Library.FontBold, TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 5, Parent = HS,
            })
            Library:Create("Frame", {
                BackgroundColor3 = Library.Accent, BorderSizePixel = 0,
                Position = UDim2.new(0, 0, 0, 0), Size = UDim2.new(0, 2, 1, 0),
                ZIndex = 5, Parent = HS,
            })

            local C = Library:Create("Frame", {
                BackgroundTransparency = 1, Position = UDim2.new(0, 8, 0, 24),
                Size = UDim2.new(1, -16, 1, -24), ZIndex = 1, Parent = BO,
            })
            Library:Create("UIListLayout", {
                FillDirection = Enum.FillDirection.Vertical,
                SortOrder = Enum.SortOrder.LayoutOrder, Parent = C,
            })

            function GB:Resize()
                local Size = 0
                for _, E in next, GB.Container:GetChildren() do
                    if not E:IsA("UIListLayout") and E.Visible then
                        Size = Size + E.Size.Y.Offset
                    end
                end
                BO.Size = UDim2.new(1, 0, 0, 24 + Size + 8)
            end
            GB.Container = C
            setmetatable(GB, BaseGroupbox)
            GB:AddBlank(4)
            GB:Resize()
            Tab.Groupboxes[Info.Name] = GB
            return GB
        end
        function Tab:AddLeftGroupbox(Name) return Tab:AddGroupbox({ Side = 1, Name = Name }) end
        function Tab:AddRightGroupbox(Name) return Tab:AddGroupbox({ Side = 2, Name = Name }) end

        function Tab:AddTabbox(Info)
            local Tabbox = { Tabs = {} }
            local BO = Library:Create("Frame", {
                BackgroundColor3 = Library.PanelBG, BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 24), ZIndex = 2,
                Parent = Info.Side == 1 and LS or RS,
            })
            Library:AddToRegistry(BO, { BackgroundColor3 = "PanelBG" })
            local HS = Library:Create("Frame", {
                BackgroundColor3 = Library.SectionBG, BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 20), ZIndex = 4, Parent = BO,
            })
            local TB = Library:Create("Frame", {
                BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0),
                ZIndex = 5, Parent = HS,
            })
            Library:Create("UIListLayout", {
                FillDirection = Enum.FillDirection.Horizontal,
                HorizontalAlignment = Enum.HorizontalAlignment.Left,
                SortOrder = Enum.SortOrder.LayoutOrder, Parent = TB,
            })
            function Tabbox:AddTab(Name)
                local T = {}
                local B = Library:Create("Frame", {
                    BackgroundColor3 = Library.SectionBG, BorderSizePixel = 0,
                    Size = UDim2.new(0, 90, 1, 0), ZIndex = 6, Parent = TB,
                })
                Library:AddToRegistry(B, { BackgroundColor3 = "SectionBG" })
                local BL = Library:CreateLabel({
                    Size = UDim2.new(1, 0, 1, 0), TextSize = 12, Text = Name,
                    TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 7, Parent = B,
                })
                local UL = Library:Create("Frame", {
                    BackgroundColor3 = Library.Accent, BorderSizePixel = 0,
                    Position = UDim2.new(0, 0, 1, -1), Size = UDim2.new(1, 0, 0, 1),
                    Visible = false, ZIndex = 9, Parent = B,
                })
                local C = Library:Create("Frame", {
                    BackgroundTransparency = 1, Position = UDim2.new(0, 8, 0, 24),
                    Size = UDim2.new(1, -16, 1, -24), ZIndex = 1,
                    Visible = false, Parent = BO,
                })
                Library:Create("UIListLayout", {
                    FillDirection = Enum.FillDirection.Vertical,
                    SortOrder = Enum.SortOrder.LayoutOrder, Parent = C,
                })
                function T:Show()
                    for _, O in next, Tabbox.Tabs do O:Hide() end
                    C.Visible = true; UL.Visible = true
                    BL.TextColor3 = Library.Accent
                    Library.RegistryMap[BL].Properties.TextColor3 = "Accent"
                    T:Resize()
                end
                function T:Hide()
                    C.Visible = false; UL.Visible = false
                    BL.TextColor3 = Library.FontColor
                    Library.RegistryMap[BL].Properties.TextColor3 = "FontColor"
                end
                function T:Resize()
                    local Ct = 0
                    for _ in next, Tabbox.Tabs do Ct = Ct + 1 end
                    for _, b in next, TB:GetChildren() do
                        if not b:IsA("UIListLayout") then b.Size = UDim2.new(1 / Ct, 0, 1, 0) end
                    end
                    if not C.Visible then return end
                    local S = 0
                    for _, E in next, T.Container:GetChildren() do
                        if not E:IsA("UIListLayout") and E.Visible then S = S + E.Size.Y.Offset end
                    end
                    BO.Size = UDim2.new(1, 0, 0, 24 + S + 8)
                end
                B.InputBegan:Connect(function(Input)
                    if Input.UserInputType == Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame() then
                        T:Show(); T:Resize()
                    end
                end)
                T.Container = C
                Tabbox.Tabs[Name] = T
                setmetatable(T, BaseGroupbox)
                T:AddBlank(3); T:Resize()
                if #TB:GetChildren() == 2 then T:Show() end
                return T
            end
            Tab.Tabboxes[Info.Name or ""] = Tabbox
            return Tabbox
        end
        function Tab:AddLeftTabbox(Name) return Tab:AddTabbox({ Name = Name, Side = 1 }) end
        function Tab:AddRightTabbox(Name) return Tab:AddTabbox({ Name = Name, Side = 2 }) end

        IB.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 then Tab:ShowTab() end
        end)
        IB.MouseEnter:Connect(function()
            if not IAcc.Visible then IB.BackgroundColor3 = Library.ControlBG end
        end)
        IB.MouseLeave:Connect(function()
            if not IAcc.Visible then IB.BackgroundColor3 = Library.SidebarBG end
        end)

        if #TabContainer:GetChildren() == 0 then Tab:ShowTab() end
        Window.Tabs[Name] = Tab
        return Tab
    end

    -- ------------------------------------------------------------------
    -- Toggle: NO transparency loop. Just show/hide.
    -- ------------------------------------------------------------------
    local WindowOpen = false
    function Library:Toggle()
        WindowOpen = not WindowOpen
        Library.Toggled = WindowOpen
        Outer.Visible = WindowOpen

        for M in next, Library.ModeSelectOuters do M.Visible = false end

        if WindowOpen then
            task.spawn(function()
                local State = UserInputService.MouseIconEnabled
                local Cursor = Drawing.new("Triangle")
                Cursor.Thickness = 1; Cursor.Filled = true; Cursor.Visible = true
                local Outline = Drawing.new("Triangle")
                Outline.Thickness = 1; Outline.Filled = false
                Outline.Color = Color3.new(0, 0, 0); Outline.Visible = true
                while WindowOpen and ScreenGui.Parent do
                    UserInputService.MouseIconEnabled = false
                    local mp = UserInputService:GetMouseLocation()
                    Cursor.Color = Library.Accent
                    Cursor.PointA = Vector2.new(mp.X, mp.Y)
                    Cursor.PointB = Vector2.new(mp.X + 14, mp.Y + 5)
                    Cursor.PointC = Vector2.new(mp.X + 5, mp.Y + 14)
                    Outline.PointA = Cursor.PointA
                    Outline.PointB = Cursor.PointB
                    Outline.PointC = Cursor.PointC
                    RenderStepped:Wait()
                end
                UserInputService.MouseIconEnabled = State
                Cursor:Remove(); Outline:Remove()
            end)
        end
    end

    UserInputService.InputBegan:Connect(function(Input, Processed)
        if type(Library.ToggleKeybind) == "table" and Library.ToggleKeybind.Type == "KeyPicker" then
            if Input.UserInputType == Enum.UserInputType.Keyboard and Input.KeyCode.Name == Library.ToggleKeybind.Value then
                Library:Toggle()
            end
        elseif Input.KeyCode == Enum.KeyCode.RightControl or (Input.KeyCode == Enum.KeyCode.RightShift and not Processed) then
            Library:Toggle()
        end
    end)

    Window.Holder = Outer
    return Window
end

local function OnPlayerChange()
    local PL = GetPlayersString()
    for _, V in next, Options do
        if V.Type == "Dropdown" and V.SpecialType == "Player" then V:SetValues(PL) end
    end
end
Players.PlayerAdded:Connect(OnPlayerChange)
Players.PlayerRemoving:Connect(OnPlayerChange)

getgenv().Library = Library
return Library
