programdatahandlermodule = {name: "programdatahandlermodule"}

#region node_modules
fs = require('fs')
#endregion

#log Switch
log = (arg) ->
    if allModules.debugmodule.modulesToDebug["programdatahandlermodule"]?  then console.log "[programdatahandlermodule]: " + arg
    return

#region internal variables
ws = null
utl  = null  
state =  null
databaseHandler = null

idToStaticInfo = []
idToDynamicInfo = []
#endregion

##initialization function  -> is automatically being called!  ONLY RELY ON DOM AND VARIABLES!! NO PLUGINS NO OHTER INITIALIZATIONS!!
programdatahandlermodule.initialize = () ->
    log "programdatahandlermodule.initialize"
    ws = allModules.websockethandlermodule
    ult = allModules.utilmodule
    state = allModules.serverstatemodule
    databaseHandler = allModules.databasehandlermodule
    return

#region internal functions
##############################################################################
# Program Data digesting functions
##############################################################################
sanitizeProgramData = (programData) ->
    minArrayLength = 2147483647
    if programData.buffertemp1.length < minArrayLength
        minArrayLength = programData.buffertemp1.length
    if programData.buffertemp2.length < minArrayLength
        minArrayLength = programData.buffertemp2.length
    if programData.buffertemp3.length < minArrayLength
        minArrayLength = programData.buffertemp3.length
    if programData.buffertemp4.length < minArrayLength
        minArrayLength = programData.buffertemp4.length
    if programData.buffervib1.length < minArrayLength
        minArrayLength = programData.buffervib1.length
    if programData.buffervib2.length < minArrayLength
        minArrayLength = programData.buffervib2.length
    if programData.bufferagression.length < minArrayLength
        minArrayLength = programData.bufferagression.length
    if programData.bufferduration.length < minArrayLength
        minArrayLength = programData.bufferduration.length
    
    programData.buffertemp1.length = minArrayLength
    programData.buffertemp2.length = minArrayLength
    programData.buffertemp3.length = minArrayLength 
    programData.buffertemp4.length = minArrayLength
    programData.buffervib1.length = minArrayLength
    programData.buffervib2.length = minArrayLength
    programData.bufferagression.length = minArrayLength
    programData.bufferduration.length = minArrayLength
    programData.dataPoints = minArrayLength

    while minArrayLength--
        if (programData.buffertemp1[minArrayLength] == 255) then programData.buffertemp1[minArrayLength] = 128
        if (programData.buffertemp2[minArrayLength] == 255) then programData.buffertemp2[minArrayLength] = 128
        if (programData.buffertemp3[minArrayLength] == 255) then programData.buffertemp3[minArrayLength] = 128
        if (programData.buffertemp4[minArrayLength] == 255) then programData.buffertemp4[minArrayLength] = 128
    
    return programData

getOverviewEntry = (programsDynamicId) ->
    console.log "createOverviewEntry"
    overview = await programdatahandlermodule.getProgramsOverview()
    for entry in overview
        if entry.programs_dynamic_id == programsDynamicId
            return entry

createProgramObject = (dynamicDatabaseData) ->
    staticData = idToStaticInfo[dynamicDatabaseData.programs_static_id]
    dynamicData =
        id: dynamicDatabaseData.programs_dynamic_id
        durationMS: dynamicDatabaseData.duration_ms
        intensity: dynamicDatabaseData.intensity
        temperature: dynamicDatabaseData.temperature
        vibration: dynamicDatabaseData.vibration
        dataPoints: dynamicDatabaseData.datapoints
        buffertemp1: Array.from(new Uint8Array(dynamicDatabaseData.buffertemp1))
        buffertemp2: Array.from(new Uint8Array(dynamicDatabaseData.buffertemp2))
        buffertemp3: Array.from(new Uint8Array(dynamicDatabaseData.buffertemp3))
        buffertemp4: Array.from(new Uint8Array(dynamicDatabaseData.buffertemp4))
        buffervib1: Array.from(new Uint8Array(dynamicDatabaseData.buffervib1))
        buffervib2: Array.from(new Uint8Array(dynamicDatabaseData.buffervib2))
        bufferagression: Array.from(new Uint8Array(dynamicDatabaseData.bufferagression))
        bufferduration: Array.from(new Uint16Array(dynamicDatabaseData.bufferduration.buffer, dynamicDatabaseData.bufferduration.byteOffset, dynamicDatabaseData.bufferduration.length / Uint16Array.BYTES_PER_ELEMENT))
        
    programData = Object.assign(dynamicData, staticData)
    programData = sanitizeProgramData(programData)
    return programData

