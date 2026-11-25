<!---
 * Adds the readable form of one value to a string buffer. Shared with
 * print_r(): the text is collected in one buffer, because joining it
 * with & copies the whole text for every element.
--->
<cffunction name="print_r_add" returntype="void" output="no" hint="Adds the readable form of one value to a string buffer">
	<cfargument name="buffer" type="any" required="yes">
	<cfargument name="value" type="any" required="yes">
	<cfargument name="indent" type="string" required="yes">
	<cfset var key = "">
	<cfset var i = 0>
	<cfset var lf = Chr(10)>

	<cfif IsSimpleValue(arguments.value)>
		<cfset arguments.buffer.append(JavaCast("string", arguments.value & ""))>

		<cfreturn>
	</cfif>

	<!--- a component is a struct too: its content is not walked --->
	<cfif IsObject(arguments.value) OR (NOT IsArray(arguments.value) AND NOT IsStruct(arguments.value))>
		<cfset arguments.buffer.append("[object]")>

		<cfreturn>
	</cfif>

	<cfset arguments.buffer.append(JavaCast("string", "Array" & lf & arguments.indent & "(" & lf))>

	<cfif IsArray(arguments.value)>
		<cfloop from="1" to="#ArrayLen(arguments.value)#" index="i">
			<cfset arguments.buffer.append(JavaCast("string", arguments.indent & "    [" & (i - 1) & "] => "))>
			<cfset print_r_add(arguments.buffer, arguments.value[i], arguments.indent & "        ")>
			<cfset arguments.buffer.append(lf)>
		</cfloop>
	<cfelse>
		<cfloop collection="#arguments.value#" item="key">
			<cfset arguments.buffer.append(JavaCast("string", arguments.indent & "    [" & key & "] => "))>
			<cfset print_r_add(arguments.buffer, arguments.value[key], arguments.indent & "        ")>
			<cfset arguments.buffer.append(lf)>
		</cfloop>
	</cfif>

	<cfset arguments.buffer.append(JavaCast("string", arguments.indent & ")" & lf))>
</cffunction>

<!---
 * Returns information about a variable in a human-readable form, as
 * print_r() of the original does with its second argument set to true.
 *
 * A list is shown with its positions counted from zero. Objects are
 * not supported: a component is shown as "[object]".
 *
 * Difference: the text is always returned, also when the second argument
 * is false or left out (nothing can be printed from here).
--->
<cffunction name="print_r" returntype="string" output="no" hint="Returns information about a variable in a human-readable form">
	<cfargument name="value" type="any" required="yes">
	<cfargument name="return_" type="boolean" required="no" default="true">
	<cfset var buffer = "">

	<cfif IsSimpleValue(arguments.value)>
		<cfreturn arguments.value>
	</cfif>

	<cfset buffer = CreateObject("java", "java.lang.StringBuffer").init()>
	<cfset print_r_add(buffer, arguments.value, "")>

	<cfreturn buffer.toString()>
</cffunction>
