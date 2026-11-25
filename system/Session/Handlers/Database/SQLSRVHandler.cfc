<!---
 * Session handler for SQLSRV
 *
 * Difference: the original has no handler for SQLSRV (Services::session()
 * supports MySQLi and Postgre only). This one is written for SQL Server
 * 2000 SP3, the only database here.
 *
 * Difference: the original extends DatabaseHandler. This class is in
 * another folder, so it is mixed in with parent (see the reference, "How
 * components are located").
 *
 * The table (the name is the savePath setting; the PRIMARY KEY is
 * (id, ip_address) when matchIP is true, as in the other platforms):
 *
 *     CREATE TABLE ci_sessions (
 *         id         varchar(128) NOT NULL PRIMARY KEY,
 *         ip_address varchar(45)  NOT NULL,
 *         timestamp  datetime     NOT NULL DEFAULT getdate(),
 *         data       text         NOT NULL
 *     )
 *     CREATE INDEX ci_sessions_timestamp ON ci_sessions (timestamp)
 *
 * Difference: the data column is text. SQL Server 2000 has no varchar(max),
 * and varchar holds 8000 characters at most. The data is kept as it is (no
 * base64 and no image), as the packet of a session is plain text. The
 * query of 6.1 puts the value in the statement as a text constant, so a
 * session larger than the limit of a statement fails (the write returns
 * false), and a data source that does not enable long text retrieval
 * cuts what it reads at 64000 characters.
 *
 * Difference: text and varchar are not Unicode, and the values go into the
 * statement as '...' constants, so a character outside the code page of
 * the database comes back as "?".
 *
 * Difference: there is no lock. The original of MySQLi and Postgre takes a
 * lock of the database (GET_LOCK, an advisory lock) in read() and keeps it
 * until close(). For SQL Server that is sp_getapplock with the owner
 * Session, which belongs to the connection, and 6.1 does not promise that
 * every query of a request runs on the same connection of the data source
 * outside a cftransaction: the lock could be taken on one connection and
 * never released (the connection goes back to the pool with the lock
 * held, and the next request that gets it waits for it), or released on
 * another one that does not hold it. The owner Transaction ends with the
 * statement, as a batch outside a transaction is its own transaction, so
 * inside one short statement it holds nothing. So the lock of BaseHandler
 * is used, which holds nothing: two requests that write the same session
 * at the same time make a lost update (the last write wins), as
 * FileHandler does.
--->
<cfcomponent output="no" parent="ColdIgniter\Session\Handlers\DatabaseHandler" hint="Session handler for SQLSRV">

	<!---
	 * The SQL that gives the time now, for the timestamp column.
	--->
	<cffunction name="nowSql" access="private" returntype="string" output="no">

		<cfreturn "getdate()">
	</cffunction>

	<!---
	 * Cleans up expired sessions.
	 *
	 * Difference: SQL Server 2000 has no INTERVAL, DATEADD() takes it away.
	 *
	 * @param max_lifetime Sessions that have not updated
	 *                     for the last max_lifetime seconds will be removed.
	 *
	 * @return false|int Returns the number of deleted sessions on success, or false on failure.
	--->
	<cffunction name="gc" access="public" returntype="any" output="no">
		<cfargument name="max_lifetime" type="numeric" required="yes">

		<cfif identical_(this.db.table(this.table).where("timestamp <", "DATEADD(second, -" & Int(arguments.max_lifetime) & ", getdate())", false).delete(), "false")>
			<cfreturn fail()>
		</cfif>

		<cfreturn 1>
	</cffunction>

</cfcomponent>
