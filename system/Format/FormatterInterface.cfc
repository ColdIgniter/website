<!---
 * Formatter interface
 *
 * Difference: there are no interfaces; this component holds the method,
 * which throws, and the formatters extend it.
--->
<cfcomponent output="no" hint="Formatter interface">

	<!---
	 * Takes the given data and formats it.
	 *
	 * @param data The data to format
	 *
	 * @return The formatted text
	--->
	<cffunction name="format" access="public" returntype="any" output="no">
		<cfargument name="data" type="any" required="yes">

		<cfthrow type="ColdIgniter.LogicException" message="The class does not define format().">
	</cffunction>

</cfcomponent>
