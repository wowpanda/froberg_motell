ESX = nil

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

function GetMotell(name)

  for i=1, #Config.Motells, 1 do
    if Config.Motells[i].name == name then
      return Config.Motells[i]
    end
  end

end

function SetMotellOwned(name, price, rented, owner)

  MySQL.Async.execute(
    'INSERT INTO owned_motell (name, price, rented, owner) VALUES (@name, @price, @rented, @owner)',
    {
      ['@name']   = name,
      ['@price']  = price,
      ['@rented'] = (rented and 1 or 0),
      ['@owner']  = owner
    },
    function(rowsChanged)

      local xPlayers = ESX.GetPlayers()

      for i=1, #xPlayers, 1 do

        local xPlayer = ESX.GetPlayerFromId(xPlayers[i])

        if xPlayer.identifier == owner then

          TriggerClientEvent('froberg_motell:setMotellOwned', xPlayer.source, name, true)

          if rented then
              TriggerClientEvent("pNotify:SendNotification",-1, {text = 'Du <font color="aqua">hyrde</font> ett motell rum för ' .. price .. '<font color="lime">SEK</font>/dygnet', type = "error", timeout = 5000, layout = "bottomCenter"})
            --TriggerClientEvent('esx:showNotification', xPlayer.source, _U('rented_for') .. price)
          else
            TriggerClientEvent('esx:showNotification', xPlayer.source, _U('purchased_for') .. price)
          end

          break
        end
      end

    end
  )

end

function RemoveOwnedMotell(name, owner)

  MySQL.Async.execute(
    'DELETE FROM owned_motell WHERE name = @name AND owner = @owner',
    {
      ['@name']  = name,
      ['@owner'] = owner
    },
    function(rowsChanged)

      local xPlayers = ESX.GetPlayers()

      for i=1, #xPlayers, 1 do

        local xPlayer = ESX.GetPlayerFromId(xPlayers[i])

        if xPlayer.identifier == owner then
          TriggerClientEvent('froberg_motell:setMotellOwned', xPlayer.source, name, false)
          TriggerClientEvent('esx:showNotification', xPlayer.source, _U('made_property'))
          break
        end
      end

    end
  )

end

AddEventHandler('onMySQLReady', function ()

  MySQL.Async.fetchAll('SELECT * FROM motell', {}, function(motells)

    for i=1, #motells, 1 do

      local entering  = nil
      local exit      = nil
      local inside    = nil
      local outside   = nil
      local isSingle  = nil
      local isRoom    = nil
      local isGateway = nil
      local roomMenu  = nil

      if motells[i].entering ~= nil then
        entering = json.decode(motells[i].entering)
      end

      if motells[i].exit ~= nil then
        exit = json.decode(motells[i].exit)
      end

      if motells[i].inside ~= nil then
        inside = json.decode(motells[i].inside)
      end

      if motells[i].outside ~= nil then
        outside = json.decode(motells[i].outside)
      end

      if motells[i].is_single == 0 then
        isSingle = false
      else
        isSingle = true
      end

      if motells[i].is_room == 0 then
        isRoom = false
      else
        isRoom = true
      end

      if motells[i].is_gateway == 0 then
        isGateway = false
      else
        isGateway = true
      end

      if motells[i].room_menu ~= nil then
        roomMenu = json.decode(motells[i].room_menu)
      end

      table.insert(Config.Motells, {
        name      = motells[i].name,
        label     = motells[i].label,
        entering  = entering,
        exit      = exit,
        inside    = inside,
        outside   = outside,
        ipls      = json.decode(motells[i].ipls),
        gateway   = motells[i].gateway,
        isSingle  = isSingle,
        isRoom    = isRoom,
        isGateway = isGateway,
        roomMenu  = roomMenu,
        price     = motells[i].price
      })

    end

  end)

end)

