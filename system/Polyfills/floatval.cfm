<!---
 * Gets the float value of a numeric string.
 *
 * The caller has to check is_numeric() first. The text is read by the
 * Java double parser, so "1e5", ".5" and "1." work, and whitespace is
 * ignored. Val() is not used, because it does not read every form.
 *
 * Difference: only a numeric string is accepted. The original reads the
 * numeric prefix of any string.
--->
<cffunction name="floatval" returntype="numeric" output="no" hint="Gets the float value of a numeric string">
	<cfargument name="value" type="string" required="yes">
	<cfreturn CreateObject("java", "java.lang.Double").parseDouble(JavaCast("string", arguments.value).trim())>
</cffunction>
