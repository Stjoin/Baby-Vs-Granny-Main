local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Shared = ReplicatedStorage.Shared
local Packages = ReplicatedStorage.Packages

local GameSettings = require(Shared.GameSettings)
local Knit = require(Packages.Knit)
local TableUtil = require(Packages.TableUtil)
local Timer = require(Packages.Timer)
local Tasks = require(Shared.Tasks)

local ScreenGui = Players.LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("Game")
local TaskIndicator = ScreenGui:WaitForChild("TaskIndicator")
local Description = TaskIndicator:WaitForChild("Description")
local Amount = TaskIndicator:WaitForChild("Amount")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

local TaskService, GameLoop

local TaskController = Knit.CreateController({
	Name = "TaskController",
	Task = nil,
})

function TaskController:NewTask(Task, TaskDescription)
	task.wait(1)
	self.Task = Tasks[Task]
	print(Task, TaskDescription)
	if TaskDescription then
		Description.Text = TaskDescription
	else
		Description.Text = self.Task.TaskDescription
	end

	self:UpdateAmountUI(self.Task.CurrentAmount)

	TaskIndicator.Visible = true

	self.Task:gameStart()
end

function TaskController:UpdateAmountUI(CurrentAmount)
	Amount.Text = (self.Task.Amount - CurrentAmount) .. "/" .. self.Task.Amount .. " Items"
end

function TaskController:GameStart()
	TaskService.NewTask:Connect(function(...)
		self:NewTask(...)
	end)

	TaskService.PartOfTaskCompleted:Connect(function(...)
		self:UpdateAmountUI(...)
	end)
end

function TaskController:KnitStart()
	if TaskService == nil and GameLoop == nil then
		GameLoop = Knit.GetService("GameLoop")
		TaskService = Knit.GetService("TaskService")
	end

	GameLoop.GameStart:Connect(function(Role)
		if Role == "Baby" then
			Amount.Visible = false
			TaskIndicator.Visible = true
			Description.Text = GameSettings.DefaultTaskDescriptionBaby
		elseif Role == "Granny" then
			self:GameStart()
		end
	end)
end

return TaskController
