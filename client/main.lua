local Keys = {
  ["ESC"] = 322, ["F1"] = 288, ["F2"] = 289, ["F3"] = 170, ["F5"] = 166, ["F6"] = 167, ["F7"] = 168, ["F8"] = 169, ["F9"] = 56, ["F10"] = 57,
  ["~"] = 243, ["1"] = 157, ["2"] = 158, ["3"] = 160, ["4"] = 164, ["5"] = 165, ["6"] = 159, ["7"] = 161, ["8"] = 162, ["9"] = 163, ["-"] = 84, ["="] = 83, ["BACKSPACE"] = 177,
  ["TAB"] = 37, ["Q"] = 44, ["W"] = 32, ["E"] = 38, ["R"] = 45, ["T"] = 245, ["Y"] = 246, ["U"] = 303, ["P"] = 199, ["["] = 39, ["]"] = 40, ["ENTER"] = 18,
  ["CAPS"] = 137, ["A"] = 34, ["S"] = 8, ["D"] = 9, ["F"] = 23, ["G"] = 47, ["H"] = 74, ["K"] = 311, ["L"] = 182,
  ["LEFTSHIFT"] = 21, ["Z"] = 20, ["X"] = 73, ["C"] = 26, ["V"] = 0, ["B"] = 29, ["N"] = 249, ["M"] = 244, [","] = 82, ["."] = 81,
  ["LEFTCTRL"] = 36, ["LEFTALT"] = 19, ["SPACE"] = 22, ["RIGHTCTRL"] = 70,
  ["HOME"] = 213, ["PAGEUP"] = 10, ["PAGEDOWN"] = 11, ["DELETE"] = 178,
  ["LEFT"] = 174, ["RIGHT"] = 175, ["TOP"] = 27, ["DOWN"] = 173,
  ["NENTER"] = 201, ["N4"] = 108, ["N5"] = 60, ["N6"] = 107, ["N+"] = 96, ["N-"] = 97, ["N7"] = 117, ["N8"] = 61, ["N9"] = 118
}

ESX                           = nil
local GUI                     = {}
GUI.Time                      = 0
local OwnedMotells         = {}
local Blips                   = {}
local CurrentMotell         = nil
local CurrentMotellOwner    = nil
local LastMotell           = nil
local LastPart                = nil
local HasAlreadyEnteredMarker = false
local CurrentAction           = nil
local CurrentActionMsg        = ''
local CurrentActionData       = {}
local FirstSpawn              = true
local HasChest                = false

function DrawSub(text, time)
  ClearPrints()
  SetTextEntry_2('STRING')
  AddTextComponentString(text)
  DrawSubtitleTimed(time, 1)
end

function CreateBlips()

  for i=1, #Config.Motells, 1 do

    local motell = Config.Motells[i]

    if motell.entering ~= nil then

      Blips[motell.name] = AddBlipForCoord(motell.entering.x, motell.entering.y, motell.entering.z)

      SetBlipSprite (Blips[motell.name], 369)
      SetBlipDisplay(Blips[motell.name], 4)
      SetBlipScale  (Blips[motell.name], 1.0)
      SetBlipAsShortRange(Blips[motell.name], true)

      BeginTextCommandSetBlipName("STRING")
      AddTextComponentString(_U('free_prop'))
      EndTextCommandSetBlipName(Blips[motell.name])

    end
  end

end

function GetMotells()
  return Config.Motells
end

function GetMotell(name)

  for i=1, #Config.Motells, 1 do
    if Config.Motells[i].name == name then
      return Config.Motells[i]
    end
  end

end

function GetGateway(motell)

  for i=1, #Config.Motells, 1 do

    local motell2 = Config.Motells[i]

    if motell2.isGateway and motell2.name == motell.gateway then
      return motell2
    end

  end

end

function GetGatewayMotells(motell)

  local motells = {}

  for i=1, #Config.Motells, 1 do
    if Config.Motells[i].gateway == motell.name then
      table.insert(motells, Config.Motells[i])
    end
  end

  return motells

