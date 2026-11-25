<!---
 * Debug toolbar configuration
 *
 * Difference: the original has a static method display(); here it is a
 * method of the one object that static_() returns. The version and the SAPI of the original
 * are engineVersion and webServer, the version of the ColdFusion server and
 * the name of the web server.
--->
<cfcomponent output="no" hint="Debug toolbar configuration">

	<!---
	 * Return toolbar config values as a map.
	 *
	 * @return A map with the keys ciVersion, engineVersion, webServer,
	 *         environment, baseURL, timezone, locale and cspEnabled
	--->
	<cffunction name="display" access="public" returntype="any" output="no">
		<cfset var appConfig = config("Config\App")>
		<cfset var engineVersion = "">
		<cfset var webServer = "">

		<cfif StructKeyExists(server, "coldfusion") AND StructKeyExists(server.coldfusion, "productversion")>
			<cfset engineVersion = server.coldfusion.productversion>
		</cfif>
		<cfif StructKeyExists(cgi, "server_software")>
			<cfset webServer = cgi.server_software>
		</cfif>

		<cfreturn array_(
			"ciVersion", static_("ColdIgniter\ColdIgniter").CI_VERSION,
			"engineVersion", engineVersion,
			"webServer", webServer,
			"environment", request.ENVIRONMENT,
			"baseURL", appConfig.baseURL,
			"timezone", appConfig.appTimezone,
			"locale", service("request").getLocale_(),
			"cspEnabled", appConfig.CSPEnabled
		)>
	</cffunction>

</cfcomponent>
