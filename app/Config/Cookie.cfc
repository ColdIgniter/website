<!---
 * Cookie configuration.
 *
 * Difference: the expires time is a Unix timestamp, or a string of digits
 * (see Cookie). The names of the SameSite constants are on
 * CookieInterface, as this.SAMESITE_NONE, this.SAMESITE_LAX and
 * this.SAMESITE_STRICT; here the values are written out.
--->
<cfcomponent output="no" parent="ColdIgniter\Config\BaseConfig" hint="Cookie configuration">

	<!---
	 * --------------------------------------------------------------------------
	 * Cookie Prefix
	 * --------------------------------------------------------------------------
	 *
	 * Set a cookie name prefix if you need to avoid collisions.
	 *
	 * @var string
	--->
	<cfset this.prefix = "">

	<!---
	 * --------------------------------------------------------------------------
	 * Cookie Expires Timestamp
	 * --------------------------------------------------------------------------
	 *
	 * Default expires timestamp for cookies. Setting this to `0` will mean the
	 * cookie will not have the `Expires` attribute and will behave as a session
	 * cookie.
	 *
	 * @var int|string
	--->
	<cfset this.expires = 0>

	<!---
	 * --------------------------------------------------------------------------
	 * Cookie Path
	 * --------------------------------------------------------------------------
	 *
	 * Typically will be a forward slash.
	 *
	 * @var string
	--->
	<cfset this.path = "/">

	<!---
	 * --------------------------------------------------------------------------
	 * Cookie Domain
	 * --------------------------------------------------------------------------
	 *
	 * Set to `.your-domain.com` for site-wide cookies.
	 *
	 * @var string
	--->
	<cfset this.domain = "">

	<!---
	 * --------------------------------------------------------------------------
	 * Cookie Secure
	 * --------------------------------------------------------------------------
	 *
	 * Cookie will only be set if a secure HTTPS connection exists.
	 *
	 * @var bool
	--->
	<cfset this.secure = false>

	<!---
	 * --------------------------------------------------------------------------
	 * Cookie HTTPOnly
	 * --------------------------------------------------------------------------
	 *
	 * Cookie will only be accessible via HTTP(S) (no JavaScript).
	 *
	 * @var bool
	--->
	<cfset this.httponly = true>

	<!---
	 * --------------------------------------------------------------------------
	 * Cookie SameSite
	 * --------------------------------------------------------------------------
	 *
	 * Configure cookie SameSite setting. Allowed values are:
	 *
	 * - None
	 * - Lax
	 * - Strict
	 * - ''
	 *
	 * Defaults to `Lax` for compatibility with modern browsers. Setting `''`
	 * (empty string) means default SameSite attribute set by browsers (`Lax`)
	 * will be set on cookies. If set to `None`, `secure` must also be set.
	 *
	 * @var ''|'Lax'|'None'|'Strict'
	--->
	<cfset this.samesite = "Lax">

	<!---
	 * --------------------------------------------------------------------------
	 * Cookie Raw
	 * --------------------------------------------------------------------------
	 *
	 * This flag allows setting a "raw" cookie, i.e., its name and value are
	 * not URL encoded using `rawurlencode()`.
	 *
	 * If this is set to `true`, cookie names should be compliant of RFC 2616's
	 * list of allowed characters.
	 *
	 * @see https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Set-Cookie#attributes
	 * @see https://tools.ietf.org/html/rfc2616#section-2.2
	 *
	 * @var bool
	--->
	<cfset this.raw = false>

</cfcomponent>
