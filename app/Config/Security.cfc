<!---
 * Security configuration.
 *
 * Difference: a boolean is the string "true" or "false". The environment
 * is request.ENVIRONMENT.
--->
<cfcomponent output="no" parent="ColdIgniter\Config\BaseConfig" hint="Security configuration">

	<!---
	 * --------------------------------------------------------------------------
	 * CSRF Protection Method
	 * --------------------------------------------------------------------------
	 *
	 * Protection Method for Cross Site Request Forgery protection.
	 *
	 * @var string 'cookie' or 'session'
	--->
	<cfset this.csrfProtection = "cookie">

	<!---
	 * --------------------------------------------------------------------------
	 * CSRF Token Randomization
	 * --------------------------------------------------------------------------
	 *
	 * Randomize the CSRF Token for added security.
	--->
	<cfset this.tokenRandomize = "false">

	<!---
	 * --------------------------------------------------------------------------
	 * CSRF Token Name
	 * --------------------------------------------------------------------------
	 *
	 * Token name for Cross Site Request Forgery protection.
	--->
	<cfset this.tokenName = "csrf_test_name">

	<!---
	 * --------------------------------------------------------------------------
	 * CSRF Header Name
	 * --------------------------------------------------------------------------
	 *
	 * Header name for Cross Site Request Forgery protection.
	--->
	<cfset this.headerName = "X-CSRF-TOKEN">

	<!---
	 * --------------------------------------------------------------------------
	 * CSRF Cookie Name
	 * --------------------------------------------------------------------------
	 *
	 * Cookie name for Cross Site Request Forgery protection.
	--->
	<cfset this.cookieName = "csrf_cookie_name">

	<!---
	 * --------------------------------------------------------------------------
	 * CSRF Expires
	 * --------------------------------------------------------------------------
	 *
	 * Expiration time for Cross Site Request Forgery protection cookie.
	 *
	 * Defaults to two hours (in seconds).
	--->
	<cfset this.expires = 7200>

	<!---
	 * --------------------------------------------------------------------------
	 * CSRF Regenerate
	 * --------------------------------------------------------------------------
	 *
	 * Regenerate CSRF Token on every submission.
	--->
	<cfset this.regenerate = "true">

	<!---
	 * --------------------------------------------------------------------------
	 * CSRF Redirect
	 * --------------------------------------------------------------------------
	 *
	 * Redirect to previous page with error on failure.
	 *
	 * @see https://codeigniter4.github.io/userguide/libraries/security.html#redirection-on-failure
	--->
	<cfif Compare(request.ENVIRONMENT, "production") EQ 0>
		<cfset this.redirect = "true">
	<cfelse>
		<cfset this.redirect = "false">
	</cfif>

</cfcomponent>
