
imagehandlermodule = {name: "imagehandlermodule"}

#region node_modules
fs = require("fs-extra")
pathModule = require("path")
#endregion

#log Switch
log = (arg) ->
    if allModules.debugmodule.modulesToDebug["imagehandlermodule"]?  then console.log "[imagehandlermodule]: " + arg
    return

#region internal variables
cfg = null
programImagesUpstream = ""
programImagesWebsite = ""
#endregion

##initialization function  -> is automatically being called!  ONLY RELY ON DOM AND VARIABLES!! NO PLUGINS NO OHTER INITIALIZATIONS!!
imagehandlermodule.initialize = () ->
    log "imagehandlermodule.initialize"
    cfg = allModules.configmodule
    programImagesUpstream = cfg.imageUpstreamPath
    programImagesWebsite = cfg.imageServingPath
    if !fs.existsSync(programImagesWebsite) then fs.mkdirsSync(programImagesWebsite)

#region internal functions
copyCurrentImagesToWebsite = ->
    log "copyCurrentImagesToWebsite"
    sourcePath = pathModule.resolve(process.cwd(), programImagesUpstream)
    destPath = pathModule.resolve(process.cwd(), programImagesWebsite)
    fs.copySync(sourcePath, destPath)
    return
#endregion

#region exposed functions
imagehandlermodule.prepareImages = ->
    log "imagehandlermodule.prepareImages"
    copyCurrentImagesToWebsite()

imagehandlermodule.saveImagesToRepository = ->
    log "saveImagesToRepository"
    sourcePath = pathModule.resolve(process.cwd(), programImagesWebsite)
    destPath = pathModule.resolve(process.cwd(), programImagesUpstream)
    fs.copySync(sourcePath, destPath)
    return

imagehandlermodule.store = (file, filename) ->
    log "imagehandlermodule.store"
    if !file or !filename then return  
    destinationPath = pathModule.resolve(process.cwd(), programImagesWebsite, filename)
    file.mv(destinationPath, (error) -> console.log("Error! " + error))
    
#endregion exposed functions

export default imagehandlermodule