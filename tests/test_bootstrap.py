from pathlib import Path


ROOT = Path(__file__).parents[1]
PROJECT = ROOT / "project.godot"
MAIN_SCENE = ROOT / "scenes" / "app" / "Main.tscn"


def test_project_declares_existing_main_scene():
    project_text = PROJECT.read_text(encoding="utf-8")
    assert 'run/main_scene="res://scenes/app/Main.tscn"' in project_text
    assert MAIN_SCENE.is_file()


def test_bootstrap_scene_has_node2d_root():
    scene_text = MAIN_SCENE.read_text(encoding="utf-8")
    assert scene_text.startswith('[gd_scene load_steps=')
    assert ' format=3]' in scene_text.splitlines()[0]
    assert '[node name="Main" type="Node2D"]' in scene_text


def test_project_declares_keyboard_actions_for_mvp_controls():
    project_text = PROJECT.read_text(encoding="utf-8")
    for action in ("flipper_left", "flipper_right", "launch_ball", "pause"):
        assert f"{action}={{" in project_text

    assert 'physical_keycode":65' in project_text
    assert 'physical_keycode":68' in project_text
    assert 'physical_keycode":32' in project_text
    assert 'physical_keycode":4194305' in project_text


def test_greybox_scene_declares_playfield_boundaries_and_launcher():
    scene_text = MAIN_SCENE.read_text(encoding="utf-8")
    for node_name in ("LeftWall", "RightWall", "TopWall", "Drain", "LauncherLane"):
        assert f'name="{node_name}"' in scene_text

    assert scene_text.count("type=\"StaticBody2D\"") >= 4
    assert scene_text.count("type=\"CollisionShape2D\"") == 5


def test_main_scene_declares_resettable_ball_instance():
    scene_text = MAIN_SCENE.read_text(encoding="utf-8")
    ball_scene = ROOT / "scenes" / "gameplay" / "Ball.tscn"
    ball_script = ROOT / "scripts" / "gameplay" / "ball.gd"

    assert ball_scene.is_file()
    assert ball_script.is_file()
    assert 'type="RigidBody2D"' in ball_scene.read_text(encoding="utf-8")
    assert 'ext_resource' in ball_scene.read_text(encoding="utf-8")
    assert 'Ball.tscn' in scene_text
    assert "reset_ball" in ball_script.read_text(encoding="utf-8")
    assert "continuous_cd = 2" in ball_scene.read_text(encoding="utf-8")


def test_main_scene_declares_two_pressable_flippers():
    scene_text = MAIN_SCENE.read_text(encoding="utf-8")
    flipper_scene = ROOT / "scenes" / "gameplay" / "Flipper.tscn"
    flipper_script = ROOT / "scripts" / "gameplay" / "flipper.gd"

    assert flipper_scene.is_file()
    assert flipper_script.is_file()
    assert scene_text.count('parent="." instance=ExtResource("2_flipper")') == 2
    assert 'name="LeftFlipper"' in scene_text
    assert 'name="RightFlipper"' in scene_text
    flipper_text = flipper_scene.read_text(encoding="utf-8")
    assert 'type="AnimatableBody2D"' in flipper_text
    assert 'type="CollisionShape2D"' in flipper_text
    script_text = flipper_script.read_text(encoding="utf-8")
    assert "Input.is_action_pressed" in script_text
    assert "action_name" in script_text
    assert "flipper_left" in scene_text
    assert "flipper_right" in scene_text
    assert 'rest_angle_degrees = 20.0' in scene_text
    assert 'active_angle_degrees = -25.0' in scene_text
    assert "@export var mirrored" in script_text
    assert "mirrored = true" in scene_text
    assert 'rest_angle_degrees = -20.0' in scene_text
    assert 'active_angle_degrees = 25.0' in scene_text


def test_ball_has_a_controlled_launcher_contract():
    ball_script = (ROOT / "scripts" / "gameplay" / "ball.gd").read_text(encoding="utf-8")
    ball_scene = (ROOT / "scenes" / "gameplay" / "Ball.tscn").read_text(encoding="utf-8")
    project_text = PROJECT.read_text(encoding="utf-8")

    assert "launch_ball" in project_text
    assert "launch_force" in ball_script
    assert "launch_ball()" in ball_script
    assert "launch_ready" in ball_script
    assert "Input.is_action_just_pressed" in ball_script
    assert "launch_force" in ball_scene


def test_ball_uses_shared_physics_tuning_resource():
    ball_script = (ROOT / "scripts" / "gameplay" / "ball.gd").read_text(encoding="utf-8")
    ball_scene = (ROOT / "scenes" / "gameplay" / "Ball.tscn").read_text(encoding="utf-8")
    tuning_script = (ROOT / "scripts" / "gameplay" / "physics_tuning.gd").read_text(encoding="utf-8")
    tuning_resource = ROOT / "data" / "tuning" / "PhysicsTuning.tres"

    assert tuning_resource.is_file()
    assert "class_name PhysicsTuning" in tuning_script
    assert "@export var max_speed" in tuning_script
    assert "@export var launch_direction" in tuning_script
    assert 'preload("res://scripts/gameplay/physics_tuning.gd")' in ball_script
    assert "@export var tuning: PhysicsTuningResource" in ball_script
    assert "_apply_tuning()" in ball_script
    assert "func _integrate_forces" in ball_script
    assert 'path="res://data/tuning/PhysicsTuning.tres"' in ball_scene


