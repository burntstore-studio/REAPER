-- @description Create different tempo / time-signature markers on alternate measures.
-- @author James D. Watson
-- @version 1.0
-- @links
--   Website https://github.com/burntstore-studio/REAPER
-- @about
--   This script creates different tempo / time-signature markers on alternate measures. 
--   It first prompts you for:
--     the number of measures to work against (e.g., 100). This is silently incremented
--       by one if you enter an odd number;
--     the tempo for the first measure (e.g., 120);
--     the time signature for the first measure (e.g., 4/4);
--     the tempo for the second measure (e.g. 120);
--     the time signature for the second measure (e.g., 3/4).
--   After parsing your answers, it creates the markers starting on the left-hand
--   side of the project. If you enter unexpected input (e.g., 1000 measures or
--   a tempo of 300, or a time signature of 4/18, the script alerts you but will
--   do it anyway. The action is undo-able.
-- @changelog
--   + Initial public release
--[[ 
--   +-+-+-+ +-+-+-+ +-+-+-+-+-+-+-+-+ +-+-+-+-+-+ +-+-+-+-+-+ +-+-+-+ +-+-+-+-+
--   |b|s|s| |a|d|d| |c|o|m|p|o|u|n|d| |m|e|t|e|r| |t|e|m|p|o| |a|n|d| |t|i|m|e|
--   +-+-+-+ +-+-+-+ +-+-+-+-+-+-+-+-+ +-+-+-+-+-+ +-+-+-+-+-+ +-+-+-+ +-+-+-+-+
--                       +-+-+-+-+-+-+-+-+-+ +-+-+-+-+-+-+-+
--                       |s|i|g|n|a|t|u|r|e| |m|a|r|k|e|r|s|
--                       +-+-+-+-+-+-+-+-+-+ +-+-+-+-+-+-+-+
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
local function get_details()
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

    local rc, n_measures, a_tempo, a_bpb, a_bd, b_tempo, b_bpb, b_bd = get_details()
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
