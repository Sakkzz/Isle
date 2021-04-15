local BASE_URL = "https://raw.githubusercontent.com/Jxl-v/schematica/main/"

local function require_module(module) return loadstring(game:HttpGet(string.format("%sdependencies/%s", BASE_URL, module)))() end

local Serializer = require_module("serializer.lua")
local Builder = require_module("builder.lua")
local Library = require_module("venyx.lua")

if game.CoreGui:FindFirstChild("Schematica") then game.CoreGui.Schematica:Destroy() end
if not isfolder("builds") then makefolder("builds") end

local Fetch = request or http_request or syn and syn.request
local Http = game:GetService("HttpService")
local Env = Http:JSONDecode(game:HttpGet(BASE_URL .. "env.json"))

local Player = game.Players.LocalPlayer
local Mouse = Player:GetMouse()

local Schematica = Library.new("Schematica")

local GlobalToggles = {}

workspace.CurrentCamera.CameraSubject = game.Players.LocalPlayer.Character.Humanoid
workspace.CurrentCamera.CameraType = "Custom"
Player.CameraMinZoomDistance = 0.5
Player.CameraMaxZoomDistance = 200
Player.CameraMode = "Classic"

local function Toggle(Name)
    for i, v in next, GlobalToggles do
        if i ~= Name then   
            v.toggle(false)
        end
    end
end

