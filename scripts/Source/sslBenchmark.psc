scriptname sslBenchmark extends sslSystemLibrary

import SexLabUtil

function PreBenchmarkSetup()
	Setup()
	Animation = AnimSlots.GetByRegistrar("zjAnal")
	List1 = new string[3]
	List1[0] = "FM"
	List1[1] = "BedOnly"
	List1[2] = "Oral"
	List2 = new string[5]
	List2[0] = "BedOnly"
	List2[1] = "FF"
	List2[2] = "Oral"
	List2[3] = "dfgsdg"
	List2[4] = "dsgd"
	List3 = new string[1]
	List3[0] = "Cowgirl"

endFunction

sslBaseAnimation Animation
string[] List1
string[] List2
string[] List3

state Test1
	string function Label()
		return "HasOneTag - Papyrus"
	endFunction

	string function Proof()
		return Animation.HasOneTag(List1)+" - "+Animation.HasOneTag(List2)+" - "+Animation.HasOneTag(List3)
	endFunction

	float function RunTest(int nth = 5000, float baseline = 0.0)
 		; START any variable preparions needed
		; END any variable preparions needed
		baseline += Utility.GetCurrentRealTime()
		while nth
			nth -= 1
			; START code to benchmark
			Animation.HasOneTag(List1)
			Animation.HasOneTag(List2)
			Animation.HasOneTag(List3)
			; END code to benchmark
		endWhile
		return Utility.GetCurrentRealTime() - baseline
	endFunction
endState

state Test2
	string function Label()
		return "HasOneTag2 - Papyrus"
	endFunction

	string function Proof()
		return Animation.HasOneTag2(List1)+" - "+Animation.HasOneTag2(List2)+" - "+Animation.HasOneTag2(List3)
	endFunction

	float function RunTest(int nth = 5000, float baseline = 0.0)
 		; START any variable preparions needed
		; END any variable preparions needed
		baseline += Utility.GetCurrentRealTime()
		while nth
			nth -= 1
			; START code to benchmark
			Animation.HasOneTag2(List1)
			Animation.HasOneTag2(List2)
			Animation.HasOneTag2(List3)
			; END code to benchmark
		endWhile
		return Utility.GetCurrentRealTime() - baseline
	endFunction
endState

state Test3
	string function Label()
		return "HasOneOf - Native"
	endFunction

	string function Proof()
		return Animation.HasOneOf(List1)+" - "+Animation.HasOneOf(List2)+" - "+Animation.HasOneOf(List3)
	endFunction

	float function RunTest(int nth = 5000, float baseline = 0.0)
 		; START any variable preparions needed
		; END any variable preparions needed
		baseline += Utility.GetCurrentRealTime()
		while nth
			nth -= 1
			; START code to benchmark
			Animation.HasOneOf(List1)
			Animation.HasOneOf(List2)
			Animation.HasOneOf(List3)
			; END code to benchmark
		endWhile
		return Utility.GetCurrentRealTime() - baseline
	endFunction
endState

function StartBenchmark(int Tests = 1, int Iterations = 5000, int Loops = 10, bool UseBaseLoop = false)
	PreBenchmarkSetup()

	Debug.Notification("Starting benchmark...")
	Utility.WaitMenuMode(1.0)

	float[] Results = Utility.CreateFloatArray(Tests)

	int Proof = 1
	while Proof <= Tests
		GoToState("Test"+Proof)
		Log("Functionality Proof: "+Proof(), Label())
		Proof += 1
	endWhile

	int Benchmark = 1
	while Benchmark <= Tests
		GoToState("Test"+Benchmark)
		Log("---- START #"+Benchmark+"/"+Tests+": "+Label()+" ----")

		float Total = 0.0
		float Base  = 0.0

		int n = 1
		while n <= Loops
			Utility.WaitMenuMode(0.5)
			if UseBaseLoop
				GoToState("")
				Base = RunTest(Iterations)
				GoToState("Test"+Benchmark)
			endIf
			float Time = RunTest(Iterations, Base)
			Total += Time
			if UseBaseLoop
				Log("Result #"+n+": "+Time+" -- EmptyLoop: "+Base, Label())
			else
				Log("Result #"+n+": "+Time, Label())
			endIf
			n += 1
		endWhile
		Total = (Total / Loops)
		Results[(Benchmark - 1)] = Total
		Log("Average Result: "+Total, Label())
		Log("---- END "+Label()+" ----")
		Debug.Notification("Finished "+Label())
		Benchmark += 1
	endWhile

	Debug.Trace("\n---- FINAL RESULTS ----")
	MiscUtil.PrintConsole("\n---- FINAL RESULTS ----")
	Benchmark = 1
	while Benchmark <= Tests
		GoToState("Test"+Benchmark)
		Log("Average Result: "+Results[(Benchmark - 1)], Label())
		Benchmark += 1
	endWhile
	Log("\n")

	GoToState("")
	Utility.WaitMenuMode(1.0)
	Debug.TraceAndBox("Benchmark Over, see console or debug log for results")
endFunction

string function Label()
	return ""
endFunction
string function Proof()
	return ""
endFunction
float function RunTest(int nth = 5000, float baseline = 0.0)
	baseline += Utility.GetCurrentRealTime()
	while nth
		nth -= 1
	endWhile
	return Utility.GetCurrentRealTime() - baseline
endFunction

; int Count
; int Result
; float Delay
; float Loop
; float Started

int function LatencyTest()
	return 0
	; Result  = 0
	; Count   = 0
	; Delay   = 0.0
	; Started = Utility.GetCurrentRealTime()
	; RegisterForSingleUpdate(0)
	; while Result == 0
	; 	Utility.Wait(0.1)
	; endWhile
	; return Result
endFunction

event OnUpdate()
	return
	; Delay += (Utility.GetCurrentRealTime() - Started)
	; Count += 1
	; if Count < 10
	; 	Started = Utility.GetCurrentRealTime()
	; 	RegisterForSingleUpdate(0.0)
	; else
	; 	Result = ((Delay / 10.0) * 1000.0) as int
	; 	Debug.Notification("Latency Test Result: "+Result+"ms")
	; endIf
endEvent


event Hook(int tid, bool HasPlayer)
endEvent


; Form[] function GetEquippedItems(Actor ActorRef)
; 	Form ItemRef
; 	Form[] Output = new Form[34]

; 	; Weapons
; 	ItemRef = ActorRef.GetEquippedWeapon(false) ; Right Hand
; 	if ItemRef && IsToggleable(ItemRef)
; 		Output[33] = ItemRef
; 	endIf
; 	ItemRef = ActorRef.GetEquippedWeapon(true) ; Left Hand
; 	if ItemRef && ItemRef != Output[33] && IsToggleable(ItemRef)
; 		Output[32] = ItemRef
; 	endIf

; 	; Armor
; 	int i = 32
; 	while i
; 		i -= 1
; 		ItemRef = ActorRef.GetWornForm(Armor.GetMaskForSlot(i + 30))
; 		if ItemRef && Output.Find(ItemRef) == -1 && IsToggleable(ItemRef)
; 			Output[i] = ItemRef
; 		endIf
; 	endWhile

; 	return PapyrusUtil.ClearNone(Output)
; endFunction