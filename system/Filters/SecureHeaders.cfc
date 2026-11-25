<!---
 * Add Common Security Headers
--->
<cfcomponent output="no" extends="FilterInterface" hint="Add Common Security Headers">

	<!---
	 * A map of the header and its value.
	--->
	<cfset this.headers = CreateObject("java", "java.util.LinkedHashMap").init()>
	<!--- https://owasp.org/www-project-secure-headers/#x-frame-options --->
	<cfset this.headers["X-Frame-Options"] = "SAMEORIGIN">
	<!--- https://owasp.org/www-project-secure-headers/#x-content-type-options --->
	<cfset this.headers["X-Content-Type-Options"] = "nosniff">
	<!--- https://docs.microsoft.com/en-us/previous-versions/windows/internet-explorer/ie-developer/compatibility/jj542450(v=vs.85)#the-noopen-directive --->
	<cfset this.headers["X-Download-Options"] = "noopen">
	<!--- https://owasp.org/www-project-secure-headers/#x-permitted-cross-domain-policies --->
	<cfset this.headers["X-Permitted-Cross-Domain-Policies"] = "none">
	<!--- https://owasp.org/www-project-secure-headers/#referrer-policy --->
	<cfset this.headers["Referrer-Policy"] = "same-origin">
	<!---
	 https://owasp.org/www-project-secure-headers/#x-xss-protection
	 If you do not need to support legacy browsers, it is recommended that you use
	 Content-Security-Policy without allowing unsafe-inline scripts instead.
	 X-XSS-Protection: 1; mode=block
	--->

	<!---
	 * We don't have anything to do here.
	 *
	 * @param arguments_ An empty string, or a list of strings
	--->
	<cffunction name="before" access="public" returntype="any" output="no">
		<cfargument name="request_" type="any" required="yes">
		<cfargument name="arguments_" type="any" required="no" default="">

		<cfreturn "">
	</cffunction>

	<!---
	 * Add security headers.
	 *
	 * @param arguments_ An empty string, or a list of strings
	--->
	<cffunction name="after" access="public" returntype="any" output="no">
		<cfargument name="request_" type="any" required="yes">
		<cfargument name="response" type="any" required="yes">
		<cfargument name="arguments_" type="any" required="no" default="">
		<cfset var header = "">

		<cfloop collection="#this.headers#" item="header">
			<cfset arguments.response.setHeader(header, this.headers[header])>
		</cfloop>

		<cfreturn arguments.response>
	</cffunction>

</cfcomponent>
