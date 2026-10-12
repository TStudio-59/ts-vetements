fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'cfx_ts_vetements'
description 'Vêtements en objets pour ox_inventory et illenium-appearance'
version '1.6.0'

shared_scripts {
    '@ox_lib/init.lua',
    'shared/config.lua',
}

client_script 'cl/client.lua'
server_script 'sv/server.lua'

dependencies {
    'ox_lib',
    'ox_inventory',
    'illenium-appearance',
}

escrow_ignore {
    'shared/*.lua'
}
