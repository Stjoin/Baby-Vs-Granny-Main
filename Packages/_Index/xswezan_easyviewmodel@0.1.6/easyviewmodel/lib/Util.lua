local Util = {}

function Util:GetBobbing(Addition: number, Speed: number, Modifier: number): number
	return math.sin(tick() * Addition * Speed) * Modifier
end

return Util