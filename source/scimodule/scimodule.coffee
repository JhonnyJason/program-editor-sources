
scimodule = {name: "scimodule"}

#region node_modules
require('systemd')
express = require('express')
bodyParser = require('body-parser')
fileUploadMiddleware = require("express-fileupload")
cors = require("cors")
#endregion

#log Switch
log = (arg) ->
    if allModules.debugmodule.modulesToDebug["scimodule"]?  then console.log "[scimodule]: " + arg
    return

#region internal variables
cfg = null
imageHandler = null
authenticationHandler = null
state = null
programDataHandler = null
gitHandler = null

app = null
#endregion

##initialization function  -> is automatically being called!  ONLY RELY ON DOM AND VARIABLES!! NO PLUGINS NO OHTER INITIALIZATIONS!!
scimodule.initialize = () ->
    log "scimodule.initialize"
    cfg = allModules.configmodule
    imageHandler = allModules.imagehandlermodule
    authenticationHandler = allModules.authenticationhandlermodule
    state = allModules.serverstatemodule
    programDataHandler = allModules.programdatahandlermodule
    gitHandler = allModules.githandlermodule
    
    app = express()
    app.use cors()
    app.use bodyParser.urlencoded(extended: false)
    app.use bodyParser.json()
    app.use fileUploadMiddleware()

#region internal functions
################################################################################
# Most Important Function
################################################################################
apiRoutine = (func, req, res) ->
    log func
    data = req.body
    if !data then log "Error: api received no data!"
    log "data: " + JSON.stringify(data)
    res.setHeader 'Content-Type', 'application/json'
    return data

################################################################################
# Layer 0 request Input handler
################################################################################
checkLogin = (req, res) ->
    data = apiRoutine("checkLogin", req, res)
    result = getAuthentificationResult(data)
    res.end JSON.stringify(result)
    return

loadProgramData = (req, res) ->
    data = apiRoutine("loadProgramData", req, res)
    result = getProgramDataResult()
    res.end JSON.stringify(result)
    return

saveProgramData = (req, res) ->
    data = apiRoutine("saveProgramData", req, res)
    result = getSaveProgramDataResult(data)
    res.end JSON.stringify(result)

createProgram = (req, res) ->
    data = apiRoutine("createProgram",req, res)
    result = getNewlyCreatedProgram(data)
    res.end JSON.stringify(result)
    return

deleteProgram = (req, res) ->
    data = apiRoutine("deleteProgram",req, res)
    result = getDeleteProgramResult(data)
    res.end JSON.stringify(result)
    return

fileUpload = (req, res) ->
    keys = Object.keys(req.files)
    console.log(keys)
    if (keys.length != 1)
        return res.status(400).send('Unexpected Number of files ' + keys.length)
    
    filename = keys[0]
    file = req.files[filename]
    imageHandler.store(file, filename)
    res.send(filename + " uploaded!")

discardUploads = (req, res) ->
    console.log("discardUploads")
    result = {}
    imageHandler.initialize()
    result.result = "ok"
    return res.end(JSON.stringify(result))

################################################################################
# Layer 1 request Input handler
################################################################################
getAuthentificationResult = (data) ->
    result = result: "error"
    if authenticationHandler.doLogin(data)
        result.result = "ok"
        result.authToken = state.activeToken
    return result

getProgramDataResult = ->
    result = {}
    if state.programs && state.langStrings
        result.result = "ok"
        result.programs = state.programs
        result.langStrings = state.langStrings
    else
        result.result = "error"
        result.reason = "There is data missing!\n"
        if !state.programs
            result.reason += "The programs were missing!\n"
        if !state.langStrings
            result.reason += "The langStrings were missing!\n"
    return result 

getSaveProgramDataResult = (data) ->
    result = {}
    if data.programs && data.langstrings
        state.programs = data.programs
        state.langStrings = data.langstrings
        programDataHandler.writeNewProgramsFile()
        programDataHandler.writeNewProgramsLangfile()
        imageHandler.saveImagesToRepository()
        gitHandler.pushPrograms()
        result.result = "ok"
    else
        result.result = "error"
        result.reason = "There is data missing."
    return result 

getNewlyCreatedProgram = (data) ->
    result = result: "error"
    result.reason = "Not implemented yet!"
    return result 

getDeleteProgramResult = (data) ->
    result = result: "error"
    result.reason = "Not implemented yet!"
    return result 


#################################################################
attachSCIFunctions = ->
    log "attachSCIFunctions"

    app.post '/login', checkLogin
    app.post '/loadProgramData', loadProgramData
    app.post '/saveProgramData', saveProgramData
    app.post '/discardUploads', discardUploads
    app.post '/createProgram', createProgram
    app.post '/deleteProgram', deleteProgram
    app.post '/upload', fileUpload

listenForRequests = ->
    log "listenForRequests"
    if process.env.SOCKETMODE
        app.listen "systemd"
        log "listening on systemd"
    else
        port = process.env.PORT || cfg.defaultPort
        app.listen port
        log "listening on port: " + port
#endregion


#region exposed functions
scimodule.prepareAndExpose = ->
    log "scimodule.prepareAndExpose"
    app.use express.static(cfg.imageServingPath)
    attachSCIFunctions()
    listenForRequests()
    
#endregion exposed functions

export default scimodule