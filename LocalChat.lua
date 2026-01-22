--[[
Location: StarterPlayer > StarterPlayerScripts > ChatClient
STATUS: FINAL - Fixed Tab UI Clipping + No Self-Whisper
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")
local TextChatService = game:GetService("TextChatService")

local LocalPlayer = Players.LocalPlayer
local chatRemote = ReplicatedStorage:WaitForChild("CustomChatEvent")
local lastMessageSent = 0
local showDisplayName = true

local channels = {
	["main"] = {messages = {}, scrollFrame = nil, uiList = nil}
}
local activeChannel = "main"

pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, false) end)
task.spawn(function()
	local cw = TextChatService:WaitForChild("ChatWindowConfiguration", 2)
	local ci = TextChatService:WaitForChild("ChatInputBarConfiguration", 2)
	if cw then cw.Enabled = false end
	if ci then ci.Enabled = false end
end)

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "CustomChatGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.DisplayOrder = 10
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local ToggleButton = Instance.new("TextButton")
ToggleButton.Name = "ToggleChat"
ToggleButton.AnchorPoint = Vector2.new(0, 1)
ToggleButton.Position = UDim2.new(0, 10, 1, -10)
ToggleButton.Size = UDim2.new(0, 45, 0, 45)
ToggleButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
ToggleButton.BackgroundTransparency = 0.4
ToggleButton.Text = "??"
ToggleButton.TextSize = 24
ToggleButton.TextColor3 = Color3.new(1,1,1)
ToggleButton.Parent = ScreenGui
Instance.new("UICorner", ToggleButton).CornerRadius = UDim.new(0, 12)

local ChatFrame = Instance.new("Frame")
ChatFrame.Name = "ChatFrame"
ChatFrame.Size = UDim2.new(0, 420, 0, 320)
ChatFrame.Position = UDim2.new(0, 10, 0, 60)
ChatFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
ChatFrame.BackgroundTransparency = 0.3
ChatFrame.Parent = ScreenGui
Instance.new("UICorner", ChatFrame).CornerRadius = UDim.new(0, 8)

local TabContainer = Instance.new("Frame")
TabContainer.Name = "TabContainer"
TabContainer.Size = UDim2.new(1, -20, 0, 30)
TabContainer.Position = UDim2.new(0, 10, 0, 5)
TabContainer.BackgroundTransparency = 1
TabContainer.Parent = ChatFrame

local TabLayout = Instance.new("UIListLayout")
TabLayout.FillDirection = Enum.FillDirection.Horizontal
TabLayout.SortOrder = Enum.SortOrder.LayoutOrder
TabLayout.Padding = UDim.new(0, 5)
TabLayout.Parent = TabContainer

local NameToggleBtn = Instance.new("TextButton")
NameToggleBtn.Name = "NameToggle"
NameToggleBtn.Size = UDim2.new(0, 30, 0, 25)
NameToggleBtn.Position = UDim2.new(1, -35, 0, 5)
NameToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
NameToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
NameToggleBtn.Text = "DN"
NameToggleBtn.Font = Enum.Font.GothamBold
NameToggleBtn.TextSize = 12
NameToggleBtn.Parent = ChatFrame
Instance.new("UICorner", NameToggleBtn).CornerRadius = UDim.new(0, 4)

local ScrollersContainer = Instance.new("Frame")
ScrollersContainer.Name = "ScrollersContainer"
ScrollersContainer.Size = UDim2.new(1, -20, 1, -105)
ScrollersContainer.Position = UDim2.new(0, 10, 0, 40)
ScrollersContainer.BackgroundTransparency = 1
ScrollersContainer.Parent = ChatFrame

local InputBox = Instance.new("TextBox")
InputBox.Size = UDim2.new(1, -80, 0, 40)
InputBox.Position = UDim2.new(0, 10, 1, -45)
InputBox.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
InputBox.BackgroundTransparency = 0.5
InputBox.TextColor3 = Color3.fromRGB(255, 255, 255)
InputBox.Text = ""
InputBox.PlaceholderText = "Type a message..."
InputBox.TextXAlignment = Enum.TextXAlignment.Left
InputBox.Font = Enum.Font.Gotham
InputBox.TextSize = 16
InputBox.ClearTextOnFocus = false
InputBox.Parent = ChatFrame
Instance.new("UICorner", InputBox).CornerRadius = UDim.new(0, 8)
Instance.new("UIPadding", InputBox).PaddingLeft = UDim.new(0, 12)

