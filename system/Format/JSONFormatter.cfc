<!---
 * Class JSONFormatter
 *
 * Difference: the platform has no JSON functions (see the json_encode
 * polyfill, which has no flags and escapes more than this needs), so the
 * text is built here, as json_encode() with the flags of the original
 * would. The type of a value comes from its Java class, as in the
 * polyfill: a Boolean gives true or false, a Double, Integer or Long gives
 * a number, a list (ArrayNew) gives a list, a map or struct gives an
 * object, or a list when its keys are 0, 1, 2 ... in order (as an array of
 * the original), and everything else gives a string. A null is an empty
 * string (see is_null()). The null marker (NullValue) inside a map gives
 * null, and any other component gives {}.
 *
 * Difference: of the flags only JSON_UNESCAPED_UNICODE (256),
 * JSON_UNESCAPED_SLASHES (64), JSON_PRETTY_PRINT (128) and
 * JSON_UNESCAPED_LINE_TERMINATORS (2048) are honoured, the others are
 * ignored. JSON_PARTIAL_OUTPUT_ON_ERROR is always on in the
 * original and changes nothing here, as an error is thrown for the two
 * kinds of error that can happen: a string that is not valid (a lone
 * surrogate stands in for malformed UTF-8) and a depth that is too deep.
 * The recursion error cannot happen, as there is no reference.
