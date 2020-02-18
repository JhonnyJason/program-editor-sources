
websocketmodule = {name: "websocketmodule"}
############################################################
#region logPrintFunctions
log = (arg) ->
    if allModules.debugmodule.modulesToDebug["websocketmodule"]?  then console.log "[websocketmodule]: " + arg
    return
ostr = (o) -> JSON.stringify(o, null, 4)
olog = (o) -> log "\n" + ostr(o)
#endregion

############################################################
#region internalVariables

runDataHandler = null
programDataHandler = null

############################################################
auth = null
state = null

############################################################
socket = null
reflexes = {}

#endregion

############################################################
websocketmodule.initialize = () ->
    log "websocketmodule.initialize"
    auth = allModules.authenticationhandlermodule
    state = allModules.serverstatemodule
    runDataHandler = allModules.rundatahandlermodule
    programDataHandler = allModules.programdatahandlermodule
    return

############################################################
sendSignal = (webSocket, name, data) ->
    log "sendSignal"
    message = JSON.stringify({name, data})
    webSocket.send(message)
    return

broadcastSignal = (name, data) ->
    log "broadcastSignal"
    message = JSON.stringify({name, data})

    # !!beware this is [object Set] ...
    clients = socket.getWss().clients
    
    # olog clients
    clients.forEach (client) ->
        log "forEach item"
        client.send(message)
    return

############################################################
#region reflexes
handleRunStart = ->
    log "handleRunStart"
    try runDataHandler.noteRunStart()
    catch e then log e
    return

handleRunQuit = ->
    log "handleRunQuit"
    try runDataHandler.noteRunQuit()
    catch e then log e
    return

handleProgramRequest = (webSocket, programId) ->
    log "handleProgramRequest"
    log "requested Program has Id: " + programId
    try
        programData = await programDataHandler.getProgram(programId)
        broadcastSignal("program", programData)
    catch e then log e
    return 

handleRunRequest = (webSockt, runId) ->
    log "handleRunRequest"
    log "requested Run has Id: " + runId
    try
        runData = await programDataHandler.getRun(runId)
        broadcastSignal("run", runData)
    catch e then log e
    return 

handleProgramDataRequest = (webSocket) ->
    log "handleProgramDataRequest"
    try 
        await programDataHandler.preparePrograms()
        programData = programs: state.programs
        # log(JSON.stringify(programData.programs))
        sendSignal(webSocket, "programData", programData)
    catch e then log e
    return 

handleMeasurementData = (webSocket, data) ->
    #log "handleMeasurementData"
    try runDataHandler.digestMeasurementData(data)
    catch e then log e
    return 
    
handleProgramOverviewRequest = (webSocket) ->
    log "handleProgramOverviewRequest"
    try 
        programOverview = await programDataHandler.getProgramsOverview()  
        sendSignal(webSocket, "programsOverview", programOverview)
    catch e then log e
    return

handleRunOverviewRequest = (webSocket, id) ->
    log "handleRunOverviewRequest"
    data = 
        id: id
    try 
        data.runOverview = await programDataHandler.getRunOverview(id)
        sendSignal(webSocket, "runOverview", data)
    catch e then log e
    return

handleStaticProgramDataRequest = (webSocket) ->
    log "handleStaticProgramDataRequest"
    try 
        staticProgramData = await programDataHandler.getStaticProgramData()  
        sendSignal(webSocket, "staticProgramData", staticProgramData)
    catch e then log e
    return 

handleLoginAttempt = (webSocket, data) ->
    log "handleLoginAttempt"
    result = result: "error"
    if auth.isAuthorized(data)
        result = result: "ok"
        webSocket.authorized = true
    sendSignal(webSocket, "loginResult", result)
    return

handleSaveProgramRequest = (webSocket, program) ->
    log "handleSaveProgramRequest"
    try programDataHandler.saveProgram(program)
    catch e then log e
    return 

handleCloneProgramRequest = (webSocket, programsDynamicId) ->
    log "handleCloneProgramRequest"
    try programDataHandler.cloneProgram(programsDynamicId)
    catch e then log e
    return

handleSetProgramActiveRequest = (webSocket, programsDynamicId) ->
    log "handleSetProgramActiveRequest"
    try programDataHandler.setProgramActive(programsDynamicId)
    catch e then log e
    return 

handleRunLabelUpdateRequest = (webSocket, data) ->
    log "handleRunLabelUpdateRequest"
    try programDataHandler.updateRunLabel(data.id, data.label)
    catch e then log e
    return

#endregion

############################################################
#region exposedFunctions
websocketmodule.attachReflexes = (reflexes) ->
    log "attachReflexes"
    # App communicates run stuff
    reflexes["runStart"] = handleRunStart
    reflexes["runQuit"] = handleRunQuit
    reflexes["measurementData"] = handleMeasurementData
    # App requesting all current Program Data
    reflexes["programDataPlease"] = handleProgramDataRequest
    # Webinterface asking for specific program data
    reflexes["updateRunLabelPlease"] = handleRunLabelUpdateRequest
    reflexes["saveProgramPlease"] = handleSaveProgramRequest
    reflexes["cloneProgramPlease"] = handleCloneProgramRequest
    reflexes["setProgramActivePlease"] = handleSetProgramActiveRequest
    reflexes["programOverviewPlease"] = handleProgramOverviewRequest
    reflexes["runOverviewPlease"] = handleRunOverviewRequest
    reflexes["staticProgramDataPlease"] = handleStaticProgramDataRequest
    reflexes["programPlease"] = handleProgramRequest
    reflexes["runPlease"] = handleRunRequest
    # webinterface 
    reflexes["loginAttempt"] = handleLoginAttempt
    return

websocketmodule.rememberSocketHandle = (webSocketHandle) ->
    log "websocketmodule.rememberSocket"
    socket = webSocketHandle
    return

websocketmodule.notifyCloneCreated = (newOverviewEntry) ->
    log "websocketmodule.notifyCloneCreated"
    if socket
        broadcastSignal("cloneCreated", newOverviewEntry)

#endregion exposed functions

export default websocketmodule
