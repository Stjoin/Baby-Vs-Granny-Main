local Janitor = require(script.Parent.Parent.Janitor)
local Types = require(script.Parent.Types)
local Util = require(script.Parent.Util)
local Spring = require(script.Parent.Parent.Spring)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local UserInputService = game:GetService("UserInputService")

local Player = Players.LocalPlayer

local VM: Types.Viewmodel = {}
VM.__index = VM

function VM.new(ViewmodelModel: Model, Settings: Types.ViewmodelSettings?)
	local self = setmetatable({
		Janitor = Janitor.new();
		ToolJanitor = Janitor.new();
		
		Settings = Settings or {};
		Sounds = {};
		ToolConfig = {};
		
		PlayingCoreAnimation = "";
		
		-- Viewmodel
		Instance = ViewmodelModel;

		RightArm = ViewmodelModel:FindFirstChild("Right Arm");
		LeftArm = ViewmodelModel:FindFirstChild("Left Arm");
	},VM)

	self.FirePlayedAnimation = self:NewEvent("PlayedAnimation")

	-- Constructor

	self:CheckViewmodelModel()
	
	self.AnimationController = ViewmodelModel:FindFirstChildWhichIsA("Humanoid") or ViewmodelModel:FindFirstChildWhichIsA("AnimationController")
	self.Animator = self.AnimationController:FindFirstChildWhichIsA("Animator") or Instance.new("Animator")
	self.Animator.Parent = self.AnimationController

	local Shirt: Shirt = ViewmodelModel:FindFirstChildWhichIsA("Shirt")
	task.spawn(function()
		pcall(function()
			Shirt.ShirtTemplate = (Player.Character or Player.CharacterAdded:Wait()):WaitForChild("Shirt").ShirtTemplate
		end)
	end)
	
	self.Camera = self.Settings.Camera or workspace.CurrentCamera
	self.Animations = {}

	self:CreateSprings()

	-- Setup

	local RightGrip: Attachment = self.RightArm:FindFirstChild("Grip") or Instance.new("Attachment")
	RightGrip.Name = "Grip"
	RightGrip.CFrame = CFrame.new(-(Vector3.yAxis * self.RightArm.Size.Y * .5)) * CFrame.Angles(math.rad(-90),0,math.rad(-90))
	RightGrip.Parent = self.RightArm

	self.RightGrip = RightGrip

	self.Janitor:Add(self.Instance,"Destroy")

	ViewmodelModel.Parent = self.Camera

	if (type(self.Settings.AutoLoadAnimations) == "table") then
		for Name: string, Id: string in self.Settings.AutoLoadAnimations do
			self:LoadAnimation(Name, Id, true, true)
		end
	end

	local function SetupPlayerCharacter(Character: Model)
		if not (Character) then return end

		local Humanoid: Humanoid = Character:WaitForChild("Humanoid", 10)
		if not (Humanoid) then return end

		Humanoid.Jumping:Connect(function(DidJump: boolean)
			if not (DidJump) then return end

			self.Springs.Jump:Impulse(Vector3.new(-1,0,0))
		end)
	end

	self.Janitor:Add(Player.CharacterAdded:Connect(SetupPlayerCharacter),"Disconnect")
	SetupPlayerCharacter()

	-- Connections

	self.Janitor:Add(RunService.RenderStepped:Connect(function(DeltaTime: number)
		self:Update(DeltaTime)
	end),"Disconnect")

	return self
end

function VM:Update(DeltaTime: number)
	local Root: Part = self:GetRoot()

	local Character: Model = self:GetCharacter()
	local Humanoid: Humanoid = Character:WaitForChild("Humanoid")

	do -- Update ViewmodelModel
		for _, Part: BasePart in self.Instance:GetDescendants() do
			if not (Part:IsA("BasePart")) then continue end

			Part.CanCollide = false
			Part.CanQuery = false
			Part.CanTouch = false

			Part.CastShadow = false
		end
	end

	do -- Sway
		local MouseDelta: Vector2 = UserInputService:GetMouseDelta()
		self.Springs.Sway:Impulse(Vector3.new(MouseDelta.X * .005, MouseDelta.Y * .005))
	end

	do -- Movement Sway
		local MovementSway: Vector3 = Vector3.new(
			Util:GetBobbing(2, 5, .03),
			-Util:GetBobbing(2, 3, .02),
			Util:GetBobbing(2, 3, .04)
		)

		local Velocity: Vector3 = Root.AssemblyLinearVelocity * Vector3.new(1,0,1) -- Dont count Y Axis
		self.Springs.WalkCycle.Target = ((MovementSway * .04) * DeltaTime * 60 * math.clamp(Velocity.Magnitude,-25,25))
	end

	do -- Tilt
		self.Springs.Tilt.Target = (Humanoid.MoveDirection:Dot(-Root.CFrame.RightVector)) * 10
	end

	local OriginCF: CFrame = if (self.Hidden) then CFrame.new(0,1e29,0) else self.Camera.CFrame

	self.Instance:PivotTo(OriginCF * self:GetSway() * self:GetWalkCycle() * self:GetJumpSpring() * CFrame.Angles(0,0,math.rad(self.Springs.Tilt.Position)))
