-- towMissionTrigger.lua (GAME ENGINE SIDE)

local M = {}

local activeMission = nil
local lastSpawnIndex = nil
local lastModelIndex = nil

-- ===================== DATABASE ===================== --

-- Penality parking
local DROPOFF_POS = vec3(-83.527, 138.940, 123.639)

-- 30 coordinates
local SPAWN_POINTS = {
  vec3(-662.420, 145.060, 116.580),
  vec3(-560.720, 293.110, 104.080),
  vec3(-743.820, 63.818, 118.160),
  vec3(-717.040, -31.064, 102.230),
  vec3(-521.500, 177.690, 100.570),
  vec3(-383.150, 295.114, 101.570),
  vec3(-341.940, 317.230, 101.730),
  vec3(-337.390, 258.900, 105.140),
  vec3(33.129, 551.400, 74.582),
  vec3(42.396, 721.490, 74.720),
  vec3(-265.220, 702.260, 74.868),
  vec3(-375.290, 654.674, 74.874),
  vec3(-538.880, 786.800, 74.840),
  vec3(-943.729, 768.685, 92.404),
  vec3(-947.623, 661.499, 112.149),
  vec3(-858.471, 625.743, 116.799),
  vec3(-938.193, 440.169, 153.237),
  vec3(-907.552, 416.648, 154.031),
  vec3(-865.373, 287.628, 159.494),
  vec3(-971.674, 177.300, 157.871),
  vec3(-839.519, 138.375, 140.256),
  vec3(-728.186, -70.515, 102.224),
  vec3(-390.644, 112.399, 91.324),
  vec3(-225.153, -194.702, 118.976),
  vec3(-588.737, -30.038, 100.550),
  vec3(-904.963, -723.868, 104.871),
  vec3(-232.666, -707.052, 127.944),
  vec3(-389.158, 749.462, 74.746),
  vec3(-544.646, 665.739, 87.771),
  vec3(-636.351, 49.882, 103.091)
}

-- List of cars
local VEHICLE_MODELS = {
  "bastion",
  "legran",
  "vivace",
  "bolide",
  "etk800",
  "etki",
  "etkc",
  "fullsize",
  "roamer",
  "sbr",
  "sunburst2",
  "bx",
  "covet",
  "hopper",
  "midsize",
  "pessima",
  "pigeon",
  "wigeon",
  "lansdale",
  "wendover",
  "autobello",
  "moonhawk",
  "barstow",
  "atv",
}

-- Display messages
local function showMessage(msg, category, icon)
  guihooks.trigger('Message', {
    msg = msg,
    ttl = 5.0,
    category = category or "towMission",
    icon = icon or "directions_car",
  })
end

-- ===================== MiSSION LOGIC ===================== --

