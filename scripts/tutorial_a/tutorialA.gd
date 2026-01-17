extends Node #tutorialA is the alpha version of the tutorial, i probably will use it in the first final release
#difficulty
@export var trial_time : int = 30
@export var density_increase : int = 15
@export var peak_increase : int = 1

@export var all_seeing_attacks: MultiMeshInstance2D
@export var check_status: Timer
@export var close_in: MultiMeshInstance2D
@export var close_in2: MultiMeshInstance2D

var expectations : bool = false
var hopelesness : bool = false
var failed_first_test : bool = false
var increase_difficulty : bool = true
var start_check : bool = true

var difficulty_index : int = 0
var try_index : int = 0

var narration : PackedStringArray = ["\" Why? \"\nYou might ask", "This world is empty, slowly dying...\nand must be fixed", "You have been born for that purpose"]
var fail_on_start_narration : PackedStringArray = ["Let's try that again", "You have a duty, and must stay focused if you want to survive", "You have to keep the world together..."]

func _ready() -> void:
	Main.SetBackgroundColor(Color.BLACK)

	check_status.timeout.connect(CheckStatus)
	print(check_status.timeout.is_connected(CheckStatus))

	Main.player.focus_speed = Main.player.normal_speed #disable focus
	Main.player.fire_rate = 0 #and shooting
	Main.player.BombReady(false) #and bomb
	Main.GameStart($Spawn.global_position)
	$Spawn.free()

	all_seeing_attacks.RePooling()
	close_in.RePooling()
	close_in2.RePooling()
	Main.narrator.Talk(". . .")
	FadeModulator.call_deferred(&"ShowAt", "res://scenes/display_scenes/basic_movement_tutorial.tscn", str(Main.screen_slots) + "/Half/2")


func _process(_delta: float) -> void:
	if Input.is_anything_pressed() && start_check:
		start_check = false
		FadeModulator.ExitAt(str(Main.screen_slots) + "/Half/2")
		Main.narrator.Talk("You are awake...\nAbout time")

		while Main.narrator.IsTalking():
				await get_tree().process_frame

		print("Reached first point waited")
		Main.player.player_hit.connect(IsHit)
		Main.narrator.LoadNarration(narration)
		StartTest()

func CheckStatus():
	print("Results coming in...")
	if difficulty_index < 3:
		all_seeing_attacks.ClearSpawner()
		await all_seeing_attacks.spawner_cleared
	else:
		all_seeing_attacks.StopShooting()
		all_seeing_attacks.movement_preset = all_seeing_attacks.MovementType.none

	if increase_difficulty:
		PassedTest()
		if expectations:
			return
	else:
		FailedTest()
		if hopelesness:
			return

	Main.narrator.Talk()
	if (Main.narrator.IsTalking()):
		await Main.narrator.finished_talking
	StartTest()

func PassedTest():
	print("Passed")
	all_seeing_attacks.bullet_density += density_increase
	all_seeing_attacks.movement_peaks += peak_increase
	all_seeing_attacks.angular_velocity = -all_seeing_attacks.angular_velocity

	if (difficulty_index >= 3):
		print("No hit 0 bombs")
		expectations = true
		Main.narrator.Talk("I expect much from you.")
		ContinueTutorial()
		return

	all_seeing_attacks.RePooling()
	try_index = 0
	difficulty_index += 1
	increase_difficulty = true

func FailedTest():
	print("loser")
	if (difficulty_index >= 3 ):
		hopelesness = true
		Main.narrator.Talk("Even if it ends up in disappointment, try.")
		ContinueTutorial()
		return

	elif (try_index >= 2 && Main.narrator.GetNarrationInOrder()[0] == -1):
		hopelesness = true
		Main.narrator.Talk("... fill the void with a noble sacrifice.")
		ContinueTutorial()
		return

	increase_difficulty = true
	try_index += 1

func StartBonus():
	var boss = load("res://scenes/tutorial_a/all_seeing_boss.tscn").instantiate()
	
	close_in.SetSpawner()
	close_in2.SetSpawner()
	$AllSeeing.add_child(boss)
	boss.boss_death.connect(TutorialEnd)

func StartTest():
	print("Initiating test...")
	check_status.start(trial_time)
	all_seeing_attacks.SetSpawner()

func IsHit():
		if (difficulty_index == 0):
			print("Hit on first test")
			failed_first_test = true
			FailedOnStart()
			return

		increase_difficulty = false

func ContinueTutorial(): #Show how to shoot, focus, and move the all seeing
	FadeModulator.ShowAt("res://scenes/display_scenes/basic_shoot_and_focus_tutorial.tscn", str(Main.screen_slots) + "/Half/2")

	if check_status.timeout.is_connected(CheckStatus):
		check_status.timeout.disconnect(CheckStatus)

	$AllSeeing.Move()
	
	all_seeing_attacks.StopShooting()
	all_seeing_attacks.allow_collision = false
	all_seeing_attacks.movement_preset = all_seeing_attacks.MovementType.set_speed
	Main.ResetPlayerSettings()
	
	while !(Input.is_action_pressed("focus") && Input.is_action_pressed("shoot")):
		await get_tree().process_frame

	FadeModulator.ExitAt(str(Main.screen_slots) + "/Half/2")
	all_seeing_attacks.KillSpawner()

	if (expectations): #FIGHT
		StartBonus()
		return
	else:
		$AllSeeing.enemy_destroyed.connect(TutorialEnd)
		$AllSeeing.monitorable = true


func FailedOnStart(): #enable and show how to focus
	check_status.stop()
	difficulty_index = 1

	all_seeing_attacks.angular_velocity += 2
	all_seeing_attacks.movement_preset = all_seeing_attacks.MovementType.reverse_bloom
	all_seeing_attacks.StopShooting()

	Main.narrator.LoadNarration(fail_on_start_narration)
	Main.narrator.Talk()
	
	all_seeing_attacks.ClearSpawner()
	await all_seeing_attacks.spawner_cleared

	all_seeing_attacks.RePooling()
	Main.ResetPlayerSettings()
	Main.player.fire_rate = 0
	FadeModulator.ShowAt("res://scenes/display_scenes/basic_focus_tutorial.tscn", str(Main.screen_slots) + "/Half/2")

	while !Input.is_action_just_pressed(&"focus"):
		await get_tree().process_frame
	
	FadeModulator.ExitAt(str(Main.screen_slots) + "/Half/2")
	StartTest()

func TutorialEnd():
	Main.player.BombReady(true)

	Main.narrator.Talk("I'll be watching over you, if you need me.")
	FadeModulator.ShowAt("res://scenes/display_scenes/ship_action_tutorial.tscn", str(Main.screen_slots) + "/Half/2")
	$CloseIn.StopShooting()
	$CloseIn2.StopShooting()
	await Main.player.player_bomb_end

	FadeModulator.ExitAt(str(Main.screen_slots) + "/Half/2")
	Main.GameEnd()
