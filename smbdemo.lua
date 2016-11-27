local startTime = love.timer.getTime()

local BPM = 140 -- beats per minute
local BEAT = BPM / 60 -- beats per second

local Qd = require 'lib.qd'
local Bank = require 'bank'

local clock = Qd.Clock { rate = 0x4000, seconds = 25 }
local track = Qd.Track()

-- guitar tabs 

local tabA = [[
e4      |----------------|-035-1-3-0------|
B3      |1----------0----|-----------130--|
G3      |---0-----2---32-|0---------------|
D3      |------2---------|----------------|
]]

local tabB = [[
e4      |321--0----------|
B3      |---4-----1--13--|
G3      |-------12--2----|
]]

local tabC = [[
e4      |321--0-8-88-----|
B3      |---4------------|
]]

local tabD = [[
B3      |4--3--1---------|
]]

local tabE = [[
e4      |--------0-------|
B3      |11-1-13--1------|
G3      |-----------20---|
]]

local tabF = [[
e4      |-------0--------|
B3      |11-1-13---------|
G3      |----------------|
]]

local tabG = [[
e4      |00-0--0-3-------|
B3      |-----1----------|
G3      |------------0---|
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

track:register('A', tabA, BEAT * 4)
track:register('B', tabB, BEAT * 4)
track:register('C', tabC, BEAT * 4)
track:register('D', tabD, BEAT * 4)
track:register('E', tabE, BEAT * 4)
track:register('F', tabF, BEAT * 4)
track:register('G', tabG, BEAT * 4)
track:register('x', mainDrums, BEAT * 4)

local mainSequence = [[
bass    |A-A-|BCBD|EFEG|
drums   |x-x-|x-x-|x-x-|
]]

-- define instruments used in the main sequence

track.bass = Qd.Axe {
    effect = function (data)
        return Qd.Tri()
            .. Qd.Env {
                data = data,
                decay = 0.2,
            }
    end
}

track.drums = Qd.Kit {
    kick = Bank.DemoKick(),
    snare = Bank.DemoSnare(),
}

-- schedule the track for playback

track:plan(clock, mainSequence, BEAT / 4)

-- master mix levels and effects

local master = clock .. (
    (track.bass * { 0.26, 0.24 }) 
    + (track.drums * { 0.24, 0.26 })
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

