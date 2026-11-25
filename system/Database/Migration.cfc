<!---
 * Class Migration
 *
 * A migration is a component in app/Database/Migrations that has the
 * parent "ColdIgniter\Database\Migration" and the two methods up() and
 * down():
 *
 *     <cfcomponent output="no" parent="ColdIgniter\Database\Migration">
 *
 * Difference: the original is abstract with abstract up() and down(). There
 * is no abstract method here, and the methods are not declared: the runner
 * refuses a migration that has no such method (Migrations.missingMethod).
--->
<cfcomponent output="no" hint="Class Migration">

	<!---
	 * The name of the database group to use.
	 *
	 * @var string An empty string is the null of the original
	--->
	<cfset this.DBGroup = "">

	<!---
	 * Database Connection instance
	 *
	 * @var ConnectionInterface
	--->
	<cfset this.db = "">

	<!---
	 * Database Forge instance.
	 *
	 * @var Forge
	--->
	<cfset this.forge = "">

	<cffunction name="__construct" access="public" returntype="any" output="no">
		<cfargument name="forge" type="any" required="no" default="">

		<cfif Compare(this.DBGroup, "") NEQ 0>
			<cfset this.forge = static_("ColdIgniter\Database\Config").forge(this.DBGroup)>
		<cfelseif IsObject(arguments.forge) AND instanceof_(arguments.forge, "ColdIgniter\Database\Forge")>
			<cfset this.forge = arguments.forge>
		<cfelse>
			<cfset this.forge = static_("ColdIgniter\Database\Config").forge(config("Config\Database").defaultGroup)>
		</cfif>

		<cfset this.db = this.forge.getConnection()>

		<cfreturn this>
	</cffunction>

	<!---
	 * Returns the database group name this migration uses.
	 *
	 * @return string An empty string when it uses the default group
	--->
	<cffunction name="getDBGroup" access="public" returntype="string" output="no">

		<cfreturn this.DBGroup>
	</cffunction>

</cfcomponent>
