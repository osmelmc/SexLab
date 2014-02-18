scriptname sslThreadModel extends sslSystemLibrary
{ Animation Thread Model: Runs storage and information about a thread. Access only through functions; NEVER create a property directly to this. }

bool property IsLocked hidden
	bool function get()
		return GetState() != "Unlocked"
	endFunction
endProperty

; Actor Storage
Actor[] property Positions auto hidden
Actor property VictimRef auto hidden
int property ActorCount auto hidden
sslActorAlias[] property ActorAlias auto hidden

; Thread status
bool property HasPlayer auto hidden
bool property AutoAdvance auto hidden
bool property LeadIn auto hidden
bool property FastEnd auto hidden
bool property IsAggressive auto hidden

; Animation Info
int property Stage auto hidden
sslBaseAnimation property Animation auto hidden
sslBaseAnimation[] CustomAnimations
sslBaseAnimation[] PrimaryAnimations
sslBaseAnimation[] LeadAnimations
sslBaseAnimation[] property Animations hidden
	sslBaseAnimation[] function get()
		if CustomAnimations.Length > 0
			return CustomAnimations
		elseIf LeadIn
			return LeadAnimations
		else
			return PrimaryAnimations
		endIf
	endFunction
endProperty

; Timer Info
float[] CustomTimers
float[] property Timers hidden
	float[] function get()
		if CustomTimers.Length != 0
			return CustomTimers
		elseif LeadIn
			return Config.fStageTimerLeadIn
		elseif IsAggressive
			return Config.fStageTimerAggr
		else
			return Config.fStageTimer
		endIf
	endFunction
endProperty

; Thread info
float[] property CenterLocation auto hidden
ObjectReference property CenterRef auto hidden
ObjectReference property BedRef auto hidden

float property StartedAt auto hidden
float property TotalTime hidden
	float function get()
		return Utility.GetCurrentRealTime() - StartedAt
	endFunction
endProperty

int[] property Genders auto hidden
int property Males hidden
	int function get()
		return Genders[0]
	endFunction
endProperty
int property Females hidden
	int function get()
		return Genders[1]
	endFunction
endProperty
int property Creatures hidden
	int function get()
		return Genders[2]
	endFunction
endProperty
bool property HasCreature hidden
	bool function get()
		return Creatures != 0
	endFunction
endProperty

; Local readonly
bool NoLeadIn
string[] Hooks
int BedFlag ; 0 allow, 1 force, -1 forbid

; ------------------------------------------------------- ;
; --- Thread Making API                               --- ;
; ------------------------------------------------------- ;

