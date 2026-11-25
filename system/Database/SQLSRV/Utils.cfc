<!---
 * Utils for SQLSRV
 *
 * Difference: the original extends BaseUtils. This class is in another
 * folder, so it is mixed in with parent (see the reference, "How
 * components are located").
 *
 * Difference: the statement of optimizeTable is UPDATE STATISTICS. The
 * original uses ALTER INDEX ... REORGANIZE, which SQL Server 2000 does not
 * have (it came with 2005). DBCC DBREINDEX would rebuild the indexes, but
 * it does not return a record set and is not a write type, so the plain
 * update of the statistics is used.
--->
<cfcomponent output="no" parent="ColdIgniter\Database\BaseUtils" hint="Utils for SQLSRV">

	<!---
	 * @var bool|string
	--->
	<cfset this.listDatabases_ = "EXEC sp_helpdb">

	<!---
	 * @var bool|string
	--->
	<cfset this.optimizeTable_ = "UPDATE STATISTICS %s">

	<!---
	 * @param db Connection
	--->
	<cffunction name="__construct" access="public" returntype="any" output="no">
		<cfargument name="db" type="any" required="yes">

		<cfset parent.__construct(arguments.db)>

		<cfset this.optimizeTable_ = "UPDATE STATISTICS " & this.db.schema & ".%s">

		<cfreturn this>
	</cffunction>

	<!---
	 * @throws DatabaseException
	--->
	<cffunction name="_backup" access="public" returntype="any" output="no">
		<cfargument name="prefs" type="any" required="no" default="">

		<cfthrow type="ColdIgniter.Database.Exceptions.DatabaseException" message="Unsupported feature of the database platform you are using.">
	</cffunction>

</cfcomponent>