end

function EnterMotell(name, owner)

  local motell       = GetMotell(name)
  local playerPed      = GetPlayerPed(-1)
  CurrentMotell      = motell
  CurrentMotellOwner = owner

  for i=1, #Config.Motells, 1 do
    if Config.Motells[i].name ~= name then
      Config.Motells[i].disabled = true
    end
  end

  TriggerServerEvent('froberg_motell:saveLastMotell', name)

  Citizen.CreateThread(function()

    DoScreenFadeOut(800)

    while not IsScreenFadedOut() do
      Citizen.Wait(0)
    end

    for i=1, #motell.ipls, 1 do

      RequestIpl(motell.ipls[i])

      while not IsIplActive(motell.ipls[i]) do
        Citizen.Wait(0)
      end

    end

    SetEntityCoords(playerPed, motell.inside.x,  motell.inside.y,  motell.inside.z)

    DoScreenFadeIn(800)

    DrawSub(motell.label, 5000)
  end)

end

function ExitMotell(name)

  local motell  = GetMotell(name)
  local playerPed = GetPlayerPed(-1)
  local outside   = nil
  CurrentMotell = nil

  if motell.isSingle then
    outside = motell.outside
  else
    outside = GetGateway(motell).outside
  end

  TriggerServerEvent('froberg_motell:deleteLastMotell')

  Citizen.CreateThread(function()

    DoScreenFadeOut(800)

    while not IsScreenFadedOut() do
      Citizen.Wait(0)
    end

    SetEntityCoords(playerPed, outside.x,  outside.y,  outside.z)

    for i=1, #motell.ipls, 1 do
      RemoveIpl(motell.ipls[i])
    end

    for i=1, #Config.Motells, 1 do
      Config.Motells[i].disabled = false
    end

    DoScreenFadeIn(800)

  end)

end

function SetMotellOwned(name, owned)

  local motell     = GetMotell(name)
  local entering     = nil
  local enteringName = nil

  if motell.isSingle then
    entering     = motell.entering
    enteringName = motell.name
  else
    local gateway = GetGateway(motell)
    entering      = gateway.entering
    enteringName  = gateway.name
  end

  if owned then

    OwnedMotells[name] = true

    RemoveBlip(Blips[enteringName])

    Blips[enteringName] = AddBlipForCoord(entering.x,  entering.y,  entering.z)

    SetBlipSprite(Blips[enteringName], 357)
    SetBlipAsShortRange(Blips[enteringName], true)

    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(_U('property'))
    EndTextCommandSetBlipName(Blips[enteringName])

  else

    OwnedMotells[name] = nil

    local found = false

    for k,v in pairs(OwnedMotells) do

      local _motell = GetMotell(k)
      local _gateway  = GetGateway(_motell)

      if _gateway ~= nil then

        if _gateway.name == enteringName then
          found = true
          break
        end
      end

    end

    if not found then

      RemoveBlip(Blips[enteringName])

      Blips[enteringName] = AddBlipForCoord(entering.x,  entering.y,  entering.z)

      SetBlipSprite(Blips[enteringName], 369)
      SetBlipAsShortRange(Blips[enteringName], true)

      BeginTextCommandSetBlipName("STRING")
      AddTextComponentString(_U('free_prop'))
      EndTextCommandSetBlipName(Blips[enteringName])

     end

  end

end

function MotellIsOwned(motell)
  return OwnedMotells[motell.name] == true
end

