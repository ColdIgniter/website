<!---
 * Base class for the connections.
 *
 * Difference: there is no abstract class, so the abstract methods are
 * methods that throw "The class does not define X()." and the driver
 * connection that extends this component has to define them. The driver is
 * not a database extension but a data source name that cfquery uses, and
 * the original DSN property keeps that name.
 *
 * Difference: the values of a connection are text, as a null is an empty
 * string and false is the text "false". A driver returns the text "false"
 * from connect() and execute() when they fail, and connID and resultID are
 * "false" before a connection exists. hasConnID() tells if there is one.
 *
 * Difference: the properties that have the name of a public method have a
 * trailing underscore (protectIdentifiers_, pretend_, transStrict_,
 * transStatus_ and transException_), and so do the arguments with the name
 * of a method. The configuration keys are mapped to them by setProperties().
 *
 * Difference: the types of the properties are not checked, so
 * castScalarValueForTypedProperty(), getBuiltinPropertyTypesMap() and
 * propertyBuiltinTypesCache are not ported.
 *
 * Difference: the rows of a result are maps (see array_()) where the
 * original has objects or arrays.
 *
 * __get() and __isset() are not ported, as every property can be read
 * from the component.
 *
 * Difference: table() and newQuery() find the builder class with
 * str_replace("Connection", "Builder", this.__class) and class_exists(),
 * and use ColdIgniter\Database\BaseBuilder when there is none.
 *
 * Not ported yet: the prepared queries (BasePreparedQuery, so prepare()).
 *
 * @template TConnection
 * @template TResult
