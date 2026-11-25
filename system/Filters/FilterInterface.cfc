<!---
 * Filter interface
 *
 * There are no interfaces on 6.1, so this is a base component. A filter of
 * the system extends it (extends="FilterInterface") and a filter of the
 * application names it as its parent
 * (parent="ColdIgniter\Filters\FilterInterface"). Filters::createFilter
 * checks it with instanceof_().
 *
 * The methods here only throw; a filter has to define both of them.
--->
<cfcomponent output="no" hint="Filter interface">

	<!---
	 * Do whatever processing this filter needs to do.
	 * By default it should not return anything during
	 * normal execution. However, when an abnormal state
	 * is found, it should return an instance of
	 * ColdIgniter\HTTP\Response. If it does, script
	 * execution will end and that Response will be
	 * sent back to the client, allowing for error pages,
	 * redirects, etc.
	 *
	 * @param request_   The request
	 * @param arguments_ An empty string, or a list of strings
	 *
	 * @return A request replaces the request for the filters and the
	 *         controller that follow. A response stops the other filters and
	 *         the controller and is sent. An empty string or nothing carries
	 *         on. Any other non-empty string stops the other filters but the
	 *         controller still runs, as upstream. Difference: true, false,
	 *         yes, no and numbers, which the engine cannot tell from the
	 *         literals, carry on like an empty result.
	--->
	<cffunction name="before" access="public" returntype="any" output="no">
		<cfargument name="request_" type="any" required="yes">
		<cfargument name="arguments_" type="any" required="no" default="">

		<cfthrow type="ColdIgniter.Filters.Exceptions.FilterException" message="The filter does not define before().">
	</cffunction>

	<!---
	 * Allows After filters to inspect and modify the response
	 * object as needed. This method does not allow any way
	 * to stop execution of other after filters, short of
	 * throwing an Exception or Error.
	 *
	 * @param request_   The request
	 * @param response   The response
	 * @param arguments_ An empty string, or a list of strings
	 *
	 * @return A response to use, or anything else to carry on.
	--->
	<cffunction name="after" access="public" returntype="any" output="no">
		<cfargument name="request_" type="any" required="yes">
		<cfargument name="response" type="any" required="yes">
		<cfargument name="arguments_" type="any" required="no" default="">

		<cfthrow type="ColdIgniter.Filters.Exceptions.FilterException" message="The filter does not define after().">
	</cffunction>

</cfcomponent>
