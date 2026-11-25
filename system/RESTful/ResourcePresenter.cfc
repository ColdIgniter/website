<!---
 * An extendable controller to help provide a UI for a resource.
--->
<cfcomponent output="no" extends="BaseResource" hint="An extendable controller to provide a UI for a resource">

	<!---
	 * Present a view of resource objects
	--->
	<cffunction name="index" access="public" returntype="any" output="no">
		<cfset var args = ArrayNew(1)>

		<cfset ArrayAppend(args, "index")>

		<cfreturn lang("RESTful.notImplemented", args)>
	</cffunction>

	<!---
	 * Present a view to present a specific resource object
	 *
	 * @param id The id of the resource; an empty string (null) for none
	--->
	<cffunction name="show" access="public" returntype="any" output="no">
		<cfargument name="id" type="any" required="no" default="">
		<cfset var args = ArrayNew(1)>

		<cfset ArrayAppend(args, "show")>

		<cfreturn lang("RESTful.notImplemented", args)>
	</cffunction>

	<!---
	 * Present a view to present a new single resource object
	--->
	<cffunction name="new" access="public" returntype="any" output="no">
		<cfset var args = ArrayNew(1)>

		<cfset ArrayAppend(args, "new")>

		<cfreturn lang("RESTful.notImplemented", args)>
	</cffunction>

	<!---
	 * Process the creation/insertion of a new resource object.
	 * This should be a POST.
	--->
	<cffunction name="create" access="public" returntype="any" output="no">
		<cfset var args = ArrayNew(1)>

		<cfset ArrayAppend(args, "create")>

		<cfreturn lang("RESTful.notImplemented", args)>
	</cffunction>

	<!---
	 * Present a view to edit the properties of a specific resource object
	 *
	 * @param id The id of the resource; an empty string (null) for none
	--->
	<cffunction name="edit" access="public" returntype="any" output="no">
		<cfargument name="id" type="any" required="no" default="">
		<cfset var args = ArrayNew(1)>

		<cfset ArrayAppend(args, "edit")>

		<cfreturn lang("RESTful.notImplemented", args)>
	</cffunction>

	<!---
	 * Process the updating, full or partial, of a specific resource object.
	 * This should be a POST.
	 *
	 * @param id The id of the resource; an empty string (null) for none
	--->
	<cffunction name="update" access="public" returntype="any" output="no">
		<cfargument name="id" type="any" required="no" default="">
		<cfset var args = ArrayNew(1)>

		<cfset ArrayAppend(args, "update")>

		<cfreturn lang("RESTful.notImplemented", args)>
	</cffunction>

	<!---
	 * Present a view to confirm the deletion of a specific resource object
	 *
	 * @param id The id of the resource; an empty string (null) for none
	--->
	<cffunction name="remove" access="public" returntype="any" output="no">
		<cfargument name="id" type="any" required="no" default="">
		<cfset var args = ArrayNew(1)>

		<cfset ArrayAppend(args, "remove")>

		<cfreturn lang("RESTful.notImplemented", args)>
	</cffunction>

	<!---
	 * Process the deletion of a specific resource object
	 *
	 * @param id The id of the resource; an empty string (null) for none
	--->
	<cffunction name="delete" access="public" returntype="any" output="no">
		<cfargument name="id" type="any" required="no" default="">
		<cfset var args = ArrayNew(1)>

		<cfset ArrayAppend(args, "delete")>

		<cfreturn lang("RESTful.notImplemented", args)>
	</cffunction>

</cfcomponent>
