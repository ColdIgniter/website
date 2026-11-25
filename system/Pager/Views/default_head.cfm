<!--- Difference: every href goes through esc(..., "attr"). The original leaves it, because its URI percent-encodes the path; this URI does not yet. --->
<cfset pager.setSurroundCount(0)>
<cfoutput><cfif pager.hasPrevious()><link rel="prev" href="#esc(pager.getPrevious(), "attr")#">#Chr(10)#</cfif><link rel="canonical" href="#esc(pager.getCurrent(), "attr")#">#Chr(10)#<cfif pager.hasNext()><link rel="next" href="#esc(pager.getNext(), "attr")#">#Chr(10)#</cfif></cfoutput>