state Making
	int function AddActor(Actor ActorRef, bool IsVictim = false, sslBaseVoice Voice = none, bool ForceSilent = false)
		; Ensure we have room for actor
		if ActorRef == none
			Log("AddActor() - Failed to add actor -- Actor is empty.", "FATAL")
			return -1
		elseIf ActorCount >= 5
			Log("AddActor() - Failed to add actor '"+ActorRef.GetLeveledActorBase().GetName()+"' -- Thread has reached actor limit", "FATAL")
			return -1
		elseIf Positions.Find(ActorRef) != -1 || ActorLib.IsActorActive(ActorRef)
			Log("AddActor() - Failed to add actor '"+ActorRef.GetLeveledActorBase().GetName()+"' -- They are already claimed by a thread", "FATAL")
			return -1
		endIf
		; Attempt to claim a slot
		sslActorAlias Slot = SlotActor(ActorRef)
		if !Slot || !Slot.PrepareAlias(ActorRef, IsVictim, Voice, ForceSilent)
			Log("AddActor() - Failed to add actor '"+ActorRef.GetLeveledActorBase().GetName()+"' -- They were unable to fill an actor alias", "FATAL")
			return -1
		endIf
		; Update thread info
		Positions = sslUtility.PushActor(ActorRef, Positions)
		ActorCount = Positions.Length
		HasPlayer = Positions.Find(PlayerRef) != -1
		Genders[Slot.Gender] = Genders[Slot.Gender] + 1
		return Positions.Find(ActorRef)
	endFunction

	bool function AddActors(Actor[] ActorList, Actor VictimActor = none)
		int Count = ActorList.Length
		if Count < 1 || ((Positions.Length + Count) > 5) || ActorList.Find(none) != -1
			Log("AddActors() - Failed to add actor list as it either contains to many actors placing the thread over it's limit, none at all, or an invalid 'None' entry -- "+ActorList, "FATAL")
			return false
		endIf
		int i
		while i < Count
			if AddActor(ActorList[i], (ActorList[i] == VictimActor)) == -1
				return false
			endIf
			i += 1
		endWhile
		return true
	endFunction

	sslThreadController function StartThread()
		UnregisterForUpdate()

		; ------------------------- ;
		; --   Validate Thread   -- ;
		; ------------------------- ;

		if ActorCount < 1 || Positions.Length == 0
			Log("StartThread() - No valid actors available for animation", "FATAL")
			return none
		endIf

		; ------------------------- ;
		; --    Locate Center    -- ;
		; ------------------------- ;

		; Search location marker near player or first position
		if CenterRef == none
			if HasPlayer
				CenterOnObject(Game.FindClosestReferenceOfTypeFromRef(ThreadLib.LocationMarker, PlayerRef, 750.0))
			else
				CenterOnObject(Game.FindClosestReferenceOfTypeFromRef(ThreadLib.LocationMarker, Positions[0], 750.0))
			endIf
		endIf
		; Search for nearby bed
		if CenterRef == none && BedFlag != -1
			CenterOnBed(HasPlayer, 750.0)
		endIf
		; Center on fallback choices
		if CenterRef == none
			if IsAggressive
				CenterOnObject(VictimRef)
			elseIf HasPlayer
				CenterOnObject(PlayerRef)
			else
				CenterOnObject(Positions[0])
			endIf
		endIf

		; ------------------------- ;
		; -- Validate Animations -- ;
		; ------------------------- ;

		; Get default primary animations if none
		if PrimaryAnimations.Length == 0
			SetAnimations(AnimSlots.GetByDefault(Males, Females, IsAggressive, (BedRef != none), Config.bRestrictAggressive))
			if PrimaryAnimations.Length == 0
				Log("StartThread() - Unable to find valid default animations", "FATAL")
				return none
			endIf
		endIf
		; Get default foreplay if none and enabled
		if !HasCreature && !IsAggressive && ActorCount == 2 && !NoLeadIn && LeadAnimations.Length == 0 && Config.bForeplayStage
			if BedRef != none
				SetLeadAnimations(AnimSlots.GetByTags(2, "LeadIn", "Standing"))
			else
				SetLeadAnimations(AnimSlots.GetByTags(2, "LeadIn"))
			endIf
		endIf

		; ------------------------- ;
		; --  Start Controller   -- ;
		; ------------------------- ;
		sslThreadController Controller = PrimeThread()
		if !Controller
			Log("StartThread() - Failed to prime thread for unknown reasons!", "FATAL")
			return none
		endIf
		return Controller
	endFunction

	event OnUpdate()
		Log("Thread has timed out of the making process; resetting model for selection pool", "FATAL")
		Initialize()
	endEvent

endState



; ------------------------------------------------------- ;
; --- Actor Setup                                     --- ;
; ------------------------------------------------------- ;

; Actor Overrides
function SetStrip(Actor ActorRef, bool[] StripSlots)
	ActorAlias(ActorRef).OverrideStrip(StripSlots)
	if StripSlots.Length == 33
		ActorAlias(ActorRef).OverrideStrip(StripSlots)
	else
		Log("Malformed StripSlots bool[] passed, must be 33 length bool array, "+StripSlots.Length+" given", "ERROR")
	endIf
endFunction

function DisableUndressAnimation(Actor ActorRef, bool disabling = true)
	ActorAlias(ActorRef).DoUndress = !disabling
endFunction

function DisableRagdollEnd(Actor ActorRef, bool disabling = true)
	ActorAlias(ActorRef).DoRagdoll = !disabling
endFunction

; Voice
function SetVoice(Actor ActorRef, sslBaseVoice Voice, bool ForceSilent = false)
	ActorAlias(ActorRef).SetVoice(Voice, ForceSilent)
endFunction

sslBaseVoice function GetVoice(Actor ActorRef)
	return ActorAlias(ActorRef).GetVoice()
endFunction

; Expressions
; function SetExpression(Actor ActorRef, sslBaseExpression Expression)
;	ActorAlias(ActorRef).SetExpression(Expression)
; endFunction
; sslBaseExpression function GetExpression(Actor ActorRef)
;	return ActorAlias(ActorRef).GetExpression()
; endFunction

