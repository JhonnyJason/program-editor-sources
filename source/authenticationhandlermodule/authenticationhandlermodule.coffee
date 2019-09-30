
authenticationhandlermodule = {name: "authenticationhandlermodule"}

#log Switch
log = (arg) ->
    if allModules.debugmodule.modulesToDebug["authenticationhandlermodule"]?  then console.log "[authenticationhandlermodule]: " + arg
    return

#region internal variables
state = null

cfg = null
#endregion

##initialization function  -> is automatically being called!  ONLY RELY ON DOM AND VARIABLES!! NO PLUGINS NO OHTER INITIALIZATIONS!!
authenticationhandlermodule.initialize = () ->
    log "authenticationhandlermodule.initialize"
    state = allModules.authenticationhandlermodule
    cfg = allModules.configmodule
    state.activeToken = getRandomChars(40)

getRandomChars = (length) ->
    result = ''
    options = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789'
    i = 0
    while i < length
        result += options.charAt(Math.floor(Math.random() * options.length))
        i++
    return result

#region exposed functions
authenticationhandlermodule.doLogin = (data) ->
    log "authenticationhandlermodule.doLogin"
    if data.secret and data.secret == cfg.secret
        state.activeToken = getRandomChars(20)
        return true
    return false      

#endregion exposed functions

export default authenticationhandlermodule