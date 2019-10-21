
utilmodule = {name: "utilmodule"}

#log Switch
log = (arg) ->
    if allModules.debugmodule.modulesToDebug["utilmodule"]?  then console.log "[utilmodule]: " + arg
    return

#region internal variables
#endregion

##initialization function  -> is automatically being called!  ONLY RELY ON DOM AND VARIABLES!! NO PLUGINS NO OHTER INITIALIZATIONS!!
utilmodule.initialize = () ->
    log "utilmodule.initialize"

#region exposed functions
utilmodule.byteArrayToBlobHexString = (buffer) ->
    array = new Uint8Array(buffer);
    resultString = "x'"
    for num in array
        if  num < 16
            resultString += "0"
        resultString += num.toString(16)
    resultString += "'"
    log(resultString)
    return resultString

utilmodule.mapIdToProgram = (allPrograms) ->
    result = []
    for program in allPrograms.relaxprograms
        result[program.id] = program
    for program in allPrograms.performprograms
        result[program.id] = program
    return result

#endregion exposed functions

export default utilmodule