def test_weighted_feel_uses_distinct_passive_and_flipper_surfaces():
    tuning_text = (ROOT / "data" / "tuning" / "PhysicsTuning.tres").read_text(encoding="utf-8")
    ball_scene = (ROOT / "scenes" / "gameplay" / "Ball.tscn").read_text(encoding="utf-8")
    guide_scene = (ROOT / "scenes" / "gameplay" / "GuideRail.tscn").read_text(encoding="utf-8")
    flipper_scene = (ROOT / "scenes" / "gameplay" / "Flipper.tscn").read_text(encoding="utf-8")
    runner_text = (ROOT / "tests" / "godot" / "test_runner.gd").read_text(encoding="utf-8")

    for material_name in ("PassiveSurfaceMaterial.tres", "FlipperMaterial.tres"):
        assert (ROOT / "data" / "tuning" / material_name).is_file()
    assert "table_slope_degrees = 6.5" in tuning_text
    assert "bounce = 0.1" in tuning_text
    assert "launch_force = 2700.0" in tuning_text
    for node_name in ("ContactShadow", "Rim", "Highlight"):
        assert f'name="{node_name}"' in ball_scene
    assert "PassiveSurfaceMaterial.tres" in guide_scene
    assert "FlipperMaterial.tres" in flipper_scene
    assert "_test_weighted_pinball_feel" in runner_text


def test_android_playtest_configuration_is_portrait_and_has_session_controls():
    project_text = PROJECT.read_text(encoding="utf-8")
    scene_text = MAIN_SCENE.read_text(encoding="utf-8")
    main_text = (ROOT / "scripts" / "app" / "main.gd").read_text(encoding="utf-8")

    assert "window/handheld/orientation=1" in project_text
    for node_name in ("StartOverlay", "PlayButton", "ResetButton", "QuitButton"):
        assert f'name="{node_name}"' in scene_text
    assert "func start_game()" in main_text
    assert "func _on_reset_pressed()" in main_text
    assert "func _on_quit_pressed()" in main_text


def test_ball_save_safety_is_armed_on_launch_and_consumed_at_drain():
    ball_script = (ROOT / "scripts" / "gameplay" / "ball.gd").read_text(encoding="utf-8")
    main_script = (ROOT / "scripts" / "app" / "main.gd").read_text(encoding="utf-8")

    assert "ball_save_duration" in ball_script
    assert "ball_save_remaining" in ball_script
    assert "ball_save_remaining = ball_save_duration" in ball_script
    assert "func try_ball_save() -> bool" in ball_script
    assert "body.try_ball_save()" in main_script
    assert "body.reset_ball(body.spawn_position, false)" in main_script
    assert 'status_label.text = "SAFETY — MÊME BILLE — APPUYEZ SUR GO"' in main_script


def test_main_scene_declares_three_rhythmic_bumpers():
    scene_text = MAIN_SCENE.read_text(encoding="utf-8")
    bumper_scene = ROOT / "scenes" / "gameplay" / "Bumper.tscn"
    bumper_script = ROOT / "scripts" / "gameplay" / "bumper.gd"

    assert bumper_scene.is_file()
    assert bumper_script.is_file()
    assert scene_text.count('parent="." instance=ExtResource("3_bumper")') == 3
    for bumper_name in ("KickBumper", "SnareBumper", "TomBumper"):
        assert f'name="{bumper_name}"' in scene_text

    bumper_text = bumper_scene.read_text(encoding="utf-8")
    script_text = bumper_script.read_text(encoding="utf-8")
    assert 'type="Area2D"' in bumper_text
    assert 'type="CollisionShape2D"' in bumper_text
    assert "body_entered" in script_text
    assert "apply_central_impulse" in script_text
    assert "bumper_hit" in script_text
    assert "flash" in script_text


def test_main_scene_declares_score_manager_and_hud():
    scene_text = MAIN_SCENE.read_text(encoding="utf-8")
    score_script = ROOT / "scripts" / "gameplay" / "score_manager.gd"
    main_script = ROOT / "scripts" / "app" / "main.gd"

    assert score_script.is_file()
    assert main_script.is_file()
    assert 'name="ScoreManager"' in scene_text
    assert 'name="ScoreLabel"' in scene_text
    assert 'type="Label"' in scene_text
    assert 'score_manager.gd' in scene_text
    assert "bumper_hit" in main_script.read_text(encoding="utf-8")


def test_score_manager_accumulates_and_resets_points():
    score_script = (ROOT / "scripts" / "gameplay" / "score_manager.gd").read_text(encoding="utf-8")

    assert "signal score_changed" in score_script
    assert "func add_points" in score_script
    assert "func reset_score" in score_script
    assert "score += points" in score_script
    assert "score = 0" in score_script
    assert "class_name ScoreManager" in score_script
    assert "ScoreManager" in (ROOT / "scripts" / "app" / "main.gd").read_text(encoding="utf-8")


