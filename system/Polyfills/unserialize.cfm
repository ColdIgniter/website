<!---
 * Finds how many characters of a text, from a place, hold a number of
 * bytes in UTF-8. Not in the original: the length of a string in serialized
 * text is in bytes.
 *
 * @param text  The serialized text
 * @param start The place of the first character, counted from 1
 * @param bytes The number of bytes to take
--->
<cffunction name="unserialize_chars_" returntype="numeric" output="no" hint="Finds how many characters hold a number of bytes">
	<cfargument name="text" type="string" required="yes">
	<cfargument name="start" type="numeric" required="yes">
	<cfargument name="bytes" type="numeric" required="yes">
	<cfset var rest = Mid(arguments.text, arguments.start, arguments.bytes)>
	<cfset var count = 0>
	<cfset var taken = 0>
	<cfset var code = 0>

	<!--- the text is short of ASCII only most of the time: a character is a byte --->
	<cfif Len(JavaCast("string", rest).replaceAll("[\u0000-\u007F]", "")) EQ 0>
		<cfreturn Len(rest)>
	</cfif>

	<cfloop condition="taken LT arguments.bytes AND arguments.start + count LTE Len(arguments.text)">
		<cfset code = Asc(Mid(arguments.text, arguments.start + count, 1))>

		<cfif code LT 128>
			<cfset taken = taken + 1>
		<cfelseif code LT 2048>
			<cfset taken = taken + 2>
		<cfelseif code GTE 55296 AND code LTE 56319>
			<!--- a high surrogate and the low one after it make four bytes --->
			<cfset taken = taken + 4>
			<cfset count = count + 1>
		<cfelse>
			<cfset taken = taken + 3>
		</cfif>

		<cfset count = count + 1>
	</cfloop>

	<cfif taken NEQ arguments.bytes>
		<cfthrow type="ColdIgniter.Exception" message="unserialize(): the length of a string does not fit its text.">
	</cfif>

	<cfreturn count>
</cffunction>

<!---
 * Reads the number that ends at a character from a place. Not in the
 * original. The reader is a struct with the text and the place (pos).
 * Moves the place past the end character.
--->
<cffunction name="unserialize_until_" returntype="string" output="no" hint="Reads up to a character">
	<cfargument name="reader" type="struct" required="yes">
	<cfargument name="end" type="string" required="yes">
	<cfset var found = Find(arguments.end, arguments.reader.text, arguments.reader.pos)>
	<cfset var result = "">

	<cfif found EQ 0>
		<cfthrow type="ColdIgniter.Exception" message="unserialize(): the text ends too early.">
	</cfif>

	<cfset result = Mid(arguments.reader.text, arguments.reader.pos, found - arguments.reader.pos)>
	<cfset arguments.reader.pos = found + 1>

	<cfreturn result>
</cffunction>

<!---
 * Reads one value, the place of the reader being on its type letter. Not
 * in the original.
