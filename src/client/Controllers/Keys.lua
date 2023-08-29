local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Shared = ReplicatedStorage.Shared
local Packages = ReplicatedStorage.Packages

local GameSettings = require(Shared.GameSettings)
local Knit = require(Packages.Knit)
local TableUtil = require(Packages.TableUtil)
local Timer = require(Packages.Timer)
local Signal = require(Packages.Signal)

local Map = workspace.Map
local Keys = Map.Keys

local ProximityPrompt = ReplicatedStorage.Assets.ProximityPrompt

local ScreenGui = Players.LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("Game")
local KeysIndicator = ScreenGui:WaitForChild("KeysIndicator")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

local GameLoop

local KeysController = Knit.CreateController({
	Name = "KeysController",
})

function KeysController:Triggered(key)
	GameLoop.AddKey:Fire(key)
end

function KeysController:InstallKeys()
	task.wait(2)
	for _, key in Keys:GetChildren() do
		if Random.new():NextInteger(1, GameSettings.RandomChangeOfSpanningKeys) == 1 then
			key.Transparency = 0.1

			local ProximityPromptClone = ProximityPrompt:Clone()
			ProximityPromptClone.Parent = key

			ProximityPromptClone.Triggered:Connect(function()
				self:Triggered(key)
			end)
		end
	end
end

function KeysController:KeysUpdated(value)
	if value == 1 then
		KeysIndicator.TextLabel.Text = value .. " Key"
	else
		KeysIndicator.TextLabel.Text = value .. " Keys"
	end
end

function KeysController:GameStart()
	KeysIndicator.Visible = true

	LocalPlayer.Keys.Changed:Connect(function(value)
		self:KeysUpdated(value)
	end)

	self:InstallKeys()
end

function KeysController:KnitStart()
	if GameLoop == nil then
		GameLoop = Knit.GetService("GameLoop")
	end

	GameLoop.GameStart:Connect(function(Role)
		if Role == "Granny" then
			return
		end

		self:GameStart()
	end)
end

return KeysController
