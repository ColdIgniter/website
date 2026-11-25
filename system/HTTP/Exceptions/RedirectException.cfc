<!---
 * RedirectException
 *
 * Not ported yet: carrying the response and the message or code of the
 * original. An exception here is not an object (see PageNotFoundException)
 * and cannot hold a response, so the code that throws it has changed a
 * response the catcher already has (see force_https() and ForceHTTPS).
 * ColdIgniter::run() does not catch it yet.
 *
 *     <cfset static_("ColdIgniter\HTTP\Exceptions\RedirectException").forResponse()>
 *
 * throws it, with the type "ColdIgniter.HTTP.Exceptions.RedirectException".
--->
<cfcomponent output="no" hint="RedirectException">

	<!---
	 * HTTP status code, the code of the exception in the original.
	--->
	<cfset this.code = 302>

	<cffunction name="forResponse" access="public" returntype="void" output="no">
		<cfthrow type="ColdIgniter.HTTP.Exceptions.RedirectException" errorcode="#this.code#" message="The request is redirected by the response.">
	</cffunction>

</cfcomponent>
