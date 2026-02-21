-- Services
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera

-- Key Constants & State Variables
local KEY_A = 0x41
local KEY_D = 0x44

local holdingA = false
local holdingD = false

local MOVEMENT_THRESHOLD = 0.25
local holdDelayMs = 150 -- Default slider position is 150ms
local holdDelaySec = holdDelayMs / 1000

local lastMoveTime = 0
local currentDirection = "None"
local isEnabled = true -- Toggle state

-- =========================================
--            UI: INDICATOR BOXES
-- =========================================

-- 1. Mouse Movement Box
local moveBox = Drawing.new("Square")
moveBox.Visible = true
moveBox.Size = Vector2.new(30, 30)
moveBox.Position = Vector2.new(50, 50)
moveBox.Color = Color3.new(1, 0, 0)
moveBox.Filled = true

local moveText = Drawing.new("Text")
moveText.Visible = true
moveText.Text = "Mouse Movement"
moveText.Size = 18
moveText.Center = false
moveText.Outline = true
moveText.Color = Color3.new(1, 1, 1)
moveText.Position = Vector2.new(90, 55)

-- 2. Enabled/Disabled Box
local toggleBox = Drawing.new("Square")
toggleBox.Visible = true
toggleBox.Size = Vector2.new(30, 30)
toggleBox.Position = Vector2.new(50, 90)
toggleBox.Color = Color3.new(0, 1, 0) -- Starts Enabled (Green)
toggleBox.Filled = true

local toggleText = Drawing.new("Text")
toggleText.Visible = true
toggleText.Text = "Autostrafe Enabled (Middle Click to Toggle)"
toggleText.Size = 18
toggleText.Center = false
toggleText.Outline = true
toggleText.Color = Color3.new(1, 1, 1)
toggleText.Position = Vector2.new(90, 95)


-- =========================================
--               UI: SLIDER
-- =========================================
local sliderWidth = 200
local sliderHeight = 10
local sliderYOffset = 100

local function getSliderPos()
    local vp = Camera.ViewportSize
    return Vector2.new(vp.X / 2 - sliderWidth / 2, vp.Y - sliderYOffset)
end

local sliderBg = Drawing.new("Square")
sliderBg.Visible = true
sliderBg.Size = Vector2.new(sliderWidth, sliderHeight)
sliderBg.Position = getSliderPos()
sliderBg.Color = Color3.fromRGB(40, 40, 40)
sliderBg.Filled = true

local sliderFill = Drawing.new("Square")
sliderFill.Visible = true
sliderFill.Size = Vector2.new((holdDelayMs / 500) * sliderWidth, sliderHeight)
sliderFill.Position = getSliderPos()
sliderFill.Color = Color3.fromRGB(0, 200, 0)
sliderFill.Filled = true

local sliderText = Drawing.new("Text")
sliderText.Visible = true
sliderText.Text = "current hold time: " .. tostring(math.floor(holdDelayMs)) .. "ms"
sliderText.Size = 18
sliderText.Center = true
sliderText.Outline = true
sliderText.Color = Color3.new(1, 1, 1)
sliderText.Position = getSliderPos() + Vector2.new(sliderWidth / 2, -25)

-- Handle window resize
local resizeConn = Camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
    local pos = getSliderPos()
    sliderBg.Position = pos
    sliderFill.Position = pos
    sliderText.Position = pos + Vector2.new(sliderWidth / 2, -25)
end)


-- =========================================
--             INPUT HANDLING
-- =========================================
local isDragging = false

