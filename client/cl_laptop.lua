-- Handle NUI Callbacks from the Laptop App (Iframe)
RegisterNUICallback('ferp-weed:getStrainData', function(_, cb)
    local data = lib.callback.await('ferp-weed:getStrainData', false)
    cb(data)
end)

RegisterNUICallback('ferp-weed:unlockPerk', function(data, cb)
    -- Trigger Server Event specific to unlockPerk
    TriggerServerEvent('Ferp-Weed:server:unlockPerk', data.strainId, data.perkId, data.type)
    cb({ success = true })
end)

RegisterNUICallback('ferp-weed:renameStrain', function(data, cb)
    -- Trigger Server Event specific to renameStrain
    TriggerServerEvent('Ferp-Weed:server:renameStrain', data.strainId, data.newName)
    -- Return immediately, notification will handle success/failure
    cb({ success = true })
end)



-- Laptop Notification Event
RegisterNetEvent('Ferp-Weed:client:laptopNotify', function(title, message, type)
    if GetResourceState('fd_laptop') == 'started' then
        -- SendAppMessage was invalid.
        -- sendNotification expects a single table: { summary = "Title", detail = "Message" }
        exports.fd_laptop:sendNotification({
            summary = title,
            detail = message
        })
    else
        Weed.Notify(nil, message, type)
    end
end)
