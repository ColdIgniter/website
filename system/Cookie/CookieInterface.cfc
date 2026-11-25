<!---
 * Interface for a value object representation of an HTTP cookie.
 *
 * There are no interfaces on 6.1, so this is a base component. Cookie
 * extends it (extends="CookieInterface"). The methods here only throw; a
 * cookie has to define them. The constants are properties of this.
 *
 * @see https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Set-Cookie
--->
<cfcomponent output="no" hint="Interface for a value object representation of an HTTP cookie">

	<!---
	 * Cookies will be sent in all contexts, i.e in responses to both
	 * first-party and cross-origin requests. If `SameSite=None` is set,
	 * the cookie `Secure` attribute must also be set (or the cookie will be blocked).
	--->
	<cfset this.SAMESITE_NONE = "None">

	<!---
	 * Cookies are not sent on normal cross-site subrequests (for example to
	 * load images or frames into a third party site), but are sent when a
	 * user is navigating to the origin site (i.e. when following a link).
	--->
	<cfset this.SAMESITE_LAX = "Lax">

	<!---
	 * Cookies will only be sent in a first-party context and not be sent
	 * along with requests initiated by third party websites.
	--->
	<cfset this.SAMESITE_STRICT = "Strict">

	<!---
	 * RFC 6265 allowed values for the "SameSite" attribute.
	 *
	 * @see https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Set-Cookie/SameSite
	--->
	<cfset this.ALLOWED_SAMESITE_VALUES = ArrayNew(1)>
	<cfset ArrayAppend(this.ALLOWED_SAMESITE_VALUES, this.SAMESITE_NONE)>
	<cfset ArrayAppend(this.ALLOWED_SAMESITE_VALUES, this.SAMESITE_LAX)>
	<cfset ArrayAppend(this.ALLOWED_SAMESITE_VALUES, this.SAMESITE_STRICT)>

	<!---
	 * Expires date format.
	 *
	 * @see https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Date
	 * @see https://tools.ietf.org/html/rfc7231#section-7.1.1.2
	--->
	<cfset this.EXPIRES_FORMAT = "D, d M Y H:i:s T">

	<!---
	 * Returns a unique identifier for the cookie consisting
	 * of its prefixed name, path, and domain.
	--->
	<cffunction name="getId" access="public" returntype="any" output="no">

		<cfthrow type="ColdIgniter.Cookie.Exceptions.CookieException" errorcode="500" message="The cookie does not define getId().">
	</cffunction>

	<!---
	 * Gets the cookie prefix.
	--->
	<cffunction name="getPrefix" access="public" returntype="any" output="no">

		<cfthrow type="ColdIgniter.Cookie.Exceptions.CookieException" errorcode="500" message="The cookie does not define getPrefix().">
	</cffunction>

	<!---
	 * Gets the cookie name.
	--->
	<cffunction name="getName" access="public" returntype="any" output="no">

		<cfthrow type="ColdIgniter.Cookie.Exceptions.CookieException" errorcode="500" message="The cookie does not define getName().">
	</cffunction>

	<!---
	 * Gets the cookie name prepended with the prefix, if any.
	--->
	<cffunction name="getPrefixedName" access="public" returntype="any" output="no">

		<cfthrow type="ColdIgniter.Cookie.Exceptions.CookieException" errorcode="500" message="The cookie does not define getPrefixedName().">
	</cffunction>

	<!---
	 * Gets the cookie value.
	--->
	<cffunction name="getValue" access="public" returntype="any" output="no">

		<cfthrow type="ColdIgniter.Cookie.Exceptions.CookieException" errorcode="500" message="The cookie does not define getValue().">
	</cffunction>

	<!---
	 * Gets the time in Unix timestamp the cookie expires.
	--->
	<cffunction name="getExpiresTimestamp" access="public" returntype="any" output="no">

		<cfthrow type="ColdIgniter.Cookie.Exceptions.CookieException" errorcode="500" message="The cookie does not define getExpiresTimestamp().">
	</cffunction>

	<!---
	 * Gets the formatted expires time.
	--->
	<cffunction name="getExpiresString" access="public" returntype="any" output="no">

		<cfthrow type="ColdIgniter.Cookie.Exceptions.CookieException" errorcode="500" message="The cookie does not define getExpiresString().">
	</cffunction>

	<!---
	 * Checks if the cookie is expired.
	--->
	<cffunction name="isExpired" access="public" returntype="any" output="no">

		<cfthrow type="ColdIgniter.Cookie.Exceptions.CookieException" errorcode="500" message="The cookie does not define isExpired().">
	</cffunction>

	<!---
	 * Gets the "Max-Age" cookie attribute.
	--->
	<cffunction name="getMaxAge" access="public" returntype="any" output="no">

		<cfthrow type="ColdIgniter.Cookie.Exceptions.CookieException" errorcode="500" message="The cookie does not define getMaxAge().">
	</cffunction>

	<!---
	 * Gets the "Path" cookie attribute.
	--->
	<cffunction name="getPath" access="public" returntype="any" output="no">

		<cfthrow type="ColdIgniter.Cookie.Exceptions.CookieException" errorcode="500" message="The cookie does not define getPath().">
	</cffunction>

	<!---
	 * Gets the "Domain" cookie attribute.
	--->
	<cffunction name="getDomain" access="public" returntype="any" output="no">

		<cfthrow type="ColdIgniter.Cookie.Exceptions.CookieException" errorcode="500" message="The cookie does not define getDomain().">
	</cffunction>

	<!---
	 * Gets the "Secure" cookie attribute.
	 * Checks if the cookie is only sent to the server when a request is made
	 * with the `https:` scheme (except on `localhost`), and therefore is more
	 * resistent to man-in-the-middle attacks.
	--->
	<cffunction name="isSecure" access="public" returntype="any" output="no">

		<cfthrow type="ColdIgniter.Cookie.Exceptions.CookieException" errorcode="500" message="The cookie does not define isSecure().">
	</cffunction>

	<!---
	 * Gets the "HttpOnly" cookie attribute.
	 * Checks if JavaScript is forbidden from accessing the cookie.
	--->
	<cffunction name="isHTTPOnly" access="public" returntype="any" output="no">

		<cfthrow type="ColdIgniter.Cookie.Exceptions.CookieException" errorcode="500" message="The cookie does not define isHTTPOnly().">
	</cffunction>

	<!---
	 * Gets the "SameSite" cookie attribute.
	--->
	<cffunction name="getSameSite" access="public" returntype="any" output="no">

		<cfthrow type="ColdIgniter.Cookie.Exceptions.CookieException" errorcode="500" message="The cookie does not define getSameSite().">
	</cffunction>

	<!---
	 * Checks if the cookie should be sent with no URL encoding.
	--->
	<cffunction name="isRaw" access="public" returntype="any" output="no">

		<cfthrow type="ColdIgniter.Cookie.Exceptions.CookieException" errorcode="500" message="The cookie does not define isRaw().">
	</cffunction>

	<!---
	 * Gets the options that are passable to the cookie function:
	 * expires, path, domain, secure, httponly and samesite, in that order,
	 * as a map (see array_()).
	--->
	<cffunction name="getOptions" access="public" returntype="any" output="no">

		<cfthrow type="ColdIgniter.Cookie.Exceptions.CookieException" errorcode="500" message="The cookie does not define getOptions().">
	</cffunction>

	<!---
	 * Returns the Cookie as a header value.
	--->
	<cffunction name="toHeaderString" access="public" returntype="any" output="no">

		<cfthrow type="ColdIgniter.Cookie.Exceptions.CookieException" errorcode="500" message="The cookie does not define toHeaderString().">
	</cffunction>

	<!---
	 * Returns the string representation of the Cookie object.
	--->
	<cffunction name="__toString" access="public" returntype="any" output="no">

		<cfthrow type="ColdIgniter.Cookie.Exceptions.CookieException" errorcode="500" message="The cookie does not define __toString().">
	</cffunction>

	<!---
	 * Returns the array representation of the Cookie object: name, value,
	 * prefix and raw, then the options, as a map (see array_()).
	--->
	<cffunction name="toArray" access="public" returntype="any" output="no">

		<cfthrow type="ColdIgniter.Cookie.Exceptions.CookieException" errorcode="500" message="The cookie does not define toArray().">
	</cffunction>

</cfcomponent>
