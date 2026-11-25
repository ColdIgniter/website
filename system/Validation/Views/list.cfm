<cfif StructKeyExists(variables, "errors") AND StructCount(errors) GT 0>
	<div class="errors" role="alert">
		<ul>
		<cfloop collection="#errors#" item="__field">
			<cfoutput><li>#esc(errors[__field])#</li></cfoutput>
		</cfloop>
		</ul>
	</div>
</cfif>