local function startMission()
  local player = be:getPlayerVehicle(0)
  if not player then
    showMessage("First, get into the tow truck!", "towErr", "error")
    return
  end

  -- Check: if the mission has already start and is not completed
  if activeMission and not activeMission.completed then
    showMessage("Mission is already active! Cancel or complete it first.", "towWarn", "warning")
    return
  end

  -- 1. Selecting a spawn point by excluding the previous one
  local spawnIdx = math.random(#SPAWN_POINTS)
  while spawnIdx == lastSpawnIndex and #SPAWN_POINTS > 1 do
    spawnIdx = math.random(#SPAWN_POINTS)
  end
  lastSpawnIndex = spawnIdx
  local spawnPos = SPAWN_POINTS[spawnIdx]

  -- 2. Choosing a car model excluding the previous one
  local modelIdx = math.random(#VEHICLE_MODELS)
  while modelIdx == lastModelIndex and #VEHICLE_MODELS > 1 do
    modelIdx = math.random(#VEHICLE_MODELS)
  end
  lastModelIndex = modelIdx
  local selectedModel = VEHICLE_MODELS[modelIdx]

  local spawnData = {
    model = selectedModel,
    pos = spawnPos,
    rot = QuatF(0, 0, 0, 1),
    autoEnterVehicle = false
  }

  local targetVeh = nil

  -- Spawn auto
  if core_vehicles and core_vehicles.spawnNewVehicle then
    targetVeh = core_vehicles.spawnNewVehicle(selectedModel, spawnData)
  elseif spawn and spawn.spawnVehicle then
    targetVeh = spawn.spawnVehicle(selectedModel, spawnData.config, spawnPos, QuatF(0,0,0,1), {autoEnterVehicle = false})
  end

  if not targetVeh then
    showMessage("Error spawning the offender's car!", "towErr", "error")
    return
  end

  local targetId = targetVeh:getID()

  activeMission = {
    targetId = targetId,
    spawnPos = spawnPos,
    spawnRadius = 12.5, -- Radius of the intruder zone 12.5m (Diameter 25m)
    dropoffPos = DROPOFF_POS, -- Fixed impound lot
    dropoffRadius = 8.5, -- Impound lot radius 8.5m (Diameter 17m)
    completed = false,
    isFrozen = false
  }

  showMessage("New order! Pick up your car and take it to the impound lot.", "towStart", "map")
  log('I', 'towMission', 'Tow mission started. Target ID: ' .. tostring(targetId) .. ' Model: ' .. selectedModel)
end


local function cancelMission()
  if activeMission then
    local targetVeh = be:getObjectByID(activeMission.targetId)
    if targetVeh then
      targetVeh:delete()
    end
    activeMission = nil
    showMessage("Mission cancelled.", "towCancel", "cancel")
  end
end

-- ===================== STUBS AND UI SYNCHRONIZATION ===================== --

local function requestConfig()
  guihooks.trigger('SRTConfigSync', {})
end

local function setConfig(jsonStr)
end

local function resetConfig()
end

-- ===================== THE MAIN GAME LOOP ===================== --

local function onExtensionLoaded()
  log('I', 'towMission', 'Tow Service Extension loaded successfully!')
end

local function onUpdate(dt)
  if not activeMission or activeMission.completed then return end

  local targetVeh = be:getObjectByID(activeMission.targetId)
  if not targetVeh then
    cancelMission()
    return
  end

  local targetPos = vec3(targetVeh:getPosition())

  -- 1 Movement restriction (invisible cylinder 25m around spawn)
  local distFromSpawn = (targetPos - activeMission.spawnPos):length()
  
  if distFromSpawn > activeMission.spawnRadius then
    -- Beyond 25m: forced shutdown, brake and neutral
    targetVeh:queueLuaCommand([[
      electrics.values.ignitionLevel = 0
      electrics.values.throttle = 0
      electrics.values.throttleOverride = 0
      electrics.values.brake = 1
      controller.setFreeze(true)
      if drivetrain then drivetrain.shiftToGear(0) end
    ]])
    activeMission.isFrozen = true
    
    if not activeMission.hasWarned then
      showMessage("The vehicle has left the restriction zone! Transport locked.", "towWarn", "warning")
      activeMission.hasWarned = true
    end
  else
    -- Inside 25m: Unlocking
    if activeMission.isFrozen then
      targetVeh:queueLuaCommand([[
        electrics.values.ignitionLevel = 2
        electrics.values.brake = 0
        controller.setFreeze(false)
      ]])
      activeMission.isFrozen = false
    end
  end

  -- 2. Dynamic beam radius over the vehicle depending on distance
  local playerVeh = be:getPlayerVehicle(0)
  local beamRadius = 0.25

  if playerVeh then
    local playerPos = vec3(playerVeh:getPosition())
    local distToPlayer = (targetPos - playerPos):length()

    beamRadius = math.max(0.1, math.min(5.0, distToPlayer * 0.01))
  end

  -- We draw an adaptive white cylinder 300 m high above the car.
  debugDrawer:drawCylinder(targetPos, targetPos + vec3(0, 0, 300), beamRadius, ColorF(1, 1, 1, 0.8))

  -- 3. Green cylinder of the impound lot (height 150m, diameter 25m)
  local dropPos = activeMission.dropoffPos
  debugDrawer:drawCylinder(dropPos, dropPos + vec3(0, 0, 150), activeMission.dropoffRadius, ColorF(0, 1, 0.2, 0.35))

  -- 4. Checking the delivery of a car to the impound lot
  local distToDropoff = (targetPos - dropPos):length()

  if distToDropoff <= activeMission.dropoffRadius then
    activeMission.completed = true
    showMessage("EXCELLENT! The car has been delivered to the impound lot. Loading the next order...", "towWin", "check_circle")
    
    targetVeh:delete()
    startMission()
  end
end

-- Registration of export functions
M.startMission      = startMission
M.cancelMission     = cancelMission
M.requestConfig     = requestConfig
M.setConfig         = setConfig
M.resetConfig       = resetConfig
M.onExtensionLoaded = onExtensionLoaded
M.onUpdate          = onUpdate

return M