def test_ball_lifecycle_declares_three_balls_drain_and_restart():
    scene_text = MAIN_SCENE.read_text(encoding="utf-8")
    main_script = (ROOT / "scripts" / "app" / "main.gd").read_text(encoding="utf-8")
    ball_script = (ROOT / "scripts" / "gameplay" / "ball.gd").read_text(encoding="utf-8")

    assert scene_text.count('parent="." instance=ExtResource("1_ball")') == 3
    assert 'body_entered.connect' in main_script
    assert "ball_drained" in ball_script
    assert "remaining_balls" in main_script
    assert "game_over" in main_script
    assert "restart_game" in main_script
    assert "respawn_delay" in main_script


def test_mobile_touch_controls_cover_flippers_and_launcher():
    main_script = (ROOT / "scripts" / "app" / "main.gd").read_text(encoding="utf-8")

    assert "InputEventScreenTouch" in main_script
    assert "InputEventScreenDrag" in main_script
    assert "touch_position.x" in main_script
    assert "Input.action_press" in main_script
    assert "Input.action_release" in main_script
    assert 'event.is_action_pressed("launch_ball")' in main_script


def test_controller_actions_cover_flippers_and_launcher():
    project_text = PROJECT.read_text(encoding="utf-8")

    assert "InputEventJoypadButton" in project_text
    assert '"button_index":2' in project_text
    assert '"button_index":3' in project_text
    assert '"button_index":0' in project_text


def test_restart_activates_only_one_ball_and_disables_the_rest():
    main_script = (ROOT / "scripts" / "app" / "main.gd").read_text(encoding="utf-8")

    assert "_deactivate_all_balls()" in main_script
    assert "balls[active_ball_index].reset_ball(" in main_script


def test_local_playtest_recorder_tracks_session_events_without_networking():
    recorder = ROOT / "scripts" / "app" / "playtest_recorder.gd"
    main_script = (ROOT / "scripts" / "app" / "main.gd").read_text(encoding="utf-8")
    scene_text = MAIN_SCENE.read_text(encoding="utf-8")
    recorder_text = recorder.read_text(encoding="utf-8")

    assert recorder.is_file()
    assert 'SAVE_PATH := "user://playtest/latest.json"' in recorder_text
    assert "JSON.stringify" in recorder_text
    assert "record_launch" in recorder_text
    assert "record_bumper_hit" in recorder_text
    assert "record_drain" in recorder_text
    assert "record_ball_save" in recorder_text
    assert "record_restart" in recorder_text
    assert "record_sync" in recorder_text
    assert "HTTPRequest" not in recorder_text
    assert 'name="PlaytestRecorder"' in scene_text
    for event in ("record_launch", "record_bumper_hit", "record_drain", "record_ball_save", "record_restart", "record_sync"):
        assert event in main_script


def test_rig_model_declares_six_data_driven_fixture_families():
    scene_text = MAIN_SCENE.read_text(encoding="utf-8")
    rig_script = ROOT / "scripts" / "show" / "rig_model.gd"
    definition_script = ROOT / "scripts" / "show" / "rig_definition.gd"
    rig_data = ROOT / "data" / "rig"

    assert rig_script.is_file()
    assert definition_script.is_file()
    assert 'name="RigModel"' in scene_text
    assert "rig_family_activated" in rig_script.read_text(encoding="utf-8")
    assert 'preload("res://scripts/show/rig_definition.gd")' in rig_script.read_text(encoding="utf-8")
    assert "@export var families: Array[RigDefinitionResource]" in rig_script.read_text(encoding="utf-8")
    assert "activate_family" in rig_script.read_text(encoding="utf-8")
    for family_file in ("FrontWash.tres", "BackWash.tres", "Beam.tres", "Pixel.tres", "Blinders.tres", "Practical.tres"):
        assert (rig_data / family_file).is_file()
    assert scene_text.count('ExtResource("') >= 13


def test_cue_definition_declares_data_driven_show_payload():
    cue_script = ROOT / "scripts" / "show" / "cue_definition.gd"

    assert cue_script.is_file()
    cue_text = cue_script.read_text(encoding="utf-8")
    assert "class_name CueDefinition" in cue_text
    for field in (
        "cue_id",
        "display_name",
        "objective_text",
        "conditions",
        "light_changes",
        "audio_changes",
        "bonus_points",
        "duration_seconds",
    ):
        assert f"@export var {field}" in cue_text
    assert "var condition_repetitions" in cue_text
    for filename, cue_id in (
        ("color_wash.tres", "color_wash"),
        ("universe_chase.tres", "universe_chase"),
        ("rhythm_drop.tres", "rhythm_drop"),
    ):
        data_text = (ROOT / "data" / "cues" / filename).read_text(encoding="utf-8")
        assert 'script_class="CueDefinition"' in data_text
        assert f'cue_id = &"{cue_id}"' in data_text


def test_cue_manager_executes_eligible_cues_and_emits_show_payloads():
    manager = ROOT / "scripts" / "show" / "cue_manager.gd"
    scene_text = MAIN_SCENE.read_text(encoding="utf-8")
    manager_text = manager.read_text(encoding="utf-8")

    assert manager.is_file()
    assert 'name="CueManager"' in scene_text
    assert 'preload("res://scripts/show/cue_definition.gd")' in manager_text
    assert "Array[CueDefinitionResource]" in manager_text
    for signal_name in (
        "cue_started",
        "cue_completed",
        "stack_progress_changed",
        "stack_completed",
        "light_changes_requested",
        "audio_changes_requested",
        "bonus_awarded",
    ):
        assert f"signal {signal_name}" in manager_text
    for method_name in (
        "set_conditions",
        "start_current_cue",
        "current_cue_ready",
        "is_stack_completed",
        "complete_current_cue",
        "_conditions_met",
    ):
        assert f"func {method_name}" in manager_text
    assert "duration_seconds" in manager_text
    assert "bonus_points" in manager_text


