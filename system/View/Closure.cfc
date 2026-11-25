<!---
 * Not in the original, where the view file is included in a closure
 * inside View::render().
 *
 * One object is created for each render and thrown away after it.
 * The view data becomes the variables of that object, so a view reads
 * them by name, and the global functions can be called in a view.
--->
<cfcomponent output="no" hint="Includes one view file">

	<cffunction name="call" access="public" returntype="string" output="no">
		<cfargument name="__file" type="string" required="yes">
		<cfargument name="__data" type="any" required="yes">
		<cfset var __output = "">
		<cfset var __key = "">

		<!--- extract --->
		<cfloop collection="#arguments.__data#" item="__key">
			<cfset variables[__key] = arguments.__data[__key]>
		</cfloop>

		<cfsavecontent variable="__output"><cfsetting enablecfoutputonly="no"><cfinclude template="#includePath(arguments.__file)#"><cfsetting enablecfoutputonly="yes"></cfsavecontent>

		<cfreturn __output>
	</cffunction>

</cfcomponent>