; Enjoyment/Pain
int function GetEnjoyment(Actor ActorRef)
	; ActorAlias(ActorRef).GetEnjoyment()
endFunction
int function GetPain(Actor ActorRef)
	; ActorAlias(ActorRef).GetPain()
endFunction

; Actor Information
int function GetPlayerPosition()
	return Positions.Find(PlayerRef)
endFunction

int function GetPosition(Actor ActorRef)
	return Positions.Find(ActorRef)
endFunction

bool function IsPlayerActor(Actor ActorRef)
	return ActorRef == PlayerRef
endFunction

bool function IsPlayerPosition(int Position)
	return Position == Positions.Find(PlayerRef)
endFunction

bool function HasActor(Actor ActorRef)
	return Positions.Find(ActorRef) != -1
endFunction

bool function IsVictim(Actor ActorRef)
	return VictimRef == ActorRef
endFunction

; ------------------------------------------------------- ;
; --- Animation Setup                                 --- ;
; ------------------------------------------------------- ;

function SetForcedAnimations(sslBaseAnimation[] AnimationList)
	if AnimationList.Length != 0
		CustomAnimations = AnimationList
		SetAnimation()
	endIf
endFunction

function SetAnimations(sslBaseAnimation[] AnimationList)
	if AnimationList.Length != 0
		PrimaryAnimations = AnimationList
		SetAnimation()
	endIf
endFunction

function SetLeadAnimations(sslBaseAnimation[] AnimationList)
	if AnimationList.Length != 0
		LeadIn = true
		LeadAnimations = AnimationList
		SetAnimation()
	endIf
endFunction

; ------------------------------------------------------- ;
; --- Thread Settings                                 --- ;
; ------------------------------------------------------- ;

function DisableLeadIn(bool disabling = true)
	NoLeadIn = disabling
	if disabling
		LeadIn = false
	endIf
endFunction

function DisableBedUse(bool disabling = true)
	BedFlag = 0
	if disabling
		BedFlag = -1
	endIf
endFunction

function SetBedFlag(int flag = 0)
	BedFlag = flag
endFunction

function SetTimers(float[] setTimers)
	if setTimers.Length < 1
		Log("SetTimers() - Empty timers given.", "ERROR")
		return
	endIf
	CustomTimers = setTimers
endFunction

float function GetStageTimer(int maxstage)
	int last = ( Timers.Length - 1 )
	if stage == maxstage
		return Timers[last]
	elseif stage < last
		return Timers[(stage - 1)]
	endIf
	return Timers[(last - 1)]
endfunction

function CenterOnObject(ObjectReference CenterOn, bool resync = true)
	if CenterOn != none
		CenterRef = CenterOn
		CenterOnCoords(CenterOn.GetPositionX(), CenterOn.GetPositionY(), CenterOn.GetPositionZ(), CenterOn.GetAngleX(), CenterOn.GetAngleY(), CenterOn.GetAngleZ(), false)
		if ThreadLib.BedsList.HasForm(CenterOn.GetBaseObject())
			BedRef = CenterOn
			CenterLocation[0] = CenterLocation[0] + (33.0 * Math.sin(CenterLocation[5]))
			CenterLocation[1] = CenterLocation[1] + (33.0 * Math.cos(CenterLocation[5]))
			if !ThreadLib.BedRollsList.HasForm(CenterOn.GetBaseObject())
				CenterLocation[2] = CenterLocation[2] + 37.0
			endIf
		endIf
	endIf
endFunction

function CenterOnCoords(float LocX = 0.0, float LocY = 0.0, float LocZ = 0.0, float RotX = 0.0, float RotY = 0.0, float RotZ = 0.0, bool resync = true)
	CenterLocation = new float[6]
	CenterLocation[0] = LocX
	CenterLocation[1] = LocY
	CenterLocation[2] = LocZ
	CenterLocation[3] = RotX
	CenterLocation[4] = RotY
	CenterLocation[5] = RotZ