createRunObject = (runDatabaseData) ->
    runObject = 
        id: runDatabaseData.programs_runs_id
        programId: runDatabaseData.programs_dynamic_id
        timestamp: runDatabaseData.timestamp
        runLabel:  runDatabaseData.run_label
        tempBLEModule: Array.from(new Uint8Array(runDatabaseData.temp_ble_module))
        tempBatteryLeft: Array.from(new Uint8Array(runDatabaseData.temp_battery_left))
        tempPTE1: Array.from(new Uint8Array(runDatabaseData.temp_pte1))
        tempPTE1Outside: Array.from(new Uint8Array(runDatabaseData.temp_pte1_outside))
        tempPTE2: Array.from(new Uint8Array(runDatabaseData.temp_pte2))
        tempPTE2Outside: Array.from(new Uint8Array(runDatabaseData.temp_pte2_outside))
        tempPTE3: Array.from(new Uint8Array(runDatabaseData.temp_pte3))
        tempPTE3Outside: Array.from(new Uint8Array(runDatabaseData.temp_pte3_outside))
        tempPTE4: Array.from(new Uint8Array(runDatabaseData.temp_pte4))
        tempPTE4Outside: Array.from(new Uint8Array(runDatabaseData.temp_pte4_outside))
        programsProgress: Array.from(new Uint16Array(runDatabaseData.programs_progress.buffer, runDatabaseData.programs_progress.byteOffset, runDatabaseData.programs_progress.length / Uint16Array.BYTES_PER_ELEMENT))
    log " - - - run Database Data:"
    log JSON.stringify(runDatabaseData)
    log " - - - run Object to return:"
    log JSON.stringify(runObject)
    return runObject

digestProgramData = (programData) ->
    programObject = createProgramObject(programData)
    if programObject.type == "relax"
        state.programs.relaxprograms.push(programObject)
    else
        state.programs.performprograms.push(programObject)

digestStaticProgramInfo = (staticProgramInfo) ->
    result = []
    for info in staticProgramInfo
        result[info.programs_static_id] = 
            static_id: info.programs_static_id
            type: info.type
            namekey: info.namekey
            iconfilename: info.iconfilename
            giffilename: info.giffilename
            descriptionkey: info.descriptionkey
    return result

retrieveStaticInfo = ->
    staticProgramInfo = await databaseHandler.getStaticProgramInformation()
    if staticProgramInfo
        idToStaticInfo = digestStaticProgramInfo(staticProgramInfo.results)

retrieveCurrentActivePrograms = ->
    log "retrieveCurrentActivePrograms"
    state.programs =
        relaxprograms: []
        performprograms: []
    try
        result = await databaseHandler.getCurrentActivePrograms()
        activePrograms = result.results

        promises = []
        for program in activePrograms
           promises.push(databaseHandler.getDynamicProgramData(program.programs_dynamic_id)) 

        results = []
        results = await Promise.all(promises)
        for programDataResult in results
            digestProgramData(programDataResult.results[0])
        log("initially digested ProgramInfo!")
    catch e then console.log(e)

getDynamicProgramInfoSavely = (id) ->
    log "getDynamicProgramInfoSavely"
    programsDynamicInfo = idToDynamicInfo[id]
    
    if !programsDynamicInfo?
        dbResult = await databaseHandler.getDynamicProgramData(id)
        if dbResult.results? 
            programsDynamicInfo = dbResult.results[0]
            idToDynamicInfo[id] = programsDynamicInfo
    return programsDynamicInfo

