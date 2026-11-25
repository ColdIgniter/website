<!---
 * Connection for SQLSRV
 *
 * The target is SQL Server 2000 (8.00), reached only through a ColdFusion
 * data source: the name of the data source is the DSN setting. The server,
 * the database, the user and the password belong to that data source.
 *
 * Difference: the original extends BaseConnection. This class is in
 * another folder, so it is mixed in with parent (see the reference,
 * "How components are located").
 *
 * Difference: the return values are the text "true" and "false" for a
 * boolean, and an empty string for a null (use is_null()). Rows are maps
 * (see array_()), not objects.
 *
 * Difference: there is no connection. connect() checks the DSN, sets the
 * connID to the DSN (any value but "false") and reads the setting
 * QUOTED_IDENTIFIER. The settings hostname, port, username, password,
 * encrypt, charset, scrollable and the others of the original that open
 * a socket are unused. No user name or password is sent to the data
 * source. ColdFusion keeps and shares the real connections.
 *
 * Difference: the original reads the number of affected rows and the
 * insert ID from the connection. A query tag of 6.1 has no result
 * attribute, so execute() adds a select to every INSERT, UPDATE and
 * DELETE statement, in the same batch, that reads @@ROWCOUNT and
 * SCOPE_IDENTITY(). The values wait in lastAffectedRows and lastInsertID.
 * A batch of the Builder that counts its rows itself declares @ci_rows,
 * and that variable is read in place of @@ROWCOUNT.
 * When a transaction is open, the same batch stops with an error if the
 * data source connection that runs it has no open transaction.
 *
 * Difference: a transaction is a BEGIN, COMMIT or ROLLBACK TRANSACTION
 * statement. It relies on ColdFusion running the queries of one request
 * on the same connection of the data source, which 6.1 does not promise.
 * close() rolls back a transaction that is still open. The data source
 * keeps a transaction that a request left open, so the first statement
 * of a request on a DSN is preceded by a query that rolls back what is
 * left on the connection (see execute()).
 *
 * Difference: all the Connection objects of one DSN share the connection
 * of the data source, so one DSN carries one transaction in a request.
 * The request counts the objects that have begun one (see transCount()).
 * A statement of another object of the same DSN runs inside that
 * transaction. When two objects begin a transaction, the second is
 * nested in the first: the work is kept when both have committed, and a
 * rollback by either ends the work of both.
 *
 * Difference: a transaction that is already open when the request runs
 * its first statement on the DSN is rolled back by the query that
 * execute() runs before the statements of the request (see execute()).
 * For example, one that a cftransaction tag or a query of
 * "BEGIN TRANSACTION" outside this class has opened. Use transBegin().
 *
 * Difference: NULL and an empty string cannot be told apart in a query of
 * 6.1. Both are an empty string (see Result).
 *
 * Difference: setDatabase() runs USE on the connection of the data source
 * that runs it. It does not change the database of the data source.
 *
 * Difference: _foreignKeyData() reads sysforeignkeys, sysobjects and
 * syscolumns, as SQL Server 2000 has no sys.foreign_keys.
 *
 * Difference: the trace of the original execute() is not ported. The
 * error is kept in properties (lastErrorState, lastErrorCode and
 * lastErrorMessage) and in the log.
 *
 * Not ported yet: the SQLSRV PreparedQuery.
