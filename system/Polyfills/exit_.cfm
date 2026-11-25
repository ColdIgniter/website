<!---
 * Ends the request, like exit in the original.
 *
 * Difference: there is no way to stop a template from inside a function,
 * so an exception is thrown and Boot::bootWeb() catches it, and then the
 * output that is in place is sent.
--->
<cffunction name="exit_" returntype="void" output="no" hint="Ends the request">
	<cfthrow type="ColdIgniter.Exit" message="exit">
</cffunction>
