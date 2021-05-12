ESX = nil

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

local ServerBoombacks = {}

RegisterNetEvent('pyrp_boombox:placeBoombox')
AddEventHandler('pyrp_boombox:placeBoombox', function(entityId)
	ServerBoombacks[entityId] = {
		ytlink = nil,
		playing = false,
		volume = 20,
		connected = nil
	}
	TriggerClientEvent('pyrp_boombox:ClientBoomBoxList', -1, ServerBoombacks)
end)

RegisterNetEvent('pyrp_boombox:connectBoombox')
AddEventHandler('pyrp_boombox:connectBoombox', function(entityId, ytLink, volume)
	local xPlayer = ESX.GetPlayerFromId(source)
	TriggerClientEvent('mythic_notify:client:SendAlert', xPlayer.source, { type = 'inform', text = 'You have successfully connected to the boombox.', length = 7000})
	
	ServerBoombacks[entityId] = {
		ytlink = ytLink,
		playing = false,
		volume = volume,
		connected = xPlayer.source
	}
	TriggerClientEvent('pyrp_boombox:ClientBoomBoxList', -1, ServerBoombacks)
end)

RegisterNetEvent('pyrp_boombox:disconnectBoombox')
AddEventHandler('pyrp_boombox:disconnectBoombox', function(entityId)
	local xPlayer = ESX.GetPlayerFromId(source)
	ServerBoombacks[entityId] = {
		ytlink = nil,
		playing = false,
		volume = 20,
		connected = nil
	}
	TriggerClientEvent('pyrp_boombox:ClientBoomBoxList', -1, ServerBoombacks)
end)

RegisterNetEvent('pyrp_boombox:pickupBoombox')
AddEventHandler('pyrp_boombox:pickupBoombox', function(entityId, giveItem)
	local xPlayer = ESX.GetPlayerFromId(source)
	
	if ServerBoombacks[entityId] == nil then
		TriggerClientEvent('mythic_notify:client:SendAlert', xPlayer.source, { type = 'inform', text = 'Nice try homie!', length = 7000})
		return
	end
	
	ServerBoombacks[entityId] = nil
	TriggerClientEvent('pyrp_boombox:deleteBoomboxObject', -1, entityId)
	
	if giveItem then
		xPlayer.addInventoryItem('boombox', 1)
	end
	
end)

ESX.RegisterUsableItem('boombox', function(source)
	local xPlayer = ESX.GetPlayerFromId(source)
	xPlayer.removeInventoryItem('boombox', 1)
	TriggerClientEvent('pyrp_boombox:dropBoombox', source)
end)
