<!---
 * Query builder
 *
 * Difference: there is no Stringable, so a caller that needs the text of a
 * Query calls __toString() (or getQuery()) itself. A method cannot have the
 * name toString on this server, so the name of the original is kept.
 *
 * Difference: the binds are kept as a list of pairs [value, escape] for the
 * simple (?) binds, and as a map (see array_()) of name to the pair for the
 * named binds. An empty string is a null bind value.
 *
 * Difference: strings are made of characters here, not of bytes, so the
 * multibyte handling of the original (getMultibyteCharPattern(),
 * getCharLength() and the checks that call them) is not needed and is not
 * ported.
 *
 * Difference: the platform of the connection is read from getPlatform()
 * ("MySQLi", "SQLSRV", "Postgre", "SQLite3", "OCI8"), where the original
 * checks the class of the connection, as every connection class here has the
 * name "Connection" and instanceof_() compares the short name only.
 *
 * Difference: there is no regular expression with a quantifier inside a
 * quantifier; the scanning is done with Find() and plain loops, and the
 * patterns that remain are noted where they are used.
 *
 * Difference: is_null(x) is written out as (IsSimpleValue(x) AND x EQ "")
 * in this file, which is the body of is_null(). A query passes these tests
 * several times, and the test costs a tenth of the call of the function.
