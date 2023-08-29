local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Shared = ReplicatedStorage.Shared
local Packages = ReplicatedStorage.Packages

local GameSettings = require(Shared.GameSettings)
local Knit = require(Packages.Knit)
local NumbersModule = require(Shared.Utils.Numbers)

local ScreenGui = Players.LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("Game")
local Victory = ScreenGui:WaitForChild("Victory")
local WinText = Victory:WaitForChild("WinText")

local TimerIndicator = ScreenGui:WaitForChild("TimerIndicator")

local map = workspace.Map
local timerValue = map.Timer

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

local GameLoop

local UIController = Knit.CreateController({
	Name = "UIController",
})

function TimerValueChanged(value)
	TimerIndicator.TextLabel.Text = NumbersModule:FormatForTimer(value)
end

function UIController:GameStart()
	GameLoop.GameFinished:Connect(function(RoleWon)
		if RoleWon == "Granny" then
			WinText.Text = "Granny survived the baby, Granny wins!"
		elseif RoleWon == "Baby" then
			WinText.Text = "Granny has passed away, Baby wins!"
		else
			WinText.Text = "Other player left, Game ended in a draw!"
		end

		Victory.Visible = true
	end)

	TimerIndicator.Visible = true

	timerValue.Changed:Connect(TimerValueChanged)
end

function UIController:KnitStart()
	if GameLoop == nil then
		GameLoop = Knit.GetService("GameLoop")
	end

	GameLoop.GameStart:Connect(function(Role)
		self:GameStart()
	end)
end

return UIController
