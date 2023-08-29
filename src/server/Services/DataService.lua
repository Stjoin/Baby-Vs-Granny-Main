local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")

local Shared = ReplicatedStorage.Shared
local Packages = ReplicatedStorage.Packages

local GameSettings = require(Shared.GameSettings)
local Knit = require(Packages.Knit)
local ProfileService = require(Packages.profileservice)

local Profiles = {}
local ProfileTemplate = {
	Wins = 0,
	EquippedSkins = {
		Granny = "Default",
		Baby = "Default",
	},
}

local UniverseProfileStore = ProfileService.GetProfileStore("PlayerData", ProfileTemplate)

local DataService = Knit.CreateService({
	Name = "DataService",
	Client = {
		GetData = Knit.CreateSignal(),
	},
})

function DataService:UpdateWins(player)
	local profile = Profiles[player]
	if profile ~= nil then
		profile.Data.Wins += 1
	end
end

function DataService:GetEquippedSkins(player)
	return DataService:GetData(player).EquippedSkins
end

function DataService.Client:GetData(player)
	return DataService:GetData(player)
end

function DataService:GetData(player)
	local profile = Profiles[player]
	if profile ~= nil then
		return profile.Data
	end
end

function DataService:PlayerAdded(player)
	local profile = UniverseProfileStore:LoadProfileAsync("Player_" .. player.UserId, "ForceLoad")
	if profile ~= nil then
		profile:AddUserId(player.UserId)
		profile:Reconcile()

		profile:ListenToRelease(function()
			Profiles[player] = nil
			player:Kick()
		end)
		if player:IsDescendantOf(Players) == true then
			Profiles[player] = profile
		else
			profile:Release()
		end
	else
		player:Kick()
	end
end

function DataService:KnitStart()
	for _, player in pairs(Players:GetPlayers()) do
		self:PlayerAdded(player)
	end

	Players.PlayerAdded:Connect(function(player)
		self:PlayerAdded(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		local profile = Profiles[player]
		if profile ~= nil then
			profile:Release()
		end
	end)
end

return DataService