endFunction

 bool function CenterOnBed(bool AskPlayer = true, float Radius = 750.0)
 	ObjectReference FoundBed
	if BedFlag == -1
		return false ; Beds forbidden by flag
	elseIf HasPlayer
		FoundBed = ThreadLib.FindBed(PlayerRef, Radius) ; Check within radius of player
	elseIf Config.sNPCBed == "$SSL_Always" || (Config.sNPCBed == "$SSL_Sometimes" && (Utility.RandomInt(0, 1) as bool))
		FoundBed = ThreadLib.FindBed(Positions[0], Radius) ; Check within radius of first position, if NPC beds are allowed
	endIf
	; Found a bed AND EITHER forced use OR don't care about players choice OR or player approved
	if FoundBed != none && (BedFlag == 1 || (!AskPlayer || (AskPlayer && (ThreadLib.UseBed.Show() as bool))))
		CenterOnObject(FoundBed)
		return true ; Bed found and approved for use
	endIf
	return false ; No bed found
endFunction

; ------------------------------------------------------- ;
; --- Event Hooks                                     --- ;
; ------------------------------------------------------- ;

function SetHook(string addHooks)
	string[] Setting = sslUtility.ArgString(addHooks)
	int i = Setting.Length
	while i
		i -= 1
		if Setting[i] != "" && Hooks.Find(Setting[i]) == -1
			; AddTag(Setting[i])
			Hooks = sslUtility.PushString(Setting[i], Hooks)
		endIf
	endWhile
endFunction

string function GetHook()
	return Hooks[0] ; v1.35 Legacy support, pre multiple hooks
endFunction

string[] function GetHooks()
	return Hooks
endFunction

function RemoveHook(string delHooks)
	string[] Removing = sslUtility.ArgString(delHooks)
	string[] NewHooks
	int i = Hooks.Length
	while i
		i -= 1
		if Removing.Find(Hooks[i]) == -1
			NewHooks = sslUtility.PushString(Hooks[i], NewHooks)
		endIf
	endWhile
	Hooks = NewHooks
endFunction

; ------------------------------------------------------- ;
; --- Actor Alias                                     --- ;
; ------------------------------------------------------- ;

int function FindSlot(Actor ActorRef)
	return StorageUtil.GetIntValue(ActorRef, "SexLab.Position", -1)
endFunction

sslActorAlias function ActorAlias(Actor ActorRef)
	return ActorAlias[FindSlot(ActorRef)]
endFunction

sslActorAlias function PositionAlias(int Position)
	return ActorAlias[FindSlot(Positions[Position])]
endFunction

sslActorAlias function SlotActor(Actor ActorRef)
	int i
	while i < 5 && !ActorAlias[i].ForceRefIfEmpty(ActorRef)
		i += 1
	endWhile
	if i < 5 && ActorAlias[i].GetReference() == ActorRef
		return ActorAlias[i]
	endIf
	return none
endFunction

; ------------------------------------------------------- ;
; --- System Use Only                                 --- ;
; ------------------------------------------------------- ;

function Initialize()
	UnregisterForUpdate()
	; Clear aliases
	ActorAlias[0].ClearAlias()
	ActorAlias[1].ClearAlias()
	ActorAlias[2].ClearAlias()
	ActorAlias[3].ClearAlias()
	ActorAlias[4].ClearAlias()
	; Forms
	VictimRef    = none
	CenterRef    = none
	BedRef       = none
	; Boolean
	HasPlayer    = false
	LeadIn       = false
	NoLeadIn     = false
	FastEnd      = false
	IsAggressive = false
	AutoAdvance  = true
	; Integers
	BedFlag      = 0
	ActorCount   = 0
	Genders      = new int[3]
	; Storage
	Actor[] aDel
	float[] fDel1
	string[] sDel1
	Positions    = aDel
	CustomTimers = fDel1
	Hooks        = sDel1
	; Animations
	sslBaseAnimation[] anDel1
	sslBaseAnimation[] anDel2
	sslBaseAnimation[] anDel3
	CustomAnimations  = anDel1
	PrimaryAnimations = anDel2
	LeadAnimations    = anDel3
	; Enter thread selection pool
	GoToState("Unlocked")
	Reset()
endFunction

function Log(string Log, string Type = "NOTICE")
	SexLabUtil.DebugLog(Log, Type, Config.DebugMode)
	if Type == "FATAL"
		Initialize()
	endIf
endFunction