function OpenMotellMenu(motell)

  local elements = {}

  if MotellIsOwned(motell) then

    table.insert(elements, {label = _U('enter'), value = 'enter'})

    if not Config.EnablePlayerManagement then
      table.insert(elements, {label = _U('leave'), value = 'leave'})
    end

  else

    if not Config.EnablePlayerManagement then
      table.insert(elements, {label = _U('rent'),   value = 'rent'})
    end

    table.insert(elements, {label = _U('visit'), value = 'visit'})

  end

  ESX.UI.Menu.Open(
    'default', GetCurrentResourceName(), 'motell',
    {
      title    = 'Motell Reception',
      align    = 'top-left',
      elements = elements,
    },
    function(data2, menu)

      menu.close()

      if data2.current.value == 'enter' then
        TriggerEvent('instance:create', 'motell', {motell = motell.name, owner = ESX.GetPlayerData().identifier})
      end

      if data2.current.value == 'leave' then
        TriggerServerEvent('froberg_motell:removeOwnedMotell', motell.name)
      end

      if data2.current.value == 'rent' then
        TriggerServerEvent('froberg_motell:rentMotell', motell.name)
      end

      if data2.current.value == 'visit' then
        TriggerEvent('instance:create', 'motell', {motell = motell.name, owner = ESX.GetPlayerData().identifier})
      end

    end,
    function(data, menu)

        menu.close()

        CurrentAction     = 'motell_menu'
        CurrentActionMsg  = _U('press_to_menu')
        CurrentActionData = {motell = motell}
    end
  )

end

function OpenGatewayMenu(motell)

  if Config.EnablePlayerManagement then
    OpenGatewayOwnedMotellsMenu(gatewayMotells)
  else

    ESX.UI.Menu.Open(
      'default', GetCurrentResourceName(), 'gateway',
      {
        title    = motell.name,
        align    = 'top-left',
        elements = {
          {label = _U('owned_properties'),    value = 'owned_motells'},
          {label = _U('available_properties'), value = 'available_motells'},
        }
      },
      function(data, menu)

        if data.current.value == 'owned_motells' then
          OpenGatewayOwnedMotellsMenu(motell)
        end

        if data.current.value == 'available_motells' then
          OpenGatewayAvailableMotellsMenu(motell)
        end

      end,
      function(data, menu)

        menu.close()

        CurrentAction     = 'gateway_menu'
        CurrentActionMsg  = _U('press_to_menu')
        CurrentActionData = {motell = motell}

      end
    )

  end

end

function OpenGatewayOwnedMotellsMenu(motell)

  local gatewayMotells = GetGatewayMotells(motell)
  local elements          = {}

  for i=1, #gatewayMotells, 1 do

    if MotellIsOwned(gatewayMotells[i]) then
      table.insert(elements, {
        label = gatewayMotells[i].label,
        value = gatewayMotells[i].name
      })
    end

  end

  ESX.UI.Menu.Open(
    'default', GetCurrentResourceName(), 'gateway_owned_motells',
    {
      title    = motell.name .. ' - ' .. _U('owned_motells'),
      align    = 'top-left',
      elements = elements,
    },
    function(data, menu)

      menu.close()

      local elements = {
        {label = _U('enter'), value = 'enter'}
      }

      if not Config.EnablePlayerManagement then
        table.insert(elements, {label = _U('leave'), value = 'leave'})
      end

      ESX.UI.Menu.Open(
        'default', GetCurrentResourceName(), 'gateway_owned_motells_actions',
        {
          title    = data.current.label,
          align    = 'top-left',
          elements = elements,
        },
        function(data2, menu)

          menu.close()

          if data2.current.value == 'enter' then
            TriggerEvent('instance:create', 'motell', {motell = data.current.value, owner = ESX.GetPlayerData().identifier})
          end

          if data2.current.value == 'leave' then
            TriggerServerEvent('froberg_motell:removeOwnedMotell', data.current.value)
          end

        end,
        function(data, menu)
          menu.close()
        end
      )

    end,
    function(data, menu)
      menu.close()
    end
  )

end

