-- Infinity Universe 0.1.0 | Mengy777 / 876osamuha
-- WindUI (MIT): https://github.com/Footagesus/WindUI
local env = getgenv and getgenv() or _G
local previous = env.InfinityUniverse
if previous and type(previous.Unload) == "function" then previous.Unload() end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Input = game:GetService("UserInputService")
local player = Players.LocalPlayer
assert(player, "Infinity Universe: LocalPlayer unavailable")

local app = { alive = true, enabled = false, speed = 60 }
local connections, flight, window = {}, nil, nil
local function stopFlight()
    local old = flight
    flight = nil
    if not old then return end
    for _, item in ipairs(old.instances) do item:Destroy() end
    if old.humanoid.Parent then
        old.humanoid.PlatformStand = old.platformStand
        old.humanoid.AutoRotate = old.autoRotate
        if old.humanoid.Health > 0 and not old.platformStand then
            old.humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
        end
    end
    if old.root.Parent then
        old.root.AssemblyLinearVelocity = Vector3.zero
        old.root.AssemblyAngularVelocity = Vector3.zero
    end
end
function app.Unload()
    if not app.alive then return end
    app.alive = false
    app.enabled = false
    for _, connection in ipairs(connections) do connection:Disconnect() end
    table.clear(connections)
    stopFlight()
    if window and not window.Destroyed then window:Destroy() end
    if env.InfinityUniverse == app then env.InfinityUniverse = nil end
end
env.InfinityUniverse = app

local function startFlight(character, humanoid, root)
    local state = {
        character = character, humanoid = humanoid, root = root, instances = {},
        platformStand = humanoid.PlatformStand, autoRotate = humanoid.AutoRotate,
    }
    flight = state -- Track partial construction so startup errors can clean up.
    local function own(className)
        local item = Instance.new(className)
        table.insert(state.instances, item)
        return item
    end
    local attachment = own("Attachment")
    attachment.Name = "InfinityFlightAttachment"
    attachment.Parent = root
    local velocity = own("LinearVelocity")
    velocity.Name = "InfinityFlightVelocity"
    velocity.Attachment0 = attachment
    velocity.RelativeTo = Enum.ActuatorRelativeTo.World
    velocity.MaxForce = math.huge
    velocity.VectorVelocity = Vector3.zero
    velocity.Parent = root
    local orientation = own("AlignOrientation")
    orientation.Name = "InfinityFlightOrientation"
    orientation.Attachment0 = attachment
    orientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
    orientation.MaxTorque = math.huge
    orientation.Responsiveness = 25
    orientation.CFrame = root.CFrame.Rotation
    orientation.Parent = root
    state.velocity, state.orientation = velocity, orientation
    humanoid.AutoRotate = false
    humanoid.PlatformStand = true
end

local ok, message = xpcall(function()
    local source = game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/d2c9bac5f96f997418d680d19cb759892542e492/dist/main.lua")
    local chunk, compileError = loadstring(source)
    assert(chunk, "WindUI: " .. tostring(compileError))
    local WindUI = chunk()
    window = WindUI:CreateWindow({
        Title = "Infinity Universe", Author = "876osamuha", Icon = "infinity",
        Size = UDim2.fromOffset(620, 440), Theme = "Dark", NewElements = true,
        ToggleKey = Enum.KeyCode.RightShift,
        OpenButton = { Title = "Infinity Universe", Icon = "infinity", Enabled = true, Draggable = true },
    })
    window:OnDestroy(function()
        window = nil
        app.Unload()
    end)
    local tab = window:Tab({ Title = "Полёт", Icon = "feather" })
    tab:Toggle({
        Title = "Полёт", Desc = "WASD · Space вверх · Ctrl вниз", Value = false,
        Callback = function(value)
            app.enabled = value == true
            if not app.enabled then stopFlight() end
        end,
    })
    tab:Slider({
        Title = "Скорость", Step = 1, IsTextbox = true,
        Value = { Min = 10, Max = 300, Default = 60 },
        Callback = function(value)
            local number = tonumber(value)
            if number and number == number then app.speed = math.clamp(number, 10, 300) end
        end,
    })
    local function down(key) return Input:IsKeyDown(key) and 1 or 0 end
    table.insert(connections, player.CharacterRemoving:Connect(stopFlight))
    table.insert(connections, RunService.Heartbeat:Connect(function()
        if not app.alive or not app.enabled then return end
        local character = player.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if not humanoid or humanoid.Health <= 0 or not root or root.Anchored then
            stopFlight()
            return
        end
        if flight and (flight.character ~= character or flight.root ~= root or flight.humanoid ~= humanoid
            or not flight.velocity.Parent or not flight.orientation.Parent) then stopFlight() end
        if not flight then startFlight(character, humanoid, root) end
        local camera = workspace.CurrentCamera
        local direction = Vector3.zero
        if camera and not Input:GetFocusedTextBox() then
            direction = camera.CFrame.LookVector * (down(Enum.KeyCode.W) - down(Enum.KeyCode.S))
                + camera.CFrame.RightVector * (down(Enum.KeyCode.D) - down(Enum.KeyCode.A))
                + Vector3.yAxis * (down(Enum.KeyCode.Space) - down(Enum.KeyCode.LeftControl) - down(Enum.KeyCode.RightControl))
            if direction.Magnitude > 1 then direction = direction.Unit end
        end
        flight.velocity.VectorVelocity = direction * app.speed
        if camera then flight.orientation.CFrame = camera.CFrame.Rotation end
    end))
end, debug.traceback)
if not ok then
    app.Unload()
    error("Infinity Universe startup failed: " .. tostring(message), 0)
end
