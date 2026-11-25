<!---
 * Interface for a fresh Cookie instance with selected attribute(s)
 * only changed from the original instance.
 *
 * There are no interfaces on 6.1, so this is a base component that extends
 * the base component CookieInterface; Cookie extends it. The methods here
 * only throw; a cookie has to define them.
--->
<cfcomponent output="no" extends="CookieInterface" hint="Interface for a fresh Cookie instance with selected attribute(s) only changed">

	<!---
	 * Creates a new Cookie with a new cookie prefix.
	--->
	<cffunction name="withPrefix" access="public" returntype="any" output="no">
		<cfargument name="prefix" type="string" required="no" default="">

		<cfthrow type="ColdIgniter.Cookie.Exceptions.CookieException" errorcode="500" message="The cookie does not define withPrefix().">
	</cffunction>

	<!---
	 * Creates a new Cookie with a new name.
	--->
	<cffunction name="withName" access="public" returntype="any" output="no">
		<cfargument name="name" type="string" required="yes">

		<cfthrow type="ColdIgniter.Cookie.Exceptions.CookieException" errorcode="500" message="The cookie does not define withName().">
	</cffunction>

	<!---
	 * Creates a new Cookie with new value.
	--->
	<cffunction name="withValue" access="public" returntype="any" output="no">
		<cfargument name="value" type="string" required="yes">

		<cfthrow type="ColdIgniter.Cookie.Exceptions.CookieException" errorcode="500" message="The cookie does not define withValue().">
	</cffunction>

	<!---
	 * Creates a new Cookie with a new cookie expires time.
	 *
	 * @param expires A Unix timestamp, or a string of digits
	--->
	<cffunction name="withExpires" access="public" returntype="any" output="no">
		<cfargument name="expires" type="any" required="yes">

		<cfthrow type="ColdIgniter.Cookie.Exceptions.CookieException" errorcode="500" message="The cookie does not define withExpires().">
	</cffunction>

	<!---
	 * Creates a new Cookie that will expire the cookie from the browser.
	--->
	<cffunction name="withExpired" access="public" returntype="any" output="no">

		<cfthrow type="ColdIgniter.Cookie.Exceptions.CookieException" errorcode="500" message="The cookie does not define withExpired().">
	</cffunction>

	<!---
	 * Creates a new Cookie with a new path on the server the cookie is available.
	--->
	<cffunction name="withPath" access="public" returntype="any" output="no">
		<cfargument name="path" type="string" required="no" default="">

		<cfthrow type="ColdIgniter.Cookie.Exceptions.CookieException" errorcode="500" message="The cookie does not define withPath().">
	</cffunction>

	<!---
	 * Creates a new Cookie with a new domain the cookie is available.
	--->
	<cffunction name="withDomain" access="public" returntype="any" output="no">
		<cfargument name="domain" type="string" required="no" default="">

		<cfthrow type="ColdIgniter.Cookie.Exceptions.CookieException" errorcode="500" message="The cookie does not define withDomain().">
	</cffunction>

	<!---
	 * Creates a new Cookie with a new "Secure" attribute.
	--->
	<cffunction name="withSecure" access="public" returntype="any" output="no">
		<cfargument name="secure" type="boolean" required="no" default="true">

		<cfthrow type="ColdIgniter.Cookie.Exceptions.CookieException" errorcode="500" message="The cookie does not define withSecure().">
	</cffunction>

	<!---
	 * Creates a new Cookie with a new "HttpOnly" attribute
	--->
	<cffunction name="withHTTPOnly" access="public" returntype="any" output="no">
		<cfargument name="httponly" type="boolean" required="no" default="true">

		<cfthrow type="ColdIgniter.Cookie.Exceptions.CookieException" errorcode="500" message="The cookie does not define withHTTPOnly().">
	</cffunction>

	<!---
	 * Creates a new Cookie with a new "SameSite" attribute.
	--->
	<cffunction name="withSameSite" access="public" returntype="any" output="no">
		<cfargument name="samesite" type="string" required="yes">

		<cfthrow type="ColdIgniter.Cookie.Exceptions.CookieException" errorcode="500" message="The cookie does not define withSameSite().">
	</cffunction>

	<!---
	 * Creates a new Cookie with URL encoding option updated.
	--->
	<cffunction name="withRaw" access="public" returntype="any" output="no">
		<cfargument name="raw" type="boolean" required="no" default="true">

		<cfthrow type="ColdIgniter.Cookie.Exceptions.CookieException" errorcode="500" message="The cookie does not define withRaw().">
	</cffunction>

</cfcomponent>