--->
<cfcomponent output="no" extends="ConnectionInterface" hint="Base class for the connections">

	<!---
	 * Data Source Name / Connect string
	 *
	 * @var string
	--->
	<cfset this.DSN = "">

	<!---
	 * Database port
	 *
	 * @var int|string
	--->
	<cfset this.port = "">

	<!---
	 * Hostname
	 *
	 * @var string
	--->
	<cfset this.hostname = "">

	<!---
	 * Username
	 *
	 * @var string
	--->
	<cfset this.username = "">

	<!---
	 * Password
	 *
	 * @var string
	--->
	<cfset this.password = "">

	<!---
	 * Database name
	 *
	 * @var string
	--->
	<cfset this.database = "">

	<!---
	 * Database driver
	 *
	 * @var string
	--->
	<cfset this.DBDriver = "MySQLi">

	<!---
	 * Sub-driver
	 *
	 * @var string
	--->
	<cfset this.subdriver = "">

	<!---
	 * Table prefix
	 *
	 * @var string
	--->
	<cfset this.DBPrefix = "">

	<!---
	 * Persistent connection flag
	 *
	 * @var bool
	--->
	<cfset this.pConnect = "false">

	<!---
	 * Whether to throw Exception or not when an error occurs.
	 *
	 * @var bool
	--->
	<cfset this.DBDebug = "true">

	<!---
	 * Character set
	 *
	 * This value must be updated by Config\Database if the driver use it.
	 *
	 * @var string
	--->
	<cfset this.charset = "">

	<!---
	 * Collation
	 *
	 * This value must be updated by Config\Database if the driver use it.
	 *
	 * @var string
	--->
	<cfset this.DBCollat = "">

	<!---
	 * Swap Prefix
	 *
	 * @var string
	--->
	<cfset this.swapPre = "">

	<!---
	 * Encryption flag/data
	 *
	 * @var array<string, bool|string>|bool
	--->
	<cfset this.encrypt = "false">

	<!---
	 * Compression flag
	 *
	 * @var bool
	--->
	<cfset this.compress = "false">

	<!---
	 * Strict ON flag
	 *
	 * Whether we're running in strict SQL mode.
	 *
	 * @var bool|null
	 *
	 * @deprecated 4.5.0 Will move to MySQLi\Connection.
	--->
	<cfset this.strictOn = "">

	<!---
	 * Settings for a failover connection.
	 *
	 * @var list<array<string, mixed>>
	--->
	<cfset this.failover = ArrayNew(1)>

	<!---
	 * The last query object that was executed
	 * on this connection.
	 *
	 * @var Query
	--->
	<cfset this.lastQuery = "">

	<!---
	 * Connection ID
	 *
	 * @var false|TConnection
	--->
	<cfset this.connID = "false">

	<!---
	 * Result ID
	 *
	 * @var false|TResult
	--->
	<cfset this.resultID = "false">

	<!---
	 * Protect identifiers flag
	 *
	 * @var bool
	--->
	<cfset this.protectIdentifiers_ = "true">

	<!---
	 * List of reserved identifiers
	 *
	 * Identifiers that must NOT be escaped.
	 *
	 * @var list<string>
	--->
	<cfset this.reservedIdentifiers = ArrayNew(1)>
	<cfset ArrayAppend(this.reservedIdentifiers, "*")>

	<!---
	 * Identifier escape character
	 *
	 * @var list<string>|string
	--->
	<cfset this.escapeChar = """">

	<!---
	 * ESCAPE statement string
	 *
	 * @var string
	--->
	<cfset this.likeEscapeStr = " ESCAPE '%s' ">

	<!---
	 * ESCAPE character
	 *
	 * @var string
	--->
	<cfset this.likeEscapeChar = "!">

	<!---
	 * RegExp used to escape identifiers
	 *
	 * @var list<string>
	--->
	<cfset this.pregEscapeChar = ArrayNew(1)>

	<!---
	 * @var array<string, mixed>
	--->
	<cfset this.dataCache = CreateObject("java", "java.util.LinkedHashMap").init()>

	<!---
	 * Microtime when connection was made
	 *
	 * @var float
	--->
	<cfset this.connectTime = 0>

	<!---
	 * How long it took to establish connection.
	 *
	 * @var float
	--->
	<cfset this.connectDuration = 0>

	<!---
	 * If true, no queries will actually be
	 * run against the database.
	 *
	 * @var bool
	--->
	<cfset this.pretend_ = "false">

	<!---
	 * Transaction enabled flag
	 *
	 * @var bool
	--->
	<cfset this.transEnabled = "true">

	<!---
	 * Strict transaction mode flag
	 *
	 * @var bool
	--->
	<cfset this.transStrict_ = "true">

	<!---
	 * Transaction depth level
	 *
	 * @var int
	--->
	<cfset this.transDepth = 0>

	<!---
	 * Transaction status flag
	 *
	 * Used with transactions to determine if a rollback should occur.
	 *
	 * @var bool
	--->
	<cfset this.transStatus_ = "true">

	<!---
	 * Transaction failure flag
	 *
	 * Used with transactions to determine if a transaction has failed.
	 *
	 * @var bool
	--->
	<cfset this.transFailure = "false">

	<!---
	 * Whether to throw exceptions during transaction
	--->
	<cfset this.transException_ = "false">

	<!---
	 * Array of table aliases.
	 *
	 * @var list<string>
	--->
	<cfset this.aliasedTables = ArrayNew(1)>

	<!---
	 * Not in the original: the results of protectIdentifiers() for text
	 * items. A java.util.HashMap, made at the first call, as its keys keep
	 * their case.
	--->
	<cfset this.protectCache_ = "">

	<!---
	 * Not in the original: the java.util.regex patterns of isWriteType(),
	 * made at the first call. A pattern does not change and can be used
	 * again for every statement.
	--->
	<cfset this.writeTypePatterns_ = "">

	<!---
	 * Query Class
	 *
	 * @var string
	--->
	<cfset this.queryClass = "ColdIgniter\Database\Query">

	<!---
	 * Default Date/Time formats
	 *
	 * @var array<string, string>
	--->
	<cfset this.dateFormat = CreateObject("java", "java.util.LinkedHashMap").init()>
	<cfset this.dateFormat["date"] = "Y-m-d">
	<cfset this.dateFormat["datetime"] = "Y-m-d H:i:s">
	<cfset this.dateFormat["datetime-ms"] = "Y-m-d H:i:s.v">
	<cfset this.dateFormat["datetime-us"] = "Y-m-d H:i:s.u">
	<cfset this.dateFormat["time"] = "H:i:s">

	<!---
	 * @param array<string, mixed> $params
	 *
	 * Difference: dateFormat is merged by a loop, then the other keys are
	 * set by setProperties().
	--->
	<cffunction name="__construct" access="public" returntype="any" output="no">
		<cfargument name="params" type="any" required="yes">
		<cfset var merged = array_()>
		<cfset var keys = "">
		<cfset var i = 0>
		<cfset var queryClass_ = "">

		<cfif StructKeyExists(arguments.params, "dateFormat")>
			<cfset keys = array_keys(this.dateFormat)>
			<cfloop from="1" to="#ArrayLen(keys)#" index="i">
				<cfset merged[keys[i]] = this.dateFormat[keys[i]]>
			</cfloop>

			<cfset keys = array_keys(arguments.params["dateFormat"])>
			<cfloop from="1" to="#ArrayLen(keys)#" index="i">
				<cfset merged[keys[i]] = arguments.params["dateFormat"][keys[i]]>
			</cfloop>
		</cfif>

		<cfset setProperties(arguments.params)>

		<cfif StructKeyExists(arguments.params, "dateFormat")>
			<cfset this.dateFormat = merged>
		</cfif>

		<cfset queryClass_ = str_replace("Connection", "Query", this.__class)>

		<cfif class_exists(queryClass_)>
			<cfset this.queryClass = queryClass_>
		</cfif>

		<cfif ArrayLen(this.failover) GT 0>
			<!---
			 * If there is a failover database, connect now to do failover.
			 * Otherwise, Query Builder creates SQL statement with the main database config
			 * (DBPrefix) even when the main database is down.
			--->
			<cfset this.initialize_()>
		</cfif>

		<cfreturn this>
	</cffunction>

	<!---
	 * Sets the properties that exist from a map of settings.
	 *
	 * Not in the original: it stands in for the loops with property_exists()
	 * of the constructor and of initialize(). A key whose name has a trailing
	 * underscore property (protectIdentifiers_) sets that one, and a key that
	 * is the name of a method is ignored.
	 *
	 * @param array<string, mixed> $params
	--->
	<cffunction name="setProperties" access="private" returntype="void" output="no">
		<cfargument name="params" type="any" required="yes">
		<cfset var keys = array_keys(arguments.params)>
		<cfset var i = 0>
		<cfset var key = "">

		<cfloop from="1" to="#ArrayLen(keys)#" index="i">
			<cfset key = keys[i]>

			<cfif StructKeyExists(this, key & "_") AND NOT IsCustomFunction(this[key & "_"])>
				<cfset this[key & "_"] = arguments.params[key]>
			<cfelseif StructKeyExists(this, key)>
				<cfif NOT IsCustomFunction(this[key])>
					<cfset this[key] = arguments.params[key]>
				</cfif>
			</cfif>
		</cfloop>
	</cffunction>

	<!---
	 * Tells if there is a connection: the original checks if connID is
	 * not false.
	 *
	 * Not in the original.
	--->
	<cffunction name="hasConnID" access="private" returntype="boolean" output="no">

		<cfreturn NOT identical_(this.connID, "false")>
	</cffunction>

	<!---
	 * Initializes the database connection/settings.
	 *
	 * @return void
	 *
	 * @throws DatabaseException
	 *
	 * Difference: the failover settings are set by setProperties(), and the
	 * errors of a connection are the messages of the exceptions, as the
	 * stack trace of the original is not given.
	--->
	<cffunction name="initialize_" access="public" returntype="void" output="no">
		<cfset var connectionErrors = ArrayNew(1)>
		<cfset var i = 0>

		<!---
		 * If an established connection is available, then there's
		 * no need to connect and select the database.
		 *
		 * Depending on the database driver, connID can be either
		 * boolean TRUE, a resource or an object.
		--->
		<cfif hasConnID()>
			<cfreturn>
		</cfif>

		<cfset this.connectTime = microtime(true)>

		<cftry>
			<!--- Connect to the database and set the connection ID --->
			<cfset this.connID = this.connect(this.pConnect)>

			<cfcatch type="any">
				<cfset this.connID = "false">
				<cfset ArrayAppend(connectionErrors, "Main connection [" & this.DBDriver & "]: " & cfcatch.message)>
				<cfset log_message("error", "Error connecting to the database: " & cfcatch.message)>
			</cfcatch>
		</cftry>

		<!--- No connection resource? Check if there is a failover else throw an error --->
		<cfif NOT hasConnID()>
			<!--- Check if there is a failover set --->
			<cfif ArrayLen(this.failover) GT 0>
				<!--- Go over all the failovers --->
				<cfloop from="1" to="#ArrayLen(this.failover)#" index="i">
					<!--- Replace the current settings with those of the failover --->
					<cfset setProperties(this.failover[i])>

					<cftry>
						<!--- Try to connect --->
						<cfset this.connID = this.connect(this.pConnect)>

						<cfcatch type="any">
							<cfset ArrayAppend(connectionErrors, "Failover ##" & i & " [" & this.DBDriver & "]: " & cfcatch.message)>
							<cfset log_message("error", "Error connecting to the database: " & cfcatch.message)>
						</cfcatch>
					</cftry>

					<!--- If a connection is made break the loop --->
					<cfif hasConnID()>
						<cfbreak>
					</cfif>
				</cfloop>
			</cfif>

			<!--- We still don't have a connection? --->
			<cfif NOT hasConnID()>
				<cfthrow type="ColdIgniter.Database.Exceptions.DatabaseException" message="Unable to connect to the database.#Chr(10)##implode(Chr(10), connectionErrors)#">
			</cfif>
		</cfif>

		<cfset this.connectDuration = microtime(true) - this.connectTime>
	</cffunction>

	<!---
	 * Close the database connection.
	 *
	 * @return void
	--->
	<cffunction name="close" access="public" returntype="void" output="no">

		<cfif hasConnID()>
			<cfset _close()>
			<cfset this.connID = "false">
		</cfif>
	</cffunction>

	<!---
	 * Keep or establish the connection if no queries have been sent for
	 * a length of time exceeding the server's idle timeout.
	 *
	 * A replaced socket is not in the transaction that was open on the old
	 * one. The server has already rolled that work back. Clear the depth and
	 * mark the transaction failed before opening the new connection, so a
	 * failed reconnect cannot still report success.
	 *
	 * @return void
	--->
	<cffunction name="reconnect" access="public" returntype="void" output="no">
		<cfset var lostTransaction = "false">

		<cfif NOT this.ping()>
			<cfif this.transDepth GT 0>
				<cfset lostTransaction = "true">
			</cfif>

			<cfset this.close()>

			<cfif lostTransaction>
				<cfset abandonLostTransaction()>
			</cfif>

			<cfset this.initialize_()>
		</cfif>
	</cffunction>

	<!---
	 * The socket that owned the transaction is already closed.
	 *
	 * Drivers that keep transaction state here, rather than only on the
	 * server, must override this.
	--->
	<cffunction name="abandonLostTransaction" access="private" returntype="void" output="no">

		<cfset this.transDepth = 0>
		<cfset this.transStatus_ = "false">
	</cffunction>

	<!---
	 * Platform dependent way method for closing the connection.
	 *
	 * @return void
	--->
	<cffunction name="_close" access="private" returntype="void" output="no">

		<cfthrow type="ColdIgniter.LogicException" message="The class does not define _close().">
	</cffunction>

	<!---
	 * Check if the connection is still alive.
	--->
	<cffunction name="ping" access="public" returntype="boolean" output="no">

		<cfif NOT hasConnID()>
			<cfreturn false>
		</cfif>

		<cfreturn _ping()>
	</cffunction>

	<!---
	 * Driver-specific ping implementation.
	--->
	<cffunction name="_ping" access="private" returntype="boolean" output="no">
		<cfset var result = "">

		<cftry>
			<cfset result = this.simpleQuery("SELECT 1")>

			<cfreturn NOT identical_(result, "false")>

			<cfcatch type="ColdIgniter.Database.Exceptions.DatabaseException">
				<cfreturn false>
			</cfcatch>
		</cftry>
	</cffunction>

	<!---
	 * Create a persistent database connection.
	 *
	 * @return false|TConnection
	--->
	<cffunction name="persistentConnect" access="public" returntype="any" output="no">

		<cfreturn this.connect(true)>
	</cffunction>

	<!---
	 * Returns the actual connection object. If both a 'read' and 'write'
	 * connection has been specified, you can pass either term in to
	 * get that connection. If you pass either alias in and only a single
	 * connection is present, it must return the sole connection.
	 *
	 * @return false|TConnection
	--->
	<cffunction name="getConnection" access="public" returntype="any" output="no">
		<cfargument name="alias" type="string" required="no" default="">

		<!--- @todo work with read/write connections --->
		<cfreturn this.connID>
	</cffunction>

	<!---
	 * Returns the name of the current database being used.
	--->
	<cffunction name="getDatabase" access="public" returntype="string" output="no">

		<cfif IsSimpleValue(this.database)>
			<cfreturn this.database>
		</cfif>

		<cfreturn "">
	</cffunction>

	<!---
	 * Set DB Prefix
	 *
	 * Set's the DB Prefix to something new without needing to reconnect
	 *
	 * @param string $prefix The prefix
	--->
	<cffunction name="setPrefix" access="public" returntype="string" output="no">
		<cfargument name="prefix" type="string" required="no" default="">

		<cfset this.DBPrefix = arguments.prefix>

		<cfreturn this.DBPrefix>
	</cffunction>

	<!---
	 * Returns the database prefix.
	--->
	<cffunction name="getPrefix" access="public" returntype="string" output="no">

		<cfreturn this.DBPrefix>
	</cffunction>

	<!---
	 * The name of the platform in use (MySQLi, Postgre, SQLite3, OCI8, etc)
	--->
	<cffunction name="getPlatform" access="public" returntype="string" output="no">

		<cfreturn this.DBDriver>
	</cffunction>

	<!---
	 * Sets the Table Aliases to use. These are typically
	 * collected during use of the Builder, and set here
	 * so queries are built correctly.
	 *
	 * @param list<string> $aliases
	 *
	 * @return $this
	--->
	<cffunction name="setAliasedTables" access="public" returntype="any" output="no">
		<cfargument name="aliases" type="array" required="yes">

		<!--- a copy, as addTableAlias() adds to it --->
		<cfset this.aliasedTables = Duplicate(arguments.aliases)>

		<cfreturn this>
	</cffunction>

	<!---
	 * Add a table alias to our list.
	 *
	 * @return $this
	--->
	<cffunction name="addTableAlias" access="public" returntype="any" output="no">
		<cfargument name="alias" type="string" required="yes">

		<cfif Len(arguments.alias) EQ 0>
			<cfreturn this>
		</cfif>

		<cfif NOT in_array(arguments.alias, this.aliasedTables)>
			<cfset ArrayAppend(this.aliasedTables, arguments.alias)>
		</cfif>

		<cfreturn this>
	</cffunction>

	<!---
	 * Executes the query against the database.
	 *
	 * @return false|TResult
	--->
	<cffunction name="execute" access="private" returntype="any" output="no">
		<cfargument name="sql" type="string" required="yes">

		<cfthrow type="ColdIgniter.LogicException" message="The class does not define execute().">
	</cffunction>

	<!---
	 * Orchestrates a query against the database. Queries must use
	 * Database\Statement objects to store the query and build it.
	 * This method works with the cache.
	 *
	 * Should automatically handle different connections for read/write
	 * queries if needed.
	 *
	 * @param array<array-key, mixed>|string|null $binds
	 *
	 * @return BaseResult<TConnection, TResult>|bool|Query
	 *
	 * @todo BC set $queryClass default as null in 4.1
	 *
	 * Difference: a write-type query gives the text "true", and a failure
	 * gives the text "false". The exception that is thrown for a failure
	 * has the message and the code of the exception of the driver, but not
	 * the exception itself as its previous one.
	--->
	<cffunction name="query" access="public" returntype="any" output="no">
		<cfargument name="sql" type="string" required="yes">
		<cfargument name="binds" type="any" required="no" default="">
		<cfargument name="setEscapeFlags" type="boolean" required="no" default="true">
		<cfargument name="queryClass" type="string" required="no" default="">
		<cfset var queryClass_ = this.queryClass>
		<cfset var query_ = "">
		<cfset var startTime = 0>
		<cfset var exceptionCaught = "false">
		<cfset var exceptionMessage = "">
		<cfset var exceptionCode = "">
		<cfset var transDepth_ = 0>
		<cfset var resultClass = "">

		<cfif Len(arguments.queryClass) GT 0 AND Compare(arguments.queryClass, "0") NEQ 0>
			<cfset queryClass_ = arguments.queryClass>
		</cfif>

		<cfif NOT hasConnID()>
			<cfset this.initialize_()>
		</cfif>

		<cfset query_ = new_(queryClass_, this)>
		<cfset query_.setQuery(arguments.sql, arguments.binds, arguments.setEscapeFlags)>

		<cfif Len(this.swapPre) GT 0 AND Len(this.DBPrefix) GT 0>
			<cfset query_.swapPrefix(this.DBPrefix, this.swapPre)>
		</cfif>

		<cfset startTime = microtime(true)>

		<!---
		 * Always save the last query so we can use
		 * the getLastQuery() method.
		--->
		<cfset this.lastQuery = query_>

		<!---
		 * If $pretend is true, then we just want to return
		 * the actual query object here. There won't be
		 * any results to return.
		--->
		<cfif this.pretend_>
			<cfset query_.setDuration(startTime)>

			<cfreturn query_>
		</cfif>

		<!--- Run the query for real --->
		<cftry>
			<cfset this.resultID = this.simpleQuery(query_.getQuery())>

			<cfcatch type="ColdIgniter.Database.Exceptions.DatabaseException">
				<cfset exceptionCaught = "true">
				<cfset exceptionMessage = cfcatch.message>
				<cfset exceptionCode = cfcatch.errorCode>
				<cfset this.resultID = "false">
			</cfcatch>
		</cftry>

		<cfif identical_(this.resultID, "false")>
			<cfset query_.setDuration(startTime, startTime)>

			<!--- This will trigger a rollback if transactions are being used --->
			<cfset this.handleTransStatus()>

			<cfif this.DBDebug AND (this.transDepth EQ 0 OR this.transException_)>
				<!---
				 * We call this function in order to roll-back queries
				 * if transactions are enabled. If we don't call this here
				 * the error message will trigger an exit, causing the
				 * transactions to remain in limbo.
				--->
				<cfloop condition="this.transDepth NEQ 0">
					<cfset transDepth_ = this.transDepth>
					<cfset this.transComplete()>

					<cfif transDepth_ EQ this.transDepth>
						<cfset log_message("error", "Database: Failure during an automated transaction commit/rollback!")>
						<cfbreak>
					</cfif>
				</cfloop>

				<!--- Let others do something with this query. --->
				<cfset static_("ColdIgniter\Events\Events").trigger("DBQuery", query_)>

				<cfif exceptionCaught>
					<cfthrow type="ColdIgniter.Database.Exceptions.DatabaseException" errorcode="#exceptionCode#" message="#exceptionMessage#">
				</cfif>

				<cfreturn "false">
			</cfif>

			<!--- Let others do something with this query. --->
			<cfset static_("ColdIgniter\Events\Events").trigger("DBQuery", query_)>

			<cfreturn "false">
		</cfif>

		<cfset query_.setDuration(startTime)>

		<!--- Let others do something with this query --->
		<cfset static_("ColdIgniter\Events\Events").trigger("DBQuery", query_)>

		<!--- resultID is not false, so it must be successful --->
		<cfif this.isWriteType(arguments.sql)>
			<cfreturn "true">
		</cfif>

		<!--- query is not write-type, so it must be read-type query; return QueryResult --->
		<cfset resultClass = str_replace("Connection", "Result", this.__class)>

		<cfreturn new_(resultClass, this.connID, this.resultID)>
	</cffunction>

	<!---
	 * Performs a basic query against the database. No binding or caching
	 * is performed, nor are transactions handled. Simply takes a raw
	 * query string and returns the database-specific result id.
	 *
	 * @return false|TResult
	--->
	<cffunction name="simpleQuery" access="public" returntype="any" output="no">
		<cfargument name="sql" type="string" required="yes">

		<cfif NOT hasConnID()>
			<cfset this.initialize_()>
		</cfif>

		<cfreturn execute(arguments.sql)>
	</cffunction>

	<!---
	 * Disable Transactions
	 *
	 * This permits transactions to be disabled at run-time.
	 *
	 * @return void
	--->
	<cffunction name="transOff" access="public" returntype="void" output="no">

		<cfset this.transEnabled = "false">
	</cffunction>

	<!---
	 * Enable/disable Transaction Strict Mode
	 *
	 * When strict mode is enabled, if you are running multiple groups of
	 * transactions, if one group fails all subsequent groups will be
	 * rolled back.
	 *
	 * If strict mode is disabled, each group is treated autonomously,
	 * meaning a failure of one group will not affect any others
	 *
	 * @param bool $mode = true
	 *
	 * @return $this
	--->
	<cffunction name="transStrict" access="public" returntype="any" output="no">
		<cfargument name="mode" type="boolean" required="no" default="true">

		<cfset this.transStrict_ = arguments.mode>

		<cfreturn this>
	</cffunction>

	<!---
	 * Start Transaction
	--->
	<cffunction name="transStart" access="public" returntype="boolean" output="no">
		<cfargument name="testMode" type="boolean" required="no" default="false">

		<cfif NOT this.transEnabled>
			<cfreturn false>
		</cfif>

		<cfreturn this.transBegin(arguments.testMode)>
	</cffunction>

	<!---
	 * If set to true, exceptions are thrown during transactions.
	 *
	 * @return $this
	--->
	<cffunction name="transException" access="public" returntype="any" output="no">
		<cfargument name="transException_" type="boolean" required="yes">

		<cfset this.transException_ = arguments.transException_>

		<cfreturn this>
	</cffunction>

	<!---
	 * Complete Transaction
	--->
	<cffunction name="transComplete" access="public" returntype="boolean" output="no">

		<cfif NOT this.transEnabled>
			<cfreturn false>
		</cfif>

		<!--- The query() function will set this flag to FALSE in the event that a query failed --->
		<cfif NOT this.transStatus_ OR this.transFailure>
			<cfset this.transRollback()>

			<!---
			 * If we are NOT running in strict mode, we will reset
			 * the _trans_status flag so that subsequent groups of
			 * transactions will be permitted.
			--->
			<cfif NOT this.transStrict_>
				<cfset this.transStatus_ = "true">
			</cfif>

			<cfreturn false>
		</cfif>

		<cfreturn this.transCommit()>
	</cffunction>

	<!---
	 * Lets you retrieve the transaction flag to determine if it has failed
	--->
	<cffunction name="transStatus" access="public" returntype="boolean" output="no">

		<cfreturn this.transStatus_>
	</cffunction>

	<!---
	 * Begin Transaction
	--->
	<cffunction name="transBegin" access="public" returntype="boolean" output="no">
		<cfargument name="testMode" type="boolean" required="no" default="false">

		<cfif NOT this.transEnabled>
			<cfreturn false>
		</cfif>

		<!--- When transactions are nested we only begin/commit/rollback the outermost ones --->
		<cfif this.transDepth GT 0>
			<cfset this.transDepth = this.transDepth + 1>

			<cfreturn true>
		</cfif>

		<cfif NOT hasConnID()>
			<cfset this.initialize_()>
		</cfif>

		<!---
		 * Reset the transaction failure flag.
		 * If the $testMode flag is set to TRUE transactions will be rolled back
		 * even if the queries produce a successful result.
		--->
		<cfset this.transFailure = arguments.testMode>

		<cfif _transBegin()>
			<cfset this.transDepth = this.transDepth + 1>

			<cfreturn true>
		</cfif>

		<cfreturn false>
	</cffunction>

	<!---
	 * Commit Transaction
	--->
	<cffunction name="transCommit" access="public" returntype="boolean" output="no">

		<cfif NOT this.transEnabled OR this.transDepth EQ 0>
			<cfreturn false>
		</cfif>

		<!--- When transactions are nested we only begin/commit/rollback the outermost ones --->
		<cfif this.transDepth GT 1 OR _transCommit()>
			<cfset this.transDepth = this.transDepth - 1>

			<cfreturn true>
		</cfif>

		<cfreturn false>
	</cffunction>

	<!---
	 * Rollback Transaction
	--->
	<cffunction name="transRollback" access="public" returntype="boolean" output="no">

		<cfif NOT this.transEnabled OR this.transDepth EQ 0>
			<cfreturn false>
		</cfif>

		<!--- When transactions are nested we only begin/commit/rollback the outermost ones --->
		<cfif this.transDepth GT 1 OR _transRollback()>
			<cfset this.transDepth = this.transDepth - 1>

			<cfreturn true>
		</cfif>

		<cfreturn false>
	</cffunction>

	<!---
	 * Reset transaction status - to restart transactions after strict mode failure
	--->
	<cffunction name="resetTransStatus" access="public" returntype="any" output="no">

		<cfset this.transStatus_ = "true">

		<cfreturn this>
	</cffunction>

	<!---
	 * Handle transaction status when a query fails
	 *
	 * @internal This method is for internal database component use only
	--->
	<cffunction name="handleTransStatus" access="public" returntype="void" output="no">

		<cfif this.transDepth NEQ 0>
			<cfset this.transStatus_ = "false">
		</cfif>
	</cffunction>

	<!---
	 * Begin Transaction
	--->
	<cffunction name="_transBegin" access="private" returntype="boolean" output="no">

		<cfthrow type="ColdIgniter.LogicException" message="The class does not define _transBegin().">
	</cffunction>

	<!---
	 * Commit Transaction
	--->
	<cffunction name="_transCommit" access="private" returntype="boolean" output="no">

		<cfthrow type="ColdIgniter.LogicException" message="The class does not define _transCommit().">
	</cffunction>

	<!---
	 * Rollback Transaction
	--->
	<cffunction name="_transRollback" access="private" returntype="boolean" output="no">

		<cfthrow type="ColdIgniter.LogicException" message="The class does not define _transRollback().">
	</cffunction>

	<!---
	 * Returns a non-shared new instance of the query builder for this connection.
	 *
	 * @param array<array-key, string>|string|TableName $tableName
	 *
	 * @return BaseBuilder
	 *
	 * @throws DatabaseException
	 *
	 * Difference: the class is found by name, see the header of this file.
	--->
	<cffunction name="table" access="public" returntype="any" output="no">
		<cfargument name="tableName" type="any" required="yes">
		<cfset var blank = "false">

		<cfif IsSimpleValue(arguments.tableName)>
			<cfif Len(arguments.tableName) EQ 0 OR Compare(arguments.tableName, "0") EQ 0>
				<cfset blank = "true">
			</cfif>
		<cfelseif IsArray(arguments.tableName)>
			<cfif ArrayLen(arguments.tableName) EQ 0>
				<cfset blank = "true">
			</cfif>
		</cfif>

		<cfif blank>
			<cfthrow type="ColdIgniter.Database.Exceptions.DatabaseException" message="You must set the database table to be used with your query.">
		</cfif>

		<cfreturn new_(builderClass_(), arguments.tableName, this)>
	</cffunction>

	<!---
	 * Returns a new instance of the BaseBuilder class with a cleared FROM clause.
	 *
	 * Difference: the class is found by name, see the header of this file.
	--->
	<cffunction name="newQuery" access="public" returntype="any" output="no">
		<cfset var aliases = this.aliasedTables>
		<cfset var builder = "">

		<!--- save the aliases, as the FROM of the new builder clears them --->
		<cfset builder = this.table(",").from(ArrayNew(1), "true")>

		<cfset this.aliasedTables = aliases>

		<cfreturn builder>
	</cffunction>

	<!--- the class of the query builder of this connection --->
	<cffunction name="builderClass_" access="private" returntype="string" output="no">
		<cfset var className = str_replace("Connection", "Builder", this.__class)>

		<cfif class_exists(className)>
			<cfreturn className>
		</cfif>

		<cfreturn "ColdIgniter\Database\BaseBuilder">
	</cffunction>

	<!---
	 * Creates a prepared statement with the database that can then
	 * be used to execute multiple statements against. Within the
	 * closure, you would build the query in any normal way, though
	 * the Query Builder is the expected manner.
	 *
	 * @param Closure(BaseConnection): mixed $func
	 * @param array<string, mixed>           $options
	 *
	 * @return BasePreparedQuery|null
	 *
	 * Not ported yet: BasePreparedQuery.
	--->
	<cffunction name="prepare" access="public" returntype="any" output="no">
		<cfargument name="func" type="any" required="yes">
		<cfargument name="options" type="any" required="no" default="">

		<cfthrow type="ColdIgniter.LogicException" message="Not ported yet: BasePreparedQuery.">
	</cffunction>

	<!---
	 * Returns the last query's statement object.
	 *
	 * @return Query
	--->
	<cffunction name="getLastQuery" access="public" returntype="any" output="no">

		<cfreturn this.lastQuery>
	</cffunction>

	<!---
	 * Returns a string representation of the last query's statement object.
	--->
	<cffunction name="showLastQuery" access="public" returntype="string" output="no">

		<cfif IsObject(this.lastQuery)>
			<cfreturn this.lastQuery.getQuery()>
		</cfif>

		<cfreturn "">
	</cffunction>

	<!---
	 * Returns the time we started to connect to this database in
	 * seconds with microseconds.
	 *
	 * Used by the Debug Toolbar's timeline.
	--->
	<cffunction name="getConnectStart" access="public" returntype="any" output="no">

		<cfreturn this.connectTime>
	</cffunction>

	<!---
	 * Returns the number of seconds with microseconds that it took
	 * to connect to the database.
	 *
	 * Used by the Debug Toolbar's timeline.
	--->
	<cffunction name="getConnectDuration" access="public" returntype="string" output="no">
		<cfargument name="decimals" type="numeric" required="no" default="6">

		<cfreturn number_format(this.connectDuration, arguments.decimals)>
	</cffunction>

	<!---
	 * Protect Identifiers
	 *
	 * This function is used extensively by the Query Builder class, and by
	 * a couple functions in this class.
	 * It takes a column or table name (optionally with an alias) and inserts
	 * the table prefix onto it. Some logic is necessary in order to deal with
	 * column names that include the path. Consider a query like this:
	 *
	 * SELECT hostname.database.table.column AS c FROM hostname.database.table
	 *
	 * Or a query with aliasing:
	 *
	 * SELECT m.member_id, m.member_name FROM members AS m
	 *
	 * Since the column name can include up to four segments (host, DB, table, column)
	 * or also have an alias prefix, we need to do a bit of work to figure this out and
	 * insert the table prefix (if it exists) in the proper position, and escape only
	 * the correct identifiers.
	 *
	 * @param array<array-key, mixed>|int|string|TableName $item
	 * @param bool                                         $prefixSingle       Prefix a table name with no segments?
	 * @param bool                                         $protectIdentifiers Protect table or column names?
	 * @param bool                                         $fieldExists        Supplied $item contains a column name?
	 *
	 * @return ($item is array ? array<array-key, mixed> : string)
	 *
	 * Difference: protectIdentifiers_ is null when it is an empty string,
	 * as a literal false is the text "false" and is not told from a null.
	 * A list gives a list, and a map gives a map.
	 *
	 * Difference: the regular expression that collapses the white space
	 * has one quantifier and is not guarded, and the one of the swapped
	 * prefix has one lazy quantifier that matches a single character.
	--->
	<cffunction name="protectIdentifiers" access="public" returntype="any" output="no">
		<cfargument name="item" type="any" required="yes">
		<cfargument name="prefixSingle" type="boolean" required="no" default="false">
		<cfargument name="protectIdentifiers_" type="any" required="no" default="">
		<cfargument name="fieldExists_" type="boolean" required="no" default="true">
		<cfset var protect = this.protectIdentifiers_>
		<cfset var item_ = "">
		<cfset var escapedArray = "">
		<cfset var keys = "">
		<cfset var i = 0>
		<cfset var offset = 0>
		<cfset var alias = "">
		<cfset var cacheKey = "">

		<!--- Difference: is_null() is written out here, as this is run for each identifier and the test costs a tenth of the call of the function. --->
		<cfif NOT (IsSimpleValue(arguments.protectIdentifiers_) AND arguments.protectIdentifiers_ EQ "")>
			<cfset protect = arguments.protectIdentifiers_>
		</cfif>

		<cfif IsArray(arguments.item)>
			<cfset escapedArray = ArrayNew(1)>

			<cfloop from="1" to="#ArrayLen(arguments.item)#" index="i">
				<cfset ArrayAppend(escapedArray, this.protectIdentifiers(arguments.item[i], arguments.prefixSingle, protect, arguments.fieldExists_))>
			</cfloop>

			<cfreturn escapedArray>
		</cfif>

		<cfif IsObject(arguments.item)>
			<!--- a TableName --->
			<cfreturn escapeTableName(arguments.item)>
		</cfif>

		<cfif IsStruct(arguments.item)>
			<cfset escapedArray = array_()>
			<cfset keys = array_keys(arguments.item)>

			<cfloop from="1" to="#ArrayLen(keys)#" index="i">
				<cfset escapedArray[this.protectIdentifiers(keys[i])] = this.protectIdentifiers(arguments.item[keys[i]], arguments.prefixSingle, protect, arguments.fieldExists_)>
			</cfloop>

			<cfreturn escapedArray>
		</cfif>

		<!--- If you pass a list of columns, an item can be a number; it is text here. --->
		<cfset item_ = "" & arguments.item>

		<!---
		 * Difference: the result for a text item is kept in this connection,
		 * as a request asks for the same names many times. The key has all
		 * that the result depends on: the flags, the prefixes, the escape
		 * character, the reserved identifiers, the aliased tables and the
		 * item.
		--->
		<cfif IsSimpleValue(this.protectCache_)>
			<cfset this.protectCache_ = CreateObject("java", "java.util.HashMap").init()>
		</cfif>

		<cfif IsArray(this.escapeChar)>
			<cfset cacheKey = "A" & ArrayToList(this.escapeChar, Chr(2))>
		<cfelse>
			<cfset cacheKey = "S" & this.escapeChar>
		</cfif>

		<cfset cacheKey = protect & Chr(1) & arguments.prefixSingle & Chr(1) & arguments.fieldExists_ & Chr(1) & this.DBPrefix & Chr(1) & this.swapPre & Chr(1) & cacheKey & Chr(1) & ArrayToList(this.reservedIdentifiers, Chr(2)) & Chr(1) & ArrayToList(this.aliasedTables, Chr(2)) & Chr(1) & item_>

		<cfif this.protectCache_.containsKey(cacheKey)>
			<cfreturn this.protectCache_.get(cacheKey)>
		</cfif>

		<!---
		 * This is basically a bug fix for queries that use MAX, MIN, etc.
		 * If a parenthesis is found we know that we do not need to
		 * escape the data or add a prefix. There's probably a more graceful
		 * way to deal with this, but I'm not thinking of it
		 *
		 * Added exception for single quotes as well, we don't want to alter
		 * literal strings.
		--->
		<!--- Difference: REFind() with one class, where the original calls strcspn() --->
		<cfif REFind("[()']", item_) GT 0>
			<cfset this.protectCache_.put(cacheKey, item_)>
			<cfreturn item_>
		</cfif>

		<!--- Do not protect identifiers and do not prefix, no swap prefix, there is nothing to do --->
		<cfif NOT protect AND NOT arguments.prefixSingle AND Len(this.swapPre) EQ 0>
			<cfset this.protectCache_.put(cacheKey, item_)>
			<cfreturn item_>
		</cfif>

		<!---
		 * Difference: an item with no white space is the usual one (NUL is
		 * in the class too, as trim() of the original takes it away, so
		 * such an item goes the long way). It is not changed by the trim or by
		 * the collapse of the white space, and it has no alias, so the steps
		 * that look for them are left out for it.
		--->
		<cfif REFind("[\x00\x09-\x0D\x20]", item_) GT 0>
			<!--- Convert tabs or multiple spaces into single spaces --->
			<cfset item_ = preg_replace("/\s+/", " ", trim_(item_), true)>

			<!---
			 * If the item has an alias declaration we remove it and set it aside.
			 * Note: strripos() is used in order to support spaces in table names
			--->
			<cfset offset = strripos(item_, " AS ")>

			<cfif offset GT 0>
				<cfif protect>
					<cfset alias = substr(item_, offset, 4) & this.escapeIdentifiers(substr(item_, offset + 4))>
				<cfelse>
					<cfset alias = substr(item_, offset)>
				</cfif>

				<cfset item_ = substr(item_, 0, offset)>
			<cfelse>
				<cfset offset = strrpos(item_, " ")>

				<cfif offset GT 0>
					<cfif protect>
						<cfset alias = " " & this.escapeIdentifiers(substr(item_, offset + 1))>
					<cfelse>
						<cfset alias = substr(item_, offset)>
					</cfif>

					<cfset item_ = substr(item_, 0, offset)>
				<cfelse>
					<cfset alias = "">
				</cfif>
			</cfif>
		</cfif>

		<!---
		 * Break the string apart if it contains periods, then insert the table prefix
		 * in the correct location, assuming the period doesn't indicate that we're dealing
		 * with an alias. While we're at it, we will escape the components
		--->
		<cfif Find(".", item_) GT 0>
			<cfset item_ = protectDotItem(item_, alias, protect, arguments.fieldExists_)>
			<cfset this.protectCache_.put(cacheKey, item_)>
			<cfreturn item_>
		</cfif>

		<!---
		 * In some cases, especially 'from', we end up running through
		 * protect_identifiers twice. This algorithm won't work when
		 * it contains the escapeChar so strip it out.
		--->
		<cfset item_ = trimEscapeChar(item_)>

		<!--- Is there a table prefix? If not, no need to insert it --->
		<cfif Len(this.DBPrefix) GT 0>
			<!--- Verify table prefix and replace if necessary --->
			<cfif Len(this.swapPre) GT 0 AND str_starts_with(item_, this.swapPre)>
				<cfset item_ = preg_replace("/^" & this.swapPre & "(\S+?)/", this.DBPrefix & "\1", item_)>
			<!--- Do we prefix an item with no segments? --->
			<cfelseif arguments.prefixSingle AND NOT str_starts_with(item_, this.DBPrefix)>
				<cfset item_ = this.DBPrefix & item_>
			</cfif>
		</cfif>

		<cfif protect AND NOT in_array(item_, this.reservedIdentifiers)>
			<cfset item_ = this.escapeIdentifiers(item_)>
		</cfif>

		<cfset item_ = item_ & alias>
		<cfset this.protectCache_.put(cacheKey, item_)>
		<cfreturn item_>
	</cffunction>

	<cffunction name="trimEscapeChar" access="private" returntype="string" output="no">
		<cfargument name="item" type="string" required="yes">

		<!--- Difference: with one escape character that is not in the item, there is nothing to trim --->
		<cfif IsSimpleValue(this.escapeChar) AND Len(this.escapeChar) EQ 1 AND Find(this.escapeChar, arguments.item) EQ 0>
			<cfreturn arguments.item>
		</cfif>

		<cfif IsArray(this.escapeChar)>
			<cfreturn trim_(arguments.item, implode("", this.escapeChar))>
		</cfif>

		<cfreturn trim_(arguments.item, this.escapeChar)>
	</cffunction>

	<cffunction name="protectDotItem" access="private" returntype="string" output="no">
		<cfargument name="item" type="string" required="yes">
		<cfargument name="alias" type="string" required="yes">
		<cfargument name="protectIdentifiers_" type="boolean" required="yes">
		<cfargument name="fieldExists_" type="boolean" required="yes">
		<cfset var parts = explode(".", arguments.item)>
		<cfset var item_ = "">
		<cfset var i = 0>
		<cfset var index = 0>

		<cfloop from="1" to="#ArrayLen(parts)#" index="i">
			<cfset parts[i] = trimEscapeChar(parts[i])>
		</cfloop>

		<cfset item_ = implode(".", parts)>

		<!---
		 * Does the first segment of the exploded item match
		 * one of the aliases previously identified? If so,
		 * we have nothing more to do other than escape the item
		 *
		 * $aliasedTables is empty when QB isn't enabled.
		--->
		<cfif ArrayLen(this.aliasedTables) GT 0 AND in_array(parts[1], this.aliasedTables)>
			<cfif arguments.protectIdentifiers_>
				<cfloop from="1" to="#ArrayLen(parts)#" index="i">
					<cfif NOT in_array(parts[i], this.reservedIdentifiers)>
						<cfset parts[i] = this.escapeIdentifiers(parts[i])>
					</cfif>
				</cfloop>

				<cfset item_ = implode(".", parts)>
			</cfif>

			<cfreturn item_ & arguments.alias>
		</cfif>

		<!--- Is there a table prefix defined in the config file? If not, no need to do anything --->
		<cfif Len(this.DBPrefix) GT 0>
			<!---
			 * We now add the table prefix based on some logic.
			 * Do we have 4 segments (hostname.database.table.column)?
			 * If so, we add the table prefix to the column name in the 3rd segment.
			 *
			 * Difference: the index is that of the original plus one, as a
			 * list starts at 1.
			--->
			<cfif ArrayLen(parts) GTE 4>
				<cfset index = 3>
			<!---
			 * Do we have 3 segments (database.table.column)?
			 * If so, we add the table prefix to the column name in 2nd position
			--->
			<cfelseif ArrayLen(parts) GTE 3>
				<cfset index = 2>
			<!---
			 * Do we have 2 segments (table.column)?
			 * If so, we add the table prefix to the column name in 1st segment
			--->
			<cfelse>
				<cfset index = 1>
			</cfif>

			<!---
			 * This flag is set when the supplied $item does not contain a field name.
			 * This can happen when this function is being called from a JOIN.
			--->
			<cfif NOT arguments.fieldExists_>
				<cfset index = index + 1>
			</cfif>

			<!--- Verify table prefix and replace if necessary --->
			<cfif Len(this.swapPre) GT 0 AND str_starts_with(parts[index], this.swapPre)>
				<cfset parts[index] = preg_replace("/^" & this.swapPre & "(\S+?)/", this.DBPrefix & "\1", parts[index])>
			<!--- We only add the table prefix if it does not already exist --->
			<cfelseif NOT str_starts_with(parts[index], this.DBPrefix)>
				<cfset parts[index] = this.DBPrefix & parts[index]>
			</cfif>

			<!--- Put the parts back together --->
			<cfset item_ = implode(".", parts)>
		</cfif>

		<cfif arguments.protectIdentifiers_>
			<cfset item_ = this.escapeIdentifiers(item_)>
		</cfif>

		<cfreturn item_ & arguments.alias>
	</cffunction>

	<!---
	 * Escape the SQL Identifier
	 *
	 * This function escapes single identifier.
	 *
	 * @param non-empty-string|TableName $item
	--->
	<cffunction name="escapeIdentifier" access="public" returntype="string" output="no">
		<cfargument name="item" type="any" required="yes">

		<cfif IsSimpleValue(arguments.item) AND Len(arguments.item) EQ 0>
			<cfreturn "">
		</cfif>

		<cfif IsObject(arguments.item)>
			<cfreturn escapeTableName(arguments.item)>
		</cfif>

		<cfreturn this.escapeChar & str_replace(this.escapeChar, this.escapeChar & this.escapeChar, arguments.item) & this.escapeChar>
	</cffunction>

	<!---
	 * Returns escaped table name with alias.
	--->
	<cffunction name="escapeTableName" access="private" returntype="string" output="no">
		<cfargument name="tableName" type="any" required="yes">
		<cfset var alias = arguments.tableName.getAlias()>
		<cfset var escaped = this.escapeIdentifier(arguments.tableName.getActualTableName())>

		<cfif Len(alias) GT 0>
			<cfset escaped = escaped & " " & this.escapeIdentifier(alias)>
		</cfif>

		<cfreturn escaped>
	</cffunction>

	<!---
	 * Escape the SQL Identifiers
	 *
	 * This function escapes column and table names
	 *
	 * @param array<array-key, mixed>|string $item
	 *
	 * @return ($item is array ? array<array-key, mixed> : string)
	 *
	 * Difference: a list gives a new list, and a map a new map, where the
	 * original changes the array that it is given. The regular expressions
	 * have one quantifier on a class that has no period, so they are read
	 * in a time that depends on the length of the item, which the guard of
	 * preg_replace() caps at 8192 characters. A name with no period and no
	 * escape character does not go through them, and has no limit.
	--->
	<cffunction name="escapeIdentifiers" access="public" returntype="any" output="no">
		<cfargument name="item" type="any" required="yes">
		<cfset var result = "">
		<cfset var keys = "">
		<cfset var i = 0>
		<cfset var id = "">
		<cfset var doubleQuote = "false">

		<cfif IsSimpleValue(this.escapeChar) AND Len(this.escapeChar) EQ 0>
			<cfreturn arguments.item>
		</cfif>

		<cfif IsSimpleValue(arguments.item)>
			<cfif Len(arguments.item) EQ 0 OR Compare(arguments.item, "0") EQ 0 OR in_array(arguments.item, this.reservedIdentifiers)>
				<cfreturn arguments.item>
			</cfif>
		<cfelseif IsArray(arguments.item)>
			<cfif ArrayLen(arguments.item) EQ 0>
				<cfreturn arguments.item>
			</cfif>
		<cfelseif IsStruct(arguments.item) AND NOT IsObject(arguments.item)>
			<cfif arguments.item.size() EQ 0>
				<cfreturn arguments.item>
			</cfif>
		</cfif>

		<cfif IsArray(arguments.item)>
			<cfset result = ArrayNew(1)>

			<cfloop from="1" to="#ArrayLen(arguments.item)#" index="i">
				<cfset ArrayAppend(result, this.escapeIdentifiers(arguments.item[i]))>
			</cfloop>

			<cfreturn result>
		</cfif>

		<cfif IsStruct(arguments.item) AND NOT IsObject(arguments.item)>
			<cfset result = array_()>
			<cfset keys = array_keys(arguments.item)>

			<cfloop from="1" to="#ArrayLen(keys)#" index="i">
				<cfset result[keys[i]] = this.escapeIdentifiers(arguments.item[keys[i]])>
			</cfloop>

			<cfreturn result>
		</cfif>

		<cfif IsSimpleValue(this.escapeChar) AND Compare(this.escapeChar, """") EQ 0>
			<cfset doubleQuote = "true">
		</cfif>

		<!--- Avoid breaking functions and literal values inside queries --->
		<!--- Difference: REFind() for a character that is not a digit, where the original calls ctype_digit() (the item is not empty here) --->
		<cfif REFind("[^0-9]", arguments.item) EQ 0 OR Compare(Left(arguments.item, 1), "'") EQ 0 OR (NOT doubleQuote AND Compare(Left(arguments.item, 1), """") EQ 0) OR Find("(", arguments.item) GT 0>
			<cfreturn arguments.item>
		</cfif>

		<!---
		 * Difference: a name with no period and no escape character is the
		 * usual item, and the regular expression below can only put the
		 * escape character on each side of it. That is done here with no
		 * regular expression (and so with no limit on its length). This runs
		 * for every name of every query.
		--->
		<cfif IsSimpleValue(this.escapeChar) AND Len(this.escapeChar) EQ 1 AND Find(".", arguments.item) EQ 0 AND Find(this.escapeChar, arguments.item) EQ 0>
			<cfreturn this.escapeChar & arguments.item & this.escapeChar>
		</cfif>

		<cfif ArrayLen(this.pregEscapeChar) EQ 0>
			<cfif IsArray(this.escapeChar)>
				<cfset ArrayAppend(this.pregEscapeChar, preg_quote(this.escapeChar[1]))>
				<cfset ArrayAppend(this.pregEscapeChar, preg_quote(this.escapeChar[2]))>
				<cfset ArrayAppend(this.pregEscapeChar, this.escapeChar[1])>
				<cfset ArrayAppend(this.pregEscapeChar, this.escapeChar[2])>
			<cfelse>
				<cfset ArrayAppend(this.pregEscapeChar, preg_quote(this.escapeChar))>
				<cfset ArrayAppend(this.pregEscapeChar, this.pregEscapeChar[1])>
				<cfset ArrayAppend(this.pregEscapeChar, this.escapeChar)>
				<cfset ArrayAppend(this.pregEscapeChar, this.escapeChar)>
			</cfif>
		</cfif>

		<cfloop from="1" to="#ArrayLen(this.reservedIdentifiers)#" index="i">
			<cfset id = this.reservedIdentifiers[i]>

			<cfif Find("." & id, arguments.item) GT 0>
				<cfreturn preg_replace("/" & this.pregEscapeChar[1] & "?([^" & this.pregEscapeChar[2] & "\.]+)" & this.pregEscapeChar[2] & "?\./i", this.pregEscapeChar[3] & "$1" & this.pregEscapeChar[4] & ".", arguments.item)>
			</cfif>
		</cfloop>

		<cfreturn preg_replace("/" & this.pregEscapeChar[1] & "?([^" & this.pregEscapeChar[2] & "\.]+)" & this.pregEscapeChar[2] & "?(\.)?/i", this.pregEscapeChar[3] & "$1" & this.pregEscapeChar[4] & "$2", arguments.item)>
	</cffunction>

	<!---
	 * Prepends a database prefix if one exists in configuration
	 *
	 * @throws DatabaseException
	--->
	<cffunction name="prefixTable" access="public" returntype="string" output="no">
		<cfargument name="table" type="string" required="no" default="">

		<cfif Len(arguments.table) EQ 0>
			<cfthrow type="ColdIgniter.Database.Exceptions.DatabaseException" message="A table name is required for that operation.">
		</cfif>

		<cfreturn this.DBPrefix & arguments.table>
	</cffunction>

	<!---
	 * Returns the total number of rows affected by this query.
	--->
	<cffunction name="affectedRows" access="public" returntype="numeric" output="no">

		<cfthrow type="ColdIgniter.LogicException" message="The class does not define affectedRows().">
	</cffunction>

	<!---
	 * "Smart" Escape String
	 *
	 * Escapes data based on type.
	 * Sets boolean and null types
	 *
	 * @param mixed $str
	 *
	 * @return ($str is array ? array<array-key, mixed> : float|int|string)
	 *
	 * Difference: the type is read from the Java class of the value. Only
	 * a real boolean (a comparison, or JavaCast) gives 0 or 1, and a real
	 * number (from a calculation or JavaCast) is returned as it is. A
	 * string is quoted, also the literal true, false and a literal number,
	 * which are text, and so is an empty string. A null is a NullValue,
	 * which gives NULL. A list gives a new list, and a map a new map.
	--->
	<cffunction name="escape" access="public" returntype="any" output="no">
		<cfargument name="str" type="any" required="yes">
		<cfset var value = arguments.str>
		<cfset var result = "">
		<cfset var keys = "">
		<cfset var i = 0>
		<cfset var typeName = "">

		<cfif IsObject(value)>
			<cfif Compare(value.__class, "ColdIgniter\Database\NullValue") EQ 0>
				<cfreturn "NULL">
			</cfif>

			<cfif Compare(value.__class, "ColdIgniter\Database\RawSql") EQ 0>
				<cfreturn value.__toString()>
			</cfif>

			<!--- Stringable --->
			<cfif StructKeyExists(value, "__toString")>
				<cfreturn "'" & this.escapeString(value.__toString()) & "'">
			</cfif>

			<cfreturn value>
		</cfif>

		<cfif IsArray(value)>
			<cfset result = ArrayNew(1)>

			<cfloop from="1" to="#ArrayLen(value)#" index="i">
				<cfset ArrayAppend(result, this.escape(value[i]))>
			</cfloop>

			<cfreturn result>
		</cfif>

		<cfif IsStruct(value)>
			<cfset result = array_()>
			<cfset keys = array_keys(value)>

			<cfloop from="1" to="#ArrayLen(keys)#" index="i">
				<cfset result[keys[i]] = this.escape(value[keys[i]])>
			</cfloop>

			<cfreturn result>
		</cfif>

		<cfset typeName = value.getClass().getName()>

		<cfif Compare(typeName, "java.lang.Boolean") EQ 0>
			<cfif value>
				<cfreturn 1>
			</cfif>

			<cfreturn 0>
		</cfif>

		<cfif Compare(typeName, "java.lang.Integer") EQ 0 OR Compare(typeName, "java.lang.Double") EQ 0 OR Compare(typeName, "java.lang.Long") EQ 0 OR Compare(typeName, "java.math.BigDecimal") EQ 0>
			<cfreturn value>
		</cfif>

		<cfreturn "'" & this.escapeString(value) & "'">
	</cffunction>

	<!---
	 * Escape String
	 *
	 * @param list<string|Stringable>|string|Stringable $str  Input string
	 * @param bool                                      $like Whether the string will be used in a LIKE condition
	 *
	 * @return list<string>|string
	 *
	 * Difference: a list gives a new list, and a map a new map.
	--->
	<cffunction name="escapeString" access="public" returntype="any" output="no">
		<cfargument name="str" type="any" required="yes">
		<cfargument name="like" type="boolean" required="no" default="false">
		<cfset var value = arguments.str>
		<cfset var result = "">
		<cfset var keys = "">
		<cfset var i = 0>
		<cfset var searchList = ArrayNew(1)>
		<cfset var replaceList = ArrayNew(1)>

		<cfif IsArray(value)>
			<cfset result = ArrayNew(1)>

			<cfloop from="1" to="#ArrayLen(value)#" index="i">
				<cfset ArrayAppend(result, this.escapeString(value[i], arguments.like))>
			</cfloop>

			<cfreturn result>
		</cfif>

		<cfif IsStruct(value) AND NOT IsObject(value)>
			<cfset result = array_()>
			<cfset keys = array_keys(value)>

			<cfloop from="1" to="#ArrayLen(keys)#" index="i">
				<cfset result[keys[i]] = this.escapeString(value[keys[i]], arguments.like)>
			</cfloop>

			<cfreturn result>
		</cfif>

		<!--- Stringable --->
		<cfif IsObject(value)>
			<cfif Compare(value.__class, "ColdIgniter\Database\RawSql") EQ 0>
				<cfreturn value.__toString()>
			</cfif>

			<cfset value = value.__toString()>
		</cfif>

		<cfset value = _escapeString(value)>

		<!--- escape LIKE condition wildcards --->
		<cfif arguments.like>
			<cfset ArrayAppend(searchList, this.likeEscapeChar)>
			<cfset ArrayAppend(searchList, "%")>
			<cfset ArrayAppend(searchList, "_")>
			<cfset ArrayAppend(replaceList, this.likeEscapeChar & this.likeEscapeChar)>
			<cfset ArrayAppend(replaceList, this.likeEscapeChar & "%")>
			<cfset ArrayAppend(replaceList, this.likeEscapeChar & "_")>

			<cfreturn str_replace(searchList, replaceList, value)>
		</cfif>

		<cfreturn value>
	</cffunction>

	<!---
	 * Escape LIKE String
	 *
	 * Calls the individual driver for platform
	 * specific escaping for LIKE conditions
	 *
	 * @param list<string|Stringable>|string|Stringable $str
	 *
	 * @return list<string>|string
	--->
	<cffunction name="escapeLikeString" access="public" returntype="any" output="no">
		<cfargument name="str" type="any" required="yes">

		<cfreturn this.escapeString(arguments.str, true)>
	</cffunction>

	<!---
	 * Platform independent string escape.
	 *
	 * Will likely be overridden in child classes.
	--->
	<cffunction name="_escapeString" access="private" returntype="string" output="no">
		<cfargument name="str" type="string" required="yes">

		<!---
		 * Difference: REReplace() and Replace(), where the original calls
		 * remove_invisible_characters($str, false) and str_replace(). The
		 * class is the one of remove_invisible_characters(): every control
		 * character except tab, newline and carriage return. One pass is
		 * enough, because taking a control character out never makes one.
		 * This runs for every value of every query.
		--->
		<cfreturn Replace(REReplace(arguments.str, "[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]+", "", "all"), "'", "''", "all")>
	</cffunction>

	<!---
	 * This function enables you to call database functions that are not natively included
	 * in ColdIgniter, in a platform independent manner.
	 *
	 * @throws DatabaseException
	 *
	 * Difference: there is no function_exists() and a function of a database
	 * extension is not called, so the feature is always not available. The
	 * params are not taken.
	--->
	<cffunction name="callFunction" access="public" returntype="any" output="no">
		<cfargument name="functionName" type="string" required="yes">
		<cfset var driver = getDriverFunctionPrefix()>
		<cfset var functionName_ = arguments.functionName>

		<cfif NOT str_starts_with(functionName_, driver)>
			<cfset functionName_ = driver & functionName_>
		</cfif>

		<cfif this.DBDebug>
			<cfthrow type="ColdIgniter.Database.Exceptions.DatabaseException" message="This feature is not available for the database you are using.">
		</cfif>

		<cfreturn "false">
	</cffunction>

	<!---
	 * Get the prefix of the function to access the DB.
	--->
	<cffunction name="getDriverFunctionPrefix" access="private" returntype="string" output="no">

		<cfreturn LCase(this.DBDriver) & "_">
	</cffunction>

	<!--- -------------------------------------------------------------------- --->
	<!--- META Methods --->
	<!--- -------------------------------------------------------------------- --->

	<!---
	 * Returns an array of table names
	 *
	 * @return false|list<string>
	 *
	 * @throws DatabaseException
	 *
	 * Difference: the names that start with the prefix are told by a
	 * comparison of the text, where the original uses preg_grep().
	--->
	<cffunction name="listTables" access="public" returntype="any" output="no">
		<cfargument name="constrainByPrefix" type="boolean" required="no" default="false">
		<cfset var tables = ArrayNew(1)>
		<cfset var names = "">
		<cfset var sql = "">
		<cfset var query_ = "">
		<cfset var rows = "">
		<cfset var row = "">
		<cfset var table = "">
		<cfset var keys = "">
		<cfset var i = 0>

		<cfif StructKeyExists(this.dataCache, "table_names") AND ArrayLen(this.dataCache["table_names"]) GT 0>
			<cfset names = this.dataCache["table_names"]>

			<cfloop from="1" to="#ArrayLen(names)#" index="i">
				<cfif NOT arguments.constrainByPrefix OR str_starts_with(names[i], this.DBPrefix)>
					<cfset ArrayAppend(tables, names[i])>
				</cfif>
			</cfloop>

			<cfreturn tables>
		</cfif>

		<cfset sql = _listTables(arguments.constrainByPrefix)>

		<cfif identical_(sql, "false")>
			<cfif this.DBDebug>
				<cfthrow type="ColdIgniter.Database.Exceptions.DatabaseException" message="This feature is not available for the database you are using.">
			</cfif>

			<cfreturn "false">
		</cfif>

		<cfset this.dataCache["table_names"] = ArrayNew(1)>

		<cfset query_ = this.query(sql)>
		<cfset rows = query_.getResultArray()>

		<cfloop from="1" to="#ArrayLen(rows)#" index="i">
			<cfset row = rows[i]>

			<cfif StructKeyExists(row, "table_name")>
				<cfset table = row["table_name"]>
			<cfelseif StructKeyExists(row, "TABLE_NAME")>
				<cfset table = row["TABLE_NAME"]>
			<cfelse>
				<!--- the first key --->
				<cfset keys = array_keys(row)>
				<cfset table = row[keys[1]]>
			</cfif>

			<cfset ArrayAppend(this.dataCache["table_names"], table)>
		</cfloop>

		<cfreturn this.dataCache["table_names"]>
	</cffunction>

	<!---
	 * Determine if a particular table exists
	 *
	 * @param bool $cached Whether to use data cache
	--->
	<cffunction name="tableExists" access="public" returntype="boolean" output="no">
		<cfargument name="tableName" type="string" required="yes">
		<cfargument name="cached" type="boolean" required="no" default="true">
		<cfset var sql = "">
		<cfset var exists_ = "false">
		<cfset var found = "false">
		<cfset var names = "">
		<cfset var i = 0>

		<cfif arguments.cached>
			<cfreturn in_array(this.protectIdentifiers(arguments.tableName, true, false, false), this.listTables())>
		</cfif>

		<cfset sql = _listTables(false, arguments.tableName)>

		<cfif identical_(sql, "false")>
			<cfif this.DBDebug>
				<cfthrow type="ColdIgniter.Database.Exceptions.DatabaseException" message="This feature is not available for the database you are using.">
			</cfif>

			<cfreturn false>
		</cfif>

		<cfset exists_ = ArrayLen(this.query(sql).getResultArray()) GT 0>

		<!--- if cache has been built already --->
		<cfif StructKeyExists(this.dataCache, "table_names") AND ArrayLen(this.dataCache["table_names"]) GT 0>
			<cfset names = this.dataCache["table_names"]>

			<cfloop from="1" to="#ArrayLen(names)#" index="i">
				<cfif Compare(LCase(names[i]), LCase(arguments.tableName)) EQ 0>
					<cfset found = "true">
					<cfbreak>
				</cfif>
			</cfloop>

			<!---
			 * table doesn't exist but still in cache - lets reset cache, it can be rebuilt later
			 * OR if table does exist but is not found in cache
			--->
			<cfif (found AND NOT exists_) OR (NOT found AND exists_)>
				<cfset this.resetDataCache()>
			</cfif>
		</cfif>

		<cfreturn exists_>
	</cffunction>

	<!---
	 * Fetch Field Names
	 *
	 * @param string|TableName $tableName
	 *
	 * @return false|list<string>
	 *
	 * @throws DatabaseException
	--->
	<cffunction name="getFieldNames" access="public" returntype="any" output="no">
		<cfargument name="tableName" type="any" required="yes">
		<cfset var table = "">
		<cfset var sql = "">
		<cfset var query_ = "">
		<cfset var rows = "">
		<cfset var row = "">
		<cfset var columnKey = "">
		<cfset var keys = "">
		<cfset var fieldNames = "">
		<cfset var i = 0>

		<cfif IsObject(arguments.tableName)>
			<cfset table = arguments.tableName.getTableName()>
		<cfelse>
			<cfset table = arguments.tableName>
		</cfif>

		<!--- Is there a cached result? --->
		<cfif StructKeyExists(this.dataCache, "field_names")>
			<cfif StructKeyExists(this.dataCache["field_names"], table)>
				<cfreturn this.dataCache["field_names"][table]>
			</cfif>
		</cfif>

		<cfif NOT hasConnID()>
			<cfset this.initialize_()>
		</cfif>

		<cfset sql = _listColumns(arguments.tableName)>

		<cfif identical_(sql, "false")>
			<cfif this.DBDebug>
				<cfthrow type="ColdIgniter.Database.Exceptions.DatabaseException" message="This feature is not available for the database you are using.">
			</cfif>

			<cfreturn "false">
		</cfif>

		<cfset query_ = this.query(sql)>

		<cfif NOT StructKeyExists(this.dataCache, "field_names")>
			<cfset this.dataCache["field_names"] = array_()>
		</cfif>

		<cfset fieldNames = this.dataCache["field_names"]>
		<cfset fieldNames[table] = ArrayNew(1)>

		<cfset rows = query_.getResultArray()>

		<cfloop from="1" to="#ArrayLen(rows)#" index="i">
			<cfset row = rows[i]>

			<!--- Do we know from where to get the column's name? --->
			<cfif Len(columnKey) EQ 0>
				<cfif StructKeyExists(row, "column_name")>
					<cfset columnKey = "column_name">
				<cfelseif StructKeyExists(row, "COLUMN_NAME")>
					<cfset columnKey = "COLUMN_NAME">
				<cfelse>
					<!--- We have no other choice but to just get the first element's key. --->
					<cfset keys = array_keys(row)>
					<cfset columnKey = keys[1]>
				</cfif>
			</cfif>

			<cfset ArrayAppend(fieldNames[table], row[columnKey])>
		</cfloop>

		<cfreturn fieldNames[table]>
	</cffunction>

	<!---
	 * Determine if a particular field exists
	--->
	<cffunction name="fieldExists" access="public" returntype="boolean" output="no">
		<cfargument name="fieldName" type="string" required="yes">
		<cfargument name="tableName" type="string" required="yes">

		<cfreturn in_array(arguments.fieldName, this.getFieldNames(arguments.tableName))>
	</cffunction>

	<!---
	 * Returns an object with field data
	 *
	 * @return list<stdClass>
	--->
	<cffunction name="getFieldData" access="public" returntype="any" output="no">
		<cfargument name="table" type="string" required="yes">

		<cfreturn _fieldData(this.protectIdentifiers(arguments.table, true, false, false))>
	</cffunction>

	<!---
	 * Returns an object with key data
	 *
	 * @return array<string, stdClass>
	--->
	<cffunction name="getIndexData" access="public" returntype="any" output="no">
		<cfargument name="table" type="string" required="yes">

		<cfreturn _indexData(this.protectIdentifiers(arguments.table, true, false, false))>
	</cffunction>

	<!---
	 * Returns an object with foreign key data
	 *
	 * @return array<string, stdClass>
	--->
	<cffunction name="getForeignKeyData" access="public" returntype="any" output="no">
		<cfargument name="table" type="string" required="yes">

		<cfreturn _foreignKeyData(this.protectIdentifiers(arguments.table, true, false, false))>
	</cffunction>

	<!---
	 * Converts array of arrays generated by _foreignKeyData() to array of objects
	 *
	 * @param array<array-key, array{
	 *     constraint_name: string|null,
	 *     table_name: string,
	 *     column_name: list<string>,
	 *     foreign_table_name: string,
	 *     foreign_column_name: list<string>,
	 *     on_delete: string,
	 *     on_update: string|null,
	 *     match: string|null,
	 * }> $data
	 *
	 * @return array<string, stdClass>
	 *
	 * Difference: the objects are maps (see array_()).
	--->
	<cffunction name="foreignKeyDataToObjects" access="private" returntype="any" output="no">
		<cfargument name="data" type="array" required="yes">
		<cfset var retVal = array_()>
		<cfset var row = "">
		<cfset var name = "">
		<cfset var obj = "">
		<cfset var i = 0>

		<cfloop from="1" to="#ArrayLen(arguments.data)#" index="i">
			<cfset row = arguments.data[i]>
			<cfset name = row["constraint_name"]>

			<cfif is_null(name)>
				<cfset name = row["table_name"] & "_" & implode("_", row["column_name"]) & "_foreign">
			</cfif>

			<cfset obj = array_("constraint_name", name, "table_name", row["table_name"], "column_name", row["column_name"], "foreign_table_name", row["foreign_table_name"], "foreign_column_name", row["foreign_column_name"], "on_delete", row["on_delete"], "on_update", row["on_update"], "match", row["match"])>

			<cfset retVal[name] = obj>
		</cfloop>

		<cfreturn retVal>
	</cffunction>

	<!---
	 * Disables foreign key checks temporarily.
	 *
	 * @return bool
	--->
	<cffunction name="disableForeignKeyChecks" access="public" returntype="any" output="no">
		<cfset var sql = _disableForeignKeyChecks()>

		<cfif Len(sql) EQ 0>
			<!--- The feature is not supported. --->
			<cfreturn "false">
		</cfif>

		<cfreturn this.query(sql)>
	</cffunction>

	<!---
	 * Enables foreign key checks temporarily.
	 *
	 * @return bool
	--->
	<cffunction name="enableForeignKeyChecks" access="public" returntype="any" output="no">
		<cfset var sql = _enableForeignKeyChecks()>

		<cfif Len(sql) EQ 0>
			<!--- The feature is not supported. --->
			<cfreturn "false">
		</cfif>

		<cfreturn this.query(sql)>
	</cffunction>

	<!---
	 * Allows the engine to be set into a mode where queries are not
	 * actually executed, but they are still generated, timed, etc.
	 *
	 * This is primarily used by the prepared query functionality.
	 *
	 * @return $this
	--->
	<cffunction name="pretend" access="public" returntype="any" output="no">
		<cfargument name="pretend_" type="boolean" required="no" default="true">

		<cfset this.pretend_ = arguments.pretend_>

		<cfreturn this>
	</cffunction>

	<!---
	 * Empties our data cache. Especially helpful during testing.
	 *
	 * @return $this
	--->
	<cffunction name="resetDataCache" access="public" returntype="any" output="no">

		<cfset this.dataCache = CreateObject("java", "java.util.LinkedHashMap").init()>

		<cfreturn this>
	</cffunction>

	<!---
	 * Determines if the statement is a write-type query or not.
	 *
	 * @param string $sql
	 *
	 * Difference: the original is one regular expression, with .+ followed
	 * by a part that can fail and a lookahead with .*, which backtrack a
	 * lot on a long query. The same rule is made here of linear steps with
	 * java.util.regex (which has no nested quantifiers): the statement
	 * starts with a keyword; or it starts with WITH and has the keyword
	 * after a white space or ")". In both, no RETURNING (with a white space
	 * on each side) may start after the end of the keyword. Every pattern
	 * is searched from a start that moves on by one character, so the
	 * work is at most about the length of the statement for each match.
	 *
	 * The patterns are made once for the connection (writeTypePatterns_):
	 * this runs for every query, and making the patterns costs more than
	 * the tests.
	--->
	<cffunction name="isWriteType" access="public" returntype="boolean" output="no">
		<cfargument name="sql" type="string" required="yes">
		<cfset var keywords = "(?:SET|INSERT|UPDATE|DELETE|REPLACE|CREATE|DROP|TRUNCATE|LOAD|COPY|ALTER|RENAME|GRANT|REVOKE|LOCK|UNLOCK|REINDEX|MERGE)">
		<cfset var flags = JavaCast("int", 2)>
		<cfset var text = JavaCast("string", arguments.sql)>
		<cfset var patternClass = "">
		<cfset var patterns = this.writeTypePatterns_>
		<cfset var matcher = "">
		<cfset var returning = "">
		<cfset var candidate = "">
		<cfset var startAt = 0>
		<cfset var maxEnd = -1>
		<cfset var lastReturning = -1>
		<cfset var scanning = "true">

		<cfif IsSimpleValue(patterns)>
			<cfset patternClass = CreateObject("java", "java.util.regex.Pattern")>
			<cfset patterns = StructNew()>
			<cfset patterns.keyword = patternClass.compile(JavaCast("string", "^\s*""?" & keywords & "\s"), flags)>
			<cfset patterns.returning = patternClass.compile(JavaCast("string", "\sRETURNING\s"), flags)>
			<cfset patterns.with = patternClass.compile(JavaCast("string", "^\s*WITH\s"), flags)>
			<cfset patterns.candidate = patternClass.compile(JavaCast("string", "[\s)]""?" & keywords & "\s"), flags)>
			<cfset this.writeTypePatterns_ = patterns>
		</cfif>

		<!--- starts with the keyword --->
		<cfset matcher = patterns.keyword.matcher(text)>

		<cfif matcher.lookingAt()>
			<cfset startAt = matcher.end()>

			<cfif patterns.returning.matcher(text).find(JavaCast("int", startAt))>
				<cfreturn false>
			</cfif>

			<cfreturn true>
		</cfif>

		<!--- starts with WITH --->
		<cfset matcher = patterns.with.matcher(text)>

		<cfif NOT matcher.lookingAt()>
			<cfreturn false>
		</cfif>

		<!--- the keyword after at least one character, the end of the last one is the best --->
		<cfset startAt = matcher.end() + 1>
		<cfset candidate = patterns.candidate.matcher(text)>
		<cfset returning = patterns.returning.matcher(text)>

		<cfloop condition="scanning">
			<cfif startAt GT Len(text)>
				<cfset scanning = "false">
			<cfelseif candidate.find(JavaCast("int", startAt))>
				<cfif candidate.end() GT maxEnd>
					<cfset maxEnd = candidate.end()>
				</cfif>

				<cfset startAt = candidate.start() + 1>
			<cfelse>
				<cfset scanning = "false">
			</cfif>
		</cfloop>

		<cfif maxEnd LT 0>
			<cfreturn false>
		</cfif>

		<!--- where the last RETURNING starts, overlaps included --->
		<cfset startAt = 0>
		<cfset scanning = "true">

		<cfloop condition="scanning">
			<cfif startAt GT Len(text)>
				<cfset scanning = "false">
			<cfelseif returning.find(JavaCast("int", startAt))>
				<cfset lastReturning = returning.start()>
				<cfset startAt = lastReturning + 1>
			<cfelse>
				<cfset scanning = "false">
			</cfif>
		</cfloop>

		<cfreturn lastReturning LT maxEnd>
	</cffunction>

	<!---
	 * Returns the last error code and message.
	 *
	 * Must return a map with keys 'code' and 'message':
	 *
	 * @return array{code: int|string|null, message: string|null}
	--->
	<cffunction name="error" access="public" returntype="any" output="no">

		<cfthrow type="ColdIgniter.LogicException" message="The class does not define error().">
	</cffunction>

	<!---
	 * Insert ID
	 *
	 * @return int|string
	--->
	<cffunction name="insertID" access="public" returntype="any" output="no">

		<cfthrow type="ColdIgniter.LogicException" message="The class does not define insertID().">
	</cffunction>

	<!---
	 * Generates the SQL for listing tables in a platform-dependent manner.
	 *
	 * @param string|null $tableName If $tableName is provided will return only this table if exists.
	 *
	 * @return false|string
	--->
	<cffunction name="_listTables" access="private" returntype="any" output="no">
		<cfargument name="constrainByPrefix" type="boolean" required="no" default="false">
		<cfargument name="tableName" type="string" required="no" default="">

		<cfthrow type="ColdIgniter.LogicException" message="The class does not define _listTables().">
	</cffunction>

	<!---
	 * Generates a platform-specific query string so that the column names can be fetched.
	 *
	 * @param string|TableName $table
	 *
	 * @return false|string
	--->
	<cffunction name="_listColumns" access="private" returntype="any" output="no">
		<cfargument name="table" type="any" required="no" default="">

		<cfthrow type="ColdIgniter.LogicException" message="The class does not define _listColumns().">
	</cffunction>

	<!---
	 * Platform-specific field data information.
	 *
	 * @see getFieldData()
	 *
	 * @return list<stdClass>
	--->
	<cffunction name="_fieldData" access="private" returntype="any" output="no">
		<cfargument name="table" type="string" required="yes">

		<cfthrow type="ColdIgniter.LogicException" message="The class does not define _fieldData().">
	</cffunction>

	<!---
	 * Platform-specific index data.
	 *
	 * @see    getIndexData()
	 *
	 * @return array<string, stdClass>
	--->
	<cffunction name="_indexData" access="private" returntype="any" output="no">
		<cfargument name="table" type="string" required="yes">

		<cfthrow type="ColdIgniter.LogicException" message="The class does not define _indexData().">
	</cffunction>

	<!---
	 * Platform-specific foreign keys data.
	 *
	 * @see    getForeignKeyData()
	 *
	 * @return array<string, stdClass>
	--->
	<cffunction name="_foreignKeyData" access="private" returntype="any" output="no">
		<cfargument name="table" type="string" required="yes">

		<cfthrow type="ColdIgniter.LogicException" message="The class does not define _foreignKeyData().">
	</cffunction>

	<!---
	 * Platform-specific SQL statement to disable foreign key checks.
	 *
	 * If this feature is not supported, return empty string.
	 *
	 * @TODO This method should be moved to an interface that represents foreign key support.
	 *
	 * @return string
	 *
	 * @see disableForeignKeyChecks()
	--->
	<cffunction name="_disableForeignKeyChecks" access="private" returntype="any" output="no">

		<cfreturn "">
	</cffunction>

	<!---
	 * Platform-specific SQL statement to enable foreign key checks.
	 *
	 * If this feature is not supported, return empty string.
	 *
	 * @TODO This method should be moved to an interface that represents foreign key support.
	 *
	 * @return string
	 *
	 * @see enableForeignKeyChecks()
	--->
	<cffunction name="_enableForeignKeyChecks" access="private" returntype="any" output="no">

		<cfreturn "">
	</cffunction>

</cfcomponent>
