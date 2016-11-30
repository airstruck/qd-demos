-- sound bank for demo tunes

local Qd = require 'lib.qd'

local Bank = {}

local function DemoBassEffect (data)
    return Qd.Sin()
        .. Qd.Env {
            data = data,
            attack = 0.01,
            decay = 0.1,
            sustain = 0,
            release = 0.1,
        }
        * 1.25
        .. Qd.Tube { count = 3 }
end

function Bank.DemoBass ()
    return Qd.Axe { effect = DemoBassEffect }
end

local function DemoRhythmEffect (data)
    return Qd.Sin() * (0.8 + 1.3 * Qd.Sin())
        .. Qd.Env {
            data = data,
            attack = 0.01,
            decay = 0.2,
            sustain = 0.05,
            release = 0.2,
        } 
        .. Qd.Tube { count = 3 }
end

function Bank.DemoRhythm ()
    return Qd.Axe { effect = DemoRhythmEffect }
end

local function DemoLeadEffect (data, context)
    return Qd.Sin()
        .. context.fold
        .. Qd.Env {
            data = data,
            attack = 0.01,
            decay = 0.1,
            sustain = 0.1,
            release = 0.5,
        }
        .. Qd.Tube { count = 3 }
end

local function automateDemoLead (dt, args)
    local lfo = args.lfo()
    args.fold.limit = 0.1 * (1 + lfo)
    args.fold.factor = 0.5 + 0.3 * (1 + lfo) 
end
    
function Bank.DemoLead (t)
    assert(t.clock, 'DemoLead args table requires "clock" field')
    assert(t.beat, 'DemoLead args table requires "beat" field')
    local fold = Qd.Fold()
    local lfo = t.clock .. Qd.Osc { freq = t.beat * 4 } .. Qd.Sin()
    t.clock:always(automateDemoLead, { fold = fold, lfo = lfo })
    return Qd.Axe { effect = DemoLeadEffect, context = { fold = fold } }
end

local function DrumDecay_process (t, v)
    return v * (1 - math.min(t.data.onTime * t.speed, 1)) * t.data.n * 0.1
end

local function DrumDecay (t)
    t = Qd.SoundUnit(t)
    t.process = DrumDecay_process
    t.speed = t.speed or 4
    assert(t.data)
    return t
end

local function DemoKickEffect (data)
    return ((Qd.Osc { freq = 32 } .. Qd.Sin()
            .. DrumDecay { data = data, speed = 8 }))
        * (1 + 2 * (Qd.Osc { freq = 256 } .. Qd.Sin()
            .. DrumDecay { data = data, speed = 18 }))
        * (1 + 2 * (Qd.Osc { freq = 64 } .. Qd.Sin()
            .. DrumDecay { data = data, speed = 10 }))
        * (1 + 2 * (Qd.Osc { freq = 8, value = 0.5 } .. Qd.Sin()
            .. DrumDecay { data = data, speed = 4 }))
        .. Qd.Soft()
        * 2
        .. Qd.Tube { count = 3 }  
end

function Bank.DemoKick ()   
    return DemoKickEffect
end

local function flip (v)
    if v == 0 then return 0 end
    local u = v / math.abs(v)
    return u - (v * u)
end

local function DemoSnareEffect (data)
    return Qd.Osc { freq = 7919 }
        * Qd.Osc { freq = 5279 }
        * Qd.Osc { freq = 3821 }
        * Qd.Osc { freq = 2803 }
        * Qd.Osc { freq = 593 }
        * Qd.Osc { freq = 59 }
        .. flip
        .. DrumDecay { data = data, speed = 12 }
        * 0.5
end

function Bank.DemoSnare ()   
    return DemoSnareEffect
end

return Bank