def test_warm_and_cold_ramps_are_data_driven_and_feed_flow():
    scene_text = MAIN_SCENE.read_text(encoding="utf-8")
    ramp_scene = ROOT / "scenes" / "gameplay" / "Ramp.tscn"
    ramp_script = ROOT / "scripts" / "show" / "ramp.gd"
    definition_script = ROOT / "scripts" / "show" / "ramp_definition.gd"
    main_script = (ROOT / "scripts" / "app" / "main.gd").read_text(encoding="utf-8")

    assert ramp_scene.is_file()
    assert ramp_script.is_file()
    assert definition_script.is_file()
    assert 'name="WarmRamp"' in scene_text
    assert 'name="ColdRamp"' in scene_text
    assert 'groups=["show_ramps"]' in ramp_scene.read_text(encoding="utf-8")
    assert "ramp_completed" in ramp_script.read_text(encoding="utf-8")
    assert "ramp_id" in definition_script.read_text(encoding="utf-8")
    assert "_on_ramp_completed" in main_script
    assert "flow_manager.add_flow(flow_value)" in main_script
    assert 'groups=["balls"]' in (ROOT / "scenes/gameplay/Ball.tscn").read_text(encoding="utf-8")
    for route in ("WarmRoute.tres", "ColdRoute.tres", "OrbitRoute.tres"):
        assert (ROOT / "data/routes" / route).is_file()
    for ramp_file, ramp_id, color in (
        ("WarmRamp.tres", "warm_ramp", "1, 0.48, 0.12"),
        ("ColdRamp.tres", "cold_ramp", "0.12, 0.72, 1"),
    ):
        ramp_text = (ROOT / "data" / "ramps" / ramp_file).read_text(encoding="utf-8")
        assert f'ramp_id = &"{ramp_id}"' in ramp_text
        assert f'ramp_color = Color({color}, 1)' in ramp_text


def test_console_scoop_validates_cue_and_awards_show_progression():
    scene_text = MAIN_SCENE.read_text(encoding="utf-8")
    scoop_scene = ROOT / "scenes" / "gameplay" / "ConsoleScoop.tscn"
    scoop_script = ROOT / "scripts" / "show" / "console_scoop.gd"
    main_script = (ROOT / "scripts" / "app" / "main.gd").read_text(encoding="utf-8")
    color_cue = (ROOT / "data" / "cues" / "color_wash.tres").read_text(encoding="utf-8")
    orbit_cue = (ROOT / "data" / "cues" / "universe_chase.tres").read_text(encoding="utf-8")
    rhythm_cue = (ROOT / "data" / "cues" / "rhythm_drop.tres").read_text(encoding="utf-8")

    assert scoop_scene.is_file()
    assert scoop_script.is_file()
    assert 'name="ConsoleScoop"' in scene_text
    assert 'groups=["console_scoops"]' in scoop_scene.read_text(encoding="utf-8")
    scoop_text = scoop_script.read_text(encoding="utf-8")
    for signal_name in ("scoop_completed",):
        assert f"signal {signal_name}" in scoop_text
    for field in ("scoop_id", "score_value", "flow_value", "rearm_delay"):
        assert f"@export var {field}" in scoop_text
    assert "body.is_in_group(\"balls\")" in scoop_text
    assert "cue_manager.add_condition" in main_script
    assert "cue_manager.start_current_cue" in main_script
    assert 'conditions = [&"warm_ramp", &"cold_ramp"]' in color_cue
    assert 'conditions = [&"universe_orbit"]' in orbit_cue
    assert "condition_repetitions = 2" in orbit_cue
    assert 'conditions = [&"bumper_hit"]' in rhythm_cue
    assert "condition_repetitions = 4" in rhythm_cue
    for node_name in ("CueProgressLabel", "ConsoleScoop"):
        assert f'name="{node_name}"' in scene_text
    assert "func _try_arm_final_show" in main_script
    assert "not cue_manager.is_stack_completed()" in main_script


def test_flow_manager_tracks_forgiving_multiplier_progression():
    flow_script = ROOT / "scripts" / "show" / "flow_manager.gd"
    main_script = (ROOT / "scripts" / "app" / "main.gd").read_text(encoding="utf-8")
    scene_text = MAIN_SCENE.read_text(encoding="utf-8")
    flow_text = flow_script.read_text(encoding="utf-8")

    assert flow_script.is_file()
    assert 'class_name FlowManager' in flow_text
    assert 'signal flow_changed' in flow_text
    assert 'signal multiplier_changed' in flow_text
    assert 'multipliers: Array[int] = [1, 2, 3, 4, 6, 8]' in flow_text
    assert 'func add_flow' in flow_text
    assert 'func decay_flow' in flow_text
    assert 'func reset_flow' in flow_text
    assert 'name="FlowManager"' in scene_text
    assert 'name="FlowLabel"' in scene_text
    assert 'flow_manager.add_flow(points)' in main_script
    assert 'flow_manager.reset_flow()' in main_script


