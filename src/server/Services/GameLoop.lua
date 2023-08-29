local MemoryStoreService = game:GetService("MemoryStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Packages = ReplicatedStorage.Packages

local GameSettings = require(Shared.GameSettings)
local Knit = require(Packages.Knit)
local TableUtil = require(Packages.TableUtil)
local TeleportModule = require(Packages.universe)
local Timer = require(Packages.Timer)

local Map = workspace.Map
local SpawnPositionsBaby, SpawnPositionsGranny = Map.SpawnPositionsBaby, Map.SpawnPositionsGranny
local timerValue = Map.Timer

local ThrowService, TaskService, ItemService, DataService

local GameLoop = Knit.CreateService({
	Name = "GameLoop",
	Client = {
		KickBaby = Knit.CreateSignal(),
		GameStart = Knit.CreateSignal(),
		AddKey = Knit.CreateSignal(),
		KnockBackGranny = Knit.CreateSignal(),
		GameFinished = Knit.CreateSignal(),
	},
	Roles = {},
})

function GameLoop:InstallValues(Player)
	local KeyValue = Instance.new("IntValue")
	KeyValue.Name = "Keys"
	KeyValue.Parent = Player

	local Energy = Instance.new("IntValue")
	Energy.Name = "Energy"
	Energy.Parent = Player
end

function GameLoop:KeyTriggered(Player, Key)
	if Player:DistanceFromCharacter(Key.Position) <= 10 then
		local KeyValue = Player:FindFirstChild("Keys")
		KeyValue.Value += 1

		Key:Destroy()
	end
end

function GameLoop:GameFinished(RoleWon)
	if self.Finished == true then
		return
	end

	self.Finished = true

	self.Client.GameFinished:FireAll(RoleWon)

	task.delay(GameSettings.TimeUntilSendToLobby, function()
		for _, Player in Players:GetPlayers() do
			if Player == self.Roles[RoleWon] then
				DataService:UpdateWins(Player)
			end
		end

		local teleportBuilder =
			TeleportModule.TeleportBuilder.new():setPlaceId(GameSettings.LobbyPlaceId):teleport(Players:GetPlayers())

		teleportBuilder
			:andThen(function()
				print("Teleport successful")
			end)
			:catch(function(err)
				print(err)
				--warn("Failed to teleport " .. self.PlayersInElevator .. " due to: " .. err)
			end)
	end)
end

function GameLoop:UpdateHealth(Player, Amount)
	print(Player, Amount)
	local HealthIntValue = Map.Health

	if Amount < 0 then
		HealthIntValue.Value -= math.clamp(Amount, 0, 100)
	else
		HealthIntValue.Value += math.clamp(Amount, 0, 100)
	end

	if HealthIntValue.Value == 0 then
		self:GameFinished("Baby")
	end
end

function GameLoop:InstallingBaby(Player)
	local character = Player.Character
	local Humanoid = character:FindFirstChild("Humanoid")
	local HumanoidRootPart = character:FindFirstChild("HumanoidRootPart")

	local EquippedSkins = DataService:GetEquippedSkins(Player)

	character:SetAttribute("Role", "Baby")
	HumanoidRootPart.CFrame = SpawnPositionsBaby[math.random(1, #SpawnPositionsBaby:GetChildren())].CFrame

	Humanoid:ApplyDescription(ReplicatedStorage.Assets.HumanoidDescriptions.Baby[EquippedSkins.Baby])
	character:ScaleTo(GameSettings.BabySize)

	Humanoid.WalkSpeed = GameSettings.BabyWalkSpeed
	Humanoid.JumpPower = GameSettings.BabyJumpPower

	self:InstallValues(Player)

	ItemService:GameStart(Player)
	ThrowService:GameStart(Player)
	self.Client.GameStart:Fire(Player, "Baby")
end

function GameLoop:InstallingGranny(Player)
	local character = Player.Character
	local Humanoid = character:FindFirstChild("Humanoid")
	local HumanoidRootPart = character:FindFirstChild("HumanoidRootPart")

	local EquippedSkins = DataService:GetEquippedSkins(Player)

	character:SetAttribute("Role", "Granny")
	HumanoidRootPart.CFrame = SpawnPositionsGranny[math.random(1, #SpawnPositionsGranny:GetChildren())].CFrame

	Humanoid:ApplyDescription(ReplicatedStorage.Assets.HumanoidDescriptions.Granny[EquippedSkins.Granny])

	character:ScaleTo(GameSettings.GrannySize)

	Humanoid.WalkSpeed = GameSettings.GrannyWalkSpeed
	Humanoid.JumpPower = GameSettings.GrannyJumpPower

	TaskService:GameStart(Player)
end

function GameLoop:StartGame(Roles)
	self.Roles = Roles
	print("123")
	for Role, Player in self.Roles do
		print(Role, Player)
		if Role == "Baby" then
			self:InstallingBaby(Player)
		elseif Role == "Granny" then
			self:InstallingGranny(Player)
		end
		self.Client.GameStart:Fire(Player, Role)
	end

	timerValue.Value = GameSettings.GameLength

	Timer.Simple(1, function()
		timerValue.Value -= 1

		if timerValue.Value == 0 then
			self:GameFinished("Granny")
		end
	end)
end

function GameLoop:KickBaby(Player, BabyPlayer)
	print("asdasdas")
	local HumanoidRootPart = BabyPlayer.Character:FindFirstChild("HumanoidRootPart")
	local lookVector = Player.Character.PrimaryPart.CFrame.LookVector
	local impulseStrength = 10000 -- adjust the strength as needed
	local impulse = lookVector * impulseStrength

	HumanoidRootPart:ApplyImpulse(impulse)
end

function GameLoop:KnitStart()
	if TaskService == nil then
		TaskService = Knit.GetService("TaskService")
		ThrowService = Knit.GetService("ThrowService")
		ItemService = Knit.GetService("ItemService")
		DataService = Knit.GetService("DataService")
	end

	self.Client.KickBaby:Connect(function(player, lookVector)
		print(player, lookVector)
		self.Client.KickBaby:Fire(self.Roles["Baby"], lookVector)
	end)

	self.Client.AddKey:Connect(function(...)
		self:KeyTriggered(...)
	end)

	Players.PlayerRemoving:Connect(function(player)
		if self.Finished == true then
			return
		end

		if self.Roles["Granny"] == player then
			if Map.Health.Value <= 70 then
				self:GameFinished("Baby")
			else
				self:GameFinished(nil)
			end
		elseif self.Roles["Baby"] == player then
			if Map.Timer.Value <= GameSettings.GameLength * 0.3 then
				self:GameFinished("Granny")
			else
				self:GameFinished(nil)
			end
		end
	end)
end

return GameLoop