AddEventHandler('froberg_ownedmotell:getOwnedMotells', function(cb)

  MySQL.Async.fetchAll(
    'SELECT * FROM owned_motell',
    {},
    function(result)

      local motells = {}

      for i=1, #result, 1 do

				table.insert(motells, {
					id     = result[i].id,
					name   = result[i].name,
					price  = result[i].price,
					rented = (result[i].rented == 1 and true or false),
					owner  = result[i].owner,
				})
			end

      cb(motells)

    end
  )

end)

AddEventHandler('froberg_motell:setMotellOwned', function(name, price, rented, owner)
  SetMotellOwned(name, price, rented, owner)
end)

AddEventHandler('froberg_motell:removeOwnedMotell', function(name, owner)
  RemoveOwnedMotell(name, owner)
end)

RegisterServerEvent('froberg_motell:rentMotell')
AddEventHandler('froberg_motell:rentMotell', function(motellName)

  local xPlayer  = ESX.GetPlayerFromId(source)
  local motell = GetMotell(motellName)

  SetMotellOwned(motellName, motell.price / 200, true, xPlayer.identifier)

end)

RegisterServerEvent('froberg_motell:buyMotell')
AddEventHandler('froberg_motell:buyMotell', function(motellName)

  local xPlayer  = ESX.GetPlayerFromId(source)
  local motell = GetMotell(motellName)

  if motell.price <= xPlayer.get('money') then

    xPlayer.removeMoney(motell.price)
    SetMotellOwned(motellName, motell.price, false, xPlayer.identifier)

  else
    TriggerClientEvent('esx:showNotification', source, _U('not_enough'))
  end

end)

RegisterServerEvent('froberg_motell:removeOwnedMotell')
AddEventHandler('froberg_motell:removeOwnedMotell', function(motellName)

  local xPlayer = ESX.GetPlayerFromId(source)

  RemoveOwnedMotell(motellName, xPlayer.identifier)

end)

AddEventHandler('froberg_motell:removeOwnedMotellIdentifier', function(motellName, identifier)
  RemoveOwnedMotell(motellName, identifier)
end)

RegisterServerEvent('froberg_motell:saveLastMotell')
AddEventHandler('froberg_motell:saveLastMotell', function(motell)

  local xPlayer = ESX.GetPlayerFromId(source)

  MySQL.Async.execute(
    'UPDATE users SET last_motell = @last_motell WHERE identifier = @identifier',
    {
      ['@last_motell'] = motell,
      ['@identifier']    = xPlayer.identifier
    }
  )

end)

RegisterServerEvent('froberg_motell:deleteLastMotell')
AddEventHandler('froberg_motell:deleteLastMotell', function()
  local xPlayer = ESX.GetPlayerFromId(source)

  MySQL.Async.execute(
    'UPDATE users SET last_motell = NULL WHERE identifier = @identifier',
    {
      ['@identifier']    = xPlayer.identifier
    }
  )
end)

