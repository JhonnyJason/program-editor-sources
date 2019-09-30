serverstatemodule = {name: "serverstatemodule"}

#log Switch
log = (arg) ->
    if allModules.debugmodule.modulesToDebug["serverstatemodule"]?  then console.log "[serverstatemodule]: " + arg
    return

##initialization function  -> is automatically being called!  ONLY RELY ON DOM AND VARIABLES!! NO PLUGINS NO OHTER INITIALIZATIONS!!
serverstatemodule.initialize = () ->
    log "serverstatemodule.initialize"

#region the configuration Object
serverstatemodule.activeToken = ""
serverstatemodule.app = null
serverstatemodule.programs = null
serverstatemodule.langStrings = null
#endregion

export default serverstatemodule