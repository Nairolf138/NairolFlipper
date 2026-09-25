# Rig data

Les six familles de fixtures du rig sont décrites par des `RigDefinition`.
Le `RigModel` conserve uniquement l'état de la session et émet
`rig_family_activated`; les scènes de show pourront ensuite traduire cet état en
lumière et en VFX.