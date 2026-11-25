<!---
 * Interface CastInterface
 *
 * There are no interfaces on 6.1, so this is a base component. A cast
 * extends it (BaseCast does), and it has to define the methods. The methods
 * here only throw.
 *
 * The original methods are static; a cast is called through static_() here,
 * the one object that stands in for the class.
 *
 * Difference: the original passes two arguments. The third, helper, is what
 * DataCaster passes to every handler (the original passes it to the Entity
 * casts too, where the extra argument is dropped): a cast may ignore it.
 * The params are a list (an ArrayNew(1)), and a null is an empty string.
--->
<cfcomponent output="no" hint="Expected behavior of a cast">

	<!---
	 * Takes a raw value from the database and returns the typed value.
	 *
	 * @param value  Data
	 * @param params Additional param
	 *
	 * @return mixed
	--->
	<cffunction name="get" access="public" returntype="any" output="no">
		<cfargument name="value" type="any" required="yes">
		<cfargument name="params" type="any" required="no" default="">
		<cfargument name="helper" type="any" required="no" default="">

		<cfthrow type="ColdIgniter.Entity.Exceptions.CastException" message="The cast does not define get().">
	</cffunction>

	<!---
	 * Takes a typed value and returns the value to store.
	 *
	 * @param value  Data
	 * @param params Additional param
	 *
	 * @return mixed
	--->
	<cffunction name="set" access="public" returntype="any" output="no">
		<cfargument name="value" type="any" required="yes">
		<cfargument name="params" type="any" required="no" default="">
		<cfargument name="helper" type="any" required="no" default="">

		<cfthrow type="ColdIgniter.Entity.Exceptions.CastException" message="The cast does not define set().">
	</cffunction>
</cfcomponent>
