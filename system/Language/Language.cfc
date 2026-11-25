<!---
 * Handle system messages and localization.
 *
 * Locale-based. The original is built on the intl extension.
 *
 * Not ported yet: MessageFormatter, so only {name} and {0} are replaced in
 * a message (see formatMessage). The plural, select and number forms of
 * ICU, and its quoting with the apostrophe, are not known.
 *
 * Difference: only the English form {n, plural, =1{# year} other{# years}}
 * is known (see formatMessage).
 *
 * Not ported yet: plural rules of other locales, and the select, number
 * and date forms.
 *
 * Not ported yet: the file locator. A language file is searched in the
 * folder "Language/{locale}" of every namespace the autoloader knows
 * (system first, then the application), see requireFile.
 *
 * Difference: a language file is not a script that returns an array. It is
 * a .cfm file that sets the variable "lines" to a map (see array_()), and
 * it is included by Language/Closure.cfc.
 *
 * Difference: setLocale and getLocale are built-in functions, so the methods
 * are setLocale_ and getLocale_.
 *
 * Difference: a null line (an empty string) and a missing one cannot be
 * told apart, so a line whose text is "" is as good as missing.
--->
<cfcomponent output="no" hint="Handle system messages and localization">

	<!---
	 * Stores the retrieved language lines
	 * from files for faster retrieval on
	 * second use.
	 *
	 * @var array<non-empty-string, array<non-empty-string, LoadedStrings>>
	--->
	<cfset this.language = CreateObject("java", "java.util.LinkedHashMap").init()>

	<!---
	 * The current locale to work with.
	 *
	 * @var non-empty-string
	--->
	<cfset this.locale = "">

	<!---
	 * Boolean value whether the `intl` extension exists on the system.
	 *
	 * Difference: there is no intl, but the simple replacement of formatMessage
	 * is always there, so this is true.
	 *
	 * @var bool
	--->
	<cfset this.intlSupport = true>

	<!---
	 * Stores filenames that have been
	 * loaded so that we don't load them again.
	 *
	 * @var array<non-empty-string, list<non-empty-string>>
	--->
	<cfset this.loadedFiles = CreateObject("java", "java.util.LinkedHashMap").init()>

	<!---
	 * @param locale non-empty-string
	--->
	<cffunction name="__construct" access="public" returntype="any" output="no">
		<cfargument name="locale" type="string" required="yes">

		<cfset this.locale = arguments.locale>

		<!--- Not ported yet: class_exists(MessageFormatter), see intlSupport --->

		<cfreturn this>
	</cffunction>

	<!---
	 * Sets the current locale to use when performing string lookups.
	 *
	 * Named with an underscore, because SetLocale is a built-in function.
	 *
	 * @param locale non-empty-string, or an empty string (null) to keep the locale
	 *
	 * @return The Language
	--->
	<cffunction name="setLocale_" access="public" returntype="any" output="no">
		<cfargument name="locale" type="string" required="no" default="">

		<cfif NOT is_null(arguments.locale)>
			<cfset this.locale = arguments.locale>
		</cfif>

		<cfreturn this>
	</cffunction>

	<!---
	 * Named with an underscore, because GetLocale is a built-in function.
	--->
	<cffunction name="getLocale_" access="public" returntype="string" output="no">
		<cfreturn this.locale>
	</cffunction>

	<!---
	 * Parses the language string for a file, loads the file, if necessary,
	 * getting the line.
	 *
	 * @param line
	 * @param args A map (see array_()) of named values, a list of values, or an empty string for none
	 *
	 * @return A list of strings, or a string
	--->
	<cffunction name="getLine" access="public" returntype="any" output="no">
		<cfargument name="line" type="string" required="yes">
		<cfargument name="args" type="any" required="no" default="">
		<cfset var file = "">
		<cfset var parsedLine = "">
		<cfset var parsed = "">
		<cfset var output = "">
		<cfset var locale = "">

		<!--- 1. Format the line as-is if it does not have a file. --->
		<cfif Find(".", arguments.line) EQ 0>
			<cfreturn formatMessage(arguments.line, arguments.args)>
		</cfif>

		<!--- 2. Get the formatted line using the file and line extracted from $line and the current locale. --->
		<cfset parsed = parseLine(arguments.line, this.locale)>
		<cfset file = parsed[1]>
		<cfset parsedLine = parsed[2]>

		<cfset output = getTranslationOutput(this.locale, file, parsedLine)>

		<!--- 3. If not found, try the locale without region (e.g., 'en-US' -> 'en'). --->
		<cfif is_null(output) AND Find("-", this.locale) GT 0>
			<cfset parsed = explode("-", this.locale, 2)>
			<cfset locale = parsed[1]>

			<cfset parsed = parseLine(arguments.line, locale)>
			<cfset file = parsed[1]>
			<cfset parsedLine = parsed[2]>

			<cfset output = getTranslationOutput(locale, file, parsedLine)>
		</cfif>

		<!--- 4. If still not found, try English. --->
		<cfif is_null(output)>
			<cfset parsed = parseLine(arguments.line, "en")>
			<cfset file = parsed[1]>
			<cfset parsedLine = parsed[2]>

			<cfset output = getTranslationOutput("en", file, parsedLine)>
		</cfif>

		<!--- 5. Fallback to the original line if no translation was found. --->
		<cfif is_null(output)>
			<cfset output = arguments.line>
		</cfif>

		<cfreturn formatMessage(output, arguments.args)>
	</cffunction>

	<!---
	 * @return A list or a map, a string, or an empty string (null)
	--->
	<cffunction name="getTranslationOutput" access="private" returntype="any" output="no">
		<cfargument name="locale" type="string" required="yes">
		<cfargument name="file" type="string" required="yes">
		<cfargument name="parsedLine" type="string" required="yes">
		<cfset var output = "">
		<cfset var current = "">
		<cfset var segments = "">
		<cfset var pair = "">
		<cfset var i = 0>

		<cfif array_key_exists(arguments.locale, this.language) AND array_key_exists(arguments.file, this.language[arguments.locale])
			AND array_key_exists(arguments.parsedLine, this.language[arguments.locale][arguments.file])>
			<cfset output = this.language[arguments.locale][arguments.file][arguments.parsedLine]>

			<cfif NOT is_null(output)>
				<cfreturn output>
			</cfif>
		</cfif>

		<!--- Fallback: try to traverse dot notation --->
		<cfif array_key_exists(arguments.locale, this.language) AND array_key_exists(arguments.file, this.language[arguments.locale])>
			<cfset current = this.language[arguments.locale][arguments.file]>
		</cfif>

		<cfif IsStruct(current)>
			<cfset segments = explode(".", arguments.parsedLine)>

			<cfloop from="1" to="#ArrayLen(segments)#" index="i">
				<cfif StructKeyExists(current, segments[i])>
					<cfset output = current[segments[i]]>
				<cfelse>
					<cfset output = "">
				</cfif>

				<cfif is_null(output)>
					<cfbreak>
				</cfif>

				<cfif is_array(output)>
					<cfset current = output>
				</cfif>
			</cfloop>

			<cfif NOT is_null(output)>
				<cfreturn output>
			</cfif>
		</cfif>

		<!--- Final fallback: try two-level access manually --->
		<cfset pair = explode(".", arguments.parsedLine, 2)>

		<cfif ArrayLen(pair) EQ 2 AND array_key_exists(arguments.locale, this.language) AND array_key_exists(arguments.file, this.language[arguments.locale])
			AND array_key_exists(pair[1], this.language[arguments.locale][arguments.file]) AND IsStruct(this.language[arguments.locale][arguments.file][pair[1]])
			AND array_key_exists(pair[2], this.language[arguments.locale][arguments.file][pair[1]])>
			<cfreturn this.language[arguments.locale][arguments.file][pair[1]][pair[2]]>
		</cfif>

		<cfreturn "">
	</cffunction>

	<!---
	 * Parses the language string which should include the
	 * filename as the first segment (separated by period).
	 *
	 * @return A list of two strings: the file and the line
	--->
	<cffunction name="parseLine" access="private" returntype="array" output="no">
		<cfargument name="line" type="string" required="yes">
		<cfargument name="locale" type="string" required="yes">
		<cfset var parts = explode(".", arguments.line, 2)>
		<cfset var file = parts[1]>
		<cfset var rest = parts[2]>

		<cfif NOT array_key_exists(arguments.locale, this.language)
			OR NOT array_key_exists(file, this.language[arguments.locale])
			OR NOT array_key_exists(rest, this.language[arguments.locale][file])>
			<cfset load(file, arguments.locale)>
		</cfif>

		<cfreturn parts>
	</cffunction>

	<!---
	 * Advanced message formatting.
	 *
	 * Difference: only {name} (a key of a map of arguments) and {0} (the
	 * position in a list of arguments, counted from zero) are replaced, in
	 * one pass, so a value that has braces in it is not replaced again. A
	 * brace that names no argument stays as it is. The quoting of ICU is not
	 * known: "'{0}'" stays as it is in the original and is replaced here.
	 *
	 * @param message A string, or a list of strings
	 * @param args    A map, a list, or an empty string for none
	 *
	 * @return A string, or a list of strings
	--->
	<cffunction name="formatMessage" access="private" returntype="any" output="no">
		<cfargument name="message" type="any" required="yes">
		<cfargument name="args" type="any" required="no" default="">
		<cfset var result = "">
		<cfset var matcher = "">
		<cfset var name = "">
		<cfset var buffer = "">
		<cfset var last = 0>
		<cfset var i = 0>
		<cfset var text = "">
		<cfset var count = "">

		<cfif NOT this.intlSupport OR NOT is_array(arguments.args) OR IsArray(arguments.args) AND ArrayLen(arguments.args) EQ 0 OR IsStruct(arguments.args) AND StructCount(arguments.args) EQ 0>
			<cfreturn arguments.message>
		</cfif>

		<cfif is_array(arguments.message)>
			<cfset result = ArrayNew(1)>

			<cfloop from="1" to="#ArrayLen(arguments.message)#" index="i">
				<cfset ArrayAppend(result, formatMessage(arguments.message[i], arguments.args))>
			</cfloop>

			<cfreturn result>
		</cfif>

		<cfset text = arguments.message>

		<!--- Difference: the plural form {n, plural, =1{# one} other{# many}} is resolved with the English rule (one for 1, else other), a # is the number --->
		<cfif REFind(", *plural *,", text) GT 0>
			<cfset matcher = CreateObject("java", "java.util.regex.Pattern").compile("\{([^{},]+), *plural, *=1\{([^{}]*)\} *other\{([^{}]*)\}\}").matcher(JavaCast("string", text))>
			<cfset buffer = CreateObject("java", "java.lang.StringBuffer").init()>

			<cfloop condition="matcher.find()">
				<cfset name = matcher.group(1)>
				<cfset buffer.append(Mid(text, last + 1, matcher.start() - last))>
				<cfset last = matcher.end()>
				<cfset count = "">

				<cfif IsStruct(arguments.args) AND StructKeyExists(arguments.args, name)>
					<cfset count = arguments.args[name]>
				<cfelseif IsArray(arguments.args) AND REFind("^(0|[1-9][0-9]*)$", name) GT 0 AND Val(name) LT ArrayLen(arguments.args)>
					<cfset count = arguments.args[Val(name) + 1]>
				</cfif>

				<!--- only a number is put in, any other value is left as written (and not read again by the {name} pass) --->
				<cfif Len(count) EQ 0 OR NOT IsNumeric(count)>
					<cfset buffer.append(matcher.group(0))>
				<cfelseif count EQ 1>
					<cfset buffer.append(JavaCast("string", Replace(matcher.group(2), Chr(35), count, "all")))>
				<cfelse>
					<cfset buffer.append(JavaCast("string", Replace(matcher.group(3), Chr(35), count, "all")))>
				</cfif>
			</cfloop>

			<cfset buffer.append(Mid(text, last + 1, Len(text) - last))>
			<cfset text = buffer.toString()>
			<cfset last = 0>
		</cfif>

		<!--- a position is written without a leading zero: ICU reads {01} as a name, not a position, so it is left as written (the original's behaviour is not checked here, as the intl extension is not at hand) --->
		<cfset matcher = CreateObject("java", "java.util.regex.Pattern").compile("\{([^{}]+)\}").matcher(JavaCast("string", text))>
		<cfset buffer = CreateObject("java", "java.lang.StringBuffer").init()>

		<cfloop condition="matcher.find()">
			<cfset name = matcher.group(1)>
			<cfset buffer.append(Mid(text, last + 1, matcher.start() - last))>
			<cfset last = matcher.end()>

			<cfif IsStruct(arguments.args) AND StructKeyExists(arguments.args, name)>
				<cfset buffer.append(JavaCast("string", strval(arguments.args[name])))>
			<cfelseif IsArray(arguments.args) AND REFind("^(0|[1-9][0-9]*)$", name) GT 0 AND Val(name) LT ArrayLen(arguments.args)>
				<cfset buffer.append(JavaCast("string", strval(arguments.args[Val(name) + 1])))>
			<cfelse>
				<cfset buffer.append(matcher.group(0))>
			</cfif>
		</cfloop>

		<cfset buffer.append(Mid(text, last + 1, Len(text) - last))>

		<cfreturn buffer.toString()>
	</cffunction>

	<!---
	 * Loads a language file in the current locale. If return is true,
	 * will return the file's contents, otherwise will merge with
	 * the existing language lines.
	 *
	 * @return The lines (a map) if return is true, otherwise an empty string (null)
	--->
	<cffunction name="load" access="private" returntype="any" output="no">
		<cfargument name="file" type="string" required="yes">
		<cfargument name="locale" type="string" required="yes">
		<cfargument name="return_" type="boolean" required="no" default="false">
		<cfset var path = "">
		<cfset var lang = "">

		<cfif NOT array_key_exists(arguments.locale, this.loadedFiles)>
			<cfset this.loadedFiles[arguments.locale] = ArrayNew(1)>
		</cfif>

		<cfif in_array(arguments.file, this.loadedFiles[arguments.locale])>
			<!--- Don't load it more than once. --->
			<cfreturn ArrayNew(1)>
		</cfif>

		<cfif NOT array_key_exists(arguments.locale, this.language)>
			<cfset this.language[arguments.locale] = CreateObject("java", "java.util.LinkedHashMap").init()>
		</cfif>

		<cfif NOT array_key_exists(arguments.file, this.language[arguments.locale])>
			<cfset this.language[arguments.locale][arguments.file] = CreateObject("java", "java.util.LinkedHashMap").init()>
		</cfif>

		<cfset path = "Language/" & arguments.locale & "/" & arguments.file & ".cfm">

		<cfset lang = requireFile(path)>

		<cfif arguments.return_>
			<cfreturn lang>
		</cfif>

		<cfset ArrayAppend(this.loadedFiles[arguments.locale], arguments.file)>

		<!--- Merge our string --->
		<cfset this.language[arguments.locale][arguments.file] = lang>

		<cfreturn "">
	</cffunction>

	<!---
	 * A simple method for including files that can be overridden during testing.
	 *
	 * Difference: the file is searched through the namespaces of the autoloader
	 * instead of service("locator").search(), and the file that is found is
	 * included by Language/Closure.cfc.
	 *
	 * @return The lines, a map
	--->
	<cffunction name="requireFile" access="private" returntype="any" output="no">
		<cfargument name="path" type="string" required="yes">
		<cfset var prefixes = request.ColdIgniter.autoloader.prefixes>
		<cfset var files = ArrayNew(1)>
		<cfset var strings = ArrayNew(1)>
		<cfset var loadedStrings = "">
		<cfset var prefix = "">
		<cfset var file = "">
		<cfset var base = "">
		<cfset var count = 0>
		<cfset var i = 0>
		<cfset var j = 0>

		<!--- Not ported yet: service("locator").search(path, extension, false) --->
		<cfloop collection="#prefixes#" item="prefix">
			<cfloop from="1" to="#ArrayLen(prefixes[prefix])#" index="i">
				<cfset file = prefixes[prefix][i] & Replace(arguments.path, "/", request.DIRECTORY_SEPARATOR, "all")>

				<cfif NOT in_array(file, files)>
					<cfset ArrayAppend(files, file)>
				</cfif>
			</cfloop>
		</cfloop>

		<cfloop from="1" to="#ArrayLen(files)#" index="i">
			<cfif is_file(files[i])>
				<cfset loadedStrings = new_("ColdIgniter\Language\Closure").call(files[i])>

				<cfif is_array(loadedStrings)>
					<cfset ArrayAppend(strings, loadedStrings)>
				</cfif>
			</cfif>
		</cfloop>

		<cfset count = ArrayLen(strings)>

		<cfif count GT 1>
			<cfset base = strings[1]>

			<cfloop from="2" to="#count#" index="j">
				<cfset base = array_replace_recursive(base, strings[j])>
			</cfloop>

			<cfset strings = base>
		<cfelseif count EQ 1>
			<cfset strings = strings[1]>
		<cfelse>
			<cfset strings = CreateObject("java", "java.util.LinkedHashMap").init()>
		</cfif>

		<cfreturn strings>
	</cffunction>

</cfcomponent>
