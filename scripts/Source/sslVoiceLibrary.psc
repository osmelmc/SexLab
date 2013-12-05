scriptname sslVoiceLibrary extends Quest

; Scripts
sslVoiceSlots property Slots auto

; Data
actor property PlayerRef auto
faction property RememberVoice auto
topic property SexLabMoanMild auto
topic property SexLabMoanMedium auto
topic property SexLabMoanHot auto
VoiceType property SexLabVoiceM auto
VoiceType property SexLabVoiceF auto
FormList property VoicesPlayer auto

Topic[] property VanillaMild auto hidden
Topic[] property VanillaMedium auto hidden
Topic[] property VanillaHot auto hidden

; Config
string property sPlayerVoice auto hidden
bool property bNPCSaveVoice auto hidden

sslBaseVoice function PickVoice(actor a)
	; Get player selected voice
	if a == PlayerRef && sPlayerVoice != "$SSL_Random"
		return Slots.GetByName(sPlayerVoice)
	; Get saved voice by faction rank as slot index
	elseIf a != PlayerRef && a.IsInFaction(RememberVoice)
		int vid = a.GetFactionRank(RememberVoice)
		; Return if it is a valid rank index
		if vid > -1 && vid < Slots.Slotted
			return Slots.GetBySlot(vid)
		endIf
	endIf
	; Pick random voice by gender
	sslBaseVoice Voice = Slots.GetRandom(a.GetLeveledActorBase().GetSex())
	; Save picked voice if option is enabled
	if bNPCSaveVoice && a != PlayerRef
		a.AddToFaction(RememberVoice)
		a.SetFactionRank(RememberVoice, Slots.Find(Voice))
	endIf
	return Voice
endFunction

function _Defaults()
	sPlayerVoice = "$SSL_Random"
	bNPCSaveVoice = true

	; VanillaMild = new Topic[3]
	; VanillaMild[0] = Game.GetForm(0x3C570) as Topic ; ExitBowZoomBreath
	; VanillaMild[1] = Game.GetForm(0x1701C) as Topic ; EnterSprintBreath
	; VanillaMild[2] = Game.GetForm(0x6CB49) as Topic ; CombatGrunt

	; VanillaMedium = new Topic[2]
	; VanillaMedium[1] = Game.GetForm(0x6CB49) as Topic ; CombatGrunt
	; VanillaMedium[2] = Game.GetForm(0x3C571) as Topic ; EnterBowZoomBreath

	; VanillaHot = new Topic[2]
	; VanillaHot[2] = Game.GetForm(0x5DD77) as Topic ; OutOfBreath
	; VanillaHot[2] = Game.GetForm(0x10EEA4) as Topic ; LeaveWaterBreath
endFunction
