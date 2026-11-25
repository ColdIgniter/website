<!---
 * Class XMLFormatter
 *
 * Difference: there is no SimpleXMLElement, so the text is built here with
 * the same result as its asXML(): the line <?xml version="1.0"?>, the
 * root element, a line feed, no white space between elements and an
 * element without content as <name/>. The value of an element is escaped
 * as SimpleXML does after htmlspecialchars(): that function writes the
 * entities of & < > " ', and addChild() reads them back, so the text is
 * kept and only & < > (and a carriage return, as &#13;) are written as
 * entities, which is not what xml_convert() does. A character that XML
 * does not allow is not removed.
 *
 * Difference: arrayToXML() and normalizeXMLTag() are private, as there is no
 * protected access on 6.1; a subclass cannot call or override them.
 *
 * Difference: the options (formatterOptions, flags of libxml) are not used.
 * A list is the array of the original with the keys 0, 1, 2 ... and a map
 * (see array_()) with its keys; a value that is not an array counts as a
 * list of one, as the cast of the original does. A Boolean is 1 or an empty
 * string, as the cast of the original. A component is a Stringable when it
 * has the method __toString(), otherwise it is refused.
 *
 * Difference: a name is checked char by char, not by a regular expression
 * with ranges: a surrogate (a character of a plane above the first) is
 * accepted as a start and as a name character, and trim() is the Trim of
 * the engine.
--->
<cfcomponent output="no" extends="FormatterInterface" hint="Formats data as XML">

	<!---
	 * A name that is valid as it is: ASCII only and not "xml" at the start
	 * (any case). Compiled once for each instance.
	--->
	<cfset variables.validTag = CreateObject("java", "java.util.regex.Pattern").compile(JavaCast("string", "^(?![Xx][Mm][Ll])[A-Za-z_][A-Za-z0-9_.-]*$"))>

	<!---
	 * Takes the given data and formats it.
	 *
	 * @param data
	 *
	 * @return The XML text
	--->
	<cffunction name="format" access="public" returntype="any" output="no">
		<cfargument name="data" type="any" required="yes">
		<cfset var list = "">
		<cfset var body = "">

		<!--- Not ported yet: the check for the SimpleXML extension (always there) and the options of the original --->

		<cfif IsArray(arguments.data) OR (IsStruct(arguments.data) AND NOT IsObject(arguments.data))>
			<cfset body = arrayToXML(arguments.data)>
		<cfelse>
			<cfset list = ArrayNew(1)>
			<cfset ArrayAppend(list, arguments.data)>
			<cfset body = arrayToXML(list)>
		</cfif>

		<cfif body EQ "">
			<cfreturn "<?xml version=""1.0""?>" & Chr(10) & "<response/>" & Chr(10)>
		</cfif>

		<cfreturn "<?xml version=""1.0""?>" & Chr(10) & "<response>" & body & "</response>" & Chr(10)>
	</cffunction>

	<!---
	 * A recursive method to convert an array into a valid XML string:
	 * the children of one element.
	 *
	 * @param data A list or a map
	 *
	 * @return The XML text of the children
	--->
	<cffunction name="arrayToXML" access="private" returntype="string" output="no">
		<cfargument name="data" type="any" required="yes">
		<cfset var buf = CreateObject("java", "java.lang.StringBuffer").init()>
		<cfset var keys = ArrayNew(1)>
		<cfset var it = "">
		<cfset var n = 0>
		<cfset var i = 0>
		<cfset var key = "">
		<cfset var value = "">
		<cfset var inner = "">
		<cfset var text = "">

		<cfif IsArray(arguments.data)>
			<cfset n = ArrayLen(arguments.data)>
		<cfelse>
			<cfif arguments.data.getClass().getName() EQ "java.util.LinkedHashMap">
				<cfset it = arguments.data.keySet().iterator()>
				<cfloop condition="it.hasNext()">
					<cfset ArrayAppend(keys, it.next())>
				</cfloop>
			<cfelse>
				<cfset keys = StructKeyArray(arguments.data)>
			</cfif>
			<cfset n = ArrayLen(keys)>
		</cfif>

		<cfloop from="1" to="#n#" index="i">
			<cfif IsArray(arguments.data)>
				<!--- the key of a list item is its place, so the name is valid as it is --->
				<cfset key = "item" & (i - 1)>
				<cfset value = arguments.data[i]>
			<cfelse>
				<cfset key = normalizeXMLTag(keys[i])>
				<cfset value = arguments.data[keys[i]]>
			</cfif>

			<cfif IsArray(value) OR (IsStruct(value) AND NOT IsObject(value))>
				<cfset inner = arrayToXML(value)>
				<cfif inner EQ "">
					<cfset buf.append("<" & key & "/>")>
				<cfelse>
					<cfset buf.append("<" & key & ">" & inner & "</" & key & ">")>
				</cfif>
			<cfelse>
				<cfif IsObject(value)>
					<cfif instanceof_(value, "ColdIgniter\Database\NullValue")>
						<!--- the null marker of a map: a null is cast to an empty string --->
						<cfset text = "">
					<cfelse>
						<cfif NOT StructKeyExists(value, "__toString")>
							<cfset static_("ColdIgniter\Format\Exceptions\FormatException").forInvalidXMLValue(GetMetaData(value).name)>
						</cfif>
						<cfset text = value.__toString()>
					</cfif>
				<cfelseif value.getClass().getName() EQ "java.lang.Boolean">
					<cfif value.booleanValue()>
						<cfset text = "1">
					<cfelse>
						<cfset text = "">
					</cfif>
				<cfelse>
					<cfset text = value & "">
				</cfif>

				<cfif text EQ "">
					<cfset buf.append("<" & key & "/>")>
				<cfelse>
					<!--- htmlspecialchars() and the read back of addChild() leave & < > and the carriage return --->
					<cfset text = Replace(text, "&", "&amp;", "all")>
					<cfset text = Replace(text, "<", "&lt;", "all")>
					<cfset text = Replace(text, ">", "&gt;", "all")>
					<cfset text = Replace(text, Chr(13), "&##13;", "all")>
					<cfset buf.append("<" & key & ">" & text & "</" & key & ">")>
				</cfif>
			</cfif>
		</cfloop>

		<cfreturn buf.toString()>
	</cffunction>

	<!---
	 * Tag names have strict names, so we need to make sure they are valid.
	 * A character that is not allowed in a name is removed, a name that
	 * does not start with a letter or an underscore gets "item" in front,
	 * so does a name that starts with "xml", and an empty name is "item".
	 *
	 * @param key
	--->
	<cffunction name="normalizeXMLTag" access="private" returntype="string" output="no">
		<cfargument name="key" type="any" required="yes">
		<cfset var text = "">
		<cfset var buf = "">
		<cfset var n = 0>
		<cfset var i = 0>
		<cfset var c = 0>
		<cfset var start = false>
		<cfset var name = "">

		<!--- the usual name needs no work --->
		<cfif variables.validTag.matcher(JavaCast("string", arguments.key & "")).matches()>
			<cfreturn arguments.key & "">
		</cfif>

		<cfset text = Trim(arguments.key & "")>
		<cfset buf = CreateObject("java", "java.lang.StringBuffer").init()>
		<cfset n = Len(text)>

		<cfloop from="1" to="#n#" index="i">
			<cfset c = Asc(Mid(text, i, 1))>
			<!--- start characters: A-Z _ a-z and the ranges of the original --->
			<cfset start = (c GTE 65 AND c LTE 90) OR c EQ 95 OR (c GTE 97 AND c LTE 122) OR (c GTE 192 AND c LTE 214) OR (c GTE 216 AND c LTE 246) OR (c GTE 248 AND c LTE 767) OR (c GTE 880 AND c LTE 893) OR (c GTE 895 AND c LTE 8191) OR (c GTE 8204 AND c LTE 8205) OR (c GTE 8304 AND c LTE 8591) OR (c GTE 11264 AND c LTE 12271) OR (c GTE 12289 AND c LTE 55295) OR (c GTE 63744 AND c LTE 64975) OR (c GTE 65008 AND c LTE 65533) OR (c GTE 55296 AND c LTE 57343)>
			<cfif start OR c EQ 46 OR (c GTE 48 AND c LTE 57) OR c EQ 183 OR (c GTE 768 AND c LTE 879) OR (c GTE 8255 AND c LTE 8256) OR c EQ 45>
				<cfif buf.length() EQ 0 AND NOT start>
					<cfset buf.append("item")>
				</cfif>
				<cfset buf.append(Mid(text, i, 1))>
			</cfif>
		</cfloop>

		<cfset name = buf.toString()>

		<!--- XML is a reserved starting word --->
		<cfif Len(name) GTE 3 AND CompareNoCase(Left(name, 3), "xml") EQ 0>
			<cfset name = "item" & name>
		</cfif>

		<cfif name EQ "">
			<cfreturn "item">
		</cfif>

		<cfreturn name>
	</cffunction>

</cfcomponent>
