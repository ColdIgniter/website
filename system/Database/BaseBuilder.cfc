<!---
 * Query Builder
 *
 * Difference: there is no Closure, so where the original takes a Closure
 * (a subquery, the callbacks of when() and whenNot()) this takes a callable
 * written as a list of two items: an object and the name of one of its
 * public methods, [object, "method"]. A BaseBuilder object is also accepted
 * wherever a subquery is. The method gets the new builder (or, for when()
 * and whenNot(), this builder and the condition) and has to return a value,
 * which is ignored.
 *
 * Difference: the methods that have the name of a built-in function have a
 * trailing underscore: insert_() and replace_(). The properties that have the
 * name of a method do too: db_ and testMode_.
 *
 * Difference: a null is an empty string and a boolean is the text "true" or
 * "false", so an argument that is "?bool $escape = null" is an empty string
 * for null. A value that is omitted is the null of where(), orWhere(), having()
 * and orHaving(): where("name") is "name IS NULL". An empty string is a string.
 * A null that is a value (in a map of where() or having(), in set() and in
 * the data of an insert) is new_("ColdIgniter\Database\NullValue").
 * A limit and an offset have to be numbers (they are written as numbers,
 * never quoted), and QBLimit and QBOffset are the text "false" when they
 * are not set.
 *
 * Difference: a number that has to be bound as a number is a number (use
 * JavaCast), as every literal of CFML is text, and text is quoted.
 *
 * Difference: Config\Feature is not ported yet, so limitZeroAsAll is always
 * true.
 *
 * Difference: the objects that are not a RawSql cannot be used as data
 * (objectToArray() and batchObjectToArray() throw "Not ported yet").
 *
 * Difference: a subject of a regular expression longer than the limit of
 * regex_guard_() is refused (the conditions of where() and having(), and
 * the conditions of join()). isLiteral() reads a number by its form, not by
 * the float conversion of the original. cleanClone() is not ported (it is
 * deprecated). The set of rows of setData() are sorted by key with the order
 * of the characters of Java, which is the byte order for ASCII.
 *
 * Difference: BaseConnection.table() and newQuery() find the builder of the
 * driver (the name of the connection with Builder in place of Connection)
 * and use this class when there is none, as the mock connection has none.
 *
 * @see \CodeIgniter\Database\BaseBuilder
