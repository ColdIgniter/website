<!---
 * Database Connection Factory
 *
 * Creates and returns an instance of the appropriate Database Connection.
 *
 * Difference: the parameters of a connection are a map (see array_()), and
 * an empty string is the null of the original.
 *
 * Difference: there are no language extensions to check, so checkDbExtension()
 * only checks the name of the driver. The CriticalError of the original is
 * not ported.
 *
 * A driver name in the original is a folder of connection, forge and utils
 * classes: SQLSRV has its connection, result, forge and utils. A driver that
 * does not exist ends in a class not found error from the autoloader.
--->
<cfcomponent output="no" hint="Database Connection Factory">

	<!---
	 * Maintains an array of the instances of all connections that have
	 * been created.
	 *
	 * Helps to keep track of all open connections for performance
	 * monitoring, logging, etc.
	 *
	 * @var array<string, BaseConnection>
	--->
	<cfset this.connections = CreateObject("java", "java.util.LinkedHashMap").init()>

	<!---
	 * Parses the connection binds and creates a Database Connection instance.
	 *
	 * @param params A map of settings, see array_()
	 *
	 * @return BaseConnection
	 *
	 * @throws InvalidArgumentException
	--->
	<cffunction name="load" access="public" returntype="any" output="no">
		<cfargument name="params" type="any" required="no" default="">
		<cfargument name="alias" type="string" required="no" default="">
		<cfset var params_ = arguments.params>

		<cfif Compare(arguments.alias, "") EQ 0>
			<cfthrow type="ColdIgniter.Exceptions.InvalidArgumentException" message="You must supply the parameter: alias.">
		</cfif>

		<!--- Difference: the default of params is an empty map --->
		<cfif NOT is_array(params_)>
			<cfset params_ = array_()>
		</cfif>

		<cfif array_key_exists("DSN", params_) AND Compare(params_["DSN"], "") NEQ 0 AND Find("://", params_["DSN"]) GT 0>
			<cfset params_ = parseDSN(params_)>
		</cfif>

		<cfif NOT array_key_exists("DBDriver", params_) OR Compare(params_["DBDriver"], "") EQ 0>
			<cfthrow type="ColdIgniter.Exceptions.InvalidArgumentException" message="You have not selected a database type to connect to.">
		</cfif>

		<cfset checkDbExtension(params_["DBDriver"])>

		<cfset this.connections[arguments.alias] = initDriver(params_["DBDriver"], "Connection", params_)>

		<cfreturn this.connections[arguments.alias]>
	</cffunction>

	<!---
	 * Creates a Forge instance for the current database type.
	 *
	 * @param db BaseConnection
	--->
	<cffunction name="loadForge" access="public" returntype="any" output="no">
		<cfargument name="db" type="any" required="yes">

		<cfif identical_(arguments.db.connID, "false")>
			<cfset arguments.db.initialize_()>
		</cfif>

		<cfreturn initDriver(arguments.db.DBDriver, "Forge", arguments.db)>
	</cffunction>

	<!---
	 * Creates an instance of Utils for the current database type.
	 *
	 * @param db BaseConnection
	--->
	<cffunction name="loadUtils" access="public" returntype="any" output="no">
		<cfargument name="db" type="any" required="yes">

		<cfif identical_(arguments.db.connID, "false")>
			<cfset arguments.db.initialize_()>
		</cfif>

		<cfreturn initDriver(arguments.db.DBDriver, "Utils", arguments.db)>
	</cffunction>

	<!---
	 * Parses universal DSN string
	 *
	 * Difference: a DSN without a scheme gives an empty DBDriver, which
	 * load() refuses, where the original reads a key that is not there.
	 *
	 * @param params A map of settings, see array_()
	 *
	 * @return A map of settings
	 *
	 * @throws InvalidArgumentException
	--->
	<cffunction name="parseDSN" access="private" returntype="any" output="no">
		<cfargument name="params" type="any" required="yes">
		<cfset var dsn = parse_url(arguments.params["DSN"])>
		<cfset var dsnParams = "">
		<cfset var extra = "">
		<cfset var keys = "">
		<cfset var key = "">
		<cfset var val = "">
		<cfset var i = 0>

		<cfif dsn.size() EQ 0>
			<cfthrow type="ColdIgniter.Exceptions.InvalidArgumentException" message="Your DSN connection string is invalid.">
		</cfif>

		<cfset dsnParams = array_(
			"DSN", "",
			"DBDriver", "",
			"hostname", "",
			"port", "",
			"username", "",
			"password", "",
			"database", ""
		)>

		<cfif array_key_exists("scheme", dsn)>
			<cfset dsnParams["DBDriver"] = dsn["scheme"]>
		</cfif>

		<cfif array_key_exists("host", dsn)>
			<cfset dsnParams["hostname"] = rawurldecode(dsn["host"])>
		</cfif>

		<cfif array_key_exists("port", dsn)>
			<cfset dsnParams["port"] = rawurldecode(dsn["port"] & "")>
		</cfif>

		<cfif array_key_exists("user", dsn)>
			<cfset dsnParams["username"] = rawurldecode(dsn["user"])>
		</cfif>

		<cfif array_key_exists("pass", dsn)>
			<cfset dsnParams["password"] = rawurldecode(dsn["pass"])>
		</cfif>

		<cfif array_key_exists("path", dsn)>
			<cfset dsnParams["database"] = rawurldecode(substr(dsn["path"], 1))>
		</cfif>

		<cfif array_key_exists("query", dsn) AND Compare(dsn["query"], "") NEQ 0>
			<cfset extra = parse_str(dsn["query"])>
			<cfset keys = array_keys(extra)>

			<cfloop from="1" to="#ArrayLen(keys)#" index="i">
				<cfset key = keys[i]>
				<cfset val = extra[key]>

				<!--- Difference: a boolean is the text "true" or "false", and a null is an empty string --->
				<cfif IsSimpleValue(val) AND ListFindNoCase("true,false,null", val) GT 0>
					<cfif Compare(val, "null") EQ 0>
						<cfset val = "">
					<cfelseif Compare(LCase(val), "true") EQ 0>
						<cfset val = "true">
					<cfelse>
						<!--- also "NULL" and "Null", as in the original --->
						<cfset val = "false">
					</cfif>
				</cfif>

				<cfset dsnParams[key] = val>
			</cfloop>
		</cfif>

		<cfreturn array_merge(arguments.params, dsnParams)>
	</cffunction>

	<!---
	 * Creates a database object.
	 *
	 * @param driver   Driver name. FQCN can be used.
	 * @param class    'Connection'|'Forge'|'Utils'
	 * @param argument The constructor parameter or DB connection
	 *
	 * @return BaseConnection|BaseUtils|Forge
	--->
	<cffunction name="initDriver" access="private" returntype="any" output="no">
		<cfargument name="driver" type="string" required="yes">
		<cfargument name="class" type="string" required="yes">
		<cfargument name="argument" type="any" required="yes">
		<cfset var classname = "">

		<cfif Find("\", arguments.driver) GT 0>
			<cfset classname = arguments.driver & "\" & arguments.class>
		<cfelse>
			<cfset classname = "ColdIgniter\Database\" & arguments.driver & "\" & arguments.class>
		</cfif>

		<cfreturn new_(classname, arguments.argument)>
	</cffunction>

	<!---
	 * Check the name of the database driver.
	 *
	 * Difference: the original checks that the extension of the
	 * driver is loaded. There is none here, so only the name is checked.
	 *
	 * @param driver DB driver or FQCN for custom driver
	 *
	 * @throws ConfigException if the driver is invalid
	--->
	<cffunction name="checkDbExtension" access="private" returntype="void" output="no">
		<cfargument name="driver" type="string" required="yes">

		<cfif Find("\", arguments.driver) GT 0>
			<!--- Cannot check a fully qualified classname for a custom driver. --->
			<cfreturn>
		</cfif>

		<!--- the names of the drivers: MySQLi, SQLite3, Postgre, SQLSRV, OCI8 --->
		<cfif NOT ListFind("MySQLi,SQLite3,Postgre,SQLSRV,OCI8", arguments.driver)>
			<cfthrow type="ColdIgniter.Config.Exceptions.ConfigException" message="Invalid DBDriver name: ""#arguments.driver#"".">
		</cfif>
	</cffunction>

</cfcomponent>