def test_audio_service_plays_original_placeholder_sfx():
    audio_script = ROOT / "scripts" / "audio" / "audio_service.gd"
    scene_text = MAIN_SCENE.read_text(encoding="utf-8")
    main_script = (ROOT / "scripts" / "app" / "main.gd").read_text(encoding="utf-8")
    cue_text = (ROOT / "data" / "cues" / "color_wash.tres").read_text(encoding="utf-8")

    assert audio_script.is_file()
    audio_text = audio_script.read_text(encoding="utf-8")
    assert 'class_name AudioService' in audio_text
    assert 'signal mix_changed' in audio_text
    assert 'signal stems_changed' in audio_text
    assert 'func apply_cue_changes' in audio_text
    assert 'func request_sfx' in audio_text
    assert "AudioStreamPlayer.new()" in audio_text
    assert 'player.bus = &"SFX"' in audio_text
    assert 'name="AudioService"' in scene_text
    assert 'audio_changes_requested.connect(audio_service.apply_cue_changes)' in main_script
    assert 'audio_changes = {"stems"' in cue_text
    sfx_dir = ROOT / "assets" / "audio" / "sfx"
    for filename in (
        "flipper.wav",
        "launcher.wav",
        "kick_bumper.wav",
        "snare_bumper.wav",
        "tom_bumper.wav",
        "ramp.wav",
        "scoop.wav",
        "cue.wav",
        "sync.wav",
        "safety.wav",
        "drain.wav",
    ):
        assert (sfx_dir / filename).is_file()


def test_audio_service_exposes_a_looping_logical_music_transport():
    audio_text = (ROOT / "scripts" / "audio" / "audio_service.gd").read_text(encoding="utf-8")

    assert "@export_range(20.0, 240.0, 1.0) var bpm" in audio_text
    assert "@export_range(1.0, 256.0, 1.0) var loop_beats" in audio_text
    assert "signal transport_changed" in audio_text
    assert "signal transport_looped" in audio_text
    assert "func start_transport()" in audio_text
    assert "func stop_transport(reset_position: bool = false)" in audio_text
    assert "func seek_transport(position_beats: float)" in audio_text
    assert "fmod(transport_position_beats, loop_beats)" in audio_text
    assert "AudioServer" in audio_text


def test_export_presets_cover_p0_platforms_without_secrets():
    presets = ROOT / "export_presets.cfg"
    assert presets.is_file()
    preset_text = presets.read_text(encoding="utf-8")

    for platform in ("Web", "Android", "Windows Desktop"):
        assert f'name="{platform}"' in preset_text
    project_text = PROJECT.read_text(encoding="utf-8")
    assert 'config/name="NairolFlipper"' in project_text
    assert "textures/vram_compression/import_etc2_astc=true" in project_text
    assert "keystore" not in preset_text.lower()
    assert "password" not in preset_text.lower()


def test_ci_validates_contract_and_headless_godot_load():
    workflow = ROOT / ".github" / "workflows" / "godot.yml"
    assert workflow.is_file()
    workflow_text = workflow.read_text(encoding="utf-8")

    assert "pytest" in workflow_text
    assert "--import" in workflow_text
    assert "--headless" in workflow_text
    assert "tests/godot/test_runner.gd" in workflow_text
    assert "assert_clean_godot_log.sh" in workflow_text
    assert "--export-release" in workflow_text
    assert '--export-release "Web"' in workflow_text
    assert '--export-debug "Android"' in workflow_text
    assert '--export-release "Windows Desktop"' in workflow_text
    assert "mkdir -p build/web build/android build/windows" in workflow_text


def test_main_scene_references_the_declared_flow_and_rig_types():
    scene_text = MAIN_SCENE.read_text(encoding="utf-8")

    assert 'path="res://scripts/show/flow_manager.gd" id="18_flow"' in scene_text
    assert 'script = ExtResource("18_flow")' in scene_text
    assert 'script = ExtResource("17_flow")' not in scene_text
    assert 'path="res://scripts/show/rig_definition.gd" id="7_rig_definition"' in scene_text
    assert 'families = Array[ExtResource("7_rig_definition")]' in scene_text


def test_godot_behavioral_runner_covers_scoring_and_session_reset():
    runner = ROOT / "tests" / "godot" / "test_runner.gd"
    assert runner.is_file()
    runner_text = runner.read_text(encoding="utf-8")

    assert "_test_flow_decay_and_multiplier" in runner_text
    assert "_test_cue_stack_progression" in runner_text
    assert "_test_main_scene_scoring_and_reset" in runner_text

def test_session_lifecycle_blocks_phantom_balls_and_exposes_game_over():
    scene_text = MAIN_SCENE.read_text(encoding="utf-8")
    main_text = (ROOT / "scripts" / "app" / "main.gd").read_text(encoding="utf-8")
    ball_text = (ROOT / "scripts" / "gameplay" / "ball.gd").read_text(encoding="utf-8")

    for node_name in ("GameOverOverlay", "FinalScoreLabel", "ReplayButton", "MenuButton"):
        assert f'name="{node_name}"' in scene_text
    assert "enum SessionState" in main_text
    assert "func _show_game_over()" in main_text
    assert "func _recover_active_ball" in main_text
    assert "body != balls[active_ball_index]" in main_text
    assert "func deactivate_ball()" in ball_text
    assert 'collision_shape.set_deferred("disabled", true)' in ball_text
    assert "reset_ball(body.spawn_position, false)" in main_text



