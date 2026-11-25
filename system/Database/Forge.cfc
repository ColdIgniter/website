<!---
 * The Forge class transforms migrations to executable
 * SQL statements.
 *
 * Difference: a boolean is the text "true" or "false" (test it with
 * identical_()), a null is an empty string, and a null that is a value in a
 * map of attributes is new_("ColdIgniter\Database\NullValue"). The result of
 * every method that gives a bool in the original is the text "true" or
 * "false".
 *
 * Difference: the original has protected methods and properties. Here a
 * protected method is private (a driver class mixes the base class in, see
 * the reference, "How components are located"), and the properties are on
 * this. The properties null and default are named null_ and default_,
 * because those names are keywords.
 *
 * Difference: the fields are a map (see array_()) of name to a map of
 * attributes, or to a string for a literal definition. The keys are a list
 * of maps, the uniqueKeys are the 0-based positions of the keys (as in the
 * original), the primaryKeys are a map that is empty when not set, and the
 * foreignKeys are a list of maps. A list is copied where the original
 * copies an array.
 *
 * Difference: sprintf() has no polyfill, so sprintf_() below puts the
 * arguments into the %s of the format, in order. A previous exception is not
 * chained (the original passes it as the third argument of the exception).
 *
 * Difference: the original reads a missing or null attribute with isset() or
 * the ?? operator. Here isset_() does the same for a map, where a null is
 * the NullValue. The empty string is a value, and is not null.
