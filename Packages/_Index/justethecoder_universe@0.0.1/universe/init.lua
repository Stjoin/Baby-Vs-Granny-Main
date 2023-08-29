local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local MemoryStoreService = game:GetService("MemoryStoreService")
local RunService = game:GetService("RunService")

local Promise = require(script.Parent.Promise)

export type Promise = typeof(Promise.new())

export type SessionData = {
	accessCode: string,
	data: any,
}

local ATTEMPT_LIMIT = 5
local RETRY_DELAY = 1
local FLOOD_DELAY = 15
-- There's no real logic behind this number, just thought three minutes should be enough to retrieve the data
local MEMORY_EXPIRY = 60 * 3

local universeMemoryStore = MemoryStoreService:GetSortedMap("universeMemoryStore")
local cachedSessionData: { [string]: SessionData } = {}

local Util = {}

function Util.isPrivateServer(): boolean
	return game.PrivateServerId ~= ""
end

-- This function also stores the reserved server access code in the universeMemoryStore
function Util.storeSessionData(teleportResult: TeleportAsyncResult, data: any): Promise
	if teleportResult.ReservedServerAccessCode == "" then
		return Promise.reject("Data can only be stored for reserved servers")
	end

	return Promise.retryWithDelay(
		universeMemoryStore.SetAsync,
		ATTEMPT_LIMIT,
		RETRY_DELAY,
		universeMemoryStore,
		teleportResult.PrivateServerId,
		{
			accessCode = teleportResult.ReservedServerAccessCode,
			data = data,
		},
		MEMORY_EXPIRY
	)
end

function Util.getSessionData(privateServerId: string): Promise
	privateServerId = privateServerId or game.PrivateServerId

	if cachedSessionData[privateServerId] then
		return Promise.resolve(cachedSessionData[privateServerId])
	end

	return Promise.retryWithDelay(
		universeMemoryStore.GetAsync,
		ATTEMPT_LIMIT,
		RETRY_DELAY,
		universeMemoryStore,
		privateServerId
	)
		:tap(function(data)
			cachedSessionData[privateServerId] = data
		end)
end

table.freeze(Util)

local TeleportBuilder = {}
TeleportBuilder.__index = TeleportBuilder

local function teleportAsync(placeId: number, players: { Player }, options: TeleportOptions): Promise
	return Promise.retryWithDelay(
		TeleportService.TeleportAsync,
		ATTEMPT_LIMIT,
		RETRY_DELAY,
		TeleportService,
		placeId,
		players,
		options
	)
end

local function handleFailedTeleport(
	player: Player,
	teleportResult: TeleportAsyncResult,
	err: string,
	placeId: number,
	teleportOptions: TeleportOptions
)
	if teleportResult == Enum.TeleportResult.Flooded then
		task.wait(FLOOD_DELAY)
	elseif teleportResult == Enum.TeleportResult.Failure then
		task.wait(RETRY_DELAY)
	else
		error(`Invalid teleport [{teleportResult.Name}]: {err}`)
	end

	teleportAsync(placeId, { player }, teleportOptions)
end

function TeleportBuilder.new(): TeleportBuilder
	return setmetatable({
		_placeId = false,
		_options = Instance.new("TeleportOptions"),
	}, TeleportBuilder)
end

function TeleportBuilder:setPlaceId(placeId: number): TeleportBuilder
	self._placeId = placeId
	return self
end

function TeleportBuilder:setTeleportData(data: any): TeleportBuilder
	self._options:SetTeleportData(data)
	return self
end

function TeleportBuilder:setShouldReserveServer(reserveServer: boolean): TeleportBuilder
	self._options.ShouldReserveServer = reserveServer
	return self
end

function TeleportBuilder:setReservedServerAccessCode(accessCode: string): TeleportBuilder
	self._options.ReservedServerAccessCode = accessCode
	return self
end

function TeleportBuilder:setServerId(serverId: string): TeleportBuilder
	self._options.ServerInstanceId = serverId
	return self
end

function TeleportBuilder:teleport(players: { Player }): Promise
	if self._placeId == false then
		return Promise.reject("PlaceId not set!")
	end

	return teleportAsync(self._placeId, players, self._options)
end

table.freeze(TeleportBuilder)

export type TeleportBuilder = typeof(TeleportBuilder.new())

TeleportService.TeleportInitFailed:Connect(handleFailedTeleport)

return table.freeze({
	Util = Util,
	TeleportBuilder = TeleportBuilder,
})
