# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Icinga-/Nagios-Plugin "check_hp_procurve.pl"                        #
# Copyright (c) 2012  Juergen Edelbluth, www.jued.de                  #
# This program is licensed under the GNU General Public License v3.   #
# This program comes with ABSOLUTELY NO WARRANTY.                     #
# This is free software, and you are welcome to redistribute it       #
# under certain conditions; see LICENSE.txt for details.              #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

Requirements
============

* Net::SNMP
* Getopt::Long


-----------------------------------------------------------------------------------------------

Usage
=====

	Command line arguments:
	     -H <HostAddress>
	     [-C <CommunityString>]
	     -T <TestName>
	     -o <ValueForOK>
	     [-no]
	     -w <ValueForWarning>
	     [-nw]
	     -c <ValueForCritical>
	     [-nc]
	     [-v]
	     [-h]
	     [-t <timeout_sec>]
	     [-p <Port>]
	     [-f <StateOnFail>]
	     [-u <StateOnUnknown>]
	     [-1810G]
	
	Parameters:
	    -h                       Show help and exit with status UNKNOWN
	    -H <HostAddress>         The IP address or the host name of the switch
	    -C <CommunityString>     The SNMP community string (default: public) [optional]
	    -T <TestName>            The Test to execute. See listing below.
	    -o <ValueForOK>          Regular expression to identify a result that is considered to be OK
	    -w <ValueForWarning>     Regular expression to identify a result that is considered to be a WARNING
	    -c <ValueForCritical>    Regular expression to identify a result that is considered to be a CRITICAL
	    -t <Timeout_Secs>        Timeout in seconds. From 1 to 60. (default: 5) [optional]
	    -p <Port>                SNMP port of the switch. (default: 161) [optional]
	    -f <StateOnFail>         Status (OK, WARNING, CRITICAL, UNKNOWN) to report when SNMP query failed (default: UNKNOWN) [optional]
	    -u <StateOnUnknown>      Status (OK, WARNING, CRITICAL, UNKNOWN) to report when no result rule matched (default: UNKNOWN) [optional]
	    -1810G                   Traffic counting for 1810G (EXPERIMENTAL) (not implemented yet)
	    -v                       Verbose output
	    
	Negation of -c -w -o:
	    You might want to negate the meaning of a -c -w or -o regex, so that the condition is fulfilled when the regex
	    does not match the query result.
	    -no                      Negate -o regex
	    -nw                      Negate -w regex
	    -nc                      Negate -c regex 
	
	Additional parameters, depending on test to execute:
	    -i <InterfaceNumber>     Interface number (switch port from 1..max)
	
	There are following Tests (-T):
		sysDesc                  Get the switch system description
		sysUptime                Get the switch uptime
		sysName                  Get the switch system name
		sysLocation              Get the switch location
		sysContact               Get the contact name for the switch
		portStatus               Get the operative port status (up/down). Needs parameter -i.
		portAdminStatus          Get the administrative port status (up/down). Needs parameter -i.
		portSpeed                Get the Port Speed in Bits per Second. Needs parameter -i.
		                         0 = not connected, 10000000 = 10 MBit/s, 100000000 = 100 MBit/s, 1000000000 = 1000 MBit/s
		portType                 Get the Port type. Needs paramenter -i.
		                         possible return values: GigabitEthernet, FastEthernet, other or the Type ID.
		portDesc                 Port Description. Needs parameter -i.
		portInBytes              Get the incoming bytes on this port. Needs parameter -i.
		portOutBytes             Get the incoming bytes on this port. Needs parameter -i.
		portInErrors             Get number of incoming errors on this port. Needs parameter -i.
		portOutErrors            Get number of outgoing errors on this port. Needs parameter -i.
		portMTU                  Get the MTU of this port. Needs parameter -i.
	
	Configuration proposals: 
	+-----------------------+-----------------------+-----------------------+-----------------------+-----------------------+-----------------------+
	| Test (-t)             | OK-Value (-o)         | Warning-Value (-w)    | Critical-Value (-c)   | On SNMP Fail (-f)     | On Unknown (-u)       |
	+-----------------------+-----------------------+-----------------------+-----------------------+-----------------------+-----------------------|
	| sysDesc               | <empty>               | "/^$/"                | <empty>               | CRITICAL              | OK                    |
	| sysUptime             | <empty>               | <empty>               | <empty>               | CRITICAL              | OK                    |
	| sysName               | <empty>               | "/^$/"                | <empty>               | CRITICAL              | OK                    |
	| sysLocation           | <empty>               | "/^$/"                | <empty>               | CRITICAL              | OK                    |
	| sysContact            | <empty>               | "/^$/"                | <empty>               | CRITICAL              | OK                    |
	| portStatus            | "/^UP$/"              | <empty>               | "/^DOWN$/"            | CRITICAL              | CRITICAL              |
	| portAdminStatus       | "/^UP$/"              | "/^DOWN$/"            | <empty>               | CRITICAL              | CRITICAL              |
	| portSpeed             | "/^1([0]{8,9})$/"     | "/^1([0]{7,7})$/"     | <empty>               | CRITICAL              | WARNING               |
	| portType              | <empty>               | <empty>               | <empty>               | CRITICAL              | OK                    |
	| portDesc              | <empty>               | <empty>               | <empty>               | CRITICAL              | OK                    |
	| portInBytes           | <empty>               | <empty>               | <empty>               | CRITICAL              | OK                    |
	| portOutBytes          | <empty>               | <empty>               | <empty>               | CRITICAL              | OK                    |
	| portInErrors          | <empty>               | "/^(^(0))$/" (-nw)    | <empty>               | CRITICAL              | OK                    |
	| portOutErrors         | <empty>               | "/^(^(0))$/" (-nw)    | <empty>               | CRITICAL              | OK                    |
	| portMTU               | <empty>               | <empty>               | <empty>               | CRITICAL              | OK                    |
	+-----------------------+-----------------------+-----------------------+-----------------------+-----------------------+-----------------------+
	
	WARNING: portInBytes, portOutBytes, portInErrors, portOutErrors seems to end at 2147483647 and stops counting there.
	
	Traffic measuring mode for 1810G (-1810G):
	    WARNING! This is a highly experimental feature! Be advised, it deletes the switch counters!
	    When -1810G is set, no other measurements or tests can be performed.
	    --- The feature is not implemented yet ---

	See commands-check_hp_procurve.cfg for more examples.


-----------------------------------------------------------------------------------------------

Release Notes
=============

Version 0.0.2.5 2012-02-06
	*  Added LICENSE.txt and README.txt.
	   No changes in the code (except for the version string and the license texts)

Version 0.0.2.4 2012-02-05
	*  Fixed an unconditional UNKNOWN exit when the SNMP session fails to be established.
	   Now it exists as set with the -f command line switch.
	*  Fixed a minor typo

Version 0.0.1.1 2012-02-04
	*  Initial Release