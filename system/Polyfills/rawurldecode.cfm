<!---
 * Decodes a string that was encoded as the RFC 3986 URL form: %XX
 * becomes the character. A plus stays a plus, which is the difference
 * from urldecode(). A percent sign that is not followed by two
 * hexadecimal digits is kept as it is (see parse_str_decode()).
--->
<cffunction name="rawurldecode" returntype="string" output="no" hint="Decodes URL-encoded strings according to RFC 3986">
	<cfargument name="string" type="string" required="yes">

	<cfreturn parse_str_decode(Replace(arguments.string, "+", "%2B", "all"))>
</cffunction>
