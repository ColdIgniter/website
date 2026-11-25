<!---
 * Class PagerRenderer
 *
 * This class is passed to the view that shows the pagination links. It
 * provides the data and the links for the current page.
 *
 * Difference: the original writes the same few lines in each method that
 * makes the URI of a page. pageURI() does it here, with the page number.
 *
 * Difference: null is an empty string. The details are a map (see array_()),
 * and links() returns a list of maps.
--->
<cfcomponent output="no" hint="Pager renderer for the pagination views">

	<!---
	 * First page number in the set of links to be displayed.
	--->
	<cfset this.first = 1>

	<!---
	 * Last page number in the set of links to be displayed.
	--->
	<cfset this.last = "">

	<!---
	 * Current page number.
	--->
	<cfset this.current = "">

	<!---
	 * Total number of items.
	--->
	<cfset this.total = "">

	<!---
	 * Total number of pages.
	--->
	<cfset this.pageCount = "">

	<!---
	 * URI base for pagination links.
	 *
	 * @var URI
	--->
	<cfset this.uri = "">

	<!---
	 * Segment number used for pagination (0 for the query variable).
	--->
	<cfset this.segment = 0>

	<!---
	 * Name of the query variable that holds the page number.
	--->
	<cfset this.pageSelector = "page">

	<!---
	 * Number of items per page.
	--->
	<cfset this.perPage = "">

	<!---
	 * Number of the first item on the current page.
	--->
	<cfset this.perPageStart = "">

	<!---
	 * Number of the last item on the current page.
	--->
	<cfset this.perPageEnd = "">

	<!---
	 * Constructor.
	 *
	 * @param details A map with the group details of the Pager
	--->
	<cffunction name="__construct" access="public" returntype="any" output="no">
		<cfargument name="details" type="any" required="yes">

		<cfset this.last = arguments.details["pageCount"]>
		<cfset this.current = arguments.details["currentPage"]>
		<cfset this.total = arguments.details["total"]>
		<cfset this.uri = arguments.details["uri"]>
		<cfset this.pageCount = arguments.details["pageCount"]>

		<cfif StructKeyExists(arguments.details, "segment")>
			<cfset this.segment = arguments.details["segment"]>
		</cfif>

		<cfif StructKeyExists(arguments.details, "pageSelector")>
			<cfset this.pageSelector = arguments.details["pageSelector"]>
		</cfif>

		<cfif StructKeyExists(arguments.details, "perPage")>
			<cfset this.perPage = arguments.details["perPage"]>
		</cfif>

		<cfset updatePerPages()>

		<cfreturn this>
	</cffunction>

	<!---
	 * Sets the total number of links that should appear on either
	 * side of the current page. Adjusts the first and last counts
	 * accordingly.
	 *
	 * @return PagerRenderer
	--->
	<cffunction name="setSurroundCount" access="public" returntype="any" output="no">
		<cfargument name="count" type="any" required="no" default="">

		<cfset updatePages(arguments.count)>

		<cfreturn this>
	</cffunction>

	<!---
	 * Checks to see if there is a "previous" page before our "first" page.
	--->
	<cffunction name="hasPrevious" access="public" returntype="boolean" output="no">
		<cfreturn this.first GT 1>
	</cffunction>

	<!---
	 * Returns a URL to the "previous" page. The previous page is NOT the
	 * page before the current page, but is the page just before the
	 * "first" page.
	 *
	 * @return A string, or an empty string for null
	--->
	<cffunction name="getPrevious" access="public" returntype="any" output="no">
		<cfif NOT hasPrevious()>
			<cfreturn "">
		</cfif>

		<cfreturn pageURI(this.first - 1)>
	</cffunction>

	<!---
	 * Checks to see if there is a "next" page after our "last" page.
	--->
	<cffunction name="hasNext" access="public" returntype="boolean" output="no">
		<cfreturn this.pageCount GT this.last>
	</cffunction>

	<!---
	 * Returns a URL to the "next" page. The next page is NOT the position
	 * after the current page, but is the page just after the "last" page.
	 *
	 * @return A string, or an empty string for null
	--->
	<cffunction name="getNext" access="public" returntype="any" output="no">
		<cfif NOT hasNext()>
			<cfreturn "">
		</cfif>

		<cfreturn pageURI(this.last + 1)>
	</cffunction>

	<!---
	 * Returns the URI of the first page.
	--->
	<cffunction name="getFirst" access="public" returntype="string" output="no">
		<cfreturn pageURI(1)>
	</cffunction>

	<!---
	 * Returns the URI of the last page.
	--->
	<cffunction name="getLast" access="public" returntype="string" output="no">
		<cfreturn pageURI(this.pageCount)>
	</cffunction>

	<!---
	 * Returns the URI of the current page.
	--->
	<cffunction name="getCurrent" access="public" returntype="string" output="no">
		<cfreturn pageURI(this.current)>
	</cffunction>

	<!---
	 * Returns a list of maps with the keys uri, title and active, one for
	 * each page from the first to the last of the set of links.
	 *
	 * @return list of maps
	--->
	<cffunction name="links" access="public" returntype="array" output="no">
		<cfset var links_ = ArrayNew(1)>
		<cfset var uri = this.uri.clone_()>
		<cfset var i = 0>

		<cfloop from="#this.first#" to="#this.last#" index="i">
			<cfif this.segment EQ 0>
				<cfset uri = uri.addQuery(this.pageSelector, i)>
			<cfelse>
				<cfset uri = uri.setSegment(this.segment, i)>
			</cfif>

			<cfset ArrayAppend(links_, array_("uri", static_("ColdIgniter\HTTP\URI").createURIString(uri.getScheme(), uri.getAuthority(), uri.getPath(), uri.getQuery(), uri.getFragment()), "title", i, "active", i EQ this.current))>
		</cfloop>

		<cfreturn links_>
	</cffunction>

	<!---
	 * Updates the first and last page numbers from the surround count.
	--->
	<cffunction name="updatePages" access="private" returntype="void" output="no">
		<cfargument name="count" type="any" required="no" default="">

		<cfif NOT is_null(arguments.count)>
			<cfif this.current - arguments.count GT 0>
				<cfset this.first = this.current - arguments.count>
			<cfelse>
				<cfset this.first = 1>
			</cfif>

			<cfif this.current + arguments.count LTE this.pageCount>
				<cfset this.last = this.current + arguments.count>
			<cfelse>
				<cfset this.last = this.pageCount>
			</cfif>
		</cfif>
	</cffunction>

	<!---
	 * Calculates the numbers of the first and the last item of the
	 * current page.
	--->
	<cffunction name="updatePerPages" access="private" returntype="void" output="no">
		<cfif NOT is_null(this.total) AND NOT is_null(this.perPage)>
			<!--- When the page is the last, perform a different calculation. --->
			<cfif this.last EQ this.current>
				<cfset this.perPageStart = this.perPage * (this.current - 1) + 1>
				<cfset this.perPageEnd = this.total>
			<cfelse>
				<cfif this.current EQ 1>
					<cfset this.perPageStart = 1>
				<cfelse>
					<cfset this.perPageStart = (this.perPage * this.current) - this.perPage + 1>
				</cfif>

				<cfset this.perPageEnd = this.perPage * this.current>
			</cfif>
		</cfif>
	</cffunction>

	<!---
	 * Checks to see if there is a page before the current page.
	--->
	<cffunction name="hasPreviousPage" access="public" returntype="boolean" output="no">
		<cfreturn this.current GT 1>
	</cffunction>

	<!---
	 * Returns a URL to the page before the current page.
	 *
	 * @return A string, or an empty string for null
	--->
	<cffunction name="getPreviousPage" access="public" returntype="any" output="no">
		<cfif NOT hasPreviousPage()>
			<cfreturn "">
		</cfif>

		<cfreturn pageURI(this.current - 1)>
	</cffunction>

	<!---
	 * Checks to see if there is a page after the current page.
	--->
	<cffunction name="hasNextPage" access="public" returntype="boolean" output="no">
		<cfreturn this.current LT this.last>
	</cffunction>

	<!---
	 * Returns a URL to the page after the current page.
	 *
	 * @return A string, or an empty string for null
	--->
	<cffunction name="getNextPage" access="public" returntype="any" output="no">
		<cfif NOT hasNextPage()>
			<cfreturn "">
		</cfif>

		<cfreturn pageURI(this.current + 1)>
	</cffunction>

	<!---
	 * Returns the number of the first page in the set of links.
	--->
	<cffunction name="getFirstPageNumber" access="public" returntype="numeric" output="no">
		<cfreturn this.first>
	</cffunction>

	<!---
	 * Returns the number of the current page.
	--->
	<cffunction name="getCurrentPageNumber" access="public" returntype="numeric" output="no">
		<cfreturn this.current>
	</cffunction>

	<!---
	 * Returns the number of the last page in the set of links.
	--->
	<cffunction name="getLastPageNumber" access="public" returntype="numeric" output="no">
		<cfreturn this.last>
	</cffunction>

	<!---
	 * Returns the total number of pages.
	--->
	<cffunction name="getPageCount" access="public" returntype="numeric" output="no">
		<cfreturn this.pageCount>
	</cffunction>

	<!---
	 * Returns the number of the page before the current page, or an empty
	 * string for null.
	--->
	<cffunction name="getPreviousPageNumber" access="public" returntype="any" output="no">
		<cfif this.current EQ 1>
			<cfreturn "">
		</cfif>

		<cfreturn this.current - 1>
	</cffunction>

	<!---
	 * Returns the number of the page after the current page, or an empty
	 * string for null.
	--->
	<cffunction name="getNextPageNumber" access="public" returntype="any" output="no">
		<cfif this.current EQ this.pageCount>
			<cfreturn "">
		</cfif>

		<cfreturn this.current + 1>
	</cffunction>

	<!---
	 * Returns the total number of items, or an empty string for null.
	--->
	<cffunction name="getTotal" access="public" returntype="any" output="no">
		<cfreturn this.total>
	</cffunction>

	<!---
	 * Returns the number of items per page, or an empty string for null.
	--->
	<cffunction name="getPerPage" access="public" returntype="any" output="no">
		<cfreturn this.perPage>
	</cffunction>

	<!---
	 * Returns the number of the first item on the current page, or an
	 * empty string for null.
	--->
	<cffunction name="getPerPageStart" access="public" returntype="any" output="no">
		<cfreturn this.perPageStart>
	</cffunction>

	<!---
	 * Returns the number of the last item on the current page, or an
	 * empty string for null.
	--->
	<cffunction name="getPerPageEnd" access="public" returntype="any" output="no">
		<cfreturn this.perPageEnd>
	</cffunction>

	<!---
	 * Makes the URI string of a page, on a copy of the URI.
	--->
	<cffunction name="pageURI" access="private" returntype="string" output="no">
		<cfargument name="page" type="any" required="yes">
		<cfset var uri = this.uri.clone_()>

		<cfif this.segment EQ 0>
			<cfset uri.addQuery(this.pageSelector, arguments.page)>
		<cfelse>
			<cfset uri.setSegment(this.segment, arguments.page)>
		</cfif>

		<cfreturn static_("ColdIgniter\HTTP\URI").createURIString(uri.getScheme(), uri.getAuthority(), uri.getPath(), uri.getQuery(), uri.getFragment())>
	</cffunction>

</cfcomponent>
