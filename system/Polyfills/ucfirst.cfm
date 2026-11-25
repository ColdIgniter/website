<!---
 * Makes the first character of a string upper case.
--->
<cffunction name="ucfirst" returntype="string" output="no" hint="Makes the first character of a string upper case">
	<cfargument name="string" type="string" required="yes">

	<cfif NOT Len(arguments.string)>
		<cfreturn "">
	</cfif>

	<cfreturn UCase(Left(arguments.string, 1)) & Right(arguments.string, Len(arguments.string) - 1)>
</cffunction>