def test_table_2_greybox_adds_playfield_routes_and_rig_objective():
    scene_text = MAIN_SCENE.read_text(encoding="utf-8")
    main_text = (ROOT / "scripts" / "app" / "main.gd").read_text(encoding="utf-8")
    rig_target = ROOT / "scripts" / "show" / "rig_target.gd"
    lane_trigger = ROOT / "scripts" / "gameplay" / "lane_trigger.gd"
    slingshot = ROOT / "scripts" / "gameplay" / "slingshot.gd"
    guide_rail = ROOT / "scenes" / "gameplay" / "GuideRail.tscn"

    for path in (rig_target, lane_trigger, slingshot, guide_rail):
        assert path.is_file()
    assert scene_text.count('parent="." instance=ExtResource("23_rig_target")') == 6
    for node_name in (
        "UniverseOrbit",
        "LeftSlingshot",
        "RightSlingshot",
        "LeftOutlaneRail",
        "RightOutlaneRail",
        "LauncherDivider",
        "RigProgressLabel",
        "TableTitle",
    ):
        assert f'name="{node_name}"' in scene_text
    assert 'groups=["rig_targets"]' in (ROOT / "scenes" / "gameplay" / "RigTarget.tscn").read_text(encoding="utf-8")
    assert 'groups=["table_lanes"]' in (ROOT / "scenes" / "gameplay" / "LaneTrigger.tscn").read_text(encoding="utf-8")
    assert 'groups=["slingshots"]' in (ROOT / "scenes" / "gameplay" / "Slingshot.tscn").read_text(encoding="utf-8")
    assert "signal target_hit" in rig_target.read_text(encoding="utf-8")
    assert "signal lane_completed" in lane_trigger.read_text(encoding="utf-8")
    assert "apply_central_impulse" in slingshot.read_text(encoding="utf-8")
    for handler in ("_on_rig_target_hit", "_on_lane_completed", "_on_slingshot_hit", "_update_rig_progress"):
        assert f"func {handler}" in main_text


def test_playfield_geometry_closes_edges_and_separates_return_lanes():
    scene_text = MAIN_SCENE.read_text(encoding="utf-8")
    runner_text = (ROOT / "tests" / "godot" / "test_runner.gd").read_text(encoding="utf-8")

    assert scene_text.count("size = Vector2(40, 1840)") == 2
    for node_name in (
        "UpperLeftGuide",
        "LauncherOuterGuide",
        "LeftOutlaneRail",
        "LeftReturnRail",
        "RightReturnRail",
        "RightOutlaneRail",
        "LauncherDivider",
        "LeftReturnExtension",
        "RightReturnExtension",
    ):
        assert f'name="{node_name}"' in scene_text
    assert "position = Vector2(682.5, 1452.5)" in scene_text
    assert "position = Vector2(820, 1495)" in scene_text
    assert "_test_playfield_safe_trajectories" in runner_text


def test_showflow_final_show_multiball_and_blackout_are_explicit():
    scene_text = MAIN_SCENE.read_text(encoding="utf-8")
    main_text = (ROOT / "scripts" / "app" / "main.gd").read_text(encoding="utf-8")
    show_flow = ROOT / "scripts" / "show" / "show_flow_manager.gd"
    runner_text = (ROOT / "tests" / "godot" / "test_runner.gd").read_text(encoding="utf-8")

    assert show_flow.is_file()
    flow_text = show_flow.read_text(encoding="utf-8")
    for state in ("STANDBY", "PRESET", "BUILD", "FLOW", "FINAL_SHOW", "BLACKOUT"):
        assert state in flow_text
    for method in ("begin_build", "arm_final_show", "start_final_show", "start_blackout", "finish_blackout"):
        assert f"func {method}" in flow_text
    for node_name in ("ShowFlowManager", "ShowStateLabel", "FinalShowLabel", "BlackoutOverlay"):
        assert f'name="{node_name}"' in scene_text
    assert "multiball_active" in main_text
    assert "func _start_final_show" in main_text
    assert "func _finish_final_show" in main_text
    assert "final_show_score_multiplier" in main_text
    assert "_test_show_flow_state_machine" in runner_text
    assert "_test_final_show_multiball_and_blackout" in runner_text


def test_stage_identity_uses_original_synchronized_music_stems():
    scene_text = MAIN_SCENE.read_text(encoding="utf-8")
    main_text = (ROOT / "scripts" / "app" / "main.gd").read_text(encoding="utf-8")
    audio_text = (ROOT / "scripts" / "audio" / "audio_service.gd").read_text(encoding="utf-8")
    stem_set = ROOT / "scripts" / "audio" / "audio_stem_set.gd"
    stage_visuals = ROOT / "scripts" / "show" / "stage_visual_controller.gd"
    stage_loop = ROOT / "data" / "audio" / "StageLoop.tres"
    runner_text = (ROOT / "tests" / "godot" / "test_runner.gd").read_text(encoding="utf-8")

    assert stem_set.is_file()
    assert stage_visuals.is_file()
    assert stage_loop.is_file()
    assert 'name="StageVisuals"' in scene_text
    assert 'stem_set = ExtResource("29_stage_loop")' in scene_text
    assert "func set_stem_mix" in audio_text
    assert "AudioStreamPlayer.new()" in audio_text
    assert "func _update_stage_identity" in main_text
    assert "stage_visuals.set_show_state" in main_text
    assert "_test_stage_identity_and_music_stems" in runner_text

    music_dir = ROOT / "assets" / "audio" / "music"
    for filename in (
        "atmosphere.ogg",
        "piano.ogg",
        "kick.ogg",
        "percussion.ogg",
        "bass.ogg",
        "arp.ogg",
        "lead.ogg",
        "impact.ogg",
    ):
        assert (music_dir / filename).is_file()


