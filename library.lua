--[[
    This is a modified version of Linoria Library, credits to the dev(s) of Linoria.
]]

local clonerefFunction = cloneref or clone_ref or clonereference or clone_reference
local ns__cloneref = clonerefFunction and function(Object)
	local Success, Result = pcall(clonerefFunction, Object)
	return Success and Result or Object
end or function(Object)
    return Object
end

local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local TextService = game:GetService("TextService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Teams = game:GetService("Teams")

local RenderStepped = RunService.RenderStepped
local LocalPlayer = Players.LocalPlayer
local Mouse = ns__cloneref(LocalPlayer:GetMouse())

local ScreenGui = ns__cloneref(Instance.new("ScreenGui"))
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
ScreenGui.Parent = ns__cloneref(game:GetService("CoreGui"))

local Toggles = {}
local Options = {}

local Library = {
    Toggled = true,

    Toggles = Toggles,
    Options = Options,

    Registry = {},
    RegistryMap = {},

    HudRegistry = {},

    FontColor = Color3.fromRGB(255, 255, 255),
    MainColor = Color3.fromRGB(28, 28, 28),
    BackgroundColor = Color3.fromRGB(20, 20, 20),
    AccentColor = Color3.fromRGB(127, 0, 255),
    OutlineColor = Color3.fromRGB(50, 50, 50),
    RiskColor = Color3.fromRGB(255, 50, 50),

    Black = Color3.new(0, 0, 0),
    Font = Enum.Font.Code,

    OpenedFrames = {},
    DependencyBoxes = {},

    ModeSelectOuters = {},

    ScreenGui = ScreenGui
}

local RainbowStep = 0
local Hue = 0

local Step, Step2 = 1/60, 1/400
RenderStepped:Connect(function(Delta)
    RainbowStep = RainbowStep + Delta

    if RainbowStep >= Step then
        RainbowStep = 0

        Hue += Step2

        if Hue > 1 then
            Hue = 0
        end

        Library.CurrentRainbowHue = Hue
        Library.CurrentRainbowColor = Color3.fromHSV(Hue, 0.8, 1)
    end
end)

local function GetPlayersString()
    local PlayerList = Players:GetPlayers()

    for Index = 1, #PlayerList do
        PlayerList[Index] = PlayerList[Index].Name
    end

    table.sort(PlayerList, function(String1, String2)
        return String1 < String2
    end)

    return PlayerList
end

local function GetTeamsString()
    local TeamList = Teams:GetTeams()

    for Index = 1, #TeamList do
        TeamList[Index] = TeamList[Index].Name
    end

    table.sort(TeamList, function(String1, String2)
        return String1 < String2
    end)

    return TeamList
end

function Library:SafeCallback(f, ...)
    if not f then
        return
    end

    if not Library.NotifyOnError then
        return f(...)
    end

    local Success, Event = pcall(f, ...)

    if not Success then
        local _,i = Event:find(":%d+: ")

        if not i then
            return Library:Notify(Event)
        end

        return Library:Notify(Event:sub(i + 1), 3)
    end
end

function Library:AttemptSave()
    if Library.SaveManager then
        Library.SaveManager:Save()
    end
end

function Library:Create(Class, Properties)
    local _Instance = Class

    if type(Class) == "string" then
        _Instance = ns__cloneref(Instance.new(Class))
    end

    for Property, Value in next, Properties do
        _Instance[Property] = Value
    end

    return _Instance
end

function Library:ApplyTextStroke(Inst)
    Inst.TextStrokeTransparency = 1
    Library:Create('UIStroke', {
        Color = Color3.new(0, 0, 0),
        Thickness = 1,
        LineJoinMode = Enum.LineJoinMode.Miter,
        Parent = Inst,
    })
end

function Library:CreateLabel(Properties, IsHud)
    local _Instance = Library:Create('TextLabel', {
        BackgroundTransparency = 1,
        Font = Library.Font,
        TextColor3 = Library.FontColor,
        TextSize = 16,
        TextStrokeTransparency = 0,
    })

    Library:ApplyTextStroke(_Instance)
    Library:AddToRegistry(_Instance, {
        TextColor3 = "FontColor",
    }, IsHud)

    return Library:Create(_Instance, Properties)
end

function Library:MakeDraggable(Instance, Cutoff)
    Instance.Active = true
    Instance.InputBegan:Connect(function(Input)
        if Input.UserInputType == Enum.UserInputType.MouseButton1 then
            local ObjPos = Vector2.new(
                Mouse.X - Instance.AbsolutePosition.X,
                Mouse.Y - Instance.AbsolutePosition.Y
            )

            if ObjPos.Y > (Cutoff or 40) then
                return
            end

            while UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                Instance.Position = UDim2.new(
                    0, Mouse.X - ObjPos.X + (Instance.Size.X.Offset * Instance.AnchorPoint.X), 0,  Mouse.Y - ObjPos.Y + (Instance.Size.Y.Offset * Instance.AnchorPoint.Y)
                )
                RenderStepped:Wait()
            end
        end
    end)
end

function Library:AddToolTip(InfoStr, HoverInstance)
    local X, Y = Library:GetTextBounds(InfoStr, Library.Font, 14);
    local Tooltip = Library:Create("Frame", {
        BackgroundColor3 = Library.MainColor,
        BorderColor3 = Library.OutlineColor,
        Size = UDim2.fromOffset(X + 5, Y + 4),
        ZIndex = 100,
        Parent = Library.ScreenGui,
        Visible = false
    })

    local Label = Library:CreateLabel({
        Position = UDim2.fromOffset(3, 1),
        Size = UDim2.fromOffset(X, Y),
        TextSize = 14,
        Text = InfoStr,
        TextColor3 = Library.FontColor,
        TextXAlignment = Enum.TextXAlignment.Left;
        ZIndex = Tooltip.ZIndex + 1,
        Parent = Tooltip
    })

    Library:AddToRegistry(Tooltip, {
        BackgroundColor3 = "MainColor";
        BorderColor3 = "OutlineColor"
    })

    Library:AddToRegistry(Label, {TextColor3 = "FontColor"})

    local IsHovering = false

    HoverInstance.MouseEnter:Connect(function()
        if Library:MouseIsOverOpenedFrame() then
            return
        end

        IsHovering = true

        Tooltip.Position = UDim2.fromOffset(Mouse.X + 15, Mouse.Y + 12)
        Tooltip.Visible = true

        while IsHovering do
            RunService.Heartbeat:Wait()
            Tooltip.Position = UDim2.fromOffset(Mouse.X + 15, Mouse.Y + 12)
        end
    end)

    HoverInstance.MouseLeave:Connect(function()
        IsHovering = false
        Tooltip.Visible = false
    end)
end

function Library:OnHighlight(HighlightInstance, Instance, Properties, PropertiesDefault)
    HighlightInstance.MouseEnter:Connect(function()
        local Reg = Library.RegistryMap[Instance]

        for Property, ColorIdx in next, Properties do
            Instance[Property] = Library[ColorIdx] or ColorIdx

            if Reg and Reg.Properties[Property] then
                Reg.Properties[Property] = ColorIdx
            end
        end
    end)

    HighlightInstance.MouseLeave:Connect(function()
        local Reg = Library.RegistryMap[Instance]

        for Property, ColorIdx in next, PropertiesDefault do
            Instance[Property] = Library[ColorIdx] or ColorIdx

            if Reg and Reg.Properties[Property] then
                Reg.Properties[Property] = ColorIdx
            end
        end
    end)
end

function Library:MouseIsOverOpenedFrame()
    for Frame in next, Library.OpenedFrames do
        local AbsolutePosition, AbsoluteSize = Frame.AbsolutePosition, Frame.AbsoluteSize
        if Mouse.X >= AbsolutePosition.X and Mouse.X <= AbsolutePosition.X + AbsoluteSize.X and Mouse.Y >= AbsolutePosition.Y and Mouse.Y <= AbsolutePosition.Y + AbsoluteSize.Y then
            return true
        end
    end
end

function Library:IsMouseOverFrame(Frame)
    local AbsolutePosition, AbsoluteSize = Frame.AbsolutePosition, Frame.AbsoluteSize
    if Mouse.X >= AbsolutePosition.X and Mouse.X <= AbsolutePosition.X + AbsoluteSize.X and Mouse.Y >= AbsolutePosition.Y and Mouse.Y <= AbsolutePosition.Y + AbsoluteSize.Y then
        return true
    end
end

function Library:UpdateDependencyBoxes()
    for _,Depbox in next, Library.DependencyBoxes do
        Depbox:Update()
    end
end

function Library:MapValue(Value, MinA, MaxA, MinB, MaxB)
    return (1 - ((Value - MinA) / (MaxA - MinA))) * MinB + ((Value - MinA) / (MaxA - MinA)) * MaxB
end

function Library:GetTextBounds(Text, Font, Size, Resolution)
    local Bounds = TextService:GetTextSize(Text, Size, Font, Resolution or Vector2.new(1920, 1080))
    return Bounds.X, Bounds.Y
end

function Library:GetDarkerColor(Color)
    local H, S, V = Color3.toHSV(Color)
    return Color3.fromHSV(H, S, V / 1.5)
end
Library.AccentColorDark = Library:GetDarkerColor(Library.AccentColor)

function Library:AddToRegistry(Instance, Properties, IsHud)
    local Index = #Library.Registry + 1
    local Data = {
        Instance = Instance,
        Properties = Properties,
        Index = Index,
    }

    table.insert(Library.Registry, Data)
    Library.RegistryMap[Instance] = Data

    if IsHud then
        table.insert(Library.HudRegistry, Data)
    end
end

function Library:RemoveFromRegistry(Instance)
    local Data = Library.RegistryMap[Instance]

    if Data then
        for Index = #Library.Registry, 1, -1 do
            if Library.Registry[Index] == Data then
                table.remove(Library.Registry, Index)
            end
        end

        for Index = #Library.HudRegistry, 1, -1 do
            if Library.HudRegistry[Index] == Data then
                table.remove(Library.HudRegistry, Index)
            end
        end

        Library.RegistryMap[Instance] = nil
    end
end

function Library:UpdateColorsUsingRegistry()
    for Index, Object in next, Library.Registry do
        for Property, ColorIdx in next, Object.Properties do
            if type(ColorIdx) == "string" then
                Object.Instance[Property] = Library[ColorIdx]
            elseif type(ColorIdx) == 'function' then
                Object.Instance[Property] = ColorIdx()
            end
        end
    end
end

ScreenGui.DescendantRemoving:Connect(function(Instance)
    if Library.RegistryMap[Instance] then
        Library:RemoveFromRegistry(Instance)
    end
end)

local BaseAddons = {}

do
    local Funcs = {}

    function Funcs:AddColorPicker(Index, Info)
        local ToggleLabel = self.TextLabel

        assert(Info.Default, 'AddColorPicker: Missing default value.')

        local ColorPicker = {
            Value = Info.Default,
            Transparency = Info.Transparency or 0,
            Type = 'ColorPicker',
            Title = type(Info.Title) == "string" and Info.Title or 'Color picker',
            Callback = Info.Callback or function(Color) end,
        }

        function ColorPicker:SetHSVFromRGB(Color)
            local H, S, V = Color3.toHSV(Color)

            ColorPicker.Hue = H
            ColorPicker.Saturation = S
            ColorPicker.Vib = V
        end

        ColorPicker:SetHSVFromRGB(ColorPicker.Value)

        local DisplayFrame = Library:Create("Frame", {
            BackgroundColor3 = ColorPicker.Value,
            BorderColor3 = Library:GetDarkerColor(ColorPicker.Value),
            BorderMode = Enum.BorderMode.Inset,
            Size = UDim2.new(0, 28, 0, 14),
            ZIndex = 6,
            Parent = ToggleLabel,
        })

        local CheckerFrame = Library:Create("ImageLabel", {
            BorderSizePixel = 0,
            Size = UDim2.new(0, 27, 0, 13),
            ZIndex = 5,
            Image = 'http://www.roblox.com/asset/?id=12977615774',
            Visible = not not Info.Transparency,
            Parent = DisplayFrame,
        })

        local PickerFrameOuter = Library:Create("Frame", {
            Name = "Color";
            BackgroundColor3 = Color3.new(1, 1, 1);
            BorderColor3 = Color3.new(0, 0, 0);
            Position = UDim2.fromOffset(DisplayFrame.AbsolutePosition.X, DisplayFrame.AbsolutePosition.Y + 18),
            Size = UDim2.fromOffset(230, Info.Transparency and 271 or 253);
            Visible = false;
            ZIndex = 15,
            Parent = ScreenGui
        })

        DisplayFrame:GetPropertyChangedSignal('AbsolutePosition'):Connect(function()
            PickerFrameOuter.Position = UDim2.fromOffset(DisplayFrame.AbsolutePosition.X, DisplayFrame.AbsolutePosition.Y + 18)
        end)

        local PickerFrameInner = Library:Create("Frame", {
            BackgroundColor3 = Library.BackgroundColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 16,
            Parent = PickerFrameOuter
        })

        local Highlight = Library:Create("Frame", {
            BackgroundColor3 = Library.AccentColor;
            BorderSizePixel = 0;
            Size = UDim2.new(1, 0, 0, 2);
            ZIndex = 17;
            Parent = PickerFrameInner
        })

        local SatVibMapOuter = Library:Create("Frame", {
            BorderColor3 = Color3.new(0, 0, 0);
            Position = UDim2.new(0, 4, 0, 25);
            Size = UDim2.new(0, 200, 0, 200);
            ZIndex = 17;
            Parent = PickerFrameInner
        })

        local SatVibMapInner = Library:Create("Frame", {
            BackgroundColor3 = Library.BackgroundColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 18;
            Parent = SatVibMapOuter
        })

        local SatVibMap = Library:Create("ImageLabel", {
            BorderSizePixel = 0;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 18;
            Image = 'rbxassetid://4155801252';
            Parent = SatVibMapInner
        })

        local CursorOuter = Library:Create("ImageLabel", {
            AnchorPoint = Vector2.new(0.5, 0.5);
            Size = UDim2.new(0, 6, 0, 6);
            BackgroundTransparency = 1;
            Image = 'http://www.roblox.com/asset/?id=9619665977';
            ImageColor3 = Color3.new(0, 0, 0);
            ZIndex = 19;
            Parent = SatVibMap
        })

        local CursorInner = Library:Create("ImageLabel", {
            Size = UDim2.new(0, CursorOuter.Size.X.Offset - 2, 0, CursorOuter.Size.Y.Offset - 2);
            Position = UDim2.new(0, 1, 0, 1);
            BackgroundTransparency = 1;
            Image = 'http://www.roblox.com/asset/?id=9619665977';
            ZIndex = 20;
            Parent = CursorOuter
        })

        local HueSelectorOuter = Library:Create("Frame", {
            BorderColor3 = Color3.new(0, 0, 0);
            Position = UDim2.new(0, 208, 0, 25);
            Size = UDim2.new(0, 15, 0, 200);
            ZIndex = 17;
            Parent = PickerFrameInner
        })

        local HueSelectorInner = Library:Create("Frame", {
            BackgroundColor3 = Color3.new(1, 1, 1);
            BorderSizePixel = 0;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 18;
            Parent = HueSelectorOuter
        })

        local HueCursor = Library:Create("Frame", {
            BackgroundColor3 = Color3.new(1, 1, 1);
            AnchorPoint = Vector2.new(0, 0.5);
            BorderColor3 = Color3.new(0, 0, 0);
            Size = UDim2.new(1, 0, 0, 1);
            ZIndex = 18;
            Parent = HueSelectorInner
        })

        local HueBoxOuter = Library:Create("Frame", {
            BorderColor3 = Color3.new(0, 0, 0);
            Position = UDim2.fromOffset(4, 228),
            Size = UDim2.new(0.5, -6, 0, 20),
            ZIndex = 18,
            Parent = PickerFrameInner
        })

        local HueBoxInner = Library:Create("Frame", {
            BackgroundColor3 = Library.MainColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 18,
            Parent = HueBoxOuter
        })

        Library:Create("UIGradient", {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(212, 212, 212))
            }),
            Rotation = 90,
            Parent = HueBoxInner
        })

        local HueBox = Library:Create("TextBox", {
            BackgroundTransparency = 1;
            Position = UDim2.new(0, 5, 0, 0);
            Size = UDim2.new(1, -5, 1, 0);
            Font = Library.Font;
            PlaceholderColor3 = Color3.fromRGB(190, 190, 190);
            PlaceholderText = 'Hex color',
            Text = '#FFFFFF',
            TextColor3 = Library.FontColor;
            TextSize = 14;
            TextStrokeTransparency = 0;
            TextXAlignment = Enum.TextXAlignment.Left;
            ZIndex = 20,
            Parent = HueBoxInner;
        })

        Library:ApplyTextStroke(HueBox);

        local RGBBoxBase = Library:Create(HueBoxOuter:Clone(), {
            Position = UDim2.new(0.5, 2, 0, 228),
            Size = UDim2.new(0.5, -6, 0, 20),
            Parent = PickerFrameInner
        })

        local RGBBox = Library:Create(RGBBoxBase.Frame:FindFirstChild("TextBox"), {
            Text = '255, 255, 255',
            PlaceholderText = 'RGB color',
            TextColor3 = Library.FontColor
        })

        local TransparencyBoxOuter, TransparencyBoxInner, TransparencyCursor;
        
        if Info.Transparency then 
            TransparencyBoxOuter = Library:Create("Frame", {
                BorderColor3 = Color3.new(0, 0, 0);
                Position = UDim2.fromOffset(4, 251);
                Size = UDim2.new(1, -8, 0, 15);
                ZIndex = 19;
                Parent = PickerFrameInner;
            })

            TransparencyBoxInner = Library:Create("Frame", {
                BackgroundColor3 = ColorPicker.Value;
                BorderColor3 = Library.OutlineColor;
                BorderMode = Enum.BorderMode.Inset;
                Size = UDim2.new(1, 0, 1, 0);
                ZIndex = 19;
                Parent = TransparencyBoxOuter;
            })

            Library:AddToRegistry(TransparencyBoxInner, {BorderColor3 = "OutlineColor" })

            Library:Create("ImageLabel", {
                BackgroundTransparency = 1;
                Size = UDim2.new(1, 0, 1, 0);
                Image = 'http://www.roblox.com/asset/?id=12978095818';
                ZIndex = 20;
                Parent = TransparencyBoxInner;
            })

            TransparencyCursor = Library:Create("Frame", {
                BackgroundColor3 = Color3.new(1, 1, 1);
                AnchorPoint = Vector2.new(0.5, 0);
                BorderColor3 = Color3.new(0, 0, 0);
                Size = UDim2.new(0, 1, 1, 0);
                ZIndex = 21;
                Parent = TransparencyBoxInner;
            })
        end

        local DisplayLabel = Library:CreateLabel({
            Size = UDim2.new(1, 0, 0, 14);
            Position = UDim2.fromOffset(5, 5);
            TextXAlignment = Enum.TextXAlignment.Left;
            TextSize = 14;
            Text = ColorPicker.Title,
            TextWrapped = false;
            ZIndex = 16;
            Parent = PickerFrameInner;
        })


        local ContextMenu = {}
        do
            ContextMenu.Options = {}
            ContextMenu.Container = Library:Create("Frame", {
                BorderColor3 = Color3.new(),
                ZIndex = 14,

                Visible = false,
                Parent = ScreenGui
            })

            ContextMenu.Inner = Library:Create("Frame", {
                BackgroundColor3 = Library.BackgroundColor;
                BorderColor3 = Library.OutlineColor;
                BorderMode = Enum.BorderMode.Inset;
                Size = UDim2.fromScale(1, 1);
                ZIndex = 15;
                Parent = ContextMenu.Container;
            })

            Library:Create('UIListLayout', {
                Name = 'Layout',
                FillDirection = Enum.FillDirection.Vertical;
                SortOrder = Enum.SortOrder.LayoutOrder;
                Parent = ContextMenu.Inner;
            })

            Library:Create('UIPadding', {
                Name = 'Padding',
                PaddingLeft = UDim.new(0, 4),
                Parent = ContextMenu.Inner,
            })

            local function updateMenuPosition()
                ContextMenu.Container.Position = UDim2.fromOffset(
                    (DisplayFrame.AbsolutePosition.X + DisplayFrame.AbsoluteSize.X) + 4,
                    DisplayFrame.AbsolutePosition.Y + 1
                )
            end

            local function updateMenuSize()
                local menuWidth = 60
                for i, label in next, ContextMenu.Inner:GetChildren() do
                    if label:IsA('TextLabel') then
                        menuWidth = math.max(menuWidth, label.TextBounds.X)
                    end
                end

                ContextMenu.Container.Size = UDim2.fromOffset(
                    menuWidth + 8,
                    ContextMenu.Inner.Layout.AbsoluteContentSize.Y + 4
                )
            end

            DisplayFrame:GetPropertyChangedSignal('AbsolutePosition'):Connect(updateMenuPosition)
            ContextMenu.Inner.Layout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(updateMenuSize)

            task.spawn(updateMenuPosition)
            task.spawn(updateMenuSize)

            Library:AddToRegistry(ContextMenu.Inner, {
                BackgroundColor3 = "BackgroundColor";
                BorderColor3 = "OutlineColor";
            })

            function ContextMenu:Show()
                self.Container.Visible = true
            end

            function ContextMenu:Hide()
                self.Container.Visible = false
            end

            function ContextMenu:AddOption(Str, Callback)
                if type(Callback) ~= 'function' then
                    Callback = function() end
                end

                local Button = Library:CreateLabel({
                    Active = false;
                    Size = UDim2.new(1, 0, 0, 15);
                    TextSize = 13;
                    Text = Str;
                    ZIndex = 16;
                    Parent = self.Inner;
                    TextXAlignment = Enum.TextXAlignment.Left
                })

                Library:OnHighlight(Button, Button, 
                    {TextColor3 = "AccentColor"},
                    {TextColor3 = "FontColor"}
                );

                Button.InputBegan:Connect(function(Input)
                    if Input.UserInputType ~= Enum.UserInputType.MouseButton1 then
                        return
                    end

                    Callback()
                end)
            end

            ContextMenu:AddOption('Copy color', function()
                Library.ColorClipboard = ColorPicker.Value
                Library:Notify('Copied color!', 2)
            end)

            ContextMenu:AddOption('Paste color', function()
                if not Library.ColorClipboard then
                    return Library:Notify('You have not copied a color!', 2)
                end
                ColorPicker:SetValueRGB(Library.ColorClipboard)
            end)


            ContextMenu:AddOption('Copy HEX', function()
                if pcall(setclipboard, ColorPicker.Value:ToHex()) then
                    return Library:Notify('Copied hex code to clipboard!', 2)
                end
                Library:Notify('Failed to copy hex code to clipboard!', 2)
            end)

            ContextMenu:AddOption('Copy RGB', function()
                if pcall(setclipboard, table.concat({math.floor(ColorPicker.Value.R * 255), math.floor(ColorPicker.Value.G * 255), math.floor(ColorPicker.Value.B * 255) }, ', ')) then
                    return Library:Notify('Copied RGB values to clipboard!', 2)
                end
                Library:Notify('Failed to copy RGB values to clipboard!', 2)
            end)

        end

        Library:AddToRegistry(PickerFrameInner, {BackgroundColor3 = "BackgroundColor"; BorderColor3 = "OutlineColor"})
        Library:AddToRegistry(Highlight, {BackgroundColor3 = "AccentColor"; })
        Library:AddToRegistry(SatVibMapInner, {BackgroundColor3 = "BackgroundColor"; BorderColor3 = "OutlineColor"})

        Library:AddToRegistry(HueBoxInner, {BackgroundColor3 = "MainColor"; BorderColor3 = "OutlineColor"})
        Library:AddToRegistry(RGBBoxBase.Frame, {BackgroundColor3 = "MainColor"; BorderColor3 = "OutlineColor"})
        Library:AddToRegistry(RGBBox, {TextColor3 = "FontColor"})
        Library:AddToRegistry(HueBox, {TextColor3 = "FontColor"})

        local SequenceTable = {};

        for Hue = 0, 1, 0.1 do
            table.insert(SequenceTable, ColorSequenceKeypoint.new(Hue, Color3.fromHSV(Hue, 1, 1)))
        end

        local HueSelectorGradient = Library:Create("UIGradient", {
            Color = ColorSequence.new(SequenceTable);
            Rotation = 90;
            Parent = HueSelectorInner
        })

        HueBox.FocusLost:Connect(function(Enter)
            if Enter then
                local Success, Result = pcall(Color3.fromHex, HueBox.Text)
                if Success and typeof(Result) == 'Color3' then
                    ColorPicker.Hue, ColorPicker.Saturation, ColorPicker.Vib = Color3.toHSV(Result)
                end
            end

            ColorPicker:Display()
        end)

        RGBBox.FocusLost:Connect(function(Enter)
            if Enter then
                local R, G, B = RGBBox.Text:match('(%d+),%s*(%d+),%s*(%d+)')
                if R and G and B then
                    ColorPicker.Hue, ColorPicker.Saturation, ColorPicker.Vib = Color3.toHSV(Color3.fromRGB(R, G, B))
                end
            end
            ColorPicker:Display()
        end)

        function ColorPicker:Display()
            ColorPicker.Value = Color3.fromHSV(ColorPicker.Hue, ColorPicker.Saturation, ColorPicker.Vib)
            SatVibMap.BackgroundColor3 = Color3.fromHSV(ColorPicker.Hue, 1, 1)

            Library:Create(DisplayFrame, {
                BackgroundColor3 = ColorPicker.Value,
                BackgroundTransparency = ColorPicker.Transparency,
                BorderColor3 = Library:GetDarkerColor(ColorPicker.Value)
            })

            if TransparencyBoxInner then
                TransparencyBoxInner.BackgroundColor3 = ColorPicker.Value
                TransparencyCursor.Position = UDim2.new(1 - ColorPicker.Transparency, 0, 0, 0)
            end

            CursorOuter.Position = UDim2.new(ColorPicker.Saturation, 0, 1 - ColorPicker.Vib, 0)
            HueCursor.Position = UDim2.new(0, 0, ColorPicker.Hue, 0)

            HueBox.Text = '#' .. ColorPicker.Value:ToHex()
            RGBBox.Text = table.concat({math.floor(ColorPicker.Value.R * 255), math.floor(ColorPicker.Value.G * 255), math.floor(ColorPicker.Value.B * 255) }, ', ')

            Library:SafeCallback(ColorPicker.Callback, ColorPicker.Value)
            Library:SafeCallback(ColorPicker.Changed, ColorPicker.Value)
        end

        function ColorPicker:OnChanged(Func)
            ColorPicker.Changed = Func
            Func(ColorPicker.Value)
        end

        function ColorPicker:Show()
            for Frame, Value in next, Library.OpenedFrames do
                if Frame.Name == "Color" then
                    Frame.Visible = false
                    Library.OpenedFrames[Frame] = nil
                end
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
            if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                while UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                    local MinX = SatVibMap.AbsolutePosition.X
                    local MaxX = MinX + SatVibMap.AbsoluteSize.X

                    local MinY = SatVibMap.AbsolutePosition.Y
                    local MaxY = MinY + SatVibMap.AbsoluteSize.Y

                    ColorPicker.Saturation = (math.clamp(Mouse.X, MinX, MaxX) - MinX) / (MaxX - MinX)
                    ColorPicker.Vib = 1 - ((math.clamp(Mouse.Y, MinY, MaxY) - MinY) / (MaxY - MinY))
                    ColorPicker:Display()
                    RenderStepped:Wait()
                end
                Library:AttemptSave()
            end
        end)

        HueSelectorInner.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                while UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                    local MinY = HueSelectorInner.AbsolutePosition.Y;
                    local MaxY = MinY + HueSelectorInner.AbsoluteSize.Y;
                    local MouseY = math.clamp(Mouse.Y, MinY, MaxY);

                    ColorPicker.Hue = ((MouseY - MinY) / (MaxY - MinY));
                    ColorPicker:Display()

                    RenderStepped:Wait()
                end

                Library:AttemptSave()
            end
        end)

        DisplayFrame.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame() then
                if PickerFrameOuter.Visible then
                    ColorPicker:Hide()
                else
                    ContextMenu:Hide()
                    ColorPicker:Show()
                end
            elseif Input.UserInputType == Enum.UserInputType.MouseButton2 and not Library:MouseIsOverOpenedFrame() then
                ContextMenu:Show()
                ColorPicker:Hide()
            end
        end)

        if TransparencyBoxInner then
            TransparencyBoxInner.InputBegan:Connect(function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                    while UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                        local MinX = TransparencyBoxInner.AbsolutePosition.X
                        local MaxX = MinX + TransparencyBoxInner.AbsoluteSize.X
                        ColorPicker.Transparency = 1 - ((math.clamp(Mouse.X, MinX, MaxX) - MinX) / (MaxX - MinX))
                        ColorPicker:Display()
                        RenderStepped:Wait()
                    end
                    Library:AttemptSave()
                end
            end)
        end

        UserInputService.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                local AbsolutePosition, AbsoluteSize = PickerFrameOuter.AbsolutePosition, PickerFrameOuter.AbsoluteSize
                if Mouse.X < AbsolutePosition.X or Mouse.X > AbsolutePosition.X + AbsoluteSize.X or Mouse.Y < (AbsolutePosition.Y - 20 - 1) or Mouse.Y > AbsolutePosition.Y + AbsoluteSize.Y then
                    ColorPicker:Hide()
                end

                if not Library:IsMouseOverFrame(ContextMenu.Container) then
                    ContextMenu:Hide()
                end
            end

            if Input.UserInputType == Enum.UserInputType.MouseButton2 and ContextMenu.Container.Visible then
                if not Library:IsMouseOverFrame(ContextMenu.Container) and not Library:IsMouseOverFrame(DisplayFrame) then
                    ContextMenu:Hide()
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

        assert(Info.Default, 'AddKeyPicker: Missing default value.');

        local KeyPicker = {
            Value = Info.Default,
            Toggled = false,
            Mode = Info.Mode or "Toggle",
            Type = 'KeyPicker',
            Callback = Info.Callback or function() end,
            ChangedCallback = Info.ChangedCallback or function() end,
            SyncToggleState = Info.SyncToggleState or false
        }

        if KeyPicker.SyncToggleState then
            Info.Modes = {"Toggle"}
            Info.Mode = "Toggle"
        end

        local PickOuter = Library:Create("Frame", {
            BackgroundColor3 = Color3.new(0, 0, 0);
            BorderColor3 = Color3.new(0, 0, 0);
            Size = UDim2.new(0, 28, 0, 15);
            ZIndex = 6,
            Parent = ToggleLabel
        })

        local PickInner = Library:Create("Frame", {
            BackgroundColor3 = Library.BackgroundColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 7;
            Parent = PickOuter
        })

        Library:AddToRegistry(PickInner, {
            BackgroundColor3 = "BackgroundColor";
            BorderColor3 = "OutlineColor"
        })

        local DisplayLabel = Library:CreateLabel({
            Size = UDim2.new(1, 0, 1, 0);
            TextSize = 13;
            Text = Info.Default;
            TextWrapped = true;
            ZIndex = 8;
            Parent = PickInner
        })

        local ModeSelectOuter = Library:Create("Frame", {
            BorderColor3 = Color3.new(0, 0, 0);
            Position = UDim2.fromOffset(ToggleLabel.AbsolutePosition.X + ToggleLabel.AbsoluteSize.X + 4, ToggleLabel.AbsolutePosition.Y + 1);
            Size = UDim2.new(0, 60, 0, 45 + 2);
            Visible = false;
            ZIndex = 14;
            Parent = ScreenGui
        })

        Library.ModeSelectOuters[ModeSelectOuter] = true

        ToggleLabel:GetPropertyChangedSignal('AbsolutePosition'):Connect(function()
            ModeSelectOuter.Position = UDim2.fromOffset(ToggleLabel.AbsolutePosition.X + ToggleLabel.AbsoluteSize.X + 4, ToggleLabel.AbsolutePosition.Y + 1);
        end)

        local ModeSelectInner = Library:Create("Frame", {
            BackgroundColor3 = Library.BackgroundColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 15;
            Parent = ModeSelectOuter
        })

        Library:AddToRegistry(ModeSelectInner, {BackgroundColor3 = "BackgroundColor", BorderColor3 = "OutlineColor"})

        Library:Create('UIListLayout', {
            FillDirection = Enum.FillDirection.Vertical;
            SortOrder = Enum.SortOrder.LayoutOrder;
            Parent = ModeSelectInner
        })

        local ContainerLabel = Library:CreateLabel({
            TextXAlignment = Enum.TextXAlignment.Left;
            Size = UDim2.new(1, 0, 0, 18);
            TextSize = 13;
            Visible = false;
            ZIndex = 110;
            Parent = Library.KeybindContainer
        }, true)

        local Modes = Info.Modes or {"Always", "Toggle", "Hold"}
        local ModeButtons = {}

        for Index, Mode in next, Modes do
            local ModeButton = {}

            local Label = Library:CreateLabel({
                Active = false;
                Size = UDim2.new(1, 0, 0, 15);
                TextSize = 13;
                Text = Mode;
                ZIndex = 16;
                Parent = ModeSelectInner
            })

            function ModeButton:Select()
                local OldMode = KeyPicker.Mode

                for _,Button in next, ModeButtons do
                    Button:Deselect()
                end

                KeyPicker.Mode = Mode

                if OldMode ~= Mode then
                    if Mode == "Hold" and OldMode == "Toggle" and KeyPicker.Toggled then
                        KeyPicker.Toggled = false
                        Library:SafeCallback(KeyPicker.Callback, false)
                        Library:SafeCallback(KeyPicker.Clicked, false)
                    elseif Mode == "Toggle" and OldMode == "Hold" then
                        if KeyPicker.Value ~= "None" then
                            local Held = KeyPicker.Value == "MB2" and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) or UserInputService:IsKeyDown(Enum.KeyCode[KeyPicker.Value])
                            if Held then
                                KeyPicker.Toggled = true
                                Library:SafeCallback(KeyPicker.Callback, true)
                                Library:SafeCallback(KeyPicker.Clicked, true)
                            end
                        end
                    end
                end

                Label.TextColor3 = Library.AccentColor
                Library.RegistryMap[Label].Properties.TextColor3 = "AccentColor"

                ModeSelectOuter.Visible = false
            end

            function ModeButton:Deselect()
                KeyPicker.Mode = nil

                Label.TextColor3 = Library.FontColor
                Library.RegistryMap[Label].Properties.TextColor3 = "FontColor"
            end

            Label.InputBegan:Connect(function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                    ModeButton:Select()
                    Library:AttemptSave()
                end
            end)

            if Mode == KeyPicker.Mode then
                ModeButton:Select()
            end

            ModeButtons[Mode] = ModeButton
        end

        function KeyPicker:Update()
            if Info.NoUI then
                return
            end

            local State = KeyPicker:GetState()

            ContainerLabel.Text = string.format('[%s] %s (%s)', KeyPicker.Value, Info.Text, KeyPicker.Mode)

            ContainerLabel.Visible = true
            ContainerLabel.TextColor3 = State and Library.AccentColor or Library.FontColor

            Library.RegistryMap[ContainerLabel].Properties.TextColor3 = State and "AccentColor" or "FontColor"

            local YSize = 0
            local XSize = 0

            for _,Label in next, Library.KeybindContainer:GetChildren() do
                if Label:IsA('TextLabel') and Label.Visible then
                    YSize += 18
                    if (Label.TextBounds.X > XSize) then
                        XSize = Label.TextBounds.X
                    end
                end
            end

            Library.KeybindFrame.Size = UDim2.new(0, math.max(XSize + 10, 210), 0, YSize + 23)
        end

        function KeyPicker:GetState()
            if KeyPicker.Mode == "Always" then
                return true
            elseif KeyPicker.Mode == "Hold" then
                if KeyPicker.Value == 'None' then
                    return false
                end

                local Key = KeyPicker.Value
                if Key == "MB2" then
                    return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
                else
                    return UserInputService:IsKeyDown(Enum.KeyCode[KeyPicker.Value])
                end
            else
                return KeyPicker.Toggled
            end
        end

        function KeyPicker:SetValue(Data)
            if type(Data) ~= "table" then
                Data = {Data, KeyPicker.Mode or "Toggle"}
            end

            local Key = Data[1]
            if typeof(Key) ~= "string" or Key == "" then
                Key = Info.Default or "None"
            end

            local Mode = Data[2]
            if typeof(Mode) ~= "string" or not ModeButtons[Mode] then
                Mode = KeyPicker.Mode or "Toggle"
            end

            DisplayLabel.Text = Key
            KeyPicker.Value = Key
            ModeButtons[Mode]:Select()
            Library:SafeCallback(KeyPicker.Callback, Key)
            KeyPicker:Update()
            Library:UpdateDependencyBoxes()
        end

        function KeyPicker:OnClick(Callback)
            KeyPicker.Clicked = Callback
        end

        function KeyPicker:OnChanged(Callback)
            KeyPicker.Changed = Callback
            Callback(KeyPicker.Value)
        end

        if ParentObj.Addons then
            table.insert(ParentObj.Addons, KeyPicker)
        end

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

                DisplayLabel.Text = ''

                local Break
                local Text = ''

                task.spawn(function()
                    while not Break do
                        if Text == '...' then
                            Text = ''
                        end

                        Text = Text .. '.'
                        DisplayLabel.Text = Text

                        task.wait(0.4)
                    end
                end)

                task.wait(0.2)

                local Event
                Event = UserInputService.InputBegan:Connect(function(Input)
                    local Key

                    if Input.UserInputType == Enum.UserInputType.Keyboard then
                        Key = Input.KeyCode.Name
                    elseif Input.UserInputType == Enum.UserInputType.MouseButton2 then
                        Key = Input.UserInputType.Name
                    elseif Input.UserInputType == Enum.UserInputType.MouseButton1 then
                        Key = "None"
                    end

                    Break = true
                    Picking = false

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
            if Processed then
                return
            end

            if not Picking then
                if KeyPicker.Mode == "Toggle" and Input.UserInputType == Enum.UserInputType.Keyboard and Input.KeyCode.Name == KeyPicker.Value then
                    KeyPicker.Toggled = not KeyPicker.Toggled
                    KeyPicker:DoClick()
                elseif KeyPicker.Mode == "Hold" then
                    if (Input.UserInputType == Enum.UserInputType.Keyboard and Input.KeyCode.Name == KeyPicker.Value) or (KeyPicker.Value == "MB2" and Input.UserInputType == Enum.UserInputType.MouseButton2) then
                        Library:SafeCallback(KeyPicker.Callback, true)
                    end
                end
                KeyPicker:Update()
            end

            if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                local AbsolutePosition, AbsoluteSize = ModeSelectOuter.AbsolutePosition, ModeSelectOuter.AbsoluteSize
                if Mouse.X < AbsolutePosition.X or Mouse.X > AbsolutePosition.X + AbsoluteSize.X or Mouse.Y < (AbsolutePosition.Y - 20 - 1) or Mouse.Y > AbsolutePosition.Y + AbsoluteSize.Y then
                    ModeSelectOuter.Visible = false
                end
            end
        end)

        local InputEndedConnection = UserInputService.InputEnded:Connect(function(Input, Processed)
            if Processed then
                return
            end

            if not Picking then
                if KeyPicker.Mode == "Hold" and ((Input.UserInputType == Enum.UserInputType.Keyboard and Input.KeyCode.Name == KeyPicker.Value) or (KeyPicker.Value == "MB2" and Input.UserInputType == Enum.UserInputType.MouseButton2)) then
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

        PickOuter.Destroying:Connect(function()
            KeyPicker:Destroy()
        end)

        KeyPicker:Update()
        Options[Index] = KeyPicker
        return KeyPicker
    end

    BaseAddons.__index = Funcs
    BaseAddons.__namecall = function(Table, Key, ...)
        return Funcs[Key](...)
    end
end

local BaseGroupbox = {}

do
    local Funcs = {}

    function Funcs:AddBlank(Size)
        local Groupbox = self
        local Container = Groupbox.Container

        Library:Create("Frame", {
            BackgroundTransparency = 1;
            Size = UDim2.new(1, 0, 0, Size);
            ZIndex = 1;
            Parent = Container
        })
    end

    function Funcs:AddLabel(Text, DoesWrap, ToolTip)
        local Label = {}

        local Groupbox = self
        local Container = Groupbox.Container

        local TextLabel = Library:CreateLabel({
            Size = UDim2.new(1, -4, 0, 15),
            TextSize = 14,
            Text = Text,
            TextWrapped = DoesWrap or false,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 5,
            Parent = Container
        })

        if DoesWrap then
            TextLabel.Size = UDim2.new(1, -4, 0, select(2, Library:GetTextBounds(Text, Library.Font, 14, Vector2.new(TextLabel.AbsoluteSize.X, math.huge))))
        else
            Library:Create('UIListLayout', {
                Padding = UDim.new(0, 4),
                FillDirection = Enum.FillDirection.Horizontal,
                HorizontalAlignment = Enum.HorizontalAlignment.Right,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Parent = TextLabel
            })
        end

        Label.TextLabel = TextLabel
        Label.Container = Container

        function Label:SetText(Text)
            TextLabel.Text = Text

            if DoesWrap then
                TextLabel.Size = UDim2.new(1, -4, 0, select(2, Library:GetTextBounds(Text, Library.Font, 14, Vector2.new(TextLabel.AbsoluteSize.X, math.huge))))
            end

            Groupbox:Resize()
        end

        if (not DoesWrap) then
            setmetatable(Label, BaseAddons)
        end

        Groupbox:AddBlank(5)
        Groupbox:Resize()
        if type(ToolTip) == "string" then
            Library:AddToolTip(ToolTip, TextLabel)
        end
        return Label
    end

    function Funcs:AddButton(...)
        local Button = {}
        local function ProcessButtonParams(Class, Obj, ...)
            local Props = select(1, ...)
            if type(Props) == 'table' then
                Obj.Text = Props.Text
                Obj.Func = Props.Func
                Obj.DoubleClick = Props.DoubleClick
                Obj.Tooltip = Props.Tooltip
            else
                Obj.Text = select(1, ...)
                Obj.Func = select(2, ...)
            end
            assert(type(Obj.Func) == 'function', 'AddButton: `Func` callback is missing.')
        end

        ProcessButtonParams('Button', Button, ...)

        local Groupbox = self
        local Container = Groupbox.Container

        local function CreateBaseButton(Button)
            local Outer = Library:Create("Frame", {
                BackgroundColor3 = Color3.new(0, 0, 0);
                BorderColor3 = Color3.new(0, 0, 0);
                Size = UDim2.new(1, -4, 0, 20);
                ZIndex = 5
            })

            local Inner = Library:Create("Frame", {
                BackgroundColor3 = Library.MainColor;
                BorderColor3 = Library.OutlineColor;
                BorderMode = Enum.BorderMode.Inset;
                Size = UDim2.new(1, 0, 1, 0);
                ZIndex = 6;
                Parent = Outer
            })

            local Label = Library:CreateLabel({
                Size = UDim2.new(1, 0, 1, 0);
                TextSize = 14;
                Text = Button.Text;
                ZIndex = 6;
                Parent = Inner
            })

            Library:Create("UIGradient", {
                Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(212, 212, 212))
                }),
                Rotation = 90,
                Parent = Inner
            })

            Library:AddToRegistry(Outer, {BorderColor3 = "Black"})

            Library:AddToRegistry(Inner, {
                BackgroundColor3 = "MainColor";
                BorderColor3 = "OutlineColor";
            })

            Library:OnHighlight(Outer, Outer, {BorderColor3 = "AccentColor"}, {BorderColor3 = "Black"})
            return Outer, Inner, Label
        end

        local function InitEvents(Button)
            local function WaitForEvent(Event, timeout, validator)
                local Bindable = ns__cloneref(Instance.new('BindableEvent'))
                local Connection = Event:Once(function(...)
                    if type(validator) == 'function' and validator(...) then
                        Bindable:Fire(true)
                    else
                        Bindable:Fire(false)
                    end
                end)
                task.delay(timeout, function()
                    Connection:Disconnect()
                    Bindable:Fire(false)
                end)
                return Bindable.Event:Wait()
            end

            local function ValidateClick(Input)
                if Library:MouseIsOverOpenedFrame() then
                    return false
                end

                if Input.UserInputType ~= Enum.UserInputType.MouseButton1 then
                    return false
                end

                return true
            end

            Button.Outer.InputBegan:Connect(function(Input)
                if not ValidateClick(Input) or Button.Locked then
                    return
                end

                if Button.DoubleClick then
                    Library:RemoveFromRegistry(Button.Label)
                    Library:AddToRegistry(Button.Label, {TextColor3 = "AccentColor"})

                    Button.Label.TextColor3 = Library.AccentColor
                    Button.Label.Text = "Are you sure?"
                    Button.Locked = true

                    local Clicked = WaitForEvent(Button.Outer.InputBegan, 0.5, ValidateClick)

                    Library:RemoveFromRegistry(Button.Label)
                    Library:AddToRegistry(Button.Label, {TextColor3 = "FontColor"})

                    Button.Label.TextColor3 = Library.FontColor
                    Button.Label.Text = Button.Text
                    task.defer(rawset, Button, 'Locked', false)

                    if Clicked then
                        Library:SafeCallback(Button.Func)
                    end

                    return
                end

                Library:SafeCallback(Button.Func)
            end)
        end

        Button.Outer, Button.Inner, Button.Label = CreateBaseButton(Button)
        Button.Outer.Parent = Container

        InitEvents(Button)

        function Button:AddTooltip(tooltip)
            if type(tooltip) == "string" then
                Library:AddToolTip(tooltip, self.Outer)
            end
            return self
        end

        function Button:AddButton(...)
            local SubButton = {}
            ProcessButtonParams('SubButton', SubButton, ...)

            self.Outer.Size = UDim2.new(0.5, -2, 0, 20)
            SubButton.Outer, SubButton.Inner, SubButton.Label = CreateBaseButton(SubButton)
            SubButton.Outer.Position = UDim2.new(1, 3, 0, 0)
            SubButton.Outer.Size = UDim2.fromOffset(self.Outer.AbsoluteSize.X - 2, self.Outer.AbsoluteSize.Y)
            SubButton.Outer.Parent = self.Outer

            function SubButton:AddTooltip(tooltip)
                if type(tooltip) == "string" then
                    Library:AddToolTip(tooltip, self.Outer)
                end
                return SubButton
            end

            if type(SubButton.Tooltip) == "string" then
                SubButton:AddTooltip(SubButton.Tooltip)
            end

            InitEvents(SubButton)
            return SubButton
        end

        if type(Button.Tooltip) == "string" then
            Button:AddTooltip(Button.Tooltip)
        end

        Groupbox:AddBlank(5)
        Groupbox:Resize()

        return Button
    end

    function Funcs:AddDivider()
        local Groupbox = self
        local Container = self.Container

        local Divider = {Type = "Divider"}

        Groupbox:AddBlank(2)
        local DividerOuter = Library:Create("Frame", {
            BackgroundColor3 = Color3.new(0, 0, 0);
            BorderColor3 = Color3.new(0, 0, 0);
            Size = UDim2.new(1, -4, 0, 5);
            ZIndex = 5;
            Parent = Container
        })

        local DividerInner = Library:Create("Frame", {
            BackgroundColor3 = Library.MainColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 6;
            Parent = DividerOuter
        })

        Library:AddToRegistry(DividerOuter, {BorderColor3 = "Black"})
        Library:AddToRegistry(DividerInner, {BackgroundColor3 = "MainColor", BorderColor3 = "OutlineColor"})
        Groupbox:AddBlank(9)
        Groupbox:Resize()
    end

    function Funcs:AddInput(Index, Info)
        assert(Info.Text, 'AddInput: Missing `Text` string.')

        local Textbox = {
            Value = Info.Default or '';
            Numeric = Info.Numeric or false;
            Finished = Info.Finished or false;
            Type = 'Input';
            Callback = Info.Callback or function(Value) end
        };

        local Groupbox = self
        local Container = Groupbox.Container

        local InputLabel = Library:CreateLabel({
            Size = UDim2.new(1, 0, 0, 15);
            TextSize = 14;
            Text = Info.Text;
            TextXAlignment = Enum.TextXAlignment.Left;
            ZIndex = 5;
            Parent = Container
        })

        Groupbox:AddBlank(1)

        local TextBoxOuter = Library:Create("Frame", {
            BackgroundColor3 = Color3.new(0, 0, 0);
            BorderColor3 = Color3.new(0, 0, 0);
            Size = UDim2.new(1, -4, 0, 20);
            ZIndex = 5;
            Parent = Container
        })

        local TextBoxInner = Library:Create("Frame", {
            BackgroundColor3 = Library.MainColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 6;
            Parent = TextBoxOuter;
        })

        Library:AddToRegistry(TextBoxInner, {
            BackgroundColor3 = "MainColor";
            BorderColor3 = "OutlineColor";
        })

        Library:OnHighlight(TextBoxOuter, TextBoxOuter,
            {BorderColor3 = "AccentColor"},
            {BorderColor3 = "Black"}
        )

        if type(Info.Tooltip) == "string" then
            Library:AddToolTip(Info.Tooltip, TextBoxOuter)
        end

        Library:Create("UIGradient", {
            Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)), ColorSequenceKeypoint.new(1, Color3.fromRGB(212, 212, 212))}),
            Rotation = 90,
            Parent = TextBoxInner
        })

        local Container = Library:Create("Frame", {
            BackgroundTransparency = 1;
            ClipsDescendants = true;

            Position = UDim2.new(0, 5, 0, 0);
            Size = UDim2.new(1, -5, 1, 0);

            ZIndex = 7,
            Parent = TextBoxInner
        })

        local Box = Library:Create("TextBox", {
            BackgroundTransparency = 1;

            Position = UDim2.fromOffset(0, 0),
            Size = UDim2.fromScale(5, 1),

            Font = Library.Font;
            PlaceholderColor3 = Color3.fromRGB(190, 190, 190);
            PlaceholderText = Info.Placeholder or '';

            Text = Info.Default or '';
            TextColor3 = Library.FontColor;
            TextSize = 14;
            TextStrokeTransparency = 0;
            TextXAlignment = Enum.TextXAlignment.Left;

            ZIndex = 7;
            Parent = Container
        })

        Library:ApplyTextStroke(Box)

        function Textbox:SetValue(Text)
            if Info.MaxLength and #Text > Info.MaxLength then
                Text = Text:sub(1, Info.MaxLength)
            end

            if Textbox.Numeric then
                if (not tonumber(Text)) and Text:len() > 0 then
                    Text = Textbox.Value
                end
            end

            Textbox.Value = Text
            Box.Text = Text

            Library:SafeCallback(Textbox.Callback, Textbox.Value);
            Library:SafeCallback(Textbox.Changed, Textbox.Value);
        end

        if Textbox.Finished then
            Box.FocusLost:Connect(function(Enter)
                if not Enter then
                    return
                end

                Textbox:SetValue(Box.Text)
                Library:AttemptSave()
            end)
        else
            Box:GetPropertyChangedSignal('Text'):Connect(function()
                Textbox:SetValue(Box.Text)
                Library:AttemptSave()
            end)
        end

        local function Update()
            local PADDING = 2
            local reveal = Container.AbsoluteSize.X

            if not Box:IsFocused() or Box.TextBounds.X <= reveal - 2 * PADDING then
                Box.Position = UDim2.new(0, PADDING, 0, 0)
            else
                local cursor = Box.CursorPosition
                if cursor ~= -1 then
                    local subtext = string.sub(Box.Text, 1, cursor-1)
                    local width = TextService:GetTextSize(subtext, Box.TextSize, Box.Font, Vector2.new(math.huge, math.huge)).X

                    local currentCursorPos = Box.Position.X.Offset + width

                    if currentCursorPos < PADDING then
                        Box.Position = UDim2.fromOffset(PADDING-width, 0)
                    elseif currentCursorPos > reveal - PADDING - 1 then
                        Box.Position = UDim2.fromOffset(reveal-width-PADDING-1, 0)
                    end
                end
            end
        end

        task.spawn(Update)

        Box:GetPropertyChangedSignal('Text'):Connect(Update)
        Box:GetPropertyChangedSignal('CursorPosition'):Connect(Update)
        Box.FocusLost:Connect(Update)
        Box.Focused:Connect(Update)

        Library:AddToRegistry(Box, {TextColor3 = "FontColor"})

        function Textbox:OnChanged(Func)
            Textbox.Changed = Func
            Func(Textbox.Value)
        end

        Groupbox:AddBlank(5)
        Groupbox:Resize()

        Options[Index] = Textbox
        return Textbox
    end

    function Funcs:AddToggle(Index, Info)
        assert(Info.Text, 'AddInput: Missing `Text` string.')

        local Toggle = {
            Value = Info.Default or false;
            Type = "Toggle";

            Callback = Info.Callback or function(Value) end,
            Addons = {},
            Risky = Info.Risky
        };

        local Groupbox = self
        local Container = Groupbox.Container

        local ToggleOuter = Library:Create("Frame", {
            BackgroundColor3 = Color3.new(0, 0, 0);
            BorderColor3 = Color3.new(0, 0, 0);
            Size = UDim2.new(0, 13, 0, 13);
            ZIndex = 5;
            Parent = Container
        })

        Library:AddToRegistry(ToggleOuter, {BorderColor3 = "Black"})

        local ToggleInner = Library:Create("Frame", {
            BackgroundColor3 = Library.MainColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 6;
            Parent = ToggleOuter
        })

        Library:AddToRegistry(ToggleInner, {
            BackgroundColor3 = "MainColor";
            BorderColor3 = "OutlineColor"
        })

        local ToggleLabel = Library:CreateLabel({
            Size = UDim2.new(0, 216, 1, 0);
            Position = UDim2.new(1, 6, 0, 0);
            TextSize = 14;
            Text = Info.Text;
            TextXAlignment = Enum.TextXAlignment.Left;
            ZIndex = 6;
            Parent = ToggleInner
        })

        Library:Create('UIListLayout', {
            Padding = UDim.new(0, 4);
            FillDirection = Enum.FillDirection.Horizontal;
            HorizontalAlignment = Enum.HorizontalAlignment.Right;
            SortOrder = Enum.SortOrder.LayoutOrder;
            Parent = ToggleLabel
        })

        local ToggleRegion = Library:Create("Frame", {
            BackgroundTransparency = 1;
            Size = UDim2.new(0, 170, 1, 0);
            ZIndex = 8;
            Parent = ToggleOuter
        })

        Library:OnHighlight(ToggleRegion, ToggleOuter,
            {BorderColor3 = "AccentColor"},
            {BorderColor3 = "Black"}
        );

        function Toggle:UpdateColors()
            Toggle:Display()
        end

        if type(Info.Tooltip) == "string" then
            Library:AddToolTip(Info.Tooltip, ToggleRegion)
        end

        function Toggle:Display()
            ToggleInner.BackgroundColor3 = Toggle.Value and Library.AccentColor or Library.MainColor
            ToggleInner.BorderColor3 = Toggle.Value and Library.AccentColorDark or Library.OutlineColor

            Library.RegistryMap[ToggleInner].Properties.BackgroundColor3 = Toggle.Value and "AccentColor" or "MainColor"
            Library.RegistryMap[ToggleInner].Properties.BorderColor3 = Toggle.Value and 'AccentColorDark' or "OutlineColor"
        end

        function Toggle:OnChanged(Func)
            Toggle.Changed = Func
            Func(Toggle.Value)
        end

        function Toggle:SetValue(Bool)
            Bool = (not not Bool)

            Toggle.Value = Bool
            Toggle:Display()

            for _,Addon in next, Toggle.Addons do
                if Addon.Type == 'KeyPicker' and Addon.SyncToggleState then
                    Addon.Toggled = Bool
                    Addon:Update()
                end
            end

            Library:SafeCallback(Toggle.Callback, Toggle.Value);
            Library:SafeCallback(Toggle.Changed, Toggle.Value);
            Library:UpdateDependencyBoxes()
        end

        ToggleRegion.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame() then
                Toggle:SetValue(not Toggle.Value)
                Library:AttemptSave()
            end
        end)

        if Toggle.Risky then
            Library:RemoveFromRegistry(ToggleLabel)
            ToggleLabel.TextColor3 = Library.RiskColor
            Library:AddToRegistry(ToggleLabel, {TextColor3 = 'RiskColor' })
        end

        Toggle:Display()
        Groupbox:AddBlank(Info.BlankSize or 5 + 2)
        Groupbox:Resize()

        Toggle.TextLabel = ToggleLabel
        Toggle.Container = Container
        setmetatable(Toggle, BaseAddons)

        Toggles[Index] = Toggle
        Library:UpdateDependencyBoxes()
        return Toggle
    end

    function Funcs:AddSlider(Index, Info)
        assert(Info.Default, 'AddSlider: Missing default value.')
        assert(Info.Text, 'AddSlider: Missing slider Text.')
        assert(Info.Min, 'AddSlider: Missing minimum value.')
        assert(Info.Max, 'AddSlider: Missing maximum value.')
        assert(Info.Rounding, 'AddSlider: Missing rounding value.')

        local Slider = {
            Value = Info.Default,
            Min = Info.Min,
            Max = Info.Max,
            Rounding = Info.Rounding,
            MaxSize = 232,
            Type = 'Slider',
            Callback = Info.Callback or function(Value) end
        };

        local Groupbox = self
        local Container = Groupbox.Container

        if not Info.Compact then
            Library:CreateLabel({
                Size = UDim2.new(1, 0, 0, 10),
                TextSize = 14,
                Text = Info.Text,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Bottom,
                ZIndex = 5,
                Parent = Container
            })
            Groupbox:AddBlank(3)
        end

        local SliderOuter = Library:Create("Frame", {
            BackgroundColor3 = Color3.new(0, 0, 0);
            BorderColor3 = Color3.new(0, 0, 0);
            Size = UDim2.new(1, -4, 0, 13);
            ZIndex = 5;
            Parent = Container
        })

        Library:AddToRegistry(SliderOuter, {BorderColor3 = "Black"})

        local SliderInner = Library:Create("Frame", {
            BackgroundColor3 = Library.MainColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 6;
            Parent = SliderOuter
        })

        Library:AddToRegistry(SliderInner, {
            BackgroundColor3 = "MainColor";
            BorderColor3 = "OutlineColor"
        })

        local Fill = Library:Create("Frame", {
            BackgroundColor3 = Library.AccentColor;
            BorderColor3 = Library.AccentColorDark;
            Size = UDim2.new(0, 0, 1, 0);
            ZIndex = 7;
            Parent = SliderInner
        })

        Library:AddToRegistry(Fill, {
            BackgroundColor3 = "AccentColor";
            BorderColor3 = 'AccentColorDark'
        })

        local HideBorderRight = Library:Create("Frame", {
            BackgroundColor3 = Library.AccentColor;
            BorderSizePixel = 0;
            Position = UDim2.new(1, 0, 0, 0);
            Size = UDim2.new(0, 1, 1, 0);
            ZIndex = 8;
            Parent = Fill
        })

        Library:AddToRegistry(HideBorderRight, {BackgroundColor3 = "AccentColor"})

        local DisplayLabel = Library:CreateLabel({
            Size = UDim2.new(1, 0, 1, 0);
            TextSize = 14;
            Text = 'Infinite';
            ZIndex = 9;
            Parent = SliderInner
        })

        Library:OnHighlight(SliderOuter, SliderOuter, {BorderColor3 = "AccentColor"}, {BorderColor3 = "Black"})

        if type(Info.Tooltip) == "string" then
            Library:AddToolTip(Info.Tooltip, SliderOuter)
        end

        function Slider:UpdateColors()
            Fill.BackgroundColor3 = Library.AccentColor;
            Fill.BorderColor3 = Library.AccentColorDark
        end

        function Slider:Display()
            local Suffix = Info.Suffix or ''

            if Info.Compact then
                DisplayLabel.Text = Info.Text .. ': ' .. Slider.Value .. Suffix
            elseif Info.HideMax then
                DisplayLabel.Text = string.format('%s', Slider.Value .. Suffix)
            else
                DisplayLabel.Text = string.format('%s/%s', Slider.Value .. Suffix, Slider.Max .. Suffix)
            end

            local X = math.ceil(Library:MapValue(Slider.Value, Slider.Min, Slider.Max, 0, Slider.MaxSize))
            Fill.Size = UDim2.new(0, X, 1, 0)

            HideBorderRight.Visible = not (X == Slider.MaxSize or X == 0)
        end

        function Slider:OnChanged(Func)
            Slider.Changed = Func
            Func(Slider.Value)
        end

        local function Round(Value)
            if Slider.Rounding == 0 then
                return math.floor(Value)
            end


            return tonumber(string.format('%.' .. Slider.Rounding .. 'f', Value))
        end

        function Slider:GetValueFromXOffset(X)
            return Round(Library:MapValue(X, 0, Slider.MaxSize, Slider.Min, Slider.Max))
        end

        function Slider:SetValue(String)
            local Number = tonumber(String)
            if not Number then
                return
            end

            Number = math.clamp(Number, Slider.Min, Slider.Max)

            Slider.Value = Number
            Slider:Display()

            Library:SafeCallback(Slider.Callback, Slider.Value)
            Library:SafeCallback(Slider.Changed, Slider.Value)
            Library:UpdateDependencyBoxes()
        end

        SliderInner.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame() then
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
            end
        end)

        Slider:Display()
        Groupbox:AddBlank(Info.BlankSize or 6)
        Groupbox:Resize()

        Options[Index] = Slider
        return Slider
    end

    function Funcs:AddDropdown(Index, Info)
        if Info.SpecialType == 'Player' then
            Info.Values = GetPlayersString()
            Info.AllowNull = true
        elseif Info.SpecialType == 'Team' then
            Info.Values = GetTeamsString()
            Info.AllowNull = true
        end

        assert(Info.Values, 'AddDropdown: Missing dropdown value list.')
        assert(Info.AllowNull or Info.Default, 'AddDropdown: Missing default value. Pass `AllowNull` as true if this was intentional.')

        if (not Info.Text) then
            Info.Compact = true
        end

        local Dropdown = {
            Values = Info.Values;
            Value = Info.Multi and {};
            Multi = Info.Multi;
            Type = 'Dropdown';
            SpecialType = Info.SpecialType;
            Callback = Info.Callback or function(Value) end
        };

        local Groupbox = self
        local Container = Groupbox.Container

        local RelativeOffset = 0

        if not Info.Compact then
            local DropdownLabel = Library:CreateLabel({
                Size = UDim2.new(1, 0, 0, 10);
                TextSize = 14;
                Text = Info.Text;
                TextXAlignment = Enum.TextXAlignment.Left;
                TextYAlignment = Enum.TextYAlignment.Bottom;
                ZIndex = 5;
                Parent = Container
            })

            Groupbox:AddBlank(3)
        end

        for _,Element in next, Container:GetChildren() do
            if not Element:IsA('UIListLayout') then
                RelativeOffset = RelativeOffset + Element.Size.Y.Offset
            end
        end

        local DropdownOuter = Library:Create("Frame", {
            BackgroundColor3 = Color3.new(0, 0, 0);
            BorderColor3 = Color3.new(0, 0, 0);
            Size = UDim2.new(1, -4, 0, 20);
            ZIndex = 5;
            Parent = Container
        })

        Library:AddToRegistry(DropdownOuter, {BorderColor3 = "Black"})

        local DropdownInner = Library:Create("Frame", {
            BackgroundColor3 = Library.MainColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 6;
            Parent = DropdownOuter
        })

        Library:AddToRegistry(DropdownInner, {
            BackgroundColor3 = "MainColor";
            BorderColor3 = "OutlineColor"
        })

        Library:Create("UIGradient", {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(212, 212, 212))
            }),
            Rotation = 90,
            Parent = DropdownInner
        })

        local DropdownArrow = Library:Create("ImageLabel", {
            AnchorPoint = Vector2.new(0, 0.5);
            BackgroundTransparency = 1;
            Position = UDim2.new(1, -16, 0.5, 0);
            Size = UDim2.new(0, 12, 0, 12);
            Image = 'http://www.roblox.com/asset/?id=6282522798';
            ZIndex = 8;
            Parent = DropdownInner
        })

        local ItemList = Library:CreateLabel({
            Position = UDim2.new(0, 5, 0, 0);
            Size = UDim2.new(1, -5, 1, 0);
            TextSize = 14;
            Text = '--';
            TextXAlignment = Enum.TextXAlignment.Left;
            TextWrapped = true;
            ZIndex = 7;
            Parent = DropdownInner
        })

        Library:OnHighlight(DropdownOuter, DropdownOuter, {BorderColor3 = "AccentColor"}, {BorderColor3 = "Black"})

        if type(Info.Tooltip) == "string" then
            Library:AddToolTip(Info.Tooltip, DropdownOuter)
        end

        local MAX_DROPDOWN_ITEMS = 8

        local ListOuter = Library:Create("Frame", {
            BackgroundColor3 = Color3.new(0, 0, 0);
            BorderColor3 = Color3.new(0, 0, 0);
            ZIndex = 20;
            Visible = false;
            Parent = ScreenGui
        })

        local function RecalculateListPosition()
            ListOuter.Position = UDim2.fromOffset(DropdownOuter.AbsolutePosition.X, DropdownOuter.AbsolutePosition.Y + DropdownOuter.Size.Y.Offset + 1)
        end

        local function RecalculateListSize(YSize)
            ListOuter.Size = UDim2.fromOffset(DropdownOuter.AbsoluteSize.X, YSize or (MAX_DROPDOWN_ITEMS * 20 + 2))
        end

        RecalculateListPosition()
        RecalculateListSize()

        DropdownOuter:GetPropertyChangedSignal('AbsolutePosition'):Connect(RecalculateListPosition)

        local ListInner = Library:Create("Frame", {
            BackgroundColor3 = Library.MainColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            BorderSizePixel = 0;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 21;
            Parent = ListOuter
        })

        Library:AddToRegistry(ListInner, {
            BackgroundColor3 = "MainColor";
            BorderColor3 = "OutlineColor"
        })

        local Scrolling = Library:Create("ScrollingFrame", {
            BackgroundTransparency = 1;
            BorderSizePixel = 0;
            CanvasSize = UDim2.new(0, 0, 0, 0);
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 21;
            Parent = ListInner;

            TopImage = 'rbxasset://textures/ui/Scroll/scroll-middle.png',
            BottomImage = 'rbxasset://textures/ui/Scroll/scroll-middle.png',

            ScrollBarThickness = 3,
            ScrollBarImageColor3 = Library.AccentColor
        })

        Library:AddToRegistry(Scrolling, {ScrollBarImageColor3 = "AccentColor"})

        Library:Create('UIListLayout', {
            Padding = UDim.new(0, 0);
            FillDirection = Enum.FillDirection.Vertical;
            SortOrder = Enum.SortOrder.LayoutOrder;
            Parent = Scrolling
        })

        function Dropdown:Display()
            local Values = Dropdown.Values
            local Str = ''

            if Info.Multi then
                for Index, Value in next, Values do
                    if Dropdown.Value[Value] then
                        Str = Str .. Value .. ', '
                    end
                end

                Str = Str:sub(1, #Str - 2)
            else
                Str = Dropdown.Value or ''
            end

            ItemList.Text = (Str == '' and '--' or Str)
        end

        function Dropdown:GetActiveValues()
            if Info.Multi then
                local T = {}

                for Value, Bool in next, Dropdown.Value do
                    table.insert(T, Value)
                end

                return T
            else
                return Dropdown.Value and 1 or 0
            end
        end

        function Dropdown:BuildDropdownList()
            local Values = Dropdown.Values
            local Buttons = {}

            for _,Element in next, Scrolling:GetChildren() do
                if not Element:IsA('UIListLayout') then
                    Element:Destroy()
                end
            end

            local Count = 0

            for Index, Value in next, Values do
                local Table = {}

                Count += 1

                local Button = Library:Create("Frame", {
                    BackgroundColor3 = Library.MainColor;
                    BorderColor3 = Library.OutlineColor;
                    BorderMode = Enum.BorderMode.Middle;
                    Size = UDim2.new(1, -1, 0, 20);
                    ZIndex = 23;
                    Active = true,
                    Parent = Scrolling
                })

                Library:AddToRegistry(Button, {
                    BackgroundColor3 = "MainColor";
                    BorderColor3 = "OutlineColor"
                })

                local ButtonLabel = Library:CreateLabel({
                    Active = false;
                    Size = UDim2.new(1, -6, 1, 0);
                    Position = UDim2.new(0, 6, 0, 0);
                    TextSize = 14;
                    Text = Value;
                    TextXAlignment = Enum.TextXAlignment.Left;
                    ZIndex = 25;
                    Parent = Button
                })

                Library:OnHighlight(Button, Button, {BorderColor3 = "AccentColor", ZIndex = 24}, {BorderColor3 = "OutlineColor", ZIndex = 23})

                local Selected

                if Info.Multi then
                    Selected = Dropdown.Value[Value]
                else
                    Selected = Dropdown.Value == Value
                end

                function Table:UpdateButton()
                    if Info.Multi then
                        Selected = Dropdown.Value[Value]
                    else
                        Selected = Dropdown.Value == Value
                    end

                    ButtonLabel.TextColor3 = Selected and Library.AccentColor or Library.FontColor
                    Library.RegistryMap[ButtonLabel].Properties.TextColor3 = Selected and "AccentColor" or "FontColor"
                end

                ButtonLabel.InputBegan:Connect(function(Input)
                    if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                        local Try = not Selected

                        if Dropdown:GetActiveValues() ~= 1 or Try or Info.AllowNull then
                            if Info.Multi then
                                Selected = Try
                                if Selected then
                                    Dropdown.Value[Value] = true
                                else
                                    Dropdown.Value[Value] = nil
                                end
                            else
                                Selected = Try
                                if Selected then
                                    Dropdown.Value = Value
                                else
                                    Dropdown.Value = nil
                                end

                                for _,OtherButton in next, Buttons do
                                    OtherButton:UpdateButton()
                                end
                            end

                            Table:UpdateButton()
                            Dropdown:Display()

                            Library:SafeCallback(Dropdown.Callback, Dropdown.Value)
                            Library:SafeCallback(Dropdown.Changed, Dropdown.Value)
                            Library:AttemptSave()
                            Library:UpdateDependencyBoxes()
                        end
                    end
                end)

                Table:UpdateButton()
                Dropdown:Display()
                Buttons[Button] = Table
            end

            Scrolling.CanvasSize = UDim2.fromOffset(0, (Count * 20) + 1)
            RecalculateListSize(math.clamp(Count * 20, 0, MAX_DROPDOWN_ITEMS * 20) + 1)
        end

        function Dropdown:SetValues(NewValues)
            if NewValues then
                Dropdown.Values = NewValues
            end
            Dropdown:BuildDropdownList()
        end

        function Dropdown:OpenDropdown()
            ListOuter.Visible = true
            Library.OpenedFrames[ListOuter] = true
            DropdownArrow.Rotation = 180
        end

        function Dropdown:CloseDropdown()
            ListOuter.Visible = false
            Library.OpenedFrames[ListOuter] = nil
            DropdownArrow.Rotation = 0
        end

        function Dropdown:OnChanged(Func)
            Dropdown.Changed = Func
            Func(Dropdown.Value)
        end

        function Dropdown:SetValue(Value)
            if Dropdown.Multi then
                local nTable = {}

                for Index in next, Value do
                    if table.find(Dropdown.Values, Index) then
                        nTable[Index] = true
                    end
                end

                Dropdown.Value = nTable
            else
                if (not Value) then
                    Dropdown.Value = nil
                elseif table.find(Dropdown.Values, Value) then
                    Dropdown.Value = Value
                end
            end

            Dropdown:BuildDropdownList()
            Library:SafeCallback(Dropdown.Callback, Dropdown.Value);
            Library:SafeCallback(Dropdown.Changed, Dropdown.Value);
            Library:UpdateDependencyBoxes()
        end

        DropdownOuter.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame() then
                if ListOuter.Visible then
                    Dropdown:CloseDropdown()
                else
                    Dropdown:OpenDropdown()
                end
            end
        end)

        UserInputService.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                local AbsolutePosition, AbsoluteSize = ListOuter.AbsolutePosition, ListOuter.AbsoluteSize
                if Mouse.X < AbsolutePosition.X or Mouse.X > AbsolutePosition.X + AbsoluteSize.X or Mouse.Y < (AbsolutePosition.Y - 20 - 1) or Mouse.Y > AbsolutePosition.Y + AbsoluteSize.Y then
                    Dropdown:CloseDropdown()
                end
            end
        end)

        Dropdown:BuildDropdownList()
        Dropdown:Display()

        local Defaults = {}

        if type(Info.Default) == "string" then
            local Index = table.find(Dropdown.Values, Info.Default)
            if Index then
                table.insert(Defaults, Index)
            end
        elseif type(Info.Default) == 'table' then
            for Index in next, Info.Default do
                table.insert(Defaults, Index)
            end
        elseif type(Info.Default) == 'number' and Dropdown.Values[Info.Default] ~= nil then
            table.insert(Defaults, Info.Default)
        end

        for Index in next, Defaults do
            if Info.Multi then
                Dropdown.Value[Dropdown.Values[Index]] = true
            else
                Dropdown.Value = Dropdown.Values[Index]
                break
            end
        end

        Dropdown:BuildDropdownList()
        Dropdown:Display()

        Groupbox:AddBlank(Info.BlankSize or 5)
        Groupbox:Resize()

        Library:UpdateDependencyBoxes()
        Options[Index] = Dropdown
        return Dropdown
    end

    function Funcs:AddPrioritySelector(Index, Info)
        assert(type(Info) == 'table', 'AddPrioritySelector: Info must be a table.')
        assert(type(Info.Default) == 'table', 'AddPrioritySelector: Info.Default must be an array.')

        local Groupbox = self
        local Container = Groupbox.Container
        local ItemHeight = 20
        local ItemGap = 2
        local RowH = ItemHeight + ItemGap
        local TotalItems = #Info.Default
        local ListH = ItemHeight * TotalItems + ItemGap * math.max(0, TotalItems - 1)
        local TitleH = (Info.Text and Info.Text ~= '') and 15 or 0
        local WrapperH = TitleH + ListH

        local Items = {}
        local OrderedList = {}
        for Index, Value in ipairs(Info.Default) do
            OrderedList[Index] = Value
        end

        local PrioSelector = {
            Type = 'PrioritySelector',
            Value  = OrderedList,
            Callback = Info.Callback or function() end
        }

        local Wrapper = Library:Create("Frame", {
            BackgroundTransparency = 1;
            Size = UDim2.new(1, -4, 0, WrapperH);
            ZIndex = 5;
            Parent = Container
        })

        if TitleH > 0 then
            Library:CreateLabel({
                Size = UDim2.new(1, 0, 0, TitleH - 1);
                TextSize = 13;
                Text = Info.Text;
                TextXAlignment = Enum.TextXAlignment.Left;
                ZIndex = 6;
                Parent = Wrapper
            })
        end

        local ListFrame = Library:Create("Frame", {
            BackgroundTransparency = 1;
            Position = UDim2.new(0, 0, 0, TitleH);
            Size = UDim2.new(1, 0, 0, ListH);
            ZIndex = 5;
            Parent = Wrapper
        })

        local function GetSlotY(Index)
            return (Index - 1) * RowH
        end

        local function RefreshRankLabels()
            for i, frm in ipairs(Items) do
                local lbl = frm:FindFirstChild('RankLabel')
                if lbl then
                    lbl.Text = tostring(i) .. '.'
                end
            end
        end

        local function SnapAllPositions()
            for i, frm in ipairs(Items) do
                frm.Position = UDim2.new(0, 0, 0, GetSlotY(i))
            end
        end

        local function FireCallback()
            local Order = {}
            for i, f in ipairs(Items) do
                Order[i] = f.Name
            end
            OrderedList = Order
            PrioSelector.Value = Order
            Library:SafeCallback(PrioSelector.Callback, Order)
        end

        local Drag = {Active = false}

        local function MakeItem(Text, Index)
            local ItemFrame = Library:Create("Frame", {
                Name = Text,
                BackgroundColor3 = Library.MainColor,
                BorderColor3 = Library.OutlineColor,
                Position = UDim2.new(0, 0, 0, GetSlotY(Index)),
                Size = UDim2.new(1, 0, 0, ItemHeight),
                ZIndex = 6,
                Parent = ListFrame
            })
            Library:AddToRegistry(ItemFrame, {BackgroundColor3 = "MainColor", BorderColor3 = "OutlineColor"})

            local RankLbl = Library:CreateLabel({
                Name = 'RankLabel';
                Size = UDim2.new(0, 16, 1, 0);
                Position = UDim2.new(0, 2, 0, 0);
                TextSize = 12;
                Text = tostring(Index) .. '.';
                TextXAlignment = Enum.TextXAlignment.Center;
                ZIndex = 7;
                Parent = ItemFrame
            })

            Library:CreateLabel({
                Size = UDim2.new(1, -30, 1, 0);
                Position = UDim2.new(0, 19, 0, 0);
                TextSize = 13;
                Text = Text;
                TextXAlignment = Enum.TextXAlignment.Left;
                ZIndex = 7;
                Parent = ItemFrame
            })

            local Handle = Library:Create('TextLabel', {
                BackgroundTransparency = 1;
                Position = UDim2.new(1, -14, 0, 0);
                Size = UDim2.new(0, 12, 1, 0);
                Text = '≡';
                TextColor3 = Library.FontColor;
                TextSize = 14;
                Font = Library.Font;
                ZIndex = 8;
                Parent = ItemFrame
            })
            Library:AddToRegistry(Handle, {TextColor3 = "FontColor" })

            ItemFrame.InputBegan:Connect(function(Input)
                if Input.UserInputType ~= Enum.UserInputType.MouseButton1 or Drag.Active then
                    return
                end

                local selfIndex = table.find(Items, ItemFrame)
                if not selfIndex then
                    return
                end

                Drag.Active = true
                Drag.Item = ItemFrame
                Drag.StartMouseY = Mouse.Y
                Drag.StartSlotY  = GetSlotY(selfIndex)

                ItemFrame.ZIndex = 12
                for _,Child in ipairs(ItemFrame:GetChildren()) do
                    Child.ZIndex = 14
                end
                ItemFrame.BorderColor3 = Library.AccentColor

                local MoveConnection, EndConnection

                MoveConnection = UserInputService.InputChanged:Connect(function(Input)
                    if Input.UserInputType ~= Enum.UserInputType.MouseMovement then
                        return
                    end

                    local ClampY = math.clamp(Drag.StartSlotY + (Mouse.Y - Drag.StartMouseY), 0, ListH - ItemHeight)
                    ItemFrame.Position = UDim2.new(0, 0, 0, ClampY)

                    local Centre  = ClampY + ItemHeight * 0.5
                    local TargetIndex = math.clamp(math.round(Centre / RowH) + 1 - 1, 1, TotalItems)
                    TargetIndex = math.clamp(math.floor(Centre / RowH) + 1, 1, TotalItems)

                    local DragIndex = table.find(Items, ItemFrame)
                    if DragIndex and TargetIndex ~= DragIndex then
                        table.remove(Items, DragIndex)
                        table.insert(Items, TargetIndex, ItemFrame)
                        for i, f in ipairs(Items) do
                            if f ~= ItemFrame then
                                f.Position = UDim2.new(0, 0, 0, GetSlotY(i))
                            end
                        end
                        RefreshRankLabels()
                    end
                end)

                EndConnection = UserInputService.InputEnded:Connect(function(Input)
                    if Input.UserInputType ~= Enum.UserInputType.MouseButton1 then
                        return
                    end

                    MoveConnection:Disconnect()
                    EndConnection:Disconnect()

                    Drag.Active = false
                    ItemFrame.ZIndex = 6
                    for _,Child in ipairs(ItemFrame:GetChildren()) do
                        Child.ZIndex = 7
                    end
                    Library:AddToRegistry(ItemFrame, {BackgroundColor3 = "MainColor", BorderColor3 = "OutlineColor"})
                    ItemFrame.BorderColor3 = Library.OutlineColor

                    SnapAllPositions()
                    RefreshRankLabels()
                    FireCallback()
                end)
            end)

            Items[Index] = ItemFrame
        end

        for Index, Value in ipairs(OrderedList) do
            MakeItem(Value, Index)
        end

        function PrioSelector:SetValue(NewOrder)
            assert(type(NewOrder) == 'table')
            local NewItems = {}
            for Index, name in ipairs(NewOrder) do
                for _,frm in ipairs(Items) do
                    if frm.Name == name then
                        NewItems[Index] = frm; break
                    end
                end
            end
            Items = NewItems
            SnapAllPositions()
            RefreshRankLabels()
            OrderedList = NewOrder
            PrioSelector.Value = NewOrder
        end

        if Index then
            Options[Index] = PrioSelector
        end

        Groupbox:AddBlank(5)
        Groupbox:Resize()

        return PrioSelector
    end

    function Funcs:AddDependencyBox()
        local Depbox = {Dependencies = {}}
        
        local Groupbox = self
        local Container = Groupbox.Container

        local Holder = Library:Create("Frame", {
            BackgroundTransparency = 1;
            Size = UDim2.new(1, 0, 0, 0);
            Visible = false;
            Parent = Container
        })

        local Frame = Library:Create("Frame", {
            BackgroundTransparency = 1;
            Size = UDim2.new(1, 0, 1, 0);
            Visible = true;
            Parent = Holder
        })

        local Layout = Library:Create('UIListLayout', {
            FillDirection = Enum.FillDirection.Vertical;
            SortOrder = Enum.SortOrder.LayoutOrder;
            Parent = Frame
        })

        function Depbox:Resize()
            Holder.Size = UDim2.new(1, 0, 0, Layout.AbsoluteContentSize.Y);
            Groupbox:Resize()
        end

        Layout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
            Depbox:Resize()
        end)

        Holder:GetPropertyChangedSignal('Visible'):Connect(function()
            Depbox:Resize()
        end)

        function Depbox:Update()
            for _,Dependency in next, Depbox.Dependencies do
                local Elem = Dependency[1];
                local Value = Dependency[2];
                local Match = false

                if type(Value) == "table" then
                    for _,Value in ipairs(Value) do
                        if Elem.Value == Value then
                            Match = true break
                        end
                    end
                else
                    Match = (Elem.Value == Value)
                end

                if not Match then
                    Holder.Visible = false
                    Depbox:Resize()
                    return
                end
            end

            Holder.Visible = true
            Depbox:Resize()

            if not Holder.Visible then
                Library:UpdateDependencyBoxes()
            end
        end

        function Depbox:SetupDependencies(Dependencies)
            for _,Dependency in next, Dependencies do
                assert(type(Dependency) == 'table', 'SetupDependencies: Dependency is not of type `table`.')
                assert(Dependency[1], 'SetupDependencies: Dependency is missing element argument.')
                assert(Dependency[2] ~= nil, 'SetupDependencies: Dependency is missing value argument.')
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

    function Funcs:CreateConfigurationManager(BasePath, Extension, TablesToSave)
        local ConfigurationFolder = BasePath .. "/Configs"
        local AutoloadFile = BasePath .. "/Autoload" .. Extension
        local ConfigurationManager = {CurrentConfigurationProfile = "", Buttons = {}}

        local function SerializeValue(Value)
            if type(Value) == "table" then
                local Data = {}
                for k, v in next, Value do
                    Data[k] = SerializeValue(v)
                end
                return Data
            end
            return typeof(Value) == "Color3" and {Type = "Color3", Hex = Value:ToHex()} or Value
        end

        local function DeserializeRecursive(CurrentValue, DecodedValue)
            if type(DecodedValue) == "table" and DecodedValue.Type == "Color3" and DecodedValue.Hex then
                return Color3.fromHex(DecodedValue.Hex)
            elseif type(CurrentValue) == "table" and type(DecodedValue) == "table" then
                table.clear(CurrentValue)
                for SubKey, SubValue in next, DecodedValue do
                    CurrentValue[SubKey] = DeserializeRecursive(CurrentValue[SubKey], SubValue)
                end
                return CurrentValue
            else
                return DecodedValue
            end
        end

        local function GetConfigurations()
            if not isfolder(ConfigurationFolder) then
                makefolder(ConfigurationFolder)
            end

            local Configurations = {}
            for _,FilePath in ipairs(listfiles(ConfigurationFolder)) do
                local Name = FilePath:match("([^/\\]+)$")
                if Name and Name:match("%" .. Extension .. "$") then
                    table.insert(Configurations, (Name:gsub("%" .. Extension .. "$", "")))
                end
            end
            return Configurations
        end

        local function LoadConfigurationProfile(ProfileName)
            local Path = ConfigurationFolder .. "/" .. ProfileName .. Extension
            local Content = isfile(Path) and readfile(Path)
            if not Content or #Content <= 0 then
                return
            end

            local Success, Data = pcall(HttpService.JSONDecode, HttpService, Content)
            if Success then
                for _,Configuration in ipairs(TablesToSave) do
                    for Setting in next, Configuration do
                        if string.find(string.lower(Setting), "inactive") then
                            continue
                        end

                        local Value = Data[Setting]
                        if Value == nil then
                            continue
                        end
                        Configuration[Setting] = DeserializeRecursive(Configuration[Setting], Value)
                        task.defer(function()
                            if Toggles[Setting] then
                                Toggles[Setting]:SetValue(Configuration[Setting])
                            elseif Options[Setting] then
                                if Options[Setting].Type == "ColorPicker" then
                                    Options[Setting]:SetValueRGB(Configuration[Setting], Data[Setting .. "Transparency"])
                                elseif Options[Setting].Type == "KeyPicker" then
                                    Options[Setting]:SetValue({Configuration[Setting], Data[Setting .. "Mode"] or "Toggle"})
                                else
                                    Options[Setting]:SetValue(Configuration[Setting])
                                end
                            end
                        end)
                    end
                end
            end
        end

        self:AddInput("ConfigurationInput", {
            Text = "Configuration Profile",
            Default = "",
            Placeholder = "Name",
            Numeric = false,
            Finished = false,
            Callback = function(Value)
                ConfigurationManager.CurrentConfigurationProfile = Value
            end
        })

        self:AddDropdown("ConfigurationDropdown", {
            Text = "Profiles",
            Default = "",
            Values = GetConfigurations(),
            Callback = function(Value)
                ConfigurationManager.CurrentConfigurationProfile = Value

                if Options.ConfigurationInput then
                    Options.ConfigurationInput:SetValue(Value)
                end

                if ConfigurationManager.Buttons.SetAutoload and ConfigurationManager.Buttons.RemoveAutoload then
                    local IsAutoload = isfile(AutoloadFile) and readfile(AutoloadFile) == Value
                    ConfigurationManager.Buttons.SetAutoload.Outer.Visible = not IsAutoload
                    ConfigurationManager.Buttons.RemoveAutoload.Outer.Visible = IsAutoload
                end
            end
        })

        local function SaveConfigurationProfile()
            local Name = ConfigurationManager.CurrentConfigurationProfile
            if Name == "" then
                return
            end

            local Data = {}
            for _,TableOfSettings in ipairs(TablesToSave) do
                for Setting, Value in next, TableOfSettings do
                    if Setting == "MenuToggleKeybind" then
                        continue
                    end
                    Data[Setting] = SerializeValue(Value)
                end
            end

            for Index, Option in next, Library.Options do
                if type(Option) == "table" and type(Option.Type) == "string" then
                    if Option.Type == "KeyPicker" and type(Option.Mode) == "string" then
                        Data[Index .. "Mode"] = Option.Mode
                    elseif Option.Type == "ColorPicker" then
                        Data[Index .. "Transparency"] = Option.Transparency or 0
                    end
                end
            end

            if not isfolder(ConfigurationFolder) then
                makefolder(ConfigurationFolder)
            end

            writefile(ConfigurationFolder .. "/" .. Name .. Extension, HttpService:JSONEncode(Data))
            Library:Notify("Saved Configuration Profile: " .. Name, 3)

            Options.ConfigurationDropdown:SetValues(GetConfigurations())
            Options.ConfigurationDropdown:SetValue(Name)
        end

        self:AddButton({Text = "Save", Func = function()
            SaveConfigurationProfile()
        end}):AddButton({Text = "Load", Func = function()
            local Name = ConfigurationManager.CurrentConfigurationProfile
            if Name == "" then
                return
            end

            LoadConfigurationProfile(Name)
            Library:Notify("Loaded Configuration Profile: " .. Name, 3)
        end})

        self:AddButton({Text = "Delete", Func = function()
            local Name = ConfigurationManager.CurrentConfigurationProfile
            if Name == "" then
                return
            end

            local Path = ConfigurationFolder .. "/" .. Name .. Extension
            if isfile(Path) then
                delfile(Path)
                Library:Notify("Deleted config: " .. Name, 3)

                if isfile(AutoloadFile) and readfile(AutoloadFile) == Name then
                    delfile(AutoloadFile)
                end

                ConfigurationManager.CurrentConfigurationProfile = ""
                Options.ConfigurationInput:SetValue("")
                Options.ConfigurationDropdown:SetValues(GetConfigurations())
                Options.ConfigurationDropdown:SetValue(nil)
            end
        end}):AddButton({Text = "Refresh List", Func = function()
            Options.ConfigurationDropdown:SetValues(GetConfigurations())
        end})

        ConfigurationManager.Buttons.SetAutoload = self:AddButton({Text = "Set as Autoload", Func = function()
            local Name = ConfigurationManager.CurrentConfigurationProfile
            if Name == "" then
                return
            end

            writefile(AutoloadFile, Name)
            Library:Notify("Set " .. Name .. " as Autoload.", 3)
            ConfigurationManager.Buttons.SetAutoload.Outer.Visible = false
            ConfigurationManager.Buttons.RemoveAutoload.Outer.Visible = true
        end})

        ConfigurationManager.Buttons.RemoveAutoload = self:AddButton({Text = "Remove Autoload", Func = function()
            if isfile(AutoloadFile) then
                delfile(AutoloadFile)
                Library:Notify("Removed Configuration Profile from Autoload.", 3)
            end
            ConfigurationManager.Buttons.SetAutoload.Outer.Visible = true
            ConfigurationManager.Buttons.RemoveAutoload.Outer.Visible = false
        end})

        ConfigurationManager.Buttons.RemoveAutoload.Outer.Visible = false

        return function()
            if isfile(AutoloadFile) then
                local Name = readfile(AutoloadFile)
                if Name and Name ~= "" then
                    LoadConfigurationProfile(Name)
                    Library:Notify("Profile '" .. Name .. "' was loaded successfully.", 3)
                    Options.ConfigurationDropdown:SetValue(Name)
                end
            end
        end
    end

    BaseGroupbox.__index = Funcs
    BaseGroupbox.__namecall = function(Table, Key, ...)
        return Funcs[Key](...)
    end
