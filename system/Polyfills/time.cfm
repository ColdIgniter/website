<!---
 * Returns the current Unix timestamp, the seconds since 1970-01-01 UTC.
--->
<cffunction name="time" returntype="numeric" output="no" hint="Returns the current Unix timestamp">
	<cfreturn Int(CreateObject("java", "java.lang.System").currentTimeMillis() / 1000)>
</cffunction>