--->
<cfcomponent output="no" hint="Query Builder">

	<!---
	 * Reset DELETE data flag
	 *
	 * @var bool
	--->
	<cfset this.resetDeleteData = "false">

	<!---
	 * QB SELECT data
	 *
	 * @var list<RawSql|string>
	--->
	<cfset this.QBSelect = ArrayNew(1)>

	<!---
	 * QB DISTINCT flag
	 *
	 * @var bool
	--->
	<cfset this.QBDistinct = "false">

	<!---
	 * QB FROM data
	 *
	 * @var list<string>
	--->
	<cfset this.QBFrom = ArrayNew(1)>

	<!---
	 * QB JOIN data
	 *
	 * @var list<string>
	--->
	<cfset this.QBJoin = ArrayNew(1)>

	<!---
	 * QB WHERE data: a list of maps with condition and escape
	 *
	 * @var list<array<string, mixed>>
	--->
	<cfset this.QBWhere = ArrayNew(1)>

	<!---
	 * QB GROUP BY data
	 *
	 * @var list<array<string, mixed>|string>
	--->
	<cfset this.QBGroupBy = ArrayNew(1)>

	<!---
	 * QB HAVING data
	 *
	 * @var list<array<string, mixed>>
	--->
	<cfset this.QBHaving = ArrayNew(1)>

	<!---
	 * QB keys
	 *
	 * @var list<string>
	--->
	<cfset this.QBKeys = ArrayNew(1)>

	<!---
	 * QB LIMIT data, the text "false" when there is none
	 *
	 * @var false|int
	--->
	<cfset this.QBLimit = "false">

	<!---
	 * QB OFFSET data, the text "false" when there is none
	 *
	 * @var false|int
	--->
	<cfset this.QBOffset = "false">

	<!---
	 * QB ORDER BY data, an empty string for null
	 *
	 * @var list<array<string, mixed>|string>|string
	--->
	<cfset this.QBOrderBy = ArrayNew(1)>

	<!---
	 * QB UNION data
	 *
	 * @var list<string>
	--->
	<cfset this.QBUnion = ArrayNew(1)>

	<!---
	 * Whether to protect identifiers in INSERT, a list of true, false and
	 * empty strings (null)
	 *
	 * @var list<bool|string>
	--->
	<cfset this.QBNoEscape = ArrayNew(1)>

	<!---
	 * QB data sets: a map of the field to the value (set()), or a list of
	 * lists of values (setData())
	 *
	 * @var array<string, string>|list<list<string>>
	--->
	<cfset this.QBSet = CreateObject("java", "java.util.LinkedHashMap").init()>

	<!---
	 * QB WHERE group started flag
	 *
	 * @var bool
	--->
	<cfset this.QBWhereGroupStarted = "false">

	<!---
	 * QB WHERE group count
	 *
	 * @var int
	--->
	<cfset this.QBWhereGroupCount = 0>

	<!---
	 * Ignore data that cause certain exceptions, for example in case of
	 * duplicate keys.
	 *
	 * @var bool
	--->
	<cfset this.QBIgnore = "false">

	<!---
	 * QB Options data
	 *
	 * @var array<string, mixed>
	--->
	<cfset this.QBOptions = CreateObject("java", "java.util.LinkedHashMap").init()>

	<!---
	 * A reference to the database connection.
	 *
	 * @var BaseConnection
	--->
	<cfset this.db_ = "">

	<!---
	 * Identity of this builder, checked when a subquery is built.
	 * Has no original: CFML has no object identity operator.
	 *
	 * @var string
	--->
	<cfset this.uid_ = "">

	<!---
	 * Name of the primary table for this instance.
	 * Tracked separately because $QBFrom gets pruned
	 * and renumbered with each _from_tables() call.
	 *
	 * @var string
	--->
	<cfset this.tableName = "">

	<!---
	 * ORDER BY random keyword
	 *
	 * @var list<string>
	--->
	<cfset this.randomKeyword = ArrayNew(1)>
	<cfset ArrayAppend(this.randomKeyword, "RAND()")>
	<cfset ArrayAppend(this.randomKeyword, "RAND(%d)")>

	<!---
	 * COUNT string
	 *
	 * @used-by CI_DB_driver::count_all()
	 * @used-by BaseBuilder::count_all_results()
	 *
	 * @var string
	--->
	<cfset this.countString = "SELECT COUNT(*) AS ">

	<!---
	 * Collects the named parameters and
	 * their values for later binding
	 * in the query object.
	 *
	 * @var array<string, list>
	--->
	<cfset this.binds = CreateObject("java", "java.util.LinkedHashMap").init()>

	<!---
	 * Collects the key count for named parameters
	 * in the query object.
	 *
	 * @var array<string, int>
	--->
	<cfset this.bindsKeyCount = CreateObject("java", "java.util.LinkedHashMap").init()>

	<!---
	 * Some databases, like SQLite, do not by default
	 * allow limiting of delete clauses.
	 *
	 * @var bool
	--->
	<cfset this.canLimitDeletes = "true">

	<!---
	 * Some databases do not by default
	 * allow limit update queries with WHERE.
	 *
	 * @var bool
	--->
	<cfset this.canLimitWhereUpdates = "true">

	<!---
	 * Specifies which sql statements
	 * support the ignore option.
	 *
	 * @var array<string, string>
	--->
	<cfset this.supportedIgnoreStatements = CreateObject("java", "java.util.LinkedHashMap").init()>

	<!---
	 * Builder testing mode status.
	 *
	 * @var bool
	--->
	<cfset this.testMode_ = "false">

	<!---
	 * Tables relation types
	 *
	 * @var list<string>
	--->
	<cfset this.joinTypes = ArrayNew(1)>
	<cfset ArrayAppend(this.joinTypes, "LEFT")>
	<cfset ArrayAppend(this.joinTypes, "RIGHT")>
	<cfset ArrayAppend(this.joinTypes, "OUTER")>
	<cfset ArrayAppend(this.joinTypes, "INNER")>
	<cfset ArrayAppend(this.joinTypes, "LEFT OUTER")>
	<cfset ArrayAppend(this.joinTypes, "RIGHT OUTER")>

	<!---
	 * Strings that determine if a string represents a literal value or a field name
	 *
	 * @var list<string>
	--->
	<cfset this.isLiteralStr = ArrayNew(1)>

	<!---
	 * RegExp used to get operators
	 *
	 * @var list<string>
	--->
	<cfset this.pregOperators = ArrayNew(1)>

	<!---
	 * Constructor
	 *
	 * @param list<string>|string|TableName $tableName tablename or tablenames with or without aliases
	 * @param array|string                  $options   A map of properties to set, or an empty string
	 *
	 * Examples of $tableName: `mytable`, `jobs j`, `jobs j, users u`, `['jobs j', 'users u']`
	 *
	 * @throws DatabaseException
	--->
	<cffunction name="__construct" access="public" returntype="any" output="no">
		<cfargument name="tableName" type="any" required="yes">
		<cfargument name="db" type="any" required="yes">
		<cfargument name="options" type="any" required="no" default="">
		<cfset var blank = "false">
		<cfset var keys = "">
		<cfset var i = 0>

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
			<cfthrow type="ColdIgniter.Database.Exceptions.DatabaseException" message="A table must be specified when creating a new Query Builder.">
		</cfif>

		<cfset this.db_ = arguments.db>
		<cfset this.uid_ = object_id_()>

		<cfif instanceof_(arguments.tableName, "TableName")>
			<cfset this.tableName = arguments.tableName.getTableName()>
			<cfset ArrayAppend(this.QBFrom, this.db_.escapeIdentifier(arguments.tableName))>
			<cfset this.db_.addTableAlias(arguments.tableName.getAlias())>
		<cfelseif IsSimpleValue(arguments.tableName) AND Find(",", arguments.tableName) EQ 0>
			<cfset this.tableName = arguments.tableName>
			<cfset from(arguments.tableName)>
		<cfelse>
			<cfset this.tableName = "">
			<cfset from(arguments.tableName)>
		</cfif>

		<cfif IsStruct(arguments.options) AND NOT IsObject(arguments.options)>
			<cfset keys = array_keys(arguments.options)>

			<cfloop from="1" to="#ArrayLen(keys)#" index="i">
				<cfif StructKeyExists(this, keys[i])>
					<cfset this[keys[i]] = arguments.options[keys[i]]>
				</cfif>
			</cfloop>
		</cfif>

		<cfreturn this>
	</cffunction>

	<!---
	 * Returns the current database connection
	 *
	 * @return BaseConnection
	--->
	<cffunction name="db" access="public" returntype="any" output="no">

		<cfreturn this.db_>
	</cffunction>

	<!---
	 * Sets a test mode status.
	 *
	 * @return $this
	--->
	<cffunction name="testMode" access="public" returntype="any" output="no">
		<cfargument name="mode" type="boolean" required="no" default="true">

		<cfset this.testMode_ = arguments.mode>

		<cfreturn this>
	</cffunction>

	<!---
	 * Gets the name of the primary table.
	--->
	<cffunction name="getTable" access="public" returntype="string" output="no">

		<cfreturn this.tableName>
	</cffunction>

	<!---
	 * Returns an array of bind values and their
	 * named parameters for binding in the query object later.
	 *
	 * @return array<string, list>
	--->
	<cffunction name="getBinds" access="public" returntype="any" output="no">

		<cfreturn this.binds>
	</cffunction>

	<!---
	 * Ignore
	 *
	 * Set ignore Flag for next insert,
	 * update or delete query.
	 *
	 * @return $this
	--->
	<cffunction name="ignore" access="public" returntype="any" output="no">
		<cfargument name="ignore" type="boolean" required="no" default="true">

		<cfset this.QBIgnore = arguments.ignore>

		<cfreturn this>
	</cffunction>

	<!---
	 * Generates the SELECT portion of the query
	 *
	 * @param list<RawSql>|list<string>|RawSql|string $select
	 * @param bool|string                             $escape An empty string is null
	 *
	 * @return $this
	--->
	<cffunction name="select" access="public" returntype="any" output="no">
		<cfargument name="select" type="any" required="no" default="*">
		<cfargument name="escape" type="any" required="no" default="">
		<cfset var escape_ = resolveEscape_(arguments.escape)>
		<cfset var items = ArrayNew(1)>
		<cfset var val = "">
		<cfset var i = 0>

		<cfif instanceof_(arguments.select, "RawSql")>
			<cfset ArrayAppend(items, arguments.select)>
		<cfelseif IsSimpleValue(arguments.select)>
			<cfif escape_>
				<cfset items = explode(",", arguments.select)>
			<cfelse>
				<cfset ArrayAppend(items, arguments.select)>
			</cfif>
		<cfelse>
			<cfset items = toList_(arguments.select)>
		</cfif>

		<cfloop from="1" to="#ArrayLen(items)#" index="i">
			<cfset val = items[i]>

			<cfif IsObject(val)>
				<cfset ArrayAppend(this.QBSelect, val)>
				<cfset ArrayAppend(this.QBNoEscape, "false")>
			<cfelse>
				<cfset val = Trim(val)>

				<cfif Len(val) GT 0>
					<cfset ArrayAppend(this.QBSelect, val)>

					<!---
					 * When doing 'SELECT NULL as field_alias FROM table'
					 * null gets taken as a field, and therefore escaped
					 * with backticks.
					 * This prevents NULL being escaped
					 * @see https://github.com/codeigniter4/CodeIgniter4/issues/1169
					--->
					<cfif Len(val) GTE 4 AND CompareNoCase(Left(val, 4), "NULL") EQ 0>
						<cfset ArrayAppend(this.QBNoEscape, "false")>
					<cfelse>
						<cfset ArrayAppend(this.QBNoEscape, escape_)>
					</cfif>
				</cfif>
			</cfif>
		</cfloop>

		<cfreturn this>
	</cffunction>

	<!---
	 * Generates a SELECT MAX(field) portion of a query
	 *
	 * @return $this
	--->
	<cffunction name="selectMax" access="public" returntype="any" output="no">
		<cfargument name="select" type="string" required="no" default="">
		<cfargument name="alias" type="string" required="no" default="">

		<cfreturn maxMinAvgSum(arguments.select, arguments.alias)>
	</cffunction>

	<!---
	 * Generates a SELECT MIN(field) portion of a query
	 *
	 * @return $this
	--->
	<cffunction name="selectMin" access="public" returntype="any" output="no">
		<cfargument name="select" type="string" required="no" default="">
		<cfargument name="alias" type="string" required="no" default="">

		<cfreturn maxMinAvgSum(arguments.select, arguments.alias, "MIN")>
	</cffunction>

	<!---
	 * Generates a SELECT AVG(field) portion of a query
	 *
	 * @return $this
	--->
	<cffunction name="selectAvg" access="public" returntype="any" output="no">
		<cfargument name="select" type="string" required="no" default="">
		<cfargument name="alias" type="string" required="no" default="">

		<cfreturn maxMinAvgSum(arguments.select, arguments.alias, "AVG")>
	</cffunction>

	<!---
	 * Generates a SELECT SUM(field) portion of a query
	 *
	 * @return $this
	--->
	<cffunction name="selectSum" access="public" returntype="any" output="no">
		<cfargument name="select" type="string" required="no" default="">
		<cfargument name="alias" type="string" required="no" default="">

		<cfreturn maxMinAvgSum(arguments.select, arguments.alias, "SUM")>
	</cffunction>

	<!---
	 * Generates a SELECT COUNT(field) portion of a query
	 *
	 * @return $this
	--->
	<cffunction name="selectCount" access="public" returntype="any" output="no">
		<cfargument name="select" type="string" required="no" default="">
		<cfargument name="alias" type="string" required="no" default="">

		<cfreturn maxMinAvgSum(arguments.select, arguments.alias, "COUNT")>
	</cffunction>

	<!---
	 * Adds a subquery to the selection
	 *
	 * @param BaseBuilder $subquery
	--->
	<cffunction name="selectSubquery" access="public" returntype="any" output="no">
		<cfargument name="subquery" type="any" required="yes">
		<cfargument name="alias" type="string" required="yes">

		<cfset ArrayAppend(this.QBSelect, buildSubquery(arguments.subquery, "true", arguments.alias))>

		<cfreturn this>
	</cffunction>

	<!---
	 * Generates a SELECT MAX(field) portion of a query
	 *
	 * @used-by selectMax()
	 * @used-by selectMin()
	 * @used-by selectAvg()
	 * @used-by selectSum()
	 *
	 * @return $this
	 *
	 * @throws DatabaseException
	 * @throws DataException
	--->
	<cffunction name="maxMinAvgSum" access="private" returntype="any" output="no">
		<cfargument name="select" type="string" required="no" default="">
		<cfargument name="alias" type="string" required="no" default="">
		<cfargument name="type" type="string" required="no" default="MAX">
		<cfset var type_ = UCase(arguments.type)>
		<cfset var alias_ = arguments.alias>
		<cfset var sql = "">

		<cfif Len(arguments.select) EQ 0>
			<cfset static_("ColdIgniter\Database\Exceptions\DataException").forEmptyInputGiven("Select")>
		</cfif>

		<cfif Find(",", arguments.select) GT 0>
			<cfset static_("ColdIgniter\Database\Exceptions\DataException").forInvalidArgument("column name not separated by comma")>
		</cfif>

		<cfif NOT in_array(type_, ListToArray("MAX,MIN,AVG,SUM,COUNT"))>
			<cfthrow type="ColdIgniter.Database.Exceptions.DatabaseException" message="Invalid function type: #type_#">
		</cfif>

		<cfif Len(alias_) EQ 0>
			<cfset alias_ = createAliasFromTable(Trim(arguments.select))>
		</cfif>

		<cfset sql = type_ & "(" & this.db_.protectIdentifiers(Trim(arguments.select)) & ") AS " & this.db_.escapeIdentifiers(Trim(alias_))>

		<cfset ArrayAppend(this.QBSelect, sql)>
		<cfset ArrayAppend(this.QBNoEscape, "")>

		<cfreturn this>
	</cffunction>

	<!---
	 * Determines the alias name based on the table
	--->
	<cffunction name="createAliasFromTable" access="private" returntype="string" output="no">
		<cfargument name="item" type="string" required="yes">
		<cfset var parts = "">

		<cfif Find(".", arguments.item) GT 0>
			<cfset parts = explode(".", arguments.item)>

			<cfreturn parts[ArrayLen(parts)]>
		</cfif>

		<cfreturn arguments.item>
	</cffunction>

	<!---
	 * Sets a flag which tells the query string compiler to add DISTINCT
	 *
	 * @return $this
	--->
	<cffunction name="distinct" access="public" returntype="any" output="no">
		<cfargument name="val" type="boolean" required="no" default="true">

		<cfset this.QBDistinct = arguments.val>

		<cfreturn this>
	</cffunction>

	<!---
	 * Generates the FROM portion of the query
	 *
	 * @param list<string>|string $from
	 *
	 * @return $this
	--->
	<cffunction name="from" access="public" returntype="any" output="no">
		<cfargument name="from_" type="any" required="yes">
		<cfargument name="overwrite" type="boolean" required="no" default="false">
		<cfset var tables = "">
		<cfset var table = "">
		<cfset var i = 0>

		<cfif arguments.overwrite>
			<cfset this.QBFrom = ArrayNew(1)>
			<cfset this.db_.setAliasedTables(ArrayNew(1))>
		</cfif>

		<cfif IsSimpleValue(arguments.from_)>
			<cfset tables = ArrayNew(1)>
			<cfset ArrayAppend(tables, arguments.from_)>
		<cfelse>
			<cfset tables = toList_(arguments.from_)>
		</cfif>

		<cfloop from="1" to="#ArrayLen(tables)#" index="i">
			<cfset table = tables[i]>

			<cfif Find(",", table) GT 0>
				<cfset from(explode(",", table))>
			<cfelse>
				<cfset table = Trim(table)>

				<cfif Len(table) GT 0>
					<cfset trackAliases(table)>
					<cfset ArrayAppend(this.QBFrom, this.db_.protectIdentifiers(table, "true", "", "false"))>
				</cfif>
			</cfif>
		</cfloop>

		<cfreturn this>
	</cffunction>

	<!---
	 * @param BaseBuilder $from Expected subquery
	 * @param string      $alias Subquery alias
	 *
	 * @return $this
	--->
	<cffunction name="fromSubquery" access="public" returntype="any" output="no">
		<cfargument name="from_" type="any" required="yes">
		<cfargument name="alias" type="string" required="yes">
		<cfset var table = buildSubquery(arguments.from_, "true", arguments.alias)>

		<cfset this.db_.addTableAlias(arguments.alias)>
		<cfset ArrayAppend(this.QBFrom, table)>

		<cfreturn this>
	</cffunction>

	<!---
	 * Generates the JOIN portion of the query
	 *
	 * @param RawSql|string $cond
	 * @param bool|string   $escape Whether not to try to escape identifiers, an empty string is null
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
			<cfset ArrayAppend(this.QBJoin, type_ & "JOIN " & table_ & " ON " & cond_.__toString())>

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

				<!--- Should never happen: the condition has no operator (it only has "AND" or "OR") --->
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
		<cfset ArrayAppend(this.QBJoin, type_ & "JOIN " & table_ & cond_)>

		<cfreturn this>
	</cffunction>

	<!---
	 * Generates the WHERE portion of the query.
	 * Separates multiple calls with 'AND'.
	 *
	 * @param list<string>|map|RawSql|string $key   An omitted value is null
	 * @param bool|string                    $escape An empty string is null
	 *
	 * @return $this
	--->
	<cffunction name="where" access="public" returntype="any" output="no">
		<cfargument name="key" type="any" required="yes">
		<cfargument name="value" type="any" required="no">
		<cfargument name="escape" type="any" required="no" default="">

		<cfif StructKeyExists(arguments, "value")>
			<cfreturn whereHaving("QBWhere", arguments.key, arguments.value, "AND ", arguments.escape, "true")>
		</cfif>

		<cfreturn whereHaving("QBWhere", arguments.key, "", "AND ", arguments.escape, "false")>
	</cffunction>

	<!---
	 * OR WHERE
	 *
	 * Generates the WHERE portion of the query.
	 * Separates multiple calls with 'OR'.
	 *
	 * @return $this
	--->
	<cffunction name="orWhere" access="public" returntype="any" output="no">
		<cfargument name="key" type="any" required="yes">
		<cfargument name="value" type="any" required="no">
		<cfargument name="escape" type="any" required="no" default="">

		<cfif StructKeyExists(arguments, "value")>
			<cfreturn whereHaving("QBWhere", arguments.key, arguments.value, "OR ", arguments.escape, "true")>
		</cfif>

		<cfreturn whereHaving("QBWhere", arguments.key, "", "OR ", arguments.escape, "false")>
	</cffunction>

	<!---
	 * @used-by where()
	 * @used-by orWhere()
	 * @used-by having()
	 * @used-by orHaving()
	 *
	 * @param list<string>|map|RawSql|string $key
	 * @param valueGiven false when the value is null
	 *
	 * @return $this
	--->
	<cffunction name="whereHaving" access="private" returntype="any" output="no">
		<cfargument name="qbKey" type="string" required="yes">
		<cfargument name="key" type="any" required="yes">
		<cfargument name="value" type="any" required="no" default="">
		<cfargument name="type" type="string" required="no" default="AND ">
		<cfargument name="escape" type="any" required="no" default="">
		<cfargument name="valueGiven" type="boolean" required="no" default="true">
		<cfset var rawSqlOnly = "false">
		<cfset var isNullValue = "false">
		<cfset var isNullEntry = "false">
		<cfset var keyValue = array_()>
		<cfset var escape_ = resolveEscape_(arguments.escape)>
		<cfset var prefix = "">
		<cfset var keys = "">
		<cfset var ops = "">
		<cfset var matcher = "">
		<cfset var entry = "">
		<cfset var bind = "">
		<cfset var k = "">
		<cfset var v = "">
		<cfset var op = "">
		<cfset var i = 0>

		<!--- IsObject() is asked first here, below in this function and in compileWhereHaving(): only a component can be an instance, and the test costs far less than the call --->
		<cfif IsObject(arguments.key) AND instanceof_(arguments.key, "RawSql")>
			<cfif arguments.valueGiven>
				<cfset keyValue[arguments.key.__toString()] = arguments.value>
			<cfelse>
				<cfset keyValue[arguments.key.__toString()] = arguments.key>
				<cfset rawSqlOnly = "true">
			</cfif>
		<cfelseif NOT isArr_(arguments.key)>
			<cfset keyValue[arguments.key] = arguments.value>
			<cfset isNullValue = NOT arguments.valueGiven>
		<cfelse>
			<cfset keyValue = toMap_(arguments.key)>
		</cfif>

		<cfif StructCount(keyValue) EQ 0>
			<cfreturn this>
		</cfif>

		<cfif clauseEmpty_(arguments.qbKey)>
			<cfset prefix = groupGetType("")>
		<cfelse>
			<cfset prefix = groupGetType(arguments.type)>
		</cfif>

		<cfset keys = array_keys(keyValue)>

		<cfloop from="1" to="#ArrayLen(keys)#" index="i">
			<cfset k = keys[i]>
			<cfset v = keyValue[k]>

			<!--- a NullValue is the null, as well as an omitted value --->
			<cfset isNullEntry = isNullValue OR (IsObject(v) AND isNullMarker_(v))>

			<cfif rawSqlOnly>
				<cfset k = "">
				<cfset op = "">
			<cfelseif NOT isNullEntry>
				<cfset ops = getOperatorFromWhereKey(k)>

				<cfif ArrayLen(ops) GT 0>
					<cfset k = Trim(k)>
					<cfset op = Trim(ops[ArrayLen(ops)])>

					<!--- the operator is at the end of the key --->
					<cfif Len(k) GTE Len(op) AND Compare(Right(k, Len(op)), op) EQ 0>
						<cfset k = RTrim(Left(k, Len(k) - Len(op)))>
						<cfset op = " " & op>
					<cfelse>
						<cfset op = "">
					</cfif>
				<cfelse>
					<cfset op = " =">
				</cfif>

				<!--- a simple value is never a subquery --->
				<cfif NOT IsSimpleValue(v) AND isSubquery(v)>
					<cfset v = buildSubquery(v, "true")>
				<cfelse>
					<cfset bind = setBind(k, v, escape_)>
					<cfset v = " :" & bind & ":">
				</cfif>
			<cfelse>
				<cfset v = "">

				<cfif NOT hasOperator(k) AND Compare(arguments.qbKey, "QBHaving") NEQ 0>
					<!--- value appears not to have been set, assign the test to IS NULL --->
					<cfset op = " IS NULL">
				<cfelse>
					<cfset matcher = rxMatcher_("/\s*(!?=|<>|IS(?:\s+NOT)?)\s*$/i", k)>

					<cfif matcher.find()>
						<cfset k = substr(k, 0, matcher.start())>

						<cfif Compare(rxGroup_(matcher, 1), "=") EQ 0>
							<cfset op = " IS NULL">
						<cfelse>
							<cfset op = " IS NOT NULL">
						</cfif>
					<cfelse>
						<cfset op = "">
					</cfif>
				</cfif>
			</cfif>

			<cfif IsObject(v) AND instanceof_(v, "RawSql")>
				<cfset entry = array_("condition", v.with(prefix & k & op & v.__toString()), "escape", escape_)>
			<cfelse>
				<cfset entry = array_("condition", prefix & k & op & v, "escape", escape_)>
			</cfif>

			<cfset appendClause_(arguments.qbKey, entry)>

			<cfset prefix = arguments.type>
		</cfloop>

		<cfreturn this>
	</cffunction>

	<!---
	 * Generates a WHERE field IN('item', 'item') SQL query,
	 * joined with 'AND' if appropriate.
	 *
	 * @param list<int|string>|BaseBuilder|callable $values
	 *
	 * @return $this
	--->
	<cffunction name="whereIn" access="public" returntype="any" output="no">
		<cfargument name="key" type="any" required="no" default="">
		<cfargument name="values" type="any" required="no" default="">
		<cfargument name="escape" type="any" required="no" default="">

		<cfreturn _whereIn(arguments.key, arguments.values, "false", "AND ", arguments.escape, "QBWhere", "whereIn")>
	</cffunction>

	<!---
	 * Generates a WHERE field IN('item', 'item') SQL query,
	 * joined with 'OR' if appropriate.
	 *
	 * @return $this
	--->
	<cffunction name="orWhereIn" access="public" returntype="any" output="no">
		<cfargument name="key" type="any" required="no" default="">
		<cfargument name="values" type="any" required="no" default="">
		<cfargument name="escape" type="any" required="no" default="">

		<cfreturn _whereIn(arguments.key, arguments.values, "false", "OR ", arguments.escape, "QBWhere", "orWhereIn")>
	</cffunction>

	<!---
	 * Generates a WHERE field NOT IN('item', 'item') SQL query,
	 * joined with 'AND' if appropriate.
	 *
	 * @return $this
	--->
	<cffunction name="whereNotIn" access="public" returntype="any" output="no">
		<cfargument name="key" type="any" required="no" default="">
		<cfargument name="values" type="any" required="no" default="">
		<cfargument name="escape" type="any" required="no" default="">

		<cfreturn _whereIn(arguments.key, arguments.values, "true", "AND ", arguments.escape, "QBWhere", "whereNotIn")>
	</cffunction>

	<!---
	 * Generates a WHERE field NOT IN('item', 'item') SQL query,
	 * joined with 'OR' if appropriate.
	 *
	 * @return $this
	--->
	<cffunction name="orWhereNotIn" access="public" returntype="any" output="no">
		<cfargument name="key" type="any" required="no" default="">
		<cfargument name="values" type="any" required="no" default="">
		<cfargument name="escape" type="any" required="no" default="">

		<cfreturn _whereIn(arguments.key, arguments.values, "true", "OR ", arguments.escape, "QBWhere", "orWhereNotIn")>
	</cffunction>

	<!---
	 * Generates a HAVING field IN('item', 'item') SQL query,
	 * joined with 'AND' if appropriate.
	 *
	 * @return $this
	--->
	<cffunction name="havingIn" access="public" returntype="any" output="no">
		<cfargument name="key" type="any" required="no" default="">
		<cfargument name="values" type="any" required="no" default="">
		<cfargument name="escape" type="any" required="no" default="">

		<cfreturn _whereIn(arguments.key, arguments.values, "false", "AND ", arguments.escape, "QBHaving", "havingIn")>
	</cffunction>

	<!---
	 * Generates a HAVING field IN('item', 'item') SQL query,
	 * joined with 'OR' if appropriate.
	 *
	 * @return $this
	--->
	<cffunction name="orHavingIn" access="public" returntype="any" output="no">
		<cfargument name="key" type="any" required="no" default="">
		<cfargument name="values" type="any" required="no" default="">
		<cfargument name="escape" type="any" required="no" default="">

		<cfreturn _whereIn(arguments.key, arguments.values, "false", "OR ", arguments.escape, "QBHaving", "orHavingIn")>
	</cffunction>

	<!---
	 * Generates a HAVING field NOT IN('item', 'item') SQL query,
	 * joined with 'AND' if appropriate.
	 *
	 * @return $this
	--->
	<cffunction name="havingNotIn" access="public" returntype="any" output="no">
		<cfargument name="key" type="any" required="no" default="">
		<cfargument name="values" type="any" required="no" default="">
		<cfargument name="escape" type="any" required="no" default="">

		<cfreturn _whereIn(arguments.key, arguments.values, "true", "AND ", arguments.escape, "QBHaving", "havingNotIn")>
	</cffunction>

	<!---
	 * Generates a HAVING field NOT IN('item', 'item') SQL query,
	 * joined with 'OR' if appropriate.
	 *
	 * @return $this
	--->
	<cffunction name="orHavingNotIn" access="public" returntype="any" output="no">
		<cfargument name="key" type="any" required="no" default="">
		<cfargument name="values" type="any" required="no" default="">
		<cfargument name="escape" type="any" required="no" default="">

		<cfreturn _whereIn(arguments.key, arguments.values, "true", "OR ", arguments.escape, "QBHaving", "orHavingNotIn")>
	</cffunction>

	<!---
	 * @used-by WhereIn()
	 * @used-by orWhereIn()
	 * @used-by whereNotIn()
	 * @used-by orWhereNotIn()
	 *
	 * @param list<int|string>|BaseBuilder|callable $values
	 * @param caller the name of the public method, for the message (the original reads it from the backtrace)
	 *
	 * @return $this
	 *
	 * @throws InvalidArgumentException
	--->
	<cffunction name="_whereIn" access="private" returntype="any" output="no">
		<cfargument name="key" type="any" required="no" default="">
		<cfargument name="values" type="any" required="no" default="">
		<cfargument name="not_" type="boolean" required="no" default="false">
		<cfargument name="type" type="string" required="no" default="AND ">
		<cfargument name="escape" type="any" required="no" default="">
		<cfargument name="clause" type="string" required="no" default="QBWhere">
		<cfargument name="caller" type="string" required="no" default="whereIn">
		<cfset var escape_ = resolveEscape_(arguments.escape)>
		<cfset var ok = arguments.key>
		<cfset var key_ = arguments.key>
		<cfset var not__ = "">
		<cfset var whereIn_ = "">
		<cfset var prefix = "">

		<cfif NOT IsSimpleValue(arguments.key) OR Len(arguments.key) EQ 0>
			<cfthrow type="ColdIgniter.Exceptions.InvalidArgumentException" message="#arguments.caller#() expects $key to be a non-empty string">
		</cfif>

		<cfif is_null(arguments.values) OR (NOT isArr_(arguments.values) AND NOT isSubquery(arguments.values))>
			<cfthrow type="ColdIgniter.Exceptions.InvalidArgumentException" message="#arguments.caller#() expects $values to be of type array or closure">
		</cfif>

		<cfif escape_>
			<cfset key_ = this.db_.protectIdentifiers(key_)>
		</cfif>

		<cfif arguments.not_>
			<cfset not__ = " NOT">
		</cfif>

		<cfif isSubquery(arguments.values)>
			<cfset whereIn_ = buildSubquery(arguments.values, "true")>
			<cfset escape_ = "false">
		<cfelse>
			<cfset whereIn_ = toList_(arguments.values)>
		</cfif>

		<cfset ok = setBind(ok, whereIn_, escape_)>

		<cfif clauseEmpty_(arguments.clause)>
			<cfset prefix = groupGetType("")>
		<cfelse>
			<cfset prefix = groupGetType(arguments.type)>
		</cfif>

		<cfset appendClause_(arguments.clause, array_("condition", prefix & key_ & not__ & " IN :" & ok & ":", "escape", "false"))>

		<cfreturn this>
	</cffunction>

	<!---
	 * Generates a %LIKE% portion of the query.
	 * Separates multiple calls with 'AND'.
	 *
	 * @param list<string>|map|RawSql|string $field
	 *
	 * @return $this
	--->
	<cffunction name="like" access="public" returntype="any" output="no">
		<cfargument name="field" type="any" required="yes">
		<cfargument name="match" type="string" required="no" default="">
		<cfargument name="side" type="string" required="no" default="both">
		<cfargument name="escape" type="any" required="no" default="">
		<cfargument name="insensitiveSearch" type="boolean" required="no" default="false">

		<cfreturn _like(arguments.field, arguments.match, "AND ", arguments.side, "", arguments.escape, arguments.insensitiveSearch)>
	</cffunction>

	<!---
	 * Generates a NOT LIKE portion of the query.
	 * Separates multiple calls with 'AND'.
	 *
	 * @return $this
	--->
	<cffunction name="notLike" access="public" returntype="any" output="no">
		<cfargument name="field" type="any" required="yes">
		<cfargument name="match" type="string" required="no" default="">
		<cfargument name="side" type="string" required="no" default="both">
		<cfargument name="escape" type="any" required="no" default="">
		<cfargument name="insensitiveSearch" type="boolean" required="no" default="false">

		<cfreturn _like(arguments.field, arguments.match, "AND ", arguments.side, "NOT", arguments.escape, arguments.insensitiveSearch)>
	</cffunction>

	<!---
	 * Generates a %LIKE% portion of the query.
	 * Separates multiple calls with 'OR'.
	 *
	 * @return $this
	--->
	<cffunction name="orLike" access="public" returntype="any" output="no">
		<cfargument name="field" type="any" required="yes">
		<cfargument name="match" type="string" required="no" default="">
		<cfargument name="side" type="string" required="no" default="both">
		<cfargument name="escape" type="any" required="no" default="">
		<cfargument name="insensitiveSearch" type="boolean" required="no" default="false">

		<cfreturn _like(arguments.field, arguments.match, "OR ", arguments.side, "", arguments.escape, arguments.insensitiveSearch)>
	</cffunction>

	<!---
	 * Generates a NOT LIKE portion of the query.
	 * Separates multiple calls with 'OR'.
	 *
	 * @return $this
	--->
	<cffunction name="orNotLike" access="public" returntype="any" output="no">
		<cfargument name="field" type="any" required="yes">
		<cfargument name="match" type="string" required="no" default="">
		<cfargument name="side" type="string" required="no" default="both">
		<cfargument name="escape" type="any" required="no" default="">
		<cfargument name="insensitiveSearch" type="boolean" required="no" default="false">

		<cfreturn _like(arguments.field, arguments.match, "OR ", arguments.side, "NOT", arguments.escape, arguments.insensitiveSearch)>
	</cffunction>

	<!---
	 * Generates a %LIKE% portion of the query.
	 * Separates multiple calls with 'AND'.
	 *
	 * @return $this
	--->
	<cffunction name="havingLike" access="public" returntype="any" output="no">
		<cfargument name="field" type="any" required="yes">
		<cfargument name="match" type="string" required="no" default="">
		<cfargument name="side" type="string" required="no" default="both">
		<cfargument name="escape" type="any" required="no" default="">
		<cfargument name="insensitiveSearch" type="boolean" required="no" default="false">

		<cfreturn _like(arguments.field, arguments.match, "AND ", arguments.side, "", arguments.escape, arguments.insensitiveSearch, "QBHaving")>
	</cffunction>

	<!---
	 * Generates a NOT LIKE portion of the query.
	 * Separates multiple calls with 'AND'.
	 *
	 * @return $this
	--->
	<cffunction name="notHavingLike" access="public" returntype="any" output="no">
		<cfargument name="field" type="any" required="yes">
		<cfargument name="match" type="string" required="no" default="">
		<cfargument name="side" type="string" required="no" default="both">
		<cfargument name="escape" type="any" required="no" default="">
		<cfargument name="insensitiveSearch" type="boolean" required="no" default="false">

		<cfreturn _like(arguments.field, arguments.match, "AND ", arguments.side, "NOT", arguments.escape, arguments.insensitiveSearch, "QBHaving")>
	</cffunction>

	<!---
	 * Generates a %LIKE% portion of the query.
	 * Separates multiple calls with 'OR'.
	 *
	 * @return $this
	--->
	<cffunction name="orHavingLike" access="public" returntype="any" output="no">
		<cfargument name="field" type="any" required="yes">
		<cfargument name="match" type="string" required="no" default="">
		<cfargument name="side" type="string" required="no" default="both">
		<cfargument name="escape" type="any" required="no" default="">
		<cfargument name="insensitiveSearch" type="boolean" required="no" default="false">

		<cfreturn _like(arguments.field, arguments.match, "OR ", arguments.side, "", arguments.escape, arguments.insensitiveSearch, "QBHaving")>
	</cffunction>

	<!---
	 * Generates a NOT LIKE portion of the query.
	 * Separates multiple calls with 'OR'.
	 *
	 * @return $this
	--->
	<cffunction name="orNotHavingLike" access="public" returntype="any" output="no">
		<cfargument name="field" type="any" required="yes">
		<cfargument name="match" type="string" required="no" default="">
		<cfargument name="side" type="string" required="no" default="both">
		<cfargument name="escape" type="any" required="no" default="">
		<cfargument name="insensitiveSearch" type="boolean" required="no" default="false">

		<cfreturn _like(arguments.field, arguments.match, "OR ", arguments.side, "NOT", arguments.escape, arguments.insensitiveSearch, "QBHaving")>
	</cffunction>

	<!---
	 * @used-by like()
	 * @used-by orLike()
	 * @used-by notLike()
	 * @used-by orNotLike()
	 * @used-by havingLike()
	 * @used-by orHavingLike()
	 * @used-by notHavingLike()
	 * @used-by orNotHavingLike()
	 *
	 * @param list<string>|map|RawSql|string $field
	 *
	 * @return $this
	--->
	<cffunction name="_like" access="private" returntype="any" output="no">
		<cfargument name="field" type="any" required="yes">
		<cfargument name="match" type="string" required="no" default="">
		<cfargument name="type" type="string" required="no" default="AND ">
		<cfargument name="side" type="string" required="no" default="both">
		<cfargument name="not_" type="string" required="no" default="">
		<cfargument name="escape" type="any" required="no" default="">
		<cfargument name="insensitiveSearch" type="boolean" required="no" default="false">
		<cfargument name="clause" type="string" required="no" default="QBWhere">
		<cfset var escape_ = resolveEscape_(arguments.escape)>
		<cfset var side_ = LCase(arguments.side)>
		<cfset var insensitive = arguments.insensitiveSearch>
		<cfset var keyValue = "">
		<cfset var keys = "">
		<cfset var prefix = "">
		<cfset var k = "">
		<cfset var v = "">
		<cfset var bind = "">
		<cfset var likeStatement = "">
		<cfset var i = 0>

		<cfif instanceof_(arguments.field, "RawSql")>
			<cfset k = arguments.field.__toString()>
			<cfset v = arguments.match>
			<cfset insensitive = "false">

			<cfif clauseEmpty_(arguments.clause)>
				<cfset prefix = groupGetType("")>
			<cfelse>
				<cfset prefix = groupGetType(arguments.type)>
			</cfif>

			<cfset bind = setBind(arguments.field.getBindingKey(), likeValue_(v, side_), escape_)>

			<cfset likeStatement = _like_statement(prefix, k, arguments.not_, bind, insensitive)>

			<!--- some platforms require an escape sequence definition for LIKE wildcards --->
			<cfif escape_ AND Len(this.db_.likeEscapeStr) GT 0>
				<cfset likeStatement = likeStatement & Replace(this.db_.likeEscapeStr, "%s", this.db_.likeEscapeChar, "all")>
			</cfif>

			<cfset appendClause_(arguments.clause, array_("condition", arguments.field.with(likeStatement), "escape", escape_))>

			<cfreturn this>
		</cfif>

		<cfif isArr_(arguments.field)>
			<cfset keyValue = toMap_(arguments.field)>
		<cfelse>
			<cfset keyValue = array_(arguments.field, arguments.match)>
		</cfif>

		<cfif StructCount(keyValue) EQ 0>
			<cfreturn this>
		</cfif>

		<cfif clauseEmpty_(arguments.clause)>
			<cfset prefix = groupGetType("")>
		<cfelse>
			<cfset prefix = groupGetType(arguments.type)>
		</cfif>

		<cfset keys = array_keys(keyValue)>

		<cfloop from="1" to="#ArrayLen(keys)#" index="i">
			<cfset k = keys[i]>
			<cfset v = keyValue[k]>

			<cfif insensitive>
				<cfset v = LCase(v)>
			</cfif>

			<cfset bind = setBind(k, likeValue_(v, side_), escape_)>

			<cfset likeStatement = _like_statement(prefix, k, arguments.not_, bind, insensitive)>

			<!--- some platforms require an escape sequence definition for LIKE wildcards --->
			<cfif escape_ AND Len(this.db_.likeEscapeStr) GT 0>
				<cfset likeStatement = likeStatement & Replace(this.db_.likeEscapeStr, "%s", this.db_.likeEscapeChar, "all")>
			</cfif>

			<cfset appendClause_(arguments.clause, array_("condition", likeStatement, "escape", escape_))>

			<cfset prefix = arguments.type>
		</cfloop>

		<cfreturn this>
	</cffunction>

	<!---
	 * Platform independent LIKE statement builder.
	--->
	<cffunction name="_like_statement" access="private" returntype="string" output="no">
		<cfargument name="prefix" type="string" required="yes">
		<cfargument name="column" type="string" required="yes">
		<cfargument name="not_" type="string" required="yes">
		<cfargument name="bind" type="string" required="yes">
		<cfargument name="insensitiveSearch" type="boolean" required="no" default="false">

		<cfif arguments.insensitiveSearch>
			<cfreturn "#arguments.prefix# LOWER(" & this.db_.escapeIdentifiers(arguments.column) & ") #arguments.not_# LIKE :#arguments.bind#:">
		</cfif>

		<cfreturn "#arguments.prefix# #arguments.column# #arguments.not_# LIKE :#arguments.bind#:">
	</cffunction>

	<!---
	 * Add UNION statement
	 *
	 * @param BaseBuilder|callable $union
	 *
	 * @return $this
	--->
	<cffunction name="union" access="public" returntype="any" output="no">
		<cfargument name="union_" type="any" required="yes">

		<cfreturn addUnionStatement(arguments.union_)>
	</cffunction>

	<!---
	 * Add UNION ALL statement
	 *
	 * @param BaseBuilder|callable $union
	 *
	 * @return $this
	--->
	<cffunction name="unionAll" access="public" returntype="any" output="no">
		<cfargument name="union_" type="any" required="yes">

		<cfreturn addUnionStatement(arguments.union_, "true")>
	</cffunction>

	<!---
	 * @used-by union()
	 * @used-by unionAll()
	 *
	 * @param BaseBuilder|callable $union
	 *
	 * @return $this
	--->
	<cffunction name="addUnionStatement" access="private" returntype="any" output="no">
		<cfargument name="union_" type="any" required="yes">
		<cfargument name="all" type="boolean" required="no" default="false">
		<cfset var sql = Chr(10) & "UNION ">

		<cfif arguments.all>
			<cfset sql = sql & "ALL ">
		</cfif>

		<cfset sql = sql & "SELECT * FROM " & buildSubquery(arguments.union_, "true", "uwrp" & (ArrayLen(this.QBUnion) + 1))>

		<cfset ArrayAppend(this.QBUnion, sql)>

		<cfreturn this>
	</cffunction>

	<!---
	 * Starts a query group.
	 *
	 * @return $this
	--->
	<cffunction name="groupStart" access="public" returntype="any" output="no">

		<cfreturn groupStartPrepare()>
	</cffunction>

	<!---
	 * Starts a query group, but ORs the group
	 *
	 * @return $this
	--->
	<cffunction name="orGroupStart" access="public" returntype="any" output="no">

		<cfreturn groupStartPrepare("", "OR ")>
	</cffunction>

	<!---
	 * Starts a query group, but NOTs the group
	 *
	 * @return $this
	--->
	<cffunction name="notGroupStart" access="public" returntype="any" output="no">

		<cfreturn groupStartPrepare("NOT ")>
	</cffunction>

	<!---
	 * Starts a query group, but OR NOTs the group
	 *
	 * @return $this
	--->
	<cffunction name="orNotGroupStart" access="public" returntype="any" output="no">

		<cfreturn groupStartPrepare("NOT ", "OR ")>
	</cffunction>

	<!---
	 * Ends a query group
	 *
	 * @return $this
	--->
	<cffunction name="groupEnd" access="public" returntype="any" output="no">

		<cfreturn groupEndPrepare()>
	</cffunction>

	<!---
	 * Starts a query group for HAVING clause.
	 *
	 * @return $this
	--->
	<cffunction name="havingGroupStart" access="public" returntype="any" output="no">

		<cfreturn groupStartPrepare("", "AND ", "QBHaving")>
	</cffunction>

	<!---
	 * Starts a query group for HAVING clause, but ORs the group.
	 *
	 * @return $this
	--->
	<cffunction name="orHavingGroupStart" access="public" returntype="any" output="no">

		<cfreturn groupStartPrepare("", "OR ", "QBHaving")>
	</cffunction>

	<!---
	 * Starts a query group for HAVING clause, but NOTs the group.
	 *
	 * @return $this
	--->
	<cffunction name="notHavingGroupStart" access="public" returntype="any" output="no">

		<cfreturn groupStartPrepare("NOT ", "AND ", "QBHaving")>
	</cffunction>

	<!---
	 * Starts a query group for HAVING clause, but OR NOTs the group.
	 *
	 * @return $this
	--->
	<cffunction name="orNotHavingGroupStart" access="public" returntype="any" output="no">

		<cfreturn groupStartPrepare("NOT ", "OR ", "QBHaving")>
	</cffunction>

	<!---
	 * Ends a query group for HAVING clause.
	 *
	 * @return $this
	--->
	<cffunction name="havingGroupEnd" access="public" returntype="any" output="no">

		<cfreturn groupEndPrepare("QBHaving")>
	</cffunction>

	<!---
	 * Prepate a query group start.
	 *
	 * @return $this
	--->
	<cffunction name="groupStartPrepare" access="private" returntype="any" output="no">
		<cfargument name="not_" type="string" required="no" default="">
		<cfargument name="type" type="string" required="no" default="AND ">
		<cfargument name="clause" type="string" required="no" default="QBWhere">
		<cfset var type_ = groupGetType(arguments.type)>
		<cfset var prefix = "">

		<cfset this.QBWhereGroupStarted = "true">

		<cfif NOT clauseEmpty_(arguments.clause)>
			<cfset prefix = type_>
		</cfif>

		<cfset this.QBWhereGroupCount = this.QBWhereGroupCount + 1>

		<cfset appendClause_(arguments.clause, array_("condition", prefix & arguments.not_ & RepeatString(" ", this.QBWhereGroupCount) & " (", "escape", "false"))>

		<cfreturn this>
	</cffunction>

	<!---
	 * Prepate a query group end.
	 *
	 * @return $this
	--->
	<cffunction name="groupEndPrepare" access="private" returntype="any" output="no">
		<cfargument name="clause" type="string" required="no" default="QBWhere">
		<cfset var count = this.QBWhereGroupCount>

		<cfset this.QBWhereGroupStarted = "false">
		<cfset this.QBWhereGroupCount = this.QBWhereGroupCount - 1>

		<cfset appendClause_(arguments.clause, array_("condition", RepeatString(" ", count) & ")", "escape", "false"))>

		<cfreturn this>
	</cffunction>

	<!---
	 * @used-by groupStart()
	 * @used-by _like()
	 * @used-by whereHaving()
	 * @used-by _whereIn()
	 * @used-by havingGroupStart()
	 *
	 * @param string $type
	--->
	<cffunction name="groupGetType" access="private" returntype="string" output="no">
		<cfargument name="type" type="string" required="yes">
		<cfset var type_ = arguments.type>

		<cfif this.QBWhereGroupStarted>
			<cfset type_ = "">
			<cfset this.QBWhereGroupStarted = "false">
		</cfif>

		<cfreturn type_>
	</cffunction>

	<!---
	 * @param list<string>|string $by
	 * @param bool|string         $escape An empty string is null
	 *
	 * @return $this
	--->
	<cffunction name="groupBy" access="public" returntype="any" output="no">
		<cfargument name="by" type="any" required="yes">
		<cfargument name="escape" type="any" required="no" default="">
		<cfset var escape_ = resolveEscape_(arguments.escape)>
		<cfset var items = ArrayNew(1)>
		<cfset var val = "">
		<cfset var i = 0>

		<cfif IsSimpleValue(arguments.by)>
			<cfif escape_>
				<cfset items = explode(",", arguments.by)>
			<cfelse>
				<cfset ArrayAppend(items, arguments.by)>
			</cfif>
		<cfelse>
			<cfset items = toList_(arguments.by)>
		</cfif>

		<cfloop from="1" to="#ArrayLen(items)#" index="i">
			<cfset val = Trim(items[i])>

			<cfif Len(val) GT 0>
				<cfset ArrayAppend(this.QBGroupBy, array_("field", val, "escape", escape_))>
			</cfif>
		</cfloop>

		<cfreturn this>
	</cffunction>

	<!---
	 * Separates multiple calls with 'AND'.
	 *
	 * @param list<string>|map|RawSql|string $key An omitted value is null
	 *
	 * @return $this
	--->
	<cffunction name="having" access="public" returntype="any" output="no">
		<cfargument name="key" type="any" required="yes">
		<cfargument name="value" type="any" required="no">
		<cfargument name="escape" type="any" required="no" default="">

		<cfif StructKeyExists(arguments, "value")>
			<cfreturn whereHaving("QBHaving", arguments.key, arguments.value, "AND ", arguments.escape, "true")>
		</cfif>

		<cfreturn whereHaving("QBHaving", arguments.key, "", "AND ", arguments.escape, "false")>
	</cffunction>

	<!---
	 * Separates multiple calls with 'OR'.
	 *
	 * @return $this
	--->
	<cffunction name="orHaving" access="public" returntype="any" output="no">
		<cfargument name="key" type="any" required="yes">
		<cfargument name="value" type="any" required="no">
		<cfargument name="escape" type="any" required="no" default="">

		<cfif StructKeyExists(arguments, "value")>
			<cfreturn whereHaving("QBHaving", arguments.key, arguments.value, "OR ", arguments.escape, "true")>
		</cfif>

		<cfreturn whereHaving("QBHaving", arguments.key, "", "OR ", arguments.escape, "false")>
	</cffunction>

	<!---
	 * @param string      $direction ASC, DESC or RANDOM
	 * @param bool|string $escape    An empty string is null
	 *
	 * @return $this
	--->
	<cffunction name="orderBy" access="public" returntype="any" output="no">
		<cfargument name="orderBy" type="string" required="yes">
		<cfargument name="direction" type="string" required="no" default="">
		<cfargument name="escape" type="any" required="no" default="">
		<cfset var orderBy_ = arguments.orderBy>
		<cfset var direction_ = UCase(Trim(arguments.direction))>
		<cfset var escape_ = "">
		<cfset var qbOrderBy = ArrayNew(1)>
		<cfset var fields = "">
		<cfset var field = "">
		<cfset var matcher = "">
		<cfset var i = 0>

		<cfif Len(orderBy_) EQ 0>
			<cfreturn this>
		</cfif>

		<cfif Compare(direction_, "RANDOM") EQ 0>
			<cfset direction_ = "">

			<cfif ctype_digit(orderBy_)>
				<cfset orderBy_ = Replace(this.randomKeyword[2], "%d", orderBy_)>
			<cfelse>
				<cfset orderBy_ = this.randomKeyword[1]>
			</cfif>

			<cfset escape_ = "false">
		<cfelse>
			<cfif Len(direction_) GT 0>
				<cfif Compare(direction_, "ASC") EQ 0 OR Compare(direction_, "DESC") EQ 0>
					<cfset direction_ = " " & direction_>
				<cfelse>
					<cfset direction_ = "">
				</cfif>
			</cfif>

			<cfset escape_ = resolveEscape_(arguments.escape)>
		</cfif>

		<cfif NOT escape_>
			<cfset ArrayAppend(qbOrderBy, array_("field", orderBy_, "direction", direction_, "escape", "false"))>
		<cfelse>
			<cfset fields = explode(",", orderBy_)>

			<cfloop from="1" to="#ArrayLen(fields)#" index="i">
				<cfset field = fields[i]>
				<cfset matcher = "">

				<cfif Len(direction_) EQ 0>
					<cfset matcher = rxMatcher_("/\s+(ASC|DESC)$/i", RTrim(field))>
				</cfif>

				<cfif IsObject(matcher) AND matcher.find()>
					<cfset ArrayAppend(qbOrderBy, array_("field", LTrim(substr(field, 0, matcher.start())), "direction", " " & rxGroup_(matcher, 1), "escape", "true"))>
				<cfelse>
					<cfset ArrayAppend(qbOrderBy, array_("field", Trim(field), "direction", direction_, "escape", "true"))>
				</cfif>
			</cfloop>
		</cfif>

		<cfif IsArray(this.QBOrderBy)>
			<cfloop from="1" to="#ArrayLen(qbOrderBy)#" index="i">
				<cfset ArrayAppend(this.QBOrderBy, qbOrderBy[i])>
			</cfloop>
		<cfelse>
			<cfset this.QBOrderBy = qbOrderBy>
		</cfif>

		<cfreturn this>
	</cffunction>

	<!---
	 * @param int|string $value  LIMIT value, an empty string is null
	 * @param int|string $offset OFFSET value, an empty string is null
	 *
	 * @return $this
	--->
	<cffunction name="limit" access="public" returntype="any" output="no">
		<cfargument name="value" type="any" required="no" default="">
		<cfargument name="offset_" type="any" required="no" default="0">
		<cfset var value_ = arguments.value>
		<cfset var offset__ = arguments.offset_>

		<!--- Config\Feature.limitZeroAsAll is not ported yet, it is always true --->
		<cfset value_ = intArg_(value_, "limit() expects $value to be an integer")>

		<cfif Len(value_) GT 0 AND value_ EQ 0>
			<cfset value_ = "">
		</cfif>

		<cfif Len(value_) GT 0>
			<cfset this.QBLimit = value_>
		</cfif>

		<cfset offset__ = intArg_(offset__, "limit() expects $offset to be an integer")>

		<cfif Len(offset__) GT 0 AND offset__ NEQ 0>
			<cfset this.QBOffset = offset__>
		</cfif>

		<cfreturn this>
	</cffunction>

	<!---
	 * Sets the OFFSET value
	 *
	 * @param int|string $offset OFFSET value
	 *
	 * @return $this
	--->
	<cffunction name="offset" access="public" returntype="any" output="no">
		<cfargument name="offset_" type="any" required="yes">
		<cfset var offset__ = intArg_(arguments.offset_, "offset() expects $offset to be an integer")>

		<cfif Len(offset__) GT 0 AND offset__ NEQ 0>
			<cfset this.QBOffset = offset__>
		</cfif>

		<cfreturn this>
	</cffunction>

	<!---
	 * Generates a platform-specific LIMIT clause.
	--->
	<cffunction name="_limit" access="private" returntype="string" output="no">
		<cfargument name="sql" type="string" required="yes">
		<cfargument name="offsetIgnore" type="boolean" required="no" default="false">
		<cfset var offsetPart = "">

		<cfif NOT arguments.offsetIgnore AND numberSet_(this.QBOffset)>
			<cfset offsetPart = this.QBOffset & ", ">
		</cfif>

		<cfreturn arguments.sql & " LIMIT " & offsetPart & this.QBLimit>
	</cffunction>

	<!---
	 * Allows key/value pairs to be set for insert(), update() or replace().
	 *
	 * @param list<string>|map|object|string $key    Field name, or an map of field/value pairs, or an object
	 * @param bool|string                    $escape An empty string is null
	 *
	 * @return $this
	--->
	<cffunction name="set" access="public" returntype="any" output="no">
		<cfargument name="key" type="any" required="yes">
		<cfargument name="value" type="any" required="no" default="">
		<cfargument name="escape" type="any" required="no" default="">
		<cfset var key_ = objectToArray(arguments.key)>
		<cfset var escape_ = resolveEscape_(arguments.escape)>
		<cfset var keys = "">
		<cfset var k = "">
		<cfset var v = "">
		<cfset var bind = "">
		<cfset var i = 0>

		<cfif isArr_(key_)>
			<cfset key_ = toMap_(key_)>
		<cfelse>
			<cfset key_ = array_(key_, arguments.value)>
		</cfif>

		<cfif IsArray(this.QBSet) AND ArrayLen(this.QBSet) EQ 0>
			<cfset this.QBSet = array_()>
		</cfif>

		<cfset keys = array_keys(key_)>

		<cfloop from="1" to="#ArrayLen(keys)#" index="i">
			<cfset k = keys[i]>
			<cfset v = key_[k]>

			<cfif escape_>
				<cfset bind = setBind(k, v, escape_)>

				<cfset this.QBSet[this.db_.protectIdentifiers(k, "false")] = ":" & bind & ":">
			<cfelse>
				<cfset this.QBSet[this.db_.protectIdentifiers(k, "false")] = v>
			</cfif>
		</cfloop>

		<cfreturn this>
	</cffunction>

	<!---
	 * Returns the previously set() data, alternatively resetting it if needed.
	 *
	 * @return map|list
	--->
	<cffunction name="getSetData" access="public" returntype="any" output="no">
		<cfargument name="clean" type="boolean" required="no" default="false">
		<cfset var data = "">
		<cfset var keys = "">
		<cfset var i = 0>

		<cfif IsArray(this.QBSet)>
			<cfset data = ArrayNew(1)>

			<cfloop from="1" to="#ArrayLen(this.QBSet)#" index="i">
				<cfset ArrayAppend(data, this.QBSet[i])>
			</cfloop>
		<cfelse>
			<cfset data = array_()>
			<cfset keys = array_keys(this.QBSet)>

			<cfloop from="1" to="#ArrayLen(keys)#" index="i">
				<cfset data[keys[i]] = this.QBSet[keys[i]]>
			</cfloop>
		</cfif>

		<cfif arguments.clean>
			<cfset this.QBSet = array_()>
		</cfif>

		<cfreturn data>
	</cffunction>

	<!---
	 * Compiles a SELECT query and returns it, without running it
	 *
	 * @param bool $reset Whether to reset the query after compiling
	--->
	<cffunction name="getCompiledSelect" access="public" returntype="string" output="no">
		<cfargument name="reset" type="boolean" required="no" default="true">
		<cfset var select_ = compileSelect()>

		<cfif arguments.reset>
			<cfset resetSelect()>
		</cfif>

		<cfreturn compileFinalQuery(select_)>
	</cffunction>

	<!---
	 * Returns a finalized, compiled query string with the bindings
	 * and dbprefix applied.
	 *
	 * @used-by getCompiledInsert()
	 * @used-by getCompiledSelect()
	 * @used-by getCompiledUpdate()
	--->
	<cffunction name="compileFinalQuery" access="private" returntype="string" output="no">
		<cfargument name="sql" type="string" required="yes">
		<cfset var qry = new_("ColdIgniter\Database\Query", this.db_)>

		<cfset qry.setQuery(arguments.sql, this.binds, "false")>

		<cfif Len(this.db_.swapPre) GT 0 AND Len(this.db_.DBPrefix) GT 0>
			<cfset qry.swapPrefix(this.db_.DBPrefix, this.db_.swapPre)>
		</cfif>

		<cfreturn qry.getQuery()>
	</cffunction>

	<!---
	 * Compiles the select statement based on the other functions called
	 * and runs the query
	 *
	 * @param int|string $limit  An empty string is null
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
			<cfset result = this.db_.query(compileSelect(), this.binds, "false")>
		</cfif>

		<cfif arguments.reset>
			<cfset resetSelect()>

			<!--- clear our binds so we don't pollute the next query --->
			<cfset this.binds = array_()>
		</cfif>

		<cfreturn result>
	</cffunction>

	<!---
	 * Generates a platform-specific query string that counts all records in
	 * the particular table
	 *
	 * @return int|string
	--->
	<cffunction name="countAll" access="public" returntype="any" output="no">
		<cfargument name="reset" type="boolean" required="no" default="true">
		<cfset var table = this.QBFrom[1]>
		<cfset var sql = this.countString & this.db_.escapeIdentifiers("numrows") & " FROM " & this.db_.protectIdentifiers(table, "true", "", "false")>
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
	 * Generates a platform-specific query string that counts all records
	 * returned by an Query Builder query.
	 *
	 * @return int|string
	--->
	<cffunction name="countAllResults" access="public" returntype="any" output="no">
		<cfargument name="reset" type="boolean" required="no" default="true">
		<cfset var orderBy_ = ArrayNew(1)>
		<cfset var limit_ = this.QBLimit>
		<cfset var select_ = "">
		<cfset var sql = "">
		<cfset var result = "">
		<cfset var row = "">

		<!--- ORDER BY usage is often problematic here (most notably on Microsoft SQL Server) and ordering is useless for a count query --->
		<cfif IsArray(this.QBOrderBy) AND ArrayLen(this.QBOrderBy) GT 0>
			<cfset orderBy_ = this.QBOrderBy>
			<cfset this.QBOrderBy = "">
		</cfif>

		<cfset this.QBLimit = "false">

		<cfif this.QBDistinct OR ArrayLen(this.QBGroupBy) GT 0>
			<!--- we need to backup the original SELECT in case DBPrefix is used --->
			<cfset select_ = this.QBSelect>
			<cfset sql = this.countString & this.db_.protectIdentifiers("numrows") & Chr(10) & "FROM (" & Chr(10) & compileSelect() & Chr(10) & ") CI_count_all_results">

			<!--- restore SELECT part --->
			<cfset this.QBSelect = select_>
		<cfelse>
			<cfset sql = compileSelect(this.countString & this.db_.protectIdentifiers("numrows"))>
		</cfif>

		<cfif this.testMode_>
			<cfreturn sql>
		</cfif>

		<cfset result = this.db_.query(sql, this.binds, "false")>

		<cfif arguments.reset>
			<cfset resetSelect()>
		<cfelseif NOT IsArray(this.QBOrderBy)>
			<cfset this.QBOrderBy = orderBy_>
		</cfif>

		<!--- restore the LIMIT setting --->
		<cfset this.QBLimit = limit_>

		<cfif IsObject(result)>
			<cfset row = result.getRow()>
		</cfif>

		<cfif NOT IsStruct(row)>
			<cfreturn 0>
		</cfif>

		<cfreturn Fix(Val(row["numrows"]))>
	</cffunction>

	<!---
	 * Get compiled QBWhere
	 *
	 * @return list<array<string, mixed>>
	--->
	<cffunction name="getCompiledQBWhere" access="public" returntype="any" output="no">

		<cfreturn this.QBWhere>
	</cffunction>

	<!---
	 * Allows the where clause, limit and offset to be added directly
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
			<cfset result = this.db_.query(compileSelect(), this.binds, "false")>
		</cfif>

		<cfif arguments.reset>
			<cfset resetSelect()>

			<!--- clear our binds so we don't pollute the next query --->
			<cfset this.binds = array_()>
		</cfif>

		<cfreturn result>
	</cffunction>

	<!---
	 * Compiles batch insert/update/upsert/delete strings and runs the queries
	 *
	 * @param string $renderMethod _insertBatch, _upsertBatch, _updateBatch or _deleteBatch
	 *
	 * @return false|int|list<string> Number of rows affected or false on failure, SQL array when testMode
	 *
	 * @throws DatabaseException
	--->
	<cffunction name="batchExecute" access="private" returntype="any" output="no">
		<cfargument name="renderMethod" type="string" required="yes">
		<cfargument name="batchSize" type="numeric" required="no" default="100">
		<cfset var batchSize_ = arguments.batchSize>
		<cfset var table = "">
		<cfset var affectedRows = 0>
		<cfset var savedSQL = ArrayNew(1)>
		<cfset var cnt = 0>
		<cfset var qbSet = ArrayNew(1)>
		<cfset var sql = "">
		<cfset var i = 0>
		<cfset var j = 0>

		<cfif setEmpty_()>
			<cfif this.db_.DBDebug>
				<cfthrow type="ColdIgniter.Database.Exceptions.DatabaseException" message="#Mid(arguments.renderMethod, 2, Len(arguments.renderMethod) - 1)#() has no data.">
			</cfif>

			<cfreturn "false">
		</cfif>

		<cfset table = this.db_.protectIdentifiers(this.QBFrom[1], "true", "", "false")>

		<cfset cnt = ArrayLen(this.QBSet)>

		<!--- batch size 0 for unlimited --->
		<cfif batchSize_ EQ 0>
			<cfset batchSize_ = cnt>
		</cfif>

		<cfloop from="1" to="#cnt#" index="i" step="#batchSize_#">
			<cfset qbSet = ArrayNew(1)>

			<cfloop from="#i#" to="#Min(i + batchSize_ - 1, cnt)#" index="j">
				<cfset ArrayAppend(qbSet, this.QBSet[j])>
			</cfloop>

			<cfif Compare(arguments.renderMethod, "_insertBatch") EQ 0>
				<cfset sql = _insertBatch(table, this.QBKeys, qbSet)>
			<cfelseif Compare(arguments.renderMethod, "_upsertBatch") EQ 0>
				<cfset sql = _upsertBatch(table, this.QBKeys, qbSet)>
			<cfelseif Compare(arguments.renderMethod, "_updateBatch") EQ 0>
				<cfset sql = _updateBatch(table, this.QBKeys, qbSet)>
			<cfelseif Compare(arguments.renderMethod, "_deleteBatch") EQ 0>
				<cfset sql = _deleteBatch(table, this.QBKeys, qbSet)>
			<cfelse>
				<cfthrow type="ColdIgniter.Exceptions.InvalidArgumentException" message="Unknown render method: #arguments.renderMethod#">
			</cfif>

			<cfif Len(sql) EQ 0>
				<cfreturn "false">
			</cfif>

			<cfif this.testMode_>
				<cfset ArrayAppend(savedSQL, sql)>
			<cfelse>
				<cfset this.db_.query(sql, "", "false")>

				<cfset affectedRows = affectedRows + this.db_.affectedRows()>
			</cfif>
		</cfloop>

		<cfif NOT this.testMode_>
			<cfset resetWrite()>
		</cfif>

		<cfif this.testMode_>
			<cfreturn savedSQL>
		</cfif>

		<cfreturn affectedRows>
	</cffunction>

	<!---
	 * Allows a row or multiple rows to be set for batch inserts/upserts/updates
	 *
	 * @param list<map>|map $set  One row, or a list of rows
	 * @param bool|string   $escape An empty string is null
	 * @param string        $alias
	 *
	 * @return $this|null
	--->
	<cffunction name="setData" access="public" returntype="any" output="no">
		<cfargument name="set_" type="any" required="yes">
		<cfargument name="escape" type="any" required="no" default="">
		<cfargument name="alias" type="string" required="no" default="">
		<cfset var rows = ArrayNew(1)>
		<cfset var first = "">
		<cfset var firstRow = "">
		<cfset var escape_ = "">
		<cfset var keysJ = "">
		<cfset var keys = ArrayNew(1)>
		<cfset var rowKeys = "">
		<cfset var row = "">
		<cfset var clean = "">
		<cfset var rowValue = "">
		<cfset var same = "true">
		<cfset var k = "">
		<cfset var i = 0>
		<cfset var j = 0>

		<cfif setIsEmpty_(arguments.set_)>
			<cfif this.db_.DBDebug>
				<cfthrow type="ColdIgniter.Database.Exceptions.DatabaseException" message="setData() has no data.">
			</cfif>

			<cfreturn "">
		</cfif>

		<cfset setAlias(arguments.alias)>

		<cfif IsObject(arguments.set_)>
			<cfset objectToArray(arguments.set_)>
			<cfset batchObjectToArray(arguments.set_)>
		</cfif>

		<cfif IsArray(arguments.set_)>
			<cfset first = arguments.set_[1]>

			<cfif (isArr_(first) OR IsObject(first)) AND NOT isNullMarker_(first)>
				<cfset rows = arguments.set_>
			<cfelse>
				<cfset ArrayAppend(rows, arguments.set_)>
			</cfif>
		<cfelse>
			<cfset first = arguments.set_.values().iterator().next()>

			<cfif (isArr_(first) OR IsObject(first)) AND NOT isNullMarker_(first)>
				<cfset rows = toList_(arguments.set_)>
			<cfelse>
				<cfset ArrayAppend(rows, arguments.set_)>
			</cfif>
		</cfif>

		<cfset escape_ = resolveEscape_(arguments.escape)>

		<cfset firstRow = toMap_(objectToArray(rows[1]))>
		<cfset keysJ = CreateObject("java", "java.util.ArrayList").init()>

		<cfset rowKeys = array_keys(firstRow)>

		<cfloop from="1" to="#ArrayLen(rowKeys)#" index="i">
			<cfset keysJ.add(JavaCast("string", rowKeys[i]))>
		</cfloop>

		<cfset CreateObject("java", "java.util.Collections").sort(keysJ)>

		<cfloop from="0" to="#keysJ.size() - 1#" index="i">
			<cfset ArrayAppend(keys, keysJ.get(JavaCast("int", i)))>
		</cfloop>

		<cfif NOT IsArray(this.QBSet)>
			<cfset this.QBSet = ArrayNew(1)>
		</cfif>

		<cfloop from="1" to="#ArrayLen(rows)#" index="i">
			<cfset row = toMap_(objectToArray(rows[i]))>
			<cfset rowKeys = array_keys(row)>
			<cfset same = "true">

			<cfif ArrayLen(rowKeys) NEQ ArrayLen(keys)>
				<cfset same = "false">
			<cfelse>
				<cfloop from="1" to="#ArrayLen(rowKeys)#" index="j">
					<cfif NOT in_array(rowKeys[j], keys)>
						<cfset same = "false">
					</cfif>
				</cfloop>
			</cfif>

			<cfif NOT same>
				<cfset ArrayAppend(this.QBSet, ArrayNew(1))>

				<cfreturn "">
			</cfif>

			<!--- the values are taken in the order of the sorted keys --->
			<cfset clean = ArrayNew(1)>

			<cfloop from="1" to="#ArrayLen(keys)#" index="j">
				<cfset rowValue = row[keys[j]]>

				<cfif escape_>
					<cfset ArrayAppend(clean, this.db_.escape(rowValue))>
				<cfelse>
					<cfset ArrayAppend(clean, rowValue)>
				</cfif>
			</cfloop>

			<cfset ArrayAppend(this.QBSet, clean)>
		</cfloop>

		<cfloop from="1" to="#ArrayLen(keys)#" index="i">
			<cfset k = this.db_.protectIdentifiers(keys[i], "false")>

			<cfif NOT in_array(k, this.QBKeys)>
				<cfset ArrayAppend(this.QBKeys, k)>
			</cfif>
		</cfloop>

		<cfreturn this>
	</cffunction>

	<!---
	 * Compiles an upsert query and returns the sql
	 *
	 * @return false|string
	 *
	 * @throws DatabaseException
	--->
	<cffunction name="getCompiledUpsert" access="public" returntype="any" output="no">
		<cfset var currentTestMode = this.testMode_>
		<cfset var sql = "">

		<cfset this.testMode_ = "true">

		<cfset sql = joinList_(";" & Chr(10), upsert())>

		<cfset this.testMode_ = currentTestMode>

		<cfreturn compileFinalQuery(sql)>
	</cffunction>

	<!---
	 * Converts call to batchUpsert
	 *
	 * @param list<map>|map|object|string $set An empty string is null
	 * @param bool|string                 $escape An empty string is null
	 *
	 * @return false|int|list<string>
	 *
	 * @throws DatabaseException
	--->
	<cffunction name="upsert" access="public" returntype="any" output="no">
		<cfargument name="set_" type="any" required="no" default="">
		<cfargument name="escape" type="any" required="no" default="">
		<cfset var set__ = "">
		<cfset var keys = "">
		<cfset var field = "">
		<cfset var k = "">
		<cfset var pair = "">
		<cfset var i = 0>

		<cfif isNullArg_(arguments.set_) AND (NOT IsArray(this.QBSet) OR ArrayLen(this.QBSet) EQ 0)>
			<cfset set__ = array_()>
			<cfset keys = array_keys(this.QBSet)>

			<cfloop from="1" to="#ArrayLen(keys)#" index="i">
				<cfset field = keys[i]>
				<cfset k = trimChars_(field, this.db_.escapeChar)>

				<cfif this.binds.containsKey(JavaCast("string", k))>
					<cfset pair = this.binds[k]>
					<cfset set__[k] = pair[1]>
				<cfelse>
					<cfset set__[k] = new_("ColdIgniter\Database\RawSql", this.QBSet[field])>
				</cfif>
			</cfloop>

			<cfset this.binds = array_()>

			<cfset this.QBSet = array_()>
			<cfset this.QBKeys = ArrayNew(1)>

			<!--- unescaped items are RawSql now --->
			<cfset setData(set__, "true")>
		<cfelseif NOT isNullArg_(arguments.set_)>
			<cfset setData(arguments.set_, arguments.escape)>
		</cfif>

		<cfreturn batchExecute("_upsertBatch")>
	</cffunction>

	<!---
	 * Converts call to batchUpsert
	 *
	 * @param list<map>|map|object|string $set An empty string is null
	 * @param bool|string                 $escape An empty string is null
	 *
	 * @return false|int|list<string>|string
	 *
	 * @throws DatabaseException
	--->
	<cffunction name="upsertBatch" access="public" returntype="any" output="no">
		<cfargument name="set_" type="any" required="no" default="">
		<cfargument name="escape" type="any" required="no" default="">
		<cfargument name="batchSize" type="numeric" required="no" default="100">
		<cfset var sql = "">

		<cfif this.QBOptions.containsKey("setQueryAsData")>
			<cfset sql = _upsertBatch(this.QBFrom[1], this.QBKeys, ArrayNew(1))>

			<cfif Len(sql) EQ 0>
				<cfreturn "false">
			</cfif>

			<cfif NOT this.testMode_>
				<cfset this.db_.query(sql, "", "false")>
			</cfif>

			<cfset resetWrite()>

			<cfif this.testMode_>
				<cfreturn sql>
			</cfif>

			<cfreturn this.db_.affectedRows()>
		</cfif>

		<cfif NOT isNullArg_(arguments.set_)>
			<cfset setData(arguments.set_, arguments.escape)>
		</cfif>

		<cfreturn batchExecute("_upsertBatch", arguments.batchSize)>
	</cffunction>

	<!---
	 * Generates a platform-specific upsertBatch string from the supplied data
	 *
	 * @used-by batchExecute()
	 *
	 * @param string                  $table  Protected table name
	 * @param list<string>            $keys   QBKeys
	 * @param list<list<int|string>>  $values QBSet
	--->
	<cffunction name="_upsertBatch" access="private" returntype="string" output="no">
		<cfargument name="table" type="string" required="yes">
		<cfargument name="keys" type="array" required="yes">
		<cfargument name="values" type="array" required="yes">
		<cfset var sql = "">
		<cfset var ufMap = "">
		<cfset var ufKeys = "">
		<cfset var parts = ArrayNew(1)>
		<cfset var data = "">
		<cfset var value = "">
		<cfset var i = 0>

		<cfset sql = optGet_("sql", "")>

		<cfif Len(sql) EQ 0>
			<cfif NOT this.QBOptions.containsKey("updateFields")>
				<cfset updateFields(arguments.keys)>
			</cfif>

			<cfif this.QBOptions.containsKey("updateFields")>
				<cfset ufMap = this.QBOptions["updateFields"]>
			<cfelse>
				<cfset ufMap = array_()>
			</cfif>

			<cfset ufKeys = array_keys(ufMap)>

			<cfloop from="1" to="#ArrayLen(ufKeys)#" index="i">
				<cfset value = ufMap[ufKeys[i]]>

				<cfif instanceof_(value, "RawSql")>
					<cfset ArrayAppend(parts, arguments.table & "." & ufKeys[i] & " = " & value.__toString())>
				<cfelse>
					<cfset ArrayAppend(parts, arguments.table & "." & ufKeys[i] & " = VALUES(" & value & ")")>
				</cfif>
			</cfloop>

			<cfset sql = "INSERT INTO " & arguments.table & " (" & implode(", ", arguments.keys) & ")" & Chr(10) & "{:_table_:}ON DUPLICATE KEY UPDATE" & Chr(10) & implode("," & Chr(10), parts)>

			<cfset this.QBOptions["sql"] = sql>
		</cfif>

		<cfif this.QBOptions.containsKey("setQueryAsData")>
			<cfset data = this.QBOptions["setQueryAsData"] & Chr(10)>
		<cfelse>
			<cfset data = "VALUES " & implode(", ", formatValues(arguments.values)) & Chr(10)>
		</cfif>

		<cfreturn Replace(sql, "{:_table_:}", data, "all")>
	</cffunction>

	<!---
	 * Sets the alias for the table used in batch statements
	 *
	 * @return $this
	--->
	<cffunction name="setAlias" access="private" returntype="any" output="no">
		<cfargument name="alias" type="string" required="yes">

		<cfif Len(arguments.alias) GT 0>
			<cfset this.db_.addTableAlias(arguments.alias)>
			<cfset this.QBOptions["alias"] = this.db_.protectIdentifiers(arguments.alias)>
		</cfif>

		<cfreturn this>
	</cffunction>

	<!---
	 * Sets update fields for upsert, update
	 *
	 * @param list<RawSql|string>|map|string $set          An empty string is null
	 * @param bool                           $addToDefault Adds an additional field to the final list
	 * @param list<string>|string            $ignore       An empty string is null, the values that are not to be updated
	 *
	 * @return $this
	--->
	<cffunction name="updateFields" access="public" returntype="any" output="no">
		<cfargument name="set_" type="any" required="yes">
		<cfargument name="addToDefault" type="boolean" required="no" default="false">
		<cfargument name="ignore" type="any" required="no" default="">
		<cfset var ks = ArrayNew(1)>
		<cfset var vs = ArrayNew(1)>
		<cfset var ignoreList = ArrayNew(1)>
		<cfset var ignoreAll = "false">
		<cfset var key = "">
		<cfset var value = "">
		<cfset var target = "">
		<cfset var fields = "">
		<cfset var additional = "">
		<cfset var addKeys = "">
		<cfset var tmp = "">
		<cfset var skip = "false">
		<cfset var i = 0>

		<cfif NOT setIsEmpty_(arguments.set_)>
			<cfif IsSimpleValue(arguments.set_)>
				<cfset vs = explode(",", arguments.set_)>
			<cfelse>
				<cfset vs = toList_(arguments.set_)>
			</cfif>

			<cfif isArr_(arguments.set_) AND NOT IsArray(arguments.set_)>
				<cfset ks = array_keys(arguments.set_)>
			<cfelse>
				<cfloop from="1" to="#ArrayLen(vs)#" index="i">
					<cfset ArrayAppend(ks, i - 1)>
				</cfloop>
			</cfif>

			<cfif NOT isNullArg_(arguments.ignore)>
				<cfset tmp = toList_(arguments.ignore)>

				<cfloop from="1" to="#ArrayLen(tmp)#" index="i">
					<cfif IsSimpleValue(tmp[i])>
						<cfset ArrayAppend(ignoreList, tmp[i])>
					</cfif>
				</cfloop>

				<cfset ignoreAll = "true">
			</cfif>

			<cfloop from="1" to="#ArrayLen(vs)#" index="i">
				<cfset key = ks[i]>
				<cfset value = vs[i]>

				<cfif NOT instanceof_(value, "RawSql")>
					<cfset value = this.db_.protectIdentifiers(value)>
				</cfif>

				<cfif NOT isStringKey_(key)>
					<cfset key = value>
				</cfif>

				<cfset skip = "false">

				<cfif ignoreAll AND IsSimpleValue(key)>
					<cfif in_array(key, ignoreList)>
						<cfset skip = "true">
					</cfif>
				</cfif>

				<cfif NOT skip>
					<cfif arguments.addToDefault>
						<cfset target = "updateFieldsAdditional">
					<cfelse>
						<cfset target = "updateFields">
					</cfif>

					<cfif NOT this.QBOptions.containsKey(target)>
						<cfset this.QBOptions[target] = array_()>
					</cfif>

					<cfset fields = this.QBOptions[target]>
					<cfset fields[this.db_.protectIdentifiers(key)] = value>
				</cfif>
			</cfloop>

			<cfif NOT arguments.addToDefault AND this.QBOptions.containsKey("updateFieldsAdditional") AND this.QBOptions.containsKey("updateFields")>
				<cfset fields = this.QBOptions["updateFields"]>
				<cfset additional = this.QBOptions["updateFieldsAdditional"]>
				<cfset addKeys = array_keys(additional)>

				<cfloop from="1" to="#ArrayLen(addKeys)#" index="i">
					<cfset fields[addKeys[i]] = additional[addKeys[i]]>
				</cfloop>

				<cfset this.QBOptions.remove("updateFieldsAdditional")>
			</cfif>
		</cfif>

		<cfreturn this>
	</cffunction>

	<!---
	 * Sets constraints for batch upsert, update
	 *
	 * @param list<RawSql|string>|map|RawSql|string $set An empty string is null
	 *
	 * @return $this
	--->
	<cffunction name="onConstraint" access="public" returntype="any" output="no">
		<cfargument name="set_" type="any" required="yes">
		<cfset var ks = ArrayNew(1)>
		<cfset var vs = ArrayNew(1)>
		<cfset var key = "">
		<cfset var value = "">
		<cfset var constraints = "">
		<cfset var i = 0>

		<cfif NOT setIsEmpty_(arguments.set_)>
			<cfif IsSimpleValue(arguments.set_)>
				<cfset vs = explode(",", arguments.set_)>

				<cfloop from="1" to="#ArrayLen(vs)#" index="i">
					<cfset vs[i] = Trim(vs[i])>
				</cfloop>
			<cfelseif instanceof_(arguments.set_, "RawSql")>
				<cfset ArrayAppend(vs, arguments.set_)>
			<cfelse>
				<cfset vs = toList_(arguments.set_)>
			</cfif>

			<cfif isArr_(arguments.set_) AND NOT IsArray(arguments.set_)>
				<cfset ks = array_keys(arguments.set_)>
			<cfelse>
				<cfloop from="1" to="#ArrayLen(vs)#" index="i">
					<cfset ArrayAppend(ks, i - 1)>
				</cfloop>
			</cfif>

			<cfloop from="1" to="#ArrayLen(vs)#" index="i">
				<cfset key = ks[i]>
				<cfset value = vs[i]>

				<cfif NOT instanceof_(value, "RawSql")>
					<cfset value = this.db_.protectIdentifiers(value)>
				</cfif>

				<cfif isStringKey_(key)>
					<cfset key = this.db_.protectIdentifiers(key)>
				</cfif>

				<cfif NOT this.QBOptions.containsKey("constraints")>
					<cfset this.QBOptions["constraints"] = array_()>
				</cfif>

				<cfset constraints = this.QBOptions["constraints"]>
				<cfset constraints[key] = value>
			</cfloop>
		</cfif>

		<cfreturn this>
	</cffunction>

	<!---
	 * Sets data source as a query for insertBatch()/updateBatch()/upsertBatch()/deleteBatch()
	 *
	 * @param BaseBuilder|RawSql          $query
	 * @param string                      $alias   An empty string is null
	 * @param list<string>|string         $columns An empty string is null
	 *
	 * @return $this
	--->
	<cffunction name="setQueryAsData" access="public" returntype="any" output="no">
		<cfargument name="query" type="any" required="yes">
		<cfargument name="alias" type="string" required="no" default="">
		<cfargument name="columns" type="any" required="no" default="">
		<cfset var query_ = arguments.query>
		<cfset var columns_ = ArrayNew(1)>
		<cfset var keys = ArrayNew(1)>
		<cfset var i = 0>

		<cfif IsSimpleValue(query_)>
			<cfthrow type="ColdIgniter.Exceptions.InvalidArgumentException" message="$query parameter must be BaseBuilder or RawSql class.">
		</cfif>

		<cfif instanceof_(query_, "BaseBuilder")>
			<cfset query_ = query_.getCompiledSelect()>
		<cfelseif instanceof_(query_, "RawSql")>
			<cfset query_ = query_.__toString()>
		</cfif>

		<cfif IsSimpleValue(query_)>
			<cfif IsSimpleValue(arguments.columns)>
				<cfif Len(arguments.columns) GT 0>
					<cfset columns_ = explode(",", arguments.columns)>

					<cfloop from="1" to="#ArrayLen(columns_)#" index="i">
						<cfset columns_[i] = Trim(columns_[i])>
					</cfloop>
				</cfif>
			<cfelse>
				<cfset columns_ = toList_(arguments.columns)>
			</cfif>

			<cfif ArrayLen(columns_) EQ 0>
				<cfset columns_ = fieldsFromQuery(query_)>
			</cfif>

			<cfif Len(arguments.alias) GT 0>
				<cfset setAlias(arguments.alias)>
			</cfif>

			<cfloop from="1" to="#ArrayLen(columns_)#" index="i">
				<cfset ArrayAppend(keys, this.db_.escapeChar & columns_[i] & this.db_.escapeChar)>
			</cfloop>

			<cfset this.QBOptions["setQueryAsData"] = query_>
			<cfset this.QBKeys = keys>
			<cfset this.QBSet = ArrayNew(1)>
		</cfif>

		<cfreturn this>
	</cffunction>

	<!---
	 * Gets column names from a select query
	--->
	<cffunction name="fieldsFromQuery" access="private" returntype="array" output="no">
		<cfargument name="sql" type="string" required="yes">
		<cfset var result = this.db_.query("SELECT * FROM (" & arguments.sql & ") _u_ LIMIT 1")>

		<cfreturn result.getFieldNames()>
	</cffunction>

	<!---
	 * Returns the rows as "(a,b,c)" strings
	 *
	 * @param list<list> $values
	 *
	 * @return list<string>
	--->
	<cffunction name="formatValues" access="private" returntype="array" output="no">
		<cfargument name="values" type="array" required="yes">
		<cfset var out = ArrayNew(1)>
		<cfset var i = 0>

		<cfloop from="1" to="#ArrayLen(arguments.values)#" index="i">
			<cfset ArrayAppend(out, "(" & joinList_(",", arguments.values[i]) & ")")>
		</cfloop>

		<cfreturn out>
	</cffunction>

	<!---
	 * Converts call to batchInsert
	 *
	 * @param list<map>|map|object|string $set An empty string is null
	 * @param bool|string                 $escape An empty string is null
	 *
	 * @return false|int|list<string>|string
	 *
	 * @throws DatabaseException
	--->
	<cffunction name="insertBatch" access="public" returntype="any" output="no">
		<cfargument name="set_" type="any" required="no" default="">
		<cfargument name="escape" type="any" required="no" default="">
		<cfargument name="batchSize" type="numeric" required="no" default="100">
		<cfset var sql = "">

		<cfif this.QBOptions.containsKey("setQueryAsData")>
			<cfset sql = _insertBatch(this.QBFrom[1], this.QBKeys, ArrayNew(1))>

			<cfif Len(sql) EQ 0>
				<cfreturn "false">
			</cfif>

			<cfif NOT this.testMode_>
				<cfset this.db_.query(sql, "", "false")>
			</cfif>

			<cfset resetWrite()>

			<cfif this.testMode_>
				<cfreturn sql>
			</cfif>

			<cfreturn this.db_.affectedRows()>
		</cfif>

		<cfif NOT setIsEmpty_(arguments.set_)>
			<cfset setData(arguments.set_, arguments.escape)>
		</cfif>

		<cfreturn batchExecute("_insertBatch", arguments.batchSize)>
	</cffunction>

	<!---
	 * Generates a platform-specific insertBatch string from the supplied data.
	 *
	 * @used-by batchExecute()
	 *
	 * @param string       $table  Protected table name
	 * @param list<string> $keys   QBKeys
	 * @param list<list>   $values QBSet
	--->
	<cffunction name="_insertBatch" access="private" returntype="string" output="no">
		<cfargument name="table" type="string" required="yes">
		<cfargument name="keys" type="array" required="yes">
		<cfargument name="values" type="array" required="yes">
		<cfset var sql = optGet_("sql", "")>
		<cfset var data = "">

		<cfif Len(sql) EQ 0>
			<cfset sql = "INSERT " & compileIgnore("insert") & "INTO " & arguments.table & " (" & implode(", ", arguments.keys) & ")" & Chr(10) & "{:_table_:}">

			<cfset this.QBOptions["sql"] = sql>
		</cfif>

		<cfif this.QBOptions.containsKey("setQueryAsData")>
			<cfset data = this.QBOptions["setQueryAsData"]>
		<cfelse>
			<cfset data = "VALUES " & implode(", ", formatValues(arguments.values))>
		</cfif>

		<cfreturn Replace(sql, "{:_table_:}", data, "all")>
	</cffunction>

	<!---
	 * Allows a row or multiple rows to be set for batch inserts
	 *
	 * @param list<map>|map|string $key
	 * @param bool|string          $escape An empty string is null
	 *
	 * @return $this|null
	 *
	 * @deprecated
	--->
	<cffunction name="setInsertBatch" access="public" returntype="any" output="no">
		<cfargument name="key" type="any" required="yes">
		<cfargument name="value" type="string" required="no" default="">
		<cfargument name="escape" type="any" required="no" default="">
		<cfset var key_ = arguments.key>
		<cfset var rows = ArrayNew(1)>

		<cfif NOT isArr_(key_)>
			<cfset ArrayAppend(rows, array_(key_, arguments.value))>
			<cfset key_ = rows>
		</cfif>

		<cfreturn setData(key_, arguments.escape)>
	</cffunction>

	<!---
	 * Compiles an insert query and returns the sql
	 *
	 * @return false|string
	 *
	 * @throws DatabaseException
	--->
	<cffunction name="getCompiledInsert" access="public" returntype="any" output="no">
		<cfargument name="reset" type="boolean" required="no" default="true">
		<cfset var sql = "">

		<cfif NOT validateInsert()>
			<cfreturn "false">
		</cfif>

		<cfset sql = _insert(this.db_.protectIdentifiers(removeAlias(this.QBFrom[1]), "true", "", "false"), array_keys(this.QBSet), setValues_())>

		<cfif arguments.reset>
			<cfset resetWrite()>
		</cfif>

		<cfreturn compileFinalQuery(sql)>
	</cffunction>

	<!---
	 * Compiles an insert string and runs the query
	 *
	 * @param list<string>|map|object|string $set An empty string is null
	 * @param bool|string                    $escape An empty string is null
	 *
	 * @return BaseResult|bool|string
	 *
	 * @throws DatabaseException
	--->
	<cffunction name="insert_" access="public" returntype="any" output="no">
		<cfargument name="set_" type="any" required="no" default="">
		<cfargument name="escape" type="any" required="no" default="">
		<cfset var sql = "">
		<cfset var result = "">

		<cfif NOT isNullArg_(arguments.set_)>
			<cfset set(arguments.set_, "", arguments.escape)>
		</cfif>

		<cfif NOT validateInsert()>
			<cfreturn "false">
		</cfif>

		<cfset sql = _insert(this.db_.protectIdentifiers(removeAlias(this.QBFrom[1]), "true", arguments.escape, "false"), array_keys(this.QBSet), setValues_())>

		<cfif NOT this.testMode_>
			<cfset resetWrite()>

			<cfset result = this.db_.query(sql, this.binds, "false")>

			<!--- clear our binds so we don't pollute the next query --->
			<cfset this.binds = array_()>

			<cfreturn result>
		</cfif>

		<cfreturn "false">
	</cffunction>

	<!---
	 * @internal This is a temporary solution.
	 *
	 * @see https://github.com/codeigniter4/CodeIgniter4/pull/5376#issuecomment-962066198
	 *
	 * Removes the alias from a table name
	--->
	<cffunction name="removeAlias" access="private" returntype="string" output="no">
		<cfargument name="from" type="string" required="yes">
		<cfset var from_ = arguments.from>
		<cfset var parts = "">

		<cfif Find(" ", from_) GT 0>
			<!--- if the alias is written with the AS keyword, remove it --->
			<cfset from_ = preg_replace("/\s+AS\s+/i", " ", from_)>

			<cfset parts = explode(" ", from_)>
			<cfset from_ = parts[1]>
		</cfif>

		<cfreturn from_>
	</cffunction>

	<!---
	 * This method is used by both insert() and getCompiledInsert() to
	 * validate that the there data is actually being set and that the table
	 * name is valid.
	 *
	 * @throws DatabaseException
	--->
	<cffunction name="validateInsert" access="private" returntype="boolean" output="no">

		<cfif setEmpty_()>
			<cfif this.db_.DBDebug>
				<cfthrow type="ColdIgniter.Database.Exceptions.DatabaseException" message="You must use the ""set"" method to insert an entry.">
			</cfif>

			<cfreturn false>
		</cfif>

		<cfreturn true>
	</cffunction>

	<!---
	 * Generates a platform-specific insert string from the supplied data
	 *
	 * @param string       $table
	 * @param list<string> $keys
	 * @param list<string> $unescapedKeys
	--->
	<cffunction name="_insert" access="private" returntype="string" output="no">
		<cfargument name="table" type="string" required="yes">
		<cfargument name="keys" type="array" required="yes">
		<cfargument name="unescapedKeys" type="array" required="yes">

		<cfreturn "INSERT " & compileIgnore("insert") & "INTO " & arguments.table & " (" & implode(", ", arguments.keys) & ") VALUES (" & joinList_(", ", arguments.unescapedKeys) & ")">
	</cffunction>

	<!---
	 * Compiles a replace into string and runs the query
	 *
	 * @param map $set An empty string is null
	 *
	 * @return BaseResult|false|string
	 *
	 * @throws DatabaseException
	--->
	<cffunction name="replace_" access="public" returntype="any" output="no">
		<cfargument name="set_" type="any" required="no" default="">
		<cfset var table = "">
		<cfset var sql = "">

		<cfif NOT isNullArg_(arguments.set_)>
			<cfset set(arguments.set_)>
		</cfif>

		<cfif setEmpty_()>
			<cfif this.db_.DBDebug>
				<cfthrow type="ColdIgniter.Database.Exceptions.DatabaseException" message="You must use the ""set"" method to update an entry.">
			</cfif>

			<cfreturn "false">
		</cfif>

		<cfset table = this.QBFrom[1]>

		<cfset sql = _replace(table, array_keys(this.QBSet), setValues_())>

		<cfset resetWrite()>

		<cfif this.testMode_>
			<cfreturn sql>
		</cfif>

		<cfreturn this.db_.query(sql, this.binds, "false")>
	</cffunction>

	<!---
	 * Generates a platform-specific replace string from the supplied data
	 *
	 * @param string       $table
	 * @param list<string> $keys
	 * @param list<string> $values
	--->
	<cffunction name="_replace" access="private" returntype="string" output="no">
		<cfargument name="table" type="string" required="yes">
		<cfargument name="keys" type="array" required="yes">
		<cfargument name="values" type="array" required="yes">

		<cfreturn "REPLACE INTO " & arguments.table & " (" & implode(", ", arguments.keys) & ") VALUES (" & joinList_(", ", arguments.values) & ")">
	</cffunction>

	<!---
	 * Groups tables in FROM clauses if needed, so there is no confusion
	 * about operator precedence.
	 *
	 * Note: This is only used (and overridden) by MySQL.
	--->
	<cffunction name="_fromTables" access="private" returntype="string" output="no">

		<cfreturn joinList_(", ", this.QBFrom)>
	</cffunction>

	<!---
	 * Compiles an update query and returns the sql
	 *
	 * @return false|string
	 *
	 * @throws DatabaseException
	--->
	<cffunction name="getCompiledUpdate" access="public" returntype="any" output="no">
		<cfargument name="reset" type="boolean" required="no" default="true">
		<cfset var sql = "">

		<cfif NOT validateUpdate()>
			<cfreturn "false">
		</cfif>

		<cfset sql = _update(this.QBFrom[1], this.QBSet)>

		<cfif arguments.reset>
			<cfset resetWrite()>
		</cfif>

		<cfreturn compileFinalQuery(sql)>
	</cffunction>

	<!---
	 * Compiles an update string and runs the query.
	 *
	 * @param list<string>|map|object|string $set   An empty string is null
	 * @param list<string>|map|RawSql|string $where An empty string is null
	 * @param int|string                     $limit An empty string is null
	 *
	 * @throws DatabaseException
	--->
	<cffunction name="update" access="public" returntype="boolean" output="no">
		<cfargument name="set_" type="any" required="no" default="">
		<cfargument name="where_" type="any" required="no" default="">
		<cfargument name="limit_" type="any" required="no" default="">
		<cfset var limit__ = intArg_(arguments.limit_, "update() expects $limit to be an integer")>
		<cfset var sql = "">
		<cfset var result = "">

		<cfif NOT isNullArg_(arguments.set_)>
			<cfset set(arguments.set_)>
		</cfif>

		<cfif NOT validateUpdate()>
			<cfreturn false>
		</cfif>

		<cfif NOT isNullArg_(arguments.where_)>
			<cfset where(arguments.where_)>
		</cfif>

		<!--- Config\Feature.limitZeroAsAll is not ported yet, it is always true --->
		<cfif Len(limit__) GT 0 AND limit__ EQ 0>
			<cfset limit__ = "">
		</cfif>

		<cfif Len(limit__) GT 0>
			<cfif NOT this.canLimitWhereUpdates>
				<cfthrow type="ColdIgniter.Database.Exceptions.DatabaseException" message="This driver does not allow LIMITs on UPDATE queries using WHERE.">
			</cfif>

			<cfset limit(limit__)>
		</cfif>

		<cfset sql = _update(this.QBFrom[1], this.QBSet)>

		<cfif NOT this.testMode_>
			<cfset resetWrite()>

			<cfset result = this.db_.query(sql, this.binds, "false")>

			<cfif NOT (IsSimpleValue(result) AND Compare(result, "false") EQ 0)>
				<!--- clear our binds so we don't pollute the next query --->
				<cfset this.binds = array_()>

				<cfreturn true>
			</cfif>

			<cfreturn false>
		</cfif>

		<cfreturn true>
	</cffunction>

	<!---
	 * Generates a platform-specific update string from the supplied data
	 *
	 * @param string $table
	 * @param map    $values
	 *
	 * @return string
	--->
	<cffunction name="_update" access="private" returntype="string" output="no">
		<cfargument name="table" type="string" required="yes">
		<cfargument name="values" type="any" required="yes">
		<cfset var valStr = ArrayNew(1)>
		<cfset var keys = array_keys(arguments.values)>
		<cfset var limitPart = "">
		<cfset var i = 0>

		<cfloop from="1" to="#ArrayLen(keys)#" index="i">
			<cfset ArrayAppend(valStr, keys[i] & " = " & strOf_(arguments.values[keys[i]]))>
		</cfloop>

		<!--- Config\Feature.limitZeroAsAll is not ported yet, it is always true --->
		<cfif numberSet_(this.QBLimit)>
			<cfset limitPart = _limit(" ", "true")>
		</cfif>

		<cfreturn "UPDATE " & compileIgnore("update") & arguments.table & " SET " & implode(", ", valStr) & compileWhereHaving("QBWhere") & compileOrderBy() & limitPart>
	</cffunction>

	<!---
	 * This method is used by both update() and getCompiledUpdate() to
	 * validate that data is actually being set and that a valid table name
	 * is provided.
	 *
	 * @throws DatabaseException
	--->
	<cffunction name="validateUpdate" access="private" returntype="boolean" output="no">

		<cfif setEmpty_()>
			<cfif this.db_.DBDebug>
				<cfthrow type="ColdIgniter.Database.Exceptions.DatabaseException" message="You must use the ""set"" method to update an entry.">
			</cfif>

			<cfreturn false>
		</cfif>

		<cfreturn true>
	</cffunction>

	<!---
	 * Update_Batch
	 *
	 * Compiles an update string and runs the query.
	 *
	 * @param list<map>|map|object|string $set         An empty string is null
	 * @param list<string>|map|RawSql|string $constraints An empty string is null
	 *
	 * @return false|int|list<string>|string
	 *
	 * @throws DatabaseException
	--->
	<cffunction name="updateBatch" access="public" returntype="any" output="no">
		<cfargument name="set_" type="any" required="no" default="">
		<cfargument name="constraints" type="any" required="no" default="">
		<cfargument name="batchSize" type="numeric" required="no" default="100">
		<cfset var sql = "">

		<cfif ArrayLen(this.QBWhere) GT 0>
			<cfthrow type="ColdIgniter.Database.Exceptions.DatabaseException" message="updateBatch() cannot be safely combined with existing Query Builder WHERE conditions. Use updateBatch($data, $constraints), onConstraint(), or include all required constraint fields in the batch data.">
		</cfif>

		<cfset onConstraint(arguments.constraints)>

		<cfif this.QBOptions.containsKey("setQueryAsData")>
			<cfset sql = _updateBatch(this.QBFrom[1], this.QBKeys, ArrayNew(1))>

			<cfif Len(sql) EQ 0>
				<cfreturn "false">
			</cfif>

			<cfif NOT this.testMode_>
				<cfset this.db_.query(sql, "", "false")>
			</cfif>

			<cfset resetWrite()>

			<cfif this.testMode_>
				<cfreturn sql>
			</cfif>

			<cfreturn this.db_.affectedRows()>
		</cfif>

		<cfif NOT setIsEmpty_(arguments.set_)>
			<cfset setData(arguments.set_, "true")>
		</cfif>

		<cfreturn batchExecute("_updateBatch", arguments.batchSize)>
	</cffunction>

	<!---
	 * Generates a platform-specific batch update string from the supplied data
	 *
	 * @used-by batchExecute()
	 *
	 * @param string       $table  Protected table name
	 * @param list<string> $keys   QBKeys
	 * @param list<list>   $values QBSet
	--->
	<cffunction name="_updateBatch" access="private" returntype="string" output="no">
		<cfargument name="table" type="string" required="yes">
		<cfargument name="keys" type="array" required="yes">
		<cfargument name="values" type="array" required="yes">
		<cfset var sql = optGet_("sql", "")>
		<cfset var constraints = "">
		<cfset var ufMap = "">
		<cfset var alias = "">
		<cfset var cKeys = "">
		<cfset var ufKeys = "">
		<cfset var parts = ArrayNew(1)>
		<cfset var rowParts = ArrayNew(1)>
		<cfset var row = "">
		<cfset var selects = ArrayNew(1)>
		<cfset var value = "">
		<cfset var data = "">
		<cfset var i = 0>
		<cfset var j = 0>

		<cfif Len(sql) EQ 0>
			<cfif this.QBOptions.containsKey("constraints")>
				<cfset constraints = this.QBOptions["constraints"]>
			<cfelse>
				<cfset constraints = array_()>
			</cfif>

			<cfif constraints.size() EQ 0>
				<cfif this.db_.DBDebug>
					<cfthrow type="ColdIgniter.Database.Exceptions.DatabaseException" message="You must specify a constraint to match on for batch updates.">
				</cfif>

				<cfreturn "">
			</cfif>

			<cfif NOT this.QBOptions.containsKey("updateFields")>
				<cfset updateFields(arguments.keys, "false", constraints)>
			</cfif>

			<cfif this.QBOptions.containsKey("updateFields")>
				<cfset ufMap = this.QBOptions["updateFields"]>
			<cfelse>
				<cfset ufMap = array_()>
			</cfif>

			<cfset alias = optGet_("alias", "_u")>

			<cfset sql = "UPDATE " & compileIgnore("update") & arguments.table & Chr(10)>
			<cfset sql = sql & "SET" & Chr(10)>

			<cfset ufKeys = array_keys(ufMap)>

			<cfloop from="1" to="#ArrayLen(ufKeys)#" index="i">
				<cfset value = ufMap[ufKeys[i]]>

				<cfif instanceof_(value, "RawSql")>
					<cfset ArrayAppend(parts, ufKeys[i] & " = " & value.__toString())>
				<cfelse>
					<cfset ArrayAppend(parts, ufKeys[i] & " = " & alias & "." & value)>
				</cfif>
			</cfloop>

			<cfset sql = sql & joinList_("," & Chr(10), parts) & Chr(10)>

			<cfset sql = sql & "FROM (" & Chr(10) & "{:_table_:}">
			<cfset sql = sql & ") " & alias & Chr(10)>

			<cfset parts = ArrayNew(1)>
			<cfset cKeys = array_keys(constraints)>

			<cfloop from="1" to="#ArrayLen(cKeys)#" index="i">
				<cfset value = constraints[cKeys[i]]>

				<cfif instanceof_(value, "RawSql") AND isStringKey_(cKeys[i])>
					<cfset ArrayAppend(parts, arguments.table & "." & cKeys[i] & " = " & value.__toString())>
				<cfelseif instanceof_(value, "RawSql")>
					<cfset ArrayAppend(parts, value)>
				<cfelse>
					<cfset ArrayAppend(parts, arguments.table & "." & value & " = " & alias & "." & value)>
				</cfif>
			</cfloop>

			<cfset sql = sql & "WHERE " & joinList_(" AND ", parts)>

			<cfset this.QBOptions["sql"] = sql>
		</cfif>

		<cfif this.QBOptions.containsKey("setQueryAsData")>
			<cfset data = this.QBOptions["setQueryAsData"]>
		<cfelse>
			<cfloop from="1" to="#ArrayLen(arguments.values)#" index="i">
				<cfset rowParts = ArrayNew(1)>
				<cfset row = arguments.values[i]>

				<cfloop from="1" to="#ArrayLen(arguments.keys)#" index="j">
					<cfif j LTE ArrayLen(row)>
						<cfset ArrayAppend(rowParts, strOf_(row[j]) & " " & arguments.keys[j])>
					<cfelse>
						<cfset ArrayAppend(rowParts, " " & arguments.keys[j])>
					</cfif>
				</cfloop>

				<cfset ArrayAppend(selects, "SELECT " & implode(", ", rowParts))>
			</cfloop>

			<cfset data = implode(" UNION ALL" & Chr(10), selects) & Chr(10)>
		</cfif>

		<cfreturn Replace(sql, "{:_table_:}", data, "all")>
	</cffunction>

	<!---
	 * Allows a row or multiple rows to be set for batch updates
	 *
	 * @param list<map>|map|string $key
	 * @param bool|string          $escape An empty string is null
	 *
	 * @return $this|null
	 *
	 * @deprecated
	--->
	<cffunction name="setUpdateBatch" access="public" returntype="any" output="no">
		<cfargument name="key" type="any" required="yes">
		<cfargument name="index" type="string" required="no" default="">
		<cfargument name="escape" type="any" required="no" default="">

		<cfif Len(arguments.index) GT 0>
			<cfset onConstraint(arguments.index)>
		</cfif>

		<cfset setData(arguments.key, arguments.escape)>

		<cfreturn this>
	</cffunction>

	<!---
	 * Compiles a delete string and runs "DELETE FROM table"
	 *
	 * @return bool|string true on success, false on failure, string on testMode
	--->
	<cffunction name="emptyTable" access="public" returntype="any" output="no">
		<cfset var table = this.QBFrom[1]>
		<cfset var sql = _delete(table)>

		<cfif this.testMode_>
			<cfreturn sql>
		</cfif>

		<cfset resetWrite()>

		<cfreturn this.db_.query(sql, "", "false")>
	</cffunction>

	<!---
	 * Compiles a truncate string and runs the query
	 * If the database does not support the truncate() command
	 * This function maps to "DELETE FROM table"
	 *
	 * @return bool|string true on success, false on failure, string on testMode
	--->
	<cffunction name="truncate" access="public" returntype="any" output="no">
		<cfset var table = this.QBFrom[1]>
		<cfset var sql = _truncate(table)>

		<cfif this.testMode_>
			<cfreturn sql>
		</cfif>

		<cfset resetWrite()>

		<cfreturn this.db_.query(sql, "", "false")>
	</cffunction>

	<!---
	 * Generates a platform-specific truncate statement.
	--->
	<cffunction name="_truncate" access="private" returntype="string" output="no">
		<cfargument name="table" type="string" required="yes">

		<cfreturn "TRUNCATE " & arguments.table>
	</cffunction>

	<!---
	 * Compiles a delete query string and returns the sql
	--->
	<cffunction name="getCompiledDelete" access="public" returntype="string" output="no">
		<cfargument name="reset" type="boolean" required="no" default="true">
		<cfset var sql = "">

		<cfset testMode("true")>

		<cfset sql = delete("", "", arguments.reset)>

		<cfset testMode("false")>

		<cfreturn compileFinalQuery(sql)>
	</cffunction>

	<!---
	 * Compiles a delete string and runs the query
	 *
	 * @param list<string>|map|RawSql|string $where An empty string is null
	 * @param int|string                     $limit An empty string is null
	 *
	 * @return bool|string|BaseResult
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

		<cfset sql = _delete(removeAlias(table))>

		<!--- Config\Feature.limitZeroAsAll is not ported yet, it is always true --->
		<cfif Len(limit__) GT 0 AND limit__ EQ 0>
			<cfset limit__ = "">
		</cfif>

		<cfif Len(limit__) GT 0>
			<cfset this.QBLimit = limit__>
		</cfif>

		<cfif numberSet_(this.QBLimit)>
			<cfif NOT this.canLimitDeletes>
				<cfthrow type="ColdIgniter.Database.Exceptions.DatabaseException" message="SQLite3 does not allow LIMITs on DELETE queries.">
			</cfif>

			<cfset sql = _limit(sql, "true")>
		</cfif>

		<cfif arguments.resetData>
			<cfset resetWrite()>
		</cfif>

		<cfif this.testMode_>
			<cfreturn sql>
		</cfif>

		<cfreturn this.db_.query(sql, this.binds, "false")>
	</cffunction>

	<!---
	 * Delete Batch
	 *
	 * Compiles a batch delete query string and runs the query
	 *
	 * @param list<map>|map|object|string    $set         An empty string is null
	 * @param list<string>|map|RawSql|string $constraints An empty string is null
	 *
	 * @return false|int|list<string>|string
	 *
	 * @throws DatabaseException
	--->
	<cffunction name="deleteBatch" access="public" returntype="any" output="no">
		<cfargument name="set_" type="any" required="no" default="">
		<cfargument name="constraints" type="any" required="no" default="">
		<cfargument name="batchSize" type="numeric" required="no" default="100">
		<cfset var sql = "">

		<cfset onConstraint(arguments.constraints)>

		<cfif this.QBOptions.containsKey("setQueryAsData")>
			<cfset sql = _deleteBatch(this.QBFrom[1], this.QBKeys, ArrayNew(1))>

			<cfif Len(sql) EQ 0>
				<cfreturn "false">
			</cfif>

			<cfif NOT this.testMode_>
				<cfset this.db_.query(sql, "", "false")>
			</cfif>

			<cfset resetWrite()>

			<cfif this.testMode_>
				<cfreturn sql>
			</cfif>

			<cfreturn this.db_.affectedRows()>
		</cfif>

		<cfif NOT setIsEmpty_(arguments.set_)>
			<cfset setData(arguments.set_, "true")>
		</cfif>

		<cfreturn batchExecute("_deleteBatch", arguments.batchSize)>
	</cffunction>

	<!---
	 * Generates a platform-specific batch delete string from the supplied data
	 *
	 * @used-by batchExecute()
	 *
	 * @param string       $table  Protected table name
	 * @param list<string> $keys   QBKeys
	 * @param list<list>   $values QBSet
	--->
	<cffunction name="_deleteBatch" access="private" returntype="string" output="no">
		<cfargument name="table" type="string" required="yes">
		<cfargument name="keys" type="array" required="yes">
		<cfargument name="values" type="array" required="yes">
		<cfset var sql = optGet_("sql", "")>
		<cfset var constraints = "">
		<cfset var alias = "">
		<cfset var cKeys = "">
		<cfset var parts = ArrayNew(1)>
		<cfset var rowParts = ArrayNew(1)>
		<cfset var row = "">
		<cfset var selects = ArrayNew(1)>
		<cfset var value = "">
		<cfset var data = "">
		<cfset var i = 0>
		<cfset var j = 0>

		<cfif Len(sql) EQ 0>
			<cfif this.QBOptions.containsKey("constraints")>
				<cfset constraints = this.QBOptions["constraints"]>
			<cfelse>
				<cfset constraints = array_()>
			</cfif>

			<cfif constraints.size() EQ 0>
				<cfif this.db_.DBDebug>
					<cfthrow type="ColdIgniter.Database.Exceptions.DatabaseException" message="You must specify a constraint to match on for batch deletes.">
				</cfif>

				<cfreturn "">
			</cfif>

			<cfset alias = optGet_("alias", "_u")>

			<cfset sql = "DELETE " & arguments.table & " FROM " & arguments.table & Chr(10)>
			<cfset sql = sql & "INNER JOIN (" & Chr(10) & "{:_table_:}">
			<cfset sql = sql & ") " & alias & Chr(10)>

			<cfset cKeys = array_keys(constraints)>

			<cfloop from="1" to="#ArrayLen(cKeys)#" index="i">
				<cfset value = constraints[cKeys[i]]>

				<cfif instanceof_(value, "RawSql")>
					<cfset ArrayAppend(parts, value)>
				<cfelseif isStringKey_(cKeys[i])>
					<cfset ArrayAppend(parts, arguments.table & "." & cKeys[i] & " = " & alias & "." & value)>
				<cfelse>
					<cfset ArrayAppend(parts, arguments.table & "." & value & " = " & alias & "." & value)>
				</cfif>
			</cfloop>

			<cfset sql = sql & "ON " & joinList_(" AND ", parts)>

			<cfset sql = sql & " " & compileWhereHaving("QBWhere")>

			<cfset this.QBOptions["sql"] = Trim(sql)>
		</cfif>

		<cfif this.QBOptions.containsKey("setQueryAsData")>
			<cfset data = this.QBOptions["setQueryAsData"]>
		<cfelse>
			<cfloop from="1" to="#ArrayLen(arguments.values)#" index="i">
				<cfset rowParts = ArrayNew(1)>
				<cfset row = arguments.values[i]>

				<cfloop from="1" to="#ArrayLen(arguments.keys)#" index="j">
					<cfif j LTE ArrayLen(row)>
						<cfset ArrayAppend(rowParts, strOf_(row[j]) & " " & arguments.keys[j])>
					<cfelse>
						<cfset ArrayAppend(rowParts, " " & arguments.keys[j])>
					</cfif>
				</cfloop>

				<cfset ArrayAppend(selects, "SELECT " & implode(", ", rowParts))>
			</cfloop>

			<cfset data = implode(" UNION ALL" & Chr(10), selects) & Chr(10)>
		</cfif>

		<cfreturn compileBatchBinds(Replace(sql, "{:_table_:}", data, "all"))>
	</cffunction>

	<!---
	 * Replaces the bindings of a query with their values
	--->
	<cffunction name="compileBatchBinds" access="private" returntype="string" output="no">
		<cfargument name="sql" type="string" required="yes">
		<cfset var qry = "">

		<cfif this.binds.size() EQ 0>
			<cfreturn arguments.sql>
		</cfif>

		<cfset qry = new_("ColdIgniter\Database\Query", this.db_)>

		<cfset qry.setQuery(arguments.sql, this.binds, "false")>

		<cfreturn qry.getQuery()>
	</cffunction>

	<!---
	 * Converts the bindings of the WHERE conditions to their values
	--->
	<cffunction name="convertWhereBindsForBatch" access="private" returntype="void" output="no">
		<cfset var items = this.QBWhere>
		<cfset var item = "">
		<cfset var condition = "">
		<cfset var sql = "">
		<cfset var qry = "">
		<cfset var i = 0>

		<cfloop from="1" to="#ArrayLen(items)#" index="i">
			<cfset item = items[i]>
			<cfset condition = item["condition"]>
			<cfset qry = new_("ColdIgniter\Database\Query", this.db_)>

			<cfset qry.setQuery(strOf_(condition), this.binds, "false")>

			<cfset sql = qry.getQuery()>

			<cfif instanceof_(condition, "RawSql")>
				<cfset item["condition"] = condition.with(sql)>
			<cfelse>
				<cfset item["condition"] = sql>
			</cfif>
		</cfloop>

		<cfset this.QBWhere = items>
	</cffunction>

	<!---
	 * Increments a numeric column by the specified value.
	 *
	 * @return bool
	--->
	<cffunction name="increment" access="public" returntype="any" output="no">
		<cfargument name="column" type="string" required="yes">
		<cfargument name="value" type="numeric" required="no" default="1">
		<cfset var column_ = this.db_.protectIdentifiers(arguments.column)>
		<cfset var sql = _update(this.QBFrom[1], array_(column_, column_ & " + " & Fix(arguments.value)))>

		<cfif NOT this.testMode_>
			<cfset resetWrite()>

			<cfreturn this.db_.query(sql, this.binds, "false")>
		</cfif>

		<cfreturn true>
	</cffunction>

	<!---
	 * Decrements a numeric column by the specified value.
	 *
	 * @return bool
	--->
	<cffunction name="decrement" access="public" returntype="any" output="no">
		<cfargument name="column" type="string" required="yes">
		<cfargument name="value" type="numeric" required="no" default="1">
		<cfset var column_ = this.db_.protectIdentifiers(arguments.column)>
		<cfset var sql = _update(this.QBFrom[1], array_(column_, column_ & "-" & Fix(arguments.value)))>

		<cfif NOT this.testMode_>
			<cfset resetWrite()>

			<cfreturn this.db_.query(sql, this.binds, "false")>
		</cfif>

		<cfreturn true>
	</cffunction>

	<!---
	 * Generates a platform-specific delete string from the supplied data
	--->
	<cffunction name="_delete" access="private" returntype="string" output="no">
		<cfargument name="table" type="string" required="yes">

		<cfreturn "DELETE " & compileIgnore("delete") & "FROM " & arguments.table & compileWhereHaving("QBWhere")>
	</cffunction>

	<!---
	 * Track Aliases
	 *
	 * Used to track SQL statements written with aliased tables.
	 *
	 * @param list<string>|string $table
	--->
	<cffunction name="trackAliases" access="private" returntype="any" output="no">
		<cfargument name="table" type="any" required="yes">
		<cfset var table_ = "">
		<cfset var tables = "">
		<cfset var alias = "">
		<cfset var i = 0>

		<cfif IsArray(arguments.table)>
			<cfloop from="1" to="#ArrayLen(arguments.table)#" index="i">
				<cfset trackAliases(arguments.table[i])>
			</cfloop>

			<cfreturn "">
		</cfif>

		<cfset table_ = arguments.table>

		<!--- if a table alias is used we can recognize it by a space --->
		<cfif Find(",", table_) GT 0>
			<cfreturn trackAliases(explode(",", table_))>
		</cfif>

		<cfif Find(" ", table_) GT 0>
			<!--- if the alias is written with the AS keyword, remove it --->
			<cfset table_ = preg_replace("/\s+AS\s+/i", " ", table_)>

			<!--- grab the alias --->
			<cfset alias = Trim(Mid(table_, strrpos(table_, " ") + 1, Len(table_)))>

			<!--- store the alias, if it doesn't already exist --->
			<cfset this.db_.addTableAlias(alias)>
		</cfif>

		<cfreturn "">
	</cffunction>

	<!---
	 * Compile the SELECT statement
	 *
	 * Generates a query string based on which functions were used.
	 * Should not be called directly.
	 *
	 * @param bool|string $selectOverride The text "false" or a SELECT part
	--->
	<cffunction name="compileSelect" access="private" returntype="string" output="no">
		<cfargument name="selectOverride" type="string" required="no" default="false">
		<cfset var sql = "">
		<cfset var val = "">
		<cfset var protect = "">
		<cfset var i = 0>

		<!--- write the "select" portion of the query --->
		<cfif Compare(arguments.selectOverride, "false") NEQ 0>
			<cfset sql = arguments.selectOverride>
		<cfelse>
			<cfif this.QBDistinct>
				<cfset sql = "SELECT DISTINCT ">
			<cfelse>
				<cfset sql = "SELECT ">
			</cfif>

			<cfif ArrayLen(this.QBSelect) EQ 0>
				<cfset sql = sql & "*">
			<cfelse>
				<!--- cycle through the "select" portion of the query and prep each column name --->
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

		<!--- write the "FROM" portion of the query --->
		<cfif ArrayLen(this.QBFrom) GT 0>
			<cfset sql = sql & Chr(10) & "FROM " & _fromTables()>
		</cfif>

		<!--- write the "JOIN" portion of the query --->
		<cfif ArrayLen(this.QBJoin) GT 0>
			<cfset sql = sql & Chr(10) & joinList_(Chr(10), this.QBJoin)>
		</cfif>

		<cfset sql = sql & compileWhereHaving("QBWhere") & compileGroupBy() & compileWhereHaving("QBHaving") & compileOrderBy()>

		<!--- Config\Feature.limitZeroAsAll is not ported yet, it is always true --->
		<cfif numberSet_(this.QBLimit)>
			<cfset sql = _limit(sql & Chr(10))>
		</cfif>

		<cfreturn unionInjection(sql)>
	</cffunction>

	<!---
	 * Checks if the ignore option is supported by
	 * the Database Driver for the specific statement.
	 *
	 * @return string
	--->
	<cffunction name="compileIgnore" access="private" returntype="string" output="no">
		<cfargument name="statement" type="string" required="yes">

		<cfif this.QBIgnore AND this.supportedIgnoreStatements.containsKey(JavaCast("string", arguments.statement))>
			<cfreturn Trim(this.supportedIgnoreStatements[arguments.statement]) & " ">
		</cfif>

		<cfreturn "">
	</cffunction>

	<!---
	 * Escapes identifiers in WHERE and HAVING statements at execution time.
	 *
	 * Required so that aliases are tracked properly, regardless of whether
	 * where(), orWhere(), having(), orHaving are called prior to from(),
	 * join() and prefixTable is added only if needed.
	 *
	 * @param string $qbKey 'QBWhere' or 'QBHaving'
	 *
	 * @return string SQL statement
	--->
	<cffunction name="compileWhereHaving" access="private" returntype="string" output="no">
		<cfargument name="qbKey" type="string" required="yes">
		<cfset var items = clauseGet_(arguments.qbKey)>
		<cfset var item = "">
		<cfset var conditions = "">
		<cfset var condition = "">
		<cfset var op = "">
		<cfset var matcher = "">
		<cfset var m1 = "">
		<cfset var m2 = "">
		<cfset var m3 = "">
		<cfset var m4 = "">
		<cfset var m5 = "">
		<cfset var protect = "">
		<cfset var head = "">
		<cfset var lead = "">
		<cfset var n = 0>
		<cfset var i = 0>
		<cfset var j = 0>

		<cfif ArrayLen(items) EQ 0>
			<cfreturn "">
		</cfif>

		<cfloop from="1" to="#ArrayLen(items)#" index="i">
			<cfset item = items[i]>

			<!--- a string or a RawSql was compiled before --->
			<cfif NOT IsSimpleValue(item) AND NOT instanceof_(item, "RawSql")>
				<cfif IsObject(item["condition"]) AND instanceof_(item["condition"], "RawSql")>
					<cfset items[i] = item["condition"]>
				<cfelseif NOT item["escape"]>
					<cfset items[i] = item["condition"]>
				<cfelseif isPlainCondition_(item["condition"])>
					<!---
					 * Difference: the condition that where("id", 5) leaves, a
					 * name, a comparison and a bind ("AND id = :id:"), is put
					 * together from its words. The steps below give the same
					 * text for it: the split gives the AND or OR and the rest,
					 * the operator is the comparison, and of the name and the
					 * bind only the name is an identifier. They take about a
					 * millisecond a condition, in Java calls.
					--->
					<cfset condition = item["condition"]>
					<cfset n = ListLen(condition, " ")>
					<cfset lead = "">

					<cfif n EQ 4>
						<cfset lead = ListFirst(condition, " ") & " ">
					</cfif>

					<cfset items[i] = lead & this.db_.protectIdentifiers(ListGetAt(condition, n - 2, " ")) & " " & ListGetAt(condition, n - 1, " ") & " " & ListLast(condition, " ")>
				<cfelse>
					<!--- split multiple conditions --->
					<cfset conditions = splitConditions_(item["condition"])>

					<cfloop from="1" to="#ArrayLen(conditions)#" index="j">
						<cfset condition = conditions[j]>
						<cfset op = getOperator(condition)>

						<cfif Len(op) GT 0>
							<cfset matcher = rxMatcher_("/^(\(?)(.*)(" & preg_quote(op) & ")\s*(.*(?<!\)))?(\)?)$/i", condition)>

							<cfif matcher.find()>
								<cfset m1 = rxGroup_(matcher, 1)>
								<cfset m2 = rxGroup_(matcher, 2)>
								<cfset m3 = rxGroup_(matcher, 3)>
								<cfset m4 = rxGroup_(matcher, 4)>
								<cfset m5 = rxGroup_(matcher, 5)>

								<!--- the value may be a column --->
								<cfif Len(m4) GT 0>
									<cfset protect = "false">

									<cfif Find(".", m4) GT 0>
										<cfset protect = "true">
									</cfif>

									<!--- a bind has a colon and is not an identifier --->
									<cfif Find(":", m4) EQ 0>
										<cfset m4 = this.db_.protectIdentifiers(Trim(m4), "false", protect)>
									</cfif>

									<cfset m4 = " " & m4>
								</cfif>

								<cfset conditions[j] = m1 & this.db_.protectIdentifiers(Trim(m2)) & " " & Trim(m3) & m4 & m5>
							</cfif>
						</cfif>
					</cfloop>

					<cfset items[i] = implode("", conditions)>
				</cfif>
			</cfif>
		</cfloop>

		<cfset clauseSet_(arguments.qbKey, items)>

		<cfif Compare(arguments.qbKey, "QBHaving") EQ 0>
			<cfset head = Chr(10) & "HAVING ">
		<cfelse>
			<cfset head = Chr(10) & "WHERE ">
		</cfif>

		<cfreturn head & joinList_(Chr(10), items)>
	</cffunction>

	<!---
	 * Escapes identifiers in GROUP BY statements at execution time.
	 *
	 * Required so that aliases are tracked properly, regardless of whether
	 * groupBy() is called prior to from(), join() and prefixTable is added
	 * only if needed.
	 *
	 * @return string SQL statement
	--->
	<cffunction name="compileGroupBy" access="private" returntype="string" output="no">
		<cfset var items = this.QBGroupBy>
		<cfset var item = "">
		<cfset var i = 0>

		<cfif ArrayLen(items) EQ 0>
			<cfreturn "">
		</cfif>

		<cfloop from="1" to="#ArrayLen(items)#" index="i">
			<cfset item = items[i]>

			<cfif NOT IsSimpleValue(item)>
				<cfif NOT item["escape"] OR isLiteral(item["field"])>
					<cfset items[i] = item["field"]>
				<cfelse>
					<cfset items[i] = this.db_.protectIdentifiers(item["field"])>
				</cfif>
			</cfif>
		</cfloop>

		<cfset this.QBGroupBy = items>

		<cfreturn Chr(10) & "GROUP BY " & joinList_(", ", items)>
	</cffunction>

	<!---
	 * Escapes identifiers in ORDER BY statements at execution time.
	 *
	 * Required so that aliases are tracked properly, regardless of whether
	 * orderBy() is called prior to from(), join() and prefixTable is added
	 * only if needed.
	 *
	 * @return string SQL statement
	--->
	<cffunction name="compileOrderBy" access="private" returntype="string" output="no">
		<cfset var items = "">
		<cfset var item = "">
		<cfset var i = 0>

		<cfif NOT IsArray(this.QBOrderBy)>
			<cfreturn "">
		</cfif>

		<cfset items = this.QBOrderBy>

		<cfif ArrayLen(items) EQ 0>
			<cfreturn "">
		</cfif>

		<cfloop from="1" to="#ArrayLen(items)#" index="i">
			<cfset item = items[i]>

			<cfif NOT IsSimpleValue(item)>
				<cfif item["escape"] AND NOT isLiteral(item["field"])>
					<cfset item["field"] = this.db_.protectIdentifiers(item["field"])>
				</cfif>

				<cfset items[i] = item["field"] & item["direction"]>
			</cfif>
		</cfloop>

		<cfset this.QBOrderBy = items>

		<cfreturn Chr(10) & "ORDER BY " & joinList_(", ", items)>
	</cffunction>

	<!---
	 * Wraps the query in a SELECT when there are UNIONs
	 *
	 * @param string $sql
	--->
	<cffunction name="unionInjection" access="private" returntype="string" output="no">
		<cfargument name="sql" type="string" required="yes">
		<cfset var wrap = "uwrp0">

		<cfif ArrayLen(this.QBUnion) EQ 0>
			<cfreturn arguments.sql>
		</cfif>

		<cfif this.db_.protectIdentifiers_>
			<cfset wrap = this.db_.escapeIdentifiers("uwrp0")>
		</cfif>

		<cfreturn "SELECT * FROM (" & arguments.sql & ") " & wrap & joinList_(Chr(10), this.QBUnion)>
	</cffunction>

	<!---
	 * Takes an object as input and converts the class variables to array key/vals
	 *
	 * Not ported yet: the objects other than RawSql, which is refused as in the original.
	 *
	 * @param map|object $object
	--->
	<cffunction name="objectToArray" access="private" returntype="any" output="no">
		<cfargument name="object" type="any" required="yes">

		<cfif NOT IsObject(arguments.object)>
			<cfreturn arguments.object>
		</cfif>

		<cfif instanceof_(arguments.object, "RawSql")>
			<cfthrow type="ColdIgniter.Exceptions.InvalidArgumentException" message="RawSql ""#arguments.object.__toString()#"" cannot be used here.">
		</cfif>

		<cfthrow type="ColdIgniter.LogicException" message="Not ported yet: the objects as data of the query builder.">
	</cffunction>

	<!---
	 * Takes an object as input and converts the class variables to array key/vals
	 *
	 * Not ported yet: the objects as data.
	 *
	 * @param map|object $object
	--->
	<cffunction name="batchObjectToArray" access="private" returntype="any" output="no">
		<cfargument name="object" type="any" required="yes">

		<cfif NOT IsObject(arguments.object)>
			<cfreturn arguments.object>
		</cfif>

		<cfthrow type="ColdIgniter.LogicException" message="Not ported yet: the objects as data of the query builder.">
	</cffunction>

	<!---
	 * Determines if a string represents a literal value or a field name
	--->
	<cffunction name="isLiteral" access="private" returntype="boolean" output="no">
		<cfargument name="str" type="string" required="yes">
		<cfset var str_ = Trim(arguments.str)>
		<cfset var first = "">

		<!--- Difference: a number is read by its form, not by the float conversion of the original --->
		<cfif Len(str_) EQ 0 OR ctype_digit(str_) OR REFind("^-?(0|[1-9][0-9]*)(\.[0-9]*[1-9])?$", str_) GT 0 OR CompareNoCase(str_, "TRUE") EQ 0 OR CompareNoCase(str_, "FALSE") EQ 0>
			<cfreturn true>
		</cfif>

		<cfif ArrayLen(this.isLiteralStr) EQ 0>
			<cfset ArrayAppend(this.isLiteralStr, "'")>

			<cfif Compare(this.db_.escapeChar, Chr(34)) NEQ 0>
				<cfset ArrayAppend(this.isLiteralStr, Chr(34))>
			</cfif>
		</cfif>

		<cfset first = Left(str_, 1)>

		<cfreturn in_array(first, this.isLiteralStr)>
	</cffunction>

	<!---
	 * Publicly-visible method to reset the QB values.
	 *
	 * @return $this
	--->
	<cffunction name="resetQuery" access="public" returntype="any" output="no">

		<cfset resetSelect()>
		<cfset resetWrite()>

		<cfreturn this>
	</cffunction>

	<!---
	 * Resets the query builder values.  Called by the get() function
	--->
	<cffunction name="resetSelect" access="private" returntype="void" output="no">
		<cfset var first = "">

		<cfset this.QBSelect = ArrayNew(1)>
		<cfset this.QBJoin = ArrayNew(1)>
		<cfset this.QBWhere = ArrayNew(1)>
		<cfset this.QBGroupBy = ArrayNew(1)>
		<cfset this.QBHaving = ArrayNew(1)>
		<cfset this.QBOrderBy = ArrayNew(1)>
		<cfset this.QBNoEscape = ArrayNew(1)>
		<cfset this.QBDistinct = "false">
		<cfset this.QBLimit = "false">
		<cfset this.QBOffset = "false">
		<cfset this.QBUnion = ArrayNew(1)>

		<cfif instanceof_(this.db_, "BaseConnection")>
			<cfset this.db_.setAliasedTables(ArrayNew(1))>
		</cfif>

		<cfif ArrayLen(this.QBFrom) GT 0>
			<cfset first = this.QBFrom[1]>

			<cfset from(first, "true")>
		</cfif>
	</cffunction>

	<!---
	 * Resets the query builder "write" values.
	 *
	 * Called by the insert() update() insertBatch() updateBatch() and delete() functions
	--->
	<cffunction name="resetWrite" access="private" returntype="void" output="no">

		<cfset this.QBSet = array_()>
		<cfset this.QBJoin = ArrayNew(1)>
		<cfset this.QBWhere = ArrayNew(1)>
		<cfset this.QBOrderBy = ArrayNew(1)>
		<cfset this.QBKeys = ArrayNew(1)>
		<cfset this.QBLimit = "false">
		<cfset this.QBIgnore = "false">
		<cfset this.QBOptions = array_()>
	</cffunction>

	<!---
	 * Tests whether the string has an SQL operator
	--->
	<cffunction name="hasOperator" access="private" returntype="boolean" output="no">
		<cfargument name="str" type="string" required="yes">
		<cfset var matcher = rxMatcher_("/(<|>|!|=|\sIS NULL|\sIS NOT NULL|\sEXISTS|\sBETWEEN|\sLIKE|\sIN\s*\(|\s)/i", Trim(arguments.str))>

		<cfreturn matcher.find()>
	</cffunction>

	<!---
	 * Returns the SQL string operator
	 *
	 * @param bool $asList Whether to return all the operators found
	 *
	 * @return list<string>|string An empty string is false
	--->
	<cffunction name="getOperator" access="private" returntype="any" output="no">
		<cfargument name="str" type="string" required="yes">
		<cfargument name="asList" type="boolean" required="no" default="false">
		<cfset var les = "">
		<cfset var matches = "">

		<cfif ArrayLen(this.pregOperators) EQ 0>
			<cfif Len(this.db_.likeEscapeStr) GT 0>
				<cfset les = "\s+" & preg_quote(Trim(Replace(this.db_.likeEscapeStr, "%s", this.db_.likeEscapeChar, "all")))>
			</cfif>

			<cfset ArrayAppend(this.pregOperators, "\s*(?:<|>|!)?=\s*")>
			<cfset ArrayAppend(this.pregOperators, "\s*<>?\s*")>
			<cfset ArrayAppend(this.pregOperators, "\s*>\s*")>
			<cfset ArrayAppend(this.pregOperators, "\s+IS NULL")>
			<cfset ArrayAppend(this.pregOperators, "\s+IS NOT NULL")>
			<cfset ArrayAppend(this.pregOperators, "\s+EXISTS\s*\(.*\)")>
			<cfset ArrayAppend(this.pregOperators, "\s+NOT EXISTS\s*\(.*\)")>
			<cfset ArrayAppend(this.pregOperators, "\s+BETWEEN\s+")>
			<cfset ArrayAppend(this.pregOperators, "\s+IN\s*\(.*\)")>
			<cfset ArrayAppend(this.pregOperators, "\s+NOT IN\s*\(.*\)")>
			<cfset ArrayAppend(this.pregOperators, "\s+LIKE\s+\S.*(" & les & ")?")>
			<cfset ArrayAppend(this.pregOperators, "\s+NOT LIKE\s+\S.*(" & les & ")?")>
		</cfif>

		<cfset matches = findAll_("/" & implode("|", this.pregOperators) & "/i", arguments.str)>

		<cfif ArrayLen(matches) EQ 0>
			<cfreturn "">
		</cfif>

		<cfif arguments.asList>
			<cfreturn matches>
		</cfif>

		<cfreturn matches[1]>
	</cffunction>

	<!---
	 * Returns the SQL string operator from where key
	 *
	 * @return list<string> an empty list when there is none
	--->
	<cffunction name="getOperatorFromWhereKey" access="private" returntype="array" output="no">
		<cfargument name="whereKey" type="string" required="yes">
		<cfset var pregOperators = ArrayNew(1)>

		<!---
		 * Difference: every operator below has a white space character (what
		 * \s matches) or one of < > = in it, so a key with none of them,
		 * which a plain column name is, has no operator and is not searched.
		--->
		<cfif REFind("[" & Chr(9) & Chr(10) & Chr(11) & Chr(12) & Chr(13) & " <>=]", arguments.whereKey) EQ 0>
			<cfreturn pregOperators>
		</cfif>

		<cfset ArrayAppend(pregOperators, "\s*(?:<|>|!)?=")>
		<cfset ArrayAppend(pregOperators, "\s*<>?")>
		<cfset ArrayAppend(pregOperators, "\s*>")>
		<cfset ArrayAppend(pregOperators, "\s+IS NULL")>
		<cfset ArrayAppend(pregOperators, "\s+IS NOT NULL")>
		<cfset ArrayAppend(pregOperators, "\s+EXISTS\s*\(.*\)")>
		<cfset ArrayAppend(pregOperators, "\s+NOT EXISTS\s*\(.*\)")>
		<cfset ArrayAppend(pregOperators, "\s+BETWEEN\s+")>
		<cfset ArrayAppend(pregOperators, "\s+IN\s*\(.*\)")>
		<cfset ArrayAppend(pregOperators, "\s+NOT IN\s*\(.*\)")>
		<cfset ArrayAppend(pregOperators, "\s+LIKE")>
		<cfset ArrayAppend(pregOperators, "\s+NOT LIKE")>

		<cfreturn findAll_("/" & implode("|", pregOperators) & "/i", Trim(arguments.whereKey))>
	</cffunction>

	<!---
	 * Stores a bind value after ensuring that it's unique.
	 * While it might be nicer to have named keys for our binds array
	 * with indexed arrays we get a memory and performance gain, so
	 * lets take advantage of that here.
	 *
	 * @param mixed $value
	--->
	<cffunction name="setBind" access="private" returntype="string" output="no">
		<cfargument name="key" type="string" required="yes">
		<cfargument name="value" type="any" required="no" default="">
		<cfargument name="escape" type="any" required="no" default="true">
		<cfset var pair = ArrayNew(1)>
		<cfset var count = 0>
		<cfset var key_ = JavaCast("string", arguments.key)>

		<cfset ArrayAppend(pair, arguments.value)>
		<cfset ArrayAppend(pair, arguments.escape)>

		<cfif NOT this.binds.containsKey(key_)>
			<cfset this.binds[arguments.key] = pair>

			<cfreturn arguments.key>
		</cfif>

		<cfif NOT this.bindsKeyCount.containsKey(key_)>
			<cfset this.bindsKeyCount[arguments.key] = 1>
		</cfif>

		<cfset count = this.bindsKeyCount[arguments.key]>
		<cfset this.bindsKeyCount[arguments.key] = count + 1>

		<cfset this.binds[arguments.key & "." & count] = pair>

		<cfreturn arguments.key & "." & count>
	</cffunction>

	<!---
	 * Returns true when the value is a subquery: a builder or a callable
	 *
	 * @param mixed $value
	--->
	<cffunction name="isSubquery" access="private" returntype="boolean" output="no">
		<cfargument name="value" type="any" required="yes">

		<cfif instanceof_(arguments.value, "BaseBuilder")>
			<cfreturn true>
		</cfif>

		<cfreturn isCallable_(arguments.value)>
	</cffunction>

	<!---
	 * @param BaseBuilder|callable $builder
	 * @param bool                 $wrapped Wrap the subquery in brackets
	 * @param string               $alias   Subquery alias
	--->
	<cffunction name="buildSubquery" access="private" returntype="string" output="no">
		<cfargument name="builder" type="any" required="yes">
		<cfargument name="wrapped" type="boolean" required="no" default="false">
		<cfargument name="alias" type="string" required="no" default="">
		<cfset var builder_ = arguments.builder>
		<cfset var newBuilder = "">
		<cfset var subquery = "">
		<cfset var alias_ = Trim(arguments.alias)>

		<cfif isCallable_(builder_)>
			<cfset newBuilder = this.db_.newQuery()>

			<cfset callCallback_(builder_, newBuilder)>

			<cfset builder_ = newBuilder>
		</cfif>

		<cfif NOT instanceof_(builder_, "BaseBuilder")>
			<cfthrow type="ColdIgniter.Exceptions.InvalidArgumentException" message="A subquery must be a query builder or a callable.">
		</cfif>

		<cfif Compare(builder_.uid_, this.uid_) EQ 0>
			<cfthrow type="ColdIgniter.Database.Exceptions.DatabaseException" message="The subquery cannot be the same object as the main query object.">
		</cfif>

		<cfset subquery = Replace(builder_.getCompiledSelect("false"), Chr(10), " ", "all")>

		<cfif arguments.wrapped>
			<cfset subquery = "(" & subquery & ")">

			<cfif Len(alias_) GT 0>
				<cfif this.db_.protectIdentifiers_>
					<cfset subquery = subquery & " " & this.db_.escapeIdentifiers(alias_)>
				<cfelse>
					<cfset subquery = subquery & " " & alias_>
				</cfif>
			</cfif>
		</cfif>

		<cfreturn subquery>
	</cffunction>

	<!---
	 * Runs the callback when the condition is true, the default callback otherwise.
	 *
	 * @param mixed    $condition
	 * @param callable $callback        [object, "method"], called with this builder and the condition
	 * @param callable $defaultCallback [object, "method"] or an empty string, called with this builder
	 *
	 * @return $this
	--->
	<cffunction name="when" access="public" returntype="any" output="no">
		<cfargument name="condition" type="any" required="yes">
		<cfargument name="callback" type="any" required="yes">
		<cfargument name="defaultCallback" type="any" required="no" default="">

		<cfif truthy_(arguments.condition)>
			<cfset callCallback_(arguments.callback, this, arguments.condition)>
		<cfelseif NOT isNullArg_(arguments.defaultCallback)>
			<cfset callCallback_(arguments.defaultCallback, this)>
		</cfif>

		<cfreturn this>
	</cffunction>

	<!---
	 * Runs the callback when the condition is false, the default callback otherwise.
	 *
	 * @return $this
	--->
	<cffunction name="whenNot" access="public" returntype="any" output="no">
		<cfargument name="condition" type="any" required="yes">
		<cfargument name="callback" type="any" required="yes">
		<cfargument name="defaultCallback" type="any" required="no" default="">

		<cfif NOT truthy_(arguments.condition)>
			<cfset callCallback_(arguments.callback, this, arguments.condition)>
		<cfelseif NOT isNullArg_(arguments.defaultCallback)>
			<cfset callCallback_(arguments.defaultCallback, this)>
		</cfif>

		<cfreturn this>
	</cffunction>

	<!---
	 * The helpers below have no original: they stand in for the features
	 * of the language that CFML 6.1 does not have.
	--->

	<!--- an empty string is null --->
	<cffunction name="isNullArg_" access="private" returntype="boolean" output="no">
		<cfargument name="value" type="any" required="yes">

		<cfreturn IsSimpleValue(arguments.value) AND Len(arguments.value) EQ 0>
	</cffunction>

	<!--- true when the value is the NullValue that stands in for null --->
	<cffunction name="isNullMarker_" access="private" returntype="boolean" output="no">
		<cfargument name="value" type="any" required="yes">

		<cfreturn instanceof_(arguments.value, "NullValue")>
	</cffunction>

	<!--- the boolean of an argument that is a ?bool: an empty string is the setting of the connection --->
	<cffunction name="resolveEscape_" access="private" returntype="boolean" output="no">
		<cfargument name="escape" type="any" required="yes">

		<cfif IsSimpleValue(arguments.escape) AND Len(arguments.escape) GT 0 AND IsBoolean(arguments.escape) AND NOT IsNumeric(arguments.escape)>
			<cfreturn arguments.escape>
		</cfif>

		<cfreturn this.db_.protectIdentifiers_>
	</cffunction>

	<!--- a list or a map (also an empty one), never a component --->
	<cffunction name="isArr_" access="private" returntype="boolean" output="no">
		<cfargument name="value" type="any" required="yes">

		<cfif IsObject(arguments.value)>
			<cfreturn false>
		</cfif>

		<cfreturn IsArray(arguments.value) OR IsStruct(arguments.value)>
	</cffunction>

	<!--- the values of a list or a map as a list, a single value as a list of one --->
	<cffunction name="toList_" access="private" returntype="array" output="no">
		<cfargument name="value" type="any" required="yes">
		<cfset var out = ArrayNew(1)>
		<cfset var keys = "">
		<cfset var i = 0>

		<cfif IsArray(arguments.value)>
			<cfloop from="1" to="#ArrayLen(arguments.value)#" index="i">
				<cfset ArrayAppend(out, arguments.value[i])>
			</cfloop>
		<cfelseif isArr_(arguments.value)>
			<cfset keys = toKeys_(arguments.value)>

			<cfloop from="1" to="#ArrayLen(keys)#" index="i">
				<cfset ArrayAppend(out, arguments.value[keys[i]])>
			</cfloop>
		<cfelse>
			<cfset ArrayAppend(out, arguments.value)>
		</cfif>

		<cfreturn out>
	</cffunction>

	<!--- the keys of a map or a struct, in order for a map --->
	<cffunction name="toKeys_" access="private" returntype="array" output="no">
		<cfargument name="value" type="any" required="yes">
		<cfset var out = ArrayNew(1)>
		<cfset var iter = "">

		<cfif IsStruct(arguments.value)>
			<cfset iter = arguments.value.keySet().iterator()>

			<cfloop condition="iter.hasNext()">
				<cfset ArrayAppend(out, iter.next())>
			</cfloop>
		</cfif>

		<cfreturn out>
	</cffunction>

	<!--- a list or a map as a map: a list gets the keys "0", "1" and so on --->
	<cffunction name="toMap_" access="private" returntype="any" output="no">
		<cfargument name="value" type="any" required="yes">
		<cfset var map = array_()>
		<cfset var keys = "">
		<cfset var i = 0>

		<cfif IsArray(arguments.value)>
			<cfloop from="1" to="#ArrayLen(arguments.value)#" index="i">
				<cfset map[JavaCast("string", i - 1)] = arguments.value[i]>
			</cfloop>
		<cfelseif IsStruct(arguments.value)>
			<cfset keys = toKeys_(arguments.value)>

			<cfloop from="1" to="#ArrayLen(keys)#" index="i">
				<cfset map[keys[i]] = arguments.value[keys[i]]>
			</cfloop>
		</cfif>

		<cfreturn map>
	</cffunction>

	<!--- a string key is a key that a number would not be --->
	<cffunction name="isStringKey_" access="private" returntype="boolean" output="no">
		<cfargument name="key" type="any" required="yes">

		<cfreturn NOT REFind("^(0|-?[1-9][0-9]*)$", arguments.key)>
	</cffunction>

	<!--- the text of a value that may be a RawSql --->
	<cffunction name="strOf_" access="private" returntype="string" output="no">
		<cfargument name="value" type="any" required="yes">

		<cfif IsObject(arguments.value)>
			<cfreturn arguments.value.__toString()>
		</cfif>

		<cfreturn arguments.value>
	</cffunction>

	<!--- implode() of a list that may hold RawSql objects --->
	<cffunction name="joinList_" access="private" returntype="string" output="no">
		<cfargument name="glue" type="string" required="yes">
		<cfargument name="items" type="array" required="yes">
		<cfset var out = "">
		<cfset var i = 0>

		<cfloop from="1" to="#ArrayLen(arguments.items)#" index="i">
			<cfif i GT 1>
				<cfset out = out & arguments.glue>
			</cfif>

			<cfset out = out & strOf_(arguments.items[i])>
		</cfloop>

		<cfreturn out>
	</cffunction>

	<!--- an integer argument: an empty string is null, anything else that is not a number is refused --->
	<cffunction name="intArg_" access="private" returntype="any" output="no">
		<cfargument name="value" type="any" required="yes">
		<cfargument name="message" type="string" required="yes">

		<cfif isNullArg_(arguments.value)>
			<cfreturn "">
		</cfif>

		<cfif NOT IsSimpleValue(arguments.value) OR NOT IsNumeric(arguments.value)>
			<cfthrow type="ColdIgniter.Exceptions.InvalidArgumentException" message="#arguments.message#">
		</cfif>

		<cfreturn Fix(Val(arguments.value))>
	</cffunction>

	<!--- the truth of a LIMIT or an OFFSET: a number that is not zero --->
	<cffunction name="numberSet_" access="private" returntype="boolean" output="no">
		<cfargument name="value" type="any" required="yes">

		<cfif NOT IsSimpleValue(arguments.value) OR NOT IsNumeric(arguments.value)>
			<cfreturn false>
		</cfif>

		<cfreturn arguments.value NEQ 0>
	</cffunction>

	<!--- the value of a LIKE that has the wildcards of the side --->
	<cffunction name="likeValue_" access="private" returntype="string" output="no">
		<cfargument name="value" type="any" required="yes">
		<cfargument name="side" type="string" required="yes">

		<cfif Compare(arguments.side, "none") EQ 0>
			<cfreturn arguments.value>
		<cfelseif Compare(arguments.side, "before") EQ 0>
			<cfreturn "%" & arguments.value>
		<cfelseif Compare(arguments.side, "after") EQ 0>
			<cfreturn arguments.value & "%">
		</cfif>

		<cfreturn "%" & arguments.value & "%">
	</cffunction>

	<!--- the truth of a value, as the cast to bool of the original --->
	<cffunction name="truthy_" access="private" returntype="boolean" output="no">
		<cfargument name="value" type="any" required="yes">

		<cfif IsSimpleValue(arguments.value)>
			<cfif Len(arguments.value) EQ 0>
				<cfreturn false>
			</cfif>

			<cfif IsBoolean(arguments.value)>
				<cfreturn arguments.value>
			</cfif>

			<cfreturn true>
		</cfif>

		<cfif IsArray(arguments.value)>
			<cfreturn ArrayLen(arguments.value) GT 0>
		</cfif>

		<cfif IsStruct(arguments.value) AND NOT IsObject(arguments.value)>
			<cfreturn arguments.value.size() GT 0>
		</cfif>

		<cfreturn true>
	</cffunction>

	<!--- strips the characters from both ends of a text --->
	<cffunction name="trimChars_" access="private" returntype="string" output="no">
		<cfargument name="value" type="string" required="yes">
		<cfargument name="chars" type="string" required="yes">
		<cfset var out = arguments.value>

		<cfif Len(arguments.chars) EQ 0>
			<cfreturn out>
		</cfif>

		<cfloop condition="Len(out) GT 0 AND Find(Left(out, 1), arguments.chars) GT 0">
			<cfset out = Mid(out, 2, Len(out) - 1)>
		</cfloop>

		<cfloop condition="Len(out) GT 0 AND Find(Right(out, 1), arguments.chars) GT 0">
			<cfset out = Left(out, Len(out) - 1)>
		</cfloop>

		<cfreturn out>
	</cffunction>

	<!--- a regular expression matcher of a pattern written as in the original --->
	<cffunction name="rxMatcher_" access="private" returntype="any" output="no">
		<cfargument name="pattern" type="string" required="yes">
		<cfargument name="subject" type="string" required="yes">

		<cfset regex_guard_(arguments.subject)>

		<cfreturn preg_pattern(arguments.pattern).matcher(JavaCast("string", arguments.subject))>
	</cffunction>

	<!--- a group of a matcher, an empty string when it did not take part --->
	<cffunction name="rxGroup_" access="private" returntype="string" output="no">
		<cfargument name="matcher" type="any" required="yes">
		<cfargument name="n" type="numeric" required="yes">

		<cfif arguments.matcher.start(JavaCast("int", arguments.n)) LT 0>
			<cfreturn "">
		</cfif>

		<cfreturn arguments.matcher.group(JavaCast("int", arguments.n))>
	</cffunction>

	<!--- all the matches of a pattern, a list of strings --->
	<cffunction name="findAll_" access="private" returntype="array" output="no">
		<cfargument name="pattern" type="string" required="yes">
		<cfargument name="subject" type="string" required="yes">
		<cfset var out = ArrayNew(1)>
		<cfset var matcher = rxMatcher_(arguments.pattern, arguments.subject)>

		<cfloop condition="matcher.find()">
			<cfset ArrayAppend(out, matcher.group())>
		</cfloop>

		<cfreturn out>
	</cffunction>

	<!--- preg_split() with the flags that delimiters are captured and the empty pieces are dropped --->
	<cffunction name="splitConditions_" access="private" returntype="array" output="no">
		<cfargument name="condition" type="string" required="yes">
		<cfset var out = ArrayNew(1)>
		<cfset var matcher = rxMatcher_("/((?:^|\s+)AND\s+|(?:^|\s+)OR\s+)/i", arguments.condition)>
		<cfset var last = 0>
		<cfset var startAt = 0>
		<cfset var piece = "">

		<cfloop condition="matcher.find()">
			<cfset startAt = matcher.start()>
			<cfset piece = Mid(arguments.condition, last + 1, startAt - last)>

			<cfif Len(piece) GT 0>
				<cfset ArrayAppend(out, piece)>
			</cfif>

			<cfset ArrayAppend(out, matcher.group(JavaCast("int", 1)))>
			<cfset last = matcher.end()>
		</cfloop>

		<cfset piece = Mid(arguments.condition, last + 1, Len(arguments.condition) - last)>

		<cfif Len(piece) GT 0>
			<cfset ArrayAppend(out, piece)>
		</cfif>

		<cfreturn out>
	</cffunction>

	<!---
	 * true for a condition that is a name, a comparison and a bind, with
	 * single spaces and at most an "AND " or an "OR " in front:
	 * "id = :id:", "AND t.name != :t.name.1:". compileWhereHaving() puts
	 * such a condition together without the patterns. A name that is AND or
	 * OR is left to the patterns, which read it as the conjunction.
	--->
	<cffunction name="isPlainCondition_" access="private" returntype="boolean" output="no">
		<cfargument name="condition" type="any" required="yes">
		<cfset var name = "">

		<cfif NOT IsSimpleValue(arguments.condition)>
			<cfreturn false>
		</cfif>

		<cfif REFind("^(AND |OR )?[A-Za-z_][A-Za-z0-9_.]* (=|[!<>]=|<>|<|>) :[A-Za-z0-9_.]+:$", arguments.condition) NEQ 1>
			<cfreturn false>
		</cfif>

		<!--- the $ of the pattern also matches before a line break at the end --->
		<cfif Compare(Right(arguments.condition, 1), ":") NEQ 0>
			<cfreturn false>
		</cfif>

		<cfset name = ListGetAt(arguments.condition, ListLen(arguments.condition, " ") - 2, " ")>

		<cfreturn CompareNoCase(name, "AND") NEQ 0 AND CompareNoCase(name, "OR") NEQ 0>
	</cffunction>

	<!--- the list of a clause that is named by its property --->
	<cffunction name="clauseGet_" access="private" returntype="array" output="no">
		<cfargument name="clause" type="string" required="yes">

		<cfif Compare(arguments.clause, "QBHaving") EQ 0>
			<cfreturn this.QBHaving>
		</cfif>

		<cfreturn this.QBWhere>
	</cffunction>

	<cffunction name="clauseSet_" access="private" returntype="void" output="no">
		<cfargument name="clause" type="string" required="yes">
		<cfargument name="items" type="array" required="yes">

		<cfif Compare(arguments.clause, "QBHaving") EQ 0>
			<cfset this.QBHaving = arguments.items>
		<cfelse>
			<cfset this.QBWhere = arguments.items>
		</cfif>
	</cffunction>

	<cffunction name="clauseEmpty_" access="private" returntype="boolean" output="no">
		<cfargument name="clause" type="string" required="yes">

		<cfreturn ArrayLen(clauseGet_(arguments.clause)) EQ 0>
	</cffunction>

	<cffunction name="appendClause_" access="private" returntype="void" output="no">
		<cfargument name="clause" type="string" required="yes">
		<cfargument name="entry" type="any" required="yes">

		<cfif Compare(arguments.clause, "QBHaving") EQ 0>
			<cfset ArrayAppend(this.QBHaving, arguments.entry)>
		<cfelse>
			<cfset ArrayAppend(this.QBWhere, arguments.entry)>
		</cfif>
	</cffunction>

	<!--- the set data: true when there is none (a map from set() or a list of rows from setData()) --->
	<cffunction name="setEmpty_" access="private" returntype="boolean" output="no">

		<cfif IsArray(this.QBSet)>
			<cfreturn ArrayLen(this.QBSet) EQ 0>
		</cfif>

		<cfreturn this.QBSet.size() EQ 0>
	</cffunction>

	<!--- a set argument that is empty: an empty string, an empty list or an empty map --->
	<cffunction name="setIsEmpty_" access="private" returntype="boolean" output="no">
		<cfargument name="value" type="any" required="yes">

		<cfif IsSimpleValue(arguments.value)>
			<cfreturn Len(arguments.value) EQ 0>
		</cfif>

		<cfif IsArray(arguments.value)>
			<cfreturn ArrayLen(arguments.value) EQ 0>
		</cfif>

		<cfif IsStruct(arguments.value) AND NOT IsObject(arguments.value)>
			<cfreturn arguments.value.size() EQ 0>
		</cfif>

		<cfreturn false>
	</cffunction>

	<!--- the values of the set map as a list --->
	<cffunction name="setValues_" access="private" returntype="array" output="no">

		<cfreturn toList_(this.QBSet)>
	</cffunction>

	<!--- the option of the write queries, or the default --->
	<cffunction name="optGet_" access="private" returntype="any" output="no">
		<cfargument name="name" type="string" required="yes">
		<cfargument name="default" type="any" required="yes">

		<cfif this.QBOptions.containsKey(JavaCast("string", arguments.name))>
			<cfreturn this.QBOptions[arguments.name]>
		</cfif>

		<cfreturn arguments.default>
	</cffunction>

	<!--- a callable is a list of an object and the name of a public method of it --->
	<cffunction name="isCallable_" access="private" returntype="boolean" output="no">
		<cfargument name="value" type="any" required="yes">

		<cfif NOT IsArray(arguments.value)>
			<cfreturn false>
		</cfif>

		<cfif ArrayLen(arguments.value) NEQ 2>
			<cfreturn false>
		</cfif>

		<cfif NOT IsObject(arguments.value[1]) OR NOT IsSimpleValue(arguments.value[2])>
			<cfreturn false>
		</cfif>

		<cfif REFind("^[A-Za-z_][A-Za-z0-9_]*$", arguments.value[2]) EQ 0>
			<cfreturn false>
		</cfif>

		<cfreturn method_exists(arguments.value[1], arguments.value[2])>
	</cffunction>

	<!--- calls a callable with one or two arguments, the result is ignored --->
	<cffunction name="callCallback_" access="private" returntype="any" output="no">
		<cfargument name="callable" type="any" required="yes">
		<cfargument name="a1" type="any" required="yes">
		<cfargument name="a2" type="any" required="no">
		<cfset var cbObject = "">
		<cfset var cbName = "">
		<cfset var cbArg1 = arguments.a1>
		<cfset var cbArg2 = "">
		<cfset var result = "">

		<cfif NOT isCallable_(arguments.callable)>
			<cfthrow type="ColdIgniter.Exceptions.InvalidArgumentException" message="The callback must be a list of an object and the name of one of its public methods.">
		</cfif>

		<cfset cbObject = arguments.callable[1]>
		<cfset cbName = arguments.callable[2]>

		<cfif StructKeyExists(arguments, "a2")>
			<cfset cbArg2 = arguments.a2>
			<cfset result = Evaluate("cbObject.#cbName#(cbArg1, cbArg2)")>
		<cfelse>
			<cfset result = Evaluate("cbObject.#cbName#(cbArg1)")>
		</cfif>

		<cfreturn "">
	</cffunction>

</cfcomponent>
