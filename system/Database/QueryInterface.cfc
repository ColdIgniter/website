<!---
 * Represents a single statement that can be executed against the database.
Statements are platform-specific and can handle binding of binds.
 *
 * There are no interfaces on 6.1, so this is a base component. Query
 * extends it, and the methods here only throw; a class that extends it
 * has to define them.
--->
<cfcomponent output="no" hint="Expected behavior of a query">

	<!---
	 * Sets the raw query string to use for this statement.
	--->
	<cffunction name="setQuery" access="public" returntype="any" output="no">
		<cfargument name="sql" type="string" required="yes">
		<cfargument name="binds" type="any" required="no" default="">
		<cfargument name="setEscape" type="boolean" required="no" default="true">

		<cfthrow type="ColdIgniter.LogicException" message="The class does not define setQuery().">
	</cffunction>

	<!---
	 * Returns the final, processed query string after binding, etal
	 * has been performed.
	--->
	<cffunction name="getQuery" access="public" returntype="string" output="no">

		<cfthrow type="ColdIgniter.LogicException" message="The class does not define getQuery().">
	</cffunction>

	<!---
	 * Records the execution time of the statement using microtime(true)
	 * for it's start and end values. If no end value is present, will
	 * use the current time to determine total duration.
	--->
	<cffunction name="setDuration" access="public" returntype="any" output="no">
		<cfargument name="start" type="numeric" required="yes">
		<cfargument name="end" type="any" required="no" default="">

		<cfthrow type="ColdIgniter.LogicException" message="The class does not define setDuration().">
	</cffunction>

	<!---
	 * Returns the duration of this query during execution, or null if
	 * the query has not been executed yet.
	--->
	<cffunction name="getDuration" access="public" returntype="string" output="no">
		<cfargument name="decimals" type="numeric" required="no" default="6">

		<cfthrow type="ColdIgniter.LogicException" message="The class does not define getDuration().">
	</cffunction>

	<!---
	 * Stores the error description that happened for this query.
	--->
	<cffunction name="setError" access="public" returntype="any" output="no">
		<cfargument name="code" type="numeric" required="yes">
		<cfargument name="error" type="string" required="yes">

		<cfthrow type="ColdIgniter.LogicException" message="The class does not define setError().">
	</cffunction>

	<!---
	 * Reports whether this statement created an error not.
	--->
	<cffunction name="hasError" access="public" returntype="boolean" output="no">

		<cfthrow type="ColdIgniter.LogicException" message="The class does not define hasError().">
	</cffunction>

	<!---
	 * Returns the error code created while executing this statement.
	--->
	<cffunction name="getErrorCode" access="public" returntype="numeric" output="no">

		<cfthrow type="ColdIgniter.LogicException" message="The class does not define getErrorCode().">
	</cffunction>

	<!---
	 * Returns the error message created while executing this statement.
	--->
	<cffunction name="getErrorMessage" access="public" returntype="string" output="no">

		<cfthrow type="ColdIgniter.LogicException" message="The class does not define getErrorMessage().">
	</cffunction>

	<!---
	 * Determines if the statement is a write-type query or not.
	--->
	<cffunction name="isWriteType" access="public" returntype="boolean" output="no">

		<cfthrow type="ColdIgniter.LogicException" message="The class does not define isWriteType().">
	</cffunction>

	<!---
	 * Swaps out one table prefix for a new one.
	--->
	<cffunction name="swapPrefix" access="public" returntype="any" output="no">
		<cfargument name="orig" type="string" required="yes">
		<cfargument name="swap" type="string" required="yes">

		<cfthrow type="ColdIgniter.LogicException" message="The class does not define swapPrefix().">
	</cffunction>

	<!---
	 * Returns the original SQL that was passed into the system.
	--->
	<cffunction name="getOriginalQuery" access="public" returntype="string" output="no">

		<cfthrow type="ColdIgniter.LogicException" message="The class does not define getOriginalQuery().">
	</cffunction>

</cfcomponent>
