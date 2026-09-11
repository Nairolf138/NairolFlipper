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

    assert scene_text.count("type=\"StaticBody2D\"") == 4
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
    assert "continuous_cd = 1" in ball_scene.read_text(encoding="utf-8")


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
