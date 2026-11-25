<!---
 * Inserts HTML line breaks before all newlines in a string.
--->
<cffunction name="nl2br" returntype="string" output="no" hint="Inserts HTML line breaks before all newlines in a string">
	<cfargument name="string" type="string" required="yes">

	<cfreturn REReplace(arguments.string, "(#Chr(13)##Chr(10)#|#Chr(10)#|#Chr(13)#)", "<br />\1", "all")>
</cffunction>
