<!---
 * @internal This is internal implementation for the framework.
 *
 * If there are any methods that should be provided, make them
 * public APIs via helper functions.
 *
 * Not ported yet: groupBy, recursiveDiff, recursiveCount and
 * sortValuesByNatural.
--->
<cfcomponent output="no" hint="Internal implementation of the array helper">

	<!---
	 * Searches an array through dot syntax. Supports wildcard searches,
	 * like `foo.*.bar`.
	 *
	 * @used-by dot_array_search()
	 *
	 * @param index The index as dot array syntax.
	 * @param array
	 *
	 * @return The value, or an empty string (null) if there is none
	--->
	<cffunction name="dotSearch" access="public" returntype="any" output="no">
		<cfargument name="index" type="string" required="yes">
		<cfargument name="array" type="any" required="yes">

		<cfreturn arraySearchDot(convertToArray(arguments.index), arguments.array)>
	</cffunction>

	<!---
	 * array_key_exists() with dot array syntax.
	 *
	 * If wildcard `*` is used, all items for the key after it must have the key.
	 *
	 * Difference: where the original would stop with a type error because a
	 * value is not an array, this returns false. As in the original, an index
	 * segment that is "0" ends the check (it is false in a loop condition), so
	 * the rest of the path is not looked at.
	 *
	 * @param index
	 * @param array
	--->
	<cffunction name="dotKeyExists" access="public" returntype="boolean" output="no">
		<cfargument name="index" type="string" required="yes">
		<cfargument name="array" type="any" required="yes">
		<cfset var indexes = "">
		<cfset var currentArray = arguments.array>
		<cfset var currentIndex = "">
		<cfset var key = "">
		<cfset var i = 0>

		<cfif Right(arguments.index, 1) EQ "*" OR Find("*.*", arguments.index) GT 0>
			<cfthrow type="ColdIgniter.Exceptions.InvalidArgumentException" message="You must set key right after ""*"". Invalid index: ""#arguments.index#""">
		</cfif>

		<cfset indexes = convertToArray(arguments.index)>

		<!--- If indexes is empty, returns false. --->
		<cfif ArrayLen(indexes) EQ 0>
			<cfreturn false>
		</cfif>

		<!--- Grab the current index --->
		<cfloop condition="ArrayLen(indexes) GT 0">
			<cfset currentIndex = indexes[1]>
			<cfset ArrayDeleteAt(indexes, 1)>

			<!--- "while ($currentIndex = array_shift($indexes))" ends on an empty string and on "0". --->
			<cfif currentIndex EQ "" OR Compare(currentIndex, "0") EQ 0>
				<cfbreak>
			</cfif>

			<cfif Compare(currentIndex, "*") EQ 0>
				<!--- "array_shift" gives null when nothing follows the star (an index like "a.*."), and null is the key "" --->
				<cfif ArrayLen(indexes) EQ 0>
					<cfset currentIndex = "">
				<cfelse>
					<cfset currentIndex = indexes[1]>
					<cfset ArrayDeleteAt(indexes, 1)>
				</cfif>

				<cfif IsArray(currentArray)>
					<cfloop from="1" to="#ArrayLen(currentArray)#" index="i">
						<cfif NOT is_array(currentArray[i]) OR NOT array_key_exists(currentIndex, currentArray[i])>
							<cfreturn false>
						</cfif>
					</cfloop>
				<cfelse>
					<cfloop collection="#currentArray#" item="key">
						<cfif NOT is_array(currentArray[key]) OR NOT array_key_exists(currentIndex, currentArray[key])>
							<cfreturn false>
						</cfif>
					</cfloop>
				</cfif>

				<!--- If indexes is empty, all elements are checked. --->
				<cfif ArrayLen(indexes) EQ 0>
					<cfreturn true>
				</cfif>

				<cfset currentArray = dotSearch("*." & currentIndex, currentArray)>
			<cfelse>
				<cfif NOT is_array(currentArray) OR NOT array_key_exists(currentIndex, currentArray)>
					<cfreturn false>
				</cfif>

				<cfif IsArray(currentArray)>
					<cfset currentArray = currentArray[Val(currentIndex) + 1]>
				<cfelse>
					<cfset currentArray = currentArray[currentIndex]>
				</cfif>
			</cfif>
		</cfloop>

		<cfreturn true>
	</cffunction>

	<!---
	 * @param index The index as dot array syntax.
	 *
	 * @return The index as an array.
	--->
	<cffunction name="convertToArray" access="private" returntype="array" output="no">
		<cfargument name="index" type="string" required="yes">
		<cfset var segments = ArrayNew(1)>
		<cfset var text = rtrim_(arguments.index, "* ")>
		<!--- A dot that is not preceded by a backslash (lookbehind needs the Java engine). --->
		<cfset var matcher = CreateObject("java", "java.util.regex.Pattern").compile("(?<!\\)\.").matcher(text)>
		<cfset var start = 0>
		<cfset var segment = "">

		<cfloop condition="matcher.find()">
			<cfset segment = Mid(text, start + 1, matcher.start() - start)>
			<cfif segment NEQ "">
				<cfset ArrayAppend(segments, Replace(segment, "\.", ".", "all"))>
			</cfif>
			<cfset start = matcher.end()>
		</cfloop>

		<cfset segment = Mid(text, start + 1, Len(text) - start)>
		<cfif segment NEQ "">
			<cfset ArrayAppend(segments, Replace(segment, "\.", ".", "all"))>
		</cfif>

		<cfreturn segments>
	</cffunction>

	<!---
	 * Recursively search the array with wildcards.
	 *
	 * @used-by dotSearch()
	 *
	 * @param indexes
	 * @param array
	 *
	 * @return The value, or an empty string (null) if there is none
	--->
	<cffunction name="arraySearchDot" access="private" returntype="any" output="no">
		<cfargument name="indexes" type="array" required="yes">
		<cfargument name="array" type="any" required="yes">
		<cfset var rest = ArrayNew(1)>
		<cfset var currentIndex = "">
		<cfset var answer = ArrayNew(1)>
		<cfset var values = ArrayNew(1)>
		<cfset var result = "">
		<cfset var key = "">
		<cfset var i = 0>

		<!--- If index is empty, returns null. --->
		<cfif ArrayLen(arguments.indexes) EQ 0>
			<cfreturn "">
		</cfif>

		<!--- Grab the current index --->
		<cfset currentIndex = arguments.indexes[1]>

		<cfloop from="2" to="#ArrayLen(arguments.indexes)#" index="i">
			<cfset ArrayAppend(rest, arguments.indexes[i])>
		</cfloop>

		<cfif NOT array_key_exists(currentIndex, arguments.array) AND Compare(currentIndex, "*") NEQ 0>
			<cfreturn "">
		</cfif>

		<!--- Handle Wildcard (*) --->
		<cfif Compare(currentIndex, "*") EQ 0>
			<cfif IsArray(arguments.array)>
				<cfset values = arguments.array>
			<cfelse>
				<cfloop collection="#arguments.array#" item="key">
					<cfset ArrayAppend(values, arguments.array[key])>
				</cfloop>
			</cfif>

			<cfloop from="1" to="#ArrayLen(values)#" index="i">
				<cfif NOT is_array(values[i])>
					<cfreturn "">
				</cfif>

				<cfset result = arraySearchDot(rest, values[i])>
				<cfif NOT is_null(result)>
					<cfset ArrayAppend(answer, result)>
				</cfif>
			</cfloop>

			<cfif ArrayLen(answer) GT 0>
				<!--- If array only has one element, we return that element for BC. --->
				<cfif ArrayLen(answer) EQ 1>
					<cfreturn answer[1]>
				</cfif>

				<cfreturn answer>
			</cfif>

			<cfreturn "">
		</cfif>

		<cfif IsArray(arguments.array)>
			<cfset result = arguments.array[Val(currentIndex) + 1]>
		<cfelse>
			<cfset result = arguments.array[currentIndex]>
		</cfif>

		<!--- If this is the last index, make sure to return it now, and not try to recurse through things. --->
		<cfif ArrayLen(rest) EQ 0>
			<cfreturn result>
		</cfif>

		<!--- Do we need to recursively search this value? --->
		<cfif is_array(result)>
			<cfif IsArray(result) AND ArrayLen(result) GT 0 OR IsStruct(result) AND StructCount(result) GT 0>
				<cfreturn arraySearchDot(rest, result)>
			</cfif>
		</cfif>

		<!--- Otherwise, not found. --->
		<cfreturn "">
	</cffunction>

</cfcomponent>
