#!/usr/bin/perl -w

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Icinga-/Nagios-Plugin "check_speedport_w920v.pl"                    #
# by Juergen Edelbluth, www.jued.de                                   #
# Licensed under GPL.                                                 #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

use strict;

my $VERSION = "0.0.1.1";

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
my $p_test = '';
my $p_ok = '';
my $p_warning = '';
my $p_critical = '';
my $p_timeout = 5;
my $p_onfail = 'UNKNOWN';
my $p_onunknown = 'UNKNOWN';
my $p_negate_critical = 0;
my $p_negate_warning = 0;
my $p_negate_ok = 0;

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
check_speedport_w920v.pl - Checks various Telekom Speedport W920V parameters for Nagios/Icinga
Version $VERSION

Copyright (c) 2012 by Juergen Edelbluth <www.jued.de>
Licensed and released under GPL v3.

Provided as-is - no warranty.

__PROGRAM_HEADER

sub readParameters
{
	use Getopt::Long qw(:config no_ignore_case);
	GetOptions(
		'H=s'	=> \$p_host,
		'h'		=> \$p_help,
		'v'		=> \$p_verbose,
		'T=s'	=> \$p_test,
		'o=s'	=> \$p_ok,
		'w=s'	=> \$p_warning,
		'c=s'	=> \$p_critical,
		't=i'	=> \$p_timeout,
		'f=s'	=> \$p_onfail,
		'u=s'	=> \$p_onunknown,
		'no'	=> \$p_negate_ok,
		'nw'	=> \$p_negate_warning,
		'nc'	=> \$p_negate_critical
	);
}

sub usage()
{
	my $usage = <<"__USAGE";
$PROGRAM_HEADER
Usage:
	${0} 
	     -H <HostAddress>
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
	
	Configuration proposals: 
	+-----------------------+-----------------------+-----------------------+-----------------------+-----------------------+-----------------------+
	| Test (-t)             | OK-Value (-o)         | Warning-Value (-w)    | Critical-Value (-c)   | On SNMP Fail (-f)     | On Unknown (-u)       |
	+-----------------------+-----------------------+-----------------------+-----------------------+-----------------------+-----------------------|
	|                       |                       |                       |                       |                       |                       |
	+-----------------------+-----------------------+-----------------------+-----------------------+-----------------------+-----------------------+
		
__USAGE
	print $usage;
}

# ###########################################################

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

sub prober
{
	# TODO: Fill me :-D
}

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
	Test (-t): .................... $p_test
	Criterium for OK (-o): ........ $p_ok
	Criterium for Warning (-w): ... $p_warning
	Criterium for Critical (-c): .. $p_critical
	Timeout (sec) (-t):............ $p_timeout
	Rule on Fail Status (-f): ..... $p_onfail
	Rule on Unknown Status (-u): .. $p_onunknown
	Negate OK regex (-no): ........ $p_negate_ok
	Negate Warning regex (-nw): ... $p_negate_warning
	Negate Critical regex (-nc): .. $p_negate_critical
		
__VERBOSE_PARAMETER_OUT
	}
	&prober();
}

&main();

# ###########################################################

&UNKNOWN("Plugin exited without gathering a status.");