<!---
 * Not in the original, where "require $file" returns the array of
 * a language file.
 *
 * One object is created for each file and thrown away after it. The
 * file is included in it, and has to set the variable "lines" (see
 * Language/en/Validation.cfm). The global functions can be called in
 * the file.
--->
<cfcomponent output="no" hint="Includes one language file">

	<cffunction name="call" access="public" returntype="any" output="no">
		<cfargument name="__file" type="string" required="yes">

		<cfinclude template="#includePath(arguments.__file)#">

		<cfif NOT StructKeyExists(variables, "lines")>
			<cfreturn ArrayNew(1)>
		</cfif>

		<cfreturn variables.lines>
	</cffunction>

</cfcomponent>
