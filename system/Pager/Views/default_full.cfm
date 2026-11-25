<!--- Difference: every href goes through esc(..., "attr"). The original leaves it, because its URI percent-encodes the path; this URI does not yet. --->
<cfset pager.setSurroundCount(2)>
<cfset links_ = pager.links()>
<cfoutput>
<nav aria-label="#lang("Pager.pageNavigation")#">
	<ul class="pagination">
		<cfif pager.hasPrevious()>
			<li>
				<a href="#esc(pager.getFirst(), "attr")#" aria-label="#lang("Pager.first")#">
					<span aria-hidden="true">#lang("Pager.first")#</span>
				</a>
			</li>
			<li>
				<a href="#esc(pager.getPrevious(), "attr")#" aria-label="#lang("Pager.previous")#">
					<span aria-hidden="true">#lang("Pager.previous")#</span>
				</a>
			</li>
		</cfif>

		<cfloop from="1" to="#ArrayLen(links_)#" index="i_">
			<li <cfif links_[i_]["active"]>class="active"</cfif>>
				<a href="#esc(links_[i_]["uri"], "attr")#">
					#links_[i_]["title"]#
				</a>
			</li>
		</cfloop>

		<cfif pager.hasNext()>
			<li>
				<a href="#esc(pager.getNext(), "attr")#" aria-label="#lang("Pager.next")#">
					<span aria-hidden="true">#lang("Pager.next")#</span>
				</a>
			</li>
			<li>
				<a href="#esc(pager.getLast(), "attr")#" aria-label="#lang("Pager.last")#">
					<span aria-hidden="true">#lang("Pager.last")#</span>
				</a>
			</li>
		</cfif>
	</ul>
</nav>
</cfoutput>