extractMergedDynamicInfoObject = (program) ->
    log "extractNewDynamicInfoObject"
    id = program.id
    programsDynamicInfo = await getDynamicProgramInfoSavely(id)

    # console.log("- - - - - program: ")
    # console.log(JSON.stringify(program))
    # console.log("- - - - - old dynamic info: ")
    # console.log(JSON.stringify(programsDynamicInfo))

    if program.new_version_label?
        programsDynamicInfo.version_label = program.new_version_label

    programsDynamicInfo.duration_ms = program.durationMS
    programsDynamicInfo.intensity = program.intensity
    programsDynamicInfo.temperature = program.temperature
    programsDynamicInfo.vibration = program.vibration
    programsDynamicInfo.datapoints = program.dataPoints
    programsDynamicInfo.buffertemp1 = Buffer.from(Uint8Array.from(program.buffertemp1))
    programsDynamicInfo.buffertemp2 = Buffer.from(Uint8Array.from(program.buffertemp2))
    programsDynamicInfo.buffertemp3 = Buffer.from(Uint8Array.from(program.buffertemp3))
    programsDynamicInfo.buffertemp4 = Buffer.from(Uint8Array.from(program.buffertemp4))
    programsDynamicInfo.buffervib1 = Buffer.from(Uint8Array.from(program.buffervib1))
    programsDynamicInfo.buffervib2 = Buffer.from(Uint8Array.from(program.buffervib2))
    programsDynamicInfo.bufferagression = Buffer.from(Uint8Array.from(program.bufferagression))
    programsDynamicInfo.bufferduration = Buffer.from(Uint16Array.from(program.bufferduration).buffer)
    
    # console.log("- - - - - new dynamic info: ")
    # console.log(JSON.stringify(programsDynamicInfo))
    # console.log("- - - - - <:) ")
    return programsDynamicInfo
    
##############################################################################
# create fake inserts for testing
##############################################################################
createProgramsDynamicUpdateInserts = (programsDynamicInfo) ->
    return [
        programsDynamicInfo.version_label
        programsDynamicInfo.duration_ms
        programsDynamicInfo.intensity
        programsDynamicInfo.temperature
        programsDynamicInfo.vibration
        programsDynamicInfo.buffertemp1
        programsDynamicInfo.buffertemp2
        programsDynamicInfo.buffertemp3
        programsDynamicInfo.buffertemp4
        programsDynamicInfo.buffervib1
        programsDynamicInfo.buffervib2
        programsDynamicInfo.bufferagression
        programsDynamicInfo.bufferduration
        programsDynamicInfo.datapoints
        programsDynamicInfo.is_active
        programsDynamicInfo.programs_dynamic_id
    ]

createNewProgramsDynamicInserts = (programsDynamicInfo) ->
    log(JSON.stringify(programsDynamicInfo))
    return [
            programsDynamicInfo.programs_static_id # programs_static_id
            programsDynamicInfo.version_label #version_label
            programsDynamicInfo.duration_ms # duration_ms
            programsDynamicInfo.intensity # intensity
            programsDynamicInfo.temperature # temperature
            programsDynamicInfo.vibration # vibration
            programsDynamicInfo.buffertemp1 # buffertemp1
            programsDynamicInfo.buffertemp2 # buffertemp2
            programsDynamicInfo.buffertemp3 # buffertemp3
            programsDynamicInfo.buffertemp4 # buffertemp4
            programsDynamicInfo.buffervib1 # buffervib1
            programsDynamicInfo.buffervib2 # buffervib2
            programsDynamicInfo.bufferagression # bufferagression
            programsDynamicInfo.bufferduration # bufferduration
            programsDynamicInfo.datapoints # datapoints
    ]

#endregion

#region exposed functions
programdatahandlermodule.prepareProgramData = ->
    log "programdatahandlermodule.prepareProgramData"
    await retrieveStaticInfo()
    await retrieveCurrentActivePrograms()

