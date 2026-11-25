<!---
 * Checks if the class has been defined: the autoloader is asked
 * whether it can find the class file.
--->
<cffunction name="class_exists" returntype="boolean" output="no" hint="Checks if the class has been defined">
	<cfargument name="class" type="string" required="yes">

	<cfreturn request.ColdIgniter.autoloader.classExists(arguments.class)>
</cffunction>
