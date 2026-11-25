<!---
 * Adds the pairs of one value to the query string, which is collected in
 * a string buffer. A map or a list becomes name[key]=value, nested as deep
 * as it goes. Shared with http_build_query().
 *
 * The pairs are not collected in a list: handing a list to a function
 * takes longer the more elements it has (measured on the server), so the
 * time grew much faster than the number of pairs.
--->
<cffunction name="http_build_query_add" returntype="void" output="no" hint="Adds the query pairs of one value to a string buffer">
	<cfargument name="parts" type="any" required="yes">
	<cfargument name="name" type="string" required="yes">
	<cfargument name="value" type="any" required="yes">
	<cfset var keys = "">
	<cfset var key = "">
	<cfset var i = 0>

	<cfif IsStruct(arguments.value)>
		<!--- the keys are read from a list: reading one position of keySet().toArray() takes longer the more keys there are --->
		<cfset keys = CreateObject("java", "java.util.ArrayList").init(arguments.value.keySet())>
		<cfloop from="0" to="#keys.size() - 1#" index="i">
			<cfset key = keys.get(JavaCast("int", i))>
			<cfset http_build_query_add(arguments.parts, arguments.name & "[" & key & "]", arguments.value[key])>
		</cfloop>
	<cfelseif IsArray(arguments.value)>
		<cfloop from="1" to="#ArrayLen(arguments.value)#" index="i">
			<cfset http_build_query_add(arguments.parts, arguments.name & "[" & (i - 1) & "]", arguments.value[i])>
		</cfloop>
	<cfelse>
		<cfif arguments.parts.length() GT 0>
			<cfset arguments.parts.append("&")>
		</cfif>
		<cfset arguments.parts.append(JavaCast("string", urlencode(arguments.name) & "=" & urlencode(arguments.value)))>
	</cfif>
</cffunction>

<!---
 * Generates a url-encoded query string from a map (see array_()).
 *
 * The keys and values are encoded as urlencode() does it, and the pairs
 * are joined with an ampersand. A boolean is not turned into 1 or 0 as in
 * the original: it is written as the text it has here.
 *
 * Difference: only the data argument is taken (no prefix, separator or
 * encoding type).
--->
<cffunction name="http_build_query" returntype="string" output="no" hint="Generates a url-encoded query string">
	<cfargument name="data" type="any" required="yes">
	<cfset var parts = CreateObject("java", "java.lang.StringBuffer").init()>
	<cfset var keys = CreateObject("java", "java.util.ArrayList").init(arguments.data.keySet())>
	<cfset var key = "">
	<cfset var i = 0>

	<cfloop from="0" to="#keys.size() - 1#" index="i">
		<cfset key = keys.get(JavaCast("int", i))>
		<cfset http_build_query_add(parts, key, arguments.data[key])>
	</cfloop>

	<cfreturn parts.toString()>
</cffunction>
