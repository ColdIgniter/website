<!---
 * Difference: the original is abstract. Here _backup() is a method that
 * throws, and each driver overrides it.
 *
 * Difference: the return values are the text "true" and "false" for a
 * boolean. The ConnectionInterface and ResultInterface types are "any".
 * Settings (listDatabases_, optimizeTable_, repairTable_) that are false
 * in the original hold the text "false". They end in an underscore, as
 * a property cannot have the name of a method.
 *
 * Difference: backup() has no gzip format: gzencode() does not exist. The
 * format gzip (the default) is turned into txt, also when DBDebug is on
 * (the original throws then only if gzencode() is missing), so the
 * gzencode() step is not ported.
--->
<cfcomponent output="no" hint="Base Utils">

	<!---
	 * Database object
	 *
	 * @var BaseConnection
	--->
	<cfset this.db = "">

	<!---
	 * List databases statement
	 *
	 * @var false|string
	--->
	<cfset this.listDatabases_ = "false">

	<!---
	 * OPTIMIZE TABLE statement
	 *
	 * @var false|string
	--->
	<cfset this.optimizeTable_ = "false">

	<!---
	 * REPAIR TABLE statement
	 *
	 * @var false|string
	--->
	<cfset this.repairTable_ = "false">

	<!---
	 * @param db BaseConnection
	--->
	<cffunction name="__construct" access="public" returntype="any" output="no">
		<cfargument name="db" type="any" required="yes">

		<cfset this.db = arguments.db>

		<cfreturn this>
	</cffunction>

	<!---
	 * List databases.
	 *
	 * @return array|false
	 *
	 * @throws DatabaseException
	--->
	<cffunction name="listDatabases" access="public" returntype="any" output="no">
		<cfset var names = ArrayNew(1)>
		<cfset var query_ = "">
		<cfset var rows = "">
		<cfset var keys = "">
		<cfset var i = 0>

		<!--- Is there a cached result? --->
		<cfif array_key_exists("db_names", this.db.dataCache)>
			<cfreturn this.db.dataCache["db_names"]>
		</cfif>

		<cfif identical_(this.listDatabases_, "false")>
			<cfif this.db.DBDebug>
				<cfthrow type="ColdIgniter.Database.Exceptions.DatabaseException" message="Unsupported feature of the database platform you are using.">
			</cfif>

			<cfreturn "false">
		</cfif>

		<cfset this.db.dataCache["db_names"] = names>

		<cfset query_ = this.db.query(this.listDatabases_)>

		<cfif identical_(query_, "false")>
			<cfreturn names>
		</cfif>

		<cfset rows = query_.getResultArray()>

		<cfloop from="1" to="#ArrayLen(rows)#" index="i">
			<cfset keys = array_keys(rows[i])>
			<cfset ArrayAppend(names, rows[i][keys[1]])>
		</cfloop>

		<cfset this.db.dataCache["db_names"] = names>

		<cfreturn names>
	</cffunction>

	<!---
	 * Determine if a particular database exists
	--->
	<cffunction name="databaseExists" access="public" returntype="boolean" output="no">
		<cfargument name="databaseName" type="string" required="yes">
		<cfset var names = this.listDatabases()>
		<cfset var i = 0>

		<cfif NOT IsArray(names)>
			<cfreturn false>
		</cfif>

		<cfloop from="1" to="#ArrayLen(names)#" index="i">
			<cfif Compare(names[i], arguments.databaseName) EQ 0>
				<cfreturn true>
			</cfif>
		</cfloop>

		<cfreturn false>
	</cffunction>

	<!---
	 * Optimize Table
	 *
	 * @return bool The text "true" or "false"
	 *
	 * @throws DatabaseException
	--->
	<cffunction name="optimizeTable" access="public" returntype="any" output="no">
		<cfargument name="tableName" type="string" required="yes">
		<cfset var query_ = "">

		<cfif identical_(this.optimizeTable_, "false")>
			<cfif this.db.DBDebug>
				<cfthrow type="ColdIgniter.Database.Exceptions.DatabaseException" message="Unsupported feature of the database platform you are using.">
			</cfif>

			<cfreturn "false">
		</cfif>

		<cfset query_ = this.db.query(str_replace("%s", this.db.escapeIdentifiers(arguments.tableName), this.optimizeTable_))>

		<cfif identical_(query_, "false")>
			<cfreturn "false">
		</cfif>

		<cfreturn "true">
	</cffunction>

	<!---
	 * Optimize Database
	 *
	 * @return array|bool A map of results per table, or "true" or "false"
	 *
	 * @throws DatabaseException
	--->
	<cffunction name="optimizeDatabase" access="public" returntype="any" output="no">
		<cfset var result = array_()>
		<cfset var tables = "">
		<cfset var res = "">
		<cfset var first = "">
		<cfset var keys = "">
		<cfset var key = "">
		<cfset var rest = "">
		<cfset var i = 0>
		<cfset var j = 0>

		<cfif identical_(this.optimizeTable_, "false")>
			<cfif this.db.DBDebug>
				<cfthrow type="ColdIgniter.Database.Exceptions.DatabaseException" message="Unsupported feature of the database platform you are using.">
			</cfif>

			<cfreturn "false">
		</cfif>

		<cfset tables = this.db.listTables()>

		<cfloop from="1" to="#ArrayLen(tables)#" index="i">
			<cfset res = this.db.query(str_replace("%s", this.db.escapeIdentifiers(tables[i]), this.optimizeTable_))>

			<cfif identical_(res, "true") OR identical_(res, "false")>
				<cfreturn res>
			</cfif>

			<!--- Build the result array... --->
			<cfset res = res.getResultArray()>

			<!--- Postgre & SQLite3 returns empty array --->
			<cfif ArrayLen(res) EQ 0>
				<cfset key = tables[i]>
				<cfset rest = array_()>
			<cfelse>
				<cfset first = res[1]>
				<cfset keys = array_keys(first)>
				<cfset key = str_replace(this.db.database & ".", "", first[keys[1]])>
				<cfset rest = array_()>

				<cfloop from="2" to="#ArrayLen(keys)#" index="j">
					<cfset rest[keys[j]] = first[keys[j]]>
				</cfloop>
			</cfif>

			<cfset result[key] = rest>
		</cfloop>

		<cfreturn result>
	</cffunction>

	<!---
	 * Repair Table
	 *
	 * @return array|bool A map of the first row, or "true" or "false"
	 *
	 * @throws DatabaseException
	--->
	<cffunction name="repairTable" access="public" returntype="any" output="no">
		<cfargument name="tableName" type="string" required="yes">
		<cfset var query_ = "">
		<cfset var rows = "">

		<cfif identical_(this.repairTable_, "false")>
			<cfif this.db.DBDebug>
				<cfthrow type="ColdIgniter.Database.Exceptions.DatabaseException" message="Unsupported feature of the database platform you are using.">
			</cfif>

			<cfreturn "false">
		</cfif>

		<cfset query_ = this.db.query(str_replace("%s", this.db.escapeIdentifiers(arguments.tableName), this.repairTable_))>

		<!--- Postgre & SQLite3 returns empty array --->
		<cfif identical_(query_, "true") OR identical_(query_, "false")>
			<cfreturn query_>
		</cfif>

		<cfset rows = query_.getResultArray()>

		<cfif ArrayLen(rows) EQ 0>
			<cfreturn "false">
		</cfif>

		<cfreturn rows[1]>
	</cffunction>

	<!---
	 * Generate CSV from a query result object
	 *
	 * @param query ResultInterface
	--->
	<cffunction name="getCSVFromResult" access="public" returntype="string" output="no">
		<cfargument name="query" type="any" required="yes">
		<cfargument name="delim" type="string" required="no" default=",">
		<cfargument name="newline" type="string" required="no" default="#Chr(10)#">
		<cfargument name="enclosure" type="string" required="no" default="""">
		<cfset var out = "">
		<cfset var names = arguments.query.getFieldNames()>
		<cfset var row = "">
		<cfset var keys = "">
		<cfset var line = "">
		<cfset var i = 0>
		<cfset var j = 0>

		<cfloop from="1" to="#ArrayLen(names)#" index="i">
			<cfset out = out & arguments.enclosure & str_replace(arguments.enclosure, arguments.enclosure & arguments.enclosure, names[i]) & arguments.enclosure & arguments.delim>
		</cfloop>

		<cfif Len(out) GTE Len(arguments.delim)>
			<cfset out = Left(out, Len(out) - Len(arguments.delim))>
		</cfif>

		<cfset out = out & arguments.newline>

		<!--- Next blast through the result array and build out the rows --->
		<cfset row = arguments.query.getUnbufferedRow("array")>

		<cfloop condition="NOT IsSimpleValue(row)">
			<cfset keys = array_keys(row)>
			<cfset line = ArrayNew(1)>

			<cfloop from="1" to="#ArrayLen(keys)#" index="j">
				<cfset ArrayAppend(line, arguments.enclosure & str_replace(arguments.enclosure, arguments.enclosure & arguments.enclosure, row[keys[j]]) & arguments.enclosure)>
			</cfloop>

			<cfset out = out & implode(arguments.delim, line) & arguments.newline>
			<cfset row = arguments.query.getUnbufferedRow("array")>
		</cfloop>

		<cfreturn out>
	</cffunction>

	<!---
	 * Generate XML data from a query result object
	 *
	 * @param query  ResultInterface
	 * @param params A map of root, element, newline and tab, or an empty string
	--->
	<cffunction name="getXMLFromResult" access="public" returntype="string" output="no">
		<cfargument name="query" type="any" required="yes">
		<cfargument name="params" type="any" required="no" default="">
		<cfset var defaults = array_("root", "root", "element", "element", "newline", Chr(10), "tab", Chr(9))>
		<cfset var settings = array_()>
		<cfset var names = array_keys(defaults)>
		<cfset var xml = "">
		<cfset var row = "">
		<cfset var keys = "">
		<cfset var val = "">
		<cfset var i = 0>
		<cfset var j = 0>

		<cfloop from="1" to="#ArrayLen(names)#" index="i">
			<cfif NOT IsSimpleValue(arguments.params) AND array_key_exists(names[i], arguments.params)>
				<cfset settings[names[i]] = arguments.params[names[i]]>
			<cfelse>
				<cfset settings[names[i]] = defaults[names[i]]>
			</cfif>
		</cfloop>

		<cfset helper("xml")>
		<cfset xml = "<" & settings["root"] & ">" & settings["newline"]>

		<cfset row = arguments.query.getUnbufferedRow()>

		<cfloop condition="NOT IsSimpleValue(row)">
			<cfset xml = xml & settings["tab"] & "<" & settings["element"] & ">" & settings["newline"]>
			<cfset keys = array_keys(row)>

			<cfloop from="1" to="#ArrayLen(keys)#" index="j">
				<cfset val = row[keys[j]]>

				<cfif Len(val) GT 0>
					<cfset val = xml_convert(val)>
				</cfif>

				<cfset xml = xml & settings["tab"] & settings["tab"] & "<" & keys[j] & ">" & val & "</" & keys[j] & ">" & settings["newline"]>
			</cfloop>

			<cfset xml = xml & settings["tab"] & "</" & settings["element"] & ">" & settings["newline"]>
			<cfset row = arguments.query.getUnbufferedRow()>
		</cfloop>

		<cfreturn xml & "</" & settings["root"] & ">" & settings["newline"]>
	</cffunction>

	<!---
	 * Database Backup
	 *
	 * @param params A map of settings, or a table name (text)
	 *
	 * @throws DatabaseException
	--->
	<cffunction name="backup" access="public" returntype="any" output="no">
		<cfargument name="params" type="any" required="no" default="">
		<cfset var params_ = arguments.params>
		<cfset var prefs = array_("tables", ArrayNew(1), "ignore", ArrayNew(1), "filename", "", "format", "gzip", "add_drop", "true", "add_insert", "true", "newline", Chr(10), "foreign_key_checks", "true")>
		<cfset var keys = array_keys(prefs)>
		<cfset var i = 0>

		<cfif IsSimpleValue(params_) AND Len(params_) GT 0>
			<cfset params_ = array_("tables", params_)>
		</cfif>

		<cfif NOT IsSimpleValue(params_)>
			<cfloop from="1" to="#ArrayLen(keys)#" index="i">
				<cfif array_key_exists(keys[i], params_)>
					<cfset prefs[keys[i]] = params_[keys[i]]>
				</cfif>
			</cfloop>
		</cfif>

		<!--- Are we backing up a complete database or individual tables? --->
		<cfif (IsArray(prefs["tables"]) AND ArrayLen(prefs["tables"]) EQ 0) OR (IsSimpleValue(prefs["tables"]) AND Len(prefs["tables"]) EQ 0)>
			<cfset prefs["tables"] = this.db.listTables()>
		</cfif>

		<!--- Validate the format --->
		<cfif Compare(prefs["format"], "gzip") NEQ 0 AND Compare(prefs["format"], "txt") NEQ 0>
			<cfset prefs["format"] = "txt">
		</cfif>

		<!--- There is no encoder, so gzip is plain text. --->
		<cfif Compare(prefs["format"], "gzip") EQ 0>
			<cfset prefs["format"] = "txt">
		</cfif>

		<cfreturn this._backup(prefs)>
	</cffunction>

	<!---
	 * Platform dependent version of the backup function.
	 *
	 * Overridden by driver classes.
	--->
	<cffunction name="_backup" access="public" returntype="any" output="no">
		<cfargument name="prefs" type="any" required="no" default="">

		<cfthrow type="ColdIgniter.LogicException" message="The class does not define _backup().">
	</cffunction>

</cfcomponent>