RegisterServerEvent('froberg_motell:getItem')
AddEventHandler('froberg_motell:getItem', function(owner, type, item, count)

	local _source      = source
	local xPlayer      = ESX.GetPlayerFromId(_source)
	local xPlayerOwner = ESX.GetPlayerFromIdentifier(owner)

	if type == 'item_standard' then
		local sourceItem = xPlayer.getInventoryItem(item)
		
		TriggerEvent('esx_addoninventory:getInventory', 'motell', xPlayerOwner.identifier, function(inventory)
			local inventoryItem = inventory.getItem(item)
			
			-- is there enough in the property?
			if count > 0 and inventoryItem.count >= count then
			
				-- can the player carry the said amount of x item?
				if sourceItem.limit ~= -1 and (sourceItem.count + count) > sourceItem.limit then
					TriggerClientEvent('esx:showNotification', _source, _U('player_cannot_hold'))
				else
					inventory.removeItem(item, count)
					xPlayer.addInventoryItem(item, count)
					TriggerClientEvent('esx:showNotification', _source, _U('have_withdrawn', count, inventoryItem.label))
				end
			else
				TriggerClientEvent('esx:showNotification', _source, _U('not_enough_in_property'))
			end
		end)
	end

  if type == 'item_account' then

    TriggerEvent('esx_addonaccount:getAccount', 'motell_' .. item, xPlayerOwner.identifier, function(account)

      local roomAccountMoney = account.money

      if roomAccountMoney >= count then
        account.removeMoney(count)
        xPlayer.addAccountMoney(item, count)
      else
        TriggerClientEvent('esx:showNotification', _source, _U('amount_invalid'))
      end

    end)

  end

  if type == 'item_weapon' then

    TriggerEvent('esx_datastore:getDataStore', 'motell', xPlayerOwner.identifier, function(store)

      local storeWeapons = store.get('weapons')

      if storeWeapons == nil then
        storeWeapons = {}
      end

      local weaponName   = nil
      local ammo         = nil

      for i=1, #storeWeapons, 1 do
        if storeWeapons[i].name == item then

          weaponName = storeWeapons[i].name
          ammo       = storeWeapons[i].ammo

          table.remove(storeWeapons, i)

          break
        end
      end

      store.set('weapons', storeWeapons)

      xPlayer.addWeapon(weaponName, ammo)

    end)

  end

end)

RegisterServerEvent('froberg_motell:putItem')
AddEventHandler('froberg_motell:putItem', function(owner, type, item, count)

  local _source      = source
  local xPlayer      = ESX.GetPlayerFromId(_source)
  local xPlayerOwner = ESX.GetPlayerFromIdentifier(owner)

  if type == 'item_standard' then

    local playerItemCount = xPlayer.getInventoryItem(item).count

    if playerItemCount >= count then
     
      TriggerEvent('esx_addoninventory:getInventory', 'motell', xPlayerOwner.identifier, function(inventory)
        xPlayer.removeInventoryItem(item, count)
        inventory.addItem(item, count)
        TriggerClientEvent('esx:showNotification', _source, _U('have_deposited', count, inventory.getItem(item).label))
      end)
      
    else
      TriggerClientEvent('esx:showNotification', _source, _U('invalid_quantity'))
    end

  end

  if type == 'item_account' then

    local playerAccountMoney = xPlayer.getAccount(item).money

    if playerAccountMoney >= count then

      xPlayer.removeAccountMoney(item, count)

      TriggerEvent('esx_addonaccount:getAccount', 'motell_' .. item, xPlayerOwner.identifier, function(account)
        account.addMoney(count)
      end)

    else
      TriggerClientEvent('esx:showNotification', _source, _U('amount_invalid'))
    end

  end

  if type == 'item_weapon' then

    TriggerEvent('esx_datastore:getDataStore', 'motell', xPlayerOwner.identifier, function(store)

      local storeWeapons = store.get('weapons')

      if storeWeapons == nil then
        storeWeapons = {}
      end

      table.insert(storeWeapons, {
        name = item,
        ammo = count
      })

      store.set('weapons', storeWeapons)

      xPlayer.removeWeapon(item)

    end)

  end

end)

ESX.RegisterServerCallback('froberg_motell:getMotells', function(source, cb)
  cb(Config.Motells)
end)

ESX.RegisterServerCallback('froberg_motell:getOwnedMotells', function(source, cb)

  local xPlayer = ESX.GetPlayerFromId(source)

  MySQL.Async.fetchAll(
    'SELECT * FROM owned_motell WHERE owner = @owner',
    {
      ['@owner'] = xPlayer.identifier
    },
    function(ownedMotells)

      local motells = {}

      for i=1, #ownedMotells, 1 do
        table.insert(motells, ownedMotells[i].name)
      end

      cb(motells)
    end
  )

end)