end

function VM:NewEvent(Name: string): (...any) -> nil
	local Event: BindableEvent = Instance.new("BindableEvent")
	self[Name] = Event.Event
	
	return function(...)
		Event:Fire(...)
	end
end

function VM:CreateSprings()
	self.Springs = {}

	local Jump = Spring.new(Vector3.new())
	Jump.Damper = .25
	Jump.Speed = 6
	self.Springs.Jump = Jump

	local Sway = Spring.new(Vector3.new())
	Sway.Damper = .5
	Sway.Speed = 15
	self.Springs.Sway = Sway

	local WalkCycle = Spring.new(Vector3.new())
	WalkCycle.Damper = .25
	WalkCycle.Speed = 15
	self.Springs.WalkCycle = WalkCycle

	local Tilt = Spring.new(0)
	Tilt.Damper = .5
	Tilt.Speed = 10
	self.Springs.Tilt = Tilt
end

function VM:GetSway(): CFrame
	local Sway: Vector3 = self.Springs.Sway.Position

	local SwayX = math.clamp(Sway.Y, -.9, .9)
	local SwayY = math.clamp(-Sway.X / 3, -.5, .5)
	local SwayZ = 0

	return CFrame.Angles(SwayX, SwayY, SwayZ)
end

function VM:GetWalkCycle()
	local WalkCycle: Vector3 = self.Springs.WalkCycle.Position

	return CFrame.Angles(WalkCycle.X, WalkCycle.Y, WalkCycle.Z)
end

function VM:GetJumpSpring()
	local Position: Vector3 = self.Springs.Jump.Position

	return CFrame.Angles(Position.X, Position.Y, Position.Z)
end

function VM:GetCharacter()
	return Player.Character or Player.CharacterAdded:Wait()
end

function VM:GetRoot()
	return self:GetCharacter():WaitForChild("HumanoidRootPart")
end

function VM:CheckViewmodelModel()
	local ViewmodelModel: Model = self.Instance

	assert(typeof(ViewmodelModel) == "Instance", "ViewmodelModel has to be an Instance (Model)!")
	assert(ViewmodelModel:IsA("Model"), "You need to pass a valid ViewmodelModel! (Not a Model)")
	assert(ViewmodelModel:FindFirstChild("HumanoidRootPart"):IsA("BasePart"), "You need to pass a valid ViewmodelModel! (Missing HumanoidRootPart)")
	assert(ViewmodelModel:FindFirstChildWhichIsA("Humanoid") or ViewmodelModel:FindFirstChildWhichIsA("AnimationController"), "You need to pass a valid ViewmodelModel! (Missing Humanoid/AnimationController)")

	assert(ViewmodelModel:FindFirstChild("Right Arm"), "Viewmodel doesn't contain a 'Right Arm'!")
	assert(ViewmodelModel:FindFirstChild("Left Arm"), "Viewmodel doesn't contain a 'Left Arm'!")
end

function VM:Destroy()
	self.Janitor:Destroy()
end

-- Module Exposed

function VM:LoadAnimation(Name: string, Animation: Animation, Force: boolean?, IsCore: boolean?): AnimationTrack
	if not (Force) then
		assert((self.Animations[Name] == nil), ("Animation '%s' is already taken!"):format(Name))
	end
	assert(Animation:IsA("Animation"), "Passed Animation has to be an Animation!")

	local AnimationTrack: AnimationTrack = self.Animator:LoadAnimation(Animation)
	self.Animations[Name] = AnimationTrack

	if (IsCore) then
		AnimationTrack:SetAttribute("IsCore",true)
	end

	return AnimationTrack
end

function VM:UnloadAnimation(Name: string): boolean?
	assert(type(Name) == "string")

	local AnimationTrack: AnimationTrack = self.Animations[Name]
	if not (AnimationTrack) then return end

	AnimationTrack:Stop(.1)

	self.Animations[Name] = nil
	AnimationTrack:Destroy()

	return true
end

function VM:GetAnimation(Name: string): AnimationTrack?
	return self.Animations[Name]
end

