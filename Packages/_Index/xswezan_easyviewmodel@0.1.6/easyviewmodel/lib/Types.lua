local Types = {}

export type EasyViewmodel = {
	new: () -> Viewmodel;
}

export type Viewmodel = {
	LoadAnimation: (self: Viewmodel, Name: string, Animation: Animation, Force: boolean?, IsCore: boolean?) -> AnimationTrack;
	UnloadAnimation: (self: Viewmodel, Name: string) -> boolean?;
	GetAnimation: (self: Viewmodel, Name: string) -> AnimationTrack?;
	PlayAnimation: (self: Viewmodel, Name: string, FadeTime: number?, DontStopOtherAnimations: boolean?) -> AnimationTrack?;
	StopAnimations: (self: Viewmodel, FadeTime: number?) -> nil;
	PlayCoreAnimation: (self: Viewmodel, Name: string, FadeTime: number?, DontStopOtherCoreAnimations: boolean?) -> AnimationTrack?;
	StopCoreAnimations: (self: Viewmodel, FadeTime: number?) -> nil;

	EquipTool: (self: Viewmodel, Tool: Tool) -> boolean?;
	UnequipTool: (self: Viewmodel) -> Tool?;
	GetTool: (self: Viewmodel) -> Tool?;

	Hide: (self: Viewmodel) -> nil;
	Show: (self: Viewmodel) -> nil;

	Destroy: (self: Viewmodel) -> nil;
}

export type ViewmodelSettings = {
	AnimateCamera: boolean?;
	Camera: Camera?;

	UsePlayerShirt: boolean?;
}

export type EasyViewmodelPlugin = {
	Name: string;

	Start: (self: EasyViewmodelPlugin, Viewmodel: Viewmodel) -> nil;
}

return Types