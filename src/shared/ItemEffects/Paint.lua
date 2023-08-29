local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local LocalPlayer = game.Players.LocalPlayer

local Assets = ReplicatedStorage.Assets
local Shared = ReplicatedStorage.Shared
local Packages = ReplicatedStorage.Packages

local ProximityPrompt = ReplicatedStorage.Assets.ProximityPromptHold
local assetsForTask = Assets.Tasks.CleanRoom

local Knit = require(Packages.Knit)

local CleanRoom = {}

function CleanRoom:Init() end

return CleanRoom
