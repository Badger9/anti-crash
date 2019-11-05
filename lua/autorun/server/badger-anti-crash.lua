local config = {}

--
-- Configure stuff here
--

-- Longest a message can take to run. If a player spams laggy net messages, it'll stop them after x seconds
-- Default = 1
config.timeOut = 1

-- If you want net messages to stop on error. This can cause extra lag because it pcalls.
-- Default = false
config.stopErrors = false

--
-- Code starts here, don't touch anything unless you know what you're doing
-- 

function net.Incoming( len, client )
    local i = net.ReadHeader()
    local strName = util.NetworkIDToString( i )

    if ( !strName ) then return end

    local lwrStrName = strName:lower()

    if client.disallowedNetMessages[ lwrStrName ] then return end

    local func = net.Receivers[ lwrStrName ]
    if ( !func ) then return end

    len = len - 16

    local startTime = SysTime()
    local ran, err
    if config.stopErrors then
        ran, err = pcall( func, len, client )
    else
        func( len, client )
    end
    local endTime = SysTime()

    if config.stopErrors and !ran then
        client.disallowedNetMessages[ lwrStrName ] = true
        MsgN( client:Nick() .. " had an error in \"" .. strName .. "\", disallowing them from sending any more net messages to that network string." )
        MsgN( err )
    end

    if ( client.lagTime[ lwrStrName ] or 0 ) > config.timeOut then
        client.disallowedNetMessages[ lwrStrName ] = true
        MsgN( client:Nick() .. " caused lag in \"" .. strName .. "\", disallowing them from sending any more net messages to that network string (" .. client.lagTime[ lwrStrName ] .. ")."  )
    end

    -- Set it after so they have to send more than one netmessage, some just cause massive amounts of lag for no reason :)
    client.lagTime[ lwrStrName ] = ( client.lagTime[ lwrStrName ] or 0 ) + endTime - startTime
end

hook.Add( "PlayerInitialSpawn", "badgerAntiCrash", function( ply )
    ply.disallowedNetMessages = {}
    ply.lagTime = {}
end )

timer.Create( "badgerAntiCrash", config.timeOut, 0, function()
    for _, ply in ipairs( player.GetAll() ) do
        ply.lagTime = {}
    end
end )