--->
<cffunction name="unserialize_value_" returntype="any" output="no" hint="Reads one serialized value">
	<cfargument name="reader" type="struct" required="yes">
	<cfset var type = Mid(arguments.reader.text, arguments.reader.pos, 1)>
	<cfset var number = "">
	<cfset var chars = 0>
	<cfset var result = "">
	<cfset var key = "">
	<cfset var i = 0>
	<cfset var isList = true>

	<cfif Compare(type, "N") EQ 0>
		<cfset arguments.reader.pos = arguments.reader.pos + 2>

		<cfreturn "">
	</cfif>

	<cfif Compare(Mid(arguments.reader.text, arguments.reader.pos + 1, 1), ":") NEQ 0>
		<cfthrow type="ColdIgniter.Exception" message="unserialize(): the text is not serialized data.">
	</cfif>

	<cfset arguments.reader.pos = arguments.reader.pos + 2>

	<cfif Compare(type, "i") EQ 0 OR Compare(type, "d") EQ 0>
		<cfset number = unserialize_until_(arguments.reader, ";")>

		<cfreturn number>
	</cfif>

	<cfif Compare(type, "b") EQ 0>
		<cfset number = unserialize_until_(arguments.reader, ";")>

		<cfreturn JavaCast("boolean", Compare(number, "0") NEQ 0)>
	</cfif>

	<cfif Compare(type, "s") EQ 0>
		<cfset number = unserialize_until_(arguments.reader, ":")>

		<cfif REFind("^[0-9]+$", number) EQ 0 OR Compare(Mid(arguments.reader.text, arguments.reader.pos, 1), """") NEQ 0>
			<cfthrow type="ColdIgniter.Exception" message="unserialize(): a string is not written right.">
		</cfif>

		<cfset arguments.reader.pos = arguments.reader.pos + 1>
		<cfset chars = unserialize_chars_(arguments.reader.text, arguments.reader.pos, Val(number))>
		<cfset result = Mid(arguments.reader.text, arguments.reader.pos, chars)>
		<cfset arguments.reader.pos = arguments.reader.pos + chars>

		<cfif Compare(Mid(arguments.reader.text, arguments.reader.pos, 2), """;") NEQ 0>
			<cfthrow type="ColdIgniter.Exception" message="unserialize(): a string is not closed.">
		</cfif>

		<cfset arguments.reader.pos = arguments.reader.pos + 2>

		<cfreturn result>
	</cfif>

	<cfif Compare(type, "a") EQ 0>
		<cfset number = unserialize_until_(arguments.reader, ":")>

		<cfif REFind("^[0-9]+$", number) EQ 0 OR Compare(Mid(arguments.reader.text, arguments.reader.pos, 1), "{") NEQ 0>
			<cfthrow type="ColdIgniter.Exception" message="unserialize(): an array is not written right.">
		</cfif>

		<cfset arguments.reader.pos = arguments.reader.pos + 1>
		<cfset result = CreateObject("java", "java.util.LinkedHashMap").init()>

		<cfloop from="1" to="#Val(number)#" index="i">
			<cfset key = unserialize_value_(arguments.reader)>
			<cfset result[key] = unserialize_value_(arguments.reader)>

			<cfif Compare(key, i - 1) NEQ 0>
				<cfset isList = false>
			</cfif>
		</cfloop>

		<cfif Compare(Mid(arguments.reader.text, arguments.reader.pos, 1), "}") NEQ 0>
			<cfthrow type="ColdIgniter.Exception" message="unserialize(): an array is not closed.">
		</cfif>

		<cfset arguments.reader.pos = arguments.reader.pos + 1>

		<!--- the keys 0, 1, 2 in order are a list --->
		<cfif isList>
			<cfreturn unserialize_list_(result)>
		</cfif>

		<cfreturn result>
	</cfif>

	<cfthrow type="ColdIgniter.LogicException" message="Not ported yet: unserialize() of the type ""#type#"" (objects).">
</cffunction>

<!---
 * Turns a map with the keys 0, 1, 2 in order into a list. Not in the
 * original.
--->
<cffunction name="unserialize_list_" returntype="array" output="no" hint="Turns a map with the keys 0, 1, 2 into a list">
	<cfargument name="map" type="any" required="yes">
	<cfset var list = ArrayNew(1)>
	<cfset var i = 0>

	<cfloop from="0" to="#arguments.map.size() - 1#" index="i">
		<cfset ArrayAppend(list, arguments.map[i])>
	</cfloop>

	<cfreturn list>
</cffunction>

<!---
 * Creates a value from a stored representation, the format of serialize()
 * and of the original.
 *
 * Difference: the platform has no types, so an integer, a float and a
 * string come back as text; only b: gives a real boolean. A null (N;) is
 * an empty string. An array whose keys are 0, 1, 2 in order is a list, and
 * any other array is a map (see array_()). Text that is not serialized
 * data throws ColdIgniter.Exception, where the original gives false.
 *
 * Not ported yet: objects (O:, C:), references (R:, r:) and enums (E:); they
 * throw.
--->
<cffunction name="unserialize" returntype="any" output="no" hint="Creates a value from a stored representation">
	<cfargument name="data" type="string" required="yes">
	<cfset var reader = StructNew()>
	<cfset var result = "">

	<cfset reader.text = arguments.data>
	<cfset reader.pos = 1>
	<cfset result = unserialize_value_(reader)>

	<cfreturn result>
</cffunction>
