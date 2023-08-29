local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Packages = ReplicatedStorage.Packages

local GameSettings = require(Shared.GameSettings)
local Knit = require(Packages.Knit)
local TableUtil = require(Packages.TableUtil)
local Tasks = require(Shared.Tasks)

local GameLoop

local TaskService = Knit.CreateService({
	Name = "TaskService",
	Client = {
		NewTask = Knit.CreateSignal(),
		PartOfTaskCompleted = Knit.CreateSignal(),
		Triggered = Knit.CreateSignal(),
	},
	CurrentTask = nil,
	Player = nil,
})

function TaskService:Reward(Player, Amount)
	GameLoop:UpdateHealth(Player, Amount)
end

function TaskService:TaskFinished(PillsTask)
	print(PillsTask)
	if PillsTask == true then
		self:getNewTask(false)
	else
		local NewTask = Tasks["Pills"]
		NewTask:gameStart(self.Player)
	end
end

function TaskService:getNewTask(PillsTask)
	local keys = {}

	for Name, Task in Tasks do
		if Task.PillsTask == PillsTask then
			table.insert(keys, Name)
		end
	end

	local NewTask = Tasks[keys[Random.new():NextInteger(1, #keys)]]
	NewTask:gameStart()

	self.Client.NewTask:Fire(self.Player, NewTask.TaskName)
end

function TaskService:GiveNewNormalTask() end

function TaskService:GameStart(Player)
	print("GameStart")
	-- Player == Granny

	if GameLoop == nil then
		GameLoop = Knit.GetService("GameLoop")
	end
	self.Player = Player
	self:getNewTask(false)
end

function TaskService:KnitStart() end

return TaskService
