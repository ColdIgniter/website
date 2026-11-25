<!---
 * Forge for SQLSRV
 *
 * Difference: the original extends Forge. This class is in another folder,
 * so it is mixed in with parent (see the reference, "How components are
 * located"). The values are as in the base class (see Forge): a boolean is
 * the text "true" or "false", a null is an empty string, and the properties
 * null and default are null_ and default_.
 *
 * Difference: the statements are for SQL Server 2000, where the original
 * is for 2005 and later:
 *
 * - createDatabaseIfStr has a DECLARE and a SET for each variable (a
 *   variable cannot get a value in its DECLARE), and VARCHAR(8000), as there
 *   is no VARCHAR(max).
 * - _alterTable finds the default constraints in sysobjects (xtype 'D') and
 *   syscolumns (cdefault), where the original reads sys.default_constraints
 *   and sys.columns.
 * - the extended property of a comment is added with sp_addextendedproperty
 *   and a level 0 type of USER, where the original uses sys.sp_addextendedproperty
 *   and SCHEMA.
 * - _dropTable tests with IF OBJECT_ID() IS NOT NULL, where the original has
 *   DROP TABLE IF EXISTS.
 * - _attributeType makes IMAGE of BLOB, where the original has
 *   VARBINARY(MAX).
 * - dropIndexStr and _dropIndex are DROP INDEX owner.table.index, as 2000
 *   has no DROP INDEX index ON table.
 *
 * Difference: renameTable() is in this class. The original passes the
 * escaped names to sp_rename, which takes the names as strings, and its
 * comment says that the statement returns an error.
--->
<cfcomponent output="no" parent="ColdIgniter\Database\Forge" hint="Forge for SQLSRV">

	<!---
	 * DROP CONSTRAINT statement
	--->
	<cfset this.dropConstraintStr = "">

	<!---
	 * DROP INDEX statement
	 *
	 * @var string
	--->
	<cfset this.dropIndexStr = "">

	<!---
	 * CREATE DATABASE IF statement
	 *
	 * @todo missing charset, collat & check for existent
	 *
	 * @var string
	--->
	<cfset this.createDatabaseIfStr = "DECLARE @DBName VARCHAR(255)" & Chr(10) & "SET @DBName = '%s'" & Chr(10) & "DECLARE @SQL VARCHAR(8000)" & Chr(10) & "SET @SQL = 'IF DB_ID( ''' + @DBName + ''' ) IS NULL CREATE DATABASE %s'" & Chr(10) & "EXEC( @SQL )">

	<!---
	 * CREATE DATABASE IF statement
	 *
	 * @todo missing charset & collat
	--->
	<cfset this.createDatabaseStr = "CREATE DATABASE %s ">

	<!---
	 * CHECK DATABASE EXIST statement
	 *
	 * @var string
	--->
	<cfset this.checkDatabaseExistStr = "IF DB_ID( %s ) IS NOT NULL SELECT 1">

	<!---
	 * RENAME TABLE statement
	 *
	 * While the below statement would work, it returns an error.
	 * Also MS recommends dropping and dropping and re-creating the table.
	 *
	 * @see https://docs.microsoft.com/en-us/sql/relational-databases/system-stored-procedures/sp-rename-transact-sql?view=sql-server-2017
	 * 'EXEC sp_rename %s , %s ;'
	 *
	 * Difference: renameTable() below does not use this statement, and it
	 * is kept as in the original.
	--->
	<cfset this.renameTableStr = "">

	<!---
	 * UNSIGNED support
	--->
	<cfset this.unsigned = CreateObject("java", "java.util.LinkedHashMap").init()>
	<cfset this.unsigned["TINYINT"] = "SMALLINT">
	<cfset this.unsigned["SMALLINT"] = "INT">
	<cfset this.unsigned["INT"] = "BIGINT">
	<cfset this.unsigned["REAL"] = "FLOAT">

	<!---
	 * Foreign Key Allowed Actions
	--->
	<cfset this.fkAllowActions = ArrayNew(1)>
	<cfset ArrayAppend(this.fkAllowActions, "CASCADE")>
	<cfset ArrayAppend(this.fkAllowActions, "SET NULL")>
	<cfset ArrayAppend(this.fkAllowActions, "NO ACTION")>
	<cfset ArrayAppend(this.fkAllowActions, "RESTRICT")>
	<cfset ArrayAppend(this.fkAllowActions, "SET DEFAULT")>

	<!---
	 * CREATE TABLE IF statement
	 *
	 * @deprecated This is no longer used.
	--->
	<cfset this.createTableIfStr = "">

	<!---
	 * CREATE TABLE statement
	--->
	<cfset this.createTableStr = "">

	<!---
	 * @param db Connection
	--->
	<cffunction name="__construct" access="public" returntype="any" output="no">
		<cfargument name="db" type="any" required="yes">

		<cfset parent.__construct(arguments.db)>

		<cfset this.createTableStr = "%s " & this.db.escapeIdentifiers(this.db.schema) & ".%s (%s" & Chr(10) & ") ">
		<cfset this.renameTableStr = "EXEC sp_rename [" & this.db.escapeIdentifiers(this.db.schema) & ".%s] , %s ;">

		<cfset this.dropConstraintStr = "ALTER TABLE " & this.db.escapeIdentifiers(this.db.schema) & ".%s DROP CONSTRAINT %s">
		<cfset this.dropIndexStr = "DROP INDEX " & this.db.escapeIdentifiers(this.db.schema) & ".%2$s.%1$s">

		<cfreturn this>
	</cffunction>

	<cffunction name="createDatabase" access="public" returntype="any" output="no">
		<cfargument name="dbName" type="string" required="yes">
		<cfargument name="ifNotExists" type="boolean" required="no" default="false">
		<cfset var sql = "">

		<cfif arguments.ifNotExists>
			<cfset sql = sprintf_(this.createDatabaseIfStr, arguments.dbName, this.db.escapeIdentifier(arguments.dbName))>
		<cfelse>
			<cfset sql = sprintf_(this.createDatabaseStr, this.db.escapeIdentifier(arguments.dbName))>
		</cfif>

		<cftry>
			<cfif identical_(this.db.query(sql), "false")>
				<!--- @codeCoverageIgnoreStart --->
				<cfif this.db.DBDebug>
					<cfthrow type="ColdIgniter.Database.Exceptions.DatabaseException" message="Unable to create the specified database.">
				</cfif>

				<cfreturn "false">
				<!--- @codeCoverageIgnoreEnd --->
			</cfif>

			<cfif array_key_exists("db_names", this.db.dataCache)>
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
	 * {@inheritDoc}
	 *
	 * @see https://stackoverflow.com/questions/7469130/cannot-drop-database-because-it-is-currently-in-use
	--->
	<cffunction name="dropDatabase" access="public" returntype="any" output="no">
		<cfargument name="dbName" type="string" required="yes">

		<cftry>
			<cfset this.db.query(sprintf_("ALTER DATABASE %s SET SINGLE_USER WITH ROLLBACK IMMEDIATE", this.db.escapeIdentifier(arguments.dbName)))>

			<cfcatch type="ColdIgniter.Database.Exceptions.DatabaseException">
				<!--- no-op --->
			</cfcatch>
		</cftry>

		<cfreturn parent.dropDatabase(arguments.dbName)>
	</cffunction>

	<cffunction name="_createTableAttributes" access="private" returntype="string" output="no">
		<cfargument name="attributes" type="any" required="yes">

		<cfreturn "">
	</cffunction>

	<cffunction name="_alterTable" access="private" returntype="any" output="no">
		<cfargument name="alterType" type="string" required="yes">
		<cfargument name="table" type="string" required="yes">
		<cfargument name="processedFields" type="any" required="yes">
		<cfset var columnNamesToDrop = "">
		<cfset var indexData = "">
		<cfset var indexNames = "">
		<cfset var index = "">
		<cfset var found = false>
		<cfset var fullTable = "">
		<cfset var fields = "">
		<cfset var sql = "">
		<cfset var sqls = ArrayNew(1)>
		<cfset var rows = "">
		<cfset var field = "">
		<cfset var colName = "">
		<cfset var findSql = "">
		<cfset var toDrop = "">
		<cfset var nullable = true>
		<cfset var i = 0>
		<cfset var j = 0>
		<cfset var k = 0>

		<!--- Handle DROP here --->
		<cfif Compare(arguments.alterType, "DROP") EQ 0>
			<cfset columnNamesToDrop = arguments.processedFields>

			<!--- check if fields are part of any indexes --->
			<cfset indexData = this.db.getIndexData(arguments.table)>
			<cfset indexNames = array_keys(indexData)>

			<cfloop from="1" to="#ArrayLen(indexNames)#" index="i">
				<cfset index = indexData[indexNames[i]]>

				<cfif IsSimpleValue(columnNamesToDrop)>
					<cfset columnNamesToDrop = explode(",", columnNamesToDrop)>
				</cfif>

				<!--- Difference: array_intersect() is a loop --->
				<cfset found = false>

				<cfloop from="1" to="#ArrayLen(columnNamesToDrop)#" index="j">
					<cfif in_array(columnNamesToDrop[j], index["fields"])>
						<cfset found = true>
					</cfif>
				</cfloop>

				<!--- Drop index if field is part of an index --->
				<cfif found>
					<cfset _dropIndex(arguments.table, index)>
				</cfif>
			</cfloop>

			<cfset fullTable = this.db.escapeIdentifiers(this.db.schema) & "." & this.db.escapeIdentifiers(arguments.table)>

			<!--- Drop default constraints --->
			<cfset columnNamesToDrop = toList_(columnNamesToDrop)>
			<cfset fields = implode(",", this.db.escape(columnNamesToDrop))>

			<!--- Difference: sysobjects and syscolumns, see the header --->
			<cfset sql = "SELECT o.name" & Chr(10)
				& "FROM sysobjects o" & Chr(10)
				& "INNER JOIN syscolumns c ON o.id = c.cdefault" & Chr(10)
				& "WHERE o.xtype = 'D'" & Chr(10)
				& "AND c.id = OBJECT_ID('#fullTable#')" & Chr(10)
				& "AND c.name IN (#fields#)">

			<cfset rows = this.db.query(sql).getResultArray()>

			<cfloop from="1" to="#ArrayLen(rows)#" index="i">
				<cfset this.db.query("ALTER TABLE " & fullTable & " DROP CONSTRAINT " & pick_(rows[i], "name") & "")>
			</cfloop>

			<cfset sql = "ALTER TABLE " & fullTable & " DROP ">

			<cfset fields = ArrayNew(1)>

			<cfloop from="1" to="#ArrayLen(columnNamesToDrop)#" index="i">
				<cfset ArrayAppend(fields, "COLUMN [" & Trim(columnNamesToDrop[i]) & "]")>
			</cfloop>

			<cfreturn sql & implode(",", fields)>
		</cfif>

		<cfset sql = "ALTER TABLE " & this.db.escapeIdentifiers(this.db.schema) & "." & this.db.escapeIdentifiers(arguments.table)>

		<cfif Compare(arguments.alterType, "ADD") EQ 0>
			<cfset sql = sql & "ADD ">
		<cfelse>
			<cfset sql = sql & " ">
		</cfif>

		<cfif Compare(arguments.alterType, "ADD") EQ 0>
			<cfloop from="1" to="#ArrayLen(arguments.processedFields)#" index="i">
				<cfset field = arguments.processedFields[i]>

				<cfif NOT identical_(field["_literal"], "false")>
					<cfset ArrayAppend(sqls, sql & field["_literal"])>
				<cfelse>
					<cfset ArrayAppend(sqls, sql & _processColumn(field))>
				</cfif>
			</cfloop>

			<cfreturn sqls>
		</cfif>

		<cfloop from="1" to="#ArrayLen(arguments.processedFields)#" index="i">
			<cfset field = arguments.processedFields[i]>

			<cfif NOT identical_(field["_literal"], "false")>
				<cfreturn "false">
			</cfif>

			<!--- Difference: the type of a field is an empty string where the original has null --->
			<cfif Compare(field["type"], "") NEQ 0>
				<cfset ArrayAppend(sqls, sql & " ALTER COLUMN " & this.db.escapeIdentifiers(field["name"]) & " " & field["type"] & field["length"])>
			</cfif>

			<cfif array_key_exists("default", field) AND Compare(field["default"], "") NEQ 0>
				<cfset fullTable = this.db.escapeIdentifiers(this.db.schema) & "." & this.db.escapeIdentifiers(arguments.table)>
				<cfset colName = field["name"]> <!--- bare, for the syscolumns lookup --->

				<!--- find the existing default constraint name for this column --->
				<!--- Difference: sysobjects and syscolumns, see the header --->
				<cfset findSql = "SELECT o.name AS constraint_name" & Chr(10)
					& "FROM sysobjects o" & Chr(10)
					& "INNER JOIN syscolumns c ON o.id = c.cdefault" & Chr(10)
					& "WHERE o.xtype = 'D'" & Chr(10)
					& "AND c.id = OBJECT_ID(N'#fullTable#')" & Chr(10)
					& "AND c.name = N'#colName#'">

				<cfset toDrop = this.db.query(findSql).getRowArray()>

				<cfif is_array(toDrop) AND Compare(pick_(toDrop, "constraint_name"), "") NEQ 0>
					<cfset ArrayAppend(sqls, sql & " DROP CONSTRAINT " & this.db.escapeIdentifiers(pick_(toDrop, "constraint_name")))>
				</cfif>

				<cfset ArrayAppend(sqls, sql & " ADD CONSTRAINT " & this.db.escapeIdentifiers(field["name"] & "_def") & field["default"] & " FOR " & this.db.escapeIdentifiers(field["name"]))>
			</cfif>

			<cfset nullable = true> <!--- Nullable by default. --->

			<cfif array_key_exists("null", field) AND Compare(field["null"], " NOT " & this.null_) EQ 0>
				<cfset nullable = false>
			</cfif>

			<cfif nullable>
				<cfset ArrayAppend(sqls, sql & " ALTER COLUMN " & this.db.escapeIdentifiers(field["name"]) & " " & field["type"] & field["length"] & " " & " NULL")>
			<cfelse>
				<cfset ArrayAppend(sqls, sql & " ALTER COLUMN " & this.db.escapeIdentifiers(field["name"]) & " " & field["type"] & field["length"] & " " & "NOT" & " NULL")>
			</cfif>

			<cfif array_key_exists("comment", field) AND Compare(field["comment"], "") NEQ 0>
				<!---
				 * Difference: sp_addextendedproperty and USER, see the header.
				 * The original puts the comment, which has its quotes
				 * already, between quotes again, and gives the escaped names
				 * of the table and the column, which the procedure does not
				 * find. Here the comment keeps its own quotes and the names
				 * are bare.
				--->
				<cfset ArrayAppend(sqls, "EXEC sp_addextendedproperty "
					& "@name=N'Caption', @value=N" & field["comment"] & " , "
					& "@level0type=N'USER',@level0name=N'" & this.db.schema & "', "
					& "@level1type=N'TABLE',@level1name=N'" & arguments.table & "', "
					& "@level2type=N'COLUMN',@level2name=N'" & field["name"] & "'")>
			</cfif>

			<cfif Compare(field["new_name"], "") NEQ 0>
				<cfset ArrayAppend(sqls, "EXEC sp_rename  '[" & this.db.schema & "].[" & arguments.table & "].[" & field["name"] & "]' , '" & field["new_name"] & "', 'COLUMN';")>
			</cfif>
		</cfloop>

		<cfreturn sqls>
	</cffunction>

	<!---
	 * Drop index for table
	 *
	 * @param indexData A map with name, fields and type
	 *
	 * @return false|resource
	--->
	<cffunction name="_dropIndex" access="private" returntype="any" output="no">
		<cfargument name="table" type="string" required="yes">
		<cfargument name="indexData" type="any" required="yes">
		<cfset var sql = "">

		<cfif Compare(arguments.indexData["type"], "PRIMARY") EQ 0>
			<cfset sql = "ALTER TABLE [" & this.db.schema & "].[" & arguments.table & "] DROP [" & arguments.indexData["name"] & "]">
		<cfelse>
			<!---
			 * Difference: the original has DROP INDEX index ON table, which
			 * is not in SQL Server 2000, and it has that for the index of a
			 * unique constraint too, which no version can drop that way. A
			 * unique constraint is dropped as a constraint, and an index
			 * with DROP INDEX owner.table.index.
			--->
			<cfset sql = "IF OBJECTPROPERTY(OBJECT_ID('[" & this.db.schema & "].[" & arguments.indexData["name"] & "]'), 'IsUniqueCnst') = 1 "
				& "ALTER TABLE [" & this.db.schema & "].[" & arguments.table & "] DROP CONSTRAINT [" & arguments.indexData["name"] & "] "
				& "ELSE DROP INDEX [" & this.db.schema & "].[" & arguments.table & "].[" & arguments.indexData["name"] & "]">
		</cfif>

		<cfreturn this.db.simpleQuery(sql)>
	</cffunction>

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
					<cfset ArrayAppend(sqls, "ALTER TABLE "
						& this.db.escapeIdentifiers(this.db.schema) & "." & this.db.escapeIdentifiers(arguments.table)
						& " ADD CONSTRAINT " & keyName
						& " UNIQUE (" & implode(", ", this.db.escapeIdentifiers(this.keys[i]["fields"])) & ");")>
				<cfelse>
					<cfset ArrayAppend(sqls, "CREATE INDEX "
						& keyName
						& " ON " & this.db.escapeIdentifiers(this.db.schema) & "." & this.db.escapeIdentifiers(arguments.table)
						& " (" & implode(", ", this.db.escapeIdentifiers(this.keys[i]["fields"])) & ");")>
				</cfif>
			</cfif>
		</cfloop>

		<cfreturn sqls>
	</cffunction>

	<!---
	 * Process column
	--->
	<cffunction name="_processColumn" access="private" returntype="string" output="no">
		<cfargument name="processedField" type="any" required="yes">
		<cfset var newName = "">
		<cfset var length = arguments.processedField["length"]>

		<cfif Compare(arguments.processedField["new_name"], "") NEQ 0>
			<cfset newName = " " & this.db.escapeIdentifiers(arguments.processedField["new_name"])>
		</cfif>

		<cfif Compare(arguments.processedField["type"], "text") EQ 0>
			<cfset length = "">
		</cfif>

		<cfreturn this.db.escapeIdentifiers(arguments.processedField["name"])
			& newName
			& " " & arguments.processedField["type"] & length
			& arguments.processedField["default"]
			& arguments.processedField["null"]
			& arguments.processedField["auto_increment"]
			& ""
			& arguments.processedField["unique"]>
	</cffunction>

	<!---
	 * Performs a data type mapping between different databases.
	--->
	<cffunction name="_attributeType" access="private" returntype="void" output="no">
		<cfargument name="attributes" type="any" required="yes">
		<cfset var maxLength = 0>
		<cfset var i = 0>

		<!--- Reset field lengths for data types that don't support it --->
		<cfif isset_(arguments.attributes, "CONSTRAINT") AND Find("int", LCase(arguments.attributes["TYPE"])) GT 0>
			<cfset arguments.attributes["CONSTRAINT"] = new_("ColdIgniter\Database\NullValue")>
		</cfif>

		<cfswitch expression="#UCase(arguments.attributes['TYPE'])#">
			<cfcase value="MEDIUMINT">
				<cfset arguments.attributes["TYPE"] = "INTEGER">
				<cfset arguments.attributes["UNSIGNED"] = "false">
			</cfcase>

			<cfcase value="INTEGER">
				<cfset arguments.attributes["TYPE"] = "INT">
			</cfcase>

			<cfcase value="ENUM">
				<!--- in char(n) and varchar(n), the n defines the string length in
				      bytes (0 to 8,000).
				      https://learn.microsoft.com/en-us/sql/t-sql/data-types/char-and-varchar-transact-sql?view=sql-server-ver16#remarks --->
				<cfloop from="1" to="#ArrayLen(arguments.attributes['CONSTRAINT'])#" index="i">
					<cfif Len(arguments.attributes["CONSTRAINT"][i]) GT maxLength>
						<cfset maxLength = Len(arguments.attributes["CONSTRAINT"][i])>
					</cfif>
				</cfloop>

				<cfset arguments.attributes["TYPE"] = "VARCHAR">
				<cfset arguments.attributes["CONSTRAINT"] = maxLength>
			</cfcase>

			<cfcase value="TIMESTAMP">
				<cfset arguments.attributes["TYPE"] = "DATETIME">
			</cfcase>

			<cfcase value="BOOLEAN">
				<cfset arguments.attributes["TYPE"] = "BIT">
			</cfcase>

			<cfcase value="BLOB">
				<!--- Difference: IMAGE has no length, and 2000 has no VARBINARY(MAX) --->
				<cfset arguments.attributes["TYPE"] = "IMAGE">
				<cfset arguments.attributes["CONSTRAINT"] = new_("ColdIgniter\Database\NullValue")>
			</cfcase>

			<cfdefaultcase>
			</cfdefaultcase>
		</cfswitch>
	</cffunction>

	<!---
	 * Field attribute AUTO_INCREMENT
	--->
	<cffunction name="_attributeAutoIncrement" access="private" returntype="void" output="no">
		<cfargument name="attributes" type="any" required="yes">
		<cfargument name="field" type="any" required="yes">

		<cfif isset_(arguments.attributes, "AUTO_INCREMENT") AND isTrue_(arguments.attributes["AUTO_INCREMENT"]) AND Find(LCase("INT"), LCase(arguments.field["type"])) GT 0>
			<cfset arguments.field["auto_increment"] = " IDENTITY(1,1)">
		</cfif>
	</cffunction>

	<!---
	 * Generates a platform-specific DROP TABLE string
	 *
	 * @todo Support for cascade
	--->
	<cffunction name="_dropTable" access="private" returntype="string" output="no">
		<cfargument name="table" type="string" required="yes">
		<cfargument name="ifExists" type="boolean" required="yes">
		<cfargument name="cascade" type="boolean" required="yes">
		<cfset var sql = "DROP TABLE">
		<cfset var table_ = " [" & this.db.database & "].[" & this.db.schema & "].[" & arguments.table & "] ">

		<!--- Difference: IF OBJECT_ID() IS NOT NULL, see the header --->
		<cfif arguments.ifExists>
			<cfset sql = "IF OBJECT_ID('" & Trim(table_) & "') IS NOT NULL " & sql>
		</cfif>

		<cfset sql = sql & table_>

		<cfif arguments.cascade>
			<cfset sql = sql & "">
		</cfif>

		<cfreturn sql>
	</cffunction>

	<!---
	 * Constructs sql to check if key is a constraint.
	--->
	<cffunction name="_dropKeyAsConstraint" access="private" returntype="string" output="no">
		<cfargument name="table" type="string" required="yes">
		<cfargument name="constraintName" type="string" required="yes">

		<cfreturn "SELECT CONSTRAINT_NAME FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
				WHERE TABLE_NAME= '" & trim_(arguments.table, """") & "'
				AND CONSTRAINT_NAME = '" & trim_(arguments.constraintName, """") & "'">
	</cffunction>

	<!---
	 * Not in the original: renames a table with sp_rename, which takes the
	 * names as strings. The rest is as in the base class.
	 *
	 * @return bool
	 *
	 * @throws DatabaseException
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

		<cfset result = this.db.query("EXEC sp_rename " & this.db.escape("[" & this.db.schema & "].[" & this.db.DBPrefix & arguments.tableName & "]") & " , " & this.db.escape(this.db.DBPrefix & arguments.newTableName))>

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
	 * Not in the original: reads a column of a row, with the case of the name
	 * as it is written or in upper case (a query of 6.1 gives upper case
	 * names).
	--->
	<cffunction name="pick_" access="private" returntype="any" output="no">
		<cfargument name="row" type="any" required="yes">
		<cfargument name="name" type="string" required="yes">

		<cfif array_key_exists(arguments.name, arguments.row)>
			<cfreturn arguments.row[arguments.name]>
		</cfif>

		<cfif array_key_exists(UCase(arguments.name), arguments.row)>
			<cfreturn arguments.row[UCase(arguments.name)]>
		</cfif>

		<cfif array_key_exists(LCase(arguments.name), arguments.row)>
			<cfreturn arguments.row[LCase(arguments.name)]>
		</cfif>

		<cfreturn "">
	</cffunction>

</cfcomponent>