do
    local Build = Schematica:addPage("Build")
    local round = math.round

    local Flags = {
        ChangingPosition = false,
        BuildId = '0',
        ShowPreview = true,
        Visibility = 0.5,
        DragCF = 0
    }

    local Indicator = Instance.new("Part")
    Indicator.Size = Vector3.new(3.1, 3.1, 3.1)
    Indicator.Transparency = 0.5
    Indicator.Anchored = true
    Indicator.CanCollide = false
    Indicator.BrickColor = BrickColor.new("Bright green")
    Indicator.TopSurface = Enum.SurfaceType.Smooth
    Indicator.Parent = workspace

    local Handles = Instance.new("Handles")
    Handles.Style = Enum.HandlesStyle.Movement
    Handles.Adornee = Indicator
    Handles.Visible = false
    Handles.Parent = game.CoreGui

    Handles.MouseButton1Down:Connect(function()
        Flags.DragCF = Handles.Adornee.CFrame
    end)

    Handles.MouseDrag:Connect(function(Face, Distance)
        if Indicator.Parent.ClassName == "Model" then
            Indicator.Parent:SetPrimaryPartCFrame(Flags.DragCF + Vector3.FromNormalId(Face) * (round(Distance / 3) * 3))
        else
            Indicator.CFrame = Flags.DragCF + Vector3.FromNormalId(Face) * (round(Distance / 3) * 3)
        end
    end)

    local SelectSection = Build:addSection("Selecting Build")

    SelectSection:addTextbox("Build ID", "0", function(buildId)
        Flags.BuildId = buildId:gsub("%s", "")
    end)

    Flags.Download = SelectSection:addButton("Download / Load", function()
        SelectSection:updateButton(Flags.Download, "Please wait ...")

        if isfile("builds/" .. Flags.BuildId .. ".s") then
            if Flags.Build then 
                Indicator.Parent = workspace
                Flags.Build:Destroy()
            end
            local Data = Http:JSONDecode(readfile("builds/" .. Flags.BuildId .. ".s"))
            Flags.Build = Builder.new(Data)
            SelectSection:updateButton(Flags.Download, "File loaded!")
        else
            local Response = Http:JSONDecode(game:HttpGet(Env.get .. Flags.BuildId))
            if Response.success == true then
                if Flags.Build then 
                    Indicator.Parent = workspace
                    Flags.Build:Destroy()
                end
                Flags.Build = Builder.new(Response.data)
                SelectSection:updateButton(Flags.Download, "Downloaded!")
                writefile("builds/" .. Flags.BuildId .. ".s", game.HttpService:JSONEncode(Response.data))
            else
                if Response.status == 404 then
                    SelectSection:updateButton(Flags.Download, "Not found")
                elseif Response.status == 400 then
                    SelectSection:updateButton(Flags.Download, "Error")
                end
            end
        end
        wait(1)
        SelectSection:updateButton(Flags.Download, "Download")
    end)

    local PositionSettings = Build:addSection("Position Settings")

    GlobalToggles.ChangePositionToggle = PositionSettings:addToggle("Change Position", false, function(willChange)
        Flags.ChangingPosition = willChange
    end)

    Mouse.Button1Down:Connect(function()
        if Mouse.Target then
            if Flags.ChangingPosition then
                if Mouse.Target.Parent.Name == "Blocks" or Mouse.Target.Parent.Parent.Name == "Blocks" then
                    local Part = Mouse.Target.Parent.Name == "Blocks" and Mouse.Target or Mouse.Target.Parent.Parent.Name == "Blocks" and Mouse.Target.Parent
                    Handles.Visible = Flags.ShowPreview
                    if Indicator.Parent and Indicator.Parent.ClassName == "Model" then
                        Indicator.Parent:SetPrimaryPartCFrame(CFrame.new(Part.Position))
                    else
                        Indicator.CFrame = CFrame.new(Part.Position)
                    end
                end
            end
        end
    end)

    print("click connection loaded")

    PositionSettings:addButton("Load Model", function()
        if Indicator and Flags.Build then
            if Flags.Build.Model then
                Indicator.Parent = workspace
                Flags.Build.Model:Destroy()
            end

            Flags.ChangingPosition = false
            --PositionSettings:updateToggle(GlobalToggles.ChangePositionToggle, "Change Position", false)
            Toggle()

            Flags.Build:Init()
            Flags.Build:SetVisibility(Flags.Visibility)
            Flags.Build:Render(Flags.ShowPreview)
            Flags.Build:SetCFrame(Indicator.CFrame)    
            
            Indicator.Parent = Flags.Build.Model
            Flags.Build.Model.PrimaryPart = Indicator
        end
    end)

    print("load preview button loaded")

    local Rotate = Build:addSection("Rotate")

    Rotate:addButton("Rotate X", function()
        if Flags.Build then
            Flags.Build:SetCFrame(Indicator.CFrame * CFrame.Angles(math.rad(90), 0, 0))
        end
    end)

    Rotate:addButton("Rotate Y", function()
        if Flags.Build then
            Flags.Build:SetCFrame(Indicator.CFrame * CFrame.Angles(0, math.rad(90), 0))
        end
    end)

    Rotate:addButton("Rotate Z", function()
        if Flags.Build then
            Flags.Build:SetCFrame(Indicator.CFrame * CFrame.Angles(0, 0, math.rad(90)))
        end
    end)
	
    local XZ = Build:addSection("XYZ")
	
	XYZ:addButton("Y 1", function()
        if Flags.Build then
            Flags.Build:SetCFrame(Indicator.CFrame + Vector3.new(0,1,0))
        end
    end)

    XYZ:addButton("Y -1", function()
        if Flags.Build then
            Flags.Build:SetCFrame(Indicator.CFrame - Vector3.new(0,-1,0))
        end
    end)
		
	XYZ:addButton("X 1", function()
        if Flags.Build then
            Flags.Build:SetCFrame(Indicator.CFrame + Vector3.new(1,0,0))
        end
    end)
    
	XYZ:addButton("X -1", function()
        if Flags.Build then
            Flags.Build:SetCFrame(Indicator.CFrame - Vector3.new(-1,0,0))
        end
    end)
    
	XYZ:addButton("Z 1", function()
        if Flags.Build then
            Flags.Build:SetCFrame(Indicator.CFrame + Vector3.new(0,0,1))
        end
    end)
    
	XYZ:addButton("Z -1", function()
        if Flags.Build then
            Flags.Build:SetCFrame(Indicator.CFrame - Vector3.new(0,0,-1))
        end
    end)

    print("placements loaded")

    local BuildSection = Build:addSection("Build")
    BuildSection:addToggle("Show Build", true, function(willShow)
        Flags.ShowPreview = willShow
        Indicator.Transparency = willShow and 0.5 or 1
        Handles.Parent = willShow and game.CoreGui or game.ReplicatedStorage

        if Flags.Build then
            if Flags.Build.Model then
                Flags.Build:Render(Flags.ShowPreview)
            end
        end
    end)

    print("show build toggle loaded")

    BuildSection:addTextbox("Block transparency", "0.5", function(newTransparency, lost)
        if lost and tonumber(newTransparency) then
            Flags.Visibility = tonumber(newTransparency)
            if Flags.Build then
                Flags.Build:SetVisibility(Flags.Visibility)
            end
        end
    end)

    print("dropdown loaded")
    BuildSection:addButton("Start Building", function()
        if Flags.Build and Flags.Build.Model then
            local OriginalPosition = Player.Character.HumanoidRootPart.CFrame
            Flags.Build:Build({
                Start = function()
                    Velocity = Instance.new("BodyVelocity", Player.Character.HumanoidRootPart)
                    Velocity.Velocity = Vector3.new(0, 0, 0)
                end;
                Build = function(CF)
                    Player.Character.HumanoidRootPart.CFrame = CF + Vector3.new(10, 10, 10)
                end;
                End = function()
                    Velocity:Destroy()
                    Player.Character.HumanoidRootPart.CFrame = OriginalPosition
                end;
            })
        else
            Schematica:Notify("Error", "The model is not loaded yet, load it by pressing on Load Model")
        end
    end)

    print("start build button loaded")

    BuildSection:addButton("Abort", function()
        if Flags.Build then
            Flags.Build.Abort = true
        end
    end)
