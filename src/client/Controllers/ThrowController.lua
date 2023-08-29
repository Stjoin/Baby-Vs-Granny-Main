local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage.Shared
local Packages = ReplicatedStorage.Packages

local GameSettings = require(Shared.GameSettings)
local Knit = require(Packages.Knit)
local TableUtil = require(Packages.TableUtil)
local Timer = require(Packages.Timer)
local Input = require(Packages.Input)
local Bezier = require(ReplicatedStorage.Bezier)

local MouseModule = require(Packages.Input).Mouse
local TouchModule = require(Packages.Input).Touch

local ScreenGui = Players.LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("Game")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

local BezierFolder = workspace.Map.Bezier

local mouse = MouseModule.new()

local Mouse = LocalPlayer:GetMouse()
Mouse.TargetFilter = BezierFolder

local TweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)

local PointsAmount = 10
local Points, Lines = {}, {}
local P1, P2, P3
local NewBezier, Item

local LeftDown, LeftUp

local GameLoop, ThrowService

local ThrowController = Knit.CreateController({
	Name = "ThrowController",
	Value = 0,
})

local function CreatePart(Name, Size, Transparency)
	local Part = Instance.new("Part")
	Part.Size = Size or Vector3.new(0.1, 0.1, 0.1)
	Part.CanCollide = false
	Part.Anchored = true
	Part.Name = Name or "Part"
	Part.Transparency = Transparency or 1
	Part.Parent = BezierFolder

	return Part
end

local function UpdatePoints(item)
	local ItemPosition = item.Handle.Position

	if Mouse.Target then
		local centerX = ItemPosition.X
		local centerY = ItemPosition.Z
		local maxRadius = GameSettings.ItemSetting[item.Name].maxRadius

		-- X and Z position
		local x, y, z = Mouse.Hit.X, Mouse.Hit.Y, Mouse.Hit.Z

		local dx = x - centerX
		local dz = z - centerY
		local angle = math.atan2(dz, dx)

		local distance = math.sqrt(dx * dx + dz * dz)
		local clampedRadius = math.min(distance, maxRadius) -- Keep the radius within the maximum

		local clampedX = centerX + clampedRadius * math.cos(angle)
		local clampedZ = centerY + clampedRadius * math.sin(angle)

		local clampedEndPosition = Vector3.new(clampedX, y, clampedZ)

		-- Y position
		local yInterpolationFactor = 1 - (distance / maxRadius) -- Smaller Y as distance increases
		local minYOffset = 4
		local maxYOffset = 7
		local interpolatedY = minYOffset + (maxYOffset - minYOffset) * yInterpolationFactor

		local midpoint = ItemPosition:Lerp(clampedEndPosition, 0.5) + Vector3.new(0, interpolatedY, 0)

		P2.Position = midpoint
		P3.Position = clampedEndPosition
	end

	P1.Position = ItemPosition

	for i = 1, #Points do
		local t = (i - 1) / (#Points - 1)
		local position = NewBezier:CalculatePositionAt(t)
		local derivative = NewBezier:CalculateDerivativeAt(t)
		Points[i].CFrame = CFrame.new(position, position + derivative)
	end

	for i = 1, #Lines do
		local line = Lines[i]
		local p1, p2 = Points[i].Position, Points[i + 1].Position
		line.Size = Vector3.new(line.Size.X, line.Size.Y, (p2 - p1).Magnitude)
		line.CFrame = CFrame.new(0.5 * (p1 + p2), p2)
	end
end

function ThrowController:Release(Value)
	--local Animation = Character.Humanoid:LoadAnimation(ReplicatedStorage.Assets.Animations.Throw2)
	local ControlPoints = {
		P1 = P1.Position,
		P2 = P2.Position,
		P3 = P3.Position,
	}
	Points, Lines = {}, {}

	--Animation:Play()

	TweenService:Create(workspace.CurrentCamera, TweenInfo, { FieldOfView = 70 }):Play()
	print("Throwing")
	ThrowService.Released:Fire(ControlPoints, Value)

	BezierFolder:ClearAllChildren()
end

function ThrowController:CreateFakeBezier(item)
	local RenderSteppedConnection, LeftDownConnection
	local Value = 0

	P1 = CreatePart("P1")
	P2 = CreatePart("P2")
	P3 = CreatePart("P3")

	NewBezier = Bezier.new(P1, P2, P3)

	for i = 1, PointsAmount do
		local part = CreatePart()
		table.insert(Points, part)
	end

	for i = 1, PointsAmount - 1 do
		local part = CreatePart(nil, Vector3.new(0.3, 0.3, 1), 0)
		part.Material = Enum.Material.ForceField
		part.BrickColor = BrickColor.new("New Yeller")
		table.insert(Lines, part)
	end

	RenderSteppedConnection = RunService.RenderStepped:Connect(function()
		UpdatePoints(item)
	end)

	LeftDownConnection = mouse.LeftDown:Connect(function()
		local Animation = Character.Humanoid:LoadAnimation(ReplicatedStorage.Assets.Animations.Throw1)

		Animation:Play()

		task.delay(0.95, function()
			if mouse:IsLeftDown() then
				Animation:AdjustSpeed(0)
			end
		end)

		while true do
			if mouse:IsLeftDown() then
				if Value < 1 then
					Value = math.clamp(Value + 0.01, 0, 1)
					workspace.CurrentCamera.FieldOfView = 70 + Value * 20
				end
			else
				LeftDownConnection:Disconnect()
				RenderSteppedConnection:Disconnect()

				Animation:Stop()

				self:Release(Value)
				break
			end
			task.wait(0.01)
		end
	end)
end

function ThrowController:GameStart()
	ThrowService.Equipped:Connect(function(item)
		self.Item = item
		self:CreateFakeBezier(item)
	end)
end

function ThrowController:KnitStart()
	if GameLoop == nil and ThrowService == nil then
		ThrowService = Knit.GetService("ThrowService")
		GameLoop = Knit.GetService("GameLoop")
	end

	GameLoop.GameStart:Connect(function(Role)
		if Role == "Granny" then
			return
		end

		self:GameStart()
	end)
end

return ThrowController
