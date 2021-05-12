ESX = nil

local BoomboxList = {}
local playingBoombox = nil

Citizen.CreateThread(function()
  	while ESX == nil do
    	TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
    	Citizen.Wait(250)
  	end

  	while ESX.GetPlayerData().job == nil do
		Citizen.Wait(250)
	end
	
  ESX.PlayerData = ESX.GetPlayerData()
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
	ESX.PlayerData.job = job
end)

function DrawText3Ds(x,y,z, text)
    local onScreen,_x,_y=World3dToScreen2d(x,y,z)
    local px,py,pz=table.unpack(GetGameplayCamCoords())
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(1)
    AddTextComponentString(text)
    DrawText(_x,_y)
    local factor = (string.len(text)) / 370
    DrawRect(_x,_y+0.0125, 0.015+ factor, 0.03, 41, 11, 41, 68)
end

----------------- BOOMBOX

RegisterNetEvent("pyrp_boombox:ClientBoomBoxList")
AddEventHandler("pyrp_boombox:ClientBoomBoxList", function(newList)
	BoomboxList = newList
end)

RegisterNetEvent("pyrp_boombox:dropBoombox")
AddEventHandler("pyrp_boombox:dropBoombox", function()
	DropBoomBox()
end)

RegisterNetEvent("pyrp_boombox:deleteBoomboxObject")
AddEventHandler("pyrp_boombox:deleteBoomboxObject", function(entityId)
  if NetworkDoesNetworkIdExist(entityId) then
    local wutdis = NetworkGetEntityFromNetworkId(entityId)
    ESX.Game.DeleteObject(wutdis)     
  end
end)

function DropBoomBox()
	local pedCoords = GetEntityCoords(PlayerPedId())

	local object = GetClosestObjectOfType(pedCoords, 5.0, GetHashKey('prop_boombox_01'), false, false, false)

	if DoesEntityExist(object) then
		exports['mythic_notify']:DoLongHudText('error', "You are too close from other boombox.")
		return
	end

	loadAnimDict("anim@heists@money_grab@briefcase")

	TaskPlayAnim(PlayerPedId(), "anim@heists@money_grab@briefcase", "put_down_case", 8.0, -8.0, -1, 1, 0, false, false, false)
	Citizen.Wait(1000)
	ClearPedTasks(PlayerPedId())

	TriggerEvent('esx:spawnObject', 'prop_boombox_01')  
	Citizen.Wait(1500)

	local object = GetClosestObjectOfType(pedCoords, 5.0, GetHashKey('prop_boombox_01'), false, false, false)
	local entityId = NetworkGetNetworkIdFromEntity(object) 

	TriggerServerEvent('pyrp_boombox:placeBoombox', entityId)
end

function loadAnimDict( dict )
    while ( not HasAnimDictLoaded( dict ) ) do
        RequestAnimDict( dict )
        Citizen.Wait( 5 )
    end
end 

Citizen.CreateThread(function()
	while true do
		local sleep = 500
		local pedCoords = GetEntityCoords(PlayerPedId())
		
		local object = GetClosestObjectOfType(pedCoords, 1.0, GetHashKey('prop_boombox_01'), false, false, false)
		local closestObject = nil
		
		if DoesEntityExist(object) then
			local health = GetEntityHealth(object)

			if health <= 0 then
				local entityId = NetworkGetNetworkIdFromEntity(object)
				local wutdis = NetworkGetEntityFromNetworkId(entityId)
				TriggerServerEvent('pyrp_boombox:pickupBoombox', entityId, false)
				Citizen.Wait(1000)       
			end

			closestObject = object
		end
		
		if closestObject ~= nil and NetworkDoesNetworkIdExist(NetworkGetNetworkIdFromEntity(closestObject)) then
			sleep = 1
			
			local objCoords = GetEntityCoords(closestObject)
			local entityId = NetworkGetNetworkIdFromEntity(closestObject)
			FreezeEntityPosition(closestObject, true)
			
			if BoomboxList[entityId] ~= nil then
				DrawText3Ds(objCoords.x, objCoords.y, objCoords.z, "[E] to use boombox | [H] to pickup")
				
				if IsControlJustReleased(0, 38) then
					ManageBoombox(entityId)
				end
				
				if IsControlJustReleased(0, 74) then
					TriggerServerEvent('pyrp_boombox:pickupBoombox', entityId, true)
					
					TaskPlayAnim(PlayerPedId(), "anim@heists@money_grab@briefcase", "put_down_case", 8.0, -8.0, -1, 1, 0, false, false, false)
					Citizen.Wait(1000)
					ClearPedTasks(PlayerPedId())        
					Citizen.Wait(1000)
				end
				
			end
		end
		
		Citizen.Wait(sleep)
	end
end)