end

print("build section done")

do
    local round = math.round
    local Save = Schematica:addPage("Save")

    local Flags = {
        ChangeStart = false,
        ChangeEnd = false,
        ShowOutline = true,
        BuildName = "Untitled",
        Private = "Public",
        CF1 = 0,
        CF2 = 0
    }

    local Points = Save:addSection("Set Positions")

    GlobalToggles.SavePoint1 = Points:addToggle("Change Start Point", false, function(willChange)
        Flags.ChangeStart = willChange
        if willChange then
            Toggle("SavePoint1")
            --Points:updateToggle(GlobalToggles.SavePoint2, "Change End Point", false)
            Flags.ChangeEnd = false
        end
    end)

    GlobalToggles.SavePoint2 = Points:addToggle("Change End Point", false, function(willChange)
        Flags.ChangeEnd = willChange
        if willChange then
            Toggle("SavePoint2")
            --Points:updateToggle(GlobalToggles.SavePoint1, "Change Start Point", false)
            Flags.ChangeStart = false
        end
    end)

    print("points loaded")

    local Model = Instance.new("Model")

    local SelectionBox = Instance.new("SelectionBox")
    SelectionBox.Adornee = Model
    SelectionBox.SurfaceColor3 = Color3.new(1, 0, 0)
    SelectionBox.Color3 = Color3.new(1, 1, 1)
    SelectionBox.LineThickness = 0.1
    SelectionBox.SurfaceTransparency = 0.8
    SelectionBox.Visible = false
    SelectionBox.Parent = Model

    local IndicatorStart = Instance.new("Part")
    IndicatorStart.Size = Vector3.new(3.1, 3.1, 3.1)
    IndicatorStart.Transparency = 1
    IndicatorStart.Anchored = true
    IndicatorStart.CanCollide = false
    IndicatorStart.BrickColor = BrickColor.new("Really red")
    IndicatorStart.Material = "Plastic"
    IndicatorStart.TopSurface = Enum.SurfaceType.Smooth
    IndicatorStart.Parent = Model

    local IndicatorEnd = Instance.new("Part")
    IndicatorEnd.Size = Vector3.new(3.1, 3.1, 3.1)
    IndicatorEnd.Transparency = 1
    IndicatorEnd.Anchored = true
    IndicatorEnd.CanCollide = false
    IndicatorEnd.BrickColor = BrickColor.new("Really blue")
    IndicatorEnd.Material = "Plastic"
    IndicatorEnd.TopSurface = Enum.SurfaceType.Smooth
    IndicatorEnd.Parent = Model

    local StartHandles = Instance.new("Handles")

    StartHandles.Style = Enum.HandlesStyle.Movement
    StartHandles.Adornee = IndicatorStart
    StartHandles.Visible = false
    StartHandles.Parent = game.CoreGui

    local EndHandles = Instance.new("Handles")

    EndHandles.Style = Enum.HandlesStyle.Movement
    EndHandles.Adornee = IndicatorEnd
    EndHandles.Visible = false
    EndHandles.Parent = game.CoreGui

    print("instances loaded")

    StartHandles.MouseButton1Down:Connect(function()
        Flags.CF1 = StartHandles.Adornee.CFrame
    end)

    StartHandles.MouseDrag:Connect(function(Face, Distance)
        StartHandles.Adornee.CFrame = Flags.CF1 + Vector3.FromNormalId(Face) * (round(Distance / 3) * 3)
    end)

    EndHandles.MouseButton1Down:Connect(function()
        Flags.CF2 = EndHandles.Adornee.CFrame
    end)

    EndHandles.MouseDrag:Connect(function(Face, Distance)
        EndHandles.Adornee.CFrame = Flags.CF2 + Vector3.FromNormalId(Face) * (round(Distance / 3) * 3)
    end)

    print("connections loaded")

    Model.Parent = workspace
    
    Points:addToggle("Show Outline", true, function(willShow)
        Flags.ShowOutline = willShow

        IndicatorStart.Transparency = willShow and 0.5 or 1
        IndicatorEnd.Transparency = willShow and 0.5 or 1
        StartHandles.Visible = willShow
        EndHandles.Visible = willShow

        Model.Parent = willShow and workspace or game.ReplicatedStorage
    end)

     Mouse.Button1Down:Connect(function()
        if Mouse.Target then
            if Flags.ChangeStart or Flags.ChangeEnd then
                local ToChange = Flags.ChangeStart and "Start" or "End"
                if Mouse.Target.Parent.Name == "Blocks" or Mouse.Target.Parent.Parent.Name == "Blocks" then
                    local Part = Mouse.Target.Parent.Name == "Blocks" and Mouse.Target or Mouse.Target.Parent.Parent.Name == "Blocks" and Mouse.Target.Parent
                    Flags[ToChange] = Part.Position

                    if ToChange == "Start" then
                        StartHandles.Visible =  Flags.ShowOutline
                        IndicatorStart.Transparency = Flags.ShowOutline and 0.5 or 1
                    elseif ToChange == "End" then
                        EndHandles.Visible =  Flags.ShowOutline
                        IndicatorEnd.Transparency = Flags.ShowOutline and 0.5 or 1
                    end

                    if Flags.Start and Flags.End then
                        SelectionBox.Visible =  Flags.ShowOutline
                        if ToChange == "Start" then
                            IndicatorStart.Position = Part.Position
                        elseif ToChange == "End" then
                            IndicatorEnd.Position = Part.Position
                        end
                    else
                        IndicatorStart.Position = Part.Position
                        IndicatorEnd.Position = Part.Position
                    end
                end
            end
        end
    end)

    print("click con added")
    local Final = Save:addSection("Save")

    Final:addTextbox("Custom Name", "", function(name)
        Flags.BuildName = name
    end)

    Final:addToggle("Unlisted", false, function(isPrivate)
        Flags.Private = isPrivate and "Private" or "Public"
    end)

    Final:addButton("Save Area", function()
        local Serialize = Serializer.new(IndicatorStart.Position, IndicatorEnd.Position)
        local Data = Serialize:Serialize()

        local Response = Fetch({
            Url = Env.post;
            Body = game.HttpService:JSONEncode(Data);
            Headers = {
                ["Content-Type"] = "application/json",
                ["Build-Name"] = Flags.BuildName == "" and "Untitled" or Flags.BuildName;
                ["Private"] = Flags.Private
            };
            Method = "POST"
        })

        local JSONResponse = Http:JSONDecode(Response.Body)
        if JSONResponse.status == "success" then
            writefile("builds/" .. JSONResponse.output .. ".s", game.HttpService:JSONEncode(Data))
            setclipboard(JSONResponse.output)
            Schematica:Notify("Build Uploaded", "Copied to clipboard")
        else
            Schematica:Notify("Error", JSONResponse.status)
        end
    end)
    print("click and stuff added")
end

print("saving added")
do

local Build = Schematica:addPage("Close")
    Rotate:addButton("Destroy Gui", function()
        game.CoreGui.Schematica:Destroy()
        end
    end)
end

print("gui has been destroyed")
do

    local Final = Print:addSection("Build")
    Final:addToggle("Show Outline", true, function(willShow)
        Flags.ShowOutline = willShow
        IndicatorStart.Transparency = willShow and 0.5 or 1
        IndicatorEnd.Transparency = willShow and 0.5 or 1

        if Flags.Start then
            StartHandles.Visible = willShow
        end

        if Flags.End then
            EndHandles.Visible = willShow
        end

        SelectionBox.Visible = willShow
    end)
end
