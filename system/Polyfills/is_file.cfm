<!---
 * Tells whether the filename is a regular file.
--->
<cffunction name="is_file" returntype="boolean" output="no" hint="Tells whether the filename is a regular file">
	<cfargument name="filename" type="string" required="yes">

	<cfreturn CreateObject("java", "java.io.File").init(arguments.filename).isFile()>
</cffunction>
