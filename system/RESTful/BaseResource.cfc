<!---
 * Difference: initController() does what Controller.initController() does
 * itself instead of calling parent.initController(). An application
 * controller has ResourceController as its parent, and the "parent" table
 * of such a chain is shared (see extend() and parentObject() of the
 * Autoloader), so the call would reach this function again. The copy must
 * change whenever Controller.initController() changes.
 *
 * Not ported yet: model() (Factories): setModel() makes the model with
 * new_(), so a model is not shared.
--->
<cfcomponent output="no" parent="ColdIgniter\Controller" hint="An extendable controller to help provide a UI for a resource">

	<!---
	 * Instance of the main Request object.
	 *
	 * Named with an underscore, because "request" is a scope.
	--->
	<cfset this.request_ = "">

	<!---
	 * The model that holding this resource's data: a class name, or an empty string (null)
	--->
	<cfset this.modelName = "">

	<!---
	 * The model that holding this resource's data: an object, or an empty string (null)
	--->
	<cfset this.model = "">

	<!---
	 * Constructor.
	 *
	 * @param request_ The request
	--->
	<cffunction name="initController" access="public" returntype="void" output="no">
		<cfargument name="request_" type="any" required="yes">
		<cfargument name="response" type="any" required="yes">
		<cfargument name="logger" type="any" required="yes">

		<cfset this.request_ = arguments.request_>
		<cfset this.response = arguments.response>
		<cfset this.logger = arguments.logger>

		<!--- Not ported yet: forceHTTPS (see Controller) --->

		<!--- Autoload helper files. --->
		<cfset helper(this.helpers)>

		<cfset setModel(this.modelName)>
	</cffunction>

	<!---
	 * Set or change the model this controller is bound to.
	 * Given either the name or the object, determine the other.
	 *
	 * @param which A model object, a class name, or an empty string (null) to keep what is set
	--->
	<cffunction name="setModel" access="public" returntype="void" output="no">
		<cfargument name="which" type="any" required="no" default="">

		<cfif NOT is_null(arguments.which)>
			<cfif IsObject(arguments.which)>
				<cfset this.model = arguments.which>
				<cfset this.modelName = "">
			<cfelse>
				<cfset this.model = "">
				<cfset this.modelName = arguments.which>
			</cfif>
		</cfif>

		<cfif is_null(this.model) AND NOT is_null(this.modelName) AND class_exists(this.modelName)>
			<cfset this.model = new_(this.modelName)>
		</cfif>

		<cfif NOT is_null(this.model) AND is_null(this.modelName)>
			<cfset this.modelName = this.model.__class>
		</cfif>
	</cffunction>

</cfcomponent>
