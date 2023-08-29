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

local BabyHandler = Knit.CreateController({
	Name = "BabyHandler",
})

function BabyHandler:KickBaby(lookVector)
	local HumanoidRootPart = Character.HumanoidRootPart

	local impulse = lookVector * GameSettings.KickStrength + Vector3.new(0, GameSettings.KickYAxis, 0)

	local AngularVelocity = Instance.new("AngularVelocity")
	local Att0 = Instance.new("Attachment")

	AngularVelocity.Attachment0 = Att0
	AngularVelocity.AngularVelocity = Vector3.new(1, 1, 1) * 30
	AngularVelocity.MaxTorque = math.huge
	AngularVelocity.RelativeTo = Enum.ActuatorRelativeTo.Attachment0

	AngularVelocity.Parent = HumanoidRootPart
	Att0.Parent = HumanoidRootPart

	Debris:AddItem(AngularVelocity, 0.2)
	Debris:AddItem(Att0, 0.2)

	HumanoidRootPart:ApplyImpulse(impulse)
	RagdollService.StartRaggdoll:Fire()

	Character.Humanoid:ChangeState(Enum.HumanoidStateType.Physics)

	task.delay(GameSettings.ragdollDuration + 0.5, function()
		Character.Humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
	end)
end

function BabyHandler:GameStart()
	GameLoop.KickBaby:Connect(function(lookVector)
		self:KickBaby(lookVector)
	end)
end

function BabyHandler:KnitStart()
	if GameLoop == nil and RagdollService == nil then
		GameLoop = Knit.GetService("GameLoop")
		RagdollService = Knit.GetService("RagdollService")
	end

	GameLoop.GameStart:Connect(function(Role)
		if Role == "Granny" then
			return
		end

		self:GameStart()
	end)
end

return BabyHandler
