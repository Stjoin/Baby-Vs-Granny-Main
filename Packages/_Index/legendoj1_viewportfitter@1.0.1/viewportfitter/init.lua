--!strict
--[[
	MIT License

	Copyright (c) 2021 EgoMoose
	Adapted by MagmaBurnsV to include strict typing and up-to-date practices

	Permission is hereby granted, free of charge, to any person obtaining a copy
	of this software and associated documentation files (the "Software"), to deal
	in the Software without restriction, including without limitation the rights
	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	copies of the Software, and to permit persons to whom the Software is
	furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in all
	copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
	SOFTWARE.
--]]

-- // Constants

local BLOCK_INDICES: {number} = {0, 1, 2, 3, 4, 5, 6, 7}
local WEDGE_INDICES: {number} = {0, 1, 3, 4, 5, 7}
local CORNER_INDICES: {number} = {0, 1, 4, 5, 6}


-- // Helper Functions

-- Returns Index Array for Part Type
local function GetIndices(Part: BasePart): {number}
	if Part:IsA("WedgePart") then
		return WEDGE_INDICES
	end

	if Part:IsA("CornerWedgePart") then
		return CORNER_INDICES
	end

	return BLOCK_INDICES
end

-- Returns Corners based on CFrame, Size and Indices
local function GetCorners(CF: CFrame, Size2: Vector3, Indices: {number}): {Vector3}
	local Corners: {Vector3} = table.create(#Indices)

	for Key: number, Index: number in Indices do
		Corners[Key] = CF * (Size2 * Vector3.new(
			2 * (math.floor(Index * 0.25) % 2) - 1,
			2 * (math.floor(Index * 0.5) % 2) - 1,
			2 * (Index % 2) - 1
			)
		)
	end

	return Corners
end

-- Get All Model Corners
local function GetModelPointCloud(Model: Model): {Vector3}
	local Descendants: {Instance} = Model:GetDescendants()

	-- Allocate Least Amount of Points Possible
	local Points: {Vector3} = table.create(5 * #Descendants)

	for _, Child: Instance in Descendants do
		if Child:IsA("BasePart") then
			local Indices: {number} = GetIndices(Child)
			local Corners: {Vector3} = GetCorners(Child.CFrame, Child.Size * 0.5, Indices)

			-- We set 't' to #Points + 1
			-- Because be don't want to Override the Previous Indexes
			table.move(Corners, 1, #Corners, #Points + 1, Points)
		end
	end

	return Points
end

-- Returns Maximum and Minimum Edge Hits
local function ViewProjectionEdgeHits(Cloud: {Vector3}, Axis: "X" | "Y", Depth: number, TanFov2: number): (number, number)
	local Max: number, Min: number = -math.huge, math.huge

	for _, LP: Vector3 in Cloud do
		local Distance: number = Depth - LP.Z
		local HalfSpan: number = TanFov2 * Distance

		local A: number = (LP :: any)[Axis] + HalfSpan
		local B: number = (LP :: any)[Axis] - HalfSpan

		Max = math.max(Max, A, B)
		Min = math.min(Min, A, B)
	end

	return Max, Min
end


-- // ViewportModel Class

local ViewportModel = {}
ViewportModel.__index = ViewportModel


type Viewport = {
	Aspect: number,

	Y_Fov2: number,
	TanY_Fov2: number,

	X_Fov2: number,
	TanX_Fov2: number,

	C_Fov2: number,
	SinC_Fov2: number
}

type self = {
	Model: Model?,
	ViewportFrame: ViewportFrame,
	Camera: Camera,

	_Points: {Vector3},
	_ModelCFrame: CFrame,
	_ModelSize: Vector3,
	_ModelRadius: number,

	_Viewport: Viewport
}

export type ViewportModel = typeof(setmetatable({} :: self, ViewportModel))


function ViewportModel.new(ViewportFrame: ViewportFrame, Camera: Camera): ViewportModel
	local self = setmetatable({
		Model = nil,
		ViewportFrame = ViewportFrame,
		Camera = Camera,

		_Points = {},
		_ModelCFrame = CFrame.identity,
		_ModelSize = Vector3.zero,
		_ModelRadius = 0,

		_Viewport = nil :: any
	} :: self, ViewportModel)

	-- Update _Viewport
	self:Calibrate()


	return self
end

-- Sets Model
-- Updates Points and Model Properties
function ViewportModel.SetModel(self: ViewportModel, Model: Model): ()
	local CF: CFrame, Size: Vector3 = Model:GetBoundingBox()

	self.Model = Model

	self._Points = GetModelPointCloud(Model)
	self._ModelCFrame = CF
	self._ModelSize = Size	
	self._ModelRadius = Size.Magnitude * 0.5
end

-- Updates _Viewport
-- Call when the ViewportFrame / Camera Changes
function ViewportModel.Calibrate(self: ViewportModel)
	local Size: Vector2 = self.ViewportFrame.AbsoluteSize


	local Aspect: number = Size.X / Size.Y

	local Y_Fov2: number = math.rad(self.Camera.FieldOfView * 0.5)
	local TanY_Fov2: number = math.tan(Y_Fov2)

	local X_Fov2: number = math.atan(TanY_Fov2 * Aspect)
	local TanX_Fov2: number = math.tan(X_Fov2)

	local C_Fov2: number = math.atan(TanY_Fov2) * math.min(1, Aspect)
	local SinC_Fov2: number = math.sin(C_Fov2)


	self._Viewport = {
		Aspect = Aspect,

		Y_Fov2 = Y_Fov2,
		TanY_Fov2 = TanY_Fov2,

		X_Fov2 = X_Fov2,
		TanX_Fov2 = TanX_Fov2,

		C_Fov2 = C_Fov2,
		SinC_Fov2 = SinC_Fov2
	}
end

-- Returns Distance that would Encapsulate self.Model
-- Based on Focus or Default Center
function ViewportModel.GetFitDistance(self: ViewportModel, Focus: Vector3?): number
	local Displacement: number = if Focus then (Focus - self._ModelCFrame.Position).Magnitude else 0
	local Radius: number = self._ModelRadius + Displacement

	return Radius / self._Viewport.SinC_Fov2
end

-- Returns Distance from an Orientation that would Encapsulate self.Model
-- Only for that Specific Orientation
function ViewportModel.GetMinimumFitCFrame(self: ViewportModel, Orientation: CFrame): CFrame
	if not self.Model then
		return CFrame.identity
	end


	local Rotation: CFrame = Orientation - Orientation.Position
	local R_Inverse: CFrame = Rotation:Inverse()

	local Points: {Vector3} = self._Points
	local Cloud: {Vector3} = table.create(#Points)


	local Furthest: number = 0

	for Index: number, Point: Vector3 in Points do
		local LP: Vector3 = R_Inverse * Point
		Furthest = math.min(Furthest, LP.Z)
		Cloud[Index] = LP
	end


	local H_Max: number, H_Min: number = ViewProjectionEdgeHits(Cloud, "X", Furthest, self._Viewport.TanX_Fov2)
	local V_Max: number, V_Min: number = ViewProjectionEdgeHits(Cloud, "Y", Furthest, self._Viewport.TanY_Fov2)

	local Distance: number = math.max(
		((H_Max - H_Min) * 0.5) / self._Viewport.TanX_Fov2,
		((V_Max - V_Min) * 0.5) / self._Viewport.TanY_Fov2
	)


	return Orientation * CFrame.new(
		(H_Max + H_Min) * 0.5,
		(V_Max + V_Min) * 0.5,
		Furthest + Distance
	)
end


return ViewportModel