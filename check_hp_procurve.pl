#!/usr/bin/perl -w

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Icinga-/Nagios-Plugin "check_hp_procurve.pl"                        #
# by Juergen Edelbluth, www.jued.de                                   #
# Licensed under GPL.                                                 #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

use strict;

my $VERSION = "0.0.2.3";

# ########## Defining exit codes

my %EXIT_VALUES = ( 
	'UNKNOWN' 	=> 3,
	'CRITICAL'	=> 2,
	'WARNING'	=> 1,
	'OK'		=> 0
);

# ###########################################################

my $p_verbose = 0;
my $p_help = 0;
my $p_host = '127.0.0.1';
my $p_community = 'public';
my $p_test = '';
my $p_ok = '';
my $p_warning = '';
my $p_critical = '';
my $p_timeout = 5;
my $p_port = 161;
my $p_snmpversion = '2c';
my $p_onfail = 'UNKNOWN';
my $p_onunknown = 'UNKNOWN';
my $p_interface = 0;
my $p_negate_critical = 0;
my $p_negate_warning = 0;
my $p_negate_ok = 0;
my $p_1810G_traffic = 0;

# ########## Methods to exit with Nagios-/Icinga exit codes

sub doExit # Parameter 1: Code, Parameter 2: Message
{
	printf("%s (%d): %s\n", $_[0], $EXIT_VALUES{$_[0]}, $_[1]);
	exit $EXIT_VALUES{$_[0]};
}

sub UNKNOWN # Parameter 1: Message
{
	&doExit('UNKNOWN', $_[0]); 
}

sub CRITICAL # Parameter 1: Message
{
	&doExit('CRITICAL', $_[0]); 
}

sub WARNING # Parameter 1: Message
{
	&doExit('WARNING', $_[0]); 
}

sub OK # Parameter 1: Message
{
	&doExit('OK', $_[0]); 
}

# ###########################################################

my $PROGRAM_HEADER = <<"__PROGRAM_HEADER";
check_hp_procurve.pl - Checks various hp ProCurve parameters for Nagios/Icinga
Version $VERSION

Copyright (c) 2012 by Juergen Edelbluth <www.jued.de>
Licensed and released under GPL v3.

Provided as-is - no warranty.

__PROGRAM_HEADER

# ########## initialize parameters, give usage info etc.

sub readParameters
{
	use Getopt::Long qw(:config no_ignore_case);
	GetOptions(
		'H=s'	=> \$p_host,
		'h'		=> \$p_help,
		'v'		=> \$p_verbose,
		'C=s'	=> \$p_community,
		'T=s'	=> \$p_test,
		'o=s'	=> \$p_ok,
		'w=s'	=> \$p_warning,
		'c=s'	=> \$p_critical,
		't=i'	=> \$p_timeout,
		'p=i'	=> \$p_port,
		'f=s'	=> \$p_onfail,
		'u=s'	=> \$p_onunknown,
		'i=i'	=> \$p_interface,
		'no'	=> \$p_negate_ok,
		'nw'	=> \$p_negate_warning,
		'nc'	=> \$p_negate_critical,
		'1810G'	=> \$p_1810G_traffic
	);
}

sub usage()
{
	my $usage = <<"__USAGE";
$PROGRAM_HEADER
Usage:
	${0} 
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
	| sysDesc               | <empty>               | "/^\$/"                | <empty>               | CRITICAL              | OK                    |
	| sysUptime             | <empty>               | <empty>               | <empty>               | CRITICAL              | OK                    |
	| sysName               | <empty>               | "/^\$/"                | <empty>               | CRITICAL              | OK                    |
	| sysLocation           | <empty>               | "/^\$/"                | <empty>               | CRITICAL              | OK                    |
	| sysContact            | <empty>               | "/^\$/"                | <empty>               | CRITICAL              | OK                    |
	| portStatus            | "/^UP\$/"              | <empty>               | "/^DOWN\$/"            | CRITICAL              | CRITICAL              |
	| portAdminStatus       | "/^UP\$/"              | "/^DOWN\$/"            | <empty>               | CRITICAL              | CRITICAL              |
	| portSpeed             | "/^1([0]{8,9})\$/"     | "/^1([0]{7,7})\$/"     | <empty>               | CRITICAL              | WARNING               |
	| portType              | <empty>               | <empty>               | <empty>               | CRITICAL              | OK                    |
	| portDesc              | <empty>               | <empty>               | <empty>               | CRITICAL              | OK                    |
	| portInBytes           | <empty>               | <empty>               | <empty>               | CRITICAL              | OK                    |
	| portOutBytes          | <empty>               | <empty>               | <empty>               | CRITICAL              | OK                    |
	| portInErrors          | <empty>               | "/^(^(0))\$/" (-nw)    | <empty>               | CRITICAL              | OK                    |
	| portOutErrors         | <empty>               | "/^(^(0))\$/" (-nw)    | <empty>               | CRITICAL              | OK                    |
	| portMTU               | <empty>               | <empty>               | <empty>               | CRITICAL              | OK                    |
	+-----------------------+-----------------------+-----------------------+-----------------------+-----------------------+-----------------------+
	
	WARNING: portInBytes, portOutBytes, portInErrors, portOutErrors seems to end at 2147483647 and stops counting there.
	
	Traffic measuring mode for 1810G (-1810G):
	    WARNING! This is a highly experimental feature! Be advised, it deletes the switch counters!
	    When -1810G is set, no other measurements or tests can be performed.
	    --- The feature is not implemented yet ---
	    	    
	
__USAGE
	print $usage;
}

