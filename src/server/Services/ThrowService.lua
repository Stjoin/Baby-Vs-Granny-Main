local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local Shared = ReplicatedStorage.Shared
local Packages = ReplicatedStorage.Packages

local GameSettings = require(Shared.GameSettings)
local Knit = require(Packages.Knit)
local TableUtil = require(Packages.TableUtil)
local Bezier = require(ReplicatedStorage.Bezier)

local Particles = ReplicatedStorage.Assets.Particles
local ItemThrow = Particles.ItemThrow

local GameLoop

local ThrowService = Knit.CreateService({
	Name = "ThrowService",
	Client = {
		Released = Knit.CreateSignal(),
		Equipped = Knit.CreateSignal(),
	},
})

function ThrowService:GetOtherPlayer()
	for _, Player in Players:GetPlayers() do
		if Player ~= self.Player then
			return Player
		end
	end
end

-- Throw an item at another player
function ThrowService:Throw(player, controlPoints, value)
	if self.Player ~= player then
		return
	end

	print(controlPoints, value)
	local newBezier = Bezier.new(controlPoints.P1, controlPoints.P2, controlPoints.P3)
	local tweenInfo = TweenInfo.new((1 - value) / 2 + 0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)

	local localItem = self.Item
	local handle

	localItem.Parent = workspace.Map
	localItem.Handle.Name = "Part"
	handle = localItem.Part

	handle.Anchored = true

	local tween = newBezier:CreateVector3Tween(handle, { "Position" }, tweenInfo)
	tween:Play()

	local angularVelocity = Instance.new("AngularVelocity")
	local att0 = Instance.new("Attachment")

	angularVelocity.Attachment0 = att0
	angularVelocity.AngularVelocity = Vector3.new(1, 1, 1) * 5
	angularVelocity.MaxTorque = math.huge
	angularVelocity.RelativeTo = Enum.ActuatorRelativeTo.Attachment0

	angularVelocity.Parent = handle
	att0.Parent = handle

	tween.Completed:Connect(function()
		local otherPlayer = self:GetOtherPlayer()
		if otherPlayer then
			local otherHumanoidRootPart = otherPlayer.Character.HumanoidRootPart

			local distance = (otherHumanoidRootPart.Position - handle.Position).Magnitude

			if distance <= 5 then
				GameLoop:UpdateHealth(otherPlayer, GameSettings.ItemSetting[localItem.Name].Damage * -1)
				local lookVector = player.Character.HumanoidRootPart.CFrame.LookVector
				print(GameSettings.ItemSetting[localItem.Name].knockBackDiveder)
				GameLoop.Client.KnockBackGranny:Fire(
					otherPlayer,
					lookVector,
					GameSettings.ItemSetting[localItem.Name].knockBackDiveder
				)
			end
		end

		local Particle1, Particle2 = ItemThrow.Particle1:Clone(), ItemThrow.Particle2:Clone()
		Particle1.Parent, Particle2.Parent = handle, handle

		Particle1.Particle:Emit(1)
		handle.Anchored = false
		task.wait(0.5)
		localItem:Destroy()
		self.Item = nil
	end)
end

function ThrowService:AddItem(Item: string)
	local Character = self.Player.Character
	local newItem = ReplicatedStorage.Assets.Items:FindFirstChild(Item):Clone()

	self.Item = newItem
	self.Item.Parent = Character
	self.Item.Handle.Anchored = false

	--Character.Humanoid.EquipTool(newItem)

	newItem.Equipped:Connect(function()
		self.Client.Equipped:Fire(self.Player, newItem)
	end)
end

function ThrowService:GameStart(Player)
	-- Player == Baby
	if GameLoop == nil then
		GameLoop = Knit.GetService("GameLoop")
	end

	self.Player = Player

	self.Client.Released:Connect(function(...)
		print("1")
		self:Throw(...)
	end)
end

function ThrowService:KnitStart() end

return ThrowService
