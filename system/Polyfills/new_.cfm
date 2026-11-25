<!---
 * Creates an object: new_(class, argument, argument, ...).
 *
 * The class is found by the autoloader, and the arguments go to its
 * __construct() method, in order.
--->
<cffunction name="new_" returntype="any" output="no" hint="Creates an object: new_(class, argument, argument, ...)">
	<cfargument name="class" type="string" required="yes">
	<cfset var object = request.ColdIgniter.autoloader.instantiate(arguments.class)>
	<cfset var call = "">
	<cfset var i = 0>

	<cfif StructKeyExists(object, "__construct")>
		<cfloop from="2" to="#ArrayLen(arguments)#" index="i">
			<cfset call = ListAppend(call, "arguments[#i#]")>
		</cfloop>

		<cfset Evaluate("object.__construct(#call#)")>
	</cfif>

	<cfreturn object>
</cffunction>
