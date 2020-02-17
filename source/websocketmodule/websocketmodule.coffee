
websocketmodule = {name: "websocketmodule"}

#region node_modules
#endregion

#log Switch
log = (arg) ->
    if allModules.debugmodule.modulesToDebug["websocketmodule"]?  then console.log "[websocketmodule]: " + arg
    return

#region internal variables

sockets = null

auth = null
state = null
runDataHandler = null
programDataHandler = null

reflexes = {}
#endregion

##initialization function  -> is automatically being called!  ONLY RELY ON DOM AND VARIABLES!! NO PLUGINS NO OHTER INITIALIZATIONS!!
websocketmodule.initialize = () ->
    log "websocketmodule.initialize"
    auth = allModules.authenticationhandlermodule
    state = allModules.serverstatemodule
    runDataHandler = allModules.rundatahandlermodule
    programDataHandler = allModules.programdatahandlermodule
    return


#region internal functions
################################################################################

################################################################################
# io stuff
################################################################################
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

handleProgramRequest = (programId) ->
    log "handleProgramRequest"
    log "requested Program has Id: " + programId
    try
        programData = await programDataHandler.getProgram(programId)
        io_socket.emit("program", programData)
    catch e then log e
    return 

handleRunRequest = (runId) ->
    log "handleRunRequest"
    log "requested Run has Id: " + runId
    try
        runData = await programDataHandler.getRun(runId)
        io_socket.emit("run", runData)
    catch e then log e
    return 

handleProgramDataRequest = ->
    log "handleProgramDataRequest"
    try 
        await programDataHandler.preparePrograms()
        programData = programs: state.programs
        # log(JSON.stringify(programData.programs))
        io_socket.emit("programData", programData)
    catch e then log e
    return 

handleMeasurementData = (data) ->
    #log "handleMeasurementData"
    try runDataHandler.digestMeasurementData(data)
    catch e then log e
    return 
    
handleProgramOverviewRequest = ->
    log "handleProgramOverviewRequest"
    try 
        programOverview = await programDataHandler.getProgramsOverview()  
        io_socket.emit("programsOverview", programOverview)
    catch e then log e
    return

handleRunOverviewRequest = (id) ->
    log "handleRunOverviewRequest"
    data = 
        id: id
    try 
        data.runOverview = await programDataHandler.getRunOverview(id)
        io_socket.emit("runOverview", data)
    catch e then log e
    return

handleStaticProgramDataRequest = ->
    log "handleStaticProgramDataRequest"
    try 
        staticProgramData = await programDataHandler.getStaticProgramData()  
        io_socket.emit("staticProgramData", staticProgramData)
    catch e then log e
    return 

handleLoginAttempt = (data) ->
    log "handleLoginAttempt"
    result = result: "error"
    if auth.doLogin(data)
        result = result: "ok"
        io_socket.authorized = true
    io_socket.emit("loginResult", result)

handleSaveProgramRequest = (program) ->
    log "handleSaveProgramRequest"
    try allModules.programDataHandler.saveProgram(program)
    catch e then log e
    return 

handleCloneProgramRequest = (programsDynamicId) ->
    log "handleCloneProgramRequest"
    try allModules.programDataHandler.cloneProgram(programsDynamicId)
    catch e then log e
    return

handleSetProgramActiveRequest = (programsDynamicId) ->
    log "handleSetProgramActiveRequest"
    try allModules.programDataHandler.setProgramActive(programsDynamicId)
    catch e then log e
    return 

handleRunLabelUpdateRequest = (data) ->
    log "handleRunLabelUpdateRequest"
    try allModules.programDataHandler.updateRunLabel(data.id, data.label)
    catch e then log e
    return

#endregion

#region exposed functions
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

websocketmodule.rememberSocket = (webSocket) ->
    log "websocketmodule.rememberSocket"
    socket

websocketmodule.notifyCloneCreated = (newOverviewEntry) ->
    log "websocketmodule.notifyCloneCreated"
    if io_socket
        io_socket.emit("cloneCreated", newOverviewEntry)

#endregion exposed functions

export default websocketmodule