--->
<cfcomponent output="no" extends="FormatterInterface" hint="Formats data as JSON">

	<!---
	 * The patterns of the characters a string has to escape, one for each
	 * set of the flags 64, 256 and 2048, compiled when first needed.
	--->
	<cfset variables.patterns = StructNew()>

	<!---
	 * Takes the given data and formats it.
	 *
	 * @param data
	 *
	 * @return The JSON text
	--->
	<cffunction name="format" access="public" returntype="any" output="no">
		<cfargument name="data" type="any" required="yes">
		<cfset var cfg = new_("Config\Format")>
		<cfset var options = 320>
		<cfset var mask = "">
		<cfset var set = "">

		<!--- JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES --->
		<cfif array_key_exists("application/json", cfg.formatterOptions)>
			<cfset options = cfg.formatterOptions["application/json"]>
		</cfif>

		<cfif request.ENVIRONMENT NEQ "production">
			<cfset options = BitOr(options, 128)> <!--- JSON_PRETTY_PRINT --->
		</cfif>

		<!---
		 * The characters that need an escape or a look: the quote, the
		 * backslash and the control characters, the slash unless flag 64,
		 * and with flag 256 only the line terminators (unless flag 2048)
		 * and the surrogates, otherwise everything above ASCII.
		--->
		<cfset mask = "p" & BitAnd(options, 2368)>
		<cfif NOT StructKeyExists(variables.patterns, mask)>
			<cfset set = """\\\u0000-\u001f">
			<cfif BitAnd(options, 64) EQ 0>
				<cfset set = set & "/">
			</cfif>
			<cfif BitAnd(options, 256) NEQ 0>
				<cfif BitAnd(options, 2048) EQ 0>
					<cfset set = set & "\u2028\u2029">
				</cfif>
				<cfset set = set & "\ud800-\udfff">
			<cfelse>
				<cfset set = set & "\u0080-\uffff">
			</cfif>
			<cfset variables.patterns[mask] = CreateObject("java", "java.util.regex.Pattern").compile(JavaCast("string", "[" & set & "]"))>
		</cfif>

		<cfreturn encode(arguments.data, options, 1, cfg.jsonEncodeDepth, variables.patterns[mask])>
	</cffunction>

	<!---
	 * Encodes a value. The level is the depth of the value (1 for the
	 * top). The indent of a pretty print is four spaces per level. The
	 * pattern finds the characters of a string that need an escape.
	--->
	<cffunction name="encode" access="private" returntype="string" output="no">
		<cfargument name="value" type="any" required="yes">
		<cfargument name="options" type="numeric" required="yes">
		<cfargument name="level" type="numeric" required="yes">
		<cfargument name="depth" type="numeric" required="yes">
		<cfargument name="pattern" type="any" required="yes">
		<cfset var buf = "">
		<cfset var pretty = BitAnd(arguments.options, 128) NEQ 0>
		<cfset var cls = "">
		<cfset var keys = ArrayNew(1)>
		<cfset var it = "">
		<cfset var isList = true>
		<cfset var isMap = false>
		<cfset var n = 0>
		<cfset var i = 0>
		<cfset var sep = ",">
		<cfset var pad = "">
		<cfset var padEnd = "">
		<cfset var item = "">

		<cfif IsObject(arguments.value)>
			<!--- the null marker of a map --->
			<cfif instanceof_(arguments.value, "ColdIgniter\Database\NullValue")>
				<cfreturn "null">
			</cfif>
			<cfreturn "{}">
		</cfif>

		<cfif IsArray(arguments.value) OR IsStruct(arguments.value)>
			<cfif arguments.level GT arguments.depth>
				<cfset static_("ColdIgniter\Format\Exceptions\FormatException").forInvalidJSON("Maximum stack depth exceeded")>
			</cfif>

			<cfif IsArray(arguments.value)>
				<cfset n = ArrayLen(arguments.value)>
			<cfelse>
				<cfset isMap = true>
				<cfif arguments.value.getClass().getName() EQ "java.util.LinkedHashMap">
					<cfset it = arguments.value.keySet().iterator()>
					<cfloop condition="it.hasNext()">
						<cfset ArrayAppend(keys, it.next())>
					</cfloop>
				<cfelse>
					<cfset keys = StructKeyArray(arguments.value)>
				</cfif>
				<cfset n = ArrayLen(keys)>
				<!--- a map with the keys 0, 1, 2 ... in order is a list, as an array of the original --->
				<cfloop from="1" to="#n#" index="i">
					<cfif Compare(keys[i] & "", i - 1) NEQ 0>
						<cfset isList = false>
						<cfbreak>
					</cfif>
				</cfloop>
			</cfif>

			<cfif n EQ 0>
				<cfreturn "[]">
			</cfif>

			<cfif isMap AND isList>
				<cfset isMap = false>
			</cfif>

			<cfset buf = CreateObject("java", "java.lang.StringBuffer").init()>

			<cfif pretty>
				<cfset pad = Chr(10) & RepeatString("    ", arguments.level)>
				<cfset padEnd = Chr(10) & RepeatString("    ", arguments.level - 1)>
				<cfset sep = "," & pad>
			</cfif>

			<cfif isMap>
				<cfset buf.append("{")>
			<cfelse>
				<cfset buf.append("[")>
			</cfif>
			<cfset buf.append(pad)>

			<cfloop from="1" to="#n#" index="i">
				<cfif i GT 1>
					<cfset buf.append(sep)>
				</cfif>
				<cfif isMap>
					<cfset buf.append(quote(keys[i] & "", arguments.options, arguments.pattern))>
					<cfif pretty>
						<cfset buf.append(": ")>
					<cfelse>
						<cfset buf.append(":")>
					</cfif>
					<cfset item = arguments.value[keys[i]]>
				<cfelseif IsArray(arguments.value)>
					<cfset item = arguments.value[i]>
				<cfelse>
					<cfset item = arguments.value[keys[i]]>
				</cfif>
				<cfset buf.append(encode(item, arguments.options, arguments.level + 1, arguments.depth, arguments.pattern))>
			</cfloop>

			<cfset buf.append(padEnd)>
			<cfif isMap>
				<cfset buf.append("}")>
			<cfelse>
				<cfset buf.append("]")>
			</cfif>

			<cfreturn buf.toString()>
		</cfif>

		<cfset cls = arguments.value.getClass().getName()>

		<cfif cls EQ "java.lang.Boolean">
			<cfif arguments.value.booleanValue()>
				<cfreturn "true">
			</cfif>
			<cfreturn "false">
		</cfif>

		<cfif cls EQ "java.lang.Double" OR cls EQ "java.lang.Integer" OR cls EQ "java.lang.Long">
			<cfreturn Replace(arguments.value & "", ",", "", "all")>
		</cfif>

		<cfreturn quote(arguments.value & "", arguments.options, arguments.pattern)>
	</cffunction>

	<!---
	 * Quotes a string. The pattern finds the characters that need an escape
	 * or a look, so a string without one is quoted as it is, and the runs
	 * between those characters are appended in one piece.
	--->
	<cffunction name="quote" access="private" returntype="string" output="no">
		<cfargument name="text" type="string" required="yes">
		<cfargument name="options" type="numeric" required="yes">
		<cfargument name="pattern" type="any" required="yes">
		<cfset var matcher = arguments.pattern.matcher(JavaCast("string", arguments.text))>
		<cfset var buf = "">
		<cfset var last = 0>
		<cfset var at = 0>
		<cfset var ch = "">
		<cfset var c = 0>
		<cfset var next = 0>
		<cfset var hex = "">
		<cfset var more = true>
		<cfset var n = Len(arguments.text)>

		<cfif NOT matcher.find()>
			<cfreturn """" & arguments.text & """">
		</cfif>

		<cfset buf = CreateObject("java", "java.lang.StringBuffer").init()>
		<cfset buf.append("""")>

		<cfloop condition="more">
			<!--- at is the place (counted from 0) of the character that was found --->
			<cfset at = matcher.start()>
			<cfif at GT last>
				<cfset buf.append(Mid(arguments.text, last + 1, at - last))>
			</cfif>
			<cfset ch = Mid(arguments.text, at + 1, 1)>
			<cfset c = Asc(ch)>
			<cfset last = at + 1>

			<cfif ch EQ """">
				<cfset buf.append("\""")>
			<cfelseif ch EQ "\">
				<cfset buf.append("\\")>
			<cfelseif ch EQ "/">
				<cfset buf.append("\/")>
			<cfelseif c EQ 8>
				<cfset buf.append("\b")>
			<cfelseif c EQ 9>
				<cfset buf.append("\t")>
			<cfelseif c EQ 10>
				<cfset buf.append("\n")>
			<cfelseif c EQ 12>
				<cfset buf.append("\f")>
			<cfelseif c EQ 13>
				<cfset buf.append("\r")>
			<cfelseif c GTE 55296 AND c LTE 57343>
				<!--- a surrogate: only a high one followed by a low one is valid --->
				<cfif c GT 56319 OR at + 1 GTE n>
					<cfset static_("ColdIgniter\Format\Exceptions\FormatException").forInvalidJSON("Malformed UTF-8 characters, possibly incorrectly encoded")>
				</cfif>
				<cfset next = Asc(Mid(arguments.text, at + 2, 1))>
				<cfif next LT 56320 OR next GT 57343>
					<cfset static_("ColdIgniter\Format\Exceptions\FormatException").forInvalidJSON("Malformed UTF-8 characters, possibly incorrectly encoded")>
				</cfif>
				<cfif BitAnd(arguments.options, 256) NEQ 0>
					<cfset buf.append(ch & Mid(arguments.text, at + 2, 1))>
				<cfelse>
					<cfset buf.append("\u" & LCase(FormatBaseN(c, 16)) & "\u" & LCase(FormatBaseN(next, 16)))>
				</cfif>
				<cfset last = at + 2>
			<cfelse>
				<!--- a control character, or a character above ASCII that is to be escaped --->
				<cfset hex = LCase(FormatBaseN(c, 16))>
				<cfset buf.append("\u" & RepeatString("0", 4 - Len(hex)) & hex)>
			</cfif>

			<!--- look again from the place after the last character that was handled --->
			<cfset more = matcher.find(JavaCast("int", last))>
		</cfloop>

		<cfif last LT n>
			<cfset buf.append(Mid(arguments.text, last + 1, n - last))>
		</cfif>
		<cfset buf.append("""")>

		<cfreturn buf.toString()>
	</cffunction>

</cfcomponent>
