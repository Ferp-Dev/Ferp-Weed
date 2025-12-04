fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'ferp_weed'
author 'Ferp.Dev'
description 'Advanced Weed Growing & Selling System'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    '@qbx_core/modules/lib.lua',
    'shared/sh_config.lua',
    'shared/sh_weed.lua',
    'shared/sh_strains.lua',
    'shared/sh_plants.lua',
    'shared/sh_items.lua',
    'shared/sh_cornering.lua'
}

client_scripts {
    'client/cl_main.lua',
    'client/cl_plants.lua',
    'client/cl_strains.lua',
    'client/cl_items.lua',
    'client/cl_cornering.lua',
    'client/cl_targets.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/sv_main.lua',
    'server/sv_plants.lua',
    'server/sv_strains.lua',
    'server/sv_items.lua',
    'server/sv_cornering.lua',
    'server/sv_dealers.lua'
}

dependencies {
    'qbx_core',
    'ox_lib',
    'ox_inventory',
    'ox_target',
    'oxmysql'
}

files {
    'locales/*.json'
}

-- Escrow: Encrypt client and server files, keep shared files open
escrow_ignore {
    'shared/sh_config.lua',
    'shared/sh_weed.lua',
    'shared/sh_strains.lua',
    'shared/sh_plants.lua',
    'shared/sh_items.lua',
    'shared/sh_cornering.lua',
    'locales/*.json'
}
dependency '/assetpacks'