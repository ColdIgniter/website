<!---
 * Interface for transforming resources into arrays.
 *
 * This interface can be implemented by classes that need to transform
 * data into a standardized array format, such as for API responses.
 *
 * Difference: there are no interfaces; this component holds the methods,
 * which throw, and the transformers extend it.
--->
<cfcomponent output="no" hint="Interface for transforming resources into arrays">

	<!---
	 * Converts the resource to an array representation.
	 * This is overridden by child classes to define specific fields.
	 *
	 * @param resource The resource being transformed
	 *
	 * @return A map
	--->
	<cffunction name="toArray" access="public" returntype="any" output="no">
		<cfargument name="resource" type="any" required="yes">

		<cfthrow type="ColdIgniter.LogicException" message="The class does not define toArray().">
	</cffunction>

	<!---
	 * Transforms the given resource into an array.
	 *
	 * @param resource A map, a component or an empty string (null)
	 *
	 * @return A map
	--->
	<cffunction name="transform" access="public" returntype="any" output="no">
		<cfargument name="resource" type="any" required="no" default="">

		<cfthrow type="ColdIgniter.LogicException" message="The class does not define transform().">
	</cffunction>

	<!---
	 * Transforms a collection of resources using $this->transform() on each item.
	 *
	 * @param resources A list
	 *
	 * @return A list of maps
	--->
	<cffunction name="transformMany" access="public" returntype="any" output="no">
		<cfargument name="resources" type="array" required="yes">

		<cfthrow type="ColdIgniter.LogicException" message="The class does not define transformMany().">
	</cffunction>

</cfcomponent>
