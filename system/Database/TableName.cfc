<!---
 * Represents a table name in SQL.
 *
 * Difference: there are no static members and no protected constructors,
 * so the static factories create(), fromActualName() and fromFullName()
 * are methods of the object that static_("ColdIgniter\Database\TableName")
 * gives, and they return new objects made with new_(). __construct() is
 * what the original calls the protected constructor.
 *
 * @interal
--->
<cfcomponent output="no" hint="Represents a table name in SQL">

	<!---
	 * @var string Actual table name
	--->
	<cfset this.actualTable = "">

	<!---
	 * @var string Logical table name (w/o DB prefix)
	--->
	<cfset this.logicalTable = "">

	<!---
	 * @var string Schema name
	--->
	<cfset this.schema = "">

	<!---
	 * @var string Database name
	--->
	<cfset this.database = "">

	<!---
	 * @var string Alias name
	--->
	<cfset this.alias = "">

	<!---
	 * @param string actualTable  Actual table name
	 * @param string logicalTable Logical table name (w/o DB prefix)
	 * @param string schema       Schema name
	 * @param string database     Database name
	 * @param string alias        Alias name
	--->
	<cffunction name="__construct" access="public" returntype="any" output="no">
		<cfargument name="actualTable" type="string" required="yes">
		<cfargument name="logicalTable" type="string" required="no" default="">
		<cfargument name="schema" type="string" required="no" default="">
		<cfargument name="database" type="string" required="no" default="">
		<cfargument name="alias" type="string" required="no" default="">

		<cfset this.actualTable = arguments.actualTable>
		<cfset this.logicalTable = arguments.logicalTable>
		<cfset this.schema = arguments.schema>
		<cfset this.database = arguments.database>
		<cfset this.alias = arguments.alias>

		<cfreturn this>
	</cffunction>

	<!---
	 * Creates a new instance.
	 *
	 * @param string table Table name (w/o DB prefix)
	 * @param string alias Alias name
	--->
	<cffunction name="create" access="public" returntype="any" output="no">
		<cfargument name="dbPrefix" type="string" required="yes">
		<cfargument name="table" type="string" required="yes">
		<cfargument name="alias" type="string" required="no" default="">

		<cfreturn new_("ColdIgniter\Database\TableName", arguments.dbPrefix & arguments.table, arguments.table, "", "", arguments.alias)>
	</cffunction>

	<!---
	 * Creates a new instance from an actual table name.
	 *
	 * @param string actualTable Actual table name with DB prefix
	 * @param string alias       Alias name
	 *
	 * As in the original, the alias is passed in the place of the database
	 * name.
	--->
	<cffunction name="fromActualName" access="public" returntype="any" output="no">
		<cfargument name="dbPrefix" type="string" required="yes">
		<cfargument name="actualTable" type="string" required="yes">
		<cfargument name="alias" type="string" required="no" default="">
		<cfset var prefix = arguments.dbPrefix>
		<cfset var logicalTable = "">

		<cfif Len(prefix) LTE Len(arguments.actualTable) AND Compare(Left(arguments.actualTable, Len(prefix)), prefix) EQ 0>
			<cfset logicalTable = substr(arguments.actualTable, Len(prefix))>
		</cfif>

		<cfreturn new_("ColdIgniter\Database\TableName", arguments.actualTable, logicalTable, "", arguments.alias)>
	</cffunction>

	<!---
	 * Creates a new instance from full name.
	 *
	 * @param string table    Table name (w/o DB prefix)
	 * @param string schema   Schema name
	 * @param string database Database name
	 * @param string alias    Alias name
	--->
	<cffunction name="fromFullName" access="public" returntype="any" output="no">
		<cfargument name="dbPrefix" type="string" required="yes">
		<cfargument name="table" type="string" required="yes">
		<cfargument name="schema" type="string" required="no" default="">
		<cfargument name="database" type="string" required="no" default="">
		<cfargument name="alias" type="string" required="no" default="">

		<cfreturn new_("ColdIgniter\Database\TableName", arguments.dbPrefix & arguments.table, arguments.table, arguments.schema, arguments.database, arguments.alias)>
	</cffunction>

	<!---
	 * Returns the single segment table name w/o DB prefix.
	--->
	<cffunction name="getTableName" access="public" returntype="string" output="no">

		<cfreturn this.logicalTable>
	</cffunction>

	<!---
	 * Returns the actual single segment table name w/z DB prefix.
	--->
	<cffunction name="getActualTableName" access="public" returntype="string" output="no">

		<cfreturn this.actualTable>
	</cffunction>

	<cffunction name="getAlias" access="public" returntype="string" output="no">

		<cfreturn this.alias>
	</cffunction>

	<cffunction name="getSchema" access="public" returntype="string" output="no">

		<cfreturn this.schema>
	</cffunction>

	<cffunction name="getDatabase" access="public" returntype="string" output="no">

		<cfreturn this.database>
	</cffunction>

</cfcomponent>
