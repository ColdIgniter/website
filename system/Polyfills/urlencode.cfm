<!---
 * URL-encodes a string: every character except letters, digits and
 * - _ . becomes %XX (UTF-8 bytes), and a space is a plus sign.
--->
<cffunction name="urlencode" returntype="string" output="no" hint="URL-encodes a string">
	<cfargument name="string" type="string" required="yes">

	<cfreturn Replace(Replace(rawurlencode(arguments.string), "%20", "+", "all"), "~", "%7E", "all")>
</cffunction>