ESX.RegisterServerCallback('froberg_motell:getLastMotell', function(source, cb)

  local xPlayer = ESX.GetPlayerFromId(source)

  MySQL.Async.fetchAll(
    'SELECT * FROM users WHERE identifier = @identifier',
    {
      ['@identifier'] = xPlayer.identifier
    },
    function(users)
      cb(users[1].last_motell)
    end
  )

end)

ESX.RegisterServerCallback('froberg_motell:getMotellInventory', function(source, cb, owner)

  local xPlayer    = ESX.GetPlayerFromIdentifier(owner)
  local blackMoney = 0
  local items      = {}
  local weapons    = {}

  TriggerEvent('esx_addonaccount:getAccount', 'motell_black_money', xPlayer.identifier, function(account)
    blackMoney = account.money
  end)

  TriggerEvent('esx_addoninventory:getInventory', 'motell', xPlayer.identifier, function(inventory)
    items = inventory.items
  end)

  TriggerEvent('esx_datastore:getDataStore', 'motell', xPlayer.identifier, function(store)

    local storeWeapons = store.get('weapons')

    if storeWeapons ~= nil then
      weapons = storeWeapons
    end

  end)

  cb({
    blackMoney = blackMoney,
    items      = items,
    weapons    = weapons
  })

end)

ESX.RegisterServerCallback('froberg_motell:getPlayerInventory', function(source, cb)

  local xPlayer    = ESX.GetPlayerFromId(source)
  local blackMoney = xPlayer.getAccount('black_money').money
  local items      = xPlayer.inventory

  cb({
    blackMoney = blackMoney,
    items      = items
  })

end)

ESX.RegisterServerCallback('froberg_motell:getPlayerDressing', function(source, cb)

  local xPlayer  = ESX.GetPlayerFromId(source)

  TriggerEvent('esx_datastore:getDataStore', 'motell', xPlayer.identifier, function(store)

    local count    = store.count('dressing')
    local labels   = {}

    for i=1, count, 1 do
      local entry = store.get('dressing', i)
      table.insert(labels, entry.label)
    end

    cb(labels)

  end)

end)

ESX.RegisterServerCallback('froberg_motell:getPlayerOutfit', function(source, cb, num)

  local xPlayer  = ESX.GetPlayerFromId(source)

  TriggerEvent('esx_datastore:getDataStore', 'motell', xPlayer.identifier, function(store)
    local outfit = store.get('dressing', num)
    cb(outfit.skin)
  end)

end)

RegisterServerEvent('froberg_motell:removeOutfit')
AddEventHandler('froberg_motell:removeOutfit', function(label)

    local xPlayer = ESX.GetPlayerFromId(source)

    TriggerEvent('esx_datastore:getDataStore', 'motell', xPlayer.identifier, function(store)

        local dressing = store.get('dressing')

        if dressing == nil then
            dressing = {}
        end

        label = label
        
        table.remove(dressing, label)

        store.set('dressing', dressing)

    end)

end)

function PayRent()
	MySQL.Async.fetchAll(
	'SELECT * FROM owned_motell WHERE rented = 1', {},
	function (result)
		for i=1, #result, 1 do
			local xPlayer = ESX.GetPlayerFromIdentifier(result[i].owner)

			-- message player if connected
			if xPlayer ~= nil then
				xPlayer.removeBank(result[i].price)
				TriggerClientEvent('esx:showNotification', xPlayer.source, _U('paid_rent', result[i].price))
			else -- pay rent either way
				MySQL.Sync.execute(
				'UPDATE users SET bank = bank - @bank WHERE identifier = @identifier',
				{
					['@bank']       = result[i].price,
					['@identifier'] = result[i].owner
				})
			end

			TriggerEvent('esx_addonaccount:getSharedAccount', 'society_realestateagent', function(account)
				account.addMoney(result[i].price)
			end)
		end
	end)
end

TriggerEvent('cron:runAt', 1, 0, PayRent)
