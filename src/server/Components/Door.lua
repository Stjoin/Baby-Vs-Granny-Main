local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Packages = ReplicatedStorage.Packages

local Component = require(Packages.Component)
local Knit = require(Packages.Knit)

local DoorService

local Door = Component.new({
	Tag = "Door",
})

function Door:Start()
	if DoorService == nil then
		DoorService = Knit.GetService("DoorService")
	end

	DoorService:Create(self.Instance)
end

return Door
