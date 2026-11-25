<!---
 * Returns the JSON representation of a value.
 *
 * Difference: the platform has no JSON functions and no null, and a literal
 * is always a string, so the type of a value is taken from its Java class:
 * a Boolean gives true or false, a Double, Integer or Long gives a number
 * and everything else gives a string. A map or struct gives an object (a
 * LinkedHashMap keeps the order of the keys) and an array gives a list.
 * Slashes are escaped, and so are the characters that could close a script
 * element, so the result is safe inside one.
 *
 * Not ported yet: the flags and the depth argument.
--->
<cffunction name="json_encode" returntype="string" output="no" hint="Returns the JSON representation of a value">
	<cfargument name="value" type="any" required="yes">
	<cfset var buf = CreateObject("java", "java.lang.StringBuffer").init()>
	<cfset var cls = "">
	<cfset var keys = "">
	<cfset var it = "">
	<cfset var key = "">
	<cfset var i = 0>
	<cfset var n = 0>
	<cfset var c = 0>
	<cfset var ch = "">
	<cfset var text = "">
	<cfset var hex = "">

	<cfif IsArray(arguments.value)>
		<cfset n = ArrayLen(arguments.value)>
		<cfset buf.append("[")>
		<cfloop from="1" to="#n#" index="i">
			<cfif i GT 1>
				<cfset buf.append(",")>
			</cfif>
			<cfset buf.append(json_encode(arguments.value[i]))>
		</cfloop>
		<cfset buf.append("]")>
		<cfreturn buf.toString()>
	</cfif>

	<cfif IsStruct(arguments.value)>
		<cfset buf.append("{")>
		<cfset i = 0>
		<cfif arguments.value.getClass().getName() EQ "java.util.LinkedHashMap">
			<cfset it = arguments.value.keySet().iterator()>
			<cfloop condition="it.hasNext()">
				<cfset key = it.next()>
				<cfif i GT 0>
					<cfset buf.append(",")>
				</cfif>
				<cfset buf.append(json_encode(key & "") & ":" & json_encode(arguments.value.get(key)))>
				<cfset i = i + 1>
			</cfloop>
		<cfelse>
			<cfset keys = StructKeyArray(arguments.value)>
			<cfloop from="1" to="#ArrayLen(keys)#" index="n">
				<cfif i GT 0>
					<cfset buf.append(",")>
				</cfif>
				<cfset buf.append(json_encode(keys[n]) & ":" & json_encode(arguments.value[keys[n]]))>
				<cfset i = i + 1>
			</cfloop>
		</cfif>
		<cfset buf.append("}")>
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

	<!--- a string --->
	<cfset text = arguments.value & "">
	<cfset buf.append("""")>
	<cfset n = Len(text)>
	<cfloop from="1" to="#n#" index="i">
		<cfset ch = Mid(text, i, 1)>
		<cfset c = Asc(ch)>
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
		<cfelseif c LT 32 OR c GT 126 OR ch EQ "<" OR ch EQ ">" OR ch EQ "&" OR ch EQ "'">
			<cfset hex = UCase(FormatBaseN(c, 16))>
			<cfset buf.append("\u" & RepeatString("0", 4 - Len(hex)) & hex)>
		<cfelse>
			<cfset buf.append(ch)>
		</cfif>
	</cfloop>
	<cfset buf.append("""")>

	<cfreturn buf.toString()>
</cffunction>
