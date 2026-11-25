<!---
 * Not in the original. Runs one file of functions for require_once().
 *
 * The file is run in an object of its own (see __require() in
 * Functions.cfc). This object starts empty, so that creating it does
 * not include the global functions a second time.
--->
<cfcomponent output="no" hint="Runs one file of functions">

	<cffunction name="__include" access="public" returntype="void" output="no">
		<cfargument name="file" type="string" required="yes">

		<cfinclude template="#includePath(arguments.file)#">
	</cffunction>

	<!---
	 * Returns the Variables scope of this object.
	--->
	<cffunction name="__variables" access="public" returntype="struct" output="no">
		<cfreturn variables>
	</cffunction>

</cfcomponent>
