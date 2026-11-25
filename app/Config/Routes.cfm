<!---
 * The routes of the application.
 *
 * "routes" is the RouteCollection.
--->
<cfset routes.get("/", "Home::index")>

<!---
 * Routes for trying things out on your own machine go in
 * Routes.local.cfm, next to this file. That file is not part of
 * the repository.
--->
<cfif is_file(request.APPPATH & "Config/Routes.local.cfm")>
	<cfinclude template="Routes.local.cfm">
</cfif>
