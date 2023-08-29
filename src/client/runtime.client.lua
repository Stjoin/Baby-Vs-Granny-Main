local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

Knit.AddControllers(script.Parent.Controllers)

Knit.Start()
	:andThen(function()
		print("Knit Started Client")

		for _, component in pairs(script.Parent.Components:GetChildren()) do
			if component:IsA("ModuleScript") then
				require(component)
			end
		end
	end)
	:catch(warn)
