
startupmodule = {name: "startupmodule"}

#log Switch
log = (arg) ->
    if allModules.debugmodule.modulesToDebug["startupmodule"]?  then console.log "[startupmodule]: " + arg
    return

#region internal variables
sci = null
pdh = null
#endregion

##initialization function  -> is automatically being called!  ONLY RELY ON DOM AND VARIABLES!! NO PLUGINS NO OHTER INITIALIZATIONS!!
startupmodule.initialize = () ->
    log "startupmodule.initialize"
    sci = allModules.scimodule
    pdh = allModules.programdatahandlermodule
    return

#region exposed functions
startupmodule.serviceStartup = ->
    log "startupmodule.serviceStartup"
    try
        await pdh.prepareProgramData()
        await sci.prepareAndExpose()
    catch err then log err
    log "ran through serviceStartup!"
#endregion exposed functions

export default startupmodule