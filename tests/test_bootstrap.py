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