def test_stagecraft_visual_pass_is_layered_and_mobile_safe():
    scene_text = MAIN_SCENE.read_text(encoding="utf-8")
    art_script = ROOT / "scripts" / "show" / "playfield_visual_controller.gd"
    stage_script = ROOT / "scripts" / "show" / "stage_visual_controller.gd"
    theme = ROOT / "data" / "ui" / "StageTheme.tres"
    runner_text = (ROOT / "tests" / "godot" / "test_runner.gd").read_text(encoding="utf-8")

    assert art_script.is_file()
    assert theme.is_file()
    assert 'name="PlayfieldArt"' in scene_text
    assert 'path="res://data/ui/StageTheme.tres"' in scene_text
    assert "_draw_shot_routes" in art_script.read_text(encoding="utf-8")
    assert "_draw_launcher_lane" in art_script.read_text(encoding="utf-8")
    assert "_draw_drain_apron" in art_script.read_text(encoding="utf-8")
    assert "_draw_haze" in stage_script.read_text(encoding="utf-8")
    assert "_draw_footlights" in stage_script.read_text(encoding="utf-8")

    visual_parts = {
        "GuideRail.tscn": ("MetalFace", "EdgeLight"),
        "Flipper.tscn": ("TopFace", "MetalSpine", "PivotCap"),
        "Bumper.tscn": ("Bezel", "Lens", "LensHighlight"),
        "RigTarget.tscn": ("MetalFrame", "Indicator"),
        "Ramp.tscn": ("Deck", "EntryEdge"),
        "ConsoleScoop.tscn": ("Faceplate", "GoStrip"),
    }
    for filename, node_names in visual_parts.items():
        content = (ROOT / "scenes" / "gameplay" / filename).read_text(encoding="utf-8")
        for node_name in node_names:
            assert f'name="{node_name}"' in content

    # The pass remains vector-only and does not add a costly full-screen shader.
    assert "shader_type" not in art_script.read_text(encoding="utf-8")
    assert "_test_stagecraft_visual_language" in runner_text


def test_sync_bonus_rewards_timing_without_punishing_normal_shots():
    scene_text = MAIN_SCENE.read_text(encoding="utf-8")
    main_text = (ROOT / "scripts" / "app" / "main.gd").read_text(encoding="utf-8")
    audio_text = (ROOT / "scripts" / "audio" / "audio_service.gd").read_text(encoding="utf-8")
    sync_script = ROOT / "scripts" / "show" / "sync_bonus_manager.gd"
    stage_text = (ROOT / "scripts" / "show" / "stage_visual_controller.gd").read_text(encoding="utf-8")
    runner_text = (ROOT / "tests" / "godot" / "test_runner.gd").read_text(encoding="utf-8")

    assert sync_script.is_file()
    sync_text = sync_script.read_text(encoding="utf-8")
    assert "class_name SyncBonusManager" in sync_text
    assert "signal sync_awarded" in sync_text
    assert "perfect_window_beats" in sync_text
    assert "sync_window_beats" in sync_text
    assert "func register_hit" in sync_text
    assert 'name="SyncBonusManager"' in scene_text
    assert 'name="SyncFeedbackLabel"' in scene_text
    assert "transport_total_beats" in audio_text
    assert 'request_sfx(&"sync")' in main_text
    assert "func _draw_sync_clock" in stage_text
    assert "_test_sync_bonus_timing" in runner_text
    assert "_test_sync_bonus_integration" in runner_text
    assert "Off-beat shots keep all normal gameplay points" in runner_text


def test_audio_settings_are_accessible_persistent_and_platform_local():
    scene_text = MAIN_SCENE.read_text(encoding="utf-8")
    main_text = (ROOT / "scripts" / "app" / "main.gd").read_text(encoding="utf-8")
    settings_script = ROOT / "scripts" / "app" / "settings_store.gd"
    runner_text = (ROOT / "tests" / "godot" / "test_runner.gd").read_text(encoding="utf-8")

    assert settings_script.is_file()
    settings_text = settings_script.read_text(encoding="utf-8")
    assert "class_name SettingsStore" in settings_text
    assert 'DEFAULT_SAVE_PATH := "user://settings.json"' in settings_text
    assert "func load_settings()" in settings_text
    assert "func save_settings()" in settings_text
    assert "func percent_to_db" in settings_text
    assert "AudioServer.set_bus_mute" in (ROOT / "scripts" / "audio" / "audio_service.gd").read_text(encoding="utf-8")
    for node_name in (
        "SettingsStore",
        "SettingsButton",
        "SettingsPanel",
        "MasterSlider",
        "MusicSlider",
        "SFXSlider",
        "DefaultsButton",
        "BackButton",
    ):
        assert f'name="{node_name}"' in scene_text
    assert "func _open_audio_settings" in main_text
    assert "func _close_audio_settings" in main_text
    assert "audio_service.set_mix" in main_text
    assert "_test_audio_settings_persistence" in runner_text
    assert "_test_audio_settings_menu" in runner_text


