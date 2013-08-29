scriptname sslAnimationFactory extends Quest

sslAnimationRegistry property Registry auto
sslBaseAnimation property Animation auto hidden
int slot

; Gender Types
int property Male = 0 autoreadonly hidden
int property Female = 1 autoreadonly hidden
; Cum Types
int property Vaginal = 1 autoreadonly hidden
int property Oral = 2 autoreadonly hidden
int property Anal = 3 autoreadonly hidden
int property VaginalOral = 4 autoreadonly hidden
int property VaginalAnal = 5 autoreadonly hidden
int property OralAnal = 6 autoreadonly hidden
int property VaginalOralAnal = 7 autoreadonly hidden
; SFX Types
int property Squishing = 1 autoreadonly hidden
int property Sucking = 2 autoreadonly hidden
int property SexMix = 3 autoreadonly hidden
; Content Types
int property Misc = 0 autoreadonly hidden
int property Sexual = 1 autoreadonly hidden
int property Foreplay = 2 autoreadonly hidden


function Register(string registrar)
	if  Registry.FindByRegistrar(registrar) != -1 || Registry.FreeSlot < 0
		return ; Duplicate or No free slots
	endIf
	; Wait for factory to be free
	_FactoryWait()
	; Get free animation slot
	slot = Registry.FreeSlot
	Animation = Registry.GetBySlot(slot)
	; Make sure it's cleared out before loading
	Animation.UnloadAnimation()
	; Set Registrar
	Animation.Registrar = registrar
	; Send load event
	RegisterForModEvent("RegisterAnimation", registrar)
	SendModEvent("RegisterAnimation", registrar, 1)
	UnregisterForModEvent("RegisterAnimation")
endFunction

function Save()
	Debug.Trace("SexLabAnimationFactory: Registered animation '"+Animation.Name+"' to slot["+slot+"]")
	Animation = none
	slot = -1
endfunction

function _FactoryWait()
	while Animation != none
		Utility.Wait(0.25)
	endWhile
endFunction