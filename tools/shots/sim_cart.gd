extends RefCounted
## Screenshot setup: builds the test cart and launches the simulation.


static func setup(session: Node) -> void:
	load("res://tools/shots/cart.gd").build(session, 2)
	session.enter_sim(7)
