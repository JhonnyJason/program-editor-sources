databasehandlermodule = {name: "databasehandlermodule"}

#region node_modules
mysql = require("mysql")
mariadb = require("mariadb")
fs = require("fs")
#endregion

#log Switch
log = (arg) ->
    if allModules.debugmodule.modulesToDebug["databasehandlermodule"]?  then console.log "[databasehandlermodule]: " + arg
    return

#region internal variables
dbConnectionMysql = null
dbConnectionMariadb = null
#endregion

##initialization function  -> is automatically being called!  ONLY RELY ON DOM AND VARIABLES!! NO PLUGINS NO OHTER INITIALIZATIONS!!
databasehandlermodule.initialize = () ->
    log "databasehandlermodule.initialize"
    c = allModules.configmodule
    caPath = c.dbCaFilePath
    keyPath = c.dbKeyFilePath
    certPath = c.dbCertFilePath
    # log "__dirname: " + __dirname
    # log "caPath: " + caPath
    # log "keyPath: " + keyPath
    # log "certPath: " + certPath
    # return
    accessOptions = 
        multipleStatements: true
        host: c.dbHost
        user: c.dbUser
        password: c.dbPassword
        database: c.dbName
        ssl:
            ca: fs.readFileSync(caPath)
            key: fs.readFileSync(keyPath)
            cert: fs.readFileSync(certPath)
            rejectUnauthorized: false

    dbConnectionMysql = mysql.createConnection(accessOptions)
    console.log("\n ! ! ! ! !  survived connect call!\n")

    return
    # caFile = [fs.readFileSync(caPath, "utf8")]
    # keyFile = [fs.readFileSync(keyPath, "utf8")]
    # certFile = [fs.readFileSync(certPath, "utf8")]

    # accessOptions = 
    #     multipleStatements: true
    #     host: c.dbHost
    #     user: c.dbUser
    #     password: c.dbPassword
    #     database: c.dbName
    #     # timezone: "auto"
    #     ssl:
    #         ca: caFile
    #         key: keyFile
    #         cert: certFile
    #         rejectUnauthorized: false

    # dbConnectionMariadb = await mariadb.createConnection(accessOptions)

    # console.log(" ! ! ! ! !  surrviced connect call!")
    # return

#region internalFunction

#region queryGetter
getStaticProgramInformationQuery = ->
    return "SELECT * FROM programs_test_history.programs_static;"
    
getProgramsOverviewQuery = ->
    return "SELECT programs_dynamic_id,programs_static_id,version,version_label,is_active FROM programs_test_history.programs_dynamic;"

getRunHistoryOverviewQuery = (programDynamicID) ->
    sql = "SELECT programs_runs_id,programs_dynamic_id,timestamp,run_label FROM programs_test_history.programs_runs WHERE programs_dynamic_id = ?;"
    inserts = [programDynamicID]
    return mysql.format(sql, inserts)

getDynamicProgramDataQuery = (programDynamicID) ->
    sql = "SELECT * FROM programs_test_history.programs_dynamic WHERE programs_dynamic_id = ?;"
    inserts = [programDynamicID]
    return mysql.format(sql, inserts)

getRunQuery = (runID) ->
    sql = "SELECT * FROM programs_test_history.programs_runs WHERE programs_runs_id = ?;"
    inserts = [runID]
    return mysql.format(sql, inserts)

getActiveProgramsQuery = ->
    return "SELECT programs_dynamic_id,programs_static_id,version_label FROM programs_test_history.programs_dynamic WHERE is_active = 1;"

getSetProgramActiveQuery = (programDynamicID) ->
    sql = "SET SQL_SAFE_UPDATES = 0;\nSET @dynamic_id = ?;\nSET @static_id = (SELECT programs_static_id AS static_id FROM programs_test_history.programs_dynamic WHERE programs_dynamic_id = @dynamic_id);\nUPDATE programs_test_history.programs_dynamic SET is_active = 0 WHERE programs_static_id = @static_id;\nUPDATE programs_test_history.programs_dynamic SET is_active = 1 WHERE programs_dynamic_id = @dynamic_id AND programs_static_id = @static_id;\nSET SQL_SAFE_UPDATES = 1;"
    inserts = [programDynamicID]
    return mysql.format(sql, inserts)

getUpdateDynamicProgramDataQuery = (inserts) ->
    sql = "UPDATE programs_test_history.programs_dynamic SET version_label = ?, duration_ms = ?, intensity = ?, temperature = ?, vibration = ?, buffertemp1 = ?, buffertemp2 = ?, buffertemp3 = ?, buffertemp4 = ?, buffervib1 = ?, buffervib2 = ?, bufferagression = ?, bufferduration = ?, datapoints = ?, is_active = ? WHERE programs_dynamic_id = ?;"
    return mysql.format(sql, inserts)

getUpdateRunLabelQuery = (inserts) ->
    sql = "SET SQL_SAFE_UPDATES = 0;\nSET @run_id = ?;\nUPDATE programs_test_history.programs_runs SET run_label = ? WHERE programs_runs_id = @run_id;\nSET SQL_SAFE_UPDATES = 1;"
    return mysql.format(sql, inserts)


getSaveNewProgramQuery = (inserts) ->
    sql = "SET @static_id = ?;\nSET @new_version = (SELECT MAX(version) + 1 AS newversion FROM programs_test_history.programs_dynamic WHERE programs_static_id = @static_id);\nINSERT INTO `programs_test_history`.`programs_dynamic`(`programs_static_id`,`version`,`version_label`,`duration_ms`,`intensity`,`temperature`,`vibration`,`buffertemp1`,`buffertemp2`,`buffertemp3`,`buffertemp4`,`buffervib1`,`buffervib2`,`bufferagression`,`bufferduration`,`datapoints`,`is_active`)\nVALUES(@static_id,@new_version,?,?,?,?,?,?,?,?,?,?,?,?,?,?,'0');"
    return mysql.format(sql, inserts)