end

do
    Library.NotificationArea = Library:Create("Frame", {
        BackgroundTransparency = 1;
        Position = UDim2.new(0, 0, 0, 40);
        Size = UDim2.new(0, 300, 0, 200);
        ZIndex = 100;
        Parent = ScreenGui
    })

    Library:Create('UIListLayout', {
        Padding = UDim.new(0, 4);
        FillDirection = Enum.FillDirection.Vertical;
        SortOrder = Enum.SortOrder.LayoutOrder;
        Parent = Library.NotificationArea
    })

    local WatermarkOuter = Library:Create("Frame", {
        BorderColor3 = Color3.new(0, 0, 0);
        Position = UDim2.new(0, 100, 0, -25);
        Size = UDim2.new(0, 213, 0, 20);
        ZIndex = 200;
        Visible = false;
        Parent = ScreenGui
    })

    local WatermarkInner = Library:Create("Frame", {
        BackgroundColor3 = Library.MainColor;
        BorderColor3 = Library.AccentColor;
        BorderMode = Enum.BorderMode.Inset;
        Size = UDim2.new(1, 0, 1, 0);
        ZIndex = 201;
        Parent = WatermarkOuter
    })

    Library:AddToRegistry(WatermarkInner, {BorderColor3 = "AccentColor"})

    local InnerFrame = Library:Create("Frame", {
        BackgroundColor3 = Color3.new(1, 1, 1);
        BorderSizePixel = 0;
        Position = UDim2.new(0, 1, 0, 1);
        Size = UDim2.new(1, -2, 1, -2);
        ZIndex = 202;
        Parent = WatermarkInner
    })

    local Gradient = Library:Create("UIGradient", {
        Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Library:GetDarkerColor(Library.MainColor)), ColorSequenceKeypoint.new(1, Library.MainColor)}),
        Rotation = -90,
        Parent = InnerFrame
    })

    Library:AddToRegistry(Gradient, {
        Color = function()
            return ColorSequence.new({
                ColorSequenceKeypoint.new(0, Library:GetDarkerColor(Library.MainColor)),
                ColorSequenceKeypoint.new(1, Library.MainColor),
            })
        end
    })

    local WatermarkLabel = Library:CreateLabel({
        Position = UDim2.new(0, 5, 0, 0);
        Size = UDim2.new(1, -4, 1, 0);
        TextSize = 14;
        TextXAlignment = Enum.TextXAlignment.Left;
        ZIndex = 203;
        Parent = InnerFrame;
    })

    Library.Watermark = WatermarkOuter;
    Library.WatermarkText = WatermarkLabel;
    Library:MakeDraggable(Library.Watermark);



    local KeybindOuter = Library:Create("Frame", {
        AnchorPoint = Vector2.new(0, 0.5);
        BorderColor3 = Color3.new(0, 0, 0);
        Position = UDim2.new(0, 10, 0.5, 0);
        Size = UDim2.new(0, 210, 0, 20);
        Visible = false;
        ZIndex = 100;
        Parent = ScreenGui;
    })

    local KeybindInner = Library:Create("Frame", {
        BackgroundColor3 = Library.MainColor;
        BorderColor3 = Library.OutlineColor;
        BorderMode = Enum.BorderMode.Inset;
        Size = UDim2.new(1, 0, 1, 0);
        ZIndex = 101;
        Parent = KeybindOuter;
    })

    Library:AddToRegistry(KeybindInner, {BackgroundColor3 = "MainColor", BorderColor3 = "OutlineColor"}, true)

    local ColorFrame = Library:Create("Frame", {
        BackgroundColor3 = Library.AccentColor;
        BorderSizePixel = 0;
        Size = UDim2.new(1, 0, 0, 2);
        ZIndex = 102;
        Parent = KeybindInner
    })

    Library:AddToRegistry(ColorFrame, {BackgroundColor3 = "AccentColor"}, true)

    local KeybindLabel = Library:CreateLabel({
        Size = UDim2.new(1, 0, 0, 20);
        Position = UDim2.fromOffset(5, 2),
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = 'Keybinds';
        ZIndex = 104;
        Parent = KeybindInner
    })

    local KeybindContainer = Library:Create("Frame", {
        BackgroundTransparency = 1;
        Size = UDim2.new(1, 0, 1, -20);
        Position = UDim2.new(0, 0, 0, 20);
        ZIndex = 1;
        Parent = KeybindInner
    })

    Library:Create('UIListLayout', {
        FillDirection = Enum.FillDirection.Vertical;
        SortOrder = Enum.SortOrder.LayoutOrder;
        Parent = KeybindContainer
    })

    Library:Create('UIPadding', {PaddingLeft = UDim.new(0, 5),  Parent = KeybindContainer})
    Library.KeybindFrame = KeybindOuter
    Library.KeybindContainer = KeybindContainer
    Library:MakeDraggable(KeybindOuter)
