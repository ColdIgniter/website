<!---
 * Static members: there are none on 6.1. Reach the class with
 * static_("ColdIgniter\Validation\DotArrayFilter") and call run().
 *
 * Difference: the filtered result is always a map with string keys, also
 * where the original array was a list, because a map of the original that
 * holds only some of the positions of a list has no other form here.
 *
 * Difference: the original splits the index with a regular expression
 * (a dot that does not follow a backslash, empty parts dropped). It is a
 * character loop here, with the same result.
--->
<cfcomponent output="no" hint="Filters an array with dot array syntax">

	<!---
	 * Creates a new array with only the elements specified in dot array syntax.
	 *
	 * @param indexes The dot array syntax pattern to use for filtering (a list of strings).
	 * @param array   The array to filter (a list or a map).
	 *
	 * @return The filtered array (a map).
	--->
	<cffunction name="run" access="public" returntype="any" output="no">
		<cfargument name="indexes" type="array" required="yes">
		<cfargument name="array" type="any" required="yes">

		<cfset var result = CreateObject("java", "java.util.LinkedHashMap").init()>
		<cfset var index = "">
		<cfset var segments = "">
		<cfset var filteredArray = "">
		<cfset var i = 0>
		<cfset var j = 0>

		<cfloop from="1" to="#ArrayLen(arguments.indexes)#" index="i">
			<cfset index = arguments.indexes[i]>
			<cfset segments = splitIndex(index)>

			<cfloop from="1" to="#ArrayLen(segments)#" index="j">
				<cfset segments[j] = Replace(segments[j], "\.", ".", "all")>
			</cfloop>

			<cfset filteredArray = filter(segments, arguments.array)>

			<cfif StructCount(filteredArray) NEQ 0>
				<cfset result = array_replace_recursive(result, filteredArray)>
			</cfif>
		</cfloop>

		<cfreturn result>
	</cffunction>

	<!---
	 * Splits an index at the dots that do not follow a backslash, and
	 * drops the empty parts.
	 *
	 * @param index string
	 *
	 * @return A list of strings.
	--->
	<cffunction name="splitIndex" access="private" returntype="array" output="no">
		<cfargument name="index" type="string" required="yes">

		<cfset var result = ArrayNew(1)>
		<cfset var current = "">
		<cfset var i = 0>
		<cfset var character = "">
		<cfset var previous = "">

		<cfloop from="1" to="#Len(arguments.index)#" index="i">
			<cfset character = Mid(arguments.index, i, 1)>
			<cfif i GT 1>
				<cfset previous = Mid(arguments.index, i - 1, 1)>
			<cfelse>
				<cfset previous = "">
			</cfif>

			<cfif Compare(character, ".") EQ 0 AND Compare(previous, "\") NEQ 0>
				<cfif Len(current) GT 0>
					<cfset ArrayAppend(result, current)>
				</cfif>
				<cfset current = "">
			<cfelse>
				<cfset current = current & character>
			</cfif>
		</cfloop>

		<cfif Len(current) GT 0>
			<cfset ArrayAppend(result, current)>
		</cfif>

		<cfreturn result>
	</cffunction>

	<!---
	 * Used by run() to recursively filter the array with wildcards.
	 *
	 * @param indexes The dot array syntax pattern to use for filtering (a list of strings).
	 * @param array   The array to filter (a list or a map).
	 *
	 * @return The filtered array (a map).
	--->
	<cffunction name="filter" access="private" returntype="any" output="no">
		<cfargument name="indexes" type="array" required="yes">
		<cfargument name="array" type="any" required="yes">

		<cfset var result = CreateObject("java", "java.util.LinkedHashMap").init()>
		<cfset var currentIndex = "">
		<cfset var rest = ArrayNew(1)>
		<cfset var filtered = "">
		<cfset var key = "">
		<cfset var value = "">
		<cfset var i = 0>

		<!--- If there are no indexes left, return an empty array --->
		<cfif ArrayLen(arguments.indexes) EQ 0>
			<cfreturn result>
		</cfif>

		<!--- Get the current index (array_shift) --->
		<cfset currentIndex = arguments.indexes[1]>
		<cfloop from="2" to="#ArrayLen(arguments.indexes)#" index="i">
			<cfset ArrayAppend(rest, arguments.indexes[i])>
		</cfloop>

		<!---
		 * If the current index doesn't exist and is not a wildcard, return an empty array.
		 * Use array_key_exists() so explicit null values are preserved.
		--->
		<cfif Compare(currentIndex, "*") NEQ 0 AND NOT array_key_exists(currentIndex, arguments.array)>
			<cfreturn result>
		</cfif>

		<!--- Handle the wildcard '*' at the current level --->
		<cfif Compare(currentIndex, "*") EQ 0>
			<!--- Iterate over all keys at this level --->
			<cfif IsArray(arguments.array)>
				<cfloop from="1" to="#ArrayLen(arguments.array)#" index="i">
					<cfset key = ToString(i - 1)>
					<cfset value = arguments.array[i]>
					<cfif ArrayLen(rest) EQ 0>
						<!--- If no indexes are left, capture the entire value --->
						<cfset result[key] = value>
					<cfelseif is_array(value)>
						<!--- If there are still indexes left, continue filtering recursively --->
						<cfset filtered = filter(rest, value)>
						<cfif StructCount(filtered) NEQ 0>
							<cfset result[key] = filtered>
						</cfif>
					</cfif>
				</cfloop>
			<cfelse>
				<cfloop collection="#arguments.array#" item="key">
					<cfset value = arguments.array[key]>
					<cfif ArrayLen(rest) EQ 0>
						<cfset result[key] = value>
					<cfelseif is_array(value)>
						<cfset filtered = filter(rest, value)>
						<cfif StructCount(filtered) NEQ 0>
							<cfset result[key] = filtered>
						</cfif>
					</cfif>
				</cfloop>
			</cfif>

			<cfreturn result>
		</cfif>

		<cfif IsArray(arguments.array)>
			<cfset value = arguments.array[Val(currentIndex) + 1]>
		<cfelse>
			<cfset value = arguments.array[currentIndex]>
		</cfif>

		<!--- If this is the last index, return the value as-is, including null. --->
		<cfif ArrayLen(rest) EQ 0>
			<cfset result[currentIndex] = value>
			<cfreturn result>
		</cfif>

		<!--- If the current value is an array, recursively filter it --->
		<cfif is_array(value)>
			<cfset filtered = filter(rest, value)>

			<cfif StructCount(filtered) NEQ 0>
				<cfset result[currentIndex] = filtered>
				<cfreturn result>
			</cfif>
		</cfif>

		<cfreturn CreateObject("java", "java.util.LinkedHashMap").init()>
	</cffunction>

</cfcomponent>