programdatahandlermodule.preparePrograms = ->
    await retrieveCurrentActivePrograms()
    return

programdatahandlermodule.saveNewVersionOfPrograms = (newPrograms) ->
    changedPrograms = []
    idToOldProgram = utl.mapIdToProgram(allModules.state.programs) 
    idToNewProgram = utl.mapIdToProgram(newPrograms)
    for id,program of idToOldProgram
        newProgram = idToNewProgram[id]
        if (JSON.stringify(newProgram) == JSON.stringify(program))
            delete idToNewProgram[id]
    
    promises = []
    for program in idToNewProgram
        if program?
            promises.push(databaseHandler.saveNewProgram(createInsertForProgram(program)))
    
    results = []
    try
        results = await Promise.all(promises)
    catch e then log(e)
    
    for result in results
        log(JSON.stringify(result))

programdatahandlermodule.getProgramsOverview = ->
    dbResult = await databaseHandler.getProgramsOverview()
    if dbResult.results? then return dbResult.results
    throw "Error, there have been no results..."

programdatahandlermodule.getRunOverview = (id) ->
    dbResult = await databaseHandler.getRunHistoryOverview(id)
    if dbResult.results? then return dbResult.results
    throw "Error, there have been no results..."

programdatahandlermodule.getStaticProgramData = ->
    dbResult = await databaseHandler.getStaticProgramInformation()
    if dbResult.results? then return dbResult.results
    throw "Error, there have been no results..."

programdatahandlermodule.getProgram = (id) ->
    id = parseInt(id)
    dbResult = await databaseHandler.getDynamicProgramData(id)
    if dbResult.results? 
        programsDynamicInfo = dbResult.results[0]
        idToDynamicInfo[id] = programsDynamicInfo
        programObject = createProgramObject(programsDynamicInfo)
        return programObject
    throw "Error, there have been no results..."

programdatahandlermodule.getRun = (id) ->
    id = parseInt(id)
    dbResult = await databaseHandler.getRunHistoryEntry(id)
    if dbResult.results? 
        runHistoryEntry = dbResult.results[0]
        return createRunObject(runHistoryEntry)
    throw "Error, there have been no results..."

programdatahandlermodule.updateRunLabel = (id, label) ->
    id = parseInt(id)
    inserts = [id, label]
    databaseHandler.updateRunLabel(inserts)

programdatahandlermodule.setProgramActive = (id) ->
    id = parseInt(id)
    programsDynamicInfo = idToDynamicInfo[id]
    if programsDynamicInfo and !programsDynamicInfo.is_active
        log(JSON.stringify(idToDynamicInfo))
        for info in idToDynamicInfo
            if info? and info.programs_static_id == programsDynamicInfo.programs_static_id
                info.is_active = false
        programsDynamicInfo.is_active = true
        databaseHandler.setProgramActive(id)

programdatahandlermodule.cloneProgram = (id) ->
    id = parseInt(id)
    try
        programsDynamicInfo = await getDynamicProgramInfoSavely(id)
        inserts = createNewProgramsDynamicInserts(programsDynamicInfo)
        log(JSON.stringify(inserts))
        result = await databaseHandler.saveNewProgram(inserts)
        # console.log("Program cloned successfully!! ;:D")
        # console.log(JSON.stringify(result))
        # console.log(result.results[2].insertId)
        insertedId = result.results[2].insertId
        overviewEntry = await getOverviewEntry(insertedId)
        ws.notifyCloneCreated(overviewEntry)
    catch e then log e
    return

programdatahandlermodule.saveProgram = (program) ->
    try
        programsDynamicInfo = await extractMergedDynamicInfoObject(program)
        inserts = createProgramsDynamicUpdateInserts(programsDynamicInfo)
        # console.log(JSON.stringify(inserts))
        await databaseHandler.updateProgram(inserts)
        log("program saved successfully!! ;:D")
    catch e
        log e
        log "Program not saved!"
    return    

#endregion exposed functions

export default programdatahandlermodule