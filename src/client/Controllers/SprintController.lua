local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Shared = ReplicatedStorage.Shared
local Packages = ReplicatedStorage.Packages

local GameSettings = require(Shared.GameSettings)
local Knit = require(Packages.Knit)
local TableUtil = require(Packages.TableUtil)
local Timer = require(Packages.Timer)
local Signal = require(Packages.Signal)

local Keyboard = require(Packages.Input).Keyboard

local ScreenGui = Players.LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("Game")
local EnergyIndicator = ScreenGui:WaitForChild("EnergyIndicator")
local Bar = EnergyIndicator:WaitForChild("Bar")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

local EnergyAmount, Sprinting = 100, false
local GameLoop

local SprintController = Knit.CreateController({
	Name = "SprintController",
})

function SprintController:OnChecking()
	local Humanoid = Character.Humanoid

	if EnergyAmount > 0 then
		if Sprinting then
			if Humanoid.MoveDirection.Magnitude > 0 then
				Humanoid.WalkSpeed = GameSettings.SprintSpeed
				EnergyAmount = math.clamp(EnergyAmount - GameSettings.EnergyDecrease, 0, 100)
			end
		else
			if Humanoid.WalkSpeed ~= GameSettings.GrannyWalkSpeed then
				Humanoid.WalkSpeed = GameSettings.GrannyWalkSpeed
			end
		end
	else
		Humanoid.WalkSpeed = GameSettings.GrannyWalkSpeed
		Sprinting = false
	end

	if EnergyAmount < 100 then
		if not Sprinting then
			EnergyAmount = math.clamp(EnergyAmount + GameSettings.EnergyIncrease, 0, 100)
		end

		local Formula = EnergyAmount / 100
		Bar:TweenSize(UDim2.new(Formula, 0, 1, 0), "Out", "Linear", 0.1, true)
	end
end

function SprintController:GameStart()
	local keyboard = Keyboard.new()
	EnergyIndicator.Visible = true

	Timer.Simple(0.1, function()
		self:OnChecking()
	end)

	keyboard.KeyDown:Connect(function(key: KeyCode)
		if key == Enum.KeyCode.LeftShift then
			Sprinting = true
		end
	end)

	keyboard.KeyUp:Connect(function(key: KeyCode)
		if key == Enum.KeyCode.LeftShift then
			Sprinting = false
		end
	end)

	-- TODO: Console and mobile support
end

function SprintController:KnitStart()
	if GameLoop == nil then
		GameLoop = Knit.GetService("GameLoop")
	end

	GameLoop.GameStart:Connect(function(Role)
		if Role == "Baby" then
			return
		end

		self:GameStart()
	end)
end

return SprintController
