local RunService = game:GetService("RunService")

assert(RunService:IsClient(), "EasyViewmodel is made only for the Client!")

local Types = require(script.Types)

local ViewmodelClass = require(script.Viewmodel)

local EasyViewmodel: Types.EasyViewmodel = {}

function EasyViewmodel.new(ViewmodelModel: Model, Settings: Types.ViewmodelSettings?): Types.Viewmodel
	local NewViewmodel = ViewmodelClass.new(ViewmodelModel, Settings)

	return NewViewmodel
end

return EasyViewmodel