extends Node2D

var switches = []
var gates = []

func _ready():
    pass

func add_gate(gate):
    gates.append(gate)

func add_switch(switch):
    switches.append(switch)

func on_switch_toggle():
    assert(len(gates) > 0)
    assert(len(switches) > 0)

    var gate_should_be_open = true
    for switch in switches:
        if switch.is_necessary and !switch.is_on:
            gate_should_be_open = false
        # Sufficiency is prioritized over necessity.
        # Used for "reset" buttons.
        if switch.is_sufficient and switch.is_on:
            gate_should_be_open = true
            break

    # Check gates and toggle as needed.
    for gate in gates:
        if gate.is_open != gate_should_be_open:
            gate.toggle()