end

function Library:SetWatermarkVisibility(Value)
    Library.Watermark.Visible = Value
end

function Library:SetWatermark(Text)
    local X, Y = Library:GetTextBounds(Text, Library.Font, 14)
    Library.Watermark.Size = UDim2.new(0, X + 15, 0, (Y * 1.5) + 3)
    Library:SetWatermarkVisibility(true)
    Library.WatermarkText.Text = Text
end

function Library:Notify(Text, Time)
    local XSize, YSize = Library:GetTextBounds(Text, Library.Font, 14);
    YSize += 7

    local NotifyOuter = Library:Create("Frame", {
        BorderColor3 = Color3.new(0, 0, 0);
        Position = UDim2.new(0, 100, 0, 10);
        Size = UDim2.new(0, 0, 0, YSize);
        ClipsDescendants = true;
        ZIndex = 100;
        Parent = Library.NotificationArea
    })

    local NotifyInner = Library:Create("Frame", {
        BackgroundColor3 = Library.MainColor;
        BorderColor3 = Library.OutlineColor;
        BorderMode = Enum.BorderMode.Inset;
        Size = UDim2.new(1, 0, 1, 0);
        ZIndex = 101;
        Parent = NotifyOuter
    })

    Library:AddToRegistry(NotifyInner, {BackgroundColor3 = "MainColor", BorderColor3 = "OutlineColor"}, true)

    local InnerFrame = Library:Create("Frame", {
        BackgroundColor3 = Color3.new(1, 1, 1);
        BorderSizePixel = 0;
        Position = UDim2.new(0, 1, 0, 1);
        Size = UDim2.new(1, -2, 1, -2);
        ZIndex = 102;
        Parent = NotifyInner
    })

    local Gradient = Library:Create("UIGradient", {
        Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Library:GetDarkerColor(Library.MainColor)), ColorSequenceKeypoint.new(1, Library.MainColor)}),
        Rotation = -90,
        Parent = InnerFrame
    })

    Library:AddToRegistry(Gradient, {Color = function()
        return ColorSequence.new({ColorSequenceKeypoint.new(0, Library:GetDarkerColor(Library.MainColor)),  ColorSequenceKeypoint.new(1, Library.MainColor)})
    end})

    local NotifyLabel = Library:CreateLabel({
        Position = UDim2.new(0, 4, 0, 0);
        Size = UDim2.new(1, -4, 1, 0);
        Text = Text;
        TextXAlignment = Enum.TextXAlignment.Left;
        TextSize = 14;
        ZIndex = 103;
        Parent = InnerFrame
    })

    local LeftColor = Library:Create("Frame", {
        BackgroundColor3 = Library.AccentColor,
        BorderSizePixel = 0,
        Position = UDim2.new(0, -1, 0, -1),
        Size = UDim2.new(0, 3, 1, 2),
        ZIndex = 104,
        Parent = NotifyOuter
    })

    Library:AddToRegistry(LeftColor, {BackgroundColor3 = "AccentColor"}, true)
    pcall(NotifyOuter.TweenSize, NotifyOuter, UDim2.new(0, XSize + 8 + 4, 0, YSize), 'Out', 'Quad', 0.4, true)
    task.spawn(function()
        task.wait(Time or 5)
        pcall(NotifyOuter.TweenSize, NotifyOuter, UDim2.new(0, 0, 0, YSize), 'Out', 'Quad', 0.4, true)
        task.wait(0.4)
        NotifyOuter:Destroy()
    end)