function OpenGatewayAvailableMotellsMenu(motell)

  local gatewayMotells = GetGatewayMotells(motell)
  local elements          = {}

  for i=1, #gatewayMotells, 1 do

    if not MotellIsOwned(gatewayMotells[i]) then
      table.insert(elements, {
        label = gatewayMotells[i].label .. ' SEK' .. gatewayMotells[i].price,
        value = gatewayMotells[i].name,
        price = gatewayMotells[i].price
      })
    end

  end

  ESX.UI.Menu.Open(
    'default', GetCurrentResourceName(), 'gateway_available_motells',
    {
      title    = motell.name.. ' - ' .. _U('available_motells'),
      align    = 'top-left',
      elements = elements,
    },
    function(data, menu)

      menu.close()

      ESX.UI.Menu.Open(
        'default', GetCurrentResourceName(), 'gateway_available_motells_actions',
        {
          title    = motell.name,
          align    = 'top-left',
          elements = {
            {label = _U('rent'),   value = 'rent'},
            {label = _U('visit'), value = 'visit'},
          },
        },
        function(data2, menu)
          menu.close()

          if data2.current.value == 'rent' then
            TriggerServerEvent('froberg_motell:rentMotell', data.current.value)
          end

          if data2.current.value == 'visit' then
            TriggerEvent('instance:create', 'motell', {motell = data.current.value, owner = ESX.GetPlayerData().identifier})
          end

        end,
        function(data, menu)
          menu.close()
        end
      )

    end,
    function(data, menu)
      menu.close()
    end
  )

end

function OpenRoomMenu(motell, owner)

  local entering = nil
  local elements = {}

  if motell.isSingle then
    entering = motell.entering
  else
    entering = GetGateway(motell).entering
  end

  table.insert(elements, {label = _U('invite_player'),  value = 'invite_player'})

  if CurrentMotellOwner == owner then
    table.insert(elements, {label = _U('player_clothes'), value = 'player_dressing'})
    table.insert(elements, {label = _U('remove_cloth'), value = 'remove_cloth'})
  end

  table.insert(elements, {label = _U('remove_object'),  value = 'room_inventory'})
  table.insert(elements, {label = _U('deposit_object'), value = 'player_inventory'})

  ESX.UI.Menu.CloseAll()

  ESX.UI.Menu.Open(
    'default', GetCurrentResourceName(), 'room',
    {
      title    = motell.label,
      align    = 'top-left',
      elements = elements,
    },
    function(data, menu)

      if data.current.value == 'invite_player' then

        local playersInArea = ESX.Game.GetPlayersInArea(entering, 10.0)
        local elements      = {}

        for i=1, #playersInArea, 1 do
          if playersInArea[i] ~= PlayerId() then
            table.insert(elements, {label = GetPlayerName(playersInArea[i]), value = playersInArea[i]})
          end
        end

        ESX.UI.Menu.Open(
          'default', GetCurrentResourceName(), 'room_invite',
          {
            title    = motell.label .. ' - ' .. _U('invite'),
            align    = 'top-left',
            elements = elements,
          },
          function(data, menu)
            TriggerEvent('instance:invite', 'motell', GetPlayerServerId(data.current.value), {motell = motell.name, owner = owner})
            ESX.ShowNotification(_U('you_invited', GetPlayerName(data.current.value)))
          end,
          function(data, menu)
            menu.close()
          end
        )

      end

      if data.current.value == 'player_dressing' then

        ESX.TriggerServerCallback('froberg_motell:getPlayerDressing', function(dressing)

          local elements = {}

          for i=1, #dressing, 1 do
            table.insert(elements, {label = dressing[i], value = i})
          end

          ESX.UI.Menu.Open(
            'default', GetCurrentResourceName(), 'player_dressing',
            {
              title    = motell.label .. ' - ' .. _U('player_clothes'),
              align    = 'top-left',
              elements = elements,
            },
            function(data, menu)

              TriggerEvent('skinchanger:getSkin', function(skin)

                ESX.TriggerServerCallback('froberg_motell:getPlayerOutfit', function(clothes)

                  TriggerEvent('skinchanger:loadClothes', skin, clothes)
                  TriggerEvent('esx_skin:setLastSkin', skin)

                  TriggerEvent('skinchanger:getSkin', function(skin)
                    TriggerServerEvent('esx_skin:save', skin)
                  end)

                end, data.current.value)

              end)

            end,
            function(data, menu)
              menu.close()
            end
          )

        end)

      end
        
      if data.current.value == 'remove_cloth' then
          ESX.TriggerServerCallback('froberg_motell:getPlayerDressing', function(dressing)
              local elements = {}
      
              for i=1, #dressing, 1 do
                  table.insert(elements, {label = dressing[i].label, value = i})
              end
              
              ESX.UI.Menu.Open(
              'default', GetCurrentResourceName(), 'remove_cloth',
              {
                title    = motell.label .. ' - ' .. _U('remove_cloth'),
                align    = 'top-left',
                elements = elements,
              },
              function(data, menu)
                  menu.close()
                  TriggerServerEvent('froberg_motell:removeOutfit', data.current.value)
                  ESX.ShowNotification(_U('removed_cloth'))
              end,
              function(data, menu)
                menu.close()
              end
            )
          end)
      end

      if data.current.value == 'room_inventory' then
        OpenRoomInventoryMenu(motell, owner)
      end

      if data.current.value == 'player_inventory' then
        OpenPlayerInventoryMenu(motell, owner)
      end

    end,
    function(data, menu)

      menu.close()

      CurrentAction     = 'room_menu'
      CurrentActionMsg  = _U('press_to_menu')
      CurrentActionData = {motell = motell, owner = owner}
    end
  )

