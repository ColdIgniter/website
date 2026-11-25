<!---
 |--------------------------------------------------------------------------
 | ERROR DISPLAY
 |--------------------------------------------------------------------------
 | Don't show ANY in production environments. Instead, let the system catch
 | it and display a generic error message.
 |
 | Not ported yet: error_reporting, CFML has no error levels.
--->
<cfset ini_set("display_errors", "0")>

<!---
 |--------------------------------------------------------------------------
 | DEBUG MODE
 |--------------------------------------------------------------------------
 | Debug mode is an experimental flag that can allow changes throughout
 | the system. It's not widely used currently, and may not survive
 | release of the framework.
--->
<cfset defined("CI_DEBUG") OR define("CI_DEBUG", false)>