local SendBtn = Instance.new("TextButton")
SendBtn.Size = UDim2.new(0, 60, 0, 40)
SendBtn.Position = UDim2.new(1, -65, 1, -45)
SendBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
SendBtn.Text = "Send"
SendBtn.Font = Enum.Font.GothamBold
SendBtn.TextSize = 14
SendBtn.Parent = ChatFrame
Instance.new("UICorner", SendBtn).CornerRadius = UDim.new(0, 8)

local AutoFrame = Instance.new("Frame")
AutoFrame.Name = "AutoComplete"
AutoFrame.Visible = false
AutoFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
AutoFrame.BackgroundTransparency = 0.2
AutoFrame.BorderSizePixel = 0
AutoFrame.Size = UDim2.new(0, 240, 0, 0)
AutoFrame.Position = UDim2.new(0, 10, 1, -90)
AutoFrame.Parent = ChatFrame
Instance.new("UICorner", AutoFrame).CornerRadius = UDim.new(0, 6)

local AutoList = Instance.new("UIListLayout")
AutoList.SortOrder = Enum.SortOrder.LayoutOrder
AutoList.Padding = UDim.new(0, 2)
AutoList.Parent = AutoFrame

ToggleButton.MouseButton1Click:Connect(function()
	ChatFrame.Visible = not ChatFrame.Visible
end)

local function createChannelScroller(channelKey)
	local Scroller = Instance.new("ScrollingFrame")
	Scroller.Name = "Scroller_" .. channelKey
	Scroller.Size = UDim2.new(1, 0, 1, 0)
	Scroller.Position = UDim2.new(0, 0, 0, 0)
	Scroller.BackgroundTransparency = 1
	Scroller.ScrollBarThickness = 0
	Scroller.AutomaticCanvasSize = Enum.AutomaticSize.Y
	Scroller.Visible = (channelKey == "main")
	Scroller.Parent = ScrollersContainer

	local UIList = Instance.new("UIListLayout")
	UIList.SortOrder = Enum.SortOrder.LayoutOrder
	UIList.Padding = UDim.new(0, 4)
	UIList.Parent = Scroller

	channels[channelKey].scrollFrame = Scroller
	channels[channelKey].uiList = UIList

	local function updateScrollBars()
		local contentSize = UIList.AbsoluteContentSize.Y
		local windowSize = Scroller.AbsoluteWindowSize.Y
		if contentSize > windowSize then
			Scroller.ScrollBarThickness = 6
		else
			Scroller.ScrollBarThickness = 0
			Scroller.CanvasPosition = Vector2.new(0, 0)
		end
	end

	UIList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateScrollBars)
	Scroller:GetPropertyChangedSignal("AbsoluteWindowSize"):Connect(updateScrollBars)

	return Scroller
end

createChannelScroller("main")

local function closeChannel(channelKey)
	if channelKey == "main" then return end

	local tab = TabContainer:FindFirstChild("Tab_" .. channelKey)
	if tab then tab:Destroy() end

	local ch = channels[channelKey]
	if ch and ch.scrollFrame then
		ch.scrollFrame:Destroy()
	end

	channels[channelKey] = nil

	if activeChannel == channelKey then
		activeChannel = "main"
	end
end

