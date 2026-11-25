<!---
 * Creates a component of this folder tree for the autoloader.
 * A component can only be created by a file in its own folder tree.
--->
<cfset arguments.component = CreateObject("component", arguments.class)>
