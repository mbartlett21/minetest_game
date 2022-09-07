

-- Autoconnect Hooks
-- Nodes like conductors may change their appearance and their connection rules
-- right after being placed or after being dug, e.g. the default wires use this
-- to automatically connect to linking nodes after placement.
-- After placement, the update function will be executed immediately so that the
-- possibly changed rules can be taken into account when recalculating the circuit.
-- After digging, the update function will be queued and executed after
-- recalculating the circuit. The update function must take care of updating the
-- node at the given position itself, but also all of the other nodes the given
-- position may have (had) a linking connection to.
mesecons.autoconnect_hooks = {}

-- name: A unique name for the hook, e.g. "foowire". Used to name the actionqueue function.
-- fct: The update function with parameters function(pos, node)
local mesecon_queue_add_function = mesecons.queue.add_function

function mesecons.register_autoconnect_hook(name, fct)
	mesecons.autoconnect_hooks[name] = fct
	mesecon_queue_add_function("autoconnect_hook_"..name, fct)
end

function mesecons.execute_autoconnect_hooks_now(pos, node)
	for _, fct in pairs(mesecons.autoconnect_hooks) do
		fct(pos, node)
	end
end

function mesecons.execute_autoconnect_hooks_queue(pos, node)
	for name in pairs(mesecons.autoconnect_hooks) do
		mesecons.queue.add_action(pos, "autoconnect_hook_"..name, {node})
	end
end