<!---
 * Expected behavior of a Pager
 *
 * There are no interfaces on 6.1, so this is a base component. A pager
 * extends it (Pager does), and it has to define the methods. The methods
 * here only throw.
 *
 * Difference: the original types are not declared (null is an empty string).
--->
<cfcomponent output="no" hint="Expected behavior of a Pager">

	<!---
	 * Handles creating and displaying the
	 * pagination links and data.
	 *
	 * @param template The output template alias to render.
	--->
	<cffunction name="links" access="public" returntype="string" output="no">
		<cfargument name="group" type="string" required="no" default="default">
		<cfargument name="template" type="string" required="no" default="default">

		<cfthrow type="ColdIgniter.Pager.Exceptions.PagerException" message="The pager does not define links().">
	</cffunction>

	<!---
	 * Creates simple Next/Previous links, instead of full pagination.
	--->
	<cffunction name="simpleLinks" access="public" returntype="string" output="no">
		<cfargument name="group" type="string" required="no" default="default">
		<cfargument name="template" type="string" required="no" default="default">

		<cfthrow type="ColdIgniter.Pager.Exceptions.PagerException" message="The pager does not define simpleLinks().">
	</cffunction>

	<!---
	 * Allows for a simple, manual, form of pagination where all of the data
	 * is provided by the user.
	 *
	 * @param template The output template alias to render.
	--->
	<cffunction name="makeLinks" access="public" returntype="string" output="no">
		<cfargument name="page" type="any" required="yes">
		<cfargument name="perPage" type="any" required="yes">
		<cfargument name="total" type="any" required="yes">
		<cfargument name="template" type="string" required="no" default="default">

		<cfthrow type="ColdIgniter.Pager.Exceptions.PagerException" message="The pager does not define makeLinks().">
	</cffunction>

	<!---
	 * Stores a set of pagination data for later display. Most commonly used
	 * by the model to automate the process.
	 *
	 * @return Pager
	--->
	<cffunction name="store" access="public" returntype="any" output="no">
		<cfargument name="group" type="string" required="yes">
		<cfargument name="page" type="any" required="yes">
		<cfargument name="perPage" type="any" required="yes">
		<cfargument name="total" type="any" required="yes">

		<cfthrow type="ColdIgniter.Pager.Exceptions.PagerException" message="The pager does not define store().">
	</cffunction>

	<!---
	 * Sets the path that an aliased group of links will use.
	 *
	 * @return Pager
	--->
	<cffunction name="setPath" access="public" returntype="any" output="no">
		<cfargument name="path" type="string" required="yes">
		<cfargument name="group" type="string" required="no" default="default">

		<cfthrow type="ColdIgniter.Pager.Exceptions.PagerException" message="The pager does not define setPath().">
	</cffunction>

	<!---
	 * Returns the total number of pages.
	--->
	<cffunction name="getPageCount" access="public" returntype="numeric" output="no">
		<cfargument name="group" type="string" required="no" default="default">

		<cfthrow type="ColdIgniter.Pager.Exceptions.PagerException" message="The pager does not define getPageCount().">
	</cffunction>

	<!---
	 * Returns the number of the current page of results.
	--->
	<cffunction name="getCurrentPage" access="public" returntype="numeric" output="no">
		<cfargument name="group" type="string" required="no" default="default">

		<cfthrow type="ColdIgniter.Pager.Exceptions.PagerException" message="The pager does not define getCurrentPage().">
	</cffunction>

	<!---
	 * Returns the URI for a specific page for the specified group.
	 *
	 * @return A string, or a URI if returnObject is true
	--->
	<cffunction name="getPageURI" access="public" returntype="any" output="no">
		<cfargument name="page" type="any" required="no" default="">
		<cfargument name="group" type="string" required="no" default="default">
		<cfargument name="returnObject" type="boolean" required="no" default="false">

		<cfthrow type="ColdIgniter.Pager.Exceptions.PagerException" message="The pager does not define getPageURI().">
	</cffunction>

	<!---
	 * Tells whether this group of results has any more pages of results.
	--->
	<cffunction name="hasMore" access="public" returntype="boolean" output="no">
		<cfargument name="group" type="string" required="no" default="default">

		<cfthrow type="ColdIgniter.Pager.Exceptions.PagerException" message="The pager does not define hasMore().">
	</cffunction>

	<!---
	 * Returns the first page.
	--->
	<cffunction name="getFirstPage" access="public" returntype="any" output="no">
		<cfargument name="group" type="string" required="no" default="default">

		<cfthrow type="ColdIgniter.Pager.Exceptions.PagerException" message="The pager does not define getFirstPage().">
	</cffunction>

	<!---
	 * Returns the last page, if we have a total that we can calculate with.
	 *
	 * @return The page, or an empty string for null
	--->
	<cffunction name="getLastPage" access="public" returntype="any" output="no">
		<cfargument name="group" type="string" required="no" default="default">

		<cfthrow type="ColdIgniter.Pager.Exceptions.PagerException" message="The pager does not define getLastPage().">
	</cffunction>

	<!---
	 * Returns the full URI to the next page of results, or null (an empty string).
	--->
	<cffunction name="getNextPageURI" access="public" returntype="any" output="no">
		<cfargument name="group" type="string" required="no" default="default">

		<cfthrow type="ColdIgniter.Pager.Exceptions.PagerException" message="The pager does not define getNextPageURI().">
	</cffunction>

	<!---
	 * Returns the full URL to the previous page of results, or null (an empty string).
	--->
	<cffunction name="getPreviousPageURI" access="public" returntype="any" output="no">
		<cfargument name="group" type="string" required="no" default="default">

		<cfthrow type="ColdIgniter.Pager.Exceptions.PagerException" message="The pager does not define getPreviousPageURI().">
	</cffunction>

	<!---
	 * Returns the number of results per page that should be shown.
	--->
	<cffunction name="getPerPage" access="public" returntype="numeric" output="no">
		<cfargument name="group" type="string" required="no" default="default">

		<cfthrow type="ColdIgniter.Pager.Exceptions.PagerException" message="The pager does not define getPerPage().">
	</cffunction>

	<!---
	 * Returns an array with details about the results, including
	 * pagination and the URIs of the neighbouring pages. Does not include
	 * the actual data. This data is suitable for adding
	 * a 'pagination' section to the response of an API.
	 *
	 * @return A map (see array_())
	--->
	<cffunction name="getDetails" access="public" returntype="any" output="no">
		<cfargument name="group" type="string" required="no" default="default">

		<cfthrow type="ColdIgniter.Pager.Exceptions.PagerException" message="The pager does not define getDetails().">
	</cffunction>

</cfcomponent>
