<!---
 * Parses a URL and returns its components.
 *
 * The result is an array with string keys (see array_()) that only
 * holds the parts that are present: scheme, host, port, user, pass,
 * path, query, fragment.
--->
<cffunction name="parse_url" returntype="any" output="no" hint="Parses a URL and returns its components">
	<cfargument name="uri" type="string" required="yes">
	<cfset var parts = CreateObject("java", "java.util.LinkedHashMap").init()>
	<cfset var matcher = CreateObject("java", "java.util.regex.Pattern").compile("^(?:([^:/?##]+):)?(?://([^/?##]*))?([^?##]*)(?:\?([^##]*))?(?:##(.*))?$").matcher(arguments.uri)>
	<cfset var authority = "">
	<cfset var userinfo = "">
	<cfset var position = 0>

	<cfif NOT matcher.matches()>
		<cfreturn parts>
	</cfif>

	<cfif matcher.start(1) GTE 0>
		<cfset parts["scheme"] = matcher.group(1)>
	</cfif>

	<cfif matcher.start(2) GTE 0>
		<cfset authority = matcher.group(2)>

		<cfset position = Find("@", authority)>
		<cfif position GT 0>
			<cfset userinfo = Left(authority, position - 1)>
			<cfset authority = substr(authority, position)>
		</cfif>

		<cfset position = REFind(":[0-9]+$", authority)>
		<cfif position GT 0>
			<cfset parts["host"] = Left(authority, position - 1)>
			<cfset parts["port"] = substr(authority, position)>
		<cfelse>
			<cfset parts["host"] = authority>
		</cfif>

		<cfif userinfo NEQ "">
			<cfset position = Find(":", userinfo)>
			<cfif position GT 0>
				<cfset parts["user"] = Left(userinfo, position - 1)>
				<cfset parts["pass"] = substr(userinfo, position)>
			<cfelse>
				<cfset parts["user"] = userinfo>
			</cfif>
		</cfif>
	</cfif>

	<cfif matcher.group(3) NEQ "">
		<cfset parts["path"] = matcher.group(3)>
	</cfif>

	<cfif matcher.start(4) GTE 0>
		<cfset parts["query"] = matcher.group(4)>
	</cfif>

	<cfif matcher.start(5) GTE 0>
		<cfset parts["fragment"] = matcher.group(5)>
	</cfif>

	<cfreturn parts>
</cffunction>
