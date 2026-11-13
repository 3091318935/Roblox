local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")

if Workspace:FindFirstChild("BoolValue") then
    return
end

local assetFunction = getcustomasset or getsynasset

assert(type(writefile) == "function", "writefile unavailable")
assert(type(readfile) == "function", "readfile unavailable")
assert(type(isfile) == "function", "isfile unavailable")
assert(type(makefolder) == "function", "makefolder unavailable")
assert(type(isfolder) == "function", "isfolder unavailable")
assert(type(assetFunction) == "function", "custom asset unavailable")

local marker = Instance.new("BoolValue")
marker.Name = "HardCoreSound"
marker.Value = true
marker.Parent = Workspace

local folder = Workspace:FindFirstChild("HardCoreSound")

if folder and not folder:IsA("Folder") then
    folder:Destroy()
    folder = nil
end

if not folder then
    folder = Instance.new("Folder")
    folder.Name = "HardCoreSound"
    folder.Parent = Workspace
end

local cacheFolder = "HardCoreMusicCache"

if not isfolder(cacheFolder) then
    makefolder(cacheFolder)
end

local rawNew = "https://raw.githubusercontent.com/Zero0Star/RipperNewSound/master/"
local rawMP = "https://raw.githubusercontent.com/Zero0Star/RipperMPSound/master/"

local soundsData = {
    {url = rawNew .. "DreadJumpFace.mp3", name = "DreadJump", vol = 5},
    {url = rawMP .. "A120Jump.mp3", name = "A200J", vol = 4},
    {url = rawMP .. "RipperNewSound.mp3", name = "RipperBackgroundSound", vol = 1},
    {url = rawNew .. "RipperDoorend.mp3", name = "RipperExplosionSound", vol = 1},
    {url = rawNew .. "A-333Music2.mp3", name = "A333Music", vol = 2},
    {url = rawNew .. "BossTime.mp3", name = "BossTime", vol = 2},
    {url = rawMP .. "ReboundSoundV1.mp3", name = "ReboundSweep", vol = 1},
    {url = rawNew .. "MultiMonster1.mp3", name = "M1", vol = 2},
    {url = rawNew .. "MultiMonster2.mp3", name = "M2", vol = 2},
    {url = rawNew .. "MultiMonster3.mp3", name = "M3", vol = 2},
    {url = rawNew .. "MultiMonster4.mp3", name = "M4", vol = 2},
    {url = rawMP .. "ReboundMovings.mp3", name = "ReboundMovings", vol = 1},
    {url = rawNew .. "Silence.mp3", name = "Silence", vol = 1},
    {url = rawNew .. "MultiMonsterRebound.mp3", name = "MultiMonsterRebound", vol = 1},
    {url = rawNew .. "MultiMonsterRipper.mp3", name = "MRS", vol = 1},
    {url = rawNew .. "SilenceFar.mp3", name = "SilenceFar", vol = 1},
    {url = rawNew .. "NoRunning.mp3", name = "DeerGodMusic", vol = 1},
    {url = rawNew .. "FrostbitePhase1.mp3", name = "F1", vol = 1},
    {url = rawNew .. "FrostbitePhase2.mp3", name = "F2", vol = 1},
    {url = rawNew .. "FrostbiteEnd.mp3", name = "F3", vol = 1},
    {url = rawMP .. "HatredBossMusic.mp3", name = "HATRED", vol = 1},
    {url = rawNew .. "HatRedPhase2.mp3", name = "HAT2", vol = 10},
    {url = rawNew .. "LEVELFUN.mp3", name = "FUN1", vol = 1},
    {url = rawNew .. "ScribbletEnd.mp3", name = "EndS", vol = 1},
    {url = rawNew .. "ScribbletStart.mp3", name = "StartS", vol = 1},
    {url = rawNew .. "DeerJumpScary.mp3", name = "DeerDeath", vol = 1},
    {url = rawNew .. "Z367Music.mp3", name = "Z367", vol = 4.4}
}

local MAX_CONCURRENT = 4
local RETRY_DELAY = 1
local MAX_RETRY_DELAY = 8

local function getFilePath(data)
    return cacheFolder .. "/" .. data.name .. ".mp3"
end