local function createTabButton(channelKey, displayName, canClose)
	local TabBtn = Instance.new("TextButton")
	TabBtn.Name = "Tab_" .. channelKey
	-- Adjusted size to fit "X" without clipping
	TabBtn.Size = UDim2.new(0, canClose and 110 or 70, 0, 25)
	TabBtn.BackgroundColor3 = (channelKey == activeChannel) and Color3.fromRGB(70, 70, 70) or Color3.fromRGB(40, 40, 40)
	TabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	TabBtn.Text = "" -- Set empty text, we use a label for TextScaled
	TabBtn.LayoutOrder = (channelKey == "main") and 0 or 1
	TabBtn.Parent = TabContainer
	Instance.new("UICorner", TabBtn).CornerRadius = UDim.new(0, 4)

	-- Text Label inside button for TextScaled username
	local TextLab = Instance.new("TextLabel")
	TextLab.BackgroundTransparency = 1
	-- Leave space on right for "X" button
	TextLab.Size = UDim2.new(1, canClose and -25 or 0, 1, 0)
	TextLab.Position = UDim2.new(0, 0, 0, 0)
	TextLab.Text = displayName
	TextLab.TextColor3 = Color3.new(1,1,1)
	TextLab.Font = Enum.Font.GothamBold
	TextLab.TextScaled = true -- ONLY username is scaled
	-- Add padding so text isn't touching edges
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 5)
	pad.PaddingRight = UDim.new(0, 5)
	pad.Parent = TextLab
	TextLab.Parent = TabBtn

	if canClose then
		local CloseBtn = Instance.new("TextButton")
		CloseBtn.Name = "Close"
		CloseBtn.Size = UDim2.new(0, 20, 0, 20)
		-- Anchored to right side, no clipping with text
		CloseBtn.AnchorPoint = Vector2.new(1, 0.5)
		CloseBtn.Position = UDim2.new(1, -2, 0.5, 0)
		CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
		CloseBtn.Text = "×"
		CloseBtn.TextColor3 = Color3.new(1,1,1)
		CloseBtn.Font = Enum.Font.GothamBold
		CloseBtn.TextSize = 14
		CloseBtn.Parent = TabBtn
		Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 3)

		CloseBtn.MouseButton1Click:Connect(function()
			closeChannel(channelKey)
			switchToChannel("main")
		end)
	end

	TabBtn.MouseButton1Click:Connect(function()
		if channelKey ~= activeChannel then
			switchToChannel(channelKey)
		end
	end)

	return TabBtn
end

function switchToChannel(channelKey)
	activeChannel = channelKey

	for key, data in pairs(channels) do
		if data.scrollFrame then
			data.scrollFrame.Visible = (key == channelKey)
		end
		local tab = TabContainer:FindFirstChild("Tab_" .. key)
		if tab then
			tab.BackgroundColor3 = (key == channelKey) and Color3.fromRGB(70, 70, 70) or Color3.fromRGB(40, 40, 40)
		end
	end

	if channelKey == "main" then
		InputBox.PlaceholderText = "Type a message..."
	else
		InputBox.PlaceholderText = "Reply to whisper..."
	end
end

createTabButton("main", "Main", false)

local function onNameClicked(username)
	local prefix = "/w " .. username .. " "
	InputBox.Text = prefix
	InputBox:CaptureFocus()
	InputBox.CursorPosition = #InputBox.Text + 1
end

local function clearAutoComplete()
	for _, child in ipairs(AutoFrame:GetChildren()) do
		if child:IsA("TextButton") then child:Destroy() end
	end
	AutoFrame.Visible = false
	AutoFrame.Size = UDim2.new(0, 240, 0, 0)
end

