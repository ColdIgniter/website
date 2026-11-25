<!--- Difference: every href goes through esc(..., "attr"). The original leaves it, because its URI percent-encodes the path; this URI does not yet. --->
<cfset pager.setSurroundCount(0)>
<cfset previous_ = pager.getPrevious()>
<cfset next_ = pager.getNext()>
<cfif is_null(previous_)>
	<cfset previous_ = "##">
</cfif>
<cfif is_null(next_)>
	<cfset next_ = "##">
</cfif>
<cfoutput>
<nav>
	<ul class="pager">
		<li <cfif NOT pager.hasPrevious()>class="disabled"</cfif>>
			<a href="#esc(previous_, "attr")#" aria-label="#lang("Pager.previous")#">
				<span aria-hidden="true">#lang("Pager.newer")#</span>
			</a>
		</li>
		<li <cfif NOT pager.hasNext()>class="disabled"</cfif>>
			<a href="#esc(next_, "attr")#" aria-label="#lang("Pager.next")#">
				<span aria-hidden="true">#lang("Pager.older")#</span>
			</a>
		</li>
	</ul>
</nav>
</cfoutput>