local function isValidMP3(content)
    if type(content) ~= "string" then
        return false
    end

    if #content < 128 then
        return false
    end

    if content:sub(1, 3) == "ID3" then
        return true
    end

    local first, second = content:byte(1, 2)

    if first == 255 and second and second >= 224 then
        return true
    end

    return false
end

local function verifyFile(data)
    local path = getFilePath(data)

    local existsOK, exists = pcall(isfile, path)

    if not existsOK or not exists then
        return false
    end

    local readOK, content = pcall(readfile, path)

    if not readOK then
        return false
    end

    return isValidMP3(content)
end

local function downloadAudio(data)
    local path = getFilePath(data)

    local success, content = pcall(function()
        return game:HttpGet(data.url, true)
    end)

    if not success or not isValidMP3(content) then
        return false
    end

    local writeOK = pcall(function()
        writefile(path, content)
    end)

    if not writeOK then
        return false
    end

    if not verifyFile(data) then
        return false
    end

    return true
end

local function downloadBatch(list)
    if #list == 0 then
        return
    end

    local index = 0
    local finished = 0
    local workerCount = math.min(MAX_CONCURRENT, #list)

    for _ = 1, workerCount do
        task.spawn(function()
            while true do
                index += 1

                local data = list[index]

                if not data then
                    break
                end

                pcall(downloadAudio, data)
            end

            finished += 1
        end)
    end

    repeat
        task.wait(0.05)
    until finished >= workerCount
end

local function collectMissingFiles()
    local missing = {}

    for _, data in ipairs(soundsData) do
        if not verifyFile(data) then
            missing[#missing + 1] = data
        end
    end

    return missing
end

local function createSound(data)
    if not verifyFile(data) then
        return false
    end

    local existing = folder:FindFirstChild(data.name)

    if existing and not existing:IsA("Sound") then
        existing:Destroy()
        existing = nil
    end

    if existing and existing.SoundId ~= "" then
        existing.Volume = data.vol
        return true
    end

    local success, assetId = pcall(function()
        return assetFunction(getFilePath(data))
    end)

    if not success or type(assetId) ~= "string" or assetId == "" then
        return false
    end

    local sound = existing

    if not sound then
        sound = Instance.new("Sound")
        sound.Name = data.name
    end

    sound.SoundId = assetId
    sound.Volume = data.vol
    sound.Looped = false
    sound.Parent = folder

    return true
end

local function verifySoundsFolder()
    for _, data in ipairs(soundsData) do
        local sound = folder:FindFirstChild(data.name)

        if not sound then
            return false
        end

        if not sound:IsA("Sound") then
            return false
        end

        if sound.SoundId == "" then
            return false
        end

        if not verifyFile(data) then
            return false
        end
    end

    return true
end

local function initializeAllSounds()
    local retryDelay = RETRY_DELAY

    while true do
        local missing = collectMissingFiles()

        if #missing > 0 then
            for _, data in ipairs(missing) do
                local existing = folder:FindFirstChild(data.name)

                if existing then
                    existing:Destroy()
                end
            end

            downloadBatch(missing)
        end

        missing = collectMissingFiles()

        if #missing == 0 then
            local registered = true

            for _, data in ipairs(soundsData) do
                if not createSound(data) then
                    registered = false
                end
            end

            if registered then
                local finalMissing = collectMissingFiles()

                if #finalMissing == 0 and verifySoundsFolder() then
                    return true
                end
            end
        end

        task.wait(retryDelay)
        retryDelay = math.min(retryDelay * 1.5, MAX_RETRY_DELAY)
    end
end

initializeAllSounds()

local allFilesValid = false

while not allFilesValid do
    local missing = collectMissingFiles()

    if #missing == 0 and verifySoundsFolder() then
        allFilesValid = true
    else
        if #missing > 0 then
            for _, data in ipairs(missing) do
                local existing = folder:FindFirstChild(data.name)

                if existing then
                    existing:Destroy()
                end
            end

            downloadBatch(missing)
        end

        if #collectMissingFiles() == 0 then
            for _, data in ipairs(soundsData) do
                createSound(data)
            end
        end

        task.wait(1)
    end
end

local hint = Instance.new("Hint", Workspace)
hint.Text = "Loading... HardCoreSound V10.7.0 By Mr.key & HeavenNow & Number303 :)"
Debris:AddItem(hint, 3)