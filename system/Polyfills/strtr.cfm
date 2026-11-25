<!---
 * Translates substrings with a map: the form strtr(string, pairs) of the
 * original. The string is scanned once, the longest key that matches wins,
 * and a replacement is never searched again.
 *
 * Make the map with array_(), so that the keys keep their case. An empty
 * key is ignored.
--->
<cffunction name="strtr" returntype="string" output="no" hint="Translates substrings with a map">
	<cfargument name="string" type="string" required="yes">
	<cfargument name="pairs" type="any" required="yes">
	<cfset var keys = ArrayNew(1)>
	<cfset var key = "">
	<cfset var result = "">
	<cfset var i = 0>
	<cfset var j = 0>
	<cfset var position = 1>
	<cfset var found = false>
	<cfset var swap = "">

	<cfloop collection="#arguments.pairs#" item="key">
		<cfif Len(key) GT 0>
			<cfset ArrayAppend(keys, key)>
		</cfif>
	</cfloop>

	<!--- Longest key first, so an insertion sort that keeps the rest in order --->
	<cfloop from="2" to="#ArrayLen(keys)#" index="i">
		<cfset j = i>
		<cfloop condition="j GT 1 AND Len(keys[j]) GT Len(keys[j - 1])">
			<cfset swap = keys[j]>
			<cfset keys[j] = keys[j - 1]>
			<cfset keys[j - 1] = swap>
			<cfset j = j - 1>
		</cfloop>
	</cfloop>

	<cfloop condition="position LTE Len(arguments.string)">
		<cfset found = false>

		<cfloop from="1" to="#ArrayLen(keys)#" index="i">
			<cfif Compare(Mid(arguments.string, position, Len(keys[i])), keys[i]) EQ 0>
				<cfset result = result & arguments.pairs[keys[i]]>
				<cfset position = position + Len(keys[i])>
				<cfset found = true>
				<cfbreak>
			</cfif>
		</cfloop>

		<cfif NOT found>
			<cfset result = result & Mid(arguments.string, position, 1)>
			<cfset position = position + 1>
		</cfif>
	</cfloop>

	<cfreturn result>
</cffunction>
