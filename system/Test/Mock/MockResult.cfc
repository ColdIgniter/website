<!---
 * Difference: the original extends BaseResult. This class is in another
 * folder, so it is mixed in with parent (see the reference, "How
 * components are located").
 *
 * Difference: fetchObject() returns an empty map (see array_()) for the
 * class stdClass, as there is no stdClass, and an object of the class
 * otherwise.
--->
<cfcomponent output="no" parent="ColdIgniter\Database\BaseResult" hint="A result for the mock connection">

	<cffunction name="getFieldCount" access="public" returntype="numeric" output="no">
		<cfreturn 0>
	</cffunction>

	<!---
	 * @return array{}
	--->
	<cffunction name="getFieldNames" access="public" returntype="array" output="no">
		<cfreturn ArrayNew(1)>
	</cffunction>

	<!---
	 * @return array{}
	--->
	<cffunction name="getFieldData" access="public" returntype="array" output="no">
		<cfreturn ArrayNew(1)>
	</cffunction>

	<cffunction name="freeResult" access="public" returntype="void" output="no">
	</cffunction>

	<!---
	 * @return true
	--->
	<cffunction name="dataSeek" access="public" returntype="any" output="no">
		<cfargument name="n" type="numeric" required="no" default="0">

		<cfreturn true>
	</cffunction>

	<!---
	 * @return array{}
	--->
	<cffunction name="fetchAssoc" access="private" returntype="any" output="no">
		<cfreturn array_()>
	</cffunction>

	<!---
	 * @return object
	--->
	<cffunction name="fetchObject" access="private" returntype="any" output="no">
		<cfargument name="className" type="string" required="no" default="">

		<cfif Len(arguments.className) EQ 0 OR Compare(arguments.className, "stdClass") EQ 0>
			<cfreturn array_()>
		</cfif>

		<cfreturn new_(arguments.className)>
	</cffunction>

	<cffunction name="getNumRows" access="public" returntype="numeric" output="no">
		<cfreturn 0>
	</cffunction>

</cfcomponent>
