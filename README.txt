# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Icinga-/Nagios-Plugin "check_speedport_w920v.pl"                    #
# Copyright (c) 2012  Juergen Edelbluth, www.jued.de                  #
# This program is licensed under the GNU General Public License v3.   #
# This program comes with ABSOLUTELY NO WARRANTY.                     #
# This is free software, and you are welcome to redistribute it       #
# under certain conditions; see LICENSE.txt for details.              #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

Requirements
============

* Getopt::Long
* LWP::UserAgent
* LWP::Protocol::https


-----------------------------------------------------------------------------------------------

Usage
=====

	Command line arguments: 
	     -H <HostAddress>
	     [-nhc]
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
	     [-f <StateOnFail>]
	     [-u <StateOnUnknown>]
	
	Parameters:
	    -h                       Show help and exit with status UNKNOWN
	    -H <HostAddress>         The IP address or the host name of the speedport
	    -nhc                     Don't check the Hostname when connecting via SSL
	    -T <TestName>            The Test to execute. See listing below.
	    -o <ValueForOK>          Regular expression to identify a result that is considered to be OK
	    -w <ValueForWarning>     Regular expression to identify a result that is considered to be a WARNING
	    -c <ValueForCritical>    Regular expression to identify a result that is considered to be a CRITICAL
	    -t <Timeout_Secs>        Timeout in seconds. From 1 to 60. (default: 5) [optional]
	    -f <StateOnFail>         Status (OK, WARNING, CRITICAL, UNKNOWN) to report when query failed (default: UNKNOWN) [optional]
	    -u <StateOnUnknown>      Status (OK, WARNING, CRITICAL, UNKNOWN) to report when no result rule matched (default: UNKNOWN) [optional]
	    -v                       Verbose output
	    
	Negation of -c -w -o:
	    You might want to negate the meaning of a -c -w or -o regex, so that the condition is fulfilled when the regex
	    does not match the query result.
	    -no                      Negate -o regex
	    -nw                      Negate -w regex
	    -nc                      Negate -c regex 
		
	There are following Tests (-T):
		Access/public_ip         Get the current public IP address (or 'unknown')
		Access/always_on         Get the "Always on" config state ('yes' or 'no')
		DSL/upstream             Upstream in KiloBit/s
		DSL/downstream           Downstream in KiloBit/s
		WLAN/active              Is the WLAN active?
		WLAN/encrypted           Is an WLAN encryption configured?
	
		
	IMPORTANT: This Plugin needs LWP::UserAgent and LWP::Protocol::https installed! Use CPAN or your package management system.
	
	Only tested with the German language version of the w920v with the firmware version 65.04.78. 


-----------------------------------------------------------------------------------------------

Release Notes
=============

Version 0.0.2.5 2012-02-06
	*  Added the command line argument -nhc to disable the host name check when establishing a
	   HTTPS-Connection. This is needed when talking to the Speedport by using the IP address
	   rather than the hostname speedport.ip (LWP would report an error 500).
	*  Added LICENSE.txt and README.txt.
	   No changes in the code (except for the version string and the license texts)

Version 0.0.1.1 2012-02-05
	*  Initial Release