end

function OpenRoomInventoryMenu(motell, owner)

  ESX.TriggerServerCallback('froberg_motell:getMotellInventory', function(inventory)

    local elements = {}

    table.insert(elements, {label = _U('dirty_money') .. inventory.blackMoney, type = 'item_account', value = 'black_money'})

    for i=1, #inventory.items, 1 do

      local item = inventory.items[i]

      if item.count > 0 then
        table.insert(elements, {label = item.label .. ' x' .. item.count, type = 'item_standard', value = item.name})
      end

    end

    for i=1, #inventory.weapons, 1 do
      local weapon = inventory.weapons[i]
      table.insert(elements, {label = ESX.GetWeaponLabel(weapon.name) .. ' [' .. weapon.ammo .. ']', type = 'item_weapon', value = weapon.name, ammo = weapon.ammo})
    end

    ESX.UI.Menu.Open(
      'default', GetCurrentResourceName(), 'room_inventory',
      {
        title    = motell.label .. ' - ' .. _U('inventory'),
        align    = 'top-left',
        elements = elements,
      },
      function(data, menu)

        if data.current.type == 'item_weapon' then

          menu.close()

          TriggerServerEvent('froberg_motell:getItem', owner, data.current.type, data.current.value, data.current.ammo)

          ESX.SetTimeout(300, function()
            OpenRoomInventoryMenu(motell, owner)
          end)

        else

          ESX.UI.Menu.Open(
            'dialog', GetCurrentResourceName(), 'get_item_count',
            {
              title = _U('amount'),
            },
            function(data2, menu)

              local quantity = tonumber(data2.value)

              if quantity == nil then
                ESX.ShowNotification(_U('amount_invalid'))
              else

                menu.close()

                TriggerServerEvent('froberg_motell:getItem', owner, data.current.type, data.current.value, quantity)

                ESX.SetTimeout(300, function()
                  OpenRoomInventoryMenu(motell, owner)
                end)

              end

            end,
            function(data2,menu)
              menu.close()
            end
          )

        end

      end,
      function(data, menu)
        menu.close()
      end
    )

  end, owner)

end