function ManageBoombox(entityId)
	local elements = {
        {label = 'Play Music', value = 'play_music'},
    }
	
    ESX.UI.Menu.CloseAll()

    ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'boombox', {
        title    = 'Manage Boombox',
        align    = 'top-right',
        elements = elements
    }, function(data, menu)
        if data.current.value == 'play_music' then
			PlayMusic(entityId)
        end
    end, function(data, menu)
        menu.close()
    end)
end

function PlayMusic(entityId)
	ESX.UI.Menu.CloseAll()

	ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'play_music', {
		title = "Play Music",
	}, function(data, menu)
		AdjustVolume(entityId, data.value)
		--TriggerServerEvent("pyrp_boombox:connectBoombox", entityId, data.value, 50)
	end, function(data, menu)
		menu.close()
	end)
end

function AdjustVolume(entityId, ytlink)
	ESX.UI.Menu.CloseAll()

	ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'manage_volume', {
		title = "Set Volume",
	}, function(data, menu)
		local value = tonumber(data.value)
		
		if value < 0 or value > 100 then
			exports['mythic_notify']:DoLongHudText('error', "Invalid volume amount.")
		else
			TriggerServerEvent("pyrp_boombox:connectBoombox", entityId, ytlink, value)
			menu.close()
		end
	end, function(data, menu)
		menu.close()
	end)
end

Citizen.CreateThread(function()
	while true do
		local sleep = 500
		local closestBoombox = nil
		
		for k, v in pairs(BoomboxList) do
			if NetworkDoesNetworkIdExist(k) then
				local pedCoords = GetEntityCoords(PlayerPedId())
				local curObj = NetworkGetEntityFromNetworkId(k)
				local objDistance = GetEntityCoords(curObj)
				local dist = GetDistanceBetweenCoords(pedCoords, objDistance, 1)

				if dist < 15.0 and BoomboxList[k].ytlink ~= nil then
					closestBoombox = k
				elseif (dist > 15.0 and BoomboxList[k].playing) then
					BoomboxList[k].playing = false

					SendNUIMessage({
						boombox = 'StopBoombox'
					})          
				end
			end
		end
		
		if closestBoombox ~= nil then
			if not BoomboxList[closestBoombox].playing and BoomboxList[closestBoombox].ytlink ~= nil then
				BoomboxList[closestBoombox].playing = true
				playingBoombox = closestBoombox

				print('Play! ' .. closestBoombox )
				print('Volume: ' .. BoomboxList[closestBoombox].volume )
				SendNUIMessage({
					boombox = 'PlayBoombox',
					ytlink = BoomboxList[closestBoombox].ytlink,
					volume = BoomboxList[closestBoombox].volume
				})          

			end
		end
		
		if closestBoombox ~= playingBoombox then

			if playingBoombox ~= nil then
				if (BoomboxList[playingBoombox] == nil) or (GetPlayerServerId(PlayerId()) == BoomboxList[playingBoombox].connected and BoomboxList[playingBoombox].ytlink ~= nil) then
					TriggerServerEvent('pyrp_boombox:disconnectBoombox', playingBoombox)
					exports['mythic_notify']:DoLongHudText('error', "You got disconnected from the boombox.")
				end
			end
	  
			playingBoombox = nil

			SendNUIMessage({
				boombox = 'StopBoombox'
			})    
  
		end

		Citizen.Wait(sleep)
	end
end)
