local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

Knit.AddServices(script.Parent.Services)

Knit.Start()
	:andThen(function()
		print("Knit Started Server")

		for _, component in pairs(script.Parent.Components:GetChildren()) do
			if component:IsA("ModuleScript") then
				require(component)
			end
		end
	end)
	:catch(warn)