function OpenPlayerInventoryMenu(motell, owner)

  ESX.TriggerServerCallback('froberg_motell:getPlayerInventory', function(inventory)

    local elements = {}

    table.insert(elements, {label = _U('dirty_money') .. inventory.blackMoney, type = 'item_account', value = 'black_money'})

    for i=1, #inventory.items, 1 do

      local item = inventory.items[i]

      if item.count > 0 then
        table.insert(elements, {label = item.label .. ' x' .. item.count, type = 'item_standard', value = item.name})
      end

    end

    local playerPed  = GetPlayerPed(-1)
    local weaponList = ESX.GetWeaponList()

    for i=1, #weaponList, 1 do

      local weaponHash = GetHashKey(weaponList[i].name)

      if HasPedGotWeapon(playerPed,  weaponHash,  false) and weaponList[i].name ~= 'WEAPON_UNARMED' then
        local ammo = GetAmmoInPedWeapon(playerPed, weaponHash)
        table.insert(elements, {label = weaponList[i].label .. ' [' .. ammo .. ']', type = 'item_weapon', value = weaponList[i].name, ammo = ammo})
      end

    end

    ESX.UI.Menu.Open(
      'default', GetCurrentResourceName(), 'player_inventory',
      {
        title    = motell.label .. ' - ' .. _U('inventory'),
        align    = 'top-left',
        elements = elements,
      },
      function(data, menu)

        if data.current.type == 'item_weapon' then

          menu.close()

          TriggerServerEvent('froberg_motell:putItem', owner, data.current.type, data.current.value, data.current.ammo)

          ESX.SetTimeout(300, function()
            OpenPlayerInventoryMenu(motell, owner)
          end)

        else

          ESX.UI.Menu.Open(
            'dialog', GetCurrentResourceName(), 'put_item_count',
            {
              title = _U('amount'),
            },
            function(data2, menu)

              menu.close()

              TriggerServerEvent('froberg_motell:putItem', owner, data.current.type, data.current.value, tonumber(data2.value))

              ESX.SetTimeout(300, function()
                OpenPlayerInventoryMenu(motell, owner)
              end)

            end,
            function(data2,menu)
              menu.close()
            end
          )

        end

      end,
      function(data, menu)
        menu.close()
      end
    )

  end)

end

AddEventHandler('instance:loaded', function()

  TriggerEvent('instance:registerType', 'motell',
    function(instance)
      EnterMotell(instance.data.motell, instance.data.owner)
    end,
    function(instance)
      ExitMotell(instance.data.motell)
    end
  )

end)

AddEventHandler('playerSpawned', function()

  if FirstSpawn then

    Citizen.CreateThread(function()

      while not ESX.IsPlayerLoaded() do
        Citizen.Wait(0)
      end

      ESX.TriggerServerCallback('froberg_motell:getLastMotell', function(motellName)
        if motellName ~= nil then
          TriggerEvent('instance:create', 'motell', {motell = motellName, owner = ESX.GetPlayerData().identifier})
        end
      end)

    end)

    FirstSpawn = false
  end

end)

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
  PlayerLoaded = true
end)

AddEventHandler('froberg_motell:getMotells', function(cb)
  cb(GetMotells())
end)

AddEventHandler('froberg_motell:getMotell', function(name, cb)
  cb(GetMotell(name))
end)

AddEventHandler('froberg_motell:getGateway', function(motell, cb)
  cb(GetGateway(motell))
end)

RegisterNetEvent('froberg_motell:setMotellOwned')
AddEventHandler('froberg_motell:setMotellOwned', function(name, owned)
  SetMotellOwned(name, owned)
end)

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)

  ESX.TriggerServerCallback('froberg_motell:getOwnedMotells', function(ownedMotells)
    for i=1, #ownedMotells, 1 do
      SetMotellOwned(ownedMotells[i], true)
    end
  end)

end)

RegisterNetEvent('instance:onCreate')
AddEventHandler('instance:onCreate', function(instance)

  if instance.type == 'motell' then
    TriggerEvent('instance:enter', instance)
  end

end)

