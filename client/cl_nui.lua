-- Open UI Event
RegisterNetEvent('ferp-weed:openUI', function()
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'open'
    })
end)

-- Handle NUI Callbacks
RegisterNUICallback('ferp-weed:closeUI', function(_, cb)
    SetNuiFocus(false, false)
    SendNUIMessage({
        action = 'close'
    })
    cb('ok')
end)

RegisterNUICallback('ferp-weed:checkVpn', function(_, cb)
    -- print('[Ferp-Weed] Client requesting VPN check...')
    local hasVpn = lib.callback.await('Ferp-Weed:server:hasVpnItem', false)
    -- print('[Ferp-Weed] Server returned VPN status: '..tostring(hasVpn))
    cb(hasVpn)
end)