end

function Library:CreateWindow(Configuration, IsParallel)
    if type(Configuration.Title) ~= "string" then
        Configuration.Title = 'No title'
    end

    if type(Configuration.TabPadding) ~= 'number' then
        Configuration.TabPadding = 0
    end

    if type(Configuration.MenuFadeTime) ~= 'number' then
        Configuration.MenuFadeTime = 0.2
    end

    if typeof(Configuration.Position) ~= 'UDim2' then
        Configuration.Position = UDim2.fromOffset(175, 50)
    end

    if typeof(Configuration.Size) ~= 'UDim2' then
        Configuration.Size = UDim2.fromOffset(550, 600)
    end

    Configuration.AnchorPoint = Vector2.new(0.5, 0.5)
    Configuration.Position = UDim2.fromScale(0.5, 0.5)

    local Window = {Tabs = {}}

    local Outer = Library:Create("Frame", {
        AnchorPoint = Configuration.AnchorPoint,
        BackgroundColor3 = Color3.new(0, 0, 0);
        BorderSizePixel = 0;
        Position = Configuration.Position,
        Size = Configuration.Size,
        Visible = false;
        ZIndex = 1;
        Parent = ScreenGui
    })

    Library:MakeDraggable(Outer, 25)

    local Inner = Library:Create("Frame", {
        BackgroundColor3 = Library.MainColor;
        BorderColor3 = Library.AccentColor;
        BorderMode = Enum.BorderMode.Inset;
        Position = UDim2.new(0, 1, 0, 1);
        Size = UDim2.new(1, -2, 1, -2);
        ZIndex = 1;
        Parent = Outer
    })

    Library:AddToRegistry(Inner, {BackgroundColor3 = "MainColor", BorderColor3 = "AccentColor"})

    local WindowLabel = Library:CreateLabel({
        Position = UDim2.new(0, 7, 0, 0),
        Size = UDim2.new(0, 0, 0, 25),
        Text = Configuration.Title or '',
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 1,
        Parent = Inner
    })

    local MainSectionOuter = Library:Create("Frame", {
        BackgroundColor3 = Library.BackgroundColor,
        BorderColor3 = Library.OutlineColor,
        Position = UDim2.new(0, 8, 0, 25),
        Size = UDim2.new(1, -16, 1, -33),
        ZIndex = 1,
        Parent = Inner
    })

    Library:AddToRegistry(MainSectionOuter, {BackgroundColor3 = "BackgroundColor",  BorderColor3 = "OutlineColor"})

    local MainSectionInner = Library:Create("Frame", {
        BackgroundColor3 = Library.BackgroundColor;
        BorderColor3 = Color3.new(0, 0, 0);
        BorderMode = Enum.BorderMode.Inset;
        Position = UDim2.new(0, 0, 0, 0);
        Size = UDim2.new(1, 0, 1, 0);
        ZIndex = 1;
        Parent = MainSectionOuter
    })

    Library:AddToRegistry(MainSectionInner, {BackgroundColor3 = "BackgroundColor"})

    local TabArea = Library:Create("Frame", {
        BackgroundTransparency = 1;
        Position = UDim2.new(0, 8, 0, 8);
        Size = UDim2.new(1, -16, 0, 21);
        ZIndex = 1;
        Parent = MainSectionInner
    })

    local TabListLayout = Library:Create('UIListLayout', {
        Padding = UDim.new(0, Configuration.TabPadding);
        FillDirection = Enum.FillDirection.Horizontal;
        SortOrder = Enum.SortOrder.LayoutOrder;
        Parent = TabArea
    })

    local TabContainer = Library:Create("Frame", {
        BackgroundColor3 = Library.MainColor;
        BorderColor3 = Library.OutlineColor;
        Position = UDim2.new(0, 8, 0, 30);
        Size = UDim2.new(1, -16, 1, -38);
        ZIndex = 2;
        Parent = MainSectionInner
    })
    

    Library:AddToRegistry(TabContainer, {BackgroundColor3 = "MainColor",  BorderColor3 = "OutlineColor"})

    function Window:SetWindowTitle(Title)
        WindowLabel.Text = Title
    end

    function Window:AddTab(Name)
        local Tab = {Groupboxes = {},  Tabboxes = {}}
        local TabButtonWidth = Library:GetTextBounds(Name, Library.Font, 16)

        local TabButton = Library:Create("Frame", {
            BackgroundColor3 = Library.BackgroundColor;
            BorderColor3 = Library.OutlineColor;
            Size = UDim2.new(0, TabButtonWidth + 8 + 4, 1, 0);
            ZIndex = 1;
            Parent = TabArea
        })

        Library:AddToRegistry(TabButton, {
            BackgroundColor3 = "BackgroundColor";
            BorderColor3 = "OutlineColor"
        })

        local TabButtonLabel = Library:CreateLabel({
            Position = UDim2.new(0, 0, 0, 0);
            Size = UDim2.new(1, 0, 1, -1);
            Text = Name;
            ZIndex = 1;
            Parent = TabButton
        })

        local Blocker = Library:Create("Frame", {
            BackgroundColor3 = Library.MainColor;
            BorderSizePixel = 0;
            Position = UDim2.new(0, 0, 1, 0);
            Size = UDim2.new(1, 0, 0, 1);
            BackgroundTransparency = 1;
            ZIndex = 3;
            Parent = TabButton
        })

        Library:AddToRegistry(Blocker, {BackgroundColor3 = "MainColor"})

        local TabFrame = Library:Create("Frame", {
            Name = 'TabFrame',
            BackgroundTransparency = 1;
            Position = UDim2.new(0, 0, 0, 0);
            Size = UDim2.new(1, 0, 1, 0);
            Visible = false;
            ZIndex = 2;
            Parent = TabContainer
        })

        local LeftSide = Library:Create("ScrollingFrame", {
            BackgroundTransparency = 1;
            BorderSizePixel = 0;
            Position = UDim2.new(0, 8 - 1, 0, 8 - 1);
            Size = UDim2.new(0.5, -12 + 2, 0, 507 + 2);
            CanvasSize = UDim2.new(0, 0, 0, 0);
            BottomImage = '';
            TopImage = '';
            ScrollBarThickness = 0;
            ZIndex = 2;
            Parent = TabFrame
        })

        local RightSide = Library:Create("ScrollingFrame", {
            BackgroundTransparency = 1;
            BorderSizePixel = 0;
            Position = UDim2.new(0.5, 4 + 1, 0, 8 - 1);
            Size = UDim2.new(0.5, -12 + 2, 0, 507 + 2);
            CanvasSize = UDim2.new(0, 0, 0, 0);
            BottomImage = '';
            TopImage = '';
            ScrollBarThickness = 0;
            ZIndex = 2;
            Parent = TabFrame
        })

        Library:Create('UIListLayout', {
            Padding = UDim.new(0, 8);
            FillDirection = Enum.FillDirection.Vertical;
            SortOrder = Enum.SortOrder.LayoutOrder;
            HorizontalAlignment = Enum.HorizontalAlignment.Center;
            Parent = LeftSide
        })

        Library:Create('UIListLayout', {
            Padding = UDim.new(0, 8);
            FillDirection = Enum.FillDirection.Vertical;
            SortOrder = Enum.SortOrder.LayoutOrder;
            HorizontalAlignment = Enum.HorizontalAlignment.Center;
            Parent = RightSide
        })

        for _,Side in next, {LeftSide, RightSide } do
            Side:WaitForChild('UIListLayout'):GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
                Side.CanvasSize = UDim2.fromOffset(0, Side.UIListLayout.AbsoluteContentSize.Y)
            end)
        end

        function Tab:ShowTab()
            for _,Tab in next, Window.Tabs do
                Tab:HideTab()
            end

            Blocker.BackgroundTransparency = 0
            TabButton.BackgroundColor3 = Library.MainColor
            Library.RegistryMap[TabButton].Properties.BackgroundColor3 = "MainColor"
            TabFrame.Visible = true
        end

        function Tab:HideTab()
            Blocker.BackgroundTransparency = 1
            TabButton.BackgroundColor3 = Library.BackgroundColor
            Library.RegistryMap[TabButton].Properties.BackgroundColor3 = "BackgroundColor"
            TabFrame.Visible = false
        end

        function Tab:SetLayoutOrder(Position)
            TabButton.LayoutOrder = Position
            TabListLayout:ApplyLayout()
        end

        function Tab:AddGroupbox(Info)
            local Groupbox = {}

            local BoxOuter = Library:Create("Frame", {
                BackgroundColor3 = Library.BackgroundColor;
                BorderColor3 = Library.OutlineColor;
                BorderMode = Enum.BorderMode.Inset;
                Size = UDim2.new(1, 0, 0, 507 + 2);
                ZIndex = 2;
                Parent = Info.Side == 1 and LeftSide or RightSide
            })

            Library:AddToRegistry(BoxOuter, {BackgroundColor3 = "BackgroundColor", BorderColor3 = "OutlineColor"})

            local BoxInner = Library:Create("Frame", {
                BackgroundColor3 = Library.BackgroundColor;
                BorderColor3 = Color3.new(0, 0, 0);
                Size = UDim2.new(1, -2, 1, -2);
                Position = UDim2.new(0, 1, 0, 1);
                ZIndex = 4;
                Parent = BoxOuter
            })

            Library:AddToRegistry(BoxInner, {BackgroundColor3 = "BackgroundColor"})

            local Highlight = Library:Create("Frame", {
                BackgroundColor3 = Library.AccentColor;
                BorderSizePixel = 0;
                Size = UDim2.new(1, 0, 0, 2);
                ZIndex = 5;
                Parent = BoxInner
            })

            Library:AddToRegistry(Highlight, {BackgroundColor3 = "AccentColor"})

            local GroupboxLabel = Library:CreateLabel({
                Size = UDim2.new(1, 0, 0, 18);
                Position = UDim2.new(0, 4, 0, 2);
                TextSize = 14;
                Text = Info.Name;
                TextXAlignment = Enum.TextXAlignment.Left;
                ZIndex = 5;
                Parent = BoxInner
            })

            local Container = Library:Create("Frame", {
                BackgroundTransparency = 1;
                Position = UDim2.new(0, 4, 0, 20);
                Size = UDim2.new(1, -4, 1, -20);
                ZIndex = 1;
                Parent = BoxInner
            })

            Library:Create('UIListLayout', {
                FillDirection = Enum.FillDirection.Vertical;
                SortOrder = Enum.SortOrder.LayoutOrder;
                Parent = Container
            })

            function Groupbox:Resize()
                local Size = 0

                for _,Element in next, Groupbox.Container:GetChildren() do
                    if (not Element:IsA('UIListLayout')) and Element.Visible then
                        Size = Size + Element.Size.Y.Offset
                    end
                end

                BoxOuter.Size = UDim2.new(1, 0, 0, 20 + Size + 2 + 2)
            end

            Groupbox.Container = Container
            setmetatable(Groupbox, BaseGroupbox)

            Groupbox:AddBlank(3)
            Groupbox:Resize()

            Tab.Groupboxes[Info.Name] = Groupbox

            return Groupbox;
        end

        function Tab:AddLeftGroupbox(Name)
            return Tab:AddGroupbox({Side = 1, Name = Name})
        end

        function Tab:AddRightGroupbox(Name)
            return Tab:AddGroupbox({Side = 2, Name = Name})
        end

        function Tab:AddTabbox(Info)
            local Tabbox = {Tabs = {}}

            local BoxOuter = Library:Create("Frame", {
                BackgroundColor3 = Library.BackgroundColor;
                BorderColor3 = Library.OutlineColor;
                BorderMode = Enum.BorderMode.Inset;
                Size = UDim2.new(1, 0, 0, 0);
                ZIndex = 2;
                Parent = Info.Side == 1 and LeftSide or RightSide
            })

            Library:AddToRegistry(BoxOuter, {BackgroundColor3 = "BackgroundColor", BorderColor3 = "OutlineColor"})

            local BoxInner = Library:Create("Frame", {
                BackgroundColor3 = Library.BackgroundColor;
                BorderColor3 = Color3.new(0, 0, 0);
                Size = UDim2.new(1, -2, 1, -2);
                Position = UDim2.new(0, 1, 0, 1);
                ZIndex = 4;
                Parent = BoxOuter
            })

            Library:AddToRegistry(BoxInner, {
                BackgroundColor3 = "BackgroundColor";
            })

            local Highlight = Library:Create("Frame", {
                BackgroundColor3 = Library.AccentColor;
                BorderSizePixel = 0;
                Size = UDim2.new(1, 0, 0, 2);
                ZIndex = 10;
                Parent = BoxInner
            })

            Library:AddToRegistry(Highlight, {BackgroundColor3 = "AccentColor"})

            local TabboxButtons = Library:Create("Frame", {
                BackgroundTransparency = 1;
                Position = UDim2.new(0, 0, 0, 1);
                Size = UDim2.new(1, 0, 0, 18);
                ZIndex = 5;
                Parent = BoxInner
            })

            Library:Create('UIListLayout', {
                FillDirection = Enum.FillDirection.Horizontal;
                HorizontalAlignment = Enum.HorizontalAlignment.Left;
                SortOrder = Enum.SortOrder.LayoutOrder;
                Parent = TabboxButtons
            })

            function Tabbox:AddTab(Name)
                local Tab = {}

                local Button = Library:Create("Frame", {
                    BackgroundColor3 = Library.MainColor;
                    BorderColor3 = Color3.new(0, 0, 0);
                    Size = UDim2.new(0.5, 0, 1, 0);
                    ZIndex = 6;
                    Parent = TabboxButtons
                })

                Library:AddToRegistry(Button, {BackgroundColor3 = "MainColor"})

                local ButtonLabel = Library:CreateLabel({
                    Size = UDim2.new(1, 0, 1, 0);
                    TextSize = 14;
                    Text = Name;
                    TextXAlignment = Enum.TextXAlignment.Center;
                    ZIndex = 7;
                    Parent = Button
                })

                local Block = Library:Create("Frame", {
                    BackgroundColor3 = Library.BackgroundColor;
                    BorderSizePixel = 0;
                    Position = UDim2.new(0, 0, 1, 0);
                    Size = UDim2.new(1, 0, 0, 1);
                    Visible = false;
                    ZIndex = 9;
                    Parent = Button
                })

                Library:AddToRegistry(Block, {BackgroundColor3 = "BackgroundColor"})

                local Container = Library:Create("Frame", {
                    BackgroundTransparency = 1;
                    Position = UDim2.new(0, 4, 0, 20);
                    Size = UDim2.new(1, -4, 1, -20);
                    ZIndex = 1;
                    Visible = false;
                    Parent = BoxInner
                })

                Library:Create('UIListLayout', {
                    FillDirection = Enum.FillDirection.Vertical;
                    SortOrder = Enum.SortOrder.LayoutOrder;
                    Parent = Container
                })

                function Tab:Show()
                    for _,Tab in next, Tabbox.Tabs do
                        Tab:Hide()
                    end

                    Container.Visible = true
                    Block.Visible = true

                    Button.BackgroundColor3 = Library.BackgroundColor
                    Library.RegistryMap[Button].Properties.BackgroundColor3 = "BackgroundColor"

                    Tab:Resize()
                end

                function Tab:Hide()
                    Container.Visible = false
                    Block.Visible = false

                    Button.BackgroundColor3 = Library.MainColor
                    Library.RegistryMap[Button].Properties.BackgroundColor3 = "MainColor"
                end

                function Tab:Resize()
                    local TabCount = 0

                    for _,Tab in next, Tabbox.Tabs do
                        TabCount = TabCount + 1
                    end

                    for _,Button in next, TabboxButtons:GetChildren() do
                        if not Button:IsA('UIListLayout') then
                            Button.Size = UDim2.new(1 / TabCount, 0, 1, 0)
                        end
                    end

                    if (not Container.Visible) then
                        return
                    end

                    local Size = 0

                    for _,Element in next, Tab.Container:GetChildren() do
                        if (not Element:IsA('UIListLayout')) and Element.Visible then
                            Size = Size + Element.Size.Y.Offset
                        end
                    end

                    BoxOuter.Size = UDim2.new(1, 0, 0, 20 + Size + 2 + 2)
                end

                Button.InputBegan:Connect(function(Input)
                    if Input.UserInputType == Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame() then
                        Tab:Show()
                        Tab:Resize()
                    end
                end)

                Tab.Container = Container
                Tabbox.Tabs[Name] = Tab

                setmetatable(Tab, BaseGroupbox)

                Tab:AddBlank(3)
                Tab:Resize()

                if #TabboxButtons:GetChildren() == 2 then
                    Tab:Show()
                end

                return Tab
            end

            Tab.Tabboxes[Info.Name or ''] = Tabbox
            return Tabbox
        end

        function Tab:AddLeftTabbox(Name)
            return Tab:AddTabbox({Name = Name, Side = 1})
        end

        function Tab:AddRightTabbox(Name)
            return Tab:AddTabbox({Name = Name, Side = 2})
        end

        TabButton.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                Tab:ShowTab()
            end
        end)

        if #TabContainer:GetChildren() == 1 then
            Tab:ShowTab()
        end

        Window.Tabs[Name] = Tab
        return Tab
    end

    local ModalElement = Library:Create('TextButton', {
        BackgroundTransparency = 1;
        Size = UDim2.new(0, 0, 0, 0);
        Visible = true;
        Text = '';
        Modal = false;
        Parent = ScreenGui
    })

    local TransparencyCache = {}
    local Toggled = false
    local Fading = false

    function Library:Toggle()
        if Fading then
            return
        end

        for ModeSelect in next, Library.ModeSelectOuters do
            ModeSelect.Visible = false
        end

        local FadeTime = Configuration.MenuFadeTime;
        Fading = true
        Toggled = (not Toggled)
        ModalElement.Modal = Toggled
        Library.Toggled = Toggled

        if Toggled then
            Outer.Visible = true
            task.spawn(function()
                local State = UserInputService.MouseIconEnabled

                local Cursor = Drawing.new('Triangle')
                Cursor.Thickness = 1
                Cursor.Filled = true
                Cursor.Visible = true

                local CursorOutline = Drawing.new('Triangle')
                CursorOutline.Thickness = 1
                CursorOutline.Filled = false
                CursorOutline.Color = Color3.new(0, 0, 0)
                CursorOutline.Visible = true

                while Toggled and ScreenGui.Parent do
                    UserInputService.MouseIconEnabled = false

                    local MouseLocation = UserInputService:GetMouseLocation()

                    Cursor.Color = Library.AccentColor

                    Cursor.PointA = Vector2.new(MouseLocation.X, MouseLocation.Y)
                    Cursor.PointB = Vector2.new(MouseLocation.X + 16, MouseLocation.Y + 6)
                    Cursor.PointC = Vector2.new(MouseLocation.X + 6, MouseLocation.Y + 16)

                    CursorOutline.PointA = Cursor.PointA
                    CursorOutline.PointB = Cursor.PointB
                    CursorOutline.PointC = Cursor.PointC

                    RenderStepped:Wait()
                end

                UserInputService.MouseIconEnabled = State
                Cursor:Remove()
                CursorOutline:Remove()
            end)
        end

        for _,Desc in next, Outer:GetDescendants() do
            local Properties = {}

            if Desc:IsA("ImageLabel") then
                table.insert(Properties, "ImageTransparency")
                table.insert(Properties, "BackgroundTransparency")
            elseif Desc:IsA('TextLabel') or Desc:IsA("TextBox") then
                table.insert(Properties, "TextTransparency")
            elseif Desc:IsA("Frame") or Desc:IsA("ScrollingFrame") then
                table.insert(Properties, "BackgroundTransparency")
            elseif Desc:IsA('UIStroke') then
                table.insert(Properties, "Transparency")
            end

            local Cache = TransparencyCache[Desc]

            if (not Cache) then
                Cache = {}
                TransparencyCache[Desc] = Cache
            end

            for _,Prop in next, Properties do
                if not Cache[Prop] then
                    Cache[Prop] = Desc[Prop]
                end

                if Cache[Prop] == 1 then
                    continue
                end

                TweenService:Create(Desc, TweenInfo.new(FadeTime, Enum.EasingStyle.Linear), {[Prop] = Toggled and Cache[Prop] or 1}):Play()
            end
        end

        task.wait(FadeTime)
        Outer.Visible = Toggled
        Fading = false
    end

    UserInputService.InputBegan:Connect(function(Input, Processed)
        if type(Library.ToggleKeybind) == 'table' and Library.ToggleKeybind.Type == 'KeyPicker' then
            if Input.UserInputType == Enum.UserInputType.Keyboard and Input.KeyCode.Name == Library.ToggleKeybind.Value then
                task.spawn(Library.Toggle)
            end
        elseif Input.KeyCode == Enum.KeyCode.RightControl or (Input.KeyCode == Enum.KeyCode.RightShift and (not Processed)) then
            task.spawn(Library.Toggle)
        end
    end)

    Window.Holder = Outer
    return Window
end

local function OnPlayerChange()
    local PlayerList = GetPlayersString()
    for _,Value in next, Options do
        if Value.Type == 'Dropdown' and Value.SpecialType == 'Player' then
            Value:SetValues(PlayerList)
        end
    end
end

Players.PlayerAdded:Connect(OnPlayerChange)
Players.PlayerRemoving:Connect(OnPlayerChange)

getgenv().Library = Library
return Library
