<!---
 * Expected behavior of a Security class.
 *
 * There are no interfaces on 6.1, so this is a base component. Security
 * extends it (extends="SecurityInterface"), and the methods here only throw;
 * a class that extends it has to define them.
--->
<cfcomponent output="no" hint="Expected behavior of a Security class">

	<!---
	 * CSRF Verify
	 *
	 * @param request_ The request
	 *
	 * @return $this
	 *
	 * @throws SecurityException when the token is missing or wrong
	--->
	<cffunction name="verify" access="public" returntype="any" output="no">
		<cfargument name="request_" type="any" required="yes">

		<cfthrow type="ColdIgniter.LogicException" message="The class does not define verify().">
	</cffunction>

	<!---
	 * Returns the CSRF Hash, or an empty string (null).
	--->
	<cffunction name="getHash" access="public" returntype="any" output="no">

		<cfthrow type="ColdIgniter.LogicException" message="The class does not define getHash().">
	</cffunction>

	<!---
	 * Returns the CSRF Token Name.
	--->
	<cffunction name="getTokenName" access="public" returntype="string" output="no">

		<cfthrow type="ColdIgniter.LogicException" message="The class does not define getTokenName().">
	</cffunction>

	<!---
	 * Returns the CSRF Header Name.
	--->
	<cffunction name="getHeaderName" access="public" returntype="string" output="no">

		<cfthrow type="ColdIgniter.LogicException" message="The class does not define getHeaderName().">
	</cffunction>

	<!---
	 * Returns the CSRF Cookie Name.
	--->
	<cffunction name="getCookieName" access="public" returntype="string" output="no">

		<cfthrow type="ColdIgniter.LogicException" message="The class does not define getCookieName().">
	</cffunction>

	<!---
	 * Check if request should be redirect on failure.
	--->
	<cffunction name="shouldRedirect" access="public" returntype="boolean" output="no">

		<cfthrow type="ColdIgniter.LogicException" message="The class does not define shouldRedirect().">
	</cffunction>

	<!---
	 * Sanitize Filename
	 *
	 * Tries to sanitize filenames in order to prevent directory traversal attempts
	 * and other security threats, which is particularly useful for files that
	 * were supplied via user input.
	 *
	 * @param str          Input file name
	 * @param relativePath Whether to preserve paths
	--->
	<cffunction name="sanitizeFilename" access="public" returntype="string" output="no">
		<cfargument name="str" type="string" required="yes">
		<cfargument name="relativePath" type="boolean" required="no" default="false">

		<cfthrow type="ColdIgniter.LogicException" message="The class does not define sanitizeFilename().">
	</cffunction>

</cfcomponent>
