-- Realtime mod created by Morgan B
local is_real_time = minetest.settings:get_bool("enable_realtime")
if is_real_time then
    local storage = minetest.get_mod_storage()
    
    local function get_os_time_amount()
        local time_table = os.date("*t")
        return {
            time = time_table.hour / 24 +
                   time_table.min / 60 / 24 +
                   time_table.sec / 60 / 60 / 24,
            formatted = ("%02d:%02d"):format(time_table.hour, time_table.min)
        }
    end

    local function start_and_set_time()
        local time_data = get_os_time_amount()
        minetest.set_timeofday(time_data.time)
    end
    
    minetest.register_on_joinplayer(function(player)
            local time_data = get_os_time_amount()
            minetest.chat_send_player(player:get_player_name(), "Welcome! It is currently " .. time_data.formatted)
        end)

    
    -- We only set the time and speed after the game loads
    minetest.after(0, function()
            start_and_set_time()
            if not storage:get_float('time_speed_original') then
                storage:set_float('time_speed_original',
                    minetest.settings:get('time_speed'))
            end
            minetest.settings:set('time_speed', 1)
        end)

    minetest.register_on_shutdown(function ()
            -- The server may be shut down before the timer above runs
            local time_speed_original = storage:get_float('time_speed_original')
            if time_speed_original then
                minetest.settings:set('time_speed', time_speed_original)
                storage:set_string('time_speed_original', nil)
            end
        end)

end