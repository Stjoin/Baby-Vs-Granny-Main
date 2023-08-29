local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local LocalPlayer = game.Players.LocalPlayer

local Assets = ReplicatedStorage.Assets
local Shared = ReplicatedStorage.Shared
local Packages = ReplicatedStorage.Packages

local ProximityPrompt = ReplicatedStorage.Assets.ProximityPromptHold
local assetsForTask = Assets.Tasks.CleanRoom

local Knit = require(Packages.Knit)

local Map = workspace.Map

local CleanRoom = {
	TaskName = "CleanRoom",

	TaskDescription = "Clean The Dining Tables By Cleaning Up Dirt And Used Dishes.",
	Amount = 6,
	RewardPerItem = 30,
	PillsTask = false,
	CurrentAmount = 6,

	TriggeredConnection = nil,
}

local TaskService

function CleanRoom:Triggered(CleanAble)
	TaskService.Triggered:Fire(CleanAble)
end

function CleanRoom:InstallItemsClient()
	task.wait(0.5)

	for _, CleanAble in Map["CleanRoom"]:GetChildren() do
		print(CleanAble)
		if CleanAble:IsA("BasePart") then
			local ProximityPromptClone = ProximityPrompt:Clone()
			ProximityPromptClone.Parent = CleanAble

			ProximityPromptClone.Triggered:Connect(function()
				CleanRoom:Triggered(CleanAble)
			end)
		end
	end
end

function CleanRoom:InstallItemsServer()
	local ClonesAssetsForTask = assetsForTask:Clone()
	ClonesAssetsForTask.Parent = Map

	self.TriggeredConnection = TaskService.Client.Triggered:Connect(function(Player, CleanAble)
		TaskService:Reward(Player, self.RewardPerItem / self.Amount)

		CleanAble:Destroy()
		self.CurrentAmount -= 1

		TaskService.Client.PartOfTaskCompleted:Fire(Player, self.CurrentAmount)

		if self.CurrentAmount == 0 then
			self.TriggeredConnection:Disconnect()

			ClonesAssetsForTask:Destroy()
			TaskService:TaskFinished(self.PillsTask)

			self.CurrentAmount = self.Amount
		end
	end)
end

function CleanRoom:gameStart()
	local IsServer = RunService:IsServer()

	if TaskService == nil then
		TaskService = Knit.GetService("TaskService")
	end

	if IsServer then
		CleanRoom:InstallItemsServer()
	else
		print("Yes")
		CleanRoom:InstallItemsClient()
	end
end

return CleanRoom
