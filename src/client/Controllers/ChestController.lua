local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage.Shared
local Packages = ReplicatedStorage.Packages

local GameSettings = require(Shared.GameSettings)
local Knit = require(Packages.Knit)
local TableUtil = require(Packages.TableUtil)
local Timer = require(Packages.Timer)
local Signal = require(Packages.Signal)

local Map = workspace.Map
local Chests = Map.Chests

local ProximityPrompt = ReplicatedStorage.Assets.ProximityPrompt

local ScreenGui = Players.LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("Game")
local ItemButton = ScreenGui:WaitForChild("ItemButton")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

local TweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local ItemService, GameLoop

local ChestController = Knit.CreateController({
	Name = "ChestController",
})

function ChestController:CheckKeys(KeysRequired)
	local KeyValue = LocalPlayer.Keys.Value

	if KeyValue >= KeysRequired then
		return true
	end
end

function ChestController:OpenLid(Chest)
	local Hinge = Chest.Hinge
	local tweenCFrame = Hinge.CFrame * CFrame.Angles(math.rad(110), 0, 0)

	local tween = TweenService:Create(Hinge, TweenInfo, { CFrame = tweenCFrame })
	tween:Play()
end

function ChestController:Triggered(Chest, KeysRequired)
	if self:CheckKeys(KeysRequired) == true and ItemButton.Visible == false then
		ItemService.ChestOpened:Fire(Chest)
		self:OpenLid(Chest)

		Chest.PrimaryPart.ProximityPrompt:Destroy()
	end
end

function ChestController:InstallChests()
	for _, Chest in Chests:GetChildren() do
		print(Chest)
		local ProximityPromptClone = ProximityPrompt:Clone()
		ProximityPromptClone.Parent = Chest.PrimaryPart

		local KeysRequired = Chest:GetAttribute("KeysRequired")

		ProximityPromptClone.Triggered:Connect(function()
			self:Triggered(Chest, KeysRequired)
		end)
	end
end

function ChestController:GameStart()
	self:InstallChests()
end

function ChestController:KnitStart()
	if ItemService == nil and GameLoop == nil then
		ItemService = Knit.GetService("ItemService")
		GameLoop = Knit.GetService("GameLoop")
	end
	print("asdasd")
	GameLoop.GameStart:Connect(function(Role)
		print(Role)
		if Role == "Granny" then
			return
		end

		self:GameStart()
	end)
end

return ChestController