# ###########################################################

sub probeWith # Paramenter 1: Session, Parameter 2: OID
{
	my $oid = $_[1];
	my $sess = $_[0];
	if ($p_verbose)
	{
		printf("Querying OID \"%s\".\n", $oid); 
	}
	my %result = (
		'error'		=> 0,
		'error_msg'	=> '',
		'answer'	=> ''
	);
	my @varbindlist = ( $oid );
	my $r = $sess->get_request(-varbindlist => \@varbindlist) || do { $result{'error'} = -1; $result{'error_msg'} = 'Request setup failed'; return %result; };
	my %rs = %{$r};
	if (exists $rs{$oid})
	{
		$result{'answer'} = $rs{$oid};
		if ($p_verbose)
		{
			printf("Received message \"%s\".\n", $result{'answer'}); 
		}
	}
	else
	{
		$result{'error'} = 1;
		$result{'error_msg'} = sprintf('OID %s not found', $oid);
	}
	return %result;
}

sub _is
{
	my $state = 0;
	my $res = $_[0];
	if (length $_[1] > 0)
	{
		my $rule = sprintf('m%s', $_[1]);
		$state = eval("\$res =~ $rule") or ($state = 0);
	}
	return $state;	
}

sub is_ok
{
	return not &_is($_[0], $p_ok) if $p_negate_ok;
	return &_is($_[0], $p_ok);
}

sub is_warning
{
	return not &_is($_[0], $p_warning) if $p_negate_warning;
	return &_is($_[0], $p_warning);
}

sub is_critical
{
	return not &_is($_[0], $p_critical) if $p_negate_critical;
	return &_is($_[0], $p_critical);
}

sub portStatus
{	
	my %r = %{$_[0]};
	$r{'answer'} =~ s/^1$/UP/i;
	$r{'answer'} =~ s/^2$/DOWN/i;
	return %r;
}

sub portType
{
	my %r = %{$_[0]};
	$r{'answer'} =~ s/^62$/FastEthernet/i;
	$r{'answer'} =~ s/^117$/GigabitEthernet/i;
	$r{'answer'} =~ s/^1$/other/i;
	return %r;	
}

