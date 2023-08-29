local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

local Shared = ReplicatedStorage.Shared
local Packages = ReplicatedStorage.Packages

local GameSettings = require(Shared.GameSettings)
local Knit = require(Packages.Knit)
local TableUtil = require(Packages.TableUtil)
local CutsceneService = require(ReplicatedStorage.CutsceneService)
local viewportfitter = require(Packages.viewportfitter)

local ScreenGui = Players.LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("RoleChoosing")
local Baby, Granny = ScreenGui:WaitForChild("Baby"), ScreenGui:WaitForChild("Granny")
local LeaveTeam = ScreenGui:WaitForChild("LeaveTeam")
local Ready = ScreenGui:WaitForChild("Ready")

local CutsceneFolder = Workspace.Map.Cutscene
local CutscenePlaying = true
local cutsceneTween

local Debounce = false
local RoleChoosing, DataService

local RoleChoosingClient = Knit.CreateController({
	Name = "RoleChoosingClient",
	cutsceneTween = nil,
})

function RoleChoosingClient:ChangeLeaveTeamAndReady(enable)
	LeaveTeam.Visible = enable
	Ready.Visible = enable
end

function RoleChoosingClient:RoleUpdating(player, role)
	ScreenGui:WaitForChild(role).TextLabel.Text = player.Name

	ScreenGui[role].TextButton.Visible = false

	self:CreateViewport(role)

	if player == LocalPlayer then
		self:ChangeLeaveTeamAndReady(true)
	end
end

function RoleChoosingClient:RemoveRoleEvent(player, role)
	ScreenGui:WaitForChild(role).TextLabel.Text = "Waiting for player..."
	ScreenGui[role].TextButton.Visible = true
	ScreenGui[role].ViewportFrame:ClearAllChildren()
	ScreenGui[role].UIStroke.Color = Color3.fromRGB(255, 47, 47)
	ScreenGui:WaitForChild("TextLabel").Visible = false

	if player == LocalPlayer then
		self:ChangeLeaveTeamAndReady(false)
		Ready.TextButton.Text = "Ready"
	end
end

function RoleChoosingClient:Ready(Roles, RolesCount, ReadyPlayer)
	if RolesCount == GameSettings.MaxPlayers then
		print("Game is ready to start")
		self:ChangeLeaveTeamAndReady(false)
		ScreenGui:WaitForChild("TextLabel").Visible = false

		ScreenGui.Enabled = false
		if self.cutsceneTween.PlaybackState == Enum.PlaybackState.Playing then
			CutscenePlaying = false
			self.cutsceneTween:Cancel()
		end
	end
	for Role, Player in Roles do
		local otherPlayer

		for _, OtherPlayer in Players:GetPlayers() do
			if OtherPlayer ~= LocalPlayer then
				otherPlayer = OtherPlayer
			end
		end

		if ReadyPlayer == Player then
			ScreenGui:WaitForChild(Role).UIStroke.Color = Color3.fromRGB(0, 255, 72)
		end

		if ReadyPlayer == LocalPlayer and Player == LocalPlayer then
			LeaveTeam.Visible = false
			Ready.TextButton.Text = "Unready"

			ScreenGui:WaitForChild("TextLabel").Visible = true
			ScreenGui:WaitForChild("TextLabel").Text = "Waiting for " .. otherPlayer.Name .. " To get ready."
		else
			ScreenGui:WaitForChild("TextLabel").Visible = true
			ScreenGui:WaitForChild("TextLabel").Text = "Waiting for You get ready."
		end
	end
end

function RoleChoosingClient:CreateViewport(Role)
	local Worked, PlayerData = DataService:GetData():await()

	local Skin = PlayerData.EquippedSkins[Role]
	local Model = ReplicatedStorage.Assets.Skins[Role][Skin]:Clone()
	local ViewportFrame = ScreenGui:WaitForChild(Role).ViewportFrame
	local Connection

	local camera = Instance.new("Camera")
	camera.FieldOfView = 70
	camera.Parent = ViewportFrame

	Model.Parent = ViewportFrame
	ViewportFrame.CurrentCamera = camera

	local vpfModel = viewportfitter.new(ViewportFrame, camera)

	local cf, size = Model:GetBoundingBox()

	vpfModel:SetModel(Model)

	local theta = 0
	local orientation = CFrame.new()
	local distance = vpfModel:GetFitDistance(cf.Position)

	Connection = game:GetService("RunService").RenderStepped:Connect(function(dt)
		if not Model then
			Connection:Disconnect()
			return
		end

		theta = theta + math.rad(20 * dt)
		orientation = CFrame.fromEulerAnglesYXZ(math.rad(-20), theta, 0)
		camera.CFrame = CFrame.new(cf.Position) * orientation * CFrame.new(0, 0, distance)
	end)
end

function RoleChoosingClient:ClickedRoleButton(role)
	if Debounce == false then
		Debounce = true

		RoleChoosing.RoleSelectedEvent:Fire(role)
		task.delay(0.5, function()
			Debounce = false
		end)
	end
end

function RoleChoosingClient:KnitStart()
	if RoleChoosing == nil then
		DataService = Knit.GetService("DataService")
		RoleChoosing = Knit.GetService("RoleChoosing")
	end
	ScreenGui.Enabled = true

	local Points = {
		CutsceneFolder:WaitForChild("P1").CFrame,
		CutsceneFolder:WaitForChild("P3").CFrame,
		CutsceneFolder:WaitForChild("P4").CFrame,
		CutsceneFolder:WaitForChild("P5").CFrame,
		CutsceneFolder:WaitForChild("P6").CFrame,
		CutsceneFolder:WaitForChild("P7").CFrame,
		CutsceneFolder:WaitForChild("P8").CFrame,
		CutsceneFolder:WaitForChild("P1").CFrame,
	}

	self.cutsceneTween = CutsceneService:Create(Points, 50, "OutInBack")

	self.cutsceneTween.Completed:Connect(function()
		if CutscenePlaying == true then
			self.cutsceneTween:Play()
		end
	end)
	self.cutsceneTween:Play()

	Ready.TextButton.MouseButton1Click:Connect(function()
		if Ready.TextButton.Text == "Ready" then
			RoleChoosing.Ready:Fire(LocalPlayer)
		else
			LeaveTeam.Visible = false
			Ready.TextButton.Text = "Unready"
			RoleChoosing.UnReady:Fire(LocalPlayer)
		end
	end)

	LeaveTeam.TextButton.MouseButton1Click:Connect(function()
		RoleChoosing.RemoveRoleEvent:Fire(LocalPlayer)

		self:ChangeLeaveTeamAndReady(false)
	end)

	Baby.TextButton.MouseButton1Click:Connect(function()
		self.ClickedRoleButton("Baby", "Baby")
	end)

	Granny.TextButton.MouseButton1Click:Connect(function()
		self.ClickedRoleButton("Granny", "Granny")
	end)

	RoleChoosing.RoleSelectedEvent:Connect(function(...)
		self:RoleUpdating(...)
	end)

	RoleChoosing.RemoveRoleEvent:Connect(function(...)
		self:RemoveRoleEvent(...)
	end)

	RoleChoosing.Ready:Connect(function(...)
		self:Ready(...)
	end)
end

return RoleChoosingClient
