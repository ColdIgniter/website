<!---
 * CookieException is thrown for invalid cookies initialization and management.
 *
 * Not ported yet: the messages come from the language files in the
 * original (Cookie.*); they are written out here until the language
 * service is ported.
 *
 * An exception is not an object here. The methods throw the exception
 * themselves, with the type "ColdIgniter.Cookie.Exceptions.CookieException":
 *
 *     <cfset static_("ColdIgniter\Cookie\Exceptions\CookieException").forEmptyCookieName()>
--->
<cfcomponent output="no" parent="ColdIgniter\Exceptions\FrameworkException" hint="CookieException is thrown for invalid cookies initialization and management">

	<!---
	 * Thrown for invalid type given for the "Expires" attribute.
	--->
	<cffunction name="forInvalidExpiresTime" access="public" returntype="void" output="no">
		<cfargument name="type" type="string" required="yes">

		<cfthrow type="ColdIgniter.Cookie.Exceptions.CookieException" errorcode="500" message="Invalid ""#arguments.type#"" type for ""Expires"" attribute. Expected: string, integer, DateTimeInterface object.">
	</cffunction>

	<!---
	 * Thrown when the value provided for "Expires" is invalid.
	--->
	<cffunction name="forInvalidExpiresValue" access="public" returntype="void" output="no">

		<cfthrow type="ColdIgniter.Cookie.Exceptions.CookieException" errorcode="500" message="The cookie expiration time is not valid.">
	</cffunction>

	<!---
	 * Thrown when the cookie name contains invalid characters per RFC 2616.
	--->
	<cffunction name="forInvalidCookieName" access="public" returntype="void" output="no">
		<cfargument name="name" type="string" required="yes">

		<cfthrow type="ColdIgniter.Cookie.Exceptions.CookieException" errorcode="500" message="The cookie name ""#arguments.name#"" contains invalid characters.">
	</cffunction>

	<!---
	 * Thrown when the cookie name is empty.
	--->
	<cffunction name="forEmptyCookieName" access="public" returntype="void" output="no">

		<cfthrow type="ColdIgniter.Cookie.Exceptions.CookieException" errorcode="500" message="The cookie name cannot be empty.">
	</cffunction>

	<!---
	 * Thrown when the cookie value contains invalid characters.
	--->
	<cffunction name="forInvalidCookieValue" access="public" returntype="void" output="no">

		<cfthrow type="ColdIgniter.Cookie.Exceptions.CookieException" errorcode="500" message="The cookie value contains invalid characters.">
	</cffunction>

	<!---
	 * Thrown when the cookie path contains invalid characters.
	--->
	<cffunction name="forInvalidCookiePath" access="public" returntype="void" output="no">

		<cfthrow type="ColdIgniter.Cookie.Exceptions.CookieException" errorcode="500" message="The cookie path contains invalid characters.">
	</cffunction>

	<!---
	 * Thrown when the cookie domain contains invalid characters.
	--->
	<cffunction name="forInvalidCookieDomain" access="public" returntype="void" output="no">

		<cfthrow type="ColdIgniter.Cookie.Exceptions.CookieException" errorcode="500" message="The cookie domain contains invalid characters.">
	</cffunction>

	<!---
	 * Thrown when using the `__Secure-` prefix but the `Secure` attribute
	 * is not set to true.
	--->
	<cffunction name="forInvalidSecurePrefix" access="public" returntype="void" output="no">

		<cfthrow type="ColdIgniter.Cookie.Exceptions.CookieException" errorcode="500" message="Using the ""__Secure-"" prefix requires setting the ""Secure"" attribute.">
	</cffunction>

	<!---
	 * Thrown when using the `__Host-` prefix but the `Secure` flag is not
	 * set, the `Domain` is set, and the `Path` is not `/`.
	--->
	<cffunction name="forInvalidHostPrefix" access="public" returntype="void" output="no">

		<cfthrow type="ColdIgniter.Cookie.Exceptions.CookieException" errorcode="500" message="Using the ""__Host-"" prefix must be set with the ""Secure"" flag, must not have a ""Domain"" attribute, and the ""Path"" is set to ""/"".">
	</cffunction>

	<!---
	 * Thrown when the `SameSite` attribute given is not of the valid types.
	--->
	<cffunction name="forInvalidSameSite" access="public" returntype="void" output="no">
		<cfargument name="sameSite" type="string" required="yes">

		<cfthrow type="ColdIgniter.Cookie.Exceptions.CookieException" errorcode="500" message="The SameSite value must be None, Lax, Strict or a blank string, #arguments.sameSite# given.">
	</cffunction>

	<!---
	 * Thrown when the `SameSite` attribute is set to `None` but the `Secure`
	 * attribute is not set.
	--->
	<cffunction name="forInvalidSameSiteNone" access="public" returntype="void" output="no">

		<cfthrow type="ColdIgniter.Cookie.Exceptions.CookieException" errorcode="500" message="Using the ""SameSite=None"" attribute requires setting the ""Secure"" attribute.">
	</cffunction>

	<!---
	 * Thrown when the `CookieStore` class is filled with invalid Cookie objects.
	 * 
	 * Difference: the four values of the list are four arguments.
	--->
	<cffunction name="forInvalidCookieInstance" access="public" returntype="void" output="no">
		<cfargument name="class" type="string" required="yes">
		<cfargument name="expected" type="string" required="yes">
		<cfargument name="actual" type="string" required="yes">
		<cfargument name="index" type="string" required="yes">

		<cfthrow type="ColdIgniter.Cookie.Exceptions.CookieException" errorcode="500" message="""#arguments.class#"" class expected cookies array to be instances of ""#arguments.expected#"" but got ""#arguments.actual#"" at index #arguments.index#.">
	</cffunction>

	<!---
	 * Thrown when the queried Cookie object does not exist in the cookie collection.
	 * 
	 * Difference: the two values of the list are two arguments.
	--->
	<cffunction name="forUnknownCookieInstance" access="public" returntype="void" output="no">
		<cfargument name="name" type="string" required="yes">
		<cfargument name="prefix" type="string" required="yes">

		<cfthrow type="ColdIgniter.Cookie.Exceptions.CookieException" errorcode="500" message="Cookie object with name ""#arguments.name#"" and prefix ""#arguments.prefix#"" was not found in the collection.">
	</cffunction>

</cfcomponent>
