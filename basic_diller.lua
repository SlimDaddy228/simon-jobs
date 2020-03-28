
--------------------------------------------------------
--Sell cars menu

local cfg = module("cfg/diller")

local diller_menu = {name="Автодиллер", css={top="55px",header_color="#9167dd"}} -- Build Menu DillerCars

diller_menu["Автомобили"] = {function(player,choice)
  local user_id = vRP.getUserId(player)
  local submenu = {name="Доступные автомобили", css={top="55px",header_color="#9167dd"}}
  for k,v in pairs (cfg.diller_job) do
    local choose = function(player, choice)
      if user_id then
        local vname = v[1]
        local prompt = vRP.prompt(player, 'Цена продажи?', '') -- how cell match?
        local amount = parseInt(prompt) -- This 1000.000000 in 1000
        local nearst = vRPclient.getNearestPlayer(player, 5)
        if nearst then
          local nplayer = vRP.getUserId(nearst)
        if prompt ~= nil or prompt ~= "" then
          if vRP.tryFullPayment(player,amount) then 
            vRPclient._notify(player,"~w~Вы успешно продали автомобиль ~g~"..k.."~g~ за ~w~"..amount.."")
            vRPclient._notify(nplayer,"~w~Вы успешно купили автомобиль за ~g~"..amount.."$")
            vRPclient._notify(nplayer,"~w~Автомобиль доставят в течении 1-2 часов")
            SetTimeout(20000,function() -- Wait 20 second for give cars
              vRPclient._notify(nplayer,"~w~Автомобиль ~b~"..k.." ~w~доставили к Вам в гараж!")
              vRP.execute("vRP/add_vehicle", {user_id = nplayer, vehicle = vname}) -- add player cars with DataBase VRP
            end)
          end
        end
      end
    end
  end
    submenu[k] = {choose, v[2]} -- build menu with cars
    vRP.openMenu(player,submenu)
  end
end}

local function build_diller_shop(source) -- Build menu
  for k,v in pairs(cfg.diller_coords) do
    local function diller_leave(source,area)
      vRP.closeMenu(source)
    end
    local function diller_enter(source,area)
      local user_id = vRP.getUserId(source)
      if user_id then
        if user_id and vRP.hasPermission(user_id,"diller") then
        vRP.openMenu(source,diller_menu)
      end
    end
  end
    local x,y,z = table.unpack(v)
    vRPclient._addBlip(source,x,y,z,500,5,"Автодиллер") -- Name Blip
    vRPclient._addMarker(source,x,y,z-1,0.7,0.7,0.5,125,125,255,255,150)
    vRP.setArea(source,"vRP:newskinshop:job"..k,x,y,z,1,1.5,diller_enter,diller_leave)
  end
end

AddEventHandler("vRP:playerSpawn",function(user_id, source, first_spawn)
  if first_spawn then
    build_diller_shop(source)
  end
end)

--------------------------------------------------------
--Cloakroom menu

local menus = {}

-- save idle custom (return current idle custom copy table)
local function save_idle_custom(player, custom)
  local r_idle = {}
  local user_id = vRP.getUserId(player)
  if user_id then
    local data = vRP.getUserDataTable(user_id)
    if data then
      if data.cloakroom_idle == nil then -- set cloakroom idle if not already set
        data.cloakroom_idle = custom
      end
      -- copy custom
      for k,v in pairs(data.cloakroom_idle) do
        r_idle[k] = v
      end
    end
  end
  return r_idle
end

-- remove the player uniform (cloakroom)
function vRP.removeCloak(player)
  local user_id = vRP.getUserId(player)
  if user_id then
    local data = vRP.getUserDataTable(user_id)
    if data then
      if data.cloakroom_idle ~= nil then -- consume cloakroom idle
        vRPclient._setCustomization(player,data.cloakroom_idle)
        data.cloakroom_idle = nil
      end
    end
  end
end

