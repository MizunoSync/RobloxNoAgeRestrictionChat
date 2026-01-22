--[[
Location: ServerScriptService > ChatServer
STATUS: FINAL - No Self-Whisper, Fixed Bubbles
]]

local TextService = game:GetService("TextService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Chat = game:GetService("Chat")

local chatRemote = Instance.new("RemoteEvent")
chatRemote.Name = "CustomChatEvent"
chatRemote.Parent = ReplicatedStorage

local whisperBridges = {}
local WHISPER_COLOR = "#AA00FF"

local function generateBridgeKey()
	return HttpService:GenerateGUID(false):sub(1, 16)
end

local function createWhisperBridge(senderId, receiverId)
	local bridgeKey = generateBridgeKey()
	whisperBridges[bridgeKey] = {
		Users = {senderId, receiverId},
		SenderUserId = senderId,
		ReceiverUserId = receiverId
	}
	return bridgeKey
end

local function findExistingBridge(user1Id, user2Id)
	for bridgeKey, bridgeData in pairs(whisperBridges) do
		if (bridgeData.SenderUserId == user1Id and bridgeData.ReceiverUserId == user2Id) or
			(bridgeData.SenderUserId == user2Id and bridgeData.ReceiverUserId == user1Id) then
			return bridgeKey
		end
	end
	return nil
end

local function findTargetPlayer(nameStub)
	if not nameStub or type(nameStub) ~= "string" then return nil end
	nameStub = nameStub:lower()
	for _, p in pairs(Players:GetPlayers()) do
		if p.Name:lower():sub(1, #nameStub) == nameStub or p.DisplayName:lower():sub(1, #nameStub) == nameStub then
			return p
		end
	end
	return nil
end

local function getPlayerByUserId(userId)
	for _, p in ipairs(Players:GetPlayers()) do
		if p.UserId == userId then
			return p
		end
	end
	return nil
end

local function getFilteredMessage(filterInstance, toUserId)
	if toUserId then
		local s, r = pcall(function() return filterInstance:GetChatForUserAsync(toUserId) end)
		if s and type(r) == "string" and r ~= "" then return r end
	end
	local s, r = pcall(function() return filterInstance:GetNonChatStringForBroadcastAsync() end)
	if s and type(r) == "string" and r ~= "" then return r end
	return nil
end

Players.PlayerAdded:Connect(function(player)
	task.wait(1.5)
	chatRemote:FireClient(player, 3, "System", "System", "Welcome to the chat! Use /w username or /tell to whisper.", "#AAAAAA", false, nil)
end)

Players.PlayerRemoving:Connect(function(player)
	local leavingId = player.UserId
	for bridgeKey, data in pairs(whisperBridges) do
		if table.find(data.Users, leavingId) then
			local otherId = (data.Users[1] == leavingId) and data.Users[2] or data.Users[1]
			local otherPlayer = getPlayerByUserId(otherId)
			if otherPlayer then
				chatRemote:FireClient(otherPlayer, 4, "System", "System", "", "#AAAAAA", false, bridgeKey)
			end
			whisperBridges[bridgeKey] = nil
		end
	end
end)

chatRemote.OnServerEvent:Connect(function(player, message)
	if type(message) ~= "string" then return end
	message = message:match("^%s*(.-)%s*$")
	if not message or message == "" then return end
	if #message > 200 then message = string.sub(message, 1, 200) end

	local isWhisper = false
	local targetPlayer = nil
	local cleanMessage = message

	local patterns = {
		{cmd = "/w ", len = 3}, {cmd = "/whisper ", len = 9},
		{cmd = "/tell ", len = 6}, {cmd = "/pm ", len = 4}, {cmd = "/msg ", len = 5}
	}

	for _, pattern in ipairs(patterns) do
		if message:sub(1, pattern.len):lower() == pattern.cmd then
			local rest = message:sub(pattern.len + 1)
			local namePart = rest:match("^(%S+)")
			if namePart then
				targetPlayer = findTargetPlayer(namePart)
				if targetPlayer then
					cleanMessage = rest:match("^%S+%s+(.+)")
					if not cleanMessage or cleanMessage == "" then return end
					isWhisper = true
					break
				end
			end
		end
	end

	local filterInstance
	local fSuccess = pcall(function()
		filterInstance = TextService:FilterStringAsync(cleanMessage, player.UserId)
	end)
	if not fSuccess then filterInstance = nil end

	if isWhisper then
		if not targetPlayer then
			chatRemote:FireClient(player, 3, "System", "System", "Player not found.", "#FF3333", false, nil)
			return
		end

		-- PREVENT SELF-WHISPER
		if targetPlayer == player then
			chatRemote:FireClient(player, 3, "System", "System", "You cannot whisper yourself!", "#FF3333", false, nil)
			return
		end

		local existingBridge = findExistingBridge(player.UserId, targetPlayer.UserId)
		local bridgeKey = existingBridge or createWhisperBridge(player.UserId, targetPlayer.UserId)

		local receiverText = cleanMessage
		local senderText = cleanMessage

		if filterInstance then
			local safeRec = getFilteredMessage(filterInstance, targetPlayer.UserId)
			if safeRec then receiverText = safeRec end
			local safeSend = getFilteredMessage(filterInstance, player.UserId)
			if safeSend then senderText = safeSend end
		end

		chatRemote:FireClient(targetPlayer, 2, player.Name, player.DisplayName, receiverText, WHISPER_COLOR, false, bridgeKey)
		chatRemote:FireClient(player, 2, targetPlayer.Name, targetPlayer.DisplayName, senderText, WHISPER_COLOR, true, bridgeKey)

		if player.Character then
			pcall(function()
				game:GetService("Chat"):Chat(player.Character.Head, "?? " .. senderText, Enum.ChatColor.White)
			end)
		end

		if not existingBridge then
			chatRemote:FireClient(player, 3, "System", "System", "?? Bridge: @"..targetPlayer.DisplayName, "#00FF00", false, nil)
			chatRemote:FireClient(targetPlayer, 3, "System", "System", "?? Bridge: @"..player.DisplayName, "#00FF00", false, nil)
		end
	else
		local publicText = cleanMessage
		if filterInstance then
			local s, r = pcall(function() return filterInstance:GetNonChatStringForBroadcastAsync() end)
			if s and type(r) == "string" and r ~= "" then publicText = r end
		end
		chatRemote:FireAllClients(1, player.Name, player.DisplayName, publicText, "#00AAFF", false, nil)

		if player.Character and player.Character:FindFirstChild("Head") then
			pcall(function()
				game:GetService("Chat"):Chat(player.Character.Head, publicText, Enum.ChatColor.White)
			end)
		end
	end
end)