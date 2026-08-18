--[[
--   +-+-+-+ +-+-+-+-+-+-+-+-+-+-+-+ +-+-+-+-+-+ +-+-+-+-+-+-+-+
--   |b|s|s| |a|l|t|e|r|n|a|t|i|n|g| |t|e|m|p|o| |m|a|r|k|e|r|s|
--   +-+-+-+ +-+-+-+-+-+-+-+-+-+-+-+ +-+-+-+-+-+ +-+-+-+-+-+-+-+
--
--   quick-and-dirty installation:
--     1. Open REAPER
--     2. Press "?" to show the action list
--     3. Press "New action"
--     4. Press "New ReaScript"
--     5. Give the file a name (I've called it "bss_alternating_tempo_markers.lua")
--     6. Make sure to use the ".lua" file extension.
--     7. Paste this entire file into the new window that opens
--     8. CTRL-S (Windows) or CMD-S (Mac) to save it
--     9. Now find that action in the action list (search for bss_alternating_tempo_markers")
--    10. Select the script in the action list and press "Run".
--
--  poc: james.watson.iii@gmail.com
--  doc: 17 August 2026
--  ver: 1.0
--]]

-- ################################################################################
local function check_details(msg, which, tmp, bpb, bd)
    if tmp > 240 then
        msg = msg .. "\nThe " .. which .. " measure's tempo (" .. tmp .. ") is pretty fast."
    end

    if bpb > 16 then
        msg = msg .. "\nThe " .. which .. " measure's beats-per-bar (" .. bpb .. ") is larger than I'd expect."
    end

    if bd > 16 then
        msg = msg .. "\nThe " .. which .. " measure's beat duration (" .. bd .. ") is larger than I'd expect."
    end
    return msg
end

-- ################################################################################
local function get_tempo_details()
    local t = "BSS Alternating Tempo Markers"

    local a = "Total number of alternating measures"
    local b = "1st measure tempo:,1st measure time signature"
    local c = "2nd measure tempo:,2nd measure time signature" 

    local x = "128"
    local y = "120,4/4"
    local z = "120,3/4"

    local labels = a .. "," .. b .. "," .. c
    local defaults = x .. "," .. y .. "," .. z

    local rc, details = reaper.GetUserInputs(t, 5, labels, defaults)
    if rc then 

        local n_meas, a_tempo, a_bpb, a_bd, b_tempo, b_bpb, b_bd = string.match(details, "(%d+),(%d+),(%d+)/(%d+),(%d+),(%d+)/(%d+)")
        local info = debug.getinfo(2, "l")

        if not n_meas then
            reaper.MB("I couldn't understand the input; please try again using only numbers (and '/' to separate the bpm and duration in the time signatures).", "WARNING", 0 + 48)
            return false, nil, nil, nil, nil, nil, nil
        end

        n_meas = tonumber(n_meas)
        a_tempo = tonumber(a_tempo)
        a_bpb = tonumber(a_bpb)
        a_bd = tonumber(a_bd)
        b_tempo = tonumber(b_tempo)
        b_bpb = tonumber(b_bpb)
        b_bd = tonumber(b_bd)


        if n_meas % 2 ~= 0 then
            n_meas = n_meas + 1
        end

        local msg = check_details("", "1st", a_tempo, a_bpb, a_bd)
        msg = check_details(msg, "2nd", b_tempo, b_bpb, b_bd)
        if #msg > 0 then
            msg = "Warning: I'll do it, but the following looks a little suspect:\n" .. msg
            reaper.MB(msg, "WARNING", 0 + 48)
        end

        return true, n_meas, a_tempo, a_bpb, a_bd, b_tempo, b_bpb, b_bd
    end
    return false, nil, nil, nil, nil, nil, nil
end


-- ################################################################################
local function make_alternating_tempo_markers()

    local rc, n_measures, a_tempo, a_bpb, a_bd, b_tempo, b_bpb, b_bd = get_tempo_details()
    if rc then

        -- Begin undo block to bundle changes into a single Ctrl+Z action
        reaper.Undo_BeginBlock()
        
        for i_measure = 0, n_measures - 1 do
            local use_a = i_measure % 2 == 0
            
            local tempo = use_a and a_tempo or b_tempo
            local bpb   = use_a and a_bpb or b_bpb
            local bd    = use_a and a_bd or b_bd


            --[[
            -- SetTempoTimeSigMarker API:
            -- https://www.reaper.fm/sdk/reascript/reascripthelp.html#SetTempoTimeSigMarker
            -- Lua: boolean reaper.SetTempoTimeSigMarker(
            --          ReaProject proj,            nil for active project
            --          integer ptidx,              -1 means insert a new marker
            --          number timepos,             time position in seconds (which gets
            --                                      ignored if the next param (measurepos) >= 0)
            --          integer measurepos,         0 == start of project
            --          number beatpos,             beat position within the measure
            --          number bpm,                 obv.
            --          integer timesig_num,        obv.
            --          integer timesig_denom,      obv.
            --          boolean lineartempo)        obv.
            -- n.b. the documentation is vague; I had to ask Google how to
            -- interpret timepos, measurepos, and beatpos.
            --]]
            reaper.SetTempoTimeSigMarker(nil, -1, -1.0, i_measure, 0.0, tempo, bpb, bd, false)
        end

        reaper.UpdateTimeline()
        reaper.Undo_EndBlock("make alternating tempo markers", -1)
    end
end

-- ################################################################################
-- do it!
make_alternating_tempo_markers()
