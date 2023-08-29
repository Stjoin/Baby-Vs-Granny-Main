local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage.Shared
local Packages = ReplicatedStorage.Packages

local GameSettings = require(Shared.GameSettings)
local Knit = require(Packages.Knit)
local TableUtil = require(Packages.TableUtil)
local Timer = require(Packages.Timer)
local Signal = require(Packages.Signal)

local Map = workspace.Map

local ScreenGui = Players.LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("Game")
local HealthIndicator = ScreenGui:WaitForChild("HealthIndicator")
local Bar = HealthIndicator:WaitForChild("Bar")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

local GameLoop

local HealthController = Knit.CreateController({
	Name = "HealthController",
})

function HealthController:TweenGui(HealthAmount)
	local Formula = HealthAmount / 100
	Bar:TweenSize(UDim2.new(Formula, 0, 1, 0), "Out", "Linear", 0.1, true)
	HealthIndicator.HealthTextLabel.Text = HealthAmount .. "/100"
end

function HealthController:GameStart()
	HealthIndicator.Visible = true

	Map.Health.Changed:Connect(function(value)
		self:TweenGui(value)
	end)
	self:TweenGui(100)
end

function HealthController:KnitStart()
	if GameLoop == nil then
		GameLoop = Knit.GetService("GameLoop")
	end

	GameLoop.GameStart:Connect(function()
		self:GameStart()
	end)
end

return HealthController
