local SoundService = game:GetService("SoundService")

local Plugin = {
	Name = "SmartAnimations";
}

function Plugin:Start(Viewmodel)
	self.Sounds = {}

	local this = self

	function Viewmodel:LoadAnimationSound(Sound: Sound)
		this.Sounds[Sound.Name] = Sound:Clone()
	end

	function Viewmodel:PlayAnimation(Name: string, FadeTime: number?): AnimationTrack?
		local AnimationTrack: AnimationTrack = self:GetAnimation(Name)
		if not (AnimationTrack) then return end

		local JanitorKey: string = `Animation_{Name}`
	
		if not (AnimationTrack:GetAttribute("SoundConnected")) then
			AnimationTrack:SetAttribute("SoundConnected", true)

			self.Janitor:Add(AnimationTrack:GetMarkerReachedSignal("Sound"):Connect(function(Name: string)
				print(Name)
				this:PlaySound(Name)
			end),"Disconnect",JanitorKey);

			--TODO
			-- self.Janitor:Add(AnimationTrack:GetMarkerReachedSignal("StartSound"):Connect(function(Name: string)
				
			-- end),"Disconnect",JanitorKey);

			-- self.Janitor:Add(AnimationTrack:GetMarkerReachedSignal("StopSound"):Connect(function(Name: string)
				
			-- end),"Disconnect",JanitorKey);
	
			AnimationTrack.Ended:Once(function()
				AnimationTrack:SetAttribute("SoundConnected", false)
				self.Janitor:Remove(JanitorKey)
			end)
		end

		AnimationTrack:Play(FadeTime)
	
		return AnimationTrack
	end
end

function Plugin:PlaySound(Name: string)
	local Sound: Sound = self.Sounds[Name]
	if not (Sound) then return end

	Sound = Sound:Clone()
	Sound.PlayOnRemove = true
	Sound.Parent = SoundService
	Sound:Destroy()
end

return Plugin