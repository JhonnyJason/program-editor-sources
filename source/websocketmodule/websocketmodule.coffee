
websocketmodule = {name: "websocketmodule"}

#region node_modules
#endregion

#log Switch
log = (arg) ->
    if allModules.debugmodule.modulesToDebug["websocketmodule"]?  then console.log "[websocketmodule]: " + arg
    return

#region internal variables
io_socket = null

auth = null
state = null
runDataHandler = null
programDataHandler = null
#endregion

##initialization function  -> is automatically being called!  ONLY RELY ON DOM AND VARIABLES!! NO PLUGINS NO OHTER INITIALIZATIONS!!
websocketmodule.initialize = () ->
    log "websocketmodule.initialize"
    auth = allModules.authenticationhandlermodule
    state = allModules.serverstatemodule
    runDataHandler = allModules.rundatahandlermodule
    programDataHandler = allModules.programdatahandlermodule

    # ## ToDo reimplement using express-ws in scimodule
    # io_socket = null
    # io.on("connection", handleConnection)
    # io.on("error", (reason) -> log("Error!\n" + reason))
    # io.on("disconnect", (reason) -> log("disconnected!\n" + reason))
    return


#region internal functions
################################################################################
attachEventsToSocket = (socket) ->
    log "attachEventsToSocket"
    # App communicates run stuff
    socket.on("runStart", handleRunStart)
    socket.on("runQuit", handleRunQuit)
    socket.on("measurementData", handleMeasurementData)
    # App requesting all current Program Data
    socket.on("programDataPlease", handleProgramDataRequest)
    # Webinterface asking for specific program data
    socket.on("updateRunLabelPlease", handleRunLabelUpdateRequest)
    socket.on("saveProgramPlease", handleSaveProgramRequest)
    socket.on("cloneProgramPlease", handleCloneProgramRequest)
    socket.on("setProgramActivePlease", handleSetProgramActiveRequest)
    socket.on("programOverviewPlease", handleProgramOverviewRequest)
    socket.on("runOverviewPlease", handleRunOverviewRequest)
    socket.on("staticProgramDataPlease", handleStaticProgramDataRequest)
    socket.on("programPlease", handleProgramRequest)
    socket.on("runPlease", handleRunRequest)
    # webinterface 
    socket.on("loginAttempt", handleLoginAttempt)

################################################################################
# io stuff
################################################################################
handleConnection = (socket) ->
    log "handleConnection"
    attachEventsToSocket(socket)
    return

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
websocketmodule.prepareWebsocket = (expressApp) ->
    log "websocketmodule.prepareWebsocket"

websocketmodule.notifyCloneCreated = (newOverviewEntry) ->
    log "websocketmodule.notifyCloneCreated"
    if io_socket
        io_socket.emit("cloneCreated", newOverviewEntry)

#endregion exposed functions

export default websocketmodule

