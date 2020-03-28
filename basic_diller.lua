
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
        if prompt ~= nil or prompt ~= "" then
          if vRP.tryFullPayment(player,amount) then 
            vRPclient._notify(player,"~w~Вы успешно продали автомобиль ~g~"..k.."~g~ за ~w~"..amount.."")
            vRPclient._notify(player,"~w~Вы успешно купили автомобиль за ~g~"..amount.."$")
            vRPclient._notify(player,"~w~Автомобиль доставят в течении 1-2 часов")
            SetTimeout(20000,function() -- Wait 20 second for give cars
              vRPclient._notify(player,"~w~Автомобиль ~b~"..k.." ~w~доставили к Вам в гараж!")
              vRP.execute("vRP/add_vehicle", {user_id = user_id, vehicle = vname}) -- add player cars with DataBase VRP
            end)
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

