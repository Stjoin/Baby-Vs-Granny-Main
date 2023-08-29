local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local EasyViewmodel = require(ReplicatedStorage.lib)

local Player: Player = Players.LocalPlayer

local Model = ReplicatedStorage:WaitForChild("Viewmodel"):Clone()

local Viewmodel = EasyViewmodel.new(Model,{})

for _, Animation: Animation in Model.Animations:GetChildren() do
	Viewmodel:LoadAnimation(Animation.Name, Animation, true, true)
end

Player.CharacterAdded:Connect(function(Character: Model)
	local Humanoid: Humanoid = Character:WaitForChild("Humanoid")

	Humanoid.Running:Connect(function(Speed: number)
		if (Speed > .001) then
			local Walk: AnimationTrack = Viewmodel:GetAnimation("Walk")
			if not (Walk.IsPlaying) then
				Viewmodel:PlayCoreAnimation("Walk")
			end

			Walk:AdjustSpeed(Humanoid.WalkSpeed / 14)
		else
			Viewmodel:PlayCoreAnimation("Idle",.1)
		end
	end)

	Humanoid.Jumping:Connect(function()
		Viewmodel:PlayCoreAnimation("Jump",0)
	end)

	local LastState: Enum.HumanoidStateType = Humanoid:GetState()
	local LastDifferentState: Enum.HumanoidStateType = LastState
	RunService.Heartbeat:Connect(function()
		local State: Enum.HumanoidStateType = Humanoid:GetState()
		if (State == Enum.HumanoidStateType.Freefall) and not (Viewmodel:GetAnimation("Fall").IsPlaying) and not (Viewmodel:GetAnimation("Jump").IsPlaying) then
			if (LastDifferentState == Enum.HumanoidStateType.Jumping) then
				Viewmodel:PlayCoreAnimation("Fall",.3)
			else
				Viewmodel:PlayCoreAnimation("Fall")
			end
		end

		local Walk: AnimationTrack = Viewmodel:GetAnimation("Walk")
		Walk:AdjustSpeed(Humanoid.WalkSpeed / 14)

		if (State ~= LastState) then
			LastDifferentState = State
		end
		LastState = State
	end)

	Viewmodel:PlayCoreAnimation("Idle")

	-- Tools

	Character.ChildAdded:Connect(function(Child: Tool)
		if not (Child:IsA("Tool")) then return end

		Viewmodel:EquipTool(Child:Clone())
		Viewmodel:PlayAnimation("ToolEquip",0)

		local ToolEquip: AnimationTrack = Viewmodel:GetAnimation("ToolEquip")
		if (ToolEquip) then
			ToolEquip.Stopped:Once(function()
				if (Child.Parent ~= Character) then return end

				Viewmodel:PlayAnimation("ToolIdle",.1,true)
			end)
		end

		for _, Part: Part | ParticleEmitter in Child:GetDescendants() do
			if (Part:IsA("BasePart")) then
				Part.LocalTransparencyModifier = 1
			elseif (Part:IsA("ParticleEmitter")) then
				Part.Enabled = false
			end
		end
	end)
	Character.ChildRemoved:Connect(function(Child: Tool)
		if not (Child:IsA("Tool")) then return end
		
		for _, Part: Part in Child:GetDescendants() do
			if (Part:IsA("BasePart")) then
				Part.LocalTransparencyModifier = 0
			elseif (Part:IsA("ParticleEmitter")) then
				Part.Enabled = true
			end
		end

		Viewmodel:UnequipTool()
	end)
end)

-- local Idle: AnimationTrack = Viewmodel:LoadAnimation("Idle", Model.Animations.Idle)
-- Idle:Play()