function VM:PlayAnimation(Name: string, FadeTime: number?, DontStopOtherAnimations: boolean?): AnimationTrack?
	local AnimationTrack: AnimationTrack = self:GetAnimation(Name)
	if not (AnimationTrack) then return end

	local JanitorKey: string = `Animation_{Name}`

	if not (AnimationTrack:GetAttribute("SoundConnected")) then
		AnimationTrack:SetAttribute("SoundConnected", true)

		self.Janitor:Add(AnimationTrack:GetMarkerReachedSignal("Sound"):Connect(function(Name: string)
			print(Name)
			self:PlaySound(Name)
		end),"Disconnect",JanitorKey);

		--TODO
		-- self.Janitor:Add(AnimationTrack:GetMarkerReachedSignal("StartSound"):Connect(function(Name: string)
			
		-- end),"Disconnect",JanitorKey);

		-- self.Janitor:Add(AnimationTrack:GetMarkerReachedSignal("StopSound"):Connect(function(Name: string)
			
		-- end),"Disconnect",JanitorKey);

		AnimationTrack.Ended:Once(function()
			AnimationTrack:SetAttribute("SoundConnected", false)
			self.Janitor:Remove(JanitorKey)
		end)
	end

	if not (DontStopOtherAnimations) then
		self:StopAnimations()
	end

	AnimationTrack:Play(FadeTime)
	self.FirePlayedAnimation(Name)

	return AnimationTrack
end

function VM:StopAnimations(FadeTime: number?)
	for _, AnimationTrack: AnimationTrack in self.Animations do
		AnimationTrack:Stop(FadeTime)
	end
end

function VM:PlayCoreAnimation(Name: string, FadeTime: number?, DontStopOtherCoreAnimations: boolean?): AnimationTrack?
	self.PlayingCoreAnimation = Name

	if (self:GetTool()) then return end

	if not (DontStopOtherCoreAnimations) then
		self:StopCoreAnimations()
	end

	return self:PlayAnimation(Name,FadeTime,true)
end

function VM:StopCoreAnimations(FadeTime: number?)
	for Name: string, AnimationTrack: AnimationTrack in self.Animations do
		if not (AnimationTrack:GetAttribute("IsCore")) then continue end

		AnimationTrack:Stop(FadeTime)
	end
end

function VM:EquipTool(Tool: Tool): boolean?
	-- assert(self.EquippedTool == nil, "A tool is already equipped! Unequip it with the :UnequipTool() method!")
	assert(Tool:IsA("Tool"), "You have to pass a valid Tool to equip!")

	if (self.EquippedTool) then
		self:UnequipTool()
	end

	local Handle: Part = Tool:FindFirstChild("Handle")
	assert(Handle, "Tool has to have a Handle to be equipped!")

	self.ToolConfig = {}

	local Config: ModuleScript = Tool:FindFirstChild("Config")
	if (Config) and (Config:IsA("ModuleScript")) then
		self.ToolConfig = require(Config)
	end
	
	local ToolAnimations = {}

	if (Tool:FindFirstChild("Animations")) then
		for _, Animation: Animation in Tool.Animations:GetChildren() do
			if not (Animation:IsA("Animation")) then continue end
			
			local Name: string = `Tool{Animation.Name}`

			if (self:LoadAnimation(Name, Animation, true)) then
				table.insert(ToolAnimations, Name)
			end
		end
	end

	local Weld: Motor6D = Instance.new("Motor6D")
	Weld.Part0 = self.RightArm
	Weld.Part1 = Handle

	Weld.C0 = self.RightGrip.CFrame
	Weld.C1 = Tool.Grip

	Weld.Parent = Handle

	local Module: ModuleScript = Tool:FindFirstChild("ViewmodelTool")
	if (Module) then
		pcall(function()
			local Unequip: () -> nil = require(Module)(self, self.ToolJanitor)
			Tool.Destroying:Connect(function()
				for _, Name: string in ToolAnimations do
					self:UnloadAnimation(Name)
				end

				self.ToolJanitor:Cleanup()

				if (type(Unequip) == "function") then
					Unequip()
				end
			end)
		end)
	end

	self.ToolWeld = Weld
	self.EquippedTool = Tool

	task.delay(.05,function() -- Fix tool blinking
		RunService.Heartbeat:Wait()

		if (self:GetTool() ~= Tool) then return end

		pcall(function()
			Tool.Parent = self.Instance
		end)
	end)

	return true
end

function VM:UnequipTool(DontDestroy: boolean?): Tool?
	if not (self.EquippedTool) then return end

	self.ToolConfig = {}

	self.ToolJanitor:Cleanup()
	
	self.EquippedTool.Parent = nil
	if not (DontDestroy) then
		self.EquippedTool:Destroy()
	end
	self.EquippedTool = nil

	self:StopAnimations()
	self:PlayCoreAnimation(self.PlayingCoreAnimation,0)
end

function VM:GetTool(): Tool?
	return self.EquippedTool
end

function VM:LoadAnimationSound(Sound: Sound)
	self.Sounds[Sound.Name] = Sound:Clone()
end

function VM:PlaySound(Name: string)
	local Sound: Sound = self.Sounds[Name]
	if not (Sound) then return end

	Sound = Sound:Clone()
	Sound.PlayOnRemove = true
	Sound.Parent = SoundService
	Sound:Destroy()
end

function VM:Hide()
	self.Hidden = true
end

function VM:Show()
	self.Hidden = false
end

return VM