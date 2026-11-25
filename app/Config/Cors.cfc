<!---
 * Cross-Origin Resource Sharing (CORS) Configuration
 *
 * @see https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS
 *
 * The arrays of the original are maps (array_()) and lists (ArrayNew(1)).
--->
<cfcomponent output="no" parent="ColdIgniter\Config\BaseConfig" hint="Cross-Origin Resource Sharing (CORS) configuration">

	<!---
	 * The default CORS configuration.
	 *
	 * A map with the keys:
	 *   allowedOrigins         - a list of origins that are allowed to access
	 *                            the resources. Example: https://www.example.com
	 *   allowedOriginsPatterns - a list of regex patterns (without delimiters,
	 *                            matched against the whole origin). Example:
	 *                            https://\w+\.example\.com
	 *   supportsCredentials    - whether the response may carry credentials
	 *                            (Access-Control-Allow-Credentials: true)
	 *   allowedHeaders         - a list of headers allowed in the request,
	 *                            for the preflight response
	 *   exposedHeaders         - a list of headers the browser may read from
	 *                            the response
	 *   allowedMethods         - a list of HTTP methods allowed in the
	 *                            request, for the preflight response
	 *   maxAge                 - the number of seconds a preflight response
	 *                            may be cached
	--->
	<cfset this.default = CreateObject("java", "java.util.LinkedHashMap").init()>
	<cfset this.default["allowedOrigins"] = ArrayNew(1)>
	<cfset this.default["allowedOriginsPatterns"] = ArrayNew(1)>
	<cfset this.default["supportsCredentials"] = false>
	<cfset this.default["allowedHeaders"] = ArrayNew(1)>
	<cfset this.default["exposedHeaders"] = ArrayNew(1)>
	<cfset this.default["allowedMethods"] = ArrayNew(1)>
	<cfset this.default["maxAge"] = 7200>

</cfcomponent>
