<!---
 * The environment testing is reserved for unit testing. It has special
 * conditions built into the framework at various places to assist with that.
 * You can't use it for your development.
--->

<!---
 |--------------------------------------------------------------------------
 | ERROR DISPLAY
 |--------------------------------------------------------------------------
 | In development, we want to show as many errors as possible to help
 | make sure they don't make it to production. And save us hours of
 | painful debugging.
 |
 | Not ported yet: error_reporting, CFML has no error levels.
--->
<cfset ini_set("display_errors", "1")>

<!---
 |--------------------------------------------------------------------------
 | DEBUG BACKTRACES
 |--------------------------------------------------------------------------
 | If true, this constant will tell the error screens to display debug
 | backtraces along with the other error information. If you would
 | prefer to not see this, set this value to false.
--->
<cfset defined("SHOW_DEBUG_BACKTRACE") OR define("SHOW_DEBUG_BACKTRACE", true)>

<!---
 |--------------------------------------------------------------------------
 | DEBUG MODE
 |--------------------------------------------------------------------------
 | Debug mode is an experimental flag that can allow changes throughout
 | the system. It's not widely used currently, and may not survive
 | release of the framework.
--->
<cfset defined("CI_DEBUG") OR define("CI_DEBUG", true)>
