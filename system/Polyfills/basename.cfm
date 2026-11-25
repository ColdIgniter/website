<!---
 * Returns the trailing name component of a path.
 *
 * Both kinds of slash separate the parts, and trailing ones are ignored.
--->
<cffunction name="basename" returntype="string" output="no" hint="Returns the trailing name component of a path">
	<cfargument name="path" type="string" required="yes">
	<cfargument name="suffix" type="string" required="no" default="">
	<cfset var name = REReplace(arguments.path, "[\\/]+$", "")>
	<cfset var i = 0>

	<cfloop from="#Len(name)#" to="1" index="i" step="-1">
		<cfif ListFind("47,92", Asc(Mid(name, i, 1)))>
			<cfset name = Mid(name, i + 1, Len(name))>
			<cfbreak>
		</cfif>
	</cfloop>

	<cfif arguments.suffix NEQ "" AND Len(name) GT Len(arguments.suffix) AND Compare(Right(name, Len(arguments.suffix)), arguments.suffix) EQ 0>
		<cfset name = Left(name, Len(name) - Len(arguments.suffix))>
	</cfif>

	<cfreturn name>
</cffunction>