RegisterNetEvent('instance:onEnter')
AddEventHandler('instance:onEnter', function(instance)

  if instance.type == 'motell' then

    local motell = GetMotell(instance.data.motell)
    local isHost   = GetPlayerFromServerId(instance.host) == PlayerId()
    local isOwned  = false

    if MotellIsOwned(motell) == true then
      isOwned = true
    end

    if(isOwned or not isHost) then
      HasChest = true
    else
      HasChest = false
    end

  end

end)

RegisterNetEvent('instance:onPlayerLeft')
AddEventHandler('instance:onPlayerLeft', function(instance, player)
  if player == instance.host then
    TriggerEvent('instance:leave')
  end
end)

AddEventHandler('froberg_motell:hasEnteredMarker', function(name, part)

  local motell = GetMotell(name)

  if part == 'entering' then

    if motell.isSingle then
      CurrentAction     = 'motell_menu'
      CurrentActionMsg  = _U('press_to_menu')
      CurrentActionData = {motell = motell}
    else
      CurrentAction     = 'gateway_menu'
      CurrentActionMsg  = _U('press_to_menu')
      CurrentActionData = {motell = motell}
    end

  end

  if part == 'exit' then
    CurrentAction     = 'room_exit'
    CurrentActionMsg  = _U('press_to_exit')
    CurrentActionData = {motellName = name}
  end

  if part == 'roomMenu' then
    CurrentAction     = 'room_menu'
    CurrentActionMsg  = _U('press_to_menu')
    CurrentActionData = {motell = motell, owner = CurrentMotellOwner}
  end

end)

AddEventHandler('froberg_motell:hasExitedMarker', function(name, part)
  ESX.UI.Menu.CloseAll()
  CurrentAction = nil
end)

-- Init
Citizen.CreateThread(function()

  while ESX == nil do
    TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
    Citizen.Wait(0)
  end

  ESX.TriggerServerCallback('froberg_motell:getMotells', function(motells)
    Config.Motells = motells
    CreateBlips()
  end)

end)

-- Display markers
Citizen.CreateThread(function()
  while true do

    Wait(0)

    local coords = GetEntityCoords(GetPlayerPed(-1))

    for i=1, #Config.Motells, 1 do

      local motell = Config.Motells[i]
      local isHost   = false

      if(motell.entering ~= nil and not motell.disabled and GetDistanceBetweenCoords(coords, motell.entering.x, motell.entering.y, motell.entering.z, true) < Config.DrawDistance) then
        DrawMarker(Config.MarkerType, motell.entering.x, motell.entering.y, motell.entering.z, 0.0, 0.0, 0.0, 0, 0.0, 0.0, Config.MarkerSize.x, Config.MarkerSize.y, Config.MarkerSize.z, Config.MarkerColor.r, Config.MarkerColor.g, Config.MarkerColor.b, 100, false, true, 2, false, false, false, false)
      end

      if(motell.exit ~= nil and not motell.disabled and GetDistanceBetweenCoords(coords, motell.exit.x, motell.exit.y, motell.exit.z, true) < Config.DrawDistance) then
        DrawMarker(Config.MarkerType, motell.exit.x, motell.exit.y, motell.exit.z, 0.0, 0.0, 0.0, 0, 0.0, 0.0, Config.MarkerSize.x, Config.MarkerSize.y, Config.MarkerSize.z, Config.MarkerColor.r, Config.MarkerColor.g, Config.MarkerColor.b, 100, false, true, 2, false, false, false, false)
      end

      if(motell.roomMenu ~= nil and HasChest and not motell.disabled and GetDistanceBetweenCoords(coords, motell.roomMenu.x, motell.roomMenu.y, motell.roomMenu.z, true) < Config.DrawDistance) then
        DrawMarker(Config.MarkerType, motell.roomMenu.x, motell.roomMenu.y, motell.roomMenu.z, 0.0, 0.0, 0.0, 0, 0.0, 0.0, Config.MarkerSize.x, Config.MarkerSize.y, Config.MarkerSize.z, Config.RoomMenuMarkerColor.r, Config.RoomMenuMarkerColor.g, Config.RoomMenuMarkerColor.b, 100, false, true, 2, false, false, false, false)
      end

    end

  end
end)