sub prober
{
	use Net::SNMP;
	my ($session, $error) = Net::SNMP->session(
		-hostname	=> $p_host,
		-timeout	=> $p_timeout,
		-community	=> $p_community,
		-port		=> $p_port,
		-version	=> $p_snmpversion
	);
	if ($error)
	{
		my $msg = sprintf('Failed to establish SNMP session (%s)', $error);
		SWITCH:
		{
			$p_onfail =~ m/^c/i && do { &CRITICAL($msg); last SWITCH; };	
			$p_onfail =~ m/^w/i && do { &WARNING($msg); last SWITCH; };	
			$p_onfail =~ m/^o/i && do { &OK($msg); last SWITCH; };
			&UNKNOWN($msg);	
		};
	}
	my %result = (
		'error'		=> 0,
		'error_msg' => '',
		'answer'	=> ''
	);
	if ($p_1810G_traffic)
	{
		&UNKNOWN("The feature is not implemented yet.");
	}
	SWITCH:
	{
		$p_test eq 'sysDesc'              && do { %result = &probeWith($session, '.1.3.6.1.2.1.1.1.0'); last SWITCH; };
		$p_test eq 'sysUptime'            && do { %result = &probeWith($session, '.1.3.6.1.2.1.1.3.0'); last SWITCH; };
		$p_test eq 'sysName'              && do { %result = &probeWith($session, '.1.3.6.1.2.1.1.5.0'); last SWITCH; };
		$p_test eq 'sysContact'           && do { %result = &probeWith($session, '.1.3.6.1.2.1.1.4.0'); last SWITCH; };
		$p_test eq 'sysLocation'          && do { %result = &probeWith($session, '.1.3.6.1.2.1.1.6.0'); last SWITCH; };
		$p_test eq 'portStatus'           && do { %result = &probeWith($session, sprintf('.1.3.6.1.2.1.2.2.1.8.%i', $p_interface)); %result = portStatus(\%result); last SWITCH; };
		$p_test eq 'portAdminStatus'      && do { %result = &probeWith($session, sprintf('.1.3.6.1.2.1.2.2.1.7.%i', $p_interface)); %result = portStatus(\%result); last SWITCH; };
		$p_test eq 'portSpeed'            && do { %result = &probeWith($session, sprintf('.1.3.6.1.2.1.2.2.1.5.%i', $p_interface)); last SWITCH; };
		$p_test eq 'portType'             && do { %result = &probeWith($session, sprintf('.1.3.6.1.2.1.2.2.1.3.%i', $p_interface)); %result = portType(\%result); last SWITCH; };
		$p_test eq 'portDesc'             && do { %result = &probeWith($session, sprintf('.1.3.6.1.2.1.2.2.1.2.%i', $p_interface)); last SWITCH; };
		$p_test eq 'portInBytes'          && do { %result = &probeWith($session, sprintf('.1.3.6.1.2.1.2.2.1.10.%i', $p_interface)); last SWITCH; };
		$p_test eq 'portOutBytes'         && do { %result = &probeWith($session, sprintf('.1.3.6.1.2.1.2.2.1.16.%i', $p_interface)); last SWITCH; };
		$p_test eq 'portInErrors'         && do { %result = &probeWith($session, sprintf('.1.3.6.1.2.1.2.2.1.14.%i', $p_interface)); last SWITCH; };
		$p_test eq 'portOutErrors'        && do { %result = &probeWith($session, sprintf('.1.3.6.1.2.1.2.2.1.20.%i', $p_interface)); last SWITCH; };
		$p_test eq 'portMTU'              && do { %result = &probeWith($session, sprintf('.1.3.6.1.2.1.2.2.1.4.%i', $p_interface)); last SWITCH; };
	};
	$session->close();
	if ($result{'error'} != 0)
	{
		my $msg = sprintf('Failed to execute SNMP query (Code: %i, Message: %s)', $result{'error'}, $result{'error_msg'});
		SWITCH:
		{
			$p_onfail =~ m/^c/i && do { &CRITICAL($msg); last SWITCH; };	
			$p_onfail =~ m/^w/i && do { &WARNING($msg); last SWITCH; };	
			$p_onfail =~ m/^o/i && do { &OK($msg); last SWITCH; };
			&UNKNOWN($msg);	
		};
	}
	&CRITICAL(sprintf('Result "%s" is considered as CRITICAL (%s)', $result{'answer'}, $p_critical)) if is_critical($result{'answer'}); 
	&WARNING(sprintf('Result "%s" is considered as WARNING (%s)', $result{'answer'}, $p_warning)) if is_warning($result{'answer'}); 
	&OK(sprintf('Result "%s" is considered as OK (%s)', $result{'answer'}, $p_ok)) if is_ok($result{'answer'});
	my $msg = sprintf('Result "%s" does not fit any (other) rule.', $result{'answer'}); 
	SWITCH:
	{
		$p_onunknown =~ m/^c/i && do { &CRITICAL($msg); last SWITCH; };
		$p_onunknown =~ m/^w/i && do { &WARNING($msg); last SWITCH; };
		$p_onunknown =~ m/^o/i && do { &OK($msg); last SWITCH; };
		&UNKNOWN($msg);	
	};
}

# ########## Main Method - I hate global code *ROFL*

sub main
{
	&readParameters();
	if ($p_help)
	{
		&usage();
		&UNKNOWN('Help requested - no further measurement taken.');
	}
	if ($p_verbose)
	{
		print <<"__VERBOSE_PARAMETER_OUT";
$PROGRAM_HEADER
Parameters:
	Host (-H): .................... $p_host
	SNMP Community String (-C): ... $p_community
	Test (-t): .................... $p_test
	Criterium for OK (-o): ........ $p_ok
	Criterium for Warning (-w): ... $p_warning
	Criterium for Critical (-c): .. $p_critical
	Timeout (sec) (-t):............ $p_timeout
	Port number (-p): ............. $p_port
	SNMP version: ................. $p_snmpversion
	Rule on Fail Status (-f): ..... $p_onfail
	Rule on Unknown Status (-u): .. $p_onunknown
	Interface (-i): ............... $p_interface
	Negate OK regex (-no): ........ $p_negate_ok
	Negate Warning regex (-nw): ... $p_negate_warning
	Negate Critical regex (-nc): .. $p_negate_critical
	1810G Traffic Mode (-1810G): .. $p_1810G_traffic
		
__VERBOSE_PARAMETER_OUT
	}
	&prober();
}

&main();

# ###########################################################

&UNKNOWN("Plugin exited without gathering a status.");