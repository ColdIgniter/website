<!---
 * BaseController provides a convenient place for loading components
 * and performing functions that are needed by all your controllers.
 *
 * Extend this class in any new controllers:
 *
 *     <cfcomponent output="no" extends="BaseController">
 *
 * For security, be sure to declare any new methods as private.
--->
<cfcomponent output="no" parent="ColdIgniter\Controller">

	<!---
	 * Be sure to declare properties for any property fetch you initialized.
	--->
	<!--- <cfset this.session = ""> --->

	<cffunction name="initController" access="public" returntype="void" output="no">
		<cfargument name="request_" type="any" required="yes">
		<cfargument name="response" type="any" required="yes">
		<cfargument name="logger" type="any" required="yes">

		<!--- Load here all helpers you want to be available in your controllers that extend BaseController. --->
		<!--- Caution: Do not put the this below the parent.initController() call below. --->
		<!--- <cfset this.helpers = ArrayNew(1)> --->

		<!--- Caution: Do not edit this line. --->
		<cfset parent.initController(arguments.request_, arguments.response, arguments.logger)>

		<!--- Preload any models, libraries, etc, here. --->
		<!--- <cfset this.session = service("session")> --->
	</cffunction>

</cfcomponent>
