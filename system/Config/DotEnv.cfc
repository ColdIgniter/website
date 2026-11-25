<!---
 * Environment-specific configuration
 *
 * Where the values live: the original puts them in getenv(), $_ENV and
 * $_SERVER. There is no process environment to write to here, so the
 * values live in one struct, request.ColdIgniter.env, and env() and the
 * config classes read it. A name is not case-sensitive (like a name in the
 * environment of Windows), which a struct does by itself.
 *
 * Difference: the original also writes putenv(). Not ported yet: a value
 * that is set in the environment of the server process is not read.
 *
 * Difference: an exception is a thrown error here. The error of an
 * unquoted value with spaces has the type
 * "ColdIgniter.Exceptions.InvalidArgumentException".
 *
 * Difference: there is no null, so a variable that is not set and a
 * variable with an empty value are the same to a nested ${name}.
 *
 * Nothing is kept. The original reads and parses the .env
 * file on every request, and so does load() here: the file is read once
 * and walked with one compiled regular expression (see parse()), which is
 * fast enough that a copy of the values is not worth having. The values
 * exist only in the request scope: no copy is written to a file, and
 * nothing is put in the server or application scope. That also means it
 * works the same on several servers, with one WRITEPATH or one for each,
 * as there is no state to share or to get out of step.
 *
 * Upgrade step: an earlier version kept an encrypted copy in
 * WRITEPATH/cache, in files named dotenv_ and a hash. They are not used
 * any more and are not deleted by this code: delete them by hand.
