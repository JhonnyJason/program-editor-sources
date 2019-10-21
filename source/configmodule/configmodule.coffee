configmodule = {name: "configmodule"}

#log Switch
log = (arg) ->
    if allModules.debugmodule.modulesToDebug["configmodule"]?  then console.log "[configmodule]: " + arg
    return


##initialization function  -> is automatically being called!  ONLY RELY ON DOM AND VARIABLES!! NO PLUGINS NO OHTER INITIALIZATIONS!!
configmodule.initialize = () ->
    log "configmodule.initialize"
    return

#region the configuration Object
configmodule.defaultPort = 3333
configmodule.secret = "asdf" 

# database config
# configmodule.dbHost = "178.162.221.176"
configmodule.dbHost = "ulea"
configmodule.dbName = "programs_test_history"
configmodule.dbUser = "aurox"
configmodule.dbPassword = "dzy3TqBENvFMC85"
# configmodule.dbUser = "lenny"
# configmodule.dbPassword = "4564564rfvujm4564564rfvujm"
configmodule.dbCaFilePath = 'ssl/server-ca.pem'
configmodule.dbKeyFilePath = 'ssl/client-key.pem'
configmodule.dbCertFilePath = 'ssl/client-cert.pem'

#endregion

export default configmodule