debugmodule = {name: "debugmodule"}

##initialization function  -> is automatically being called!  ONLY RELY ON DOM AND VARIABLES!! NO PLUGINS NO OHTER INITIALIZATIONS!!
debugmodule.initialize = () ->
    #console.log "debugmodule.initialize - nothing to do"
    return

debugmodule.modulesToDebug = 
    unbreaker: true
    authenticationhandlermodule: true
    configmodule: true
    githandlermodule: true
    imagehandlermodule: true
    programdatahandlermodule: true
    scimodule: true
    serverstatemodule: true
    # startupmodule: true
#region exposed variables

export default debugmodule