def test_flashing_effects_setting_is_persistent_and_keeps_readable_feedback():
    scene_text = MAIN_SCENE.read_text(encoding="utf-8")
    main_text = (ROOT / "scripts" / "app" / "main.gd").read_text(encoding="utf-8")
    settings_text = (ROOT / "scripts" / "app" / "settings_store.gd").read_text(encoding="utf-8")
    runner_text = (ROOT / "tests" / "godot" / "test_runner.gd").read_text(encoding="utf-8")

    assert "SCHEMA_VERSION := 2" in settings_text
    assert "visual_settings_changed" in settings_text
    assert "func set_flashing_effects" in settings_text
    assert '"accessibility"' in settings_text
    assert 'name="FlashingEffectsOption"' in scene_text
    assert "COMPLETS" in main_text
    assert "RÉDUITS" in main_text
    assert "DÉSACTIVÉS" in main_text
    assert "func _apply_visual_settings" in main_text
    assert "func _show_blackout_feedback" in main_text

    reactive_scripts = (
        ROOT / "scripts" / "show" / "stage_visual_controller.gd",
        ROOT / "scripts" / "gameplay" / "bumper.gd",
        ROOT / "scripts" / "gameplay" / "lane_trigger.gd",
        ROOT / "scripts" / "gameplay" / "slingshot.gd",
        ROOT / "scripts" / "show" / "ramp.gd",
        ROOT / "scripts" / "show" / "rig_target.gd",
    )
    for script_path in reactive_scripts:
        assert "func set_flashing_effects" in script_path.read_text(encoding="utf-8")

    assert "_test_flashing_effects_accessibility" in runner_text
    assert "Off mode suppresses the hit flash" in runner_text
    assert "Off mode keeps the readable Sync clock contract" in runner_text


def test_playtest_has_consistent_version_and_french_action_copy():
    version = (ROOT / "VERSION").read_text(encoding="utf-8").strip()
    project_text = PROJECT.read_text(encoding="utf-8")
    export_text = (ROOT / "export_presets.cfg").read_text(encoding="utf-8")
    scene_text = MAIN_SCENE.read_text(encoding="utf-8")
    main_text = (ROOT / "scripts" / "app" / "main.gd").read_text(encoding="utf-8")
    runner_text = (ROOT / "tests" / "godot" / "test_runner.gd").read_text(encoding="utf-8")

    assert version == "0.1.0-alpha.1"
    assert 'config/version="0.1.0-alpha.1"' in project_text
    assert 'package/version="0.1.0-alpha.1"' in export_text
    assert 'application/file_version="0.1.0.0"' in export_text
    assert 'application/product_version="0.1.0-alpha.1"' in export_text
    assert "greybox" not in export_text.lower()
    assert "PLAYTEST 0.1.0" in scene_text
    assert "TABLE 2.3" not in scene_text
    assert "TABLE 2.4" not in scene_text

    for expected_copy in (
        "BILLE RÉCUPÉRÉE",
        "GO POUR LANCER",
        "CUE PRÊTE — VISEZ LA CONSOLE",
        "RIG PRÊT — TERMINEZ LA CUE STACK",
        "FINAL SHOW ARMÉ — VISEZ LA CONSOLE",
        "PARTIE TERMINÉE",
    ):
        assert expected_copy in main_text
    for stale_copy in ("TOUCH TOP", "HIT CONSOLE", "GAME OVER", "3 BALLS"):
        assert stale_copy not in main_text

    assert "_test_alpha_candidate_player_journey" in runner_text


def test_how_to_play_explains_the_complete_show_loop_visually():
    scene_text = MAIN_SCENE.read_text(encoding="utf-8")
    main_text = (ROOT / "scripts" / "app" / "main.gd").read_text(encoding="utf-8")
    panel_scene = ROOT / "scenes" / "ui" / "HowToPlayPanel.tscn"
    panel_script = ROOT / "scripts" / "ui" / "how_to_play_panel.gd"
    diagram_script = ROOT / "scripts" / "ui" / "how_to_play_diagram.gd"
    runner_text = (ROOT / "tests" / "godot" / "test_runner.gd").read_text(encoding="utf-8")

    for path in (panel_scene, panel_script, diagram_script):
        assert path.is_file()
    assert 'name="HowToPlayButton"' in scene_text
    assert 'name="HowToPlayPanel"' in scene_text
    assert "func _open_how_to_play" in main_text
    assert "func _close_how_to_play" in main_text
    panel_text = panel_script.read_text(encoding="utf-8")
    for concept in ("LANCEZ ET JOUEZ", "CONSTRUISEZ LE RIG", "EXÉCUTEZ LES CUES", "LANCEZ LE FINAL SHOW"):
        assert concept in panel_text
    assert "const PAGES: Array[Dictionary]" in panel_text
    assert "func show_next_page" in panel_text
    diagram_text = diagram_script.read_text(encoding="utf-8")
    for drawing_method in ("_draw_controls", "_draw_rig", "_draw_cues", "_draw_final_show"):
        assert drawing_method in diagram_text
    assert "_test_how_to_play_menu" in runner_text