function SendThreadEvent(string HookEvent)
	SetupThreadEvent(HookEvent)
	int i = Hooks.Length
	while i
		i -= 1
		SetupThreadEvent(HookEvent+"_"+Hooks[i])
	endWhile
endFunction

function SetupThreadEvent(string HookEvent)
	int eid = ModEvent.Create(HookEvent)
	if eid
		ModEvent.PushInt(eid, thread_id)
		ModEvent.PushString(eid, HookEvent)
		ModEvent.Send(eid)
		Log("Thread Hook Sent: "+HookEvent)
	endIf
	SendModEvent(HookEvent, thread_id)
endFunction

function SyncActors(bool force = false)
	ActorAlias[0].SyncThread(Animation, Stage)
	ActorAlias[1].SyncThread(Animation, Stage)
	ActorAlias[2].SyncThread(Animation, Stage)
	ActorAlias[3].SyncThread(Animation, Stage)
	ActorAlias[4].SyncThread(Animation, Stage)
endFunction

bool function ActorWait(string WaitFor)
	int i = ActorCount
	while i
		i -= 1
		if ActorAlias[i].GetState() != WaitFor
			return false
		endIf
	endWhile
	return true
endFunction

function AliasAction(string FireState, string StateFinish)
	; Start actor action state
	ActorAlias[0].Action(FireState)
	ActorAlias[1].Action(FireState)
	ActorAlias[2].Action(FireState)
	ActorAlias[3].Action(FireState)
	ActorAlias[4].Action(FireState)
	; Wait for actors ready, or for ~30 seconds to pass
	int failsafe = 30
	while !ActorWait(StateFinish) && failsafe
		failsafe -= 1
		Utility.Wait(1.0)
	endWhile
endFunction

function Action(string FireState)
	UnregisterForUpdate()
	EndAction() ; OnEndState()
	GoToState(FireState)
	FireAction() ; OnBeginState()
endFunction

int thread_id
int property tid hidden
	int function get()
		return thread_id
	endFunction
endProperty

function _SetupThread(int id)
	thread_id = id
	ActorAlias = new sslActorAlias[5]
	ActorAlias[0] = GetNthAlias(0) as sslActorAlias
	ActorAlias[1] = GetNthAlias(1) as sslActorAlias
	ActorAlias[2] = GetNthAlias(2) as sslActorAlias
	ActorAlias[3] = GetNthAlias(3) as sslActorAlias
	ActorAlias[4] = GetNthAlias(4) as sslActorAlias
	Initialize()
endFunction

; ------------------------------------------------------- ;
; --- State Restricted                                --- ;
; ------------------------------------------------------- ;

auto state Unlocked
	sslThreadModel function Make(float TimeOut = 30.0)
		Log("Entering Making State", "Unlocked")
		Initialize()
		GoToState("Making")
		RegisterForSingleUpdate(TimeOut)
		return self
	endFunction
endState

; Making
sslThreadModel function Make(float TimeOut = 30.0)
	Log("Make() - Cannot enter make on a locked thread", "FATAL")
	return none
endFunction
sslThreadController function StartThread()
	Log("StartThread() - Cannot start thread while not in a Making state", "FATAL")
	return none
endFunction
sslThreadController function PrimeThread()
	Log("StartThread() - Failed to start, controller is null", "FATAL")
	return none
endFunction
int function AddActor(Actor ActorRef, bool IsVictim = false, sslBaseVoice Voice = none, bool ForceSilent = false)
	Log("AddActor() - Cannot add an actor to a locked thread", "FATAL")
	return -1
endFunction
bool function AddActors(Actor[] ActorList, Actor VictimActor = none)
	Log("AddActors() - Cannot add a list of actors to a locked thread", "FATAL")
	return false
endFunction
; State varied
function SetAnimation(int AnimID = -1)
endFunction
function FireAction()
endFunction
function EndAction()
endFunction
; Animating
event OnKeyDown(int keyCode)
endEvent

; ------------------------------------------------------- ;
; --- Legacy; do not use these functions anymore!     --- ;
; ------------------------------------------------------- ;

bool function HasPlayer()
	return HasPlayer
endFunction
Actor function GetPlayer()
	return PlayerRef
endFunction
Actor function GetVictim()
	return VictimRef
endFunction
float function GetTime()
	return StartedAt
endfunction
function SetBedding(int flag = 0)
	SetBedFlag(flag)
endFunction
