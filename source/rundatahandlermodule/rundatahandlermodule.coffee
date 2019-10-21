
rundatahandlermodule = {name: "rundatahandlermodule"}

#log Switch
log = (arg) ->
    if allModules.debugmodule.modulesToDebug["rundatahandlermodule"]?  then console.log "[rundatahandlermodule]: " + arg
    return

#region internal variables
################################################################################
databaseHandler = null

currentRun = null
################################################################################
# definitions
################################################################################
NOTRUNNING = 0
PROGRAMRUNNING = 1
PROGRAMPAUSED = 2

discrepancyToleranceMS = 1000
currentRunTimeoutMS = 4000
timeoutId = 0
#endregion

##initialization function  -> is automatically being called!  ONLY RELY ON DOM AND VARIABLES!! NO PLUGINS NO OHTER INITIALIZATIONS!!
rundatahandlermodule.initialize = () ->
    log "rundatahandlermodule.initialize"
    databaseHandler = allModules.databasehandlermodule
    return

#region internal functions
################################################################################
# Other Functions
################################################################################
runTimeout = ->
    log "runTimeout"
    timeoutId = 0
    if currentRun then saveCurrentRun()

resetTimeout = ->
    if timeoutId then clearTimeout(timeoutId)
    timeoutId = setTimeout(runTimeout, currentRunTimeoutMS)

#################################################################################
# checker functions
################################################################################
runIsFinished = (data) ->
    # log "runIsFinished?"
    ##get all potentially relevant data
    programTimeMS = data.latestState.timer * 100
    totalDurationMS = data.program.totalDurationMS
    passedTimeMS = data.timestamp - data.latestState.timestamp

    timeLeftMS = totalDurationMS - programTimeMS
    discrepancyMS = passedTimeMS - timeLeftMS
    # log "discrepancy is: " + discrepancyMS
    if discrepancyMS*discrepancyMS > discrepancyToleranceMS*discrepancyToleranceMS
        # log " - run not finished!"
        return false
    # log " - run finished!"
    return true

dataFitsToCurrentRun = (data) ->
    # log "dataFitsToCurrentRun?"
    if !currentRun 
        return false
    if data.latestState.state == NOTRUNNING
        # log "latest State was NOTRUNNING - answer is no"
        return false
    if currentRun.programId != data.program.id
        # log "currentRun.programId(" + currentRun.programId + ") != data.program.id(" + data.program.id + ") - answer is no"
        return false
    if currentRun.programId != data.latestState.id
        # log "currentRun.programId(" + currentRun.programId + ") != data.latestState.id(" + data.latestState.id + ") - answer is no"
        return false
    if currentRun.latestTimer < data.latestState.timer 
        # log "currentRun.latestTimer(" + currentRun.latestTimer + ") < data.latestState.timer(" + data.latestState.timer + ") - answer is true"
        return true
    # log "timer too much progressed - answer is no"
    return false
    ## TODO (later) make more sophisticated version

################################################################################
# functions to treat the currentRun object
################################################################################
startNewRun = (data) ->
    log "startNewRun"
    if currentRun then saveCurrentRun()
    
    currentRun = {}
    currentRun.tempBLEModule = []
    currentRun.tempBLEModule.push(data.tempBLEModule)
    currentRun.tempBatteryLeft = []
    currentRun.tempBatteryLeft.push(data.tempBatteryLeft)
    currentRun.tempPTE1 = []
    currentRun.tempPTE1.push(data.tempPTE1)
    currentRun.tempPTE1Outside = []
    currentRun.tempPTE1Outside.push(data.tempPTE1Outside)
    currentRun.tempPTE2 = []
    currentRun.tempPTE2.push(data.tempPTE2)
    currentRun.tempPTE2Outside = []
    currentRun.tempPTE2Outside.push(data.tempPTE2Outside)
    currentRun.tempPTE3 = []
    currentRun.tempPTE3.push(data.tempPTE3)
    currentRun.tempPTE3Outside = []
    currentRun.tempPTE3Outside.push(data.tempPTE3Outside)
    currentRun.tempPTE4 = []
    currentRun.tempPTE4.push(data.tempPTE4)
    currentRun.tempPTE4Outside = []
    currentRun.tempPTE4Outside.push(data.tempPTE4Outside)
    currentRun.programId = data.program.id
    currentRun.latestDataTimestamp = data.timestamp
    currentRun.programTimes = []
    
    if data.latestState.id == data.program.id
        currentRun.latestTimer = data.latestState.timer
        currentRun.latestProgramState = data.latestState.state
        currentRun.latestProgressTimestamp = data.latestState.timestamp
        # calculate the programTime
        timestampDeltaMS = data.timestamp - data.latestState.timestamp
        programTimeDelta = timestampDeltaMS / 100
        programTime = currentRun.latestTimer + programTimeDelta
        currentRun.programTimes.push(programTime)
    else
        currentRun.latestTimer = 0
        currentRun.latestProgramState = PROGRAMRUNNING
        currentRun.latestProgressTimeStamp = data.timestamp
        currentRun.programTimes.push(0)

    log "newly created current Run is: "
    log JSON.stringify(currentRun)

