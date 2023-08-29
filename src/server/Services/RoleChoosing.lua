local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Packages = ReplicatedStorage.Packages

local GameSettings = require(Shared.GameSettings)
local Knit = require(Packages.Knit)
local TableUtil = require(Packages.TableUtil)

local GameLoop

local RoleChoosing = Knit.CreateService({
	Name = "RoleChoosing",
	Client = {
		RoleSelectedEvent = Knit.CreateSignal(),
		RemoveRoleEvent = Knit.CreateSignal(),
		Ready = Knit.CreateSignal(),
		UnReady = Knit.CreateSignal(),
	},
	ReadyPlayers = {},
	Roles = {
		Baby = nil,
		Granny = nil,
	},
})

function RoleChoosing:CheckIfAlreadyChoosenARole(Player)
	for _, player in self.Roles do
		print(player)
		if player == Player then
			return true
		end
	end
	return false
end

function RoleChoosing:RoleSelectedEvent(player, role)
	if self.Roles[role] or self.ReadyPlayers[player] == true then
		return
	elseif self:CheckIfAlreadyChoosenARole(player) then
		self:RemoveRoleEvent(player)
		self:RoleSelectedEvent(player, role)
	else
		self.Roles[role] = player
		self.Client.RoleSelectedEvent:FireAll(player, role)
	end
end

function RoleChoosing:RemoveRoleEvent(player)
	for role, playerInRole in self.Roles do
		if playerInRole == player then
			self.Roles[role] = nil
			self.Client.RemoveRoleEvent:FireAll(player, role)
		end
	end
end

function RoleChoosing:Ready(player)
	local Count = 0
	self.ReadyPlayers[player] = true

	for _, status in self.ReadyPlayers do
		if status == true then
			Count += 1
		end
	end

	if Count == GameSettings.MaxPlayers then
		GameLoop:StartGame(self.Roles)
	end

	self.Client.Ready:FireAll(self.Roles, Count, player)
end

function RoleChoosing:UnReady(player)
	self.ReadyPlayers[player] = false

	self:RemoveRoleEvent(player)
end

function RoleChoosing:KnitStart()
	print("GameStart")
	if GameLoop == nil then
		GameLoop = Knit.GetService("GameLoop")
	end

	self.Client.RoleSelectedEvent:Connect(function(...)
		self:RoleSelectedEvent(...)
	end)

	self.Client.RemoveRoleEvent:Connect(function(...)
		self:RemoveRoleEvent(...)
	end)

	self.Client.Ready:Connect(function(...)
		self:Ready(...)
	end)

	self.Client.UnReady:Connect(function(...)
		self:UnReady(...)
	end)
end

return RoleChoosing