getSaveNewRunQuery = (inserts) ->
    sql = "INSERT INTO `programs_test_history`.`programs_runs`(`programs_dynamic_id`,`timestamp`,`run_label`,`temp_ble_module`,`temp_battery_left`,`temp_pte1`,`temp_pte1_outside`,`temp_pte2`,`temp_pte2_outside`,`temp_pte3`,`temp_pte3_outside`,`temp_pte4`,`temp_pte4_outside`,`programs_progress`)\nVALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?);"
    return mysql.format(sql, inserts)
#endregion

getProgramOverview = (resolve, reject) ->
    dbConnectionMysql.query(
        getProgramsOverviewQuery(), 
        (error, results, fields) ->
            if (error)
                reject("error occurered: " + error)            
            result = 
                results: results
                fields: fields
            resolve(result)
    )

getRunHistoryOverview = (resolve, reject, programDynamicID) ->
    dbConnectionMysql.query(
        getRunHistoryOverviewQuery(programDynamicID), 
        (error, results, fields) ->
            if (error)
                reject("error occurered: " + error)            
            result = 
                results: results
                fields: fields
            resolve(result)
    )


getDynamicProgramData = (resolve, reject, programDynamicID) ->
    dbConnectionMysql.query(
        getDynamicProgramDataQuery(programDynamicID), 
        (error, results, fields) ->
            if (error)
                reject("error occurered: " + error)            
            result = 
                results: results
                fields: fields
            resolve(result)
    )

getRun = (resolve, reject, runID) ->
    dbConnectionMysql.query(
        getRunQuery(runID), 
        (error, results, fields) ->
            if (error)
                reject("error occurered: " + error)            
            result = 
                results: results
                fields: fields
            resolve(result)
    )

getActivePrograms = (resolve, reject) ->
    dbConnectionMysql.query(
        getActiveProgramsQuery(), 
        (error, results, fields) ->
            if (error)
                reject("error occurered: " + error)            
            result = 
                results: results
                fields: fields
            resolve(result)
    )

setProgramActive = (resolve, reject, programDynamicID) ->
    dbConnectionMysql.query(
        getSetProgramActiveQuery(programDynamicID), 
        (error, results, fields) ->
            if (error)
                reject("error occurered: " + error)            
            result = 
                results: results
                fields: fields
            resolve(result)
    )

saveNewProgram = (resolve, reject, inserts) ->
    dbConnectionMysql.query(
        getSaveNewProgramQuery(inserts), 
        (error, results, fields) ->
            if (error)
                reject("error occurered: " + error)            
            result = 
                results: results
                fields: fields
            resolve(result)
    )

updateProgram = (resolve, reject, inserts) ->
    dbConnectionMysql.query(
        getUpdateDynamicProgramDataQuery(inserts), 
        (error, results, fields) ->
            if (error)
                reject("error occurered: " + error)            
            result = 
                results: results
                fields: fields
            resolve(result)
    )

updateRunLabel = (resolve, reject, inserts) ->
    dbConnectionMysql.query(
        getUpdateRunLabelQuery(inserts), 
        (error, results, fields) ->
            if (error)
                reject("error occurered: " + error)            
            result = 
                results: results
                fields: fields
            resolve(result)
    )


saveNewRun = (resolve, reject, inserts) ->
    dbConnectionMysql.query(
        getSaveNewRunQuery(inserts), 
        (error, results, fields) ->
            if (error)
                reject("error occurered: " + error)            
            result = 
                results: results
                fields: fields
            resolve(result)
    )

getStaticProgramInformation = (resolve, reject) ->
    dbConnectionMysql.query(
        getStaticProgramInformationQuery(), 
        (error, results, fields) ->
            if (error)
                reject("error occurered: " + error)            
            result = 
                results: results
                fields: fields
            resolve(result)
    )

#endregion

#region exposed functions
databasehandlermodule.getProgramsOverview = -> new Promise(getProgramOverview)
databasehandlermodule.getRunHistoryOverview = (programDynamicID) ->
    return new Promise(
        (resolve, reject) -> getRunHistoryOverview(resolve, reject, programDynamicID)
    )
databasehandlermodule.getDynamicProgramData = (programDynamicID) ->
    return new Promise(
        (resolve, reject) -> getDynamicProgramData(resolve, reject, programDynamicID)
    )
databasehandlermodule.getRunHistoryEntry = (runID) ->
    return new Promise(
        (resolve, reject) -> getRun(resolve, reject, runID)
    )
databasehandlermodule.getCurrentActivePrograms = -> new Promise(getActivePrograms)
databasehandlermodule.setProgramActive = (programDynamicID) ->
    return new Promise(
        (resolve, reject) -> setProgramActive(resolve, reject, programDynamicID)
    )
databasehandlermodule.saveNewProgram = (inserts) ->
    return new Promise(
        (resolve, reject) -> saveNewProgram(resolve, reject, inserts)
    )
databasehandlermodule.saveNewRun = (inserts) ->
    return new Promise(
        (resolve, reject) -> saveNewRun(resolve, reject, inserts)
    )
databasehandlermodule.getStaticProgramInformation = -> new Promise(getStaticProgramInformation)
databasehandlermodule.updateProgram = (inserts) ->
    return new Promise(
        (resolve, reject) -> updateProgram(resolve, reject, inserts)
    )
databasehandlermodule.updateRunLabel = (inserts) ->
    return new Promise(
        (resolve, reject) -> updateRunLabel(resolve, reject, inserts)
    )
#endregion exposed functions

export default databasehandlermodule
