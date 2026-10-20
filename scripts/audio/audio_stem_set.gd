class_name AudioStemSet
extends Resource

@export var atmosphere: AudioStream
@export var piano: AudioStream
@export var kick: AudioStream
@export var percussion: AudioStream
@export var bass: AudioStream
@export var arp: AudioStream
@export var lead: AudioStream
@export var impact: AudioStream


func streams() -> Dictionary:
	return {
		&"atmosphere": atmosphere,
		&"piano": piano,
		&"kick": kick,
		&"percussion": percussion,
		&"bass": bass,
		&"arp": arp,
		&"lead": lead,
		&"impact": impact,
	}
