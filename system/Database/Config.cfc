<!---
 * Difference: the static properties and methods of the original are
 * properties and methods of the one object that static_() gives (see
 * static_("ColdIgniter\Database\Config").connect()). That object is
 * created without __construct(), so the environment is not read into it,
 * and it has no use for the properties of BaseConfig.
 *
 * Difference: the group is an empty string where the original has null, a
 * map of settings is made with array_(), and md5() takes the place of the
 * md5() of the original over the json_encode() of the settings.
 *
 * Not ported yet: utils() (BaseUtils).
--->
<cfcomponent output="no" parent="ColdIgniter\Config\BaseConfig" hint="Database configuration and connection manager">

	<!---
	 * Cache for instance of any connections that
	 * have been requested as a "shared" instance.
	 *
	 * @var array<string, BaseConnection>
	--->
	<cfset this.instances = CreateObject("java", "java.util.LinkedHashMap").init()>

	<!---
	 * The main instance used to manage all of
	 * our open database connections.
	 *
	 * An empty string until ensureFactory() creates it.
	 *
	 * @var Database|null
	--->
	<cfset this.factory = "">

	<!---
	 * Returns the database connection
	 *
	 * @param group     The name of the connection group to use, or a map of
	 *                  configuration settings, or a BaseConnection. An empty
	 *                  string is the default group.
	 * @param getShared Whether to return a shared instance of the connection.
	 *
	 * @return BaseConnection
	--->
	<cffunction name="connect" access="public" returntype="any" output="no">
		<cfargument name="group" type="any" required="no" default="">
		<cfargument name="getShared" type="boolean" required="no" default="true">
		<cfset var group_ = arguments.group>
		<cfset var dbConfig = "">
		<cfset var connectConfig = "">
		<cfset var connection = "">

		<!--- If a DB connection is passed in, just pass it back --->
		<cfif IsObject(group_) AND instanceof_(group_, "ColdIgniter\Database\BaseConnection")>
			<cfreturn group_>
		</cfif>

		<cfif is_array(group_)>
			<cfset connectConfig = group_>
			<cfset group_ = "custom-" & md5(json_encode(connectConfig))>
		<cfelse>
			<cfset dbConfig = variables.config("Config\Database")>

			<cfif Compare(group_, "") EQ 0>
				<cfif Compare(request.ENVIRONMENT, "testing") EQ 0>
					<cfset group_ = "tests">
				<cfelse>
					<cfset group_ = dbConfig.defaultGroup>
				</cfif>
			</cfif>

			<cfif NOT StructKeyExists(dbConfig, group_) OR IsCustomFunction(dbConfig[group_])>
				<cfthrow type="ColdIgniter.Exceptions.InvalidArgumentException" message="""#group_#"" is not a valid database connection group.">
			</cfif>

			<cfset connectConfig = dbConfig[group_]>
		</cfif>

		<cfif arguments.getShared AND array_key_exists(group_, this.instances)>
			<cfreturn this.instances[group_]>
		</cfif>

		<cfset ensureFactory()>

		<cfset connection = this.factory.load(connectConfig, group_)>

		<cfif arguments.getShared>
			<cfset this.instances[group_] = connection>
		</cfif>

		<cfreturn connection>
	</cffunction>

	<!---
	 * Returns an array of all db connections currently made.
	 *
	 * @return A map of group name to BaseConnection, see array_()
	--->
	<cffunction name="getConnections" access="public" returntype="any" output="no">
		<cfreturn this.instances>
	</cffunction>

	<!---
	 * Loads and returns an instance of the Forge for the specified
	 * database group, and loads the group if it hasn't been loaded yet.
	--->
	<cffunction name="forge" access="public" returntype="any" output="no">
		<cfargument name="group" type="any" required="no" default="">
		<cfset var db = this.connect(arguments.group)>

		<cfreturn this.factory.loadForge(db)>
	</cffunction>

	<!---
	 * Returns a new instance of the Database Utilities class.
	 *
	 * Not ported yet: BaseUtils.
	--->
	<cffunction name="utils" access="public" returntype="any" output="no">
		<cfargument name="group" type="any" required="no" default="">

		<cfthrow type="ColdIgniter.LogicException" message="Not ported yet: BaseUtils.">
	</cffunction>

	<!---
	 * Returns a new instance of the Database Seeder.
	--->
	<cffunction name="seeder" access="public" returntype="any" output="no">
		<cfargument name="group" type="string" required="no" default="">

		<cfreturn new_("ColdIgniter\Database\Seeder", variables.config("Config\Database"), this.connect(arguments.group))>
	</cffunction>

	<!---
	 * Ensures the database Connection Manager/Factory is loaded and ready to use.
	--->
	<cffunction name="ensureFactory" access="private" returntype="void" output="no">
		<cfif IsObject(this.factory)>
			<cfreturn>
		</cfif>

		<cfset this.factory = new_("ColdIgniter\Database\Database")>
	</cffunction>

	<!---
	 * Reconnect database connections for worker mode at the start of a request.
	 *
	 * This should be called at the beginning of each request in worker mode,
	 * before the application runs.
	--->
	<cffunction name="reconnectForWorkerMode" access="public" returntype="void" output="no">
		<cfset var groups = array_keys(this.instances)>
		<cfset var group = "">
		<cfset var i = 0>

		<cfloop from="1" to="#ArrayLen(groups)#" index="i">
			<cfset group = groups[i]>
			<cfset this.instances[group].reconnect()>
		</cfloop>
	</cffunction>

	<!---
	 * Cleanup database connections for worker mode.
	 *
	 * Rolls back any uncommitted transactions and resets transaction status
	 * to ensure a clean state for the next request.
	 *
	 * Uncommitted transactions at this point indicate a bug in the
	 * application code (transactions should be completed before request ends).
	 *
	 * Called at the END of each request to clean up state.
	--->
	<cffunction name="cleanupForWorkerMode" access="public" returntype="void" output="no">
		<cfset var groups = array_keys(this.instances)>
		<cfset var group = "">
		<cfset var i = 0>
		<cfset var connection = "">

		<cfloop from="1" to="#ArrayLen(groups)#" index="i">
			<cfset group = groups[i]>
			<cfset connection = this.instances[group]>

			<cfif connection.transDepth GT 0>
				<cfset log_message("error", "Uncommitted transaction detected in database group '#group#'. Transactions must be completed before request ends.")>

				<cfloop condition="connection.transDepth GT 0">
					<cfset connection.transRollback()>
				</cfloop>
			</cfif>

			<cfset connection.resetTransStatus()>
		</cfloop>
	</cffunction>

</cfcomponent>
