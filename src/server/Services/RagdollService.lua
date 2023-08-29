local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Packages = ReplicatedStorage.Packages

local GameSettings = require(Shared.GameSettings)
local Knit = require(Packages.Knit)
local TableUtil = require(Packages.TableUtil)

local stateType = Enum.HumanoidStateType

local RAGDOLL_NAME = "RagdollConstraint"
local NOCOLLIDE_NAME = "RagdollNoCollide"

local noCollisionMap = {
	R15 = {
		Head = { "LeftUpperArm", "LeftUpperLeg", "LowerTorso", "RightUpperArm", "RightUpperLeg" },
		LeftFoot = { "LowerTorso", "UpperTorso" },
		LeftHand = { "LowerTorso", "UpperTorso" },
		RightFoot = { "LowerTorso", "UpperTorso" },
		RightHand = { "LowerTorso", "UpperTorso" },
		LeftLowerArm = { "LowerTorso", "UpperTorso" },
		LeftLowerLeg = { "LowerTorso", "UpperTorso" },
		LeftUpperArm = { "LeftUpperLeg", "LowerTorso", "UpperTorso", "RightUpperArm", "RightUpperLeg" },
		LeftUpperLeg = { "LowerTorso", "UpperTorso", "RightUpperLeg" },
		RightLowerArm = { "LowerTorso", "UpperTorso" },
		RightLowerLeg = { "LowerTorso", "UpperTorso" },
		RightUpperArm = { "RightUpperLeg", "LowerTorso", "UpperTorso", "LeftUpperLeg" },
		RightUpperLeg = { "LowerTorso", "UpperTorso" },
	},

	R6 = {
		Head = { "Left Arm", "Left Leg", "Torso", "Right Arm", "Right Leg" },
	},
}

local RagdollService = Knit.CreateService({
	Name = "RagdollService",
	Client = {
		StartRaggdoll = Knit.CreateSignal(),
	},
})

local function getMotors(character: Model): { Motor6D }
	local t: { Motor6D } = {}
	local humanoid: Humanoid = character.Humanoid

	for _, part in character:GetChildren() do
		for _, descendant in part:GetChildren() do
			if descendant:IsA("Motor6D") then
				t[#t + 1] = descendant
			end
		end
	end

	return t
end

local function createNoCollisionConstraints(character, rigTypeName)
	for i, subMap in noCollisionMap[rigTypeName] do
		for _, x in subMap do
			local noCollision = Instance.new("NoCollisionConstraint")
			noCollision.Name = NOCOLLIDE_NAME
			noCollision.Part0 = character[i]
			noCollision.Part1 = character[x]
			noCollision.Parent = character
		end
	end
end

function RagdollService:CreateJoints(character: Model): { Motor6D }
	if not character:IsA("Model") or not character:FindFirstChildOfClass("Humanoid") then
		return
	end

	local rigType = character.Humanoid.RigType
	local motors = getMotors(character)

	createNoCollisionConstraints(character, rigType.Name)

	for _, motor in motors do
		local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")
		a0.Name, a1.Name = RAGDOLL_NAME, RAGDOLL_NAME
		a0.CFrame = motor.C0
		a1.CFrame = motor.C1
		a0.Parent = motor.Part0
		a1.Parent = motor.Part1

		local name = motor.Name:gsub("Right", "")
		name = name:gsub("Left", "")
		name = name:gsub("Joint", "")
		name = name:gsub(" ", "")

		local b = (
			ReplicatedStorage.Assets.Rigs[rigType.Name]:FindFirstChild(name)
			or ReplicatedStorage.Assets.Rigs[rigType.Name].Default
		):Clone()
		b.Name = RAGDOLL_NAME

		b.Attachment0 = a0
		b.Attachment1 = a1
		b.Parent = motor.Part1
	end

	return motors
end

-- Remove joints for ragdoll
function RagdollService:DestroyJoints(character: Model)
	for _, descendant: Instance in character:GetDescendants() do
		-- Remove BallSockets and NoCollides, leave the additional Attachments
		if
			(descendant:IsA("Constraint") or descendant:IsA("WeldConstraint") or descendant:IsA("Attachment"))
				and descendant.Name == RAGDOLL_NAME
			or descendant:IsA("NoCollisionConstraint") and descendant.Name == NOCOLLIDE_NAME
		then
			descendant:Destroy()
		end
	end
end

-- Setup properties for Ragdoll
function RagdollService:Ragdoll(character: Model)
	local rootPart: BasePart? = character.PrimaryPart
	local humanoid: Humanoid = character.Humanoid

	humanoid.WalkSpeed = 0
	humanoid.AutoRotate = false
	rootPart.CanCollide = false
	character.Head.CanCollide = true

	if not character.PrimaryPart:GetNetworkOwner() then
		if humanoid.Health > 0 and humanoid:GetState() ~= stateType.Physics then
			humanoid:ChangeState(stateType.Physics)
		end
	end
end

-- Reset properties for ragdoll
function RagdollService:UnRagdoll(character: Model)
	local humanoid: Humanoid = character.Humanoid

	if humanoid.Health > 0 then
		humanoid.WalkSpeed = 10
		humanoid.AutoRotate = true
		character.PrimaryPart.CanCollide = true
		character.Head.CanCollide = false

		if not character.PrimaryPart:GetNetworkOwner() then
			if humanoid:GetState() ~= stateType.GettingUp then
				humanoid:ChangeState(stateType.GettingUp)
			end
		end
	end
end

-- Set motor-set enabled
function RagdollService:SetMotorsEnabled(motors: { Motor6D }, enabled: boolean)
	for _, motor in motors do
		motor.Enabled = enabled
	end
end

-- Check whether a humanoid is ragdolled or not
function RagdollService:IsRagdolled(humanoid: Humanoid): boolean
	return humanoid:GetState() == stateType.Physics
end

function RagdollService:StartRagdoll(player)
	if not player.Character or not player.Character:FindFirstChildOfClass("Humanoid") then
		return false
	end
	local Humanoid = player.Character:FindFirstChildOfClass("Humanoid")
	local canRagdoll = not self:IsRagdolled(Humanoid)
	print(canRagdoll)
	if canRagdoll then
		print("yes")
		player.Character.PrimaryPart:SetNetworkOwner(nil)

		task.wait(0.1)

		local motors = self:CreateJoints(player.Character)
		self:Ragdoll(player.Character)
		self:SetMotorsEnabled(motors, false)

		-- Humanoid:ChangeState(stateType.Physics)

		task.delay(GameSettings.ragdollDuration, function()
			self:DestroyJoints(player.Character)
			self:SetMotorsEnabled(motors, true)
			self:UnRagdoll(player.Character)

			-- Humanoid:ChangeState(stateType.GettingUp)

			player.Character.PrimaryPart:SetNetworkOwner(player)
		end)
	end

	return canRagdoll, canRagdoll and GameSettings.ragdollDuration
end

function RagdollService:KnitStart()
	self.Client.StartRaggdoll:Connect(function(player)
		self:StartRagdoll(player)
	end)
end

return RagdollService
