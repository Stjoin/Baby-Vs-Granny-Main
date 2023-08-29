local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

local Shared = ReplicatedStorage.Shared
local Packages = ReplicatedStorage.Packages

local GameSettings = require(Shared.GameSettings)
local Knit = require(Packages.Knit)
local TableUtil = require(Packages.TableUtil)
local Timer = require(Packages.Timer)

local ScreenGui = Players.LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("Game")
local Kick = ScreenGui:WaitForChild("Kick")
local KickButton = Kick:WaitForChild("Button")

local GameLoop

local Debounce, ClickDebounce = false, false

local KickGuiVisible = false

local GrannyKickMechanic = Knit.CreateController({
	Name = "GrannyKickMechanic",
	BabyPlayer = nil,
})

function GrannyKickMechanic:SetUI() end

function GrannyKickMechanic:CheckDistance()
	if self.BabyPlayer == nil then
		return
	end

	local HumanoidRootPart = Character.HumanoidRootPart
	local HumanoidRootPartBaby = self.BabyPlayer.Character.HumanoidRootPart

	local distance = (Character.RightFoot.Position - HumanoidRootPartBaby.Position).Magnitude
	if distance <= 10 then
		local dirToOtherPlayer = (HumanoidRootPartBaby.Position - HumanoidRootPart.Position).Unit
		local lookVector = HumanoidRootPart.CFrame.LookVector
		if lookVector:Dot(dirToOtherPlayer) > 0.65 then
			Debounce = true

			if Kick.Visible == false then
				Kick.Visible = true
			end
		else
			if Kick.Visible == true then
				Kick.Visible = false
			end
		end
	else
		if Kick.Visible == true then
			Kick.Visible = false
		end
	end
end

function GrannyKickMechanic:GameStart()
	for _, player in Players:GetPlayers() do
		if player ~= LocalPlayer then
			self.BabyPlayer = player
		end
	end

	Timer.Simple(0.3, function()
		self:CheckDistance()
	end)

	KickButton.MouseButton1Click:Connect(function()
		if ClickDebounce == false then
			ClickDebounce = true

			local HumanoidRootPart = Character.HumanoidRootPart
			local lookVector = HumanoidRootPart.CFrame.LookVector

			GameLoop.KickBaby:Fire(lookVector)

			Kick.Visible = false

			task.delay(0.5, function()
				ClickDebounce = false
			end)
		end
	end)
end

function GrannyKickMechanic:KnitStart()
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

return GrannyKickMechanic
