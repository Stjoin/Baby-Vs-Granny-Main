local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local LocalPlayer = game.Players.LocalPlayer

local Assets = ReplicatedStorage.Assets
local Shared = ReplicatedStorage.Shared
local Packages = ReplicatedStorage.Packages

local ProximityPrompt = ReplicatedStorage.Assets.ProximityPromptHold

local Knit = require(Packages.Knit)

local Map = workspace.Map

local Pills = {
	TaskDescription = "Clean The Dining Tables By Cleaning Up Dirt And Used Dishes.",

	Amount = 1,
	PillsTask = true,
	CurrentAmount = 1,

	TriggeredConnection = nil,

	PillTasks = {
		["Memory_Pill"] = {
			TaskName = "Memory_Pill",
			TaskDescription = "You forgot your tasks, find the Memory pill to remember your tasks. There is a hint at the highlighted location on the map",
			Reward = 40,
		},
	},
}

local TaskService

function Pills:GetRandomTask()
	local Tasks = {}

	for TaskName, _ in pairs(self.PillTasks) do
		table.insert(Tasks, TaskName)
	end

	return Tasks[Random.new():NextInteger(1, #Tasks)]
end

function Pills:GetRandomPillAsset()
	local Pills = {}

	for _, Pill in pairs(Assets.Pills:GetChildren()) do
		table.insert(Pills, Pill)
	end

	return Pills[Random.new():NextInteger(1, #Pills)]
end

function Pills:Triggered(CleanAble)
	TaskService.Triggered:Fire(CleanAble)
end

function Pills:InstallItemsClient()
	local ProximityPromptClone = ProximityPrompt:Clone()
	print(Map:GetChildren(), Map.Pill, Map.Pill:FindFirstAncestor("Pill"))
	ProximityPromptClone.Parent = Map.Pill:FindFirstChildWhichIsA("Folder").Pill

	ProximityPromptClone.Triggered:Connect(function()
		Pills:Triggered()
	end)
end

function Pills:GiveEffect(Task)
	if Task.TaskName == "Memory_Pill" then
		print("Memory_Pill")
	end
end

function Pills:InstallItemsServer(Player)
	local TaskName = self:GetRandomTask()
	local Task = self.PillTasks[TaskName]
	local RandomPillAsset = self:GetRandomPillAsset():Clone()

	self.TaskFolder = Instance.new("Folder")
	self.TaskFolder.Name = "Pill"
	self.TaskFolder.Parent = Map

	RandomPillAsset.Parent = self.TaskFolder
	print(Task, Task.TaskDescription)
	TaskService.Client.NewTask:Fire(Player, "Pills", Task.TaskDescription)

	self.TriggeredConnection = TaskService.Client.Triggered:Connect(function(Player)
		self.TriggeredConnection:Disconnect()

		TaskService:Reward(Player, Task.Reward)
		TaskService.Client.PartOfTaskCompleted:Fire(Player, 0)
		TaskService:TaskFinished(self.PillsTask)

		self:GiveEffect(Task)

		self.Task = nil
		self.TaskFolder:Destroy()
	end)
end

function Pills:gameStart(Player)
	local IsServer = RunService:IsServer()

	if TaskService == nil then
		TaskService = Knit.GetService("TaskService")
	end

	if IsServer then
		self:InstallItemsServer(Player)
	else
		self:InstallItemsClient()
	end
end

return Pills
