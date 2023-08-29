local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

local Shared = ReplicatedStorage.Shared
local Packages = ReplicatedStorage.Packages

local GameSettings = require(Shared.GameSettings)
local Knit = require(Packages.Knit)
local TableUtil = require(Packages.TableUtil)
local Timer = require(Packages.Timer)
local Signal = require(Packages.Signal)

local GameLoop, RagdollService

local GrannyHandler = Knit.CreateController({
	Name = "GrannyHandler",
})

function GrannyHandler:KnockBackGranny(lookVector, Divider)
	local HumanoidRootPart = Character.HumanoidRootPart
	print(Divider)
	local impulse = lookVector * (GameSettings.KnockBackStrength * Divider)
		+ Vector3.new(0, GameSettings.KnockbackYAxis, 0)

	HumanoidRootPart:ApplyImpulse(impulse)
	RagdollService.StartRaggdoll:Fire()

	Character.Humanoid:ChangeState(Enum.HumanoidStateType.Physics)

	task.delay(GameSettings.ragdollDuration + 0.5, function()
		Character.Humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
	end)
end

function GrannyHandler:GameStart()
	GameLoop.KnockBackGranny:Connect(function(...)
		print("yes")
		self:KnockBackGranny(...)
	end)
end

function GrannyHandler:KnitStart()
	if GameLoop == nil and RagdollService == nil then
		GameLoop = Knit.GetService("GameLoop")
		RagdollService = Knit.GetService("RagdollService")
	end

	GameLoop.GameStart:Connect(function(Role)
		if Role == "Baby" then
			return
		end

		self:GameStart()
	end)
end

return GrannyHandler
