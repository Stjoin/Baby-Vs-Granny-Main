local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Shared = ReplicatedStorage.Shared
local Packages = ReplicatedStorage.Packages

local GameSettings = require(Shared.GameSettings)
local Knit = require(Packages.Knit)
local Timer = require(Packages.Timer)

local ScreenGui = Players.LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("Game")
local ItemButton = ScreenGui:WaitForChild("ItemButton")
local ItemImage = ItemButton:WaitForChild("ImageLabel")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

local ItemService
local ButtonPressedConnection

local ItemController = Knit.CreateController({
	Name = "ItemController",
})

function ItemController:KnitStart()
	if ItemService == nil then
		ItemService = Knit.GetService("ItemService")
	end

	game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)

	ItemService.AddItem:Connect(function(Item)
		ItemImage.Image = GameSettings.ItemSetting[Item].Image
		ItemButton.Visible = true

		ButtonPressedConnection = ItemButton.MouseButton1Click:Connect(function()
			ButtonPressedConnection:Disconnect()

			ItemButton.Visible = false
			ItemService.ClaimItem:Fire(Item)
		end)
	end)
end

return ItemController
