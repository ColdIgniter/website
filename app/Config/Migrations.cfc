<!---
 * Migrations Configuration
 *
 * Difference: a migration file is a component, so its name has to be a
 * valid component name: it starts with the letter M, then the timestamp
 * as YmdHis, an underscore and the name (M20261124120000_CreateUsers.cfc).
 * The timestamp formats with hyphens or underscores of the original
 * are not supported (a hyphen is not safe in a component name).
--->
<cfcomponent output="no" parent="ColdIgniter\Config\BaseConfig" hint="Migrations Configuration">

	<!---
	 * --------------------------------------------------------------------------
	 * Enable/Disable Migrations
	 * --------------------------------------------------------------------------
	 *
	 * Migrations are enabled by default.
	 *
	 * You should enable migrations whenever you intend to do a schema migration
	 * and disable it back when you're done.
	--->
	<cfset this.enabled = true>

	<!---
	 * --------------------------------------------------------------------------
	 * Migrations Table
	 * --------------------------------------------------------------------------
	 *
	 * This is the name of the table that will store the current migrations state.
	 * When migrations runs it will store in a database table which migration
	 * files have already been run.
	--->
	<cfset this.table = "migrations">

	<!---
	 * --------------------------------------------------------------------------
	 * Timestamp Format
	 * --------------------------------------------------------------------------
	 *
	 * This is the format that will be used when a migration file is named.
	 * There is no command line to create one, so the name is made by hand.
	 *
	 * Difference: only YmdHis_ is supported, written as the letter M in
	 * front of the file name (see the top of this file).
	--->
	<cfset this.timestampFormat = "YmdHis_">

	<!---
	 * --------------------------------------------------------------------------
	 * Enable/Disable Migration Lock
	 * --------------------------------------------------------------------------
	 *
	 * Locking is disabled by default.
	 *
	 * When enabled, it will prevent multiple migration processes
	 * from running at the same time by using a lock mechanism.
	 *
	 * This is useful in production environments to avoid conflicts
	 * or race conditions during concurrent deployments.
	--->
	<cfset this.lock = false>

</cfcomponent>
