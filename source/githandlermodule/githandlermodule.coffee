
githandlermodule = {name: "githandlermodule"}

#region node_modules
fs = require("fs-extra")
git = require("simple-git/promise")
pathModule = require("path")
#endregion

#log Switch
log = (arg) ->
    if allModules.debugmodule.modulesToDebug["githandlermodule"]?  then console.log "[githandlermodule]: " + arg
    return

#region internal variables
rootDir = ""
repoDir = ""

upstreamremote = ""
#endregion

##initialization function  -> is automatically being called!  ONLY RELY ON DOM AND VARIABLES!! NO PLUGINS NO OHTER INITIALIZATIONS!!
githandlermodule.initialize = () ->
    log "githandlermodule.initialize"
    c = allModules.configmodule
    upstreamremote = 'https://' + c.user + ':' + c.pass + '@' + c.repo

    rootDir = pathModule.resolve(process.cwd(), c.gitRootPath)
    repoDir = pathModule.resolve(process.cwd(), c.upstreamRepoPath)

#region internal functions
tryPull = ->
    log "tryPull"
    try
        result = await gitAtRepo.pull("origin", "master")
        log JSON.stringify(result)
    catch err
        fs.removeSync(repoDir)
        doInitialClone()

doInitialClone = ->
    log "doInitialClone"
    result = await git(rootDir).clone(upstreamremote)
    log JSON.stringify(result)

#endregion

#region exposed functions
githandlermodule.pushPrograms = ->
        log "githandlermodule.pushPrograms"
        result = ""
        try 
            result = await git(repoDir).add(".")
            log result
            result = await git(repoDir).commit("automated commit")
            log result
            result = await git(repoDir).push(upstreamremote, "master")
            log result
        catch error then log error
        return

githandlermodule.startupCheck = ->
    log "githandlermodule.starupCheck"
    if fs.existsSync(repoDir) then await tryPull()
    else await doInitialClone()

#endregion exposed functions

export default githandlermodule