<!---
 * Returns the struct of the tables that this site keeps between requests
 * (application.ColdIgniter.shared): classes, number, inflector and
 * userAgent, each a struct that the user of the table fills.
 *
 * Not in the original. The reference is taken once per request and kept in
 * request.ColdIgniter.shared. The struct is made under a double-checked
 * application lock. When the application scope can not be used
 * (request.ColdIgniterApplication is false, see public/index.cfm), or the
 * lock times out, the struct lives for the request only, so a caller never
 * has to check.
 *
 * Only data that is the same for every request and that is not secret goes
 * in it: class names, file paths, rules, Java handles and compiled patterns.
 * Never a secret, a value of the .env file or of the configuration, or an
 * instance of a component. Any template on the server that names the same
 * application can read this scope.
--->
<cffunction name="shared_" returntype="struct" output="no" hint="Returns the tables that this site keeps between requests">
	<cfset var kept = "">

	<cfif StructKeyExists(request, "ColdIgniter") AND StructKeyExists(request.ColdIgniter, "shared")>
		<cfreturn request.ColdIgniter.shared>
	</cfif>

	<cftry>
		<cfif NOT StructKeyExists(request, "ColdIgniterApplication") OR NOT request.ColdIgniterApplication>
			<cfthrow type="ColdIgniter" message="no application scope">
		</cfif>

		<cfif NOT StructKeyExists(application, "ColdIgniter") OR NOT StructKeyExists(application.ColdIgniter, "shared")>
			<cflock scope="application" type="exclusive" timeout="10">
				<cfif NOT StructKeyExists(application, "ColdIgniter")>
					<cfset application.ColdIgniter = StructNew()>
				</cfif>

				<cfif NOT StructKeyExists(application.ColdIgniter, "shared")>
					<!--- complete before it is stored --->
					<cfset kept = StructNew()>
					<cfset kept.classes = StructNew()>
					<cfset kept.number = StructNew()>
					<cfset kept.inflector = StructNew()>
					<cfset kept.userAgent = StructNew()>
					<cfset application.ColdIgniter.shared = kept>
				</cfif>
			</cflock>
		</cfif>

		<cfset kept = application.ColdIgniter.shared>

		<cfcatch type="any">
			<!--- no scope or no lock: tables for this request only --->
			<cfset kept = StructNew()>
			<cfset kept.classes = StructNew()>
			<cfset kept.number = StructNew()>
			<cfset kept.inflector = StructNew()>
			<cfset kept.userAgent = StructNew()>
		</cfcatch>
	</cftry>

	<cfif StructKeyExists(request, "ColdIgniter")>
		<cfset request.ColdIgniter.shared = kept>
	</cfif>

	<cfreturn kept>
</cffunction>