saveCurrentRun = ->
    log "saveCurrentRun"
    if !currentRun then return
    inserts = createNewRunInserts()
    currentRun = null
    
    try databaseHandler.saveNewRun(inserts)
    catch e then log e
    return 

addDataToCurrentRun = (data) ->
    # log "addDataToCurrentRun"
    currentRun.tempBLEModule.push(data.tempBLEModule)
    currentRun.tempBatteryLeft.push(data.tempBatteryLeft)
    currentRun.tempPTE1.push(data.tempPTE1)
    currentRun.tempPTE1Outside.push(data.tempPTE1Outside)
    currentRun.tempPTE2.push(data.tempPTE2)
    currentRun.tempPTE2Outside.push(data.tempPTE2Outside)
    currentRun.tempPTE3.push(data.tempPTE3)
    currentRun.tempPTE3Outside.push(data.tempPTE3Outside)
    currentRun.tempPTE4.push(data.tempPTE4)
    currentRun.tempPTE4Outside.push(data.tempPTE4Outside)
    currentRun.latestDataTimestamp = data.timestamp

    currentRun.latestTimer = data.latestState.timer
    currentRun.latestProgramState = data.latestState.state
    currentRun.latestProgressTimeStamp = data.latestState.timestamp

    # log " - latest State Program Time: " + currentRun.latestTimer
    timestampDeltaMS = data.timestamp - data.latestState.timestamp
    programTimeDelta = Math.round(0.01 * timestampDeltaMS)
    # log " - program Time Difference: " + programTimeDelta
    programTime = currentRun.latestTimer + programTimeDelta
    # log " - noticed and save programTime: " + programTime
    currentRun.programTimes.push(programTime)

################################################################################
# measurement Data digesting functions
################################################################################
useMeasurementData = (data) ->
    resetTimeout()
    if  currentRun and dataFitsToCurrentRun(data)
        addDataToCurrentRun(data)
    else 
        startNewRun(data)

    if runIsFinished(data) then saveCurrentRun()
    return 

################################################################################
# create fake inserts for testing
################################################################################
createNewRunInserts = ->    
    bufferBLEModule = Buffer.from(Uint8Array.from(currentRun.tempBLEModule))
    bufferBatteryLeft = Buffer.from(Uint8Array.from(currentRun.tempBatteryLeft))
    bufferPTE1 = Buffer.from(Uint8Array.from(currentRun.tempPTE1))
    bufferPTE1Outside = Buffer.from(Uint8Array.from(currentRun.tempPTE1Outside))
    bufferPTE2 = Buffer.from(Uint8Array.from(currentRun.tempPTE2))
    bufferPTE2Outside = Buffer.from(Uint8Array.from(currentRun.tempPTE2Outside))
    bufferPTE3 = Buffer.from(Uint8Array.from(currentRun.tempPTE3))
    bufferPTE3Outside = Buffer.from(Uint8Array.from(currentRun.tempPTE3Outside))
    bufferPTE4 = Buffer.from(Uint8Array.from(currentRun.tempPTE4))
    bufferPTE4Outside = Buffer.from(Uint8Array.from(currentRun.tempPTE4Outside))
    bufferProgramTimes = Buffer.from(Uint16Array.from(currentRun.programTimes).buffer)
    
    return [
        currentRun.programId    
        currentRun.latestDataTimestamp
        null
        bufferBLEModule 
        bufferBatteryLeft 
        bufferPTE1 
        bufferPTE1Outside 
        bufferPTE2 
        bufferPTE2Outside 
        bufferPTE3 
        bufferPTE3Outside 
        bufferPTE4
        bufferPTE4Outside
        bufferProgramTimes
    ]


#endregion

#region exposed functions
rundatahandlermodule.digestMeasurementData = (data) ->
    log "digestMeasurementData"
    #log JSON.stringify(data)
    #log " - - - "
    useMeasurementData(data)
    return

rundatahandlermodule.noteRunStart = ->
    # if !currentProgram
    # saveCurrentRun()
    ## TODO implement fancy version
    return

rundatahandlermodule.noteRunQuit = ->
    saveCurrentRun()
    ## TODO implement fancy version
    return

#endregion exposed functions

export default rundatahandlermodule