<!---
 * Expected behavior of a database connection.
 *
 * There are no interfaces on 6.1, so this is a base component. BaseConnection
 * extends it, and the methods here only throw; a class that extends it
 * has to define them.
--->
<cfcomponent output="no" hint="Expected behavior of a database connection">

	<!---
	 * Initializes the database connection/settings.
	 *
	 * Difference: named initialize_ because initialize is a built-in function.
	--->
	<cffunction name="initialize_" access="public" returntype="void" output="no">

		<cfthrow type="ColdIgniter.LogicException" message="The class does not define initialize_().">
	</cffunction>

	<!---
	 * Connect to the database.
	--->
	<cffunction name="connect" access="public" returntype="any" output="no">
		<cfargument name="persistent" type="boolean" required="no" default="false">

		<cfthrow type="ColdIgniter.LogicException" message="The class does not define connect().">
	</cffunction>

	<!---
	 * Create a persistent database connection.
	--->
	<cffunction name="persistentConnect" access="public" returntype="any" output="no">

		<cfthrow type="ColdIgniter.LogicException" message="The class does not define persistentConnect().">
	</cffunction>

	<!---
	 * Keep or establish the connection if no queries have been sent for
	 * a length of time exceeding the server's idle timeout.
	--->
	<cffunction name="reconnect" access="public" returntype="void" output="no">

		<cfthrow type="ColdIgniter.LogicException" message="The class does not define reconnect().">
	</cffunction>

	<!---
	 * Returns the actual connection object. If both a 'read' and 'write'
	 * connection has been specified, you can pass either term in to
	 * get that connection. If you pass either alias in and only a single
	 * connection is present, it must return the sole connection.
	--->
	<cffunction name="getConnection" access="public" returntype="any" output="no">
		<cfargument name="alias" type="string" required="no" default="">

		<cfthrow type="ColdIgniter.LogicException" message="The class does not define getConnection().">
	</cffunction>

	<!---
	 * Select a specific database table to use.
	--->
	<cffunction name="setDatabase" access="public" returntype="any" output="no">
		<cfargument name="databaseName" type="string" required="yes">

		<cfthrow type="ColdIgniter.LogicException" message="The class does not define setDatabase().">
	</cffunction>

	<!---
	 * Returns the name of the current database being used.
	--->
	<cffunction name="getDatabase" access="public" returntype="string" output="no">

		<cfthrow type="ColdIgniter.LogicException" message="The class does not define getDatabase().">
	</cffunction>

	<!---
	 * Returns the last error encountered by this connection.
	 * Must return a map with the keys code and message.
	 * intval(code) === 0 means "no error".
	--->
	<cffunction name="error" access="public" returntype="any" output="no">

		<cfthrow type="ColdIgniter.LogicException" message="The class does not define error().">
	</cffunction>

	<!---
	 * The name of the platform in use (MySQLi, mssql, etc)
	--->
	<cffunction name="getPlatform" access="public" returntype="string" output="no">

		<cfthrow type="ColdIgniter.LogicException" message="The class does not define getPlatform().">
	</cffunction>

	<!---
	 * Returns a string containing the version of the database being used.
	--->
	<cffunction name="getVersion" access="public" returntype="string" output="no">

		<cfthrow type="ColdIgniter.LogicException" message="The class does not define getVersion().">
	</cffunction>

	<!---
	 * Orchestrates a query against the database. Queries must use
	 * Database\Statement objects to store the query and build it.
	 * This method works with the cache.
	 *
	 * Should automatically handle different connections for read/write
	 * queries if needed.
	--->
	<cffunction name="query" access="public" returntype="any" output="no">
		<cfargument name="sql" type="string" required="yes">
		<cfargument name="binds" type="any" required="no" default="">

		<cfthrow type="ColdIgniter.LogicException" message="The class does not define query().">
	</cffunction>

	<!---
	 * Performs a basic query against the database. No binding or caching
	 * is performed, nor are transactions handled. Simply takes a raw
	 * query string and returns the database-specific result id.
	--->
	<cffunction name="simpleQuery" access="public" returntype="any" output="no">
		<cfargument name="sql" type="string" required="yes">

		<cfthrow type="ColdIgniter.LogicException" message="The class does not define simpleQuery().">
	</cffunction>

	<!---
	 * Returns an instance of the query builder for this connection.
	--->
	<cffunction name="table" access="public" returntype="any" output="no">
		<cfargument name="tableName" type="any" required="yes">

		<cfthrow type="ColdIgniter.LogicException" message="The class does not define table().">
	</cffunction>

	<!---
	 * Returns the last query's statement object.
	--->
	<cffunction name="getLastQuery" access="public" returntype="any" output="no">

		<cfthrow type="ColdIgniter.LogicException" message="The class does not define getLastQuery().">
	</cffunction>

	<!---
	 * "Smart" Escaping
	 *
	 * Escapes data based on type.
	 * Sets boolean and null types.
	--->
	<cffunction name="escape" access="public" returntype="any" output="no">
		<cfargument name="str" type="any" required="yes">

		<cfthrow type="ColdIgniter.LogicException" message="The class does not define escape().">
	</cffunction>

	<!---
	 * Allows for custom calls to the database engine that are not
	 * supported through our database layer.
	 *
	 * Difference: the variadic params are collected from the arguments after the first.
	--->
	<cffunction name="callFunction" access="public" returntype="any" output="no">
		<cfargument name="functionName" type="string" required="yes">
		<cfargument name="params_" type="any" required="no" default="">

		<cfthrow type="ColdIgniter.LogicException" message="The class does not define callFunction().">
	</cffunction>

	<!---
	 * Determines if the statement is a write-type query or not.
	--->
	<cffunction name="isWriteType" access="public" returntype="boolean" output="no">
		<cfargument name="sql" type="string" required="yes">

		<cfthrow type="ColdIgniter.LogicException" message="The class does not define isWriteType().">
	</cffunction>

</cfcomponent>
