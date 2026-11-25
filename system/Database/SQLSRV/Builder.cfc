<!---
 * Builder for SQLSRV
 *
 * @todo auto check for TextCastToInt
 * @todo auto check for InsertIndexValue
 * @todo replace: delete index entries before insert
 *
 * Difference: the original extends BaseBuilder. This class is in another
 * folder, so it is mixed in with parent (see the reference, "How
 * components are located").
 *
 * Difference: the target is SQL Server 2000 SP3, and the original writes
 * the syntax of 2012 and later. What changes:
 * - _limit() writes TOP, not OFFSET ... FETCH. A limit alone is TOP n.
 *   With an offset, get() asks for TOP offset+limit and the result skips
 *   the first "offset" rows (see Result.skipRows()), so every page is
 *   right and no ORDER BY is needed. Where the string is not run by get()
 *   (getCompiledSelect(), a subquery, a union) the query is nested: TOP
 *   offset+limit in the ORDER BY of the query, then TOP limit in the
 *   reverse of it, then the original order again. get() uses this form
 *   too when the query has a union, as the offset is that of the first
 *   query only. That form needs an ORDER BY made of plain columns (a
 *   DatabaseException is thrown without one), every column of the ORDER
 *   BY must be in the select list, and every column of the result needs
 *   a name of its own (SELECT * over a join of two tables that both have
 *   "id" fails). When fewer rows than offset+limit match, the last page
 *   holds the wrong rows (it is the last "limit" rows, not the rows after
 *   the offset).
 * - _insertBatch() writes INSERT ... SELECT ... UNION ALL SELECT, as 2000
 *   has no VALUES with several rows. The type of a column is that of the
 *   UNION, so a column that has a number in one row and text in another
 *   is converted to the number type.
 * - _update() and _delete() with a limit write SET ROWCOUNT n before the
 *   statement and SET ROWCOUNT 0 after it, as 2000 has no UPDATE TOP and
 *   no DELETE TOP. An error that stops the batch leaves ROWCOUNT (or
 *   IDENTITY_INSERT) set on the connection, so Connection.execute() sets
 *   them back (see there).
 * - A batch that does not end with its one INSERT, UPDATE or DELETE (a
 *   limit, IDENTITY_INSERT, an upsert) counts its rows in the variable
 *   @ci_rows, which the connection reads as the affected rows (see
 *   Connection.execute()).
 * - increment() and decrement() use VARCHAR(8000), as VARCHAR(MAX) does
 *   not exist in 2000.
 * - _replace() writes a DELETE of the rows that have the same primary or
 *   unique key and then the INSERT, in one batch, with SET IDENTITY_INSERT
 *   around them when the table has an identity column in the data.
 * - _upsertBatch() writes, for each row, an UPDATE and an INSERT ... WHERE
 *   NOT EXISTS, as 2000 has no MERGE.
 *
 * Difference: Config\Feature is not ported yet, limitZeroAsAll is always
 * true.
--->
<cfcomponent output="no" parent="ColdIgniter\Database\BaseBuilder" hint="Builder for SQLSRV">

	<!---
	 * ORDER BY random keyword
	 *
	 * @var list<string>
	--->
	<cfset this.randomKeyword = ArrayNew(1)>
	<cfset ArrayAppend(this.randomKeyword, "NEWID()")>
	<cfset ArrayAppend(this.randomKeyword, "RAND(%d)")>

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
	 * Handle increment/decrement on text
	 *
	 * @var bool
	--->
	<cfset this.castTextToInt = "true">

	<!---
	 * Handle IDENTITY_INSERT property/
	 *
	 * @var bool
	--->
	<cfset this.keyPermission = "false">

	<!---
	 * True while get() compiles the query: the offset is then taken from
	 * the result, see _limit().
	 *
	 * Not in the original.
	 *
	 * @var bool
	--->
	<cfset this.offsetByResult_ = "false">

	<!---
	 * Groups tables in FROM clauses if needed, so there is no confusion
	 * about operator precedence.
	--->
	<cffunction name="_fromTables" access="private" returntype="string" output="no">
		<cfset var from = ArrayNew(1)>
		<cfset var value = "">
		<cfset var i = 0>

		<cfloop from="1" to="#ArrayLen(this.QBFrom)#" index="i">
			<cfset value = this.QBFrom[i]>

			<cfif str_starts_with(value, "(SELECT")>
				<cfset ArrayAppend(from, value)>
			<cfelse>
				<cfset ArrayAppend(from, getFullName(value))>
			</cfif>
		</cfloop>

		<cfreturn implode(", ", from)>
	</cffunction>

	<!---
	 * Generates a platform-specific truncate string from the supplied data
	 *
	 * If the database does not support the truncate() command,
	 * then this method maps to 'DELETE FROM table'
	--->
	<cffunction name="_truncate" access="private" returntype="string" output="no">
		<cfargument name="table" type="string" required="yes">

		<cfreturn "TRUNCATE TABLE " & getFullName(arguments.table)>
	</cffunction>

	<!---
	 * Generates the JOIN portion of the query
	 *
	 * Difference: a RawSql condition is accepted as in the base Builder
	 * (the original calls hasOperator() with it).
	 *
	 * @param RawSql|string $cond
	 * @param bool|string   $escape An empty string is null
	 *
	 * @return $this
	--->
	<cffunction name="join" access="public" returntype="any" output="no">
		<cfargument name="table" type="string" required="yes">
		<cfargument name="cond" type="any" required="yes">
		<cfargument name="type" type="string" required="no" default="">
		<cfargument name="escape" type="any" required="no" default="">
		<cfset var type_ = arguments.type>
		<cfset var table_ = arguments.table>
		<cfset var cond_ = arguments.cond>
		<cfset var escape_ = resolveEscape_(arguments.escape)>
		<cfset var matcher = "">
		<cfset var joints = ArrayNew(1)>
		<cfset var afters = ArrayNew(1)>
		<cfset var conditions = ArrayNew(1)>
		<cfset var pos = 0>
		<cfset var i = 0>
		<cfset var operator = "">
		<cfset var condition = "">
		<cfset var piece = "">

		<cfif Len(type_) GT 0>
			<cfset type_ = UCase(Trim(type_))>

			<cfif NOT in_array(type_, this.joinTypes)>
				<cfset type_ = "">
			<cfelse>
				<cfset type_ = type_ & " ">
			</cfif>
		</cfif>

		<!--- Extract any aliases that might exist. We use this information in the protectIdentifiers to know whether to add a table prefix --->
		<cfset trackAliases(table_)>

		<!--- Do we want to escape the table name? --->
		<cfif escape_>
			<cfset table_ = this.db_.protectIdentifiers(table_, "true", "", "false")>
		</cfif>

		<cfif instanceof_(cond_, "RawSql")>
			<cfset ArrayAppend(this.QBJoin, type_ & "JOIN " & getFullName(table_) & " ON " & cond_.__toString())>

			<cfreturn this>
		</cfif>

		<cfif NOT hasOperator(cond_)>
			<cfif escape_>
				<cfset cond_ = " USING (" & this.db_.escapeIdentifiers(cond_) & ")">
			<cfelse>
				<cfset cond_ = " USING (" & cond_ & ")">
			</cfif>
		<cfelseif NOT escape_>
			<cfset cond_ = " ON " & cond_>
		<cfelse>
			<!--- Split multiple conditions --->
			<cfset matcher = rxMatcher_("/\sAND\s|\sOR\s/i", cond_)>

			<cfset ArrayAppend(joints, "")>
			<cfset ArrayAppend(afters, 0)>

			<cfloop condition="matcher.find()">
				<cfset piece = matcher.group()>
				<cfset ArrayAppend(joints, piece)>
				<cfset ArrayAppend(afters, matcher.start() + Len(piece))>
			</cfloop>

			<cfset pos = Len(cond_)>

			<cfloop from="#ArrayLen(joints)#" to="1" index="i" step="-1">
				<cfset conditions[i] = substr(cond_, afters[i], pos - afters[i])>
				<cfset pos = afters[i] - Len(joints[i])>
			</cfloop>

			<cfset cond_ = " ON ">

			<cfloop from="1" to="#ArrayLen(conditions)#" index="i">
				<cfset condition = conditions[i]>
				<cfset operator = getOperator(condition)>

				<!--- Workaround for BETWEEN --->
				<cfif Len(operator) EQ 0>
					<cfset cond_ = cond_ & joints[i] & condition>
				<cfelse>
					<cfset cond_ = cond_ & joints[i]>
					<cfset matcher = rxMatcher_("/(\(*)?([\[\]\w\.\'-]+)" & preg_quote(operator) & "(.*)/i", condition)>

					<cfif matcher.find()>
						<cfset cond_ = cond_ & rxGroup_(matcher, 1) & this.db_.protectIdentifiers(rxGroup_(matcher, 2)) & operator & this.db_.protectIdentifiers(rxGroup_(matcher, 3))>
					<cfelse>
						<cfset cond_ = cond_ & condition>
					</cfif>
				</cfif>
			</cfloop>
		</cfif>

		<!--- Assemble the JOIN statement --->
		<cfset ArrayAppend(this.QBJoin, type_ & "JOIN " & getFullName(table_) & cond_)>

		<cfreturn this>
	</cffunction>

	<!---
	 * Generates a platform-specific insert string from the supplied data
	 *
	 * @todo implement check for this instead static $insertKeyPermission
	 *
	 * @param string       $table
	 * @param list<string> $keys
	 * @param list<string> $unescapedKeys
	--->
	<cffunction name="_insert" access="private" returntype="string" output="no">
		<cfargument name="table" type="string" required="yes">
		<cfargument name="keys" type="array" required="yes">
		<cfargument name="unescapedKeys" type="array" required="yes">
		<cfset var fullTableName = getFullName(arguments.table)>
		<cfset var statement = "">

		<!--- insert statement --->
		<cfset statement = "INSERT INTO " & fullTableName & " (" & implode(",", arguments.keys) & ") VALUES (" & joinList_(", ", arguments.unescapedKeys) & ")">

		<cfif this.keyPermission>
			<cfreturn addIdentity(fullTableName, statement)>
		</cfif>

		<cfreturn statement>
	</cffunction>

	<!---
	 * Insert batch statement
	 *
	 * Generates a platform-specific insert string from the supplied data.
	 *
	 * Difference: the rows are written as SELECT ... UNION ALL SELECT ...
	 * and not as VALUES (...), (...), as SQL Server 2000 has no VALUES with
	 * several rows.
	 *
	 * @param string       $table  Protected table name
	 * @param list<string> $keys
	 * @param list<list>   $values
	--->
	<cffunction name="_insertBatch" access="private" returntype="string" output="no">
		<cfargument name="table" type="string" required="yes">
		<cfargument name="keys" type="array" required="yes">
		<cfargument name="values" type="array" required="yes">
		<cfset var sql = optGet_("sql", "")>
		<cfset var data = "">
		<cfset var rows = "">
		<cfset var i = 0>

		<!--- if this is the first iteration of batch then we need to build skeleton sql --->
		<cfif Len(sql) EQ 0>
			<cfset sql = "INSERT " & compileIgnore("insert") & "INTO " & getFullName(arguments.table) & " (" & implode(", ", arguments.keys) & ")" & Chr(10) & "{:_table_:}">

			<cfset this.QBOptions["sql"] = sql>
		</cfif>

		<cfif this.QBOptions.containsKey("setQueryAsData")>
			<cfset data = this.QBOptions["setQueryAsData"]>
		<cfelse>
			<cfset rows = formatValues(arguments.values)>
			<cfset data = "">

			<cfloop from="1" to="#ArrayLen(rows)#" index="i">
				<cfif i GT 1>
					<cfset data = data & Chr(10) & "UNION ALL" & Chr(10)>
				</cfif>

				<!--- the row is "(a,b,c)": the parentheses are taken off --->
				<cfset data = data & "SELECT " & Mid(rows[i], 2, Len(rows[i]) - 2)>
			</cfloop>
		</cfif>

		<cfreturn Replace(sql, "{:_table_:}", data, "all")>
	</cffunction>

	<!---
	 * Generates a platform-specific update string from the supplied data
	 *
	 * Difference: a limit is written as SET ROWCOUNT around the statement,
	 * as SQL Server 2000 has no UPDATE TOP. The ORDER BY is kept as in the
	 * original, SQL Server does not accept it in an UPDATE.
	 *
	 * @param string $table
	 * @param map    $values
	--->
	<cffunction name="_update" access="private" returntype="string" output="no">
		<cfargument name="table" type="string" required="yes">
		<cfargument name="values" type="any" required="yes">
		<cfset var valstr = ArrayNew(1)>
		<cfset var keys = array_keys(arguments.values)>
		<cfset var fullTableName = getFullName(arguments.table)>
		<cfset var statement = "">
		<cfset var i = 0>

		<cfloop from="1" to="#ArrayLen(keys)#" index="i">
			<cfset ArrayAppend(valstr, keys[i] & " = " & strOf_(arguments.values[keys[i]]))>
		</cfloop>

		<cfset statement = "UPDATE " & fullTableName & " SET ">

		<cfset statement = statement & implode(", ", valstr) & compileWhereHaving("QBWhere") & compileOrderBy()>

		<cfif numberSet_(this.QBLimit)>
			<cfset statement = "SET ROWCOUNT " & Fix(Val(this.QBLimit)) & Chr(10) & "DECLARE @ci_rows INT" & Chr(10) & statement & Chr(10) & "SET @ci_rows = @@ROWCOUNT" & Chr(10) & "SET ROWCOUNT 0">
		</cfif>

		<cfif this.keyPermission>
			<cfreturn addIdentity(fullTableName, statement)>
		</cfif>

		<cfreturn statement>
	</cffunction>

	<!---
	 * Increments a numeric column by the specified value.
	 *
	 * Difference: VARCHAR(8000) replaces VARCHAR(MAX), which 2000 does not have.
	 *
	 * @return bool
	--->
	<cffunction name="increment" access="public" returntype="any" output="no">
		<cfargument name="column" type="string" required="yes">
		<cfargument name="value" type="numeric" required="no" default="1">
		<cfset var column_ = this.db_.protectIdentifiers(arguments.column)>
		<cfset var values = array_()>
		<cfset var sql = "">

		<cfif this.castTextToInt>
			<cfset values[column_] = "CONVERT(VARCHAR(8000),CONVERT(INT,CONVERT(VARCHAR(8000), " & column_ & ")) + " & Fix(arguments.value) & ")">
		<cfelse>
			<cfset values[column_] = column_ & " + " & Fix(arguments.value)>
		</cfif>

		<cfset sql = _update(this.QBFrom[1], values)>

		<cfif NOT this.testMode_>
			<cfset resetWrite()>

			<cfreturn this.db_.query(sql, this.binds, "false")>
		</cfif>

		<cfreturn true>
	</cffunction>

	<!---
	 * Decrements a numeric column by the specified value.
	 *
	 * Difference: VARCHAR(8000) replaces VARCHAR(MAX), which 2000 does not have.
	 *
	 * @return bool
	--->
	<cffunction name="decrement" access="public" returntype="any" output="no">
		<cfargument name="column" type="string" required="yes">
		<cfargument name="value" type="numeric" required="no" default="1">
		<cfset var column_ = this.db_.protectIdentifiers(arguments.column)>
		<cfset var values = array_()>
		<cfset var sql = "">

		<cfif this.castTextToInt>
			<cfset values[column_] = "CONVERT(VARCHAR(8000),CONVERT(INT,CONVERT(VARCHAR(8000), " & column_ & ")) - " & Fix(arguments.value) & ")">
		<cfelse>
			<cfset values[column_] = column_ & " - " & Fix(arguments.value)>
		</cfif>

		<cfset sql = _update(this.QBFrom[1], values)>

		<cfif NOT this.testMode_>
			<cfset resetWrite()>

			<cfreturn this.db_.query(sql, this.binds, "false")>
		</cfif>

		<cfreturn true>
	</cffunction>

	<!---
	 * Get full name of the table
	--->
	<cffunction name="getFullName" access="private" returntype="string" output="no">
		<cfargument name="table" type="string" required="yes">
		<cfset var table_ = arguments.table>
		<cfset var q = Chr(34)>
		<cfset var alias = "">
		<cfset var pos = Find(" ", table_)>
		<cfset var dbInfo = "">
		<cfset var database = "">
		<cfset var schema = "">
		<cfset var tableName = "">

		<cfif pos GT 0>
			<cfset alias = " " & Mid(table_, pos + 1, Len(table_))>
			<cfset table_ = Left(table_, pos - 1)>
		</cfif>

		<cfif Compare(this.db_.escapeChar, q) EQ 0>
			<cfif Find(".", table_) GT 0 AND NOT str_starts_with(table_, ".") AND Compare(Right(table_, 1), ".") NEQ 0>
				<cfset dbInfo = explode(".", table_)>
				<cfset database = this.db_.getDatabase()>
				<cfset table_ = dbInfo[1]>

				<cfif ArrayLen(dbInfo) EQ 3>
					<cfset database = str_replace(q, "", dbInfo[1])>
					<cfset schema = str_replace(q, "", dbInfo[2])>
					<cfset tableName = str_replace(q, "", dbInfo[3])>
				<cfelse>
					<cfset schema = str_replace(q, "", dbInfo[1])>
					<cfset tableName = str_replace(q, "", dbInfo[2])>
				</cfif>

				<cfreturn q & database & q & "." & q & schema & q & "." & q & str_replace(q, "", tableName) & q & alias>
			</cfif>

			<cfreturn q & this.db_.getDatabase() & q & "." & q & this.db_.schema & q & "." & q & str_replace(q, "", table_) & q & alias>
		</cfif>

		<cfreturn "[" & this.db_.getDatabase() & "].[" & this.db_.schema & "].[" & str_replace(q, "", table_) & "]" & str_replace(q, "", alias)>
	</cffunction>

	<!---
	 * Add permission statements for index value inserts
	--->
	<cffunction name="addIdentity" access="private" returntype="string" output="no">
		<cfargument name="fullTable" type="string" required="yes">
		<cfargument name="insert" type="string" required="yes">

		<cfif REFind("^(SET [^#Chr(10)#]*#Chr(10)#){0,2}DECLARE @ci_rows INT#Chr(10)#", arguments.insert) EQ 1>
			<cfreturn "SET IDENTITY_INSERT " & arguments.fullTable & " ON" & Chr(10) & arguments.insert & Chr(10) & "SET IDENTITY_INSERT " & arguments.fullTable & " OFF">
		</cfif>

		<cfreturn "SET IDENTITY_INSERT " & arguments.fullTable & " ON" & Chr(10) & "DECLARE @ci_rows INT" & Chr(10) & arguments.insert & Chr(10) & "SET @ci_rows = @@ROWCOUNT" & Chr(10) & "SET IDENTITY_INSERT " & arguments.fullTable & " OFF">
	</cffunction>

	<!---
	 * Local implementation of limit
	 *
	 * Difference: written with TOP, see the header. The original writes
	 * OFFSET and FETCH.
	 *
	 * @throws DatabaseException
	--->
	<cffunction name="_limit" access="private" returntype="string" output="no">
		<cfargument name="sql" type="string" required="yes">
		<cfargument name="offsetIgnore" type="boolean" required="no" default="false">
		<cfset var sql_ = arguments.sql>
		<cfset var limit_ = 0>
		<cfset var offset_ = 0>
		<cfset var prefix = "">
		<cfset var rest = "">
		<cfset var innerSql = "">
		<cfset var reversed = ArrayNew(1)>
		<cfset var ordered = ArrayNew(1)>
		<cfset var item = "">
		<cfset var expr = "">
		<cfset var name = "">
		<cfset var dir = "">
		<cfset var parts = "">
		<cfset var i = 0>

		<cfif NOT numberSet_(this.QBLimit)>
			<cfreturn sql_>
		</cfif>

		<cfset limit_ = Fix(Val(this.QBLimit))>

		<cfif NOT arguments.offsetIgnore AND numberSet_(this.QBOffset)>
			<cfset offset_ = Fix(Val(this.QBOffset))>
		</cfif>

		<cfif str_starts_with(sql_, "SELECT DISTINCT ")>
			<cfset prefix = "SELECT DISTINCT ">
		<cfelseif str_starts_with(sql_, "SELECT ")>
			<cfset prefix = "SELECT ">
		<cfelse>
			<cfreturn sql_>
		</cfif>

		<cfset rest = Mid(sql_, Len(prefix) + 1, Len(sql_))>

		<cfif offset_ EQ 0>
			<cfreturn prefix & "TOP " & limit_ & " " & rest>
		</cfif>

		<!--- get() skips the first rows of the result --->
		<cfif this.offsetByResult_>
			<cfreturn prefix & "TOP " & (offset_ + limit_) & " " & rest>
		</cfif>

		<cfif NOT IsArray(this.QBOrderBy) OR ArrayLen(this.QBOrderBy) EQ 0>
			<cfthrow type="ColdIgniter.Database.Exceptions.DatabaseException" message="SQL Server 2000 needs an ORDER BY to use an offset.">
		</cfif>

		<cfset innerSql = prefix & "TOP " & (offset_ + limit_) & " " & rest>

		<!--- the order of the query is written again with the names of the columns, and its reverse --->
		<cfloop from="1" to="#ArrayLen(this.QBOrderBy)#" index="i">
			<cfset item = Trim(strOf_(this.QBOrderBy[i]))>
			<cfset dir = "ASC">
			<cfset expr = item>

			<cfif Len(item) GT 5 AND Compare(UCase(Right(item, 5)), " DESC") EQ 0>
				<cfset dir = "DESC">
				<cfset expr = Trim(Left(item, Len(item) - 5))>
			<cfelseif Len(item) GT 4 AND Compare(UCase(Right(item, 4)), " ASC") EQ 0>
				<cfset expr = Trim(Left(item, Len(item) - 4))>
			</cfif>

			<cfset name = str_replace(this.db_.escapeChar, "", expr)>
			<cfset name = str_replace("[", "", name)>
			<cfset name = str_replace("]", "", name)>

			<cfif Len(name) EQ 0 OR REFind("[^A-Za-z0-9_.]", name) GT 0>
				<cfthrow type="ColdIgniter.Database.Exceptions.DatabaseException" message="SQL Server 2000 can use an offset only with an ORDER BY of plain columns.">
			</cfif>

			<cfset parts = explode(".", name)>
			<cfset name = this.db_.escapeIdentifiers(parts[ArrayLen(parts)])>

			<cfset ArrayAppend(ordered, name & " " & dir)>

			<cfif Compare(dir, "ASC") EQ 0>
				<cfset ArrayAppend(reversed, name & " DESC")>
			<cfelse>
				<cfset ArrayAppend(reversed, name & " ASC")>
			</cfif>
		</cfloop>

		<cfreturn "SELECT TOP " & limit_ & " * FROM (SELECT TOP " & limit_ & " * FROM (" & innerSql & ") _ci_a ORDER BY " & implode(", ", reversed) & ") _ci_b ORDER BY " & implode(", ", ordered)>
	</cffunction>

	<!---
	 * Compiles a replace into string and runs the query
	 *
	 * Difference: the original sets IDENTITY_INSERT with two more queries
	 * around the replace. Here _replace() writes it in the batch, only when
	 * the table has an identity column among the keys, so replace() is the
	 * one of the base Builder (replace_()).
	--->

	<!---
	 * Generates a platform-specific replace string from the supplied data
	 * on match delete and insert
	 *
	 * Difference: the original queries the existing rows and deletes them
	 * with two more queries while the statement is made, and writes the
	 * INSERT only. Here one batch is written: DELETE of the rows with the
	 * same primary or unique key, then INSERT. The batch is not atomic.
	 *
	 * @param string       $table
	 * @param list<string> $keys
	 * @param list<string> $values
	--->
	<cffunction name="_replace" access="private" returntype="string" output="no">
		<cfargument name="table" type="string" required="yes">
		<cfargument name="keys" type="array" required="yes">
		<cfargument name="values" type="array" required="yes">
		<cfset var pKeys = this.db_.getIndexData(arguments.table)>
		<cfset var names = array_keys(pKeys)>
		<cfset var keyFields = ArrayNew(1)>
		<cfset var fields = "">
		<cfset var idxType = "">
		<cfset var escField = "">
		<cfset var conds = ArrayNew(1)>
		<cfset var fullTableName = getFullName(arguments.table)>
		<cfset var sql = "">
		<cfset var identity = "">
		<cfset var i = 0>
		<cfset var j = 0>
		<cfset var k = 0>

		<!--- check whether the existing keys are part of the primary key --->
		<cfloop from="1" to="#ArrayLen(names)#" index="i">
			<cfset idxType = pKeys[names[i]]["type"]>

			<cfif Compare(idxType, "PRIMARY") EQ 0 OR Compare(idxType, "UNIQUE") EQ 0>
				<cfset fields = pKeys[names[i]]["fields"]>

				<cfloop from="1" to="#ArrayLen(fields)#" index="j">
					<cfset ArrayAppend(keyFields, fields[j])>
				</cfloop>
			</cfif>
		</cfloop>

		<!--- the fields of the index that are in the data are matched --->
		<cfloop from="1" to="#ArrayLen(keyFields)#" index="i">
			<cfset escField = this.db_.protectIdentifiers(keyFields[i])>

			<cfloop from="1" to="#ArrayLen(arguments.keys)#" index="k">
				<cfif Compare(arguments.keys[k], escField) EQ 0>
					<cfset ArrayAppend(conds, escField & " = " & strOf_(arguments.values[k]))>
				</cfif>
			</cfloop>
		</cfloop>

		<cfif ArrayLen(conds) GT 0>
			<cfset sql = "DELETE FROM " & fullTableName & " WHERE " & implode(" AND ", conds) & Chr(10)>
		</cfif>

		<cfset sql = sql & "INSERT INTO " & fullTableName & " (" & implode(",", arguments.keys) & ") VALUES (" & joinList_(",", arguments.values) & ");">

		<cfset identity = identityColumn_(arguments.table)>

		<cfif Len(identity) GT 0 AND hasKey_(arguments.keys, identity)>
			<cfreturn addIdentity(fullTableName, sql)>
		</cfif>

		<cfreturn sql>
	</cffunction>

	<!---
	 * SELECT [MAX|MIN|AVG|SUM|COUNT]()
	 *
	 * Handle float return value
	 *
	 * @return $this
	--->
	<cffunction name="maxMinAvgSum" access="private" returntype="any" output="no">
		<cfargument name="select" type="string" required="no" default="">
		<cfargument name="alias" type="string" required="no" default="">
		<cfargument name="type" type="string" required="no" default="MAX">
		<cfset var alias_ = arguments.alias>
		<cfset var sql = "">

		<!--- int functions can be handled by parent --->
		<cfif Compare(arguments.type, "AVG") NEQ 0>
			<cfreturn parent.maxMinAvgSum(arguments.select, arguments.alias, arguments.type)>
		</cfif>

		<cfif Len(arguments.select) EQ 0>
			<cfset static_("ColdIgniter\Database\Exceptions\DataException").forEmptyInputGiven("Select")>
		</cfif>

		<cfif Find(",", arguments.select) GT 0>
			<cfset static_("ColdIgniter\Database\Exceptions\DataException").forInvalidArgument("Column name not separated by comma")>
		</cfif>

		<cfif Len(alias_) EQ 0>
			<cfset alias_ = createAliasFromTable(Trim(arguments.select))>
		</cfif>

		<cfset sql = arguments.type & "( CAST( " & this.db_.protectIdentifiers(Trim(arguments.select)) & " AS FLOAT ) ) AS " & this.db_.escapeIdentifiers(Trim(alias_))>

		<cfset ArrayAppend(this.QBSelect, sql)>
		<cfset ArrayAppend(this.QBNoEscape, "")>

		<cfreturn this>
	</cffunction>

	<!---
	 * "Count All" query
	 *
	 * Generates a platform-specific query string that counts all records in
	 * the particular table
	 *
	 * @param bool $reset Are we want to clear query builder values?
	 *
	 * @return int|string when $test = true
	--->
	<cffunction name="countAll" access="public" returntype="any" output="no">
		<cfargument name="reset" type="boolean" required="no" default="true">
		<cfset var table = this.QBFrom[1]>
		<cfset var sql = this.countString & this.db_.escapeIdentifiers("numrows") & " FROM " & getFullName(table)>
		<cfset var query_ = "">
		<cfset var row = "">

		<cfif this.testMode_>
			<cfreturn sql>
		</cfif>

		<cfset query_ = this.db_.query(sql, "", "false")>

		<cfif ArrayLen(query_.getResult()) EQ 0>
			<cfreturn 0>
		</cfif>

		<cfset row = query_.getRow()>

		<cfif arguments.reset>
			<cfset resetSelect()>
		</cfif>

		<cfreturn Fix(Val(row["numrows"]))>
	</cffunction>

	<!---
	 * Delete statement
	 *
	 * Difference: a limit is written as SET ROWCOUNT around the statement,
	 * as SQL Server 2000 has no DELETE TOP.
	--->
	<cffunction name="_delete" access="private" returntype="string" output="no">
		<cfargument name="table" type="string" required="yes">
		<cfset var sql = "DELETE FROM " & getFullName(arguments.table) & compileWhereHaving("QBWhere")>

		<cfif numberSet_(this.QBLimit)>
			<cfset sql = "SET ROWCOUNT " & Fix(Val(this.QBLimit)) & Chr(10) & "DECLARE @ci_rows INT" & Chr(10) & sql & Chr(10) & "SET @ci_rows = @@ROWCOUNT" & Chr(10) & "SET ROWCOUNT 0">
		</cfif>

		<cfreturn sql>
	</cffunction>

	<!---
	 * Compiles a delete string and runs the query
	 *
	 * @param list<map>|map|RawSql|string $where_ An empty string is null
	 * @param int|string                   $limit_ An empty string is null
	 *
	 * @return bool|string
	 *
	 * @throws DatabaseException
	--->
	<cffunction name="delete" access="public" returntype="any" output="no">
		<cfargument name="where_" type="any" required="no" default="">
		<cfargument name="limit_" type="any" required="no" default="">
		<cfargument name="resetData" type="boolean" required="no" default="true">
		<cfset var limit__ = intArg_(arguments.limit_, "delete() expects $limit to be an integer")>
		<cfset var table = this.db_.protectIdentifiers(this.QBFrom[1], "true", "", "false")>
		<cfset var sql = "">

		<cfif NOT isNullArg_(arguments.where_)>
			<cfset where(arguments.where_)>
		</cfif>

		<cfif ArrayLen(this.QBWhere) EQ 0>
			<cfif this.db_.DBDebug>
				<cfthrow type="ColdIgniter.Database.Exceptions.DatabaseException" message="Deletes are not allowed unless they contain a ""where"" or ""like"" clause.">
			</cfif>

			<cfreturn "false">
		</cfif>

		<cfif Len(limit__) GT 0 AND limit__ NEQ 0>
			<cfset this.QBLimit = limit__>
		</cfif>

		<cfset sql = _delete(table)>

		<cfif arguments.resetData>
			<cfset resetWrite()>
		</cfif>

		<cfif this.testMode_>
			<cfreturn sql>
		</cfif>

		<cfreturn this.db_.query(sql, this.binds, "false")>
	</cffunction>

	<!---
	 * Compile the SELECT statement
	 *
	 * Generates a query string based on which functions were used.
	 *
	 * @param bool|string $selectOverride The text "false" or a SELECT part
	--->
	<cffunction name="compileSelect" access="private" returntype="string" output="no">
		<cfargument name="selectOverride" type="string" required="no" default="false">
		<cfset var sql = "">
		<cfset var val = "">
		<cfset var protect = "">
		<cfset var field = "">
		<cfset var i = 0>

		<!--- Write the "select" portion of the query --->
		<cfif Compare(arguments.selectOverride, "false") NEQ 0>
			<cfset sql = arguments.selectOverride>
		<cfelse>
			<cfif this.QBDistinct>
				<cfset sql = "SELECT DISTINCT ">
			<cfelse>
				<cfset sql = "SELECT ">
			</cfif>

			<!--- SQL Server can't work with select * if group by is specified --->
			<cfif ArrayLen(this.QBSelect) EQ 0 AND IsArray(this.QBGroupBy) AND ArrayLen(this.QBGroupBy) GT 0>
				<cfloop from="1" to="#ArrayLen(this.QBGroupBy)#" index="i">
					<cfset field = this.QBGroupBy[i]>

					<cfif IsSimpleValue(field)>
						<cfset ArrayAppend(this.QBSelect, field)>
					<cfelse>
						<cfset ArrayAppend(this.QBSelect, field["field"])>
					</cfif>
				</cfloop>
			</cfif>

			<cfif ArrayLen(this.QBSelect) EQ 0>
				<cfset sql = sql & "*">
			<cfelse>
				<!--- Cycle through the "select" portion of the query and prep each column name. --->
				<cfloop from="1" to="#ArrayLen(this.QBSelect)#" index="i">
					<cfset val = this.QBSelect[i]>

					<cfif instanceof_(val, "RawSql")>
						<cfset this.QBSelect[i] = val.__toString()>
					<cfelse>
						<cfif i LTE ArrayLen(this.QBNoEscape)>
							<cfset protect = this.QBNoEscape[i]>
						<cfelse>
							<cfset protect = "">
						</cfif>

						<cfset this.QBSelect[i] = this.db_.protectIdentifiers(val, "false", protect)>
					</cfif>
				</cfloop>

				<cfset sql = sql & joinList_(", ", this.QBSelect)>
			</cfif>
		</cfif>

		<!--- Write the "FROM" portion of the query --->
		<cfif ArrayLen(this.QBFrom) GT 0>
			<cfset sql = sql & Chr(10) & "FROM " & _fromTables()>
		</cfif>

		<!--- Write the "JOIN" portion of the query --->
		<cfif ArrayLen(this.QBJoin) GT 0>
			<cfset sql = sql & Chr(10) & joinList_(Chr(10), this.QBJoin)>
		</cfif>

		<cfset sql = sql & compileWhereHaving("QBWhere") & compileGroupBy() & compileWhereHaving("QBHaving") & compileOrderBy()>

		<!--- LIMIT --->
		<!--- Config\Feature.limitZeroAsAll is not ported yet, it is always true --->
		<cfif numberSet_(this.QBLimit)>
			<cfset sql = _limit(sql & Chr(10))>
		</cfif>

		<cfreturn unionInjection(sql)>
	</cffunction>

	<!---
	 * Compiles the select statement based on the other functions called
	 * and runs the query
	 *
	 * @param int|string $limit_ An empty string is null
	 * @param bool       $reset  Are we want to clear query builder values?
	 *
	 * @return BaseResult|false|string
	--->
	<cffunction name="get" access="public" returntype="any" output="no">
		<cfargument name="limit_" type="any" required="no" default="">
		<cfargument name="offset_" type="any" required="no" default="0">
		<cfargument name="reset" type="boolean" required="no" default="true">
		<cfset var limit__ = intArg_(arguments.limit_, "get() expects $limit to be an integer")>
		<cfset var result = "">

		<!--- Config\Feature.limitZeroAsAll is not ported yet, it is always true --->
		<cfif Len(limit__) GT 0 AND limit__ EQ 0>
			<cfset limit__ = "">
		</cfif>

		<cfif Len(limit__) GT 0>
			<cfset limit(limit__, arguments.offset_)>
		</cfif>

		<cfif this.testMode_>
			<cfset result = getCompiledSelect(arguments.reset)>
		<cfelse>
			<cfset result = runSelect_()>
		</cfif>

		<cfif arguments.reset>
			<cfset resetSelect()>

			<!--- Clear our binds so we don't eat up memory --->
			<cfset this.binds = array_()>
		</cfif>

		<cfreturn result>
	</cffunction>

	<!---
	 * Tells if a list of column names holds a name, in any case (the
	 * names of SQL Server columns are compared without case).
	 *
	 * Not in the original.
	--->
	<cffunction name="hasKey_" access="private" returntype="boolean" output="no">
		<cfargument name="keys" type="any" required="yes">
		<cfargument name="name" type="string" required="yes">
		<cfset var i = 0>

		<cfloop from="1" to="#ArrayLen(arguments.keys)#" index="i">
			<cfif CompareNoCase(strOf_(arguments.keys[i]), arguments.name) EQ 0>
				<cfreturn "true">
			</cfif>
		</cfloop>

		<cfreturn "false">
	</cffunction>

	<!---
	 * Runs the select of get() and getWhere(), and takes the offset from
	 * the result (see the header).
	 *
	 * Not in the original.
	 *
	 * @return BaseResult|false
	--->
	<cffunction name="runSelect_" access="private" returntype="any" output="no">
		<cfset var result = "">
		<cfset var skip = 0>

		<!--- Difference: the offset is taken from the result, see the header --->
		<cfif ArrayLen(this.QBUnion) GT 0>
			<!--- with a union the rows to skip are those of the first query only, so the nested form is used --->
			<cfreturn this.db_.query(compileSelect(), this.binds, "false")>
		</cfif>

		<cfif numberSet_(this.QBLimit) AND numberSet_(this.QBOffset)>
			<cfset skip = Fix(Val(this.QBOffset))>
		</cfif>

		<cfset this.offsetByResult_ = "true">

		<cftry>
			<cfset result = this.db_.query(compileSelect(), this.binds, "false")>

			<cfcatch type="any">
				<cfset this.offsetByResult_ = "false">
				<cfrethrow>
			</cfcatch>
		</cftry>

		<cfset this.offsetByResult_ = "false">

		<cfif skip GT 0 AND IsObject(result)>
			<cfset result.skipRows(skip)>
		</cfif>

		<cfreturn result>
	</cffunction>

	<!---
	 * Allows the where clause, limit and offset to be added directly
	 *
	 * Difference: the original has it in BaseBuilder only. It is here for
	 * the offset, see runSelect_().
	 *
	 * @param list<string>|map|RawSql|string $where An empty string is null
	 * @param int|string                     $limit An empty string is null
	 * @param int|string                     $offset
	 * @param bool                           $reset
	 *
	 * @return BaseResult|false|string
	--->
	<cffunction name="getWhere" access="public" returntype="any" output="no">
		<cfargument name="where_" type="any" required="no" default="">
		<cfargument name="limit_" type="any" required="no" default="">
		<cfargument name="offset_" type="any" required="no" default="0">
		<cfargument name="reset" type="boolean" required="no" default="true">
		<cfset var limit__ = intArg_(arguments.limit_, "getWhere() expects $limit to be an integer")>
		<cfset var result = "">

		<cfif NOT isNullArg_(arguments.where_)>
			<cfset where(arguments.where_)>
		</cfif>

		<!--- Config\Feature.limitZeroAsAll is not ported yet, it is always true --->
		<cfif Len(limit__) GT 0 AND limit__ EQ 0>
			<cfset limit__ = "">
		</cfif>

		<cfif Len(limit__) GT 0>
			<cfset limit(limit__, arguments.offset_)>
		</cfif>

		<cfif this.testMode_>
			<cfset result = getCompiledSelect(arguments.reset)>
		<cfelse>
			<cfset result = runSelect_()>
		</cfif>

		<cfif arguments.reset>
			<cfset resetSelect()>

			<!--- clear our binds so we don't pollute the next query --->
			<cfset this.binds = array_()>
		</cfif>

		<cfreturn result>
	</cffunction>

	<!---
	 * Generates a platform-specific upsertBatch string from the supplied data
	 *
	 * Difference: SQL Server 2000 has no MERGE. For each row the string has
	 * an UPDATE and an INSERT ... SELECT ... WHERE NOT EXISTS, matched on
	 * the constraints. The batch is not atomic. A constraint that is a
	 * RawSql, an update field that is a RawSql, and a query given with
	 * setQueryAsData() are not supported. The CASE of the original that
	 * gives the next identity value to a NULL one is left out.
	 *
	 * Not ported yet: RawSql constraints and update fields, and
	 * setQueryAsData() with upsert.
	 *
	 * @param string                  $table  Protected table name
	 * @param list<string>            $keys   QBKeys
	 * @param list<list<int|string>>  $values QBSet
	 *
	 * @throws DatabaseException
	--->
	<cffunction name="_upsertBatch" access="private" returntype="string" output="no">
		<cfargument name="table" type="string" required="yes">
		<cfargument name="keys" type="array" required="yes">
		<cfargument name="values" type="array" required="yes">
		<cfset var fullTableName = getFullName(arguments.table)>
		<cfset var constraints = ArrayNew(1)>
		<cfset var cMap = "">
		<cfset var cKeys = "">
		<cfset var cVal = "">
		<cfset var tableIndexes = "">
		<cfset var idxNames = "">
		<cfset var idx = "">
		<cfset var fieldNames = ArrayNew(1)>
		<cfset var wanted = "">
		<cfset var hasAll = "">
		<cfset var ufMap = "">
		<cfset var ufKeys = "">
		<cfset var ufVal = "">
		<cfset var tableIdentity = optGet_("tableIdentity", "")>
		<cfset var sql = ArrayNew(1)>
		<cfset var row = "">
		<cfset var conds = "">
		<cfset var sets = "">
		<cfset var jc = 0>
		<cfset var out = "">
		<cfset var t = 0>
		<cfset var i = 0>
		<cfset var j = 0>
		<cfset var k = 0>
		<cfset var r = 0>

		<cfif this.QBOptions.containsKey("setQueryAsData")>
			<cfthrow type="ColdIgniter.Database.Exceptions.DatabaseException" message="Not ported yet: upsert with a query as data on SQL Server 2000.">
		</cfif>

		<!--- the identity column of the table --->
		<cfset tableIdentity = identityColumn_(arguments.table)>
		<cfset this.QBOptions["tableIdentity"] = tableIdentity>

		<cfif this.QBOptions.containsKey("constraints")>
			<cfset cMap = this.QBOptions["constraints"]>
			<cfset cKeys = array_keys(cMap)>

			<cfloop from="1" to="#ArrayLen(cKeys)#" index="i">
				<cfset cVal = cMap[cKeys[i]]>

				<cfif instanceof_(cVal, "RawSql") OR isStringKey_(cKeys[i])>
					<cfthrow type="ColdIgniter.Database.Exceptions.DatabaseException" message="Not ported yet: a RawSql constraint of upsert on SQL Server 2000.">
				</cfif>

				<cfset ArrayAppend(constraints, cVal)>
			</cfloop>
		</cfif>

		<cfif ArrayLen(constraints) EQ 0>
			<cfloop from="1" to="#ArrayLen(arguments.keys)#" index="i">
				<cfset ArrayAppend(fieldNames, trimChars_(arguments.keys[i], this.db_.escapeChar))>
			</cfloop>

			<cfset tableIndexes = this.db_.getIndexData(arguments.table)>
			<cfset idxNames = array_keys(tableIndexes)>

			<!--- the primary index is used, and if there is none the first unique one, as indexes have no order --->
			<cfloop from="1" to="2" index="t">
				<cfif t EQ 1>
					<cfset wanted = "PRIMARY">
				<cfelse>
					<cfset wanted = "UNIQUE">
				</cfif>

				<cfloop from="1" to="#ArrayLen(idxNames)#" index="i">
					<cfif ArrayLen(constraints) EQ 0>
						<cfset idx = tableIndexes[idxNames[i]]>
						<cfset hasAll = true>

						<cfloop from="1" to="#ArrayLen(idx['fields'])#" index="j">
							<cfif NOT in_array(idx["fields"][j], fieldNames)>
								<cfset hasAll = false>
							</cfif>
						</cfloop>

						<cfif Compare(idx["type"], wanted) EQ 0 AND hasAll>
							<cfloop from="1" to="#ArrayLen(idx['fields'])#" index="j">
								<cfset ArrayAppend(constraints, this.db_.protectIdentifiers(idx["fields"][j]))>
							</cfloop>
						</cfif>
					</cfif>
				</cfloop>
			</cfloop>
		</cfif>

		<cfif ArrayLen(constraints) EQ 0>
			<cfif this.db_.DBDebug>
				<cfthrow type="ColdIgniter.Database.Exceptions.DatabaseException" message="No constraint found for upsert.">
			</cfif>

			<cfreturn "">
		</cfif>

		<cfif NOT this.QBOptions.containsKey("updateFields")>
			<cfset cMap = array_()>

			<cfloop from="1" to="#ArrayLen(constraints)#" index="i">
				<cfset cMap[i - 1] = constraints[i]>
			</cfloop>

			<cfset updateFields(arguments.keys, "false", cMap)>
		</cfif>

		<cfif this.QBOptions.containsKey("updateFields")>
			<cfset ufMap = this.QBOptions["updateFields"]>
		<cfelse>
			<cfset ufMap = array_()>
		</cfif>

		<cfset ufKeys = array_keys(ufMap)>

		<cfloop from="1" to="#ArrayLen(arguments.values)#" index="r">
			<cfset row = arguments.values[r]>
			<cfset conds = ArrayNew(1)>
			<cfset sets = ArrayNew(1)>

			<cfloop from="1" to="#ArrayLen(constraints)#" index="i">
				<cfset jc = 0>

				<cfloop from="1" to="#ArrayLen(arguments.keys)#" index="k">
					<cfif Compare(arguments.keys[k], constraints[i]) EQ 0>
						<cfset jc = k>
					</cfif>
				</cfloop>

				<cfif jc EQ 0>
					<cfthrow type="ColdIgniter.Database.Exceptions.DatabaseException" message="The constraint #constraints[i]# of upsert is not one of the fields of the data.">
				</cfif>

				<cfset ArrayAppend(conds, constraints[i] & " = " & strOf_(row[jc]))>
			</cfloop>

			<cfloop from="1" to="#ArrayLen(ufKeys)#" index="i">
				<cfset ufVal = ufMap[ufKeys[i]]>

				<cfif instanceof_(ufVal, "RawSql")>
					<cfthrow type="ColdIgniter.Database.Exceptions.DatabaseException" message="Not ported yet: a RawSql update field of upsert on SQL Server 2000.">
				</cfif>

				<cfset jc = 0>

				<cfloop from="1" to="#ArrayLen(arguments.keys)#" index="k">
					<cfif Compare(arguments.keys[k], ufVal) EQ 0>
						<cfset jc = k>
					</cfif>
				</cfloop>

				<cfif jc GT 0 AND NOT in_array(ufVal, constraints)>
					<cfset ArrayAppend(sets, ufKeys[i] & " = " & strOf_(row[jc]))>
				</cfif>
			</cfloop>

			<cfif ArrayLen(sets) GT 0>
				<cfset ArrayAppend(sql, "UPDATE " & fullTableName & " SET " & implode(", ", sets) & " WHERE " & implode(" AND ", conds))>
				<cfset ArrayAppend(sql, "SET @ci_rows = @ci_rows + @@ROWCOUNT")>
			</cfif>

			<cfset ArrayAppend(sql, "INSERT INTO " & fullTableName & " (" & implode(", ", arguments.keys) & ")" & Chr(10) & "SELECT " & joinList_(", ", row) & Chr(10) & "WHERE NOT EXISTS (SELECT 1 FROM " & fullTableName & " WHERE " & implode(" AND ", conds) & ");")>
			<cfset ArrayAppend(sql, "SET @ci_rows = @ci_rows + @@ROWCOUNT")>
		</cfloop>

		<!--- the batch starts with SET, so it is a write (see isWriteType()) --->
		<cfset out = "SET NOCOUNT ON" & Chr(10) & "DECLARE @ci_rows INT" & Chr(10) & "SET @ci_rows = 0" & Chr(10) & implode(Chr(10), sql)>

		<cfif Len(tableIdentity) GT 0 AND hasKey_(arguments.keys, tableIdentity)>
			<cfreturn addIdentity(fullTableName, out)>
		</cfif>

		<cfreturn out>
	</cffunction>

	<!---
	 * Gets column names from a select query
	--->
	<cffunction name="fieldsFromQuery" access="private" returntype="array" output="no">
		<cfargument name="sql" type="string" required="yes">
		<cfset var result = this.db_.query("SELECT TOP 1 * FROM (" & arguments.sql & ") _u_")>

		<cfreturn result.getFieldNames()>
	</cffunction>

	<!---
	 * The helpers below have no original: they stand in for what the
	 * original does inline.
	--->

	<!---
	 * The identity column of the table, written as an escaped name, or an
	 * empty string when there is none (the query of the original upsert)
	 *
	 * @throws DatabaseException
	--->
	<cffunction name="identityColumn_" access="private" returntype="string" output="no">
		<cfargument name="table" type="string" required="yes">
		<cfset var sql = "SELECT name from syscolumns where id = Object_ID('" & str_replace("'", "''", arguments.table) & "') and colstat = 1">
		<cfset var query_ = this.db_.query(sql)>
		<cfset var rows = "">
		<cfset var names = "">
		<cfset var identity = "">
		<cfset var i = 0>
		<cfset var j = 0>

		<cfif IsSimpleValue(query_)>
			<cfthrow type="ColdIgniter.Database.Exceptions.DatabaseException" message="Failed to get table identity">
		</cfif>

		<cfset rows = query_.getResult()>

		<cfloop from="1" to="#ArrayLen(rows)#" index="i">
			<cfset names = array_keys(rows[i])>

			<!--- the name of the column can be in any case --->
			<cfloop from="1" to="#ArrayLen(names)#" index="j">
				<cfif Compare(UCase(names[j]), "NAME") EQ 0>
					<cfset identity = Chr(34) & rows[i][names[j]] & Chr(34)>
				</cfif>
			</cfloop>
		</cfloop>

		<cfreturn identity>
	</cffunction>

</cfcomponent>
