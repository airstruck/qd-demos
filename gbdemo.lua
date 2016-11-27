local startTime = love.timer.getTime()

local BPM = 140 -- beats per minute
local BEAT = BPM / 60 -- beats per second

local Qd = require 'lib.qd'
local Bank = require 'bank'

local clock = Qd.Clock { rate = 0x4000, seconds = 40 }
local track = Qd.Track()

-- guitar tabs 

local bassTab = [[
A2      |2.2.----0.------|
E2      |----024.--0.4.0.|
]]

local rhythmTab = [[
G2      |--4-.---2-.-----|
D2      |--4-.---2-.-6-.-|
A2      |--2-.---0-.-7-.-|
E2      |------------4-.-|
]]

local melodyTab = [[
G4      |----8.--6.------|----------------|
D4      |--99--9.--7.----|----99997.9.----|
]]

local coolPartTab = [[
G4      |7-----7-----7---|--7-----7-.-----|
D4      |----9.----9.----|9.----9.--9-789.|
]]

local harmonyTab = [[
e5      |----------------|--------e------.|
G4      |b-----b-----b---|--b----.--------|
D4      |----c.----c.----|c.----c.--------|
]]

-- drum tabs 

local mainDrums = [[
kick    |9---9---9---9---|9---9---9---9---|
snare   |--7---4---7---4-|--7---4---7---74|
]]

local introDrums = [[
snare   |2111322243335444|
]]

-- assign each tab (and its playback rate) to a character
-- for use in the main sequence

track:register('B', bassTab, BEAT * 4)
track:register('M', melodyTab, BEAT * 4)
track:register('C', coolPartTab, BEAT * 4)
track:register('H', harmonyTab, BEAT * 4)
track:register('R', rhythmTab, BEAT * 4)
track:register('D', mainDrums, BEAT * 4)
track:register('d', introDrums, BEAT * 4)

local mainSequence = [[
bass    |-|BBBB|BBBB|BBBB|BBBB|BBBB|
rhythm  |-|RRRR|RRRR|RRRR|RRRR|RRRR|
lead    |-|----|M-M-|C-C-|C-H-|--M-|
drums   |d|D-D-|D-D-|D-D-|D-D-|D-D-|
]]

-- define instruments used in the main sequence

track.bass = Bank.DemoBass()

track.rhythm = Bank.DemoRhythm()

track.lead = Bank.DemoLead { clock = clock, beat = BEAT }

track.drums = Qd.Kit {
    kick = Bank.DemoKick(),
    snare = Bank.DemoSnare(),
}

-- schedule the track for playback

track:plan(clock, mainSequence, BEAT / 4)

-- master mix levels and effects

local master = clock .. (
    (track.bass * { 0.26, 0.24 }) 
    + (track.rhythm * { 0.18, 0.20 }
        .. Qd.Delay {
            len = math.floor(clock.rate / BEAT),
            wet = 0.2, dry = 0.7, echo = true,
        })
    + (track.lead * { 0.14, 0.14 }) 
    + (track.drums * { 0.24, 0.26 }
        .. Qd.Delay {
            len = math.floor(clock.rate / BEAT * 1.5),
            wet = 0.1, dry = 1, echo = true,
        })
) .. Qd.Clamp()

-- create a SoundData and play it 

local sound = love.sound.newSoundData(clock:reflect())

while clock:tick() do
    local left, right = master()
    sound:setSample(clock.sample, left)
    if clock.channels == 2 then
        sound:setSample(clock.sample + 1, right)
    end
end

love.audio.newSource(sound):play()

-- visualization

local visTop = 300
local visHeight = 30
local sampleCount = sound:getSampleCount()
function love.draw ()
    local pX, pY
    love.graphics.line(0, visTop - visHeight, 800, visTop - visHeight)
    love.graphics.line(0, visTop + visHeight, 800, visTop + visHeight)
    for x = 1, 800 do
        if x * 0x100 >= sampleCount then break end
        local y = -sound:getSample(x * 0x100) * visHeight + visTop
        if pX then
            love.graphics.line(pX, pY, x, y)
        end
        pX, pY = x, y
    end
end

print(love.timer.getTime() - startTime, 'seconds')