--->
<cfcomponent output="no" parent="ColdIgniter\Database\BaseConnection" hint="Connection for SQLSRV">

	<!---
	 * Database driver
	 *
	 * @var string
	--->
	<cfset this.DBDriver = "SQLSRV">

	<!---
	 * Database name
	 *
	 * @var string
	--->
	<cfset this.database = "">

	<!---
	 * Scrollable flag. Unused.
	 *
	 * @var false|string|null
	--->
	<cfset this.scrollable = "false">

	<!---
	 * Identifier escape character
	 *
	 * @var string|list<string>
	--->
	<cfset this.escapeChar = """">

	<!---
	 * Database schema
	 *
	 * @var string
	--->
	<cfset this.schema = "dbo">

	<!---
	 * Quoted identifier flag
	 *
	 * Whether to use SQL-92 standard quoted identifier
	 * (double quotes) or brackets for identifier escaping.
	 *
	 * @var bool
	--->
	<cfset this._quoted_identifier = "true">

	<!---
	 * List of reserved identifiers
	 *
	 * Identifiers that must NOT be escaped.
	 *
	 * @var list<string>
	--->
	<cfset this._reserved_identifiers = ArrayNew(1)>
	<cfset ArrayAppend(this._reserved_identifiers, "*")>

	<!---
	 * Number of rows the last INSERT, UPDATE or DELETE changed.
	 *
	 * Not in the original.
	 *
	 * @var int
	--->
	<cfset this.lastAffectedRows = 0>

	<!---
	 * The last identity value that was made.
	 *
	 * Not in the original.
	 *
	 * @var int
	--->
	<cfset this.lastInsertID = 0>

	<!---
	 * SQLSTATE of the last error, or an empty string.
	 *
	 * Not in the original.
	 *
	 * @var string
	--->
	<cfset this.lastErrorState = "">

	<!---
	 * Native error code of the last error, or an empty string.
	 *
	 * Not in the original.
	 *
	 * @var string
	--->
	<cfset this.lastErrorCode = "">

	<!---
	 * Message of the last error, or an empty string.
	 *
	 * Not in the original.
	 *
	 * @var string
	--->
	<cfset this.lastErrorMessage = "">

	<!---
	 * Connect to the database.
	 *
	 * Difference: see the header. The connID is the name of the data source.
	 *
	 * @return false|string
	 *
	 * @throws DatabaseException
	--->
	<cffunction name="connect" access="public" returntype="any" output="no">
		<cfargument name="persistent" type="boolean" required="no" default="false">
		<cfset var query_ = "">
		<cfset var row = "">

		<cfif Len(this.DSN) EQ 0>
			<cfthrow type="ColdIgniter.Database.Exceptions.DatabaseException" message="The DSN is empty. Set the name of a ColdFusion data source.">
		</cfif>

		<cfset this.connID = this.DSN>

		<cftry>
			<!--- If an error happens here, the connection did not work. --->
			<cfset query_ = this.query("SELECT CASE WHEN (@@OPTIONS | 256) = @@OPTIONS THEN 1 ELSE 0 END AS qi")>

			<cfif identical_(query_, "false")>
				<cfthrow type="ColdIgniter.Database.Exceptions.DatabaseException" message="#this.lastErrorMessage#">
			</cfif>

			<cfset row = query_.getRowArray()>

			<cfif Val(pick_(row, "qi")) EQ 1>
				<cfset this._quoted_identifier = "true">
				<cfset this.escapeChar = """">
			<cfelse>
				<cfset this._quoted_identifier = "false">
				<cfset this.escapeChar = ArrayNew(1)>
				<cfset ArrayAppend(this.escapeChar, "[")>
				<cfset ArrayAppend(this.escapeChar, "]")>
			</cfif>

			<cfcatch type="any">
				<cfset this.connID = "false">
				<cfrethrow>
			</cfcatch>
		</cftry>

		<cfreturn this.connID>
	</cffunction>

	<!---
	 * Get the error messages of the last query.
	 *
	 * @internal
	--->
	<cffunction name="getAllErrorMessages" access="public" returntype="string" output="no">
		<cfreturn this.lastErrorMessage>
	</cffunction>

	<!---
	 * Close the connection.
	 *
	 * Difference: there is no socket to close. A transaction that is
	 * still open is rolled back.
	--->
	<cffunction name="_close" access="private" returntype="void" output="no">
		<cfif this.transDepth GT 0>
			<cftry>
				<cfset execute("IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION")>

				<cfcatch type="any">
				</cfcatch>
			</cftry>

			<cfset this.transDepth = 0>
			<cfset setTransCount(0)>
		</cfif>
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
	 * Insert ID
	 *
	 * Difference: the identity value of the last INSERT that made one (see
	 * the header). It is 0 before any.
	--->
	<cffunction name="insertID" access="public" returntype="any" output="no">
		<cfreturn this.lastInsertID>
	</cffunction>

	<!---
	 * Generates the SQL for listing tables in a platform-dependent manner.
	 *
	 * @param tableName If tableName is provided will return only this table if exists.
	--->
	<cffunction name="_listTables" access="private" returntype="any" output="no">
		<cfargument name="constrainByPrefix" type="boolean" required="no" default="false">
		<cfargument name="tableName" type="string" required="no" default="">
		<cfset var sql = "SELECT [TABLE_NAME] AS ""name"" FROM [INFORMATION_SCHEMA].[TABLES]  WHERE  [TABLE_SCHEMA] = '" & this.schema & "'    ">

		<cfif Len(arguments.tableName) GT 0>
			<cfreturn sql & " AND [TABLE_NAME] LIKE " & this.escape(arguments.tableName)>
		</cfif>

		<cfif arguments.constrainByPrefix AND Len(this.DBPrefix) GT 0>
			<cfset sql = sql & " AND [TABLE_NAME] LIKE '" & this.escapeLikeString(this.DBPrefix) & "%' " & str_replace("%s", this.likeEscapeChar, this.likeEscapeStr)>
		</cfif>

		<cfreturn sql>
	</cffunction>

	<!---
	 * Generates a platform-specific query string so that the column names can be fetched.
	 *
	 * @param table A string or a TableName
	--->
	<cffunction name="_listColumns" access="private" returntype="any" output="no">
		<cfargument name="table" type="any" required="no" default="">
		<cfset var tableName = "">

		<cfif IsObject(arguments.table)>
			<cfset tableName = this.escape(LCase(arguments.table.getActualTableName()))>
		<cfelse>
			<cfset tableName = this.escape(this.DBPrefix & LCase(arguments.table))>
		</cfif>

		<cfreturn "SELECT [COLUMN_NAME]  FROM [INFORMATION_SCHEMA].[COLUMNS] WHERE  [TABLE_NAME] = " & tableName & " AND [TABLE_SCHEMA] = " & this.escape(this.schema)>
	</cffunction>

	<!---
	 * Returns an array of objects with index data
	 *
	 * Difference: the objects are maps (see array_()). SQL Server 2000
	 * writes "primary key located on PRIMARY" in the description of a
	 * primary key, as later versions do.
	 *
	 * @return array<string, stdClass>
	 *
	 * @throws DatabaseException
	--->
	<cffunction name="_indexData" access="private" returntype="any" output="no">
		<cfargument name="table" type="string" required="yes">
		<cfset var sql = "EXEC sp_helpindex " & this.escape(this.schema & "." & arguments.table)>
		<cfset var query_ = this.query(sql)>
		<cfset var rows = "">
		<cfset var row = "">
		<cfset var obj = "">
		<cfset var retVal = array_()>
		<cfset var fields = "">
		<cfset var description = "">
		<cfset var i = 0>
		<cfset var j = 0>

		<cfif identical_(query_, "false") OR identical_(query_, "true")>
			<cfthrow type="ColdIgniter.Database.Exceptions.DatabaseException" message="#lang('Database.failGetIndexData')#">
		</cfif>

		<cfset rows = query_.getResultArray()>

		<cfloop from="1" to="#ArrayLen(rows)#" index="i">
			<cfset row = rows[i]>
			<cfset fields = explode(",", trim_(pick_(row, "index_keys")))>

			<cfloop from="1" to="#ArrayLen(fields)#" index="j">
				<cfset fields[j] = trim_(fields[j])>
			</cfloop>

			<cfset description = pick_(row, "index_description")>
			<cfset obj = array_("name", pick_(row, "index_name"), "fields", fields)>

			<cfif Find("primary key located on", description) GT 0>
				<cfset obj["type"] = "PRIMARY">
			<cfelseif Find("nonclustered, unique", description) GT 0>
				<cfset obj["type"] = "UNIQUE">
			<cfelse>
				<cfset obj["type"] = "INDEX">
			</cfif>

			<cfset retVal[obj["name"]] = obj>
		</cfloop>

		<cfreturn retVal>
	</cffunction>

	<!---
	 * Returns an array of objects with Foreign key data
	 *
	 * Difference: the objects are maps (see array_()), and the query reads
	 * the system tables of SQL Server 2000 (see the header).
	 *
	 * @return array<string, stdClass>
	 *
	 * @throws DatabaseException
	--->
	<cffunction name="_foreignKeyData" access="private" returntype="any" output="no">
		<cfargument name="table" type="string" required="yes">
		<cfset var sql = "SELECT fo.name AS constraint_name, po.name AS table_name, pc.name AS column_name, ro.name AS foreign_table_name, rc2.name AS foreign_column_name, rc.DELETE_RULE AS delete_rule, rc.UPDATE_RULE AS update_rule, rc.MATCH_OPTION AS match_option FROM sysforeignkeys fk INNER JOIN sysobjects fo ON fo.id = fk.constid INNER JOIN sysobjects po ON po.id = fk.fkeyid INNER JOIN syscolumns pc ON pc.id = fk.fkeyid AND pc.colid = fk.fkey INNER JOIN sysobjects ro ON ro.id = fk.rkeyid INNER JOIN syscolumns rc2 ON rc2.id = fk.rkeyid AND rc2.colid = fk.rkey INNER JOIN INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS rc ON rc.CONSTRAINT_NAME = fo.name WHERE po.name = " & this.escape(arguments.table) & " ORDER BY fo.name, fk.keyno">
		<cfset var query_ = this.query(sql)>
		<cfset var rows = "">
		<cfset var row = "">
		<cfset var indexes = array_()>
		<cfset var data = ArrayNew(1)>
		<cfset var entry = "">
		<cfset var name = "">
		<cfset var columns = "">
		<cfset var names = "">
		<cfset var i = 0>

		<cfif identical_(query_, "false") OR identical_(query_, "true")>
			<cfthrow type="ColdIgniter.Database.Exceptions.DatabaseException" message="#lang('Database.failGetForeignKeyData')#">
		</cfif>

		<cfset rows = query_.getResultArray()>

		<cfloop from="1" to="#ArrayLen(rows)#" index="i">
			<cfset row = rows[i]>
			<cfset name = pick_(row, "constraint_name")>

			<cfif NOT array_key_exists(name, indexes)>
				<cfset indexes[name] = array_("constraint_name", name, "table_name", pick_(row, "table_name"), "column_name", ArrayNew(1), "foreign_table_name", pick_(row, "foreign_table_name"), "foreign_column_name", ArrayNew(1), "on_delete", pick_(row, "delete_rule"), "on_update", pick_(row, "update_rule"), "match", pick_(row, "match_option"))>
			</cfif>

			<cfset entry = indexes[name]>
			<cfset columns = entry["column_name"]>
			<cfset ArrayAppend(columns, pick_(row, "column_name"))>
			<cfset entry["column_name"] = columns>
			<cfset columns = entry["foreign_column_name"]>
			<cfset ArrayAppend(columns, pick_(row, "foreign_column_name"))>
			<cfset entry["foreign_column_name"] = columns>
		</cfloop>

		<cfset names = array_keys(indexes)>

		<cfloop from="1" to="#ArrayLen(names)#" index="i">
			<cfset ArrayAppend(data, indexes[names[i]])>
		</cfloop>

		<cfreturn foreignKeyDataToObjects(data)>
	</cffunction>

	<!---
	 * Disables foreign key checks temporarily.
	--->
	<cffunction name="_disableForeignKeyChecks" access="private" returntype="any" output="no">
		<cfreturn "EXEC sp_MSforeachtable ""ALTER TABLE ? NOCHECK CONSTRAINT ALL""">
	</cffunction>

	<!---
	 * Enables foreign key checks temporarily.
	--->
	<cffunction name="_enableForeignKeyChecks" access="private" returntype="any" output="no">
		<cfreturn "EXEC sp_MSforeachtable ""ALTER TABLE ? WITH CHECK CHECK CONSTRAINT ALL""">
	</cffunction>

	<!---
	 * Returns an array of objects with field data
	 *
	 * Difference: the objects are maps (see array_()) of name, type,
	 * max_length, nullable (a real boolean) and default. A default that is
	 * NULL or empty is an empty string.
	 *
	 * Difference: the rows are ordered by ORDINAL_POSITION, so the fields
	 * come in the order of the table. IS_NULLABLE is compared without case
	 * and without the spaces around it: SQL Server 2000 gives "No" and
	 * "YES".
	 *
	 * @return list<stdClass>
	 *
	 * @throws DatabaseException
	--->
	<cffunction name="_fieldData" access="private" returntype="any" output="no">
		<cfargument name="table" type="string" required="yes">
		<cfset var parts = explode(".", arguments.table)>
		<cfset var table_ = parts[ArrayLen(parts)]>
		<cfset var schema_ = "">
		<cfset var sql = "">
		<cfset var query_ = "">
		<cfset var rows = "">
		<cfset var row = "">
		<cfset var obj = "">
		<cfset var retVal = ArrayNew(1)>
		<cfset var length = "">
		<cfset var maxLength = "">
		<cfset var i = 0>

		<cfif ArrayLen(parts) GT 1>
			<cfset schema_ = parts[ArrayLen(parts) - 1]>
		</cfif>

		<cfset sql = "SELECT COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH, NUMERIC_PRECISION, COLUMN_DEFAULT, IS_NULLABLE FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME= " & this.escape(table_)>

		<cfif Len(schema_) GT 0>
			<cfset sql = sql & " AND TABLE_SCHEMA = " & this.escape(schema_)>
		</cfif>

		<cfset sql = sql & " ORDER BY ORDINAL_POSITION">
		<cfset query_ = this.query(sql)>

		<cfif identical_(query_, "false") OR identical_(query_, "true")>
			<cfthrow type="ColdIgniter.Database.Exceptions.DatabaseException" message="#lang('Database.failGetFieldData')#">
		</cfif>

		<cfset rows = query_.getResultArray()>

		<cfloop from="1" to="#ArrayLen(rows)#" index="i">
			<cfset row = rows[i]>
			<cfset length = pick_(row, "CHARACTER_MAXIMUM_LENGTH")>

			<cfif IsNumeric(length) AND Val(length) GT 0>
				<cfset maxLength = length>
			<cfelseif IsNumeric(length) AND Val(length) EQ -1>
				<cfset maxLength = "max">
			<cfelse>
				<cfset maxLength = pick_(row, "NUMERIC_PRECISION")>
			</cfif>

			<cfset obj = array_("name", pick_(row, "COLUMN_NAME"), "type", pick_(row, "DATA_TYPE"), "max_length", maxLength, "nullable", JavaCast("boolean", CompareNoCase(trim_(pick_(row, "IS_NULLABLE")), "NO") NEQ 0), "default", normalizeDefault(pick_(row, "COLUMN_DEFAULT")))>

			<cfset ArrayAppend(retVal, obj)>
		</cfloop>

		<cfreturn retVal>
	</cffunction>

	<!---
	 * Normalizes SQL Server default values by removing outer parentheses,
	 * handling NULL literals and unescaping string literals.
	 *
	 * Difference: a NULL gives an empty string.
	--->
	<cffunction name="normalizeDefault" access="private" returntype="string" output="no">
		<cfargument name="default" type="string" required="yes">
		<cfset var value = trim_(arguments.default)>

		<!--- Remove outer parentheses (handles both single and double wrapping) --->
		<cfloop condition="Len(value) GTE 2 AND Left(value, 1) EQ '(' AND Right(value, 1) EQ ')' AND Find(Chr(10), value) EQ 0">
			<cfset value = trim_(Mid(value, 2, Len(value) - 2))>
		</cfloop>

		<!--- Handle NULL literal --->
		<cfif CompareNoCase(value, "NULL") EQ 0>
			<cfreturn "">
		</cfif>

		<!--- Handle string literals - remove quotes and unescape --->
		<cfif Len(value) GTE 2 AND Left(value, 1) EQ "'" AND Right(value, 1) EQ "'">
			<cfreturn str_replace("''", "'", Mid(value, 2, Len(value) - 2))>
		</cfif>

		<cfreturn value>
	</cffunction>

	<!---
	 * Begin Transaction
	--->
	<cffunction name="_transBegin" access="private" returntype="boolean" output="no">
		<cfif transStatement("BEGIN TRANSACTION")>
			<cfset setTransCount(transCount() + 1)>

			<cfreturn true>
		</cfif>

		<cfreturn false>
	</cffunction>

	<!---
	 * Commit Transaction
	--->
	<cffunction name="_transCommit" access="private" returntype="boolean" output="no">
		<cfif transStatement("COMMIT TRANSACTION")>
			<cfset setTransCount(Max(0, transCount() - 1))>

			<cfreturn true>
		</cfif>

		<cfreturn false>
	</cffunction>

	<!---
	 * Rollback Transaction
	 *
	 * Difference: the server has already rolled back after a deadlock or
	 * an error that ends the batch, and a ROLLBACK TRANSACTION is an error
	 * then. So it is only sent when a transaction is open. It ends the
	 * transactions of all the objects of the DSN (see the header).
	--->
	<cffunction name="_transRollback" access="private" returntype="boolean" output="no">
		<cfif transStatement("IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION")>
			<cfset setTransCount(0)>

			<cfreturn true>
		</cfif>

		<cfreturn false>
	</cffunction>

	<!---
	 * The number of transactions that the objects of this request have
	 * begun on the DSN and not ended.
	 *
	 * Not in the original (see the header).
	--->
	<cffunction name="transCount" access="private" returntype="numeric" output="no">

		<cfif NOT StructKeyExists(request, "ColdIgniter") OR NOT StructKeyExists(request.ColdIgniter, "sqlsrvTransactions") OR NOT StructKeyExists(request.ColdIgniter.sqlsrvTransactions, this.DSN)>
			<cfreturn 0>
		</cfif>

		<cfreturn request.ColdIgniter.sqlsrvTransactions[this.DSN]>
	</cffunction>

	<!---
	 * Keeps the number of open transactions of the DSN for the request.
	 *
	 * Not in the original (see the header).
	--->
	<cffunction name="setTransCount" access="private" returntype="void" output="no">
		<cfargument name="count" type="numeric" required="yes">

		<cfif NOT StructKeyExists(request, "ColdIgniter")>
			<cfset request.ColdIgniter = StructNew()>
		</cfif>

		<cfif NOT StructKeyExists(request.ColdIgniter, "sqlsrvTransactions")>
			<cfset request.ColdIgniter.sqlsrvTransactions = StructNew()>
		</cfif>

		<cfset request.ColdIgniter.sqlsrvTransactions[this.DSN] = arguments.count>
	</cffunction>

	<!---
	 * Runs a transaction statement.
	 *
	 * Not in the original.
	--->
	<cffunction name="transStatement" access="private" returntype="boolean" output="no">
		<cfargument name="sql" type="string" required="yes">
		<cfset var result = "">

		<cftry>
			<cfset result = execute(arguments.sql)>

			<cfreturn NOT identical_(result, "false")>

			<cfcatch type="any">
				<cfreturn false>
			</cfcatch>
		</cftry>
	</cffunction>

	<!---
	 * Returns the last error code and message.
	 *
	 * @return A map with code and message
	--->
	<cffunction name="error" access="public" returntype="any" output="no">
		<cfset var error_ = array_("code", "00000", "message", "")>

		<cfif Len(this.lastErrorState) GT 0>
			<cfif Len(this.lastErrorCode) GT 0>
				<cfset error_["code"] = this.lastErrorState & "/" & this.lastErrorCode>
			<cfelse>
				<cfset error_["code"] = this.lastErrorState>
			</cfif>
		<cfelseif Len(this.lastErrorCode) GT 0>
			<cfset error_["code"] = this.lastErrorCode>
		</cfif>

		<cfset error_["message"] = this.lastErrorMessage>

		<cfreturn error_>
	</cffunction>

	<!---
	 * Returns the total number of rows affected by this query.
	 *
	 * Difference: the count of the last INSERT, UPDATE or DELETE (see the
	 * header). It is 0 after any other statement.
	--->
	<cffunction name="affectedRows" access="public" returntype="numeric" output="no">
		<cfreturn this.lastAffectedRows>
	</cffunction>

	<!---
	 * Select a specific database table to use.
	 *
	 * Difference: see the header.
	 *
	 * @return bool
	--->
	<cffunction name="setDatabase" access="public" returntype="any" output="no">
		<cfargument name="databaseName" type="string" required="no" default="">
		<cfset var name = arguments.databaseName>

		<cfif Len(name) EQ 0>
			<cfset name = this.database>
		</cfif>

		<!--- If the DB name is still empty, proceed to initialize it. --->
		<cfif identical_(this.connID, "false")>
			<cfset this.initialize_()>
		</cfif>

		<cfif NOT identical_(execute("USE " & _escapeString(name)), "false")>
			<cfset this.database = name>
			<cfset this.dataCache = CreateObject("java", "java.util.LinkedHashMap").init()>

			<cfreturn "true">
		</cfif>

		<cfreturn "false">
	</cffunction>

	<!---
	 * Executes the query against the database.
	 *
	 * Difference: an INSERT, UPDATE or DELETE statement is sent with a
	 * select of @@ROWCOUNT and SCOPE_IDENTITY() (see the header). The
	 * result of a statement without a record set is the text "true".
	 *
	 * @return false|query|string The query, "true" or "false"
	 *
	 * @throws DatabaseException
	--->
	<cffunction name="execute" access="private" returntype="any" output="no">
		<cfargument name="sql" type="string" required="yes">
		<cfset var q = "">
		<cfset var batch = arguments.sql>
		<cfset var isChange = "false">
		<cfset var counted = REFind("^(SET [^#Chr(10)#]*#Chr(10)#){0,3}DECLARE @ci_rows INT#Chr(10)#", arguments.sql) EQ 1>
		<cfset var identityOn = "">
		<cfset var identityTable = "">
		<cfset var rowsOf = "@@ROWCOUNT">
		<cfset var guard = "">
		<cfset var clean = "">
		<cfset var state = "">
		<cfset var native = "">
		<cfset var detail = "">
		<cfset var message = "">
		<cfset var newID = "">

		<cfset this.lastErrorState = "">
		<cfset this.lastErrorCode = "">
		<cfset this.lastErrorMessage = "">
		<cfset this.lastAffectedRows = 0>

		<!---
		 The data source hands a connection on to the next request as it is:
		 a transaction that a request left open is still open there
		 (verified on the server). So the first statement of a request on
		 a DSN is preceded by a query of its own that rolls back what is
		 left. The count is set when it has run, so it runs once. When it
		 fails, the count is not set, so a later statement tries it again
		 until a statement sets the count. The error is left to the
		 statement that follows. When a transaction was left open, a
		 statement that runs after a failed attempt runs inside it, so the
		 next attempt that works rolls back its changes too.
		--->
		<cfif NOT StructKeyExists(request, "ColdIgniter") OR NOT StructKeyExists(request.ColdIgniter, "sqlsrvTransactions") OR NOT StructKeyExists(request.ColdIgniter.sqlsrvTransactions, this.DSN)>
			<cftry>
				<cfquery name="clean" datasource="#this.DSN#">IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION</cfquery>

				<cfset setTransCount(0)>

				<cfcatch type="any">
				</cfcatch>
			</cftry>
		</cfif>

		<cfif counted OR REFindNoCase("^[[:space:]]*(INSERT|UPDATE|DELETE)[[:space:]]", arguments.sql) GT 0>
			<cfset isChange = "true">

			<cfif counted>
				<cfset rowsOf = "@ci_rows">
			</cfif>

			<cfif this.transDepth GT 0>
				<cfset guard = "IF @@TRANCOUNT = 0 BEGIN RAISERROR('The transaction is not open on this connection.', 16, 1) RETURN END" & Chr(10)>
			</cfif>

			<cfset batch = "SET NOCOUNT ON" & Chr(10) & "SET ROWCOUNT 0" & Chr(10) & guard & REReplace(arguments.sql, "[;[:space:]]+$", "") & Chr(10) & "SELECT " & rowsOf & " AS ci_affected_rows, SCOPE_IDENTITY() AS ci_insert_id" & Chr(10) & "SET NOCOUNT OFF">
		</cfif>

		<!---
		 A limit of the builder is SET ROWCOUNT n ... SET ROWCOUNT 0 in one
		 batch. An error that stops the batch (a conversion error, a
		 deadlock) leaves ROWCOUNT n on the connection, which the data
		 source hands on. So a change and a select start with SET ROWCOUNT
		 0, and after an error ROWCOUNT and IDENTITY_INSERT are set back
		 (see the catch). Other statements are sent as they are, as some
		 (CREATE PROCEDURE) must be the first of their batch.
		--->
		<cfif NOT isChange AND REFindNoCase("^[[:space:]]*SELECT[[:space:]]", arguments.sql) GT 0>
			<cfset batch = "SET ROWCOUNT 0" & Chr(10) & arguments.sql>
		</cfif>

		<cftry>
			<cfquery name="q" datasource="#this.DSN#">#PreserveSingleQuotes(batch)#</cfquery>

			<cfcatch type="any">
				<cfif StructKeyExists(cfcatch, "SQLState")>
					<cfset state = cfcatch.SQLState>
				</cfif>

				<cfif StructKeyExists(cfcatch, "NativeErrorCode")>
					<cfset native = cfcatch.NativeErrorCode>
				</cfif>

				<cfif StructKeyExists(cfcatch, "Detail") AND Len(cfcatch.Detail) GT 0>
					<cfset detail = cfcatch.Detail>
				<cfelse>
					<cfset detail = cfcatch.Message>
				</cfif>

				<cfset message = detail & " SQLSTATE: " & state & ", code: " & native>
				<cfset this.lastErrorState = state>
				<cfset this.lastErrorCode = native>
				<cfset this.lastErrorMessage = message>
				<cfset log_message("error", message)>

				<!---
				 Sets back what the stopped batch left on the connection.
				 Outside a transaction the data source may run this on
				 another connection of the pool; the SET ROWCOUNT 0 at the
				 start of the next change or select covers that case.
				--->
				<cfset identityOn = REFind("^SET IDENTITY_INSERT [^#Chr(10)#]+ ON#Chr(10)#", arguments.sql, 1, "true")>

				<cfif identityOn.pos[1] EQ 1>
					<cfset identityTable = Mid(arguments.sql, 21, identityOn.len[1] - 24)>
				</cfif>

				<cftry>
					<cfquery name="clean" datasource="#this.DSN#">SET ROWCOUNT 0</cfquery>

					<cfif Len(identityTable) GT 0>
						<cfquery name="clean" datasource="#this.DSN#">SET IDENTITY_INSERT #PreserveSingleQuotes(identityTable)# OFF</cfquery>
					</cfif>

					<cfcatch type="any">
					</cfcatch>
				</cftry>

				<cfif this.DBDebug>
					<cfthrow type="ColdIgniter.Database.Exceptions.DatabaseException" errorcode="#state#/#native#" message="#message#">
				</cfif>

				<cfreturn "false">
			</cfcatch>
		</cftry>

		<!---
		 A statement without a record set (DROP TABLE, CREATE TABLE) takes
		 the variable of the query away (verified on the server).
		--->
		<cfif NOT IsDefined("q")>
			<cfreturn "true">
		</cfif>

		<cfif isChange AND IsQuery(q)>
			<cfset this.lastAffectedRows = Val(q.ci_affected_rows[1])>
			<cfset newID = q.ci_insert_id[1]>

			<!--- An INSERT into a table without an identity column gives 0. --->
			<cfif REFindNoCase("^[[:space:]]*INSERT[[:space:]]", arguments.sql) GT 0>
				<cfset this.lastInsertID = Int(Val(newID))>
			</cfif>

			<cfreturn "true">
		</cfif>

		<cfif IsQuery(q)>
			<cfreturn q>
		</cfif>

		<cfreturn "true">
	</cffunction>

	<!---
	 * Returns the last error encountered by this connection.
	 *
	 * @deprecated Use error() instead.
	 *
	 * @return A map with code and message
	--->
	<cffunction name="getError" access="public" returntype="any" output="no">
		<cfreturn this.error()>
	</cffunction>

	<!---
	 * Returns the database platform
	--->
	<cffunction name="getPlatform" access="public" returntype="string" output="no">
		<cfreturn this.DBDriver>
	</cffunction>

	<!---
	 * Returns a string containing the version of the database being used.
	 *
	 * Difference: the original reads SQLServerVersion from the driver,
	 * which pads the parts ("08.00.0760"). This is the ProductVersion of
	 * the server ("8.00.760").
	--->
	<cffunction name="getVersion" access="public" returntype="string" output="no">
		<cfset var result = "">
		<cfset var version = "">

		<cfif array_key_exists("version", this.dataCache)>
			<cfreturn this.dataCache["version"]>
		</cfif>

		<cfif identical_(this.connID, "false")>
			<cfset this.initialize_()>
		</cfif>

		<cfset result = execute("SELECT CONVERT(varchar(128), SERVERPROPERTY('ProductVersion')) AS version")>

		<cfif IsQuery(result) AND result.recordCount GT 0>
			<cfset version = result.version[1]>
		</cfif>

		<cfset this.dataCache["version"] = version>

		<cfreturn version>
	</cffunction>

	<!---
	 * Determines if the statement is a write-type query or not.
	 *
	 * @return bool
	--->
	<cffunction name="isWriteType" access="public" returntype="boolean" output="no">
		<cfargument name="sql" type="string" required="yes">

		<cfif REFindNoCase("^[[:space:]]*""?EXEC[[:space:]]*sp_rename[[:space:]]", arguments.sql) GT 0>
			<cfreturn true>
		</cfif>

		<cfreturn parent.isWriteType(arguments.sql)>
	</cffunction>

	<!---
	 * Reads a column of a row, with the case of the name as it is written
	 * or in upper case (a query of 6.1 gives upper case names).
	 *
	 * Not in the original.
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