-- Handles Middle Click Toggle & Dragging Slider
local inputBeganConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    -- Middle Mouse Button Toggle
    if input.UserInputType == Enum.UserInputType.MouseButton3 then
        isEnabled = not isEnabled
        
        if isEnabled then
            toggleBox.Color = Color3.new(0, 1, 0)
            toggleText.Text = "Autostrafe Enabled (Middle Click to Toggle)"
        else
            toggleBox.Color = Color3.new(1, 0, 0)
            toggleText.Text = "Autostrafe Disabled (Middle Click to Toggle)"
            moveBox.Color = Color3.new(1, 0, 0) -- Reset move box visually
            currentDirection = "None"
            
            -- Force drop keys so we don't get stuck walking when disabled
            if holdingA then
                keyrelease(KEY_A)
                holdingA = false
            end
            if holdingD then
                keyrelease(KEY_D)
                holdingD = false
            end
        end
    end

    -- Mouse Button 1 for Slider Drag
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        local mPos = UserInputService:GetMouseLocation()
        local sPos = sliderBg.Position
        
        if mPos.X >= sPos.X - 20 and mPos.X <= sPos.X + sliderWidth + 20 and
           mPos.Y >= sPos.Y - 20 and mPos.Y <= sPos.Y + sliderHeight + 20 then
            isDragging = true
        end
    end
end)

local inputEndedConn = UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        isDragging = false
    end
end)

local inputChangedConn = UserInputService.InputChanged:Connect(function(input)
    if isDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local mPos = UserInputService:GetMouseLocation()
        local sPos = sliderBg.Position
        
        local relativeX = math.clamp(mPos.X - sPos.X, 0, sliderWidth)
        local percentage = relativeX / sliderWidth
        
        holdDelayMs = math.floor(percentage * 500)
        holdDelaySec = holdDelayMs / 1000
        
        sliderFill.Size = Vector2.new(relativeX, sliderHeight)
        sliderText.Text = "current hold time: " .. tostring(holdDelayMs) .. "ms"
    end
end)


-- =========================================
--            MAIN SMART LOOP
-- =========================================
local function updateKeys()
    if not isEnabled then return end
    
    local now = os.clock()
    
    if now - lastMoveTime <= holdDelaySec and currentDirection ~= "None" then
        moveBox.Color = Color3.new(0, 1, 0)
        
        if currentDirection == "Right" then
            if not holdingD then
                keypress(KEY_D)
                holdingD = true
            end
            if holdingA then
                keyrelease(KEY_A)
                holdingA = false
            end
        elseif currentDirection == "Left" then
            if not holdingA then
                keypress(KEY_A)
                holdingA = true
            end
            if holdingD then
                keyrelease(KEY_D)
                holdingD = false
            end
        end
    else
        moveBox.Color = Color3.new(1, 0, 0)
        currentDirection = "None"
        
        if holdingA then
            keyrelease(KEY_A)
            holdingA = false
        end
        if holdingD then
            keyrelease(KEY_D)
            holdingD = false
        end
    end
end

-- Tracks Mouse movement to update times
local renderConn = RunService.RenderStepped:Connect(function()
    local delta = UserInputService:GetMouseDelta()
    
    -- Only update movement processing if the script is actually enabled!
    if isEnabled then
        if delta.X > MOVEMENT_THRESHOLD then
            currentDirection = "Right"
            lastMoveTime = os.clock()
        elseif delta.X < -MOVEMENT_THRESHOLD then
            currentDirection = "Left"
            lastMoveTime = os.clock()
        end
    end
    
    updateKeys()
end)

-- =========================================
--               CLEANUP LOGIC
-- =========================================
_G.StopStrafe = function()
    if renderConn then renderConn:Disconnect() end
    if inputBeganConn then inputBeganConn:Disconnect() end
    if inputEndedConn then inputEndedConn:Disconnect() end
    if inputChangedConn then inputChangedConn:Disconnect() end
    if resizeConn then resizeConn:Disconnect() end
    
    if moveBox then moveBox:Remove() end
    if moveText then moveText:Remove() end
    if toggleBox then toggleBox:Remove() end
    if toggleText then toggleText:Remove() end
    if sliderBg then sliderBg:Remove() end
    if sliderFill then sliderFill:Remove() end
    if sliderText then sliderText:Remove() end
    
    if holdingA then keyrelease(KEY_A) end
    if holdingD then keyrelease(KEY_D) end
end
