local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage.Shared
local Packages = ReplicatedStorage.Packages

local GameSettings = require(Shared.GameSettings)
local Knit = require(Packages.Knit)
local TableUtil = require(Packages.TableUtil)
local Timer = require(Packages.Timer)

local doorCircleSize = 13
local DoorOpenAngle = 100
local TimeForDoorToOpen = 0.7
local DoorEasingStyle = Enum.EasingStyle.Quad
local WaitTime = 0.1

local GameLoop

local DoorService = Knit.CreateService({
	Name = "DoorService",
	Client = {},
	doors = {},
})

function DoorService:Reset(door)
	door.Animating = true
	door.LastDesiredAngle = (door.DesiredAngle or 0) * door.TimeStamp
	door.TimeStamp = 0
end

function DoorService:Open(door, angle)
	door.Open = true

	self:Reset(door)

	door.DesiredAngle = math.rad(DoorOpenAngle) * -math.sign(angle)
end

function DoorService:Close(door)
	door.Open = false

	self:Reset(door)

	door.DesiredAngle = 0
end

function DoorService:Create(object)
	if self.doors[object] then
		return self.doors[object].Functions
	end

	local descendants = object:GetDescendants()

	local anchor

	for _, object in descendants do
		if object:IsA("Attachment") or object.Name == "Attachment" then
			anchor = object

			break
		end
	end

	if not anchor then
		return
	end
	local anchorPoint = anchor.WorldPosition
	local centerPoint = object:GetBoundingBox()
	local anchorOrientation = CFrame.new(Vector3.new(), centerPoint.RightVector)
	local anchorCFrame = CFrame.new(anchorPoint) * anchorOrientation

	anchor:Destroy()

	local cache = {}

	for _, object in pairs(descendants) do
		if object:IsA("BasePart") then
			cache[object] = anchorCFrame:Inverse() * object.CFrame
		end
	end

	--Function List
	local functions = {
		Disconnect = function()
			self.doors[object] = nil
		end,
	}

	--Add door to door list
	self.doors[object] = {
		Anchor = anchorCFrame,
		Center = centerPoint,
		Cache = cache,
		Functions = functions,
		TimeStamp = 0,
		LastDesiredAngle = 0,
	}

	return functions
end
local debounce = {}

function DoorService:UpdateDoor(Character, deltaTime)
	local characterCencter = Character.PrimaryPart.CFrame

	for _, door in self.doors do
		local doorCenter = door.Center
		local offset = doorCenter:Inverse() * characterCencter
		local inRadius = offset.p.magnitude <= doorCircleSize

		if inRadius and not door.Open and not debounce[door] then
			local angle = math.atan2(offset.z, offset.x)

			self:Open(door, angle)
			debounce[door] = Character
		elseif not inRadius and door.Open and debounce[door] == Character then
			self:Close(door)
			debounce[door] = nil
		end

		--Door Animating
		if door.Animating then
			if door.TimeStamp > 1 then
				door.Animating = false

				for object, offset in pairs(door.Cache) do
					object.CFrame = door.Anchor * CFrame.fromOrientation(0, door.DesiredAngle, 0) * offset
				end

				if door.Open then
					if door.Functions.Open then
						door.Functions.Open()
					end
				else
					if door.Functions.Closed then
						door.Functions.Closed()
					end
				end
			else
				local adjustedTimeStamp =
					TweenService:GetValue(door.TimeStamp, DoorEasingStyle, Enum.EasingDirection.InOut)
				local orientation = CFrame.fromOrientation(
					0,
					door.LastDesiredAngle + (door.DesiredAngle - door.LastDesiredAngle) * adjustedTimeStamp,
					0
				)

				for object, offset in pairs(door.Cache) do
					object.CFrame = door.Anchor * orientation * offset
				end

				door.TimeStamp = door.TimeStamp + deltaTime / TimeForDoorToOpen
			end
		end
	end
end

function DoorService:KnitStart()
	if GameLoop == nil then
		GameLoop = Knit.GetService("GameLoop")
	end
	print("GameStart")
	RunService.Heartbeat:Connect(function(deltaTime)
		for _, Player in Players:GetPlayers() do
			local Character = Player.Character
			if Character and Character.PrimaryPart then
				self:UpdateDoor(Character, deltaTime)
			end
		end
	end)

	--[[Timer.Simple(WaitTime, function()
        
    end)-]]
end

return DoorService
