local queue_actions ={} -- contains all ActionQueue actions

local funcs = {}

mesecons.queue = {}

-- Add a function that can be executed. Not available for other mods
function mesecons.queue.add_function(name, func)
	funcs[name] = func
end

-- If add_action with twice the same owcheck and same position are called, the first one is overwritten
-- use owcheck nil to never overwrite, but just add the event to the queue
-- priority specifies the order actions are executed within one globalstep, highest first
-- should be between 0 and 1
function mesecons.queue.add_action(pos, func, params, time, owcheck, priority)
	-- Create Action Table
	local action = {
        pos      = table.copy(pos),
        func     = func,
        params   = table.copy(params or {}),
        time     = time or 0,
        -- time <= 0 --> execute, time > 0 --> wait time until execution
        owcheck  = type(owcheck) == "table" and table.copy(owcheck) or owcheck,
        priority = priority or 1
    }

	local toremove = nil
	-- Otherwise, add the action to the queue
	if owcheck then -- check if old action has to be overwritten / removed:
		for i, ac in ipairs(queue_actions) do
			if vector.equals(pos, ac.pos)
                    and (owcheck == ac.owcheck or table.equals(owcheck, ac.owcheck)) then
				toremove = i
				break
			end
		end
	end

	if toremove then
		table.remove(queue_actions, toremove)
	end

	table.insert(queue_actions, action)
end

-- execute the stored functions on a globalstep
-- if however, the pos of a function is not loaded (get_node_or_nil == nil), do NOT execute the function
-- this makes sure that resuming mesecons circuits when restarting minetest works fine
-- However, even that does not work in some cases, that's why we delay the time the globalsteps
-- start to be execute by 4 seconds
local get_highest_priority = function (actions)
	local highestp = -1
	local highesti
	for i, ac in ipairs(actions) do
		if ac.priority > highestp then
			highestp = ac.priority
			highesti = i
		end
	end

	return highesti
end

local function mesecon_queue_execute(action)
    funcs[action.func](action.pos, unpack(action.params))
end

local m_time = 0
local resumetime = tonumber(minetest.settings:get("mesecons_resumetime") or 4)
minetest.register_globalstep(function (dtime)
	-- don't even try if server has not been running for XY seconds; resumetime = time to wait
	-- after starting the server before processing the ActionQueue, don't set this too low
	if m_time < resumetime then
        m_time = m_time + dtime
        return
    end
    
	local actions = queue_actions
	local actions_now = {}

	queue_actions = {}

	-- sort actions into two categories:
	-- those to execute now (actions_now) and those to execute later (queue_actions)
	for i, ac in ipairs(actions) do
		if ac.time > 0 then
			ac.time = ac.time - dtime -- executed later
			table.insert(queue_actions, ac)
		else
			table.insert(actions_now, ac)
		end
	end

	while(#actions_now > 0) do -- execute highest priorities first, until all are executed
		local hp = get_highest_priority(actions_now)
		mesecon_queue_execute(actions_now[hp])
		table.remove(actions_now, hp)
	end
end)


-- Store and read the ActionQueue to / from a file
-- so that upcoming actions are remembered when the game
-- is restarted

local get_storage, set_storage = mesecons.storage("mesecon_actionqueue")
queue_actions = get_storage()

minetest.register_on_shutdown(function()
	set_storage(queue_actions)
end)