--->
<cfcomponent output="no" extends="QueryInterface" hint="Query builder">

	<!---
	 * The query string, as provided by the user.
	 *
	 * @var string
	--->
	<cfset this.originalQueryString = "">

	<!---
	 * The query string if table prefix has been swapped.
	 *
	 * @var string|null
	--->
	<cfset this.swappedQueryString = "">

	<!---
	 * The final query string after binding, etc.
	 *
	 * @var string|null
	--->
	<cfset this.finalQueryString = "">

	<!---
	 * The binds and their values used for binding.
	 *
	 * @var array
	--->
	<cfset this.binds = ArrayNew(1)>

	<!---
	 * Bind marker
	 *
	 * Character used to identify values in a prepared statement.
	 *
	 * @var string
	--->
	<cfset this.bindMarker = "?">

	<!---
	 * The start time in seconds with microseconds
	 * for when this query was executed.
	 *
	 * @var float|string
	--->
	<cfset this.startTime = 0>

	<!---
	 * The end time in seconds with microseconds
	 * for when this query was executed.
	 *
	 * @var float
	--->
	<cfset this.endTime = 0>

	<!---
	 * The error code, if any.
	 *
	 * Difference: starts as 0, as getErrorCode() has to return a number.
	 *
	 * @var int
	--->
	<cfset this.errorCode = 0>

	<!---
	 * The error message, if any.
	 *
	 * @var string
	--->
	<cfset this.errorString = "">

	<!---
	 * Pointer to database connection.
	 * Mainly for escaping features.
	 *
	 * @var ConnectionInterface
	--->
	<cfset this.db = "">

	<cffunction name="__construct" access="public" returntype="any" output="no">
		<cfargument name="db" type="any" required="yes">

		<cfset this.db = arguments.db>

		<cfreturn this>
	</cffunction>

	<cffunction name="setQuery" access="public" returntype="any" output="no">
		<cfargument name="sql" type="string" required="yes">
		<cfargument name="binds" type="any" required="no" default="">
		<cfargument name="setEscape" type="boolean" required="no" default="true">
		<cfset var binds_ = arguments.binds>

		<cfset this.originalQueryString = arguments.sql>
		<cfset this.swappedQueryString = "">

		<cfif NOT (IsSimpleValue(binds_) AND binds_ EQ "")>
			<!--- an object (a RawSql) is one bind; IsStruct() is true for a component --->
			<cfif NOT is_array(binds_) OR IsObject(binds_)>
				<cfset binds_ = ArrayNew(1)>
				<cfset ArrayAppend(binds_, arguments.binds)>
			</cfif>

			<cfif arguments.setEscape>
				<cfset binds_ = wrapBinds(binds_)>
			</cfif>

			<cfset this.binds = binds_>
		</cfif>

		<cfset this.finalQueryString = "">

		<cfreturn this>
	</cffunction>

	<!---
	 * Will store the variables to bind into the query later.
	 *
	 * @param array binds
	 *
	 * @return $this
	--->
	<cffunction name="setBinds" access="public" returntype="any" output="no">
		<cfargument name="binds" type="any" required="yes">
		<cfargument name="setEscape" type="boolean" required="no" default="true">
		<cfset var binds_ = arguments.binds>

		<cfif arguments.setEscape>
			<cfset binds_ = wrapBinds(binds_)>
		</cfif>

		<cfset this.binds = binds_>

		<cfset this.finalQueryString = "">

		<cfreturn this>
	</cffunction>

	<!---
	 * Not in the original. Stands in for the array_walk() that turns each
	 * bind value into the pair [value, true]. A new list or map is made, as
	 * the one that was passed in must not change.
	--->
	<cffunction name="wrapBinds" access="private" returntype="any" output="no">
		<cfargument name="binds" type="any" required="yes">
		<cfset var result = "">
		<cfset var pair = "">
		<cfset var key = "">
		<cfset var i = 0>

		<cfif IsArray(arguments.binds)>
			<cfset result = ArrayNew(1)>

			<cfloop from="1" to="#ArrayLen(arguments.binds)#" index="i">
				<cfset pair = ArrayNew(1)>
				<cfset ArrayAppend(pair, arguments.binds[i])>
				<cfset ArrayAppend(pair, true)>
				<cfset ArrayAppend(result, pair)>
			</cfloop>

			<cfreturn result>
		</cfif>

		<cfset result = array_()>

		<cfloop collection="#arguments.binds#" item="key">
			<cfset pair = ArrayNew(1)>
			<cfset ArrayAppend(pair, arguments.binds[key])>
			<cfset ArrayAppend(pair, true)>
			<cfset result[key] = pair>
		</cfloop>

		<cfreturn result>
	</cffunction>

	<cffunction name="getQuery" access="public" returntype="string" output="no">

		<cfif IsSimpleValue(this.finalQueryString) AND this.finalQueryString EQ "">
			<cfset compileBinds()>
		</cfif>

		<cfreturn this.finalQueryString>
	</cffunction>

	<cffunction name="setDuration" access="public" returntype="any" output="no">
		<cfargument name="start" type="numeric" required="yes">
		<cfargument name="end" type="any" required="no" default="">
		<cfset var end_ = arguments.end>

		<cfset this.startTime = arguments.start>

		<cfif IsSimpleValue(end_) AND end_ EQ "">
			<cfset end_ = microtime(true)>
		</cfif>

		<cfset this.endTime = end_>

		<cfreturn this>
	</cffunction>

	<!---
	 * Returns the start time in seconds with microseconds.
	 *
	 * @return float|string
	--->
	<cffunction name="getStartTime" access="public" returntype="any" output="no">
		<cfargument name="returnRaw" type="boolean" required="no" default="false">
		<cfargument name="decimals" type="numeric" required="no" default="6">

		<cfif arguments.returnRaw>
			<cfreturn this.startTime>
		</cfif>

		<cfreturn number_format(this.startTime, arguments.decimals)>
	</cffunction>

	<cffunction name="getDuration" access="public" returntype="string" output="no">
		<cfargument name="decimals" type="numeric" required="no" default="6">

		<cfreturn number_format(this.endTime - this.startTime, arguments.decimals)>
	</cffunction>

	<cffunction name="setError" access="public" returntype="any" output="no">
		<cfargument name="code" type="numeric" required="yes">
		<cfargument name="error" type="string" required="yes">

		<cfset this.errorCode = arguments.code>
		<cfset this.errorString = arguments.error>

		<cfreturn this>
	</cffunction>

	<cffunction name="hasError" access="public" returntype="boolean" output="no">

		<cfreturn Compare(this.errorString, "") NEQ 0>
	</cffunction>

	<cffunction name="getErrorCode" access="public" returntype="numeric" output="no">

		<cfreturn this.errorCode>
	</cffunction>

	<cffunction name="getErrorMessage" access="public" returntype="string" output="no">

		<cfreturn this.errorString>
	</cffunction>

	<cffunction name="isWriteType" access="public" returntype="boolean" output="no">

		<cfreturn this.db.isWriteType(this.originalQueryString)>
	</cffunction>

	<!---
	 * The pattern is (\W)orig(\S): one pass, with no quantifier. orig is
	 * the prefix from the configuration, used as it is, so the pattern is
	 * not guarded by the subject limit (the SQL is the query of the code).
	--->
	<cffunction name="swapPrefix" access="public" returntype="any" output="no">
		<cfargument name="orig" type="string" required="yes">
		<cfargument name="swap" type="string" required="yes">
		<cfset var sql = this.swappedQueryString>
		<cfset var from = "">
		<cfset var to = "">

		<cfif IsSimpleValue(sql) AND sql EQ "">
			<cfset sql = this.originalQueryString>
		</cfif>

		<cfset from = "/(\W)" & arguments.orig & "(\S)/">
		<cfset to = "\1" & arguments.swap & "\2">

		<cfset this.swappedQueryString = preg_replace(from, to, sql, true)>

		<cfset this.finalQueryString = "">

		<cfreturn this>
	</cffunction>

	<cffunction name="getOriginalQuery" access="public" returntype="string" output="no">

		<cfreturn this.originalQueryString>
	</cffunction>

	<!---
	 * Escapes and inserts any binds into the finalQueryString property.
	 *
	 * @see https://regex101.com/r/EUEhay/5
	 *
	 * @return void
	--->
	<cffunction name="compileBinds" access="private" returntype="void" output="no">
		<cfset var sql = this.swappedQueryString>
		<cfset var binds_ = this.binds>
		<cfset var bindCount = 0>
		<cfset var ml = 0>

		<cfif IsSimpleValue(sql) AND sql EQ "">
			<cfset sql = this.originalQueryString>
		</cfif>

		<cfif (IsArray(binds_) AND ArrayLen(binds_) EQ 0) OR (NOT IsArray(binds_) AND StructCount(binds_) EQ 0)>
			<cfset this.finalQueryString = sql>

			<cfreturn>
		</cfif>

		<cfif IsArray(binds_)>
			<cfset bindCount = ArrayLen(binds_)>
			<cfset ml = Len(this.bindMarker)>

			<cfset this.finalQueryString = matchSimpleBinds(sql, binds_, bindCount, ml)>
		<cfelse>
			<!--- Reverse the binds so that duplicate named binds
			      will be processed prior to the original binds. --->
			<cfset this.finalQueryString = matchNamedBinds(sql, binds_)>
		</cfif>
	</cffunction>

	<!---
	 * @param binds A map of name to the pair [value, escape]
	 *
	 * Difference: the map is read from its last key to its first, which is
	 * what array_reverse() does in the original.
	--->
	<cffunction name="matchNamedBinds" access="private" returntype="string" output="no">
		<cfargument name="sql" type="string" required="yes">
		<cfargument name="binds" type="any" required="yes">
		<cfset var replacers = array_()>
		<cfset var keys = array_reverse(array_keys(arguments.binds))>
		<cfset var placeholder = "">
		<cfset var value = "">
		<cfset var escapedValue = "">
		<cfset var i = 0>

		<cfloop from="1" to="#ArrayLen(keys)#" index="i">
			<cfset placeholder = keys[i]>
			<cfset value = arguments.binds[placeholder]>

			<!--- value[2] contains the boolean whether should be escaped or not --->
			<cfif value[2]>
				<cfset escapedValue = this.db.escape(value[1])>
			<cfelse>
				<cfset escapedValue = value[1]>
			</cfif>

			<!--- In order to correctly handle backlashes in saved strings
			      we will need to preg_quote, so remove the wrapping escape characters
			      otherwise it will get escaped. --->
			<cfif IsArray(value[1])>
				<cfset escapedValue = "(" & implode(",", escapedValue) & ")">
			</cfif>

			<cfset replacers[":" & placeholder & ":"] = escapedValue>
		</cfloop>

		<cfreturn replaceNamedPlaceholders(arguments.sql, replacers)>
	</cffunction>

	<!---
	 * Works like strtr(), but leaves quoted strings, quoted identifiers
	 * and comments untouched, so that values already rendered into the SQL
	 * (escaped values, compiled subqueries) are never treated as placeholders.
	 *
	 * @param replacers A map of ":name:" to the text
	 *
	 * Bounds: the scan visits each character a constant number of times; the
	 * finders it calls look forward only, and the longest placeholder
	 * is tried only up to the longest key.
	--->
	<cffunction name="replaceNamedPlaceholders" access="private" returntype="string" output="no">
		<cfargument name="sql" type="string" required="yes">
		<cfargument name="replacers" type="any" required="yes">
		<cfset var maxLength = 0>
		<cfset var keys = array_keys(arguments.replacers)>
		<cfset var platform = this.db.getPlatform()>
		<cfset var isMySQL = Compare(platform, "MySQLi") EQ 0>
		<cfset var isSQLSRV = Compare(platform, "SQLSRV") EQ 0>
		<cfset var isPostgre = Compare(platform, "Postgre") EQ 0>
		<cfset var isSQLite = Compare(platform, "SQLite3") EQ 0>
		<cfset var isOCI8 = Compare(platform, "OCI8") EQ 0>
		<cfset var backslashEscapes = false>
		<cfset var length = Len(arguments.sql)>
		<cfset var result = "">
		<cfset var offset = 0>
		<cfset var position = 0>
		<cfset var char = "">
		<cfset var next = "">
		<cfset var third = "">
		<cfset var end = 0>
		<cfset var placeholder = "">
		<cfset var close = 0>
		<cfset var closer = "">
		<cfset var isEscapeString = false>
		<cfset var handled = false>
		<cfset var newLine = 0>
		<cfset var tag = "">
		<cfset var found = 0>
		<cfset var j = 0>
		<cfset var i = 0>

		<!--- Difference: the characters are looked for with REFind(), where the original uses strpbrk(). --->
		<cfif REFind("['""`##\[$]", arguments.sql) EQ 0 AND Find("--", arguments.sql) EQ 0 AND Find("/*", arguments.sql) EQ 0>
			<cfreturn strtr(arguments.sql, arguments.replacers)>
		</cfif>

		<cfloop from="1" to="#ArrayLen(keys)#" index="i">
			<cfif Len(keys[i]) GT maxLength>
				<cfset maxLength = Len(keys[i])>
			</cfif>
		</cfloop>

		<!--- Backslash escapes matter only when there is a backslash in the SQL. --->
		<cfif Find("\", arguments.sql) GT 0>
			<cfset backslashEscapes = Compare(this.db.escapeString("\"), "\") NEQ 0>
		</cfif>

		<cfloop condition="offset LT length">
			<!---
			 * Difference: the next character of $stop is found with REFind(),
			 * and the parts are read with Mid(), where the original uses
			 * strcspn(), substr() and $sql[$position]. This loop runs for
			 * every query of the builder, and a call of a function costs
			 * more here than the work it does. The set is $stop of the
			 * original: : ' " ` - / ## [ $
			--->
			<cfset found = REFind("[:'""`/##\[$-]", arguments.sql, offset + 1)>

			<cfif found EQ 0>
				<cfset position = length>
			<cfelse>
				<cfset position = found - 1>
			</cfif>

			<cfif position GT offset>
				<cfset result = result & Mid(arguments.sql, offset + 1, position - offset)>
			</cfif>

			<cfif position GTE length>
				<cfbreak>
			</cfif>

			<cfset char = Mid(arguments.sql, position + 1, 1)>
			<cfset next = "">

			<cfif position + 1 LT length>
				<cfset next = Mid(arguments.sql, position + 2, 1)>
			</cfif>
			<cfset end = position + 1>
			<cfset handled = false>

			<cfif Compare(char, ":") EQ 0>
				<cfset placeholder = findPlaceholderAt(arguments.sql, position, arguments.replacers, maxLength)>

				<cfif NOT (IsSimpleValue(placeholder) AND placeholder EQ "")>
					<cfset result = result & arguments.replacers[placeholder]>
					<cfset offset = position + Len(placeholder)>
					<cfset handled = true>
				</cfif>
			<cfelseif Compare(char, "'") EQ 0 AND isOCI8 AND preg_match("/(?<![\w$##])[nN]?[qQ]\z/", substr(arguments.sql, Max(0, position - 3), Min(3, position)), true) EQ 1 AND Len(Trim(next)) GT 0>
				<!--- Oracle alternative quoting: q'[...]', q'{...}', q'<...>', q'(...)' or q'X...X' --->
				<cfset closer = next>
				<cfset j = Find(next, "[{<(")>

				<cfif j GT 0>
					<cfset closer = Mid("]}>)", j, 1)>
				</cfif>

				<cfset close = strpos(arguments.sql, closer & "'", position + 2)>

				<cfif close EQ -1>
					<cfset end = length>
				<cfelse>
					<cfset end = close + 2>
				</cfif>
			<cfelseif Compare(char, "'") EQ 0>
				<!--- PostgreSQL E'...' strings always use backslash escapes. --->
				<cfset isEscapeString = false>

				<cfif isPostgre AND position GT 0 AND (Compare(charAt(arguments.sql, position - 1), "E") EQ 0 OR Compare(charAt(arguments.sql, position - 1), "e") EQ 0)>
					<cfset isEscapeString = position EQ 1 OR preg_match("/[\w$\u0080-\uFFFF]/", charAt(arguments.sql, position - 2), true) NEQ 1>
				</cfif>

				<cfset end = findQuotedEnd(arguments.sql, position, "'", backslashEscapes OR isEscapeString)>
			<cfelseif Compare(char, """") EQ 0>
				<!--- Only MySQL uses "..." for strings; elsewhere it quotes
				      identifiers, in which a backslash is never an escape. --->
				<cfset end = findQuotedEnd(arguments.sql, position, """", backslashEscapes AND isMySQL)>
			<cfelseif Compare(char, "`") EQ 0>
				<cfset end = findQuotedEnd(arguments.sql, position, "`", false)>
			<cfelseif Compare(char, "[") EQ 0 AND (isSQLSRV OR isSQLite)>
				<cfset end = findQuotedEnd(arguments.sql, position, "]", false)>
			<cfelseif Compare(char, "$") EQ 0 AND isPostgre AND (position EQ 0 OR preg_match("/[\w$\u0080-\uFFFF]/", charAt(arguments.sql, position - 1), true) NEQ 1)>
				<!--- PostgreSQL dollar-quoted strings: $$...$$ or $tag$...$tag$
				      The tag is read with a loop, [A-Za-z_] and then word characters, up to a $. --->
				<cfset tag = "">
				<cfset j = position + 1>

				<cfif Len(next) GT 0 AND (Compare(next, "$") EQ 0 OR REFind("[A-Za-z_]", next) GT 0 OR Asc(next) GT 127)>
					<cfloop condition="j LT length AND (REFind(""[A-Za-z0-9_]"", charAt(arguments.sql, j)) GT 0 OR Asc(charAt(arguments.sql, j)) GT 127)">
						<cfset j = j + 1>
					</cfloop>

					<cfif Compare(charAt(arguments.sql, j), "$") EQ 0>
						<cfset tag = substr(arguments.sql, position, j - position + 1)>
					</cfif>
				</cfif>

				<cfif Len(tag) GT 0>
					<cfset close = strpos(arguments.sql, tag, position + Len(tag))>

					<cfif close EQ -1>
						<cfset end = length>
					<cfelse>
						<cfset end = close + Len(tag)>
					</cfif>
				</cfif>
			<cfelseif (Compare(char, "-") EQ 0 AND Compare(next, "-") EQ 0) OR (Compare(char, "##") EQ 0 AND isMySQL)>
				<!--- MySQL requires whitespace after "--" and also supports "#" comments. --->
				<cfset third = charAt(arguments.sql, position + 2)>

				<cfif Len(third) EQ 0>
					<cfset third = " ">
				</cfif>

				<cfif Compare(char, "##") EQ 0 OR NOT isMySQL OR Asc(third) LTE 32>
					<cfset newLine = strpos(arguments.sql, Chr(10), position)>

					<cfif newLine EQ -1>
						<cfset end = length>
					<cfelse>
						<cfset end = newLine>
					</cfif>
				</cfif>
			<cfelseif Compare(char, "/") EQ 0 AND Compare(next, "*") EQ 0 AND (NOT isMySQL OR Compare(charAt(arguments.sql, position + 2), "!") NEQ 0)>
				<!--- MySQL executes /*! ... */ comments, so they are not skipped.
				      PostgreSQL and SQL Server allow nested block comments. --->
				<cfset end = findCommentEnd(arguments.sql, position, isPostgre OR isSQLSRV)>
			</cfif>

			<!--- there is no cfcontinue: a placeholder has been put in and the offset set --->
			<cfif NOT handled>
				<cfset result = result & Mid(arguments.sql, position + 1, end - position)>
				<cfset offset = end>
			</cfif>
		</cfloop>

		<cfreturn result>
	</cffunction>

	<!---
	 * Not in the original. Returns the character at a position (from 0), or
	 * an empty string when the position is not in the string, as
	 * $sql[$position] ?? '' does.
	--->
	<cffunction name="charAt" access="private" returntype="string" output="no">
		<cfargument name="sql" type="string" required="yes">
		<cfargument name="position" type="numeric" required="yes">

		<cfif arguments.position LT 0 OR arguments.position GTE Len(arguments.sql)>
			<cfreturn "">
		</cfif>

		<cfreturn Mid(arguments.sql, arguments.position + 1, 1)>
	</cffunction>

	<!---
	 * Returns the longest placeholder that starts at the given position,
	 * matching the strtr() behavior. An empty string (null) when there is none.
	 *
	 * @param replacers A map of ":name:" to the text
	--->
	<cffunction name="findPlaceholderAt" access="private" returntype="string" output="no">
		<cfargument name="sql" type="string" required="yes">
		<cfargument name="position" type="numeric" required="yes">
		<cfargument name="replacers" type="any" required="yes">
		<cfargument name="maxLength" type="numeric" required="yes">
		<cfset var candidates = ArrayNew(1)>
		<cfset var colon = arguments.position>
		<cfset var length = Len(arguments.sql)>
		<cfset var i = 0>

		<!--- Difference: Find() and Mid(), where the original uses strpos() and substr(). --->
		<cfloop condition="true">
			<cfif colon + 2 GT length>
				<cfbreak>
			</cfif>

			<!--- The position from 0 of the next colon, -1 when there is none. --->
			<cfset colon = Find(":", arguments.sql, colon + 2) - 1>

			<cfif colon EQ -1 OR colon - arguments.position GTE arguments.maxLength>
				<cfbreak>
			</cfif>

			<cfset ArrayAppend(candidates, Mid(arguments.sql, arguments.position + 1, colon - arguments.position + 1))>
		</cfloop>

		<cfloop from="#ArrayLen(candidates)#" to="1" index="i" step="-1">
			<cfif StructKeyExists(arguments.replacers, candidates[i])>
				<cfreturn candidates[i]>
			</cfif>
		</cfloop>

		<cfreturn "">
	</cffunction>

	<!---
	 * Returns the position just after the end of the block comment
	 * that starts at the given position.
	 *
	 * Bounds: each step moves the offset forward by 2, and a step looks for
	 * the next "/*" and the next "*" "/" only.
	--->
	<cffunction name="findCommentEnd" access="private" returntype="numeric" output="no">
		<cfargument name="sql" type="string" required="yes">
		<cfargument name="position" type="numeric" required="yes">
		<cfargument name="nested" type="boolean" required="yes">
		<cfset var close = 0>
		<cfset var depth = 0>
		<cfset var offset = arguments.position>
		<cfset var open = 0>
		<cfset var found = 0>

		<cfif NOT arguments.nested>
			<cfset close = strpos(arguments.sql, "*/", arguments.position + 2)>

			<cfif close EQ -1>
				<cfreturn Len(arguments.sql)>
			</cfif>

			<cfreturn close + 2>
		</cfif>

		<cfloop condition="true">
			<cfset open = strpos(arguments.sql, "/*", offset)>
			<cfset close = strpos(arguments.sql, "*/", offset)>

			<cfif open EQ -1 AND close EQ -1>
				<cfbreak>
			</cfif>

			<cfif close EQ -1 OR (open NEQ -1 AND open LT close)>
				<cfset found = open>
				<cfset depth = depth + 1>
			<cfelse>
				<cfset found = close>
				<cfset depth = depth - 1>
			</cfif>

			<cfset offset = found + 2>

			<cfif depth EQ 0>
				<cfreturn offset>
			</cfif>
		</cfloop>

		<cfreturn Len(arguments.sql)>
	</cffunction>

	<!---
	 * Returns the position just after the closing quote of the quoted
	 * string or identifier that starts at the given position.
	--->
	<cffunction name="findQuotedEnd" access="private" returntype="numeric" output="no">
		<cfargument name="sql" type="string" required="yes">
		<cfargument name="position" type="numeric" required="yes">
		<cfargument name="quote" type="string" required="yes">
		<cfargument name="backslashEscapes" type="boolean" required="yes">
		<cfset var stop = arguments.quote>
		<cfset var length = Len(arguments.sql)>
		<cfset var offset = arguments.position + 1>
		<cfset var found = 0>

		<!---
		 * Difference: with no backslash escapes the quote is found with
		 * Find(). The position from 1 of a quote is also the position from 0
		 * of the character after it.
		--->
		<cfif NOT arguments.backslashEscapes>
			<cfloop condition="offset LT length">
				<cfset found = Find(arguments.quote, arguments.sql, offset + 1)>

				<cfif found EQ 0>
					<cfbreak>
				</cfif>

				<cfif found LT length AND Compare(Mid(arguments.sql, found + 1, 1), arguments.quote) EQ 0>
					<!--- A doubled quote. --->
					<cfset offset = found + 1>
				<cfelse>
					<cfreturn found>
				</cfif>
			</cfloop>

			<cfreturn length>
		</cfif>

		<cfset stop = arguments.quote & "\">

		<cfloop condition="offset LT length">
			<cfset offset = offset + strcspn(arguments.sql, stop, offset)>

			<cfif offset GTE length>
				<cfbreak>
			</cfif>

			<!--- there is no cfcontinue, so a cfif chain --->
			<cfif Compare(charAt(arguments.sql, offset), "\") EQ 0>
				<cfset offset = offset + 2>
			<cfelseif Compare(charAt(arguments.sql, offset + 1), arguments.quote) EQ 0>
				<cfset offset = offset + 2>
			<cfelse>
				<cfreturn offset + 1>
			</cfif>
		</cfloop>

		<cfreturn length>
	</cffunction>

	<!---
	 * @param binds A list of the pairs [value, escape]
	 *
	 * Bounds: no regular expression. The quoted strings ('...' with no quote
	 * inside, as the original) are found with Find(), the markers are found with
	 * FindNoCase() from the end of the last one, and a marker inside a quoted
	 * string is not counted. The values are put in from the last marker to
	 * the first, on the original SQL, so that the offsets stay right.
	--->
	<cffunction name="matchSimpleBinds" access="private" returntype="string" output="no">
		<cfargument name="sql" type="string" required="yes">
		<cfargument name="binds" type="any" required="yes">
		<cfargument name="bindCount" type="numeric" required="yes">
		<cfargument name="ml" type="numeric" required="yes">
		<cfset var sql_ = arguments.sql>
		<cfset var spans = ArrayNew(1)>
		<cfset var offsets = ArrayNew(1)>
		<cfset var span = "">
		<cfset var open = 0>
		<cfset var close = 0>
		<cfset var found = 0>
		<cfset var inQuote = false>
		<cfset var c = 0>
		<cfset var escapedValue = "">
		<cfset var i = 0>
		<cfset var j = 0>

		<!--- the pairs of quotes, from left to right --->
		<cfset open = Find("'", sql_, 1)>

		<cfloop condition="open GT 0">
			<cfset close = Find("'", sql_, open + 1)>

			<cfif close EQ 0>
				<cfbreak>
			</cfif>

			<cfset span = ArrayNew(1)>
			<cfset ArrayAppend(span, open)>
			<cfset ArrayAppend(span, close)>
			<cfset ArrayAppend(spans, span)>

			<cfset open = Find("'", sql_, close + 1)>
		</cfloop>

		<!--- the markers that are not in a pair of quotes (0 based offsets) --->
		<cfset found = FindNoCase(this.bindMarker, sql_, 1)>
		<cfset j = 1>

		<cfloop condition="found GT 0">
			<cfloop condition="j LTE ArrayLen(spans) AND spans[j][2] LT found">
				<cfset j = j + 1>
			</cfloop>

			<cfset inQuote = j LTE ArrayLen(spans) AND spans[j][1] LTE found>

			<cfif NOT inQuote>
				<cfset ArrayAppend(offsets, found - 1)>
			</cfif>

			<cfset found = FindNoCase(this.bindMarker, sql_, found + arguments.ml)>
		</cfloop>

		<cfset c = ArrayLen(offsets)>

		<!--- Bind values' count must match the count of markers in the query --->
		<cfif arguments.bindCount NEQ c>
			<cfreturn arguments.sql>
		</cfif>

		<cfloop condition="c GT 0">
			<cfset c = c - 1>

			<cfif arguments.binds[c + 1][2]>
				<cfset escapedValue = this.db.escape(arguments.binds[c + 1][1])>
			<cfelse>
				<cfset escapedValue = arguments.binds[c + 1][1]>
			</cfif>

			<cfif IsArray(escapedValue)>
				<cfset escapedValue = "(" & implode(",", escapedValue) & ")">
			</cfif>

			<cfset sql_ = substr(sql_, 0, offsets[c + 1]) & escapedValue & substr(sql_, offsets[c + 1] + arguments.ml)>
		</cfloop>

		<cfreturn sql_>
	</cffunction>

	<!---
	 * Returns string to display in debug toolbar
	 *
	 * Difference: the original finds the key words with a pattern that has a
	 * quantifier inside a quantifier. Here the key words are found with one
	 * pattern with no quantifier, and a key word is bolded when the number
	 * of &#039; after it is even, which is what the original pattern is
	 * meant to test.
	 *
	 * Difference: [^(&#039;)] of the original is a character class (any
	 * character but ( & # 0 3 9 ; )), so the original also bolds some key
	 * words inside a quoted string, as the AND of SELECT 'AND' FROM t0.
	 * Here a key word inside a quoted string is never bolded.
	--->
	<cffunction name="debugToolbarDisplay" access="public" returntype="string" output="no">
		<!--- Key words we want bolded --->
		<cfset var highlight = "AND|AS|ASC|AVG|BY|COUNT|DESC|DISTINCT|FROM|GROUP|HAVING|IN|INNER|INSERT|INTO|IS|JOIN|LEFT|LIKE|LIMIT|MAX|MIN|NOT|NULL|OFFSET|ON|OR|ORDER|RIGHT|SELECT|SUM|UPDATE|VALUES|WHERE">
		<cfset var sql = esc(getQuery())>
		<cfset var quote = "&##039;">
		<cfset var matcher = CreateObject("java", "java.util.regex.Pattern").compile("\b(?:" & highlight & ")\b").matcher(sql)>
		<cfset var result = "">
		<cfset var total = 0>
		<cfset var before = 0>
		<cfset var last = 0>
		<cfset var start = 0>
		<cfset var stop = 0>
		<cfset var segment = "">
		<cfset var found = 0>

		<!--- how many quotes there are in all --->
		<cfset found = Find(quote, sql, 1)>

		<cfloop condition="found GT 0">
			<cfset total = total + 1>
			<cfset found = Find(quote, sql, found + Len(quote))>
		</cfloop>

		<cfloop condition="matcher.find()">
			<cfset start = matcher.start()>
			<cfset stop = matcher.end()>
			<cfset segment = substr(sql, last, start - last)>

			<!--- the quotes in the text before the key word --->
			<cfset found = Find(quote, segment, 1)>

			<cfloop condition="found GT 0">
				<cfset before = before + 1>
				<cfset found = Find(quote, segment, found + Len(quote))>
			</cfloop>

			<cfset result = result & segment>

			<cfif (total - before) MOD 2 EQ 0>
				<cfset result = result & "<strong>" & Replace(substr(sql, start, stop - start), " ", "&nbsp;", "all") & "</strong>">
			<cfelse>
				<cfset result = result & substr(sql, start, stop - start)>
			</cfif>

			<cfset last = stop>
		</cfloop>

		<cfreturn result & substr(sql, last)>
	</cffunction>

	<!---
	 * Return text representation of the query
	--->
	<cffunction name="__toString" access="public" returntype="string" output="no">
		<cfreturn this.getQuery()>
	</cffunction>

</cfcomponent>
