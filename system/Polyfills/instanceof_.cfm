<!---
 * Stands in for the instanceof operator: instanceof_(value, class).
 *
 * There are no interfaces and a class cannot be named across folder trees,
 * so the class is matched by its short name (the part after the last
 * backslash) against the component, the components it extends and the
 * component named in its "parent" attribute. The interfaces of the original
 * that have no component are matched by the class that stands in for them:
 * "ResponseInterface" is a Response and "RequestInterface" is a Request.
 * A value that is not a component is never an instance.
 * When the walk finds no match, each component named in a "parent"
 * attribute is checked the same way (through static_()), so the chain of
 * the parent is followed too; a match costs nothing more. The answer of
 * that pass is kept for the request in request.ColdIgniter.instanceofs
 * (by the file path of the class of the value and the wanted class), and the parents
 * already looked into are passed on in the third argument, so a parent
 * that names itself or a loop of parents ends.
 *
 * Difference: two classes with the same short name in different folders
 * cannot be told apart.
--->
<cffunction name="instanceof_" returntype="boolean" output="no" hint="Finds whether an object is an instance of a class">
	<cfargument name="value" type="any" required="yes">
	<cfargument name="class" type="string" required="yes">
	<cfargument name="seen" type="string" required="no" default="" hint="The parents already looked into (set by the function itself)">
	<cfset var wanted = ListLast(arguments.class, "\")>
	<cfset var meta = "">
	<cfset var parents = "">
	<cfset var parent = "">
	<cfset var top = "">
	<cfset var key = "">
	<cfset var kept = false>
	<cfset var seen_ = "">

	<cfif NOT IsObject(arguments.value)>
		<cfreturn false>
	</cfif>

	<cfif Compare(wanted, "ResponseInterface") EQ 0>
		<cfset wanted = "Response">
	<cfelseif Compare(wanted, "RequestInterface") EQ 0>
		<cfset wanted = "Request">
	</cfif>

	<cfset meta = GetMetaData(arguments.value)>

	<cfloop condition="IsStruct(meta)">
		<cfif IsSimpleValue(top)>
			<cfset top = meta>
		</cfif>

		<cfif StructKeyExists(meta, "name") AND Compare(ListLast(meta.name, "."), wanted) EQ 0>
			<cfreturn true>
		</cfif>

		<cfif StructKeyExists(meta, "parent") AND Compare(ListLast(meta.parent, "\"), wanted) EQ 0>
			<cfreturn true>
		</cfif>

		<!--- a parent that did not match is looked into after the walk, as it has a chain of its own --->
		<cfif StructKeyExists(meta, "parent")>
			<cfset parents = ListAppend(parents, meta.parent)>
		</cfif>

		<cfif NOT StructKeyExists(meta, "extends")>
			<cfbreak>
		</cfif>

		<cfset meta = meta.extends>
	</cfloop>

	<cfif parents EQ "">
		<cfreturn false>
	</cfif>

	<!--- the answer of the parents is kept for the request, by the class of the value and the wanted class (only a complete walk, one that began with nothing seen, is kept) --->
	<!--- the path, as the name is relative to the nearest autoload.cfm: app/Config/Filters and system/Config/Filters are both Config.Filters --->
	<cfif StructKeyExists(top, "path")>
		<cfset key = top.path & "|" & wanted>
	<cfelse>
		<cfset key = top.name & "|" & wanted>
	</cfif>

	<cfif arguments.seen EQ "">
		<cfif StructKeyExists(request.ColdIgniter.instanceofs, key)>
			<cfreturn request.ColdIgniter.instanceofs[key]>
		</cfif>

		<cfset kept = true>
	</cfif>

	<cfset seen_ = ListAppend(arguments.seen, parents)>

	<cfloop list="#parents#" index="parent">
		<cfif NOT ListFind(arguments.seen, parent)>
			<cfif instanceof_(static_(parent), arguments.class, seen_)>
				<cfif kept>
					<cfset request.ColdIgniter.instanceofs[key] = true>
				</cfif>

				<cfreturn true>
			</cfif>
		</cfif>
	</cfloop>

	<cfif kept>
		<cfset request.ColdIgniter.instanceofs[key] = false>
	</cfif>

	<cfreturn false>
</cffunction>