-- Enter / Exit marker events
Citizen.CreateThread(function()
  while true do

    Wait(0)

    local coords          = GetEntityCoords(GetPlayerPed(-1))
    local isInMarker      = false
    local currentMotell = nil
    local currentPart     = nil

    for i=1, #Config.Motells, 1 do

      local motell = Config.Motells[i]

      if(motell.entering ~= nil and not motell.disabled and GetDistanceBetweenCoords(coords, motell.entering.x, motell.entering.y, motell.entering.z, true) < Config.MarkerSize.x) then
        isInMarker      = true
        currentMotell = motell.name
        currentPart     = 'entering'
      end

      if(motell.exit ~= nil and not motell.disabled and GetDistanceBetweenCoords(coords, motell.exit.x, motell.exit.y, motell.exit.z, true) < Config.MarkerSize.x) then
        isInMarker      = true
        currentMotell = motell.name
        currentPart     = 'exit'
      end

      if(motell.inside ~= nil and not motell.disabled and GetDistanceBetweenCoords(coords, motell.inside.x, motell.inside.y, motell.inside.z, true) < Config.MarkerSize.x) then
        isInMarker      = true
        currentMotell = motell.name
        currentPart     = 'inside'
      end

      if(motell.outside ~= nil and not motell.disabled and GetDistanceBetweenCoords(coords, motell.outside.x, motell.outside.y, motell.outside.z, true) < Config.MarkerSize.x) then
        isInMarker      = true
        currentMotell = motell.name
        currentPart     = 'outside'
      end

      if(motell.roomMenu ~= nil and HasChest and not motell.disabled and GetDistanceBetweenCoords(coords, motell.roomMenu.x, motell.roomMenu.y, motell.roomMenu.z, true) < Config.MarkerSize.x) then
        isInMarker      = true
        currentMotell = motell.name
        currentPart     = 'roomMenu'
      end

    end

    if isInMarker and not HasAlreadyEnteredMarker or (isInMarker and (LastMotell ~= currentMotell or LastPart ~= currentPart) ) then

      HasAlreadyEnteredMarker = true
      LastMotell            = currentMotell
      LastPart                = currentPart

      TriggerEvent('froberg_motell:hasEnteredMarker', currentMotell, currentPart)
    end

    if not isInMarker and HasAlreadyEnteredMarker then

      HasAlreadyEnteredMarker = false

      TriggerEvent('froberg_motell:hasExitedMarker', LastMotell, LastPart)
    end

  end
end)

-- Key controls
Citizen.CreateThread(function()
  while true do

    Citizen.Wait(0)

    if CurrentAction ~= nil then

      SetTextComponentFormat('STRING')
      AddTextComponentString(CurrentActionMsg)
      DisplayHelpTextFromStringLabel(0, 0, 1, -1)

      if IsControlPressed(0,  Keys['E']) and (GetGameTimer() - GUI.Time) > 300 then

        if CurrentAction == 'motell_menu' then
          OpenMotellMenu(CurrentActionData.motell)
        end

        if CurrentAction == 'gateway_menu' then

          if Config.EnablePlayerManagement then
            OpenGatewayOwnedMotellsMenu(CurrentActionData.motell)
          else
            OpenGatewayMenu(CurrentActionData.motell)
          end

        end

        if CurrentAction == 'room_menu' then
          OpenRoomMenu(CurrentActionData.motell, CurrentActionData.owner)
        end

        if CurrentAction == 'room_exit' then
          TriggerEvent('instance:leave')
        end

        CurrentAction = nil
        GUI.Time      = GetGameTimer()

      end

    end

  end
end)
