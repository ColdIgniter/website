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
 | the system. This will control whether Kint is loaded, and a few other
 | items. It can always be used within your own application too.
--->
<cfset defined("CI_DEBUG") OR define("CI_DEBUG", true)>
