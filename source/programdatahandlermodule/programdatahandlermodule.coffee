programdatahandlermodule = {name: "programdatahandlermodule"}

#region node_modules
fs = require('fs')
coffeescript = require("coffeescript")
js2coffee = require("js2coffee")
vm = require('vm')
pathModule = require("path")
#endregion

#log Switch
log = (arg) ->
    if allModules.debugmodule.modulesToDebug["programdatahandlermodule"]?  then console.log "[programdatahandlermodule]: " + arg
    return

#region internal variables
state =  null

programsPath = ""
langfilePath = ""

programsCoffeeString = ""
programsLangfileCoffeeString = ""
programsJavascriptString = ""
programsLangfileJavascriptString = ""
#endregion

##initialization function  -> is automatically being called!  ONLY RELY ON DOM AND VARIABLES!! NO PLUGINS NO OHTER INITIALIZATIONS!!
programdatahandlermodule.initialize = () ->
    log "programdatahandlermodule.initialize"
    c = allModules.configmodule
    programsPath = pathModule.resolve(process.cwd(), c.programsPath)
    langfilePath = pathModule.resolve(process.cwd(), c.langfilePath)
    state = allModules.serverstatemodule

#region internal functions
################################################################################
# Internal Functions
################################################################################
cutOffExport = (string) ->
    return string.replace(/export(.*\n*\r*)*$/, '')

readFilesSync = ->
    programsCoffeeString = fs.readFileSync(programsPath, "utf-8")
    programsLangfileCoffeeString = fs.readFileSync(langfilePath, "utf-8")
    programsCoffeeString = cutOffExport(programsCoffeeString)
    programsLangfileCoffeeString = cutOffExport(programsLangfileCoffeeString)

transpileFilesSync = ->
    options = {header: false}
    programsJavascriptString = coffeescript.compile(programsCoffeeString, options)
    programsLangfileJavascriptString = coffeescript.compile(programsLangfileCoffeeString, options)

manipulateStringsForExecution = ->
    programsJavascriptString = programsJavascriptString.replace("(function() {", "")
    programsLangfileJavascriptString = programsLangfileJavascriptString.replace("(function() {", "")
    programsJavascriptString = programsJavascriptString.replace("}).call(this);", "")
    programsLangfileJavascriptString = programsLangfileJavascriptString.replace("}).call(this);", "")
    
extractData = ->
    programsContext = vm.createContext({ programs: null })
    langStringsContext = vm.createContext({ programLangStrings: null })
    vm.runInContext(programsJavascriptString, programsContext)
    vm.runInContext(programsLangfileJavascriptString, langStringsContext)
    state.programs = programsContext.programs
    state.langStrings = langStringsContext.programLangStrings

deleteStrings = ->
    programsCoffeeString = ""
    programsLangfileCoffeeString = ""
    programsJavascriptString = ""
    programsLangfileJavascriptString = ""

createCoffeeFromJSObject = (varName, object) ->
    objectString = JSON.stringify(object)
    prefix = "var " + varName + " = "
    postfix = "\nexport default "+ varName + "\n"
    newJavascript = prefix + objectString
    result = js2coffee.build(newJavascript)
    return (result.code + postfix)
#endregion


#region exposed functions
programdatahandlermodule.prepareProgramData = ->
    log "programdatahandlermodule.prepareProgramData"
    readFilesSync()
    transpileFilesSync()
    manipulateStringsForExecution()
    extractData()
    deleteStrings()
    # log JSON.stringify state.programs


programdatahandlermodule.writeNewProgramsFile = ->
    log "programdatahandlermodule.writeNewProgramsFile"
    coffee = createCoffeeFromJSObject("programs", state.programs)
    fs.writeFileSync(programsPath, coffee)
    return

programdatahandlermodule.writeNewProgramsLangfile = ->
    log "programdatahandlermodule.writeNewProgramsLangfile"
    coffee = createCoffeeFromJSObject("programLangStrings", state.langStrings)
    fs.writeFileSync(langfilePath, coffee)
    return

#endregion exposed functions

export default programdatahandlermodule