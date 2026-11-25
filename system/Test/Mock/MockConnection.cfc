<!---
 * Difference: the original extends BaseConnection. This class is in
 * another folder, so it is mixed in with parent (see the reference,
 * "How components are located").
 *
 * Difference: the return values are the text "true" and "false" for a
 * boolean, and an empty string for a null. The "false|object|resource"
 * of the original is "false" or any value. A list of values for connect()
 * is a CFML array.
 *
 * Difference: the query and result classes are made from the name of
 * this class (this.__class), where the original uses static::class.
--->
<cfcomponent output="no" parent="ColdIgniter\Database\BaseConnection" hint="A connection that does not connect to anything, for tests">

	<!---
	 * @var array{
	 *   connect?: false|list<false|object|resource>|object|resource,
	 *   execute?: false|object|resource,
	 * }
	--->
	<cfset this.returnValues = CreateObject("java", "java.util.LinkedHashMap").init()>

	<!---
	 * Database schema for Postgre and SQLSRV
	 *
	 * @var string
	--->
	<cfset this.schema = "">

	<!---
	 * @var string
	--->
	<cfset this.database = "">

	<!---
	 * @var Query
	--->
	<cfset this.lastQuery = "">

	<!---
	 * @param return false|list<false|object|resource>|object|resource
	 *
	 * @return this
	--->
	<cffunction name="shouldReturn" access="public" returntype="any" output="no">
		<cfargument name="method" type="string" required="yes">
		<cfargument name="return_" type="any" required="yes">

		<cfset this.returnValues[arguments.method] = arguments.return_>

		<cfreturn this>
	</cffunction>

	<!---
	 * Orchestrates a query against the database. Queries must use
	 * Database\Statement objects to store the query and build it.
	 * This method works with the cache.
	 *
	 * Should automatically handle different connections for read/write
	 * queries if needed.
	 *
	 * @param binds A list or a map, or an empty string
	 *
	 * @return BaseResult|bool|Query The text "true" or "false" for a bool
	--->
	<cffunction name="query" access="public" returntype="any" output="no">
		<cfargument name="sql" type="string" required="yes">
		<cfargument name="binds" type="any" required="no" default="">
		<cfargument name="setEscapeFlags" type="boolean" required="no" default="true">
		<cfargument name="queryClass" type="string" required="no" default="">
		<cfset var queryClass_ = str_replace("Connection", "Query", this.__class)>
		<cfset var query_ = new_(queryClass_, this)>
		<cfset var startTime = 0>
		<cfset var resultClass = "">

		<cfset query_.setQuery(arguments.sql, arguments.binds, arguments.setEscapeFlags)>

		<cfif Len(this.swapPre) GT 0 AND Len(this.DBPrefix) GT 0>
			<cfset query_.swapPrefix(this.DBPrefix, this.swapPre)>
		</cfif>

		<cfset startTime = microtime(true)>

		<cfset this.lastQuery = query_>

		<cfset this.resultID = this.simpleQuery(query_.getQuery())>

		<cfif identical_(this.resultID, "false")>
			<cfset query_.setDuration(startTime, startTime)>

			<!--- @todo deal with errors --->

			<cfreturn "false">
		</cfif>

		<cfset query_.setDuration(startTime)>

		<!--- resultID is not false, so it must be successful --->
		<cfif query_.isWriteType()>
			<cfreturn "true">
		</cfif>

		<!--- query is not write-type, so it must be read-type query; return QueryResult --->
		<cfset resultClass = str_replace("Connection", "Result", this.__class)>

		<cfreturn new_(resultClass, this.connID, this.resultID)>
	</cffunction>

	<!---
	 * Connect to the database.
	 *
	 * @return false|object|resource
	--->
	<cffunction name="connect" access="public" returntype="any" output="no">
		<cfargument name="persistent" type="boolean" required="no" default="false">
		<cfset var return_ = "true">
		<cfset var shifted = "">

		<cfif array_key_exists("connect", this.returnValues)>
			<cfset return_ = this.returnValues["connect"]>
		</cfif>

		<cfif IsArray(return_)>
			<!--- By removing the top item here, we can get a different value for, say, testing failover connections. --->
			<cfif ArrayLen(return_) EQ 0>
				<cfreturn "">
			</cfif>

			<cfset shifted = return_[1]>
			<cfset ArrayDeleteAt(return_, 1)>
			<!--- An array is copied when it is assigned, so the shortened list is stored again. --->
			<cfset this.returnValues["connect"] = return_>

			<cfreturn shifted>
		</cfif>

		<cfreturn return_>
	</cffunction>

	<!---
	 * Keep or establish the connection if no queries have been sent for
	 * a length of time exceeding the server's idle timeout.
	--->
	<cffunction name="reconnect" access="public" returntype="any" output="no">
		<cfreturn true>
	</cffunction>

	<!---
	 * Select a specific database table to use.
	 *
	 * @return bool
	--->
	<cffunction name="setDatabase" access="public" returntype="any" output="no">
		<cfargument name="databaseName" type="string" required="yes">

		<cfset this.database = arguments.databaseName>

		<cfreturn true>
	</cffunction>

	<!---
	 * Returns a string containing the version of the database being used.
	--->
	<cffunction name="getVersion" access="public" returntype="string" output="no">
		<cfreturn static_("ColdIgniter\ColdIgniter").CI_VERSION>
	</cffunction>

	<!---
	 * Executes the query against the database.
	 *
	 * @return false|object|resource
	--->
	<cffunction name="execute" access="private" returntype="any" output="no">
		<cfargument name="sql" type="string" required="yes">

		<cfreturn this.returnValues["execute"]>
	</cffunction>

	<!---
	 * Returns the total number of rows affected by this query.
	--->
	<cffunction name="affectedRows" access="public" returntype="numeric" output="no">
		<cfreturn 1>
	</cffunction>

	<!---
	 * Returns the last error code and message.
	 *
	 * @return A map with code and message
	--->
	<cffunction name="error" access="public" returntype="any" output="no">
		<cfreturn array_(
			"code", 0,
			"message", ""
		)>
	</cffunction>

	<cffunction name="insertID" access="public" returntype="any" output="no">
		<cfreturn 0>
	</cffunction>

	<!---
	 * Generates the SQL for listing tables in a platform-dependent manner.
	 *
	 * @param tableName If tableName is provided will return only this table if exists.
	--->
	<cffunction name="_listTables" access="private" returntype="any" output="no">
		<cfargument name="constrainByPrefix" type="boolean" required="no" default="false">
		<cfargument name="tableName" type="string" required="no" default="">

		<cfreturn "">
	</cffunction>

	<!---
	 * Generates a platform-specific query string so that the column names can be fetched.
	 *
	 * @param table A string or a TableName
	--->
	<cffunction name="_listColumns" access="private" returntype="any" output="no">
		<cfargument name="table" type="any" required="no" default="">

		<cfreturn "">
	</cffunction>

	<!---
	 * @return list<stdClass>
	--->
	<cffunction name="_fieldData" access="private" returntype="any" output="no">
		<cfargument name="table" type="string" required="yes">

		<cfreturn ArrayNew(1)>
	</cffunction>

	<!---
	 * @return array<string, stdClass>
	--->
	<cffunction name="_indexData" access="private" returntype="any" output="no">
		<cfargument name="table" type="string" required="yes">

		<cfreturn array_()>
	</cffunction>

	<!---
	 * @return array<string, stdClass>
	--->
	<cffunction name="_foreignKeyData" access="private" returntype="any" output="no">
		<cfargument name="table" type="string" required="yes">

		<cfreturn array_()>
	</cffunction>

	<!---
	 * Close the connection.
	--->
	<cffunction name="_close" access="private" returntype="void" output="no">
	</cffunction>

	<!---
	 * Begin Transaction
	--->
	<cffunction name="_transBegin" access="private" returntype="boolean" output="no">
		<cfreturn true>
	</cffunction>

	<!---
	 * Commit Transaction
	--->
	<cffunction name="_transCommit" access="private" returntype="boolean" output="no">
		<cfreturn true>
	</cffunction>

	<!---
	 * Rollback Transaction
	--->
	<cffunction name="_transRollback" access="private" returntype="boolean" output="no">
		<cfreturn true>
	</cffunction>

</cfcomponent>