--->
<cfcomponent output="no" hint="Environment-specific configuration">

	<!---
	 * The directory where the .env file can be located.
	 *
	 * @var string
	--->
	<cfset this.path = "">

	<!---
	 * Builds the path to our file.
	--->
	<cffunction name="__construct" access="public" returntype="any" output="no">
		<cfargument name="path" type="string" required="yes">
		<cfargument name="file" type="string" required="no" default=".env">

		<cfset this.path = rtrim_(arguments.path, request.DIRECTORY_SEPARATOR) & request.DIRECTORY_SEPARATOR & arguments.file>

		<cfreturn this>
	</cffunction>

	<!---
	 * The main entry point, will load the .env file and process it
	 * so that we end up with all settings in the environment values
	 * (request.ColdIgniter.env, see the top of this file)
	--->
	<cffunction name="load" access="public" returntype="boolean" output="no">
		<cfreturn NOT is_null(parse())>
	</cffunction>

	<!---
	 * Parse the .env file into a map of key => value
	 *
	 * Difference: the file is read as one string and walked with one
	 * compiled regular expression, so a blank line and a comment line are
	 * never seen by CFML code. A plain line (a simple name, and a value
	 * without whitespace, quote, ##, $ or backslash) is set from the two
	 * groups of the match. Every other line with an equal sign goes through
	 * normaliseVariable() as before, so quotes, export, a comment after the
	 * value, nested ${name} and the error for spaces are the same. The
	 * order of the file is kept. A byte order mark at the start is dropped,
	 * and a carriage return is dropped wherever it is.
	 *
	 * @return A map, or an empty string when there is no file
	--->
	<cffunction name="parse" access="public" returntype="any" output="no">
		<cfset var content = "">
		<cfset var matcher = "">
		<cfset var vars = "">
		<cfset var env = request.ColdIgniter.env>
		<cfset var parts = "">
		<cfset var name = "">
		<cfset var value = "">

		<!--- We don't want to enforce the presence of a .env file, they should be optional. --->
		<cfif NOT is_file(this.path)>
			<cfreturn "">
		</cfif>

		<cftry>
			<cffile action="read" file="#this.path#" variable="content" charset="utf-8">

			<cfcatch type="any">
				<cfthrow type="ColdIgniter.Exceptions.InvalidArgumentException" message="The .env file is not readable: #this.path#">
			</cfcatch>
		</cftry>

		<!--- A byte order mark would end up in the first name. --->
		<cfif Len(content) GT 0 AND Asc(Left(content, 1)) EQ 65279>
			<cfset content = Mid(content, 2, Len(content) - 1)>
		</cfif>

		<!---
		 (?m): ^ and $ are at every line; (?d): only a line feed ends a line.
		 Group 1 and 2: a plain line, name = value, nothing to clean.
		 Group 3: any other line that is not a comment and has an equal sign.
		 A blank line, a comment line and a line without an equal sign do
		 not match at all.
		--->
		<cfset matcher = CreateObject("java", "java.util.regex.Pattern").compile(JavaCast("string", "(?md)^[ \t]*(?:([A-Za-z0-9_.\-]+)[ \t]*=[ \t]*([^\s'""##$\\]*)[ \t]*|([^##\s][^\n]*=[^\n]*))$")).matcher(JavaCast("string", Replace(content, Chr(13), "", "all")))>

		<cfset vars = array_()>

		<cfloop condition="matcher.find()">
			<cfif matcher.start(JavaCast("int", 3)) GTE 0>
				<!--- The slow way, as before. --->
				<cfset parts = normaliseVariable(matcher.group(JavaCast("int", 3)))>
				<cfset name = parts[1]>
				<cfset value = parts[2]>
			<cfelse>
				<cfset name = matcher.group(JavaCast("int", 1))>
				<cfset value = matcher.group(JavaCast("int", 2))>
			</cfif>

			<cfset vars[name] = value>

			<!--- setVariable_(), written out to save a call --->
			<cfif NOT StructKeyExists(env, name) OR Compare(env[name], "") EQ 0 OR Compare(env[name], "0") EQ 0>
				<cfset env[name] = value>
			</cfif>
		</cfloop>

		<cfreturn vars>
	</cffunction>

	<!---
	 * Sets the variable into the environment. Will parse the string
	 * first to look for {name}={value} pattern, ensure that nested
	 * variables are handled, and strip it of single and double quotes.
	 *
	 * Not ported yet: putenv()
	--->
	<cffunction name="setVariable_" access="private" returntype="void" output="no">
		<cfargument name="name" type="string" required="yes">
		<cfargument name="value" type="string" required="no" default="">

		<!--- $_ENV and $_SERVER are one struct here --->
		<cfif NOT StructKeyExists(request.ColdIgniter.env, arguments.name) OR Compare(request.ColdIgniter.env[arguments.name], "") EQ 0 OR Compare(request.ColdIgniter.env[arguments.name], "0") EQ 0>
			<cfset request.ColdIgniter.env[arguments.name] = arguments.value>
		</cfif>
	</cffunction>

	<!---
	 * Parses for assignment, cleans the $name and $value, and ensures
	 * that nested variables are handled.
	 *
	 * @return A list of two: the name and the value
	--->
	<cffunction name="normaliseVariable" access="public" returntype="array" output="no">
		<cfargument name="name" type="string" required="yes">
		<cfargument name="value" type="string" required="no" default="">
		<cfset var parts = ArrayNew(1)>
		<cfset var result = ArrayNew(1)>

		<!--- Split our compound string into its parts. --->
		<cfif Find("=", arguments.name) GT 0>
			<cfset parts = explode("=", arguments.name, 2)>
			<cfset arguments.name = parts[1]>
			<cfset arguments.value = parts[2]>
		</cfif>

		<cfset arguments.name = trim_(arguments.name)>
		<cfset arguments.value = trim_(arguments.value)>

		<!--- Sanitize the name --->
		<cfset arguments.name = JavaCast("string", arguments.name).replaceAll("^export[ \t]++(\S+)", "$1")>
		<cfset arguments.name = Replace(Replace(arguments.name, "'", "", "all"), """", "", "all")>

		<!--- Sanitize the value --->
		<cfset arguments.value = sanitizeValue(arguments.value)>
		<cfset arguments.value = resolveNestedVariables(arguments.value)>

		<cfset ArrayAppend(result, arguments.name)>
		<cfset ArrayAppend(result, arguments.value)>

		<cfreturn result>
	</cffunction>

	<!---
	 * Strips quotes from the environment variable value.
	 *
	 * This was borrowed from the excellent dotenv library by vlucas with very few changes.
	 *
	 * @throws InvalidArgumentException
	--->
	<cffunction name="sanitizeValue" access="private" returntype="string" output="no">
		<cfargument name="value" type="string" required="yes">
		<cfset var quote = "">
		<cfset var regexPattern = "">
		<cfset var parts = ArrayNew(1)>

		<cfif Compare(arguments.value, "") EQ 0>
			<cfreturn arguments.value>
		</cfif>

		<!--- Does it begin with a quote? --->
		<cfif Find(Left(arguments.value, 1), "'""") GT 0>
			<!--- value starts with a quote --->
			<cfset quote = Left(arguments.value, 1)>

			<!---
			 The pattern of the original, without its comments:
			 a quote at the start, then any character other than a quote
			 or backslash, or two backslashes together, or an escaped quote,
			 as many as match, then the closing quote, and any string after
			 the closing quote is discarded.
			--->
			<cfset regexPattern = "^" & quote & "((?:[^" & quote & "\\]|\\\\|\\" & quote & ")*)" & quote & ".*$">

			<cfset arguments.value = JavaCast("string", arguments.value).replaceAll(regexPattern, "$1")>
			<cfset arguments.value = Replace(arguments.value, "\" & quote, quote, "all")>
			<cfset arguments.value = Replace(arguments.value, "\\", "\", "all")>
		<cfelse>
			<cfset parts = explode(" ##", arguments.value, 2)>
			<cfset arguments.value = trim_(parts[1])>

			<!--- Unquoted values cannot contain whitespace --->
			<cfif REFind("[[:space:]]", arguments.value) GT 0>
				<cfthrow type="ColdIgniter.Exceptions.InvalidArgumentException" message=".env values containing spaces must be surrounded by quotes.">
			</cfif>
		</cfif>

		<cfreturn arguments.value>
	</cffunction>

	<!---
	 *  Resolve the nested variables.
	 *
	 * Look for ${varname} patterns in the variable value and replace with an existing
	 * environment variable.
	 *
	 * This was borrowed from the excellent dotenv library by vlucas with very few changes.
	--->
	<cffunction name="resolveNestedVariables" access="private" returntype="string" output="no">
		<cfargument name="value" type="string" required="yes">
		<cfset var result = "">
		<cfset var position = 1>
		<cfset var found = "">
		<cfset var matchedName = "">
		<cfset var nestedVariable = "">

		<cfif Find("$", arguments.value) EQ 0>
			<cfreturn arguments.value>
		</cfif>

		<!--- preg_replace_callback --->
		<cfloop condition="true">
			<cfset found = REFind("\$\{([a-zA-Z0-9_.]+)\}", arguments.value, position, true)>

			<cfif found.pos[1] EQ 0>
				<cfbreak>
			</cfif>

			<cfset result = result & Mid(arguments.value, position, found.pos[1] - position)>
			<cfset matchedName = Mid(arguments.value, found.pos[2], found.len[2])>
			<cfset nestedVariable = getVariable(matchedName)>

			<cfif is_null(nestedVariable)>
				<cfset result = result & Mid(arguments.value, found.pos[1], found.len[1])>
			<cfelse>
				<cfset result = result & nestedVariable>
			</cfif>

			<cfset position = found.pos[1] + found.len[1]>
		</cfloop>

		<cfreturn result & Mid(arguments.value, position, Len(arguments.value) - position + 1)>
	</cffunction>

	<!---
	 * Search the different places for environment variables and return first value found.
	 *
	 * This was borrowed from the excellent dotenv library by vlucas with very few changes.
	 *
	 * Not ported yet: $_SERVER and getenv() are the same struct as $_ENV here.
	 *
	 * @return The value, or an empty string
	--->
	<cffunction name="getVariable" access="private" returntype="string" output="no">
		<cfargument name="name" type="string" required="yes">

		<cfif StructKeyExists(request.ColdIgniter.env, arguments.name)>
			<cfreturn request.ColdIgniter.env[arguments.name]>
		</cfif>

		<cfreturn "">
	</cffunction>

</cfcomponent>
