local Types = require(script.Parent.Types)
local Janitor = require(script.Parent.Packages.Janitor)

local PluginClass = {}
PluginClass.__index = PluginClass

function PluginClass.new(Plugin: Types.EasyViewmodelPlugin)
	local self = setmetatable(Plugin,PluginClass)

	self.Janitor = Janitor.new()

	return self
end

return PluginClass