local function setAutoComplete(list)
	clearAutoComplete()
	if #list == 0 then return end

	AutoFrame.Visible = true
	local max = math.min(5, #list)

	for i = 1, max do
		local p = list[i]
		local btn = Instance.new("TextButton")
		btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
		btn.BorderSizePixel = 0
		btn.Size = UDim2.new(1, 0, 0, 22)
		btn.TextXAlignment = Enum.TextXAlignment.Left
		btn.Font = Enum.Font.Gotham
		btn.TextSize = 12
		btn.TextColor3 = Color3.fromRGB(255, 255, 255)
		btn.Text = string.format("%s  (@%s)", p.Name, p.DisplayName)
		btn.Parent = AutoFrame

		btn.MouseButton1Click:Connect(function()
			InputBox.Text = "/w " .. p.Name .. " "
			InputBox:CaptureFocus()
			InputBox.CursorPosition = #InputBox.Text + 1
			clearAutoComplete()
		end)
	end

	AutoFrame.Size = UDim2.new(0, 240, 0, 22 * max + 2)
end

local function computeAutoComplete()
	local txt = InputBox.Text
	if txt:sub(1, 3):lower() ~= "/w " then
		clearAutoComplete()
		return
	end

	local rest = txt:sub(4)
	if rest:find("%s") then
		clearAutoComplete()
		return
	end

	local stub = rest:lower()
	if stub == "" then
		clearAutoComplete()
		return
	end

	local matches = {}
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LocalPlayer then
			local n = p.Name:lower()
			local d = p.DisplayName:lower()
			if n:sub(1, #stub) == stub or d:sub(1, #stub) == stub then
				table.insert(matches, p)
			end
		end
	end

	table.sort(matches, function(a, b) return a.Name:lower() < b.Name:lower() end)
	setAutoComplete(matches)
end

InputBox:GetPropertyChangedSignal("Text"):Connect(computeAutoComplete)
InputBox.Focused:Connect(computeAutoComplete)
InputBox.FocusLost:Connect(clearAutoComplete)

local function clearActiveChannelLocal()
	local ch = channels[activeChannel]
	if not ch or not ch.scrollFrame then return end

	for _, child in ipairs(ch.scrollFrame:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end

	ch.messages = {}
	ch.scrollFrame.CanvasPosition = Vector2.new(0, 0)
end

local function sendMessage()
	local msg = InputBox.Text
	if msg:match("^%s*$") then
		InputBox:ReleaseFocus()
		InputBox.Text = ""
		return
	end

	local trimmed = msg:match("^%s*(.-)%s*$")
	if trimmed and trimmed:lower() == "/clear" then
		clearActiveChannelLocal()
		InputBox.Text = ""
		return
	end

	if os.clock() - lastMessageSent < 0.5 then return end
	lastMessageSent = os.clock()

	if activeChannel ~= "main" and not msg:match("^/") then
		local bridgeData = channels[activeChannel]
		if bridgeData and bridgeData.targetUsername then
			msg = "/w " .. bridgeData.targetUsername .. " " .. msg
		end
	end

	chatRemote:FireServer(msg)
	InputBox.Text = ""
end

SendBtn.MouseButton1Click:Connect(function() sendMessage(); InputBox:ReleaseFocus() end)
InputBox.FocusLost:Connect(function(enter) if enter then sendMessage() end end)

local function refreshNames()
	for _, channel in pairs(channels) do
		if channel.scrollFrame then
			for _, child in pairs(channel.scrollFrame:GetChildren()) do
				if child:IsA("Frame") then
					local NameBtn = child:FindFirstChild("NameBtn")
					if NameBtn then
						local uName = NameBtn:GetAttribute("RawUser")
						local dName = NameBtn:GetAttribute("RawDisplay")
						local msgType = NameBtn:GetAttribute("MsgType")
						local isToSender = NameBtn:GetAttribute("IsToSender")
						local nameToShow = showDisplayName and dName or uName

						if msgType == 1 then
							NameBtn.Text = string.format("[%s]:", nameToShow)
						elseif msgType == 2 then
							NameBtn.Text = isToSender and "[You]:" or string.format("[%s]:", nameToShow)
						elseif msgType == 3 then
							NameBtn.Text = (uName ~= "System") and string.format("[%s]:", nameToShow) or ""
						end
					end
				end
			end
		end
	end
end

NameToggleBtn.MouseButton1Click:Connect(function()
	showDisplayName = not showDisplayName
	NameToggleBtn.Text = showDisplayName and "DN" or "US"
	refreshNames()
end)

local function addMessageToUI(msgType, senderName, displayName, message, colorHex, isToSender, bridgeKey)
	msgType = msgType or 1
	senderName = senderName or "Unknown"
	displayName = displayName or senderName
	message = message or ""
	colorHex = colorHex or "#FFFFFF"
	isToSender = isToSender or false
	bridgeKey = bridgeKey or nil

	if msgType == 4 and bridgeKey then
		closeChannel(bridgeKey)
		switchToChannel("main")
		return
	end

	local targetChannel = "main"
	local targetUsername = nil

	if msgType == 2 and bridgeKey then
		targetChannel = bridgeKey
		targetUsername = isToSender and displayName or senderName
		if not channels[bridgeKey] then
			channels[bridgeKey] = {messages = {}, scrollFrame = nil, uiList = nil, targetUsername = targetUsername}
			createChannelScroller(bridgeKey)
			createTabButton(bridgeKey, "@" .. targetUsername, true)
		else
			if not channels[bridgeKey].targetUsername then
				channels[bridgeKey].targetUsername = targetUsername
			end
		end
	end

	local channel = channels[targetChannel]
	if not channel or not channel.scrollFrame or not channel.uiList then return end

	local Scroller = channel.scrollFrame
	local UIList = channel.uiList

	local contentSizeBefore = UIList.AbsoluteContentSize.Y
	local windowSize = Scroller.AbsoluteWindowSize.Y

	local wasAtBottom = true
	if contentSizeBefore > windowSize then
		local distFromBottom = contentSizeBefore - (Scroller.CanvasPosition.Y + windowSize)
		if distFromBottom > 30 then
			wasAtBottom = false
		end
	end

	local LineFrame = Instance.new("Frame")
	LineFrame.BackgroundTransparency = 1
	LineFrame.Size = UDim2.new(1, 0, 0, 0)
	LineFrame.AutomaticSize = Enum.AutomaticSize.Y
	LineFrame.Parent = Scroller

	local LineLayout = Instance.new("UIListLayout")
	LineLayout.FillDirection = Enum.FillDirection.Horizontal
	LineLayout.SortOrder = Enum.SortOrder.LayoutOrder
	LineLayout.Padding = UDim.new(0, 4)
	LineLayout.Parent = LineFrame

	local NameBtn = Instance.new("TextButton")
	NameBtn.Name = "NameBtn"
	NameBtn.BackgroundTransparency = 1
	NameBtn.Font = Enum.Font.GothamBold
	NameBtn.TextSize = 16
	NameBtn.TextColor3 = Color3.fromHex(colorHex)
	NameBtn.AutomaticSize = Enum.AutomaticSize.XY
	NameBtn:SetAttribute("RawUser", senderName)
	NameBtn:SetAttribute("RawDisplay", displayName)
	NameBtn:SetAttribute("MsgType", msgType)
	NameBtn:SetAttribute("IsToSender", isToSender)

	local nameToShow = showDisplayName and displayName or senderName
	if msgType == 1 then
		NameBtn.Text = string.format("[%s]:", nameToShow)
	elseif msgType == 2 then
		NameBtn.Text = isToSender and "[You]:" or string.format("[%s]:", nameToShow)
	elseif msgType == 3 then
		NameBtn.Text = (senderName ~= "System") and string.format("[%s]:", nameToShow) or ""
	end

	NameBtn.Parent = LineFrame
	if (msgType == 1 or msgType == 2) and senderName ~= "System" then
		NameBtn.MouseButton1Click:Connect(function() onNameClicked(senderName) end)
	end

	local MsgLabel = Instance.new("TextLabel")
	MsgLabel.BackgroundTransparency = 1
	MsgLabel.Font = Enum.Font.Gotham
	MsgLabel.TextSize = 16
	MsgLabel.TextXAlignment = Enum.TextXAlignment.Left
	MsgLabel.TextWrapped = true
	MsgLabel.RichText = false
	MsgLabel.Text = message
	MsgLabel.Size = UDim2.new(0, 0, 0, 0)
	MsgLabel.AutomaticSize = Enum.AutomaticSize.XY

	if msgType == 2 then
		MsgLabel.TextColor3 = Color3.fromHex(colorHex)
	elseif msgType == 3 and senderName == "System" then
		MsgLabel.TextColor3 = Color3.fromRGB(170, 170, 170)
	else
		MsgLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	end

	MsgLabel.Parent = LineFrame

	task.wait()
	local nameWidth = NameBtn.AbsoluteSize.X
	MsgLabel.Size = UDim2.new(0, 380 - nameWidth - 10, 0, 0)
	MsgLabel.AutomaticSize = Enum.AutomaticSize.Y

	local contentSizeAfter = UIList.AbsoluteContentSize.Y
	if wasAtBottom and contentSizeAfter > windowSize then
		Scroller.CanvasPosition = Vector2.new(0, contentSizeAfter)
	elseif contentSizeAfter <= windowSize then
		Scroller.CanvasPosition = Vector2.new(0, 0)
	end
end

chatRemote.OnClientEvent:Connect(addMessageToUI)

UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == Enum.KeyCode.Slash or input.KeyCode == Enum.KeyCode.Semicolon then
		ChatFrame.Visible = true
		task.wait()
		InputBox:CaptureFocus()
		InputBox.Text = ""
	end
end)