local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local Shared = ReplicatedStorage.Shared
local Packages = ReplicatedStorage.Packages

local GameSettings = require(Shared.GameSettings)
local Knit = require(Packages.Knit)
local TableUtil = require(Packages.TableUtil)

local ThrowService

local ItemService = Knit.CreateService({
	Name = "ItemService",
	Client = {
		ChestOpened = Knit.CreateSignal(),
		AddItem = Knit.CreateSignal(),
		ClaimItem = Knit.CreateSignal(),
	},
	Item = nil,
})

local function getRandomItem(KeysRequired)
	local items = {}
	for item, data in pairs(GameSettings.ItemSetting) do
		if data.KeysNeeded == KeysRequired then
			table.insert(items, item)
		end
	end

	if #items == 0 then
		warn("No items found that match the requirement")
		return nil -- No items found that match the requirement
	end

	local randomIndex = Random.new():NextInteger(1, #items)
	return items[randomIndex]
end

function ItemService:AddItem(KeysRequired)
	local Item: string = getRandomItem(KeysRequired)

	if Item then
		self.Item = Item

		self.Client.AddItem:Fire(self.Player, Item)
	end
end

function ItemService:ChestOpened(Player, Chest)
	if Player:DistanceFromCharacter(Chest.PrimaryPart.Position) <= 10 then
		local KeyValue = Player:FindFirstChild("Keys")
		local KeysRequired = Chest:GetAttribute("KeysRequired")

		if KeyValue.Value >= KeysRequired then
			KeyValue.Value -= KeysRequired

			self:AddItem(KeysRequired)
		end
	end
end

function ItemService:GameStart(Player)
	print("GameStart")
	-- Player == Baby
	if ThrowService == nil then
		ThrowService = Knit.GetService("ThrowService")
	end

	self.Player = Player

	self.Client.ClaimItem:Connect(function(Player, Item)
		if self.Item == Item then
			self.Item = nil
			ThrowService:AddItem(Item)
		end
	end)

	self.Client.ChestOpened:Connect(function(Player, Chest)
		self:ChestOpened(Player, Chest)
	end)
end

function ItemService:KnitStart() end

return ItemService