async(function()
  -- generate menus
  for k,v in pairs(cfg.cloakroom_types) do
    local menu = {name=k,css={top="75px",header_color="#9167dd"}}
    menus[k] = menu

    -- check if not uniform cloakroom
    local not_uniform = false
    if v._config and v._config.not_uniform then not_uniform = true end

    -- choose cloak 
    local choose = function(player, choice)
      local custom = v[choice]
      if custom then
        old_custom = vRPclient.getCustomization(player)
        local idle_copy = {}

        if not not_uniform then -- if a uniform cloakroom
          -- save old customization if not already saved (idle customization)
          idle_copy = save_idle_custom(player, old_custom)
        end

        -- prevent idle_copy to hide the cloakroom model property (modelhash priority)
        if custom.model then
          idle_copy.modelhash = nil
        end

        -- write on idle custom copy
        for l,w in pairs(custom) do
          idle_copy[l] = w
        end

        -- set cloak customization
        vRPclient._setCustomization(player,idle_copy)
      end
    end

    -- rollback clothes
    if not not_uniform then
      menu[">Раздеться"] = {function(player,choice) vRP.removeCloak(player) end}
    end

    -- add cloak choices
    for l,w in pairs(v) do
      if l ~= "_config" then
        menu[l] = {choose}
      end
    end
  end
end)

-- clients points

local function build_diller_cloak(source)
  for k,v in pairs(cfg.cloakrooms) do
    local gtype,x,y,z = table.unpack(v)
    local cloakroom = cfg.cloakroom_types[gtype]
    local menu = menus[gtype]
    if cloakroom and menu then
      local gcfg = cloakroom._config or {}

      local function cloakroom_enter(source,area)
        local user_id = vRP.getUserId(source)
        if user_id then
          if user_id and vRP.hasPermission(user_id,"diller") then
          if gcfg.not_uniform then -- not a uniform cloakroom
            -- notify player if wearing a uniform
            local data = vRP.getUserDataTable(user_id)
            if data.cloakroom_idle ~= nil then
              vRPclient._notify(source,"На Вас униформа")
            end
          end
        end
      end

          vRP.openMenu(source,menu)
        end

      local function cloakroom_leave(source,area)
        vRP.closeMenu(source)
      end

      -- cloakroom
      vRPclient._addMarker(source,x,y,z-1,0.7,0.7,0.5,125,125,255,255,150)
      vRP.setArea(source,"vRP:diller:cloak"..k,x,y,z,1,1.5,cloakroom_enter,cloakroom_leave)
    end
  end
end

-- add points on first spawn
AddEventHandler("vRP:playerSpawn",function(user_id, source, first_spawn)
  if first_spawn then
    build_diller_cloak(source)
  end
end)

--------------------------------------------------------
--Vehicle repair menu


local function build_diller_repair(source)
  for k,v in pairs(cfg.repair_coords) do
    local x,y,z = table.unpack(v)
    local diller_repair_menu = {name="Автодиллер Починка", css={top="55px",header_color="#9167dd"}} -- Build Menu DillerCars
      local function diller_repair_enter(source,area)
        local user_id = vRP.getUserId(source)
        if user_id then
          if user_id and vRP.hasPermission(user_id,"diller") then
          vRP.openMenu(source,diller_repair_menu)
        end
      end
    end
      local function diller_repair_leave(source,area)
        vRP.closeMenu(source)
      end

      local function ch_repair(player,choice)
        local user_id = vRP.getUserId(player)
        if user_id then
          if vRP.tryGetInventoryItem(user_id,"repairkit",1,true) then
            vRPclient._playAnim(player,false,{task="WORLD_HUMAN_WELDING"},false)
            SetTimeout(15000, function()
              vRPclient._fixeNearestVehicle(player,7)
              vRPclient._stopAnim(player,false)
            end)
          end
        end
      end

      diller_repair_menu["Починить транспорт"] = {ch_repair}

      -- cloakroom
      vRPclient.addMarker(source,x,y,z-1,3,3,0.7,125,125,255,255,150)
      vRP.setArea(source,"vRP:diller:repair"..k,x,y,z,1,1.5,diller_repair_enter,diller_repair_leave)
    end
  end

-- add points on first spawn
AddEventHandler("vRP:playerSpawn",function(user_id, source, first_spawn)
  if first_spawn then
    build_diller_repair(source)
  end
end)
