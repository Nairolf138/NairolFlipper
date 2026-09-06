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
    assert '[gd_scene load_steps=1 format=3]' in scene_text
    assert '[node name="Main" type="Node2D"]' in scene_text
