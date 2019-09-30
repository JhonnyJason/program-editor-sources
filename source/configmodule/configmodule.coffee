configmodule = {name: "configmodule"}

#log Switch
log = (arg) ->
    if allModules.debugmodule.modulesToDebug["configmodule"]?  then console.log "[configmodule]: " + arg
    return


##initialization function  -> is automatically being called!  ONLY RELY ON DOM AND VARIABLES!! NO PLUGINS NO OHTER INITIALIZATIONS!!
configmodule.initialize = () ->
    log "configmodule.initialize"

#region the configuration Object
configmodule.defaultPort = 3333
configmodule.secret = "asdf" 

## path definitions
configmodule.imageServingPath = "program-images/"
configmodule.imageUpstreamPath = "../aurox-program-manager-upstream/svg" 
configmodule.upstreamRepoPath = "../aurox-program-manager-upstream" 
configmodule.gitRootPath = "../" 
configmodule.programsPath = "../aurox-program-manager-upstream/programs.coffee"
configmodule.langfilePath = "../aurox-program-manager-upstream/programsLangfile.coffee"
## github access
configmodule.user = "JhonnyJason"
configmodule.pass = "gz7vi9njt6cfhu8bu8bhbhu8"
configmodule.repo = "github.com/JhonnyJason/aurox-program-manager-upstream.git"


#endregion

export default configmodule