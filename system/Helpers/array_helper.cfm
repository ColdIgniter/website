<!---
 * ColdIgniter Array Helpers
 *
 * Not ported yet: every other function of the original helper.
 *
 * A function here has no guard against a second definition (the original
 * checks function_exists): helper() keeps the first definition of a name.
 *
 * Where the original returns null, these functions return an empty
 * string, because null and an empty string cannot be told apart.
--->

<!---
 * Searches an array through dot syntax. Supports
 * wildcard searches, like foo.*.bar
 *
 * @param index
 * @param array A list or a map (see array_())
--->
<cffunction name="dot_array_search" returntype="any" output="no" hint="Searches an array through dot syntax">
	<cfargument name="index" type="string" required="yes">
	<cfargument name="array" type="any" required="yes">

	<cfreturn static_("ColdIgniter\Helpers\Array\ArrayHelper").dotSearch(arguments.index, arguments.array)>
</cffunction>

<!---
 * Flatten a multidimensional array using dots as separators.
 *
 * The keys of a list are its positions, counted from zero. The result
 * is a map (see array_()).
 *
 * @param array The multi-dimensional array
 * @param id    Something to initially prepend to the flattened keys
 *
 * @return The flattened array
--->
<cffunction name="array_flatten_with_dots" returntype="any" output="no" hint="Flatten a multidimensional array using dots as separators">
	<cfargument name="array" type="any" required="yes">
	<cfargument name="id" type="string" required="no" default="">
	<cfset var flattened = array_()>
	<cfset var inner = "">
	<cfset var value = "">
	<cfset var newKey = "">
	<cfset var key = "">
	<cfset var i = 0>
	<cfset var k = 0>

	<cfif IsArray(arguments.array)>
		<cfloop from="1" to="#ArrayLen(arguments.array)#" index="i">
			<cfset value = arguments.array[i]>
			<cfset newKey = arguments.id & (i - 1)>

			<cfif IsArray(value) AND ArrayLen(value) GT 0 OR IsStruct(value) AND StructCount(value) GT 0>
				<cfset inner = array_flatten_with_dots(value, newKey & ".")>

				<cfloop collection="#inner#" item="key">
					<cfset flattened[key] = inner[key]>
				</cfloop>
			<cfelse>
				<cfset flattened[newKey] = value>
			</cfif>
		</cfloop>
	<cfelse>
		<cfloop collection="#arguments.array#" item="key">
			<cfset value = arguments.array[key]>
			<cfset newKey = arguments.id & key>

			<cfif IsArray(value) AND ArrayLen(value) GT 0 OR IsStruct(value) AND StructCount(value) GT 0>
				<cfset inner = array_flatten_with_dots(value, newKey & ".")>

				<cfloop collection="#inner#" item="k">
					<cfset flattened[k] = inner[k]>
				</cfloop>
			<cfelse>
				<cfset flattened[newKey] = value>
			</cfif>
		</cfloop>
	</cfif>

	<cfreturn flattened>
</cffunction>