--->
<cfcomponent output="no" hint="The Forge class transforms migrations to executable SQL statements">

	<!---
	 * The active database connection.
	 *
	 * @var BaseConnection
	--->
	<cfset this.db = "">

	<!---
	 * List of fields in the form [name => attributes]
	 *
	 * @var A map of name to a map of attributes, or to a string
	--->
	<cfset this.fields = CreateObject("java", "java.util.LinkedHashMap").init()>

	<!---
	 * List of keys.
	 *
	 * @var A list of maps with fields (a list of names) and keyName
	--->
	<cfset this.keys = ArrayNew(1)>

	<!---
	 * List of unique keys.
	 *
	 * @var A list of the 0-based positions in keys
	--->
	<cfset this.uniqueKeys = ArrayNew(1)>

	<!---
	 * Primary keys.
	 *
	 * @var A map with fields (a list of names) and keyName, empty when not set
	--->
	<cfset this.primaryKeys = CreateObject("java", "java.util.LinkedHashMap").init()>

	<!---
	 * List of foreign keys.
	 *
	 * @var A list of maps with field, referenceTable, referenceField,
	 *      onDelete, onUpdate and fkName
	--->
	<cfset this.foreignKeys = ArrayNew(1)>

	<!---
	 * Character set used.
	 *
	 * @var string
	--->
	<cfset this.charset = "">

	<!---
	 * CREATE DATABASE statement
	 *
	 * @var false|string
	--->
	<cfset this.createDatabaseStr = "CREATE DATABASE %s">

	<!---
	 * CREATE DATABASE IF statement
	 *
	 * An empty string is null.
	 *
	 * @var string
	--->
	<cfset this.createDatabaseIfStr = "">

	<!---
	 * CHECK DATABASE EXIST statement
	 *
	 * An empty string is null.
	 *
	 * @var string
	--->
	<cfset this.checkDatabaseExistStr = "">

	<!---
	 * DROP DATABASE statement
	 *
	 * @var false|string
	--->
	<cfset this.dropDatabaseStr = "DROP DATABASE %s">

	<!---
	 * CREATE TABLE statement
	 *
	 * @var string
	--->
	<cfset this.createTableStr = "%s %s (%s" & Chr(10) & ")">

	<!---
	 * CREATE TABLE IF statement
	 *
	 * @var bool|string
	 *
	 * @deprecated This is no longer used.
	--->
	<cfset this.createTableIfStr = "CREATE TABLE IF NOT EXISTS">

	<!---
	 * CREATE TABLE keys flag
	 *
	 * Whether table keys are created from within the
	 * CREATE TABLE statement.
	 *
	 * @var bool
	--->
	<cfset this.createTableKeys = "false">

	<!---
	 * DROP TABLE IF EXISTS statement
	 *
	 * @var bool|string
	--->
	<cfset this.dropTableIfStr = "DROP TABLE IF EXISTS">

	<!---
	 * RENAME TABLE statement
	 *
	 * @var false|string
	--->
	<cfset this.renameTableStr = "ALTER TABLE %s RENAME TO %s">

	<!---
	 * UNSIGNED support
	 *
	 * @var A list of types, or a map of type to type, or a bool
	--->
	<cfset this.unsigned = "true">

	<!---
	 * NULL value representation in CREATE/ALTER TABLE statements
	 *
	 * @var string
	 *
	 * @internal Used for marking nullable fields. Not covered by BC promise.
	--->
	<cfset this.null_ = "NULL">

	<!---
	 * DEFAULT value representation in CREATE/ALTER TABLE statements
	 *
	 * @var false|string
	--->
	<cfset this.default_ = " DEFAULT ">

	<!---
	 * DROP CONSTRAINT statement
	 *
	 * An empty string is null.
	 *
	 * @var string
	--->
	<cfset this.dropConstraintStr = "">

	<!---
	 * DROP INDEX statement
	 *
	 * @var string
	--->
	<cfset this.dropIndexStr = "DROP INDEX %s ON %s">

	<!---
	 * Foreign Key Allowed Actions
	 *
	 * @var list<string>
	--->
	<cfset this.fkAllowActions = ArrayNew(1)>
	<cfset ArrayAppend(this.fkAllowActions, "CASCADE")>
	<cfset ArrayAppend(this.fkAllowActions, "SET NULL")>
	<cfset ArrayAppend(this.fkAllowActions, "NO ACTION")>
	<cfset ArrayAppend(this.fkAllowActions, "RESTRICT")>
	<cfset ArrayAppend(this.fkAllowActions, "SET DEFAULT")>

	<!---
	 * Constructor.
	 *
	 * @param db BaseConnection
	--->
	<cffunction name="__construct" access="public" returntype="any" output="no">
		<cfargument name="db" type="any" required="yes">

		<cfset this.db = arguments.db>

		<cfreturn this>
	</cffunction>

	<!---
	 * Provides access to the forge's current database connection.
	 *
	 * @return ConnectionInterface
	--->
	<cffunction name="getConnection" access="public" returntype="any" output="no">
		<cfreturn this.db>
	</cffunction>

	<!---
	 * Create database
	 *
	 * @param bool $ifNotExists Whether to add IF NOT EXISTS condition
	 *
	 * @throws DatabaseException
	--->
	<cffunction name="createDatabase" access="public" returntype="any" output="no">
		<cfargument name="dbName" type="string" required="yes">
		<cfargument name="ifNotExists" type="boolean" required="no" default="false">
		<cfset var ifNotExists_ = arguments.ifNotExists>
		<cfset var sql = "">
		<cfset var result = "">

		<cfif ifNotExists_ AND is_null(this.createDatabaseIfStr)>
			<cfif databaseExists(arguments.dbName)>
				<cfreturn "true">
			</cfif>

			<cfset ifNotExists_ = false>
		</cfif>

		<cfif identical_(this.createDatabaseStr, "false")>
			<cfif this.db.DBDebug>
				<cfthrow type="ColdIgniter.Database.Exceptions.DatabaseException" message="This feature is not available for the database you are using.">
			</cfif>

			<cfreturn "false"> <!--- @codeCoverageIgnore --->
		</cfif>

		<cftry>
			<cfif ifNotExists_>
				<cfset sql = sprintf_(this.createDatabaseIfStr, this.db.escapeIdentifier(arguments.dbName), this.db.charset, this.db.DBCollat)>
			<cfelse>
				<cfset sql = sprintf_(this.createDatabaseStr, this.db.escapeIdentifier(arguments.dbName), this.db.charset, this.db.DBCollat)>
			</cfif>

			<cfset result = this.db.query(sql)>

			<cfif identical_(result, "false")>
				<!--- @codeCoverageIgnoreStart --->
				<cfif this.db.DBDebug>
					<cfthrow type="ColdIgniter.Database.Exceptions.DatabaseException" message="Unable to create the specified database.">
				</cfif>

				<cfreturn "false">
				<!--- @codeCoverageIgnoreEnd --->
			</cfif>

			<cfif array_key_exists("db_names", this.db.dataCache) AND ArrayLen(this.db.dataCache["db_names"]) GT 0>
				<cfset ArrayAppend(this.db.dataCache["db_names"], arguments.dbName)>
			</cfif>

			<cfreturn "true">

			<cfcatch type="any">
				<cfif this.db.DBDebug>
					<cfthrow type="ColdIgniter.Database.Exceptions.DatabaseException" message="Unable to create the specified database.">
				</cfif>

				<cfreturn "false"> <!--- @codeCoverageIgnore --->
			</cfcatch>
		</cftry>
	</cffunction>

	<!---
	 * Determine if a database exists
	 *
	 * @throws DatabaseException
	--->
	<cffunction name="databaseExists" access="private" returntype="any" output="no">
		<cfargument name="dbName" type="string" required="yes">
		<cfset var binds = ArrayNew(1)>

		<cfif is_null(this.checkDatabaseExistStr)>
			<cfif this.db.DBDebug>
				<cfthrow type="ColdIgniter.Database.Exceptions.DatabaseException" message="This feature is not available for the database you are using.">
			</cfif>

			<cfreturn "false">
		</cfif>

		<cfset ArrayAppend(binds, arguments.dbName)>

		<cfreturn NOT is_null(this.db.query(this.checkDatabaseExistStr, binds).getRow())>
	</cffunction>

	<!---
	 * Drop database
	 *
	 * @throws DatabaseException
	--->
	<cffunction name="dropDatabase" access="public" returntype="any" output="no">
		<cfargument name="dbName" type="string" required="yes">
		<cfset var names = "">
		<cfset var i = 0>

		<cfif identical_(this.dropDatabaseStr, "false")>
			<cfif this.db.DBDebug>
				<cfthrow type="ColdIgniter.Database.Exceptions.DatabaseException" message="This feature is not available for the database you are using.">
			</cfif>

			<cfreturn "false">
		</cfif>

		<cfif identical_(this.db.query(sprintf_(this.dropDatabaseStr, this.db.escapeIdentifier(arguments.dbName))), "false")>
			<cfif this.db.DBDebug>
				<cfthrow type="ColdIgniter.Database.Exceptions.DatabaseException" message="Unable to drop the specified database.">
			</cfif>

			<cfreturn "false">
		</cfif>

		<cfif array_key_exists("db_names", this.db.dataCache) AND ArrayLen(this.db.dataCache["db_names"]) GT 0>
			<cfset names = this.db.dataCache["db_names"]>

			<cfloop from="1" to="#ArrayLen(names)#" index="i">
				<cfif Compare(LCase(names[i]), LCase(arguments.dbName)) EQ 0>
					<cfset ArrayDeleteAt(this.db.dataCache["db_names"], i)>
					<cfbreak>
				</cfif>
			</cfloop>
		</cfif>

		<cfreturn "true">
	</cffunction>

	<!---
	 * Add Key
	 *
	 * @param list<string>|string $key
	 *
	 * @return Forge
	--->
	<cffunction name="addKey" access="public" returntype="any" output="no">
		<cfargument name="key" type="any" required="yes">
		<cfargument name="primary" type="boolean" required="no" default="false">
		<cfargument name="unique" type="boolean" required="no" default="false">
		<cfargument name="keyName" type="string" required="no" default="">

		<cfif arguments.primary>
			<cfset this.primaryKeys = array_("fields", toList_(arguments.key), "keyName", arguments.keyName)>
		<cfelse>
			<cfset ArrayAppend(this.keys, array_("fields", toList_(arguments.key), "keyName", arguments.keyName))>

			<cfif arguments.unique>
				<cfset ArrayAppend(this.uniqueKeys, ArrayLen(this.keys) - 1)>
			</cfif>
		</cfif>

		<cfreturn this>
	</cffunction>

	<!---
	 * Add Primary Key
	 *
	 * @param list<string>|string $key
	 *
	 * @return Forge
	--->
	<cffunction name="addPrimaryKey" access="public" returntype="any" output="no">
		<cfargument name="key" type="any" required="yes">
		<cfargument name="keyName" type="string" required="no" default="">

		<cfreturn this.addKey(arguments.key, true, false, arguments.keyName)>
	</cffunction>

	<!---
	 * Add Unique Key
	 *
	 * @param list<string>|string $key
	 *
	 * @return Forge
	--->
	<cffunction name="addUniqueKey" access="public" returntype="any" output="no">
		<cfargument name="key" type="any" required="yes">
		<cfargument name="keyName" type="string" required="no" default="">

		<cfreturn this.addKey(arguments.key, false, true, arguments.keyName)>
	</cffunction>

	<!---
	 * Add Field
	 *
	 * @param fields A map of name to a map of attributes or to a string, or a
	 *               list of strings, or a string
	 *
	 * @return Forge
	 *
	 * Difference: a list has no names, so a map of attributes in a list is
	 * ignored (the original gives it the number as its name).
	--->
	<cffunction name="addField" access="public" returntype="any" output="no">
		<cfargument name="fields" type="any" required="yes">
		<cfset var id = "">
		<cfset var fieldName = "">
		<cfset var parts = "">
		<cfset var names = "">
		<cfset var name = "">
		<cfset var attributes = "">
		<cfset var i = 0>

		<cfif IsSimpleValue(arguments.fields)>
			<cfif Compare(arguments.fields, "id") EQ 0>
				<cfset id = array_("id", array_("type", "INT", "constraint", 9, "auto_increment", "true"))>
				<cfset this.addField(id)>
				<cfset this.addKey("id", true)>
			<cfelse>
				<cfif Find(" ", arguments.fields) EQ 0>
					<cfthrow type="ColdIgniter.Exceptions.InvalidArgumentException" message="Field information is required for that operation.">
				</cfif>

				<cfset parts = explode(" ", arguments.fields, 2)>
				<cfset fieldName = parts[1]>
				<cfset fieldName = trim_(fieldName, "`'""")>

				<cfset this.fields[fieldName] = arguments.fields>
			</cfif>
		</cfif>

		<cfif is_array(arguments.fields)>
			<cfif IsArray(arguments.fields)>
				<cfloop from="1" to="#ArrayLen(arguments.fields)#" index="i">
					<cfif IsSimpleValue(arguments.fields[i])>
						<cfset this.addField(arguments.fields[i])>
					</cfif>
				</cfloop>
			<cfelse>
				<cfset names = array_keys(arguments.fields)>

				<cfloop from="1" to="#ArrayLen(names)#" index="i">
					<cfset name = names[i]>
					<cfset attributes = arguments.fields[name]>

					<cfif IsSimpleValue(attributes)>
						<cfset this.addField(attributes)>
					<cfelseif is_array(attributes)>
						<cfset this.fields[name] = attributes>
					</cfif>
				</cfloop>
			</cfif>
		</cfif>

		<cfreturn this>
	</cffunction>

	<!---
	 * Add Foreign Key
	 *
	 * @param list<string>|string $fieldName
	 * @param list<string>|string $tableField
	 *
	 * @throws DatabaseException
	--->
	<cffunction name="addForeignKey" access="public" returntype="any" output="no">
		<cfargument name="fieldName" type="any" required="no" default="">
		<cfargument name="tableName" type="string" required="no" default="">
		<cfargument name="tableField" type="any" required="no" default="">
		<cfargument name="onUpdate" type="string" required="no" default="">
		<cfargument name="onDelete" type="string" required="no" default="">
		<cfargument name="fkName" type="string" required="no" default="">

		<cfset ArrayAppend(this.foreignKeys, array_(
			"field", toList_(arguments.fieldName),
			"referenceTable", arguments.tableName,
			"referenceField", toList_(arguments.tableField),
			"onDelete", UCase(arguments.onDelete),
			"onUpdate", UCase(arguments.onUpdate),
			"fkName", arguments.fkName
		))>

		<cfreturn this>
	</cffunction>

	<!---
	 * Drop Key
	 *
	 * @throws DatabaseException
	--->
	<cffunction name="dropKey" access="public" returntype="any" output="no">
		<cfargument name="table" type="string" required="yes">
		<cfargument name="keyName" type="string" required="yes">
		<cfargument name="prefixKeyName" type="boolean" required="no" default="true">
		<cfset var keyName_ = "">
		<cfset var table_ = "">
		<cfset var dropKeyAsConstraint_ = "">
		<cfset var sql = "">

		<cfif arguments.prefixKeyName>
			<cfset keyName_ = this.db.escapeIdentifiers(this.db.DBPrefix & arguments.keyName)>
		<cfelse>
			<cfset keyName_ = this.db.escapeIdentifiers(arguments.keyName)>
		</cfif>

		<cfset table_ = this.db.escapeIdentifiers(this.db.DBPrefix & arguments.table)>

		<cfset dropKeyAsConstraint_ = dropKeyAsConstraint(table_, keyName_)>

		<cfif dropKeyAsConstraint_>
			<cfset sql = sprintf_(this.dropConstraintStr, table_, keyName_)>
		<cfelse>
			<cfset sql = sprintf_(this.dropIndexStr, keyName_, table_)>
		</cfif>

		<cfif Compare(sql, "") EQ 0>
			<cfif this.db.DBDebug>
				<cfthrow type="ColdIgniter.Database.Exceptions.DatabaseException" message="This feature is not available for the database you are using.">
			</cfif>

			<cfreturn "false">
		</cfif>

		<cfreturn succeeded_(this.db.query(sql))>
	</cffunction>

	<!---
	 * Checks if key needs to be dropped as a constraint.
	--->
	<cffunction name="dropKeyAsConstraint" access="private" returntype="boolean" output="no">
		<cfargument name="table" type="string" required="yes">
		<cfargument name="constraintName" type="string" required="yes">
		<cfset var sql = _dropKeyAsConstraint(arguments.table, arguments.constraintName)>

		<cfif Compare(sql, "") EQ 0>
			<cfreturn false>
		</cfif>

		<cfreturn ArrayLen(this.db.query(sql).getResultArray()) GT 0>
	</cffunction>

	<!---
	 * Constructs sql to check if key is a constraint.
	--->
	<cffunction name="_dropKeyAsConstraint" access="private" returntype="string" output="no">
		<cfargument name="table" type="string" required="yes">
		<cfargument name="constraintName" type="string" required="yes">

		<cfreturn "">
	</cffunction>

	<!---
	 * Drop Primary Key
	--->
	<cffunction name="dropPrimaryKey" access="public" returntype="any" output="no">
		<cfargument name="table" type="string" required="yes">
		<cfargument name="keyName" type="string" required="no" default="">
		<cfset var keyName_ = "">
		<cfset var sql = "">

		<cfif Compare(arguments.keyName, "") EQ 0>
			<cfset keyName_ = this.db.escapeIdentifiers("pk_" & this.db.DBPrefix & arguments.table)>
		<cfelse>
			<cfset keyName_ = this.db.escapeIdentifiers(arguments.keyName)>
		</cfif>

		<cfset sql = sprintf_("ALTER TABLE %s DROP CONSTRAINT %s", this.db.escapeIdentifiers(this.db.DBPrefix & arguments.table), keyName_)>

		<cfreturn succeeded_(this.db.query(sql))>
	</cffunction>

	<!---
	 * @return bool
	 *
	 * @throws DatabaseException
	--->
	<cffunction name="dropForeignKey" access="public" returntype="any" output="no">
		<cfargument name="table" type="string" required="yes">
		<cfargument name="foreignName" type="string" required="yes">
		<cfset var sql = sprintf_(this.dropConstraintStr, this.db.escapeIdentifiers(this.db.DBPrefix & arguments.table), this.db.escapeIdentifiers(arguments.foreignName))>

		<cfif Compare(sql, "") EQ 0>
			<cfif this.db.DBDebug>
				<cfthrow type="ColdIgniter.Database.Exceptions.DatabaseException" message="This feature is not available for the database you are using.">
			</cfif>

			<cfreturn "false">
		</cfif>

		<cfreturn succeeded_(this.db.query(sql))>
	</cffunction>

	<!---
	 * @param array<string, mixed> $attributes Table attributes (a map)
	 *
	 * @return bool
	 *
	 * @throws DatabaseException
	 *
	 * Difference: the result is "true" or "false", where the original gives
	 * what the query gives.
	--->
	<cffunction name="createTable" access="public" returntype="any" output="no">
		<cfargument name="table" type="string" required="yes">
		<cfargument name="ifNotExists" type="boolean" required="no" default="false">
		<cfargument name="attributes" type="any" required="no" default="">
		<cfset var table_ = "">
		<cfset var attributes_ = arguments.attributes>
		<cfset var sql = "">
		<cfset var result = "">
		<cfset var sqls = "">
		<cfset var i = 0>

		<cfif Compare(arguments.table, "") EQ 0>
			<cfthrow type="ColdIgniter.Exceptions.InvalidArgumentException" message="A table name is required for that operation.">
		</cfif>

		<cfif NOT is_array(attributes_)>
			<cfset attributes_ = array_()>
		</cfif>

		<cfset table_ = this.db.DBPrefix & arguments.table>

		<cfif StructCount(this.fields) EQ 0>
			<cfthrow type="ColdIgniter.Exceptions.RuntimeException" message="Field information is required.">
		</cfif>

		<!--- If table exists lets stop here --->
		<cfif arguments.ifNotExists AND this.db.tableExists(table_, false)>
			<cfset this.reset()>

			<cfreturn "true">
		</cfif>

		<cfset sql = _createTable(table_, false, attributes_)>

		<cfset result = this.db.query(sql)>

		<cfif NOT identical_(result, "false")>
			<cfif array_key_exists("table_names", this.db.dataCache) AND NOT in_array(table_, this.db.dataCache["table_names"])>
				<cfset ArrayAppend(this.db.dataCache["table_names"], table_)>
			</cfif>

			<!--- Most databases don't support creating indexes from within the CREATE TABLE statement --->
			<cfif ArrayLen(this.keys) GT 0>
				<cfset sqls = _processIndexes(table_)>

				<cfloop from="1" to="#ArrayLen(sqls)#" index="i">
					<cfset this.db.query(sqls[i])>
				</cfloop>
			</cfif>
		</cfif>

		<cfset this.reset()>

		<cfreturn succeeded_(result)>
	</cffunction>

	<!---
	 * @param array<string, mixed> $attributes Table attributes (a map)
	 *
	 * @return string SQL string
	 *
	 * @deprecated $ifNotExists is no longer used, and will be removed.
	--->
	<cffunction name="_createTable" access="private" returntype="string" output="no">
		<cfargument name="table" type="string" required="yes">
		<cfargument name="ifNotExists" type="boolean" required="yes">
		<cfargument name="attributes" type="any" required="yes">
		<cfset var processedFields = _processFields(true)>
		<cfset var definitions = ArrayNew(1)>
		<cfset var joined = "">
		<cfset var foreign = "">
		<cfset var indexes = "">
		<cfset var i = 0>

		<cfloop from="1" to="#ArrayLen(processedFields)#" index="i">
			<cfif NOT identical_(processedFields[i]["_literal"], "false")>
				<cfset ArrayAppend(definitions, Chr(10) & Chr(9) & processedFields[i]["_literal"])>
			<cfelse>
				<cfset ArrayAppend(definitions, Chr(10) & Chr(9) & _processColumn(processedFields[i]))>
			</cfif>
		</cfloop>

		<cfset joined = implode(",", definitions)>

		<cfset joined = joined & _processPrimaryKeys(arguments.table)>

		<cfset foreign = _processForeignKeys(arguments.table)>
		<cfset joined = joined & foreign[1]>

		<cfif isTrue_(this.createTableKeys)>
			<cfset indexes = _processIndexes(arguments.table)>

			<cfif ArrayLen(indexes) GT 0>
				<cfset joined = joined & indexes[1]>
			</cfif>
		</cfif>

		<cfreturn sprintf_(this.createTableStr & "%s", "CREATE TABLE", this.db.escapeIdentifiers(arguments.table), joined, _createTableAttributes(arguments.attributes))>
	</cffunction>

	<!---
	 * @param array<string, mixed> $attributes A map
	--->
	<cffunction name="_createTableAttributes" access="private" returntype="string" output="no">
		<cfargument name="attributes" type="any" required="yes">
		<cfset var sql = "">
		<cfset var keys = array_keys(arguments.attributes)>
		<cfset var i = 0>

		<cfloop from="1" to="#ArrayLen(keys)#" index="i">
			<cfset sql = sql & " " & UCase(keys[i]) & " " & this.db.escape(arguments.attributes[keys[i]])>
		</cfloop>

		<cfreturn sql>
	</cffunction>

	<!---
	 * @return bool
	 *
	 * @throws DatabaseException
	 *
	 * Difference: the result is "true" or "false", where the original gives
	 * what the query gives.
	--->
	<cffunction name="dropTable" access="public" returntype="any" output="no">
		<cfargument name="tableName" type="string" required="yes">
		<cfargument name="ifExists" type="boolean" required="no" default="false">
		<cfargument name="cascade" type="boolean" required="no" default="false">
		<cfset var tableName_ = arguments.tableName>
		<cfset var query = "">
		<cfset var names = "">
		<cfset var i = 0>

		<cfif Compare(tableName_, "") EQ 0>
			<cfif this.db.DBDebug>
				<cfthrow type="ColdIgniter.Database.Exceptions.DatabaseException" message="A table name is required for that operation.">
			</cfif>

			<cfreturn "false">
		</cfif>

		<cfif Compare(this.db.DBPrefix, "") NEQ 0 AND str_starts_with(tableName_, this.db.DBPrefix)>
			<cfset tableName_ = substr(tableName_, Len(this.db.DBPrefix))>
		</cfif>

		<cfset query = _dropTable(this.db.DBPrefix & tableName_, arguments.ifExists, arguments.cascade)>

		<cfif identical_(query, "true")>
			<cfreturn "true">
		</cfif>

		<cfset this.db.disableForeignKeyChecks()>

		<cfset query = this.db.query(query)>

		<cfset this.db.enableForeignKeyChecks()>

		<cfif NOT identical_(query, "false") AND array_key_exists("table_names", this.db.dataCache) AND ArrayLen(this.db.dataCache["table_names"]) GT 0>
			<cfset names = this.db.dataCache["table_names"]>

			<cfloop from="1" to="#ArrayLen(names)#" index="i">
				<cfif Compare(LCase(names[i]), LCase(this.db.DBPrefix & tableName_)) EQ 0>
					<cfset ArrayDeleteAt(this.db.dataCache["table_names"], i)>
					<cfbreak>
				</cfif>
			</cfloop>
		</cfif>

		<cfreturn succeeded_(query)>
	</cffunction>

	<!---
	 * Generates a platform-specific DROP TABLE string
	 *
	 * @return bool|string
	--->
	<cffunction name="_dropTable" access="private" returntype="any" output="no">
		<cfargument name="table" type="string" required="yes">
		<cfargument name="ifExists" type="boolean" required="yes">
		<cfargument name="cascade" type="boolean" required="yes">
		<cfset var sql = "DROP TABLE">

		<cfif arguments.ifExists>
			<cfif identical_(this.dropTableIfStr, "false")>
				<cfif NOT this.db.tableExists(arguments.table)>
					<cfreturn "true">
				</cfif>
			<cfelse>
				<cfset sql = sprintf_(this.dropTableIfStr, this.db.escapeIdentifiers(arguments.table))>
			</cfif>
		</cfif>

		<cfreturn sql & " " & this.db.escapeIdentifiers(arguments.table)>
	</cffunction>

	<!---
	 * @return bool
	 *
	 * @throws DatabaseException
	 *
	 * Difference: the result is "true" or "false", where the original gives
	 * what the query gives.
	--->
	<cffunction name="renameTable" access="public" returntype="any" output="no">
		<cfargument name="tableName" type="string" required="yes">
		<cfargument name="newTableName" type="string" required="yes">
		<cfset var result = "">
		<cfset var names = "">
		<cfset var i = 0>

		<cfif Compare(arguments.tableName, "") EQ 0 OR Compare(arguments.newTableName, "") EQ 0>
			<cfthrow type="ColdIgniter.Exceptions.InvalidArgumentException" message="A table name is required for that operation.">
		</cfif>

		<cfif identical_(this.renameTableStr, "false")>
			<cfif this.db.DBDebug>
				<cfthrow type="ColdIgniter.Database.Exceptions.DatabaseException" message="This feature is not available for the database you are using.">
			</cfif>

			<cfreturn "false">
		</cfif>

		<cfset result = this.db.query(sprintf_(this.renameTableStr, this.db.escapeIdentifiers(this.db.DBPrefix & arguments.tableName), this.db.escapeIdentifiers(this.db.DBPrefix & arguments.newTableName)))>

		<cfif NOT identical_(result, "false") AND array_key_exists("table_names", this.db.dataCache) AND ArrayLen(this.db.dataCache["table_names"]) GT 0>
			<cfset names = this.db.dataCache["table_names"]>

			<cfloop from="1" to="#ArrayLen(names)#" index="i">
				<cfif Compare(LCase(names[i]), LCase(this.db.DBPrefix & arguments.tableName)) EQ 0>
					<cfset this.db.dataCache["table_names"][i] = this.db.DBPrefix & arguments.newTableName>
					<cfbreak>
				</cfif>
			</cfloop>
		</cfif>

		<cfreturn succeeded_(result)>
	</cffunction>

	<!---
	 * @param fields A map of name to a map of attributes or to a string, or a
	 *               list of strings, or a string
	 *
	 * @throws DatabaseException
	--->
	<cffunction name="addColumn" access="public" returntype="any" output="no">
		<cfargument name="table" type="string" required="yes">
		<cfargument name="fields" type="any" required="yes">
		<cfset var fields_ = arguments.fields>
		<cfset var names = "">
		<cfset var sqls = "">
		<cfset var i = 0>

		<!--- Work-around for literal column definitions --->
		<cfif IsSimpleValue(fields_)>
			<cfset fields_ = ArrayNew(1)>
			<cfset ArrayAppend(fields_, arguments.fields)>
		</cfif>

		<cfif IsArray(fields_)>
			<!--- Difference: a list has no names, see addField() --->
			<cfloop from="1" to="#ArrayLen(fields_)#" index="i">
				<cfset this.addField(fields_[i])>
			</cfloop>
		<cfelse>
			<cfset names = array_keys(fields_)>

			<cfloop from="1" to="#ArrayLen(names)#" index="i">
				<cfset this.addField(array_(names[i], fields_[names[i]]))>
			</cfloop>
		</cfif>

		<cfset sqls = _alterTable("ADD", this.db.DBPrefix & arguments.table, _processFields())>
		<cfset this.reset()>

		<cfif identical_(sqls, "false")>
			<cfif this.db.DBDebug>
				<cfthrow type="ColdIgniter.Database.Exceptions.DatabaseException" message="This feature is not available for the database you are using.">
			</cfif>

			<cfreturn "false">
		</cfif>

		<cfloop from="1" to="#ArrayLen(sqls)#" index="i">
			<cfif identical_(this.db.query(sqls[i]), "false")>
				<cfreturn "false">
			</cfif>
		</cfloop>

		<cfreturn "true">
	</cffunction>

	<!---
	 * @param list<string>|string $columnNames column names to DROP
	 *
	 * @return bool
	 *
	 * @throws DatabaseException
	 *
	 * Difference: the result is "true" or "false", where the original gives
	 * what the query gives.
	--->
	<cffunction name="dropColumn" access="public" returntype="any" output="no">
		<cfargument name="table" type="string" required="yes">
		<cfargument name="columnNames" type="any" required="yes">
		<cfset var sql = _alterTable("DROP", this.db.DBPrefix & arguments.table, arguments.columnNames)>

		<cfif identical_(sql, "false")>
			<cfif this.db.DBDebug>
				<cfthrow type="ColdIgniter.Database.Exceptions.DatabaseException" message="This feature is not available for the database you are using.">
			</cfif>

			<cfreturn "false">
		</cfif>

		<cfreturn succeeded_(this.db.query(sql))>
	</cffunction>

	<!---
	 * @param fields A map of name to a map of attributes or to a string, or a
	 *               list of strings, or a string
	 *
	 * @throws DatabaseException
	--->
	<cffunction name="modifyColumn" access="public" returntype="any" output="no">
		<cfargument name="table" type="string" required="yes">
		<cfargument name="fields" type="any" required="yes">
		<cfset var fields_ = arguments.fields>
		<cfset var names = "">
		<cfset var sqls = "">
		<cfset var i = 0>

		<!--- Work-around for literal column definitions --->
		<cfif IsSimpleValue(fields_)>
			<cfset fields_ = ArrayNew(1)>
			<cfset ArrayAppend(fields_, arguments.fields)>
		</cfif>

		<cfif IsArray(fields_)>
			<!--- Difference: a list has no names, see addField() --->
			<cfloop from="1" to="#ArrayLen(fields_)#" index="i">
				<cfset this.addField(fields_[i])>
			</cfloop>
		<cfelse>
			<cfset names = array_keys(fields_)>

			<cfloop from="1" to="#ArrayLen(names)#" index="i">
				<cfset this.addField(array_(names[i], fields_[names[i]]))>
			</cfloop>
		</cfif>

		<cfif StructCount(this.fields) EQ 0>
			<cfthrow type="ColdIgniter.Exceptions.RuntimeException" message="Field information is required">
		</cfif>

		<cfset sqls = _alterTable("CHANGE", this.db.DBPrefix & arguments.table, _processFields())>
		<cfset this.reset()>

		<cfif identical_(sqls, "false")>
			<cfif this.db.DBDebug>
				<cfthrow type="ColdIgniter.Database.Exceptions.DatabaseException" message="This feature is not available for the database you are using.">
			</cfif>

			<cfreturn "false">
		</cfif>

		<cfif IsArray(sqls)>
			<cfloop from="1" to="#ArrayLen(sqls)#" index="i">
				<cfif identical_(this.db.query(sqls[i]), "false")>
					<cfreturn "false">
				</cfif>
			</cfloop>
		</cfif>

		<cfreturn "true">
	</cffunction>

	<!---
	 * @param 'ADD'|'CHANGE'|'DROP' $alterType
	 * @param processedFields A list of the maps of the processed column
	 *                        definitions, or the column names to DROP (a list
	 *                        or a string)
	 *
	 * @return A string for DROP, else "false" or a list of strings
	--->
	<cffunction name="_alterTable" access="private" returntype="any" output="no">
		<cfargument name="alterType" type="string" required="yes">
		<cfargument name="table" type="string" required="yes">
		<cfargument name="processedFields" type="any" required="yes">
		<cfset var sql = "ALTER TABLE " & this.db.escapeIdentifiers(arguments.table) & " ">
		<cfset var columnNamesToDrop = "">
		<cfset var sqls = ArrayNew(1)>
		<cfset var field = "">
		<cfset var i = 0>

		<!--- DROP has everything it needs now. --->
		<cfif Compare(arguments.alterType, "DROP") EQ 0>
			<cfset columnNamesToDrop = arguments.processedFields>

			<cfif IsSimpleValue(columnNamesToDrop)>
				<cfset columnNamesToDrop = explode(",", columnNamesToDrop)>
			</cfif>

			<cfset sqls = ArrayNew(1)>

			<cfloop from="1" to="#ArrayLen(columnNamesToDrop)#" index="i">
				<cfset ArrayAppend(sqls, "DROP COLUMN " & this.db.escapeIdentifiers(Trim(columnNamesToDrop[i])))>
			</cfloop>

			<cfreturn sql & implode(", ", sqls)>
		</cfif>

		<cfif Compare(arguments.alterType, "ADD") EQ 0>
			<cfset sql = sql & "ADD ">
		<cfelse>
			<cfset sql = sql & arguments.alterType & " COLUMN ">
		</cfif>

		<cfloop from="1" to="#ArrayLen(arguments.processedFields)#" index="i">
			<cfset field = arguments.processedFields[i]>

			<cfif NOT identical_(field["_literal"], "false")>
				<cfset ArrayAppend(sqls, sql & field["_literal"])>
			<cfelse>
				<cfset ArrayAppend(sqls, sql & _processColumn(field))>
			</cfif>
		</cfloop>

		<cfreturn sqls>
	</cffunction>

	<!---
	 * Returns $processedFields array from $this->fields data.
	 *
	 * @return A list of maps
	 *
	 * Difference: the keys of the attributes are upper-cased into a new map,
	 * as array_change_key_case() does, and the type and the new_name of a
	 * field are an empty string where the original has null.
	--->
	<cffunction name="_processFields" access="private" returntype="any" output="no">
		<cfargument name="createTable" type="boolean" required="no" default="false">
		<cfset var processedFields = ArrayNew(1)>
		<cfset var names = array_keys(this.fields)>
		<cfset var name = "">
		<cfset var item = "">
		<cfset var attributes = "">
		<cfset var attributeKeys = "">
		<cfset var field = "">
		<cfset var nullString = "">
		<cfset var constraint = "">
		<cfset var skip = false>
		<cfset var newName = "">
		<cfset var type = "">
		<cfset var i = 0>
		<cfset var j = 0>

		<cfloop from="1" to="#ArrayLen(names)#" index="i">
			<cfset name = names[i]>
			<cfset item = this.fields[name]>

			<cfif NOT is_array(item)>
				<cfset ArrayAppend(processedFields, array_("_literal", item))>
			<cfelse>
				<cfset attributes = array_()>
				<cfset attributeKeys = array_keys(item)>

				<cfloop from="1" to="#ArrayLen(attributeKeys)#" index="j">
					<cfset attributes[UCase(attributeKeys[j])] = item[attributeKeys[j]]>
				</cfloop>

				<cfset skip = false>

				<cfif arguments.createTable>
					<cfif NOT isset_(attributes, "TYPE")>
						<cfset skip = true>
					<cfelseif Compare(attributes["TYPE"], "") EQ 0>
						<cfset skip = true>
					</cfif>
				</cfif>

				<cfif NOT skip>
					<cfif isset_(attributes, "TYPE")>
						<cfset _attributeType(attributes)>
					</cfif>

					<cfset newName = "">
					<cfset type = "">

					<cfif isset_(attributes, "NAME")>
						<cfset newName = attributes["NAME"]>
					</cfif>

					<cfif isset_(attributes, "TYPE")>
						<cfset type = attributes["TYPE"]>
					</cfif>

					<cfset field = array_(
						"name", name,
						"new_name", newName,
						"type", type,
						"length", "",
						"unsigned", "",
						"null", "",
						"unique", "",
						"default", "",
						"auto_increment", "",
						"_literal", "false"
					)>

					<cfif isset_(attributes, "TYPE")>
						<cfset _attributeUnsigned(attributes, field)>
					</cfif>

					<cfif NOT arguments.createTable>
						<cfif isset_(attributes, "AFTER")>
							<cfset field["after"] = attributes["AFTER"]>
						<cfelseif isset_(attributes, "FIRST")>
							<!--- Difference: the original casts to bool, so 1 is true there; here only true and "true" are (see isTrue_) --->
							<cfif isTrue_(attributes["FIRST"])>
								<cfset field["first"] = "true">
							<cfelse>
								<cfset field["first"] = "false">
							</cfif>
						</cfif>
					</cfif>

					<cfset _attributeDefault(attributes, field)>

					<cfif isset_(attributes, "NULL")>
						<cfset nullString = " " & this.null_>

						<cfif isTrue_(attributes["NULL"])>
							<cfif Compare(this.null_, "") EQ 0>
								<cfset field["null"] = "">
							<cfelse>
								<cfset field["null"] = nullString>
							</cfif>
						<cfelseif identical_(attributes["NULL"], nullString)>
							<cfset field["null"] = nullString>
						<cfelseif identical_(attributes["NULL"], "")>
							<cfset field["null"] = "">
						<cfelse>
							<cfset field["null"] = " NOT " & this.null_>
						</cfif>
					<cfelseif arguments.createTable>
						<cfset field["null"] = " NOT " & this.null_>
					</cfif>

					<cfset _attributeAutoIncrement(attributes, field)>
					<cfset _attributeUnique(attributes, field)>

					<cfif isset_(attributes, "COMMENT")>
						<cfset field["comment"] = this.db.escape(attributes["COMMENT"])>
					</cfif>

					<cfif isset_(attributes, "TYPE") AND isset_(attributes, "CONSTRAINT")>
						<cfset constraint = attributes["CONSTRAINT"]>

						<cfif IsArray(constraint)>
							<cfif ArrayLen(constraint) GT 0>
								<cfset attributes["CONSTRAINT"] = implode(",", this.db.escape(constraint))>
								<cfset field["length"] = "(" & attributes["CONSTRAINT"] & ")">
							</cfif>
						<cfelseif IsSimpleValue(constraint) AND Compare(constraint, "") NEQ 0 AND Compare(constraint, "0") NEQ 0>
							<cfset field["length"] = "(" & constraint & ")">
						</cfif>
					</cfif>

					<cfset ArrayAppend(processedFields, field)>
				</cfif>
			</cfif>
		</cfloop>

		<cfreturn processedFields>
	</cffunction>

	<!---
	 * Converts $processedField array to field definition string.
	 *
	 * @param array<string, mixed> $processedField A map
	--->
	<cffunction name="_processColumn" access="private" returntype="string" output="no">
		<cfargument name="processedField" type="any" required="yes">

		<cfreturn this.db.escapeIdentifiers(arguments.processedField["name"])
			& " " & arguments.processedField["type"] & arguments.processedField["length"]
			& arguments.processedField["unsigned"]
			& arguments.processedField["default"]
			& arguments.processedField["null"]
			& arguments.processedField["auto_increment"]
			& arguments.processedField["unique"]>
	</cffunction>

	<!---
	 * Performs a data type mapping between different databases.
	 *
	 * @param array<string, mixed> $attributes A map, changed in place
	 *
	 * @return void
	--->
	<cffunction name="_attributeType" access="private" returntype="void" output="no">
		<cfargument name="attributes" type="any" required="yes">

		<!--- Usually overridden by drivers --->
	</cffunction>

	<!---
	 * Depending on the unsigned property value:
	 *
	 *    - TRUE will always set $field['unsigned'] to 'UNSIGNED'
	 *    - FALSE will always set $field['unsigned'] to ''
	 *    - array(TYPE) will set $field['unsigned'] to 'UNSIGNED',
	 *        if $attributes['TYPE'] is found in the array
	 *    - array(TYPE => UTYPE) will change $field['type'],
	 *        from TYPE to UTYPE in case of a match
	 *
	 * @param array<string, mixed> $attributes A map, changed in place
	 * @param array<string, mixed> $field      A map, changed in place
	 *
	 * @return void
	--->
	<cffunction name="_attributeUnsigned" access="private" returntype="void" output="no">
		<cfargument name="attributes" type="any" required="yes">
		<cfargument name="field" type="any" required="yes">
		<cfset var keys = "">
		<cfset var i = 0>

		<cfif NOT isset_(arguments.attributes, "UNSIGNED") OR NOT isTrue_(arguments.attributes["UNSIGNED"])>
			<cfreturn>
		</cfif>

		<!--- Reset the attribute in order to avoid issues if we do type conversion --->
		<cfset arguments.attributes["UNSIGNED"] = "false">

		<cfif is_array(this.unsigned)>
			<cfif IsArray(this.unsigned)>
				<!--- a list: the keys of the original are numbers --->
				<cfloop from="1" to="#ArrayLen(this.unsigned)#" index="i">
					<cfif CompareNoCase(arguments.attributes["TYPE"], this.unsigned[i]) EQ 0>
						<cfset arguments.field["unsigned"] = " UNSIGNED">

						<cfreturn>
					</cfif>
				</cfloop>
			<cfelse>
				<!--- a map: the keys of the original are strings --->
				<cfset keys = array_keys(this.unsigned)>

				<cfloop from="1" to="#ArrayLen(keys)#" index="i">
					<cfif CompareNoCase(arguments.attributes["TYPE"], keys[i]) EQ 0>
						<cfset arguments.field["type"] = keys[i]>

						<cfreturn>
					</cfif>
				</cfloop>
			</cfif>

			<cfreturn>
		</cfif>

		<cfif isTrue_(this.unsigned)>
			<cfset arguments.field["unsigned"] = " UNSIGNED">
		<cfelse>
			<cfset arguments.field["unsigned"] = "">
		</cfif>
	</cffunction>

	<!---
	 * @param array<string, mixed> $attributes A map, changed in place
	 * @param array<string, mixed> $field      A map, changed in place
	 *
	 * @return void
	--->
	<cffunction name="_attributeDefault" access="private" returntype="void" output="no">
		<cfargument name="attributes" type="any" required="yes">
		<cfargument name="field" type="any" required="yes">
		<cfset var value = "">

		<cfif identical_(this.default_, "false")>
			<cfreturn>
		</cfif>

		<cfif array_key_exists("DEFAULT", arguments.attributes)>
			<cfset value = arguments.attributes["DEFAULT"]>

			<cfif instanceof_(value, "ColdIgniter\Database\NullValue")>
				<cfif Compare(this.null_, "") EQ 0>
					<cfset arguments.field["default"] = "">
				<cfelse>
					<cfset arguments.field["default"] = this.default_ & this.null_>
				</cfif>

				<!--- Override the NULL attribute if that's our default --->
				<cfset arguments.attributes["NULL"] = "true">

				<cfif Compare(this.null_, "") EQ 0>
					<cfset arguments.field["null"] = "">
				<cfelse>
					<cfset arguments.field["null"] = " " & this.null_>
				</cfif>
			<cfelseif instanceof_(value, "ColdIgniter\Database\RawSql")>
				<cfset arguments.field["default"] = this.default_ & value.__toString()>
			<cfelse>
				<cfset arguments.field["default"] = this.default_ & this.db.escape(value)>
			</cfif>
		</cfif>
	</cffunction>

	<!---
	 * @param array<string, mixed> $attributes A map, changed in place
	 * @param array<string, mixed> $field      A map, changed in place
	 *
	 * @return void
	--->
	<cffunction name="_attributeUnique" access="private" returntype="void" output="no">
		<cfargument name="attributes" type="any" required="yes">
		<cfargument name="field" type="any" required="yes">

		<cfif isset_(arguments.attributes, "UNIQUE") AND isTrue_(arguments.attributes["UNIQUE"])>
			<cfset arguments.field["unique"] = " UNIQUE">
		</cfif>
	</cffunction>

	<!---
	 * @param array<string, mixed> $attributes A map, changed in place
	 * @param array<string, mixed> $field      A map, changed in place
	 *
	 * @return void
	--->
	<cffunction name="_attributeAutoIncrement" access="private" returntype="void" output="no">
		<cfargument name="attributes" type="any" required="yes">
		<cfargument name="field" type="any" required="yes">

		<cfif isset_(arguments.attributes, "AUTO_INCREMENT") AND isTrue_(arguments.attributes["AUTO_INCREMENT"]) AND Find("int", LCase(arguments.field["type"])) GT 0>
			<cfset arguments.field["auto_increment"] = " AUTO_INCREMENT">
		</cfif>
	</cffunction>

	<!---
	 * Generates SQL to add primary key
	 *
	 * @param bool $asQuery When true returns stand alone SQL, else partial SQL used with CREATE TABLE
	--->
	<cffunction name="_processPrimaryKeys" access="private" returntype="string" output="no">
		<cfargument name="table" type="string" required="yes">
		<cfargument name="asQuery" type="boolean" required="no" default="false">
		<cfset var sql = "">
		<cfset var keyName = "">
		<cfset var i = 0>

		<cfif array_key_exists("fields", this.primaryKeys)>
			<!--- Difference: from the end, so the numbers of the other fields stay the same --->
			<cfloop from="#ArrayLen(this.primaryKeys['fields'])#" to="1" index="i" step="-1">
				<cfif NOT array_key_exists(this.primaryKeys["fields"][i], this.fields)>
					<cfset ArrayDeleteAt(this.primaryKeys["fields"], i)>
				</cfif>
			</cfloop>
		</cfif>

		<cfif array_key_exists("fields", this.primaryKeys) AND ArrayLen(this.primaryKeys["fields"]) GT 0>
			<cfif arguments.asQuery>
				<cfset sql = sql & "ALTER TABLE " & this.db.escapeIdentifiers(this.db.DBPrefix & arguments.table) & " ADD ">
			<cfelse>
				<cfset sql = sql & "," & Chr(10) & Chr(9)>
			</cfif>

			<cfif Compare(this.primaryKeys["keyName"], "") EQ 0>
				<cfset keyName = "pk_" & arguments.table>
			<cfelse>
				<cfset keyName = this.primaryKeys["keyName"]>
			</cfif>

			<cfset sql = sql & "CONSTRAINT " & this.db.escapeIdentifiers(keyName)
				& " PRIMARY KEY(" & implode(", ", this.db.escapeIdentifiers(this.primaryKeys["fields"])) & ")">
		</cfif>

		<cfreturn sql>
	</cffunction>

	<!---
	 * Executes Sql to add indexes without createTable
	 *
	 * Difference: the fields and the foreign keys are kept as they are (they
	 * are not copies), as nothing between the save and the restore changes
	 * them.
	--->
	<cffunction name="processIndexes" access="public" returntype="any" output="no">
		<cfargument name="table" type="string" required="yes">
		<cfset var sqls = ArrayNew(1)>
		<cfset var fk = this.foreignKeys>
		<cfset var fieldData = "">
		<cfset var fields = "">
		<cfset var more = "">
		<cfset var i = 0>

		<cfif StructCount(this.fields) EQ 0>
			<cfset fieldData = this.db.getFieldData(this.db.DBPrefix & arguments.table)>

			<cfloop from="1" to="#ArrayLen(fieldData)#" index="i">
				<cfset this.fields[fieldData[i]["name"]] = array_()>
			</cfloop>
		</cfif>

		<cfset fields = this.fields>

		<cfif ArrayLen(this.keys) GT 0>
			<cfset sqls = _processIndexes(this.db.DBPrefix & arguments.table, true)>
		</cfif>

		<cfif StructCount(this.primaryKeys) GT 0>
			<cfset ArrayAppend(sqls, _processPrimaryKeys(arguments.table, true))>
		</cfif>

		<cfset this.foreignKeys = fk>
		<cfset this.fields = fields>

		<cfif ArrayLen(this.foreignKeys) GT 0>
			<cfset more = _processForeignKeys(arguments.table, true)>

			<cfloop from="1" to="#ArrayLen(more)#" index="i">
				<cfset ArrayAppend(sqls, more[i])>
			</cfloop>
		</cfif>

		<cfloop from="1" to="#ArrayLen(sqls)#" index="i">
			<cfif identical_(this.db.query(sqls[i]), "false")>
				<cfreturn "false">
			</cfif>
		</cfloop>

		<cfset this.reset()>

		<cfreturn "true">
	</cffunction>

	<!---
	 * Generates SQL to add indexes
	 *
	 * @param bool $asQuery When true returns stand alone SQL, else partial SQL used with CREATE TABLE
	 *
	 * @return list<string>
	--->
	<cffunction name="_processIndexes" access="private" returntype="any" output="no">
		<cfargument name="table" type="string" required="yes">
		<cfargument name="asQuery" type="boolean" required="no" default="false">
		<cfset var sqls = ArrayNew(1)>
		<cfset var keyName = "">
		<cfset var i = 0>
		<cfset var i2 = 0>

		<cfloop from="1" to="#ArrayLen(this.keys)#" index="i">
			<!--- Difference: from the end, so the numbers of the other fields stay the same --->
			<cfloop from="#ArrayLen(this.keys[i]['fields'])#" to="1" index="i2" step="-1">
				<cfif NOT array_key_exists(this.keys[i]["fields"][i2], this.fields)>
					<cfset ArrayDeleteAt(this.keys[i]["fields"], i2)>
				</cfif>
			</cfloop>

			<cfif ArrayLen(this.keys[i]["fields"]) GT 0>
				<cfif Compare(this.keys[i]["keyName"], "") EQ 0>
					<cfset keyName = this.db.escapeIdentifiers(arguments.table & "_" & implode("_", this.keys[i]["fields"]))>
				<cfelse>
					<cfset keyName = this.db.escapeIdentifiers(this.keys[i]["keyName"])>
				</cfif>

				<!--- the positions of uniqueKeys are 0-based --->
				<cfif in_array(i - 1, this.uniqueKeys)>
					<cfif Compare(this.db.DBDriver, "SQLite3") EQ 0>
						<cfset ArrayAppend(sqls, "CREATE UNIQUE INDEX " & keyName
							& " ON " & this.db.escapeIdentifiers(arguments.table)
							& " (" & implode(", ", this.db.escapeIdentifiers(this.keys[i]["fields"])) & ")")>
					<cfelse>
						<cfset ArrayAppend(sqls, "ALTER TABLE " & this.db.escapeIdentifiers(arguments.table)
							& " ADD CONSTRAINT " & keyName
							& " UNIQUE (" & implode(", ", this.db.escapeIdentifiers(this.keys[i]["fields"])) & ")")>
					</cfif>
				<cfelse>
					<cfset ArrayAppend(sqls, "CREATE INDEX " & keyName
						& " ON " & this.db.escapeIdentifiers(arguments.table)
						& " (" & implode(", ", this.db.escapeIdentifiers(this.keys[i]["fields"])) & ")")>
				</cfif>
			</cfif>
		</cfloop>

		<cfreturn sqls>
	</cffunction>

	<!---
	 * Generates SQL to add foreign keys
	 *
	 * @param bool $asQuery When true returns stand alone SQL, else partial SQL used with CREATE TABLE
	 *
	 * @return list<string>
	 *
	 * Difference: the original tests that onDelete and onUpdate are not
	 * false. They are strings, so that test is always true and is left out.
	--->
	<cffunction name="_processForeignKeys" access="private" returntype="any" output="no">
		<cfargument name="table" type="string" required="yes">
		<cfargument name="asQuery" type="boolean" required="no" default="false">
		<cfset var errorNames = ArrayNew(1)>
		<cfset var sqls = ArrayNew(1)>
		<cfset var isOci8 = false>
		<cfset var dbPrefix = this.db.DBPrefix>
		<cfset var fkSuffix = "">
		<cfset var prefixSql = "">
		<cfset var fkey = "">
		<cfset var nameIndex = "">
		<cfset var sql = "">
		<cfset var idx = 0>
		<cfset var i = 0>
		<cfset var j = 0>

		<cfif ArrayLen(this.foreignKeys) EQ 0>
			<cfset ArrayAppend(sqls, "")>

			<cfreturn sqls>
		</cfif>

		<cfloop from="1" to="#ArrayLen(this.foreignKeys)#" index="i">
			<cfloop from="1" to="#ArrayLen(this.foreignKeys[i]['field'])#" index="j">
				<cfif NOT array_key_exists(this.foreignKeys[i]["field"][j], this.fields)>
					<cfset ArrayAppend(errorNames, this.foreignKeys[i]["field"][j])>
				</cfif>
			</cfloop>
		</cfloop>

		<cfif ArrayLen(errorNames) GT 0>
			<cfset sql = implode(", ", errorNames)>
			<cfset errorNames = ArrayNew(1)>
			<cfset ArrayAppend(errorNames, sql)>

			<cfthrow type="ColdIgniter.Database.Exceptions.DatabaseException" message="#lang('Database.fieldNotExists', errorNames)#">
		</cfif>

		<cfset ArrayAppend(sqls, "")>
		<cfset isOci8 = Compare(this.db.DBDriver, "OCI8") EQ 0>

		<cfif isOci8>
			<cfset fkSuffix = "_fk">
		<cfelse>
			<cfset fkSuffix = "_foreign">
		</cfif>

		<cfif arguments.asQuery>
			<cfset prefixSql = "ALTER TABLE " & this.db.escapeIdentifiers(dbPrefix & arguments.table) & " ADD ">
		<cfelse>
			<cfset prefixSql = "," & Chr(10) & Chr(9)>
		</cfif>

		<cfloop from="1" to="#ArrayLen(this.foreignKeys)#" index="i">
			<cfset fkey = this.foreignKeys[i]>

			<!--- Difference: the position in sqls is 1-based --->
			<cfif arguments.asQuery>
				<cfset idx = i>

				<cfif i EQ 1>
					<cfset sqls[1] = "">
				<cfelse>
					<cfset ArrayAppend(sqls, "")>
				</cfif>
			<cfelse>
				<cfset idx = 1>
			</cfif>

			<cfif Compare(fkey["fkName"], "") NEQ 0>
				<cfset nameIndex = fkey["fkName"]>
			<cfelse>
				<cfset nameIndex = arguments.table & "_" & implode("_", fkey["field"]) & fkSuffix>
			</cfif>

			<cfset sql = prefixSql & sprintf_("CONSTRAINT %s FOREIGN KEY (%s) REFERENCES %s(%s)",
				this.db.escapeIdentifiers(nameIndex),
				implode(", ", this.db.escapeIdentifiers(fkey["field"])),
				this.db.escapeIdentifiers(dbPrefix & fkey["referenceTable"]),
				implode(", ", this.db.escapeIdentifiers(fkey["referenceField"])))>

			<cfif in_array(fkey["onDelete"], this.fkAllowActions)>
				<cfset sql = sql & " ON DELETE " & fkey["onDelete"]>
			</cfif>

			<cfif NOT isOci8 AND in_array(fkey["onUpdate"], this.fkAllowActions)>
				<cfset sql = sql & " ON UPDATE " & fkey["onUpdate"]>
			</cfif>

			<cfset sqls[idx] = sqls[idx] & sql>
		</cfloop>

		<cfreturn sqls>
	</cffunction>

	<!---
	 * Resets table creation vars
	 *
	 * @return void
	--->
	<cffunction name="reset" access="public" returntype="void" output="no">
		<cfset this.fields = array_()>
		<cfset this.keys = ArrayNew(1)>
		<cfset this.uniqueKeys = ArrayNew(1)>
		<cfset this.primaryKeys = array_()>
		<cfset this.foreignKeys = ArrayNew(1)>
	</cffunction>

	<!---
	 * Not in the original: puts the arguments after the format into the %s
	 * and the %N$s (the Nth argument) of the format, as sprintf() does.
	--->
	<cffunction name="sprintf_" access="private" returntype="string" output="no">
		<cfargument name="format" type="string" required="yes">
		<cfset var result = "">
		<cfset var pos = 1>
		<cfset var hit = Find("%", arguments.format)>
		<cfset var next = 1>
		<cfset var digits = "">
		<cfset var j = 0>

		<cfloop condition="hit GT 0">
			<cfif hit GT pos>
				<cfset result = result & Mid(arguments.format, pos, hit - pos)>
			</cfif>

			<cfset digits = "">
			<cfset j = hit + 1>

			<cfloop condition="j LTE Len(arguments.format) AND Find(Mid(arguments.format, j, 1), ""0123456789"") GT 0">
				<cfset digits = digits & Mid(arguments.format, j, 1)>
				<cfset j = j + 1>
			</cfloop>

			<cfif Compare(digits, "") NEQ 0 AND j + 1 LTE Len(arguments.format) AND Mid(arguments.format, j, 2) EQ "$s">
				<cfset result = result & arguments[digits + 1]>
				<cfset pos = j + 2>
			<cfelseif Compare(digits, "") EQ 0 AND j LTE Len(arguments.format) AND Mid(arguments.format, j, 1) EQ "s">
				<cfset next = next + 1>
				<cfset result = result & arguments[next]>
				<cfset pos = j + 1>
			<cfelse>
				<cfset result = result & "%">
				<cfset pos = hit + 1>
			</cfif>

			<cfset hit = Find("%", arguments.format, pos)>
		</cfloop>

		<cfif pos LTE Len(arguments.format)>
			<cfset result = result & Mid(arguments.format, pos, Len(arguments.format) - pos + 1)>
		</cfif>

		<cfreturn result>
	</cffunction>

	<!---
	 * Not in the original: the (array) cast of the original. A list is
	 * copied, anything else is the one item of a new list.
	--->
	<cffunction name="toList_" access="private" returntype="any" output="no">
		<cfargument name="value" type="any" required="yes">
		<cfset var result = ArrayNew(1)>
		<cfset var i = 0>

		<cfif IsArray(arguments.value)>
			<cfloop from="1" to="#ArrayLen(arguments.value)#" index="i">
				<cfset ArrayAppend(result, arguments.value[i])>
			</cfloop>
		<cfelse>
			<cfset ArrayAppend(result, arguments.value)>
		</cfif>

		<cfreturn result>
	</cffunction>

	<!---
	 * Not in the original: isset() for a key of a map. A null is the
	 * NullValue, an empty string is a value.
	--->
	<cffunction name="isset_" access="private" returntype="boolean" output="no">
		<cfargument name="map" type="any" required="yes">
		<cfargument name="key" type="string" required="yes">

		<cfif NOT array_key_exists(arguments.key, arguments.map)>
			<cfreturn false>
		</cfif>

		<cfreturn NOT instanceof_(arguments.map[arguments.key], "ColdIgniter\Database\NullValue")>
	</cffunction>

	<!---
	 * Not in the original: the test === true. A flag is the text "true" or a
	 * real boolean true; a literal true in a map is the text "true" here, so
	 * the other values that are true in a loose test (such as 1) are not.
	--->
	<cffunction name="isTrue_" access="private" returntype="boolean" output="no">
		<cfargument name="value" type="any" required="yes">

		<cfif NOT IsSimpleValue(arguments.value)>
			<cfreturn false>
		</cfif>

		<cfif is_bool(arguments.value)>
			<cfreturn arguments.value>
		</cfif>

		<cfreturn Compare(arguments.value, "true") EQ 0>
	</cffunction>

	<!---
	 * Not in the original: the result of a query as a bool. A query gives
	 * "false" when it fails, "true" for a write type, and a result object
	 * for the other types (such as a batch that starts with IF or EXEC), which
	 * is a success too.
	--->
	<cffunction name="succeeded_" access="private" returntype="string" output="no">
		<cfargument name="result" type="any" required="yes">

		<cfif identical_(arguments.result, "false")>
			<cfreturn "false">
		</cfif>

		<cfreturn "true">
	</cffunction>

</cfcomponent>
