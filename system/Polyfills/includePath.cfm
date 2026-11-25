<!---
 * Turns a full path into the path cfinclude needs.
 *
 * cfinclude only takes a path relative to the file it is written in,
 * so a full path is reached by climbing to the top of the drive
 * (climbing further than the top is allowed). The file has to be on
 * the same drive as the caller.
 *
 * <cfinclude template="#includePath(file)#"> stands in for "require file".
--->
<cffunction name="includePath" returntype="string" output="no" hint="Turns a full path into the path cfinclude needs">
	<cfargument name="path" type="string" required="yes">

	<cfreturn RepeatString("../", 30) & REReplace(Replace(arguments.path, "\", "/", "all"), "^([A-Za-z]:)?/", "")>
</cffunction>
