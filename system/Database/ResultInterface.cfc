<!---
 * Expected behavior of a database result.
 *
 * There are no interfaces on 6.1, so this is a base component. BaseResult
 * extends it, and the methods here only throw; a class that extends it
 * has to define them.
--->
<cfcomponent output="no" hint="Expected behavior of a database result">

	<!---
	 * Retrieve the results of the query. Typically an array of
	 * individual data rows, which can be either an 'array', an
	 * 'object', or a custom class name.
	--->
	<cffunction name="getResult" access="public" returntype="any" output="no">
		<cfargument name="type" type="string" required="no" default="object">

		<cfthrow type="ColdIgniter.LogicException" message="The class does not define getResult().">
	</cffunction>

	<!---
	 * Returns the results as an array of custom objects.
	--->
	<cffunction name="getCustomResultObject" access="public" returntype="any" output="no">
		<cfargument name="className" type="string" required="yes">

		<cfthrow type="ColdIgniter.LogicException" message="The class does not define getCustomResultObject().">
	</cffunction>

	<!---
	 * Returns the results as an array of arrays.
	 *
	 * If no results, an empty array is returned.
	--->
	<cffunction name="getResultArray" access="public" returntype="array" output="no">

		<cfthrow type="ColdIgniter.LogicException" message="The class does not define getResultArray().">
	</cffunction>

	<!---
	 * Returns the results as an array of objects.
	 *
	 * If no results, an empty array is returned.
	--->
	<cffunction name="getResultObject" access="public" returntype="array" output="no">

		<cfthrow type="ColdIgniter.LogicException" message="The class does not define getResultObject().">
	</cffunction>

	<!---
	 * Wrapper object to return a row as either an array, an object, or
	 * a custom class.
	 *
	 * If the row doesn't exist, returns null (an empty string).
	--->
	<cffunction name="getRow" access="public" returntype="any" output="no">
		<cfargument name="n" type="any" required="no" default="0">
		<cfargument name="type" type="string" required="no" default="object">

		<cfthrow type="ColdIgniter.LogicException" message="The class does not define getRow().">
	</cffunction>

	<!---
	 * Returns a row as a custom class instance.
	 *
	 * If the row doesn't exist, returns null (an empty string).
	--->
	<cffunction name="getCustomRowObject" access="public" returntype="any" output="no">
		<cfargument name="n" type="numeric" required="yes">
		<cfargument name="className" type="string" required="yes">

		<cfthrow type="ColdIgniter.LogicException" message="The class does not define getCustomRowObject().">
	</cffunction>

	<!---
	 * Returns a single row from the results as an array.
	 *
	 * If row doesn't exist, returns null (an empty string).
	--->
	<cffunction name="getRowArray" access="public" returntype="any" output="no">
		<cfargument name="n" type="numeric" required="no" default="0">

		<cfthrow type="ColdIgniter.LogicException" message="The class does not define getRowArray().">
	</cffunction>

	<!---
	 * Returns a single row from the results as an object.
	 *
	 * If row doesn't exist, returns null (an empty string).
	--->
	<cffunction name="getRowObject" access="public" returntype="any" output="no">
		<cfargument name="n" type="numeric" required="no" default="0">

		<cfthrow type="ColdIgniter.LogicException" message="The class does not define getRowObject().">
	</cffunction>

	<!---
	 * Assigns an item into a particular column slot.
	--->
	<cffunction name="setRow" access="public" returntype="void" output="no">
		<cfargument name="key" type="any" required="yes">
		<cfargument name="value" type="any" required="no" default="">

		<cfthrow type="ColdIgniter.LogicException" message="The class does not define setRow().">
	</cffunction>

	<!---
	 * Returns the "first" row of the current results.
	--->
	<cffunction name="getFirstRow" access="public" returntype="any" output="no">
		<cfargument name="type" type="string" required="no" default="object">

		<cfthrow type="ColdIgniter.LogicException" message="The class does not define getFirstRow().">
	</cffunction>

	<!---
	 * Returns the "last" row of the current results.
	--->
	<cffunction name="getLastRow" access="public" returntype="any" output="no">
		<cfargument name="type" type="string" required="no" default="object">

		<cfthrow type="ColdIgniter.LogicException" message="The class does not define getLastRow().">
	</cffunction>

	<!---
	 * Returns the "next" row of the current results.
	--->
	<cffunction name="getNextRow" access="public" returntype="any" output="no">
		<cfargument name="type" type="string" required="no" default="object">

		<cfthrow type="ColdIgniter.LogicException" message="The class does not define getNextRow().">
	</cffunction>

	<!---
	 * Returns the "previous" row of the current results.
	--->
	<cffunction name="getPreviousRow" access="public" returntype="any" output="no">
		<cfargument name="type" type="string" required="no" default="object">

		<cfthrow type="ColdIgniter.LogicException" message="The class does not define getPreviousRow().">
	</cffunction>

	<!---
	 * Returns number of rows in the result set.
	--->
	<cffunction name="getNumRows" access="public" returntype="numeric" output="no">

		<cfthrow type="ColdIgniter.LogicException" message="The class does not define getNumRows().">
	</cffunction>

	<!---
	 * Returns an unbuffered row and move the pointer to the next row.
	--->
	<cffunction name="getUnbufferedRow" access="public" returntype="any" output="no">
		<cfargument name="type" type="string" required="no" default="object">

		<cfthrow type="ColdIgniter.LogicException" message="The class does not define getUnbufferedRow().">
	</cffunction>

	<!---
	 * Gets the number of fields in the result set.
	--->
	<cffunction name="getFieldCount" access="public" returntype="numeric" output="no">

		<cfthrow type="ColdIgniter.LogicException" message="The class does not define getFieldCount().">
	</cffunction>

	<!---
	 * Generates an array of column names in the result set.
	--->
	<cffunction name="getFieldNames" access="public" returntype="array" output="no">

		<cfthrow type="ColdIgniter.LogicException" message="The class does not define getFieldNames().">
	</cffunction>

	<!---
	 * Generates an array of objects representing field meta-data.
	--->
	<cffunction name="getFieldData" access="public" returntype="array" output="no">

		<cfthrow type="ColdIgniter.LogicException" message="The class does not define getFieldData().">
	</cffunction>

	<!---
	 * Frees the current result.
	--->
	<cffunction name="freeResult" access="public" returntype="void" output="no">

		<cfthrow type="ColdIgniter.LogicException" message="The class does not define freeResult().">
	</cffunction>

	<!---
	 * Moves the internal pointer to the desired offset. This is called
	 * internally before fetching results to make sure the result set
	 * starts at zero.
	--->
	<cffunction name="dataSeek" access="public" returntype="any" output="no">
		<cfargument name="n" type="numeric" required="no" default="0">

		<cfthrow type="ColdIgniter.LogicException" message="The class does not define dataSeek().">
	</cffunction>

</cfcomponent>
