local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Packages = ReplicatedStorage.Packages

local Component = require(Packages.Component)
local Knit = require(Packages.Knit)
local FractureGlass = require(ReplicatedStorage.FractureGlass)

local Glass = Component.new({
	Tag = "Glass",
})

function Glass:Start()
	local Debounce = false

	self.Instance.Touched:Connect(function(hit)
		print("asdasd")
		if not Debounce then
			Debounce = true
			print(hit.CFrame.LookVector)
			FractureGlass(self.Instance, hit.Position, hit.CFrame.LookVector * 50)
		end
	end)
end

return Glass
