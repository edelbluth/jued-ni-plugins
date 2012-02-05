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
my $p_host = 'speedport.ip';
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
		Access/public_ip         Get the current public IP address (or 'unknown')
		Access/always_on         Get the "Always on" config state ('yes' or 'no')
		DSL/upstream             Upstream in KiloBit/s
		DSL/downstream           Downstream in KiloBit/s
		WLAN/active              Is the WLAN active?
		WLAN/encrypted           Is an WLAN encryption configured?
	
		
	IMPORTANT: This Plugin needs LWP::UserAgent and LWP::Protocol::https installed! Use CPAN or your package management system.
	
	Only tested with the German language version of the w920v with the firmware version 65.04.78. 
		
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

sub _fail
{
	SWITCH:
	{
		$p_onfail =~ m/^c/i && do { &CRITICAL($_[0]); last SWITCH; };	
		$p_onfail =~ m/^w/i && do { &WARNING($_[0]); last SWITCH; };	
		$p_onfail =~ m/^o/i && do { &OK($_[0]); last SWITCH; };
		&UNKNOWN($_[0]);	
	};
}

sub _unknown
{
	SWITCH:
	{
		$p_onunknown =~ m/^c/i && do { &CRITICAL($_[0]); last SWITCH; };	
		$p_onunknown =~ m/^w/i && do { &WARNING($_[0]); last SWITCH; };	
		$p_onunknown =~ m/^o/i && do { &OK($_[0]); last SWITCH; };
		&UNKNOWN($_[0]);	
	};
}

sub _gatherWLAN
{
	my $r = $_[0];
	my %cr = %{$r};
	my $l = $_[1];
	my @lines = @{$l};
	if ($cr{'WLAN'}{'starts_at'} < 0)
	{
		return;
	}
	for (my $i = ($cr{'WLAN'}{'starts_at'} + 1); $i < $#lines; $i++)
	{
		if ($lines[$i] =~ m/(<div class=titel>)/i)
		{
			last;
		}
		if ($lines[$i] =~ m/(<div class=colStat>Betriebszustand:<\/div>)/i)
		{
			do
			{
				$i++;
			}
			while (($i < $#lines) && ($lines[$i] !~ m/<div class=colLast>/i) && ($lines[$i] !~ m/(<div class=titel>)/i));
			if ($lines[$i] =~ m/(<div class=titel>)/i)
			{
				last;
			}
			if ($i < $#lines)
			{
				if ($lines[$i] =~ m/<div class=colLast>(.*)<\/div>/gi)
				{
					$cr{'WLAN'}{'active'} = ($+ =~ m/Ein/i ? 'yes' : 'no');
					next;
				}
			}
		}
		if ($lines[$i] =~ m/(<div class=colStat>Verschl(.*)sselung:<\/div>)/gi)
		{
			do
			{
				$i++;
			}
			while (($i < $#lines) && ($lines[$i] !~ m/<div class=colLast>/i) && ($lines[$i] !~ m/(<div class=titel>)/i));
			if ($lines[$i] =~ m/(<div class=titel>)/i)
			{
				last;
			}
			if ($i < $#lines)
			{
				if ($lines[$i] =~ m/<div class=colLast>(.*)<\/div>/gi)
				{
					$cr{'WLAN'}{'encrypted'} = ($+ =~ m/Konfiguriert/i ? 'yes' : 'no');
					next;
				}
			}
		}		
	}
}

sub _gatherAccess
{
	my $r = $_[0];
	my %cr = %{$r};
	my $l = $_[1];
	my @lines = @{$l};
	if ($cr{'Access'}{'starts_at'} < 0)
	{
		return;
	}
	for (my $i = ($cr{'Access'}{'starts_at'} + 1); $i < $#lines; $i++)
	{
		if ($lines[$i] =~ m/(<div class=titel>)/i)
		{
			last;
		}
		if ($lines[$i] =~ m/(<div class=colStat>Immer online:<\/div>)/i)
		{
			do
			{
				$i++;
			}
			while (($i < $#lines) && ($lines[$i] !~ m/<div class=colLast>/i) && ($lines[$i] !~ m/(<div class=titel>)/i));
			if ($lines[$i] =~ m/(<div class=titel>)/i)
			{
				last;
			}
			if ($i < $#lines)
			{
				if ($lines[$i] =~ m/<div class=colLast>(.*)<\/div>/gi)
				{
					$cr{'Access'}{'always_on'} = ($+ =~ m/Ja/i ? 'yes' : 'no');
					next;
				}
			}
		}
		if ($lines[$i] =~ m/(<div class=colStat>(.*)ffentliche WAN-IP:<\/div>)/gi)
		{
			do
			{
				$i++;
			}
			while (($i < $#lines) && ($lines[$i] !~ m/<div class=colLast>/i) && ($lines[$i] !~ m/(<div class=titel>)/i));
			if ($lines[$i] =~ m/(<div class=titel>)/i)
			{
				last;
			}
			if ($i < $#lines)
			{
				if ($lines[$i] =~ m/<div class=colLast>(.*)<\/div>/gi)
				{
					$cr{'Access'}{'public_ip'} = $+;
					next;
				}
			}
		}		
	}
}

sub _gatherDSL
{
	my $r = $_[0];
	my %cr = %{$r};
	my $l = $_[1];
	my @lines = @{$l};
	if ($cr{'DSL'}{'starts_at'} < 0)
	{
		return;
	}
	for (my $i = ($cr{'DSL'}{'starts_at'} + 1); $i < $#lines; $i++)
	{
		if ($lines[$i] =~ m/(<div class=titel>)/i)
		{
			last;
		}
		if ($lines[$i] =~ m/(<div class=colStat>DSL Downstream:<\/div>)/i)
		{
			do
			{
				$i++;
			}
			while (($i < $#lines) && ($lines[$i] !~ m/<div class=colLast>/i) && ($lines[$i] !~ m/(<div class=titel>)/i));
			if ($lines[$i] =~ m/(<div class=titel>)/i)
			{
				last;
			}
			if ($i < $#lines)
			{
				if ($lines[$i] =~ m/<div class=colLast>(\d+) kbit\/s<\/div>/gi)
				{
					$cr{'DSL'}{'downstream'} = $+;
					next;
				}
			}
		}
		if ($lines[$i] =~ m/(<div class=colStat>DSL Upstream:<\/div>)/gi)
		{
			do
			{
				$i++;
			}
			while (($i < $#lines) && ($lines[$i] !~ m/<div class=colLast>/i) && ($lines[$i] !~ m/(<div class=titel>)/i));
			if ($lines[$i] =~ m/(<div class=titel>)/i)
			{
				last;
			}
			if ($i < $#lines)
			{
				if ($lines[$i] =~ m/<div class=colLast>(\d+) kbit\/s<\/div>/gi)
				{
					$cr{'DSL'}{'upstream'} = $+;
					next;
				}
			}
		}		
	}
}

sub getInformation
{
	my $content = $_[0];
	my $chapter = $_[1];
	my $field = $_[2];
	my @lines = split(/\n/x, $content);
	my $linesCount = $#lines;
	my %chapters = (
		'WLAN'		=>	{
							'starts_at'		=>	-1,
							'active'		=>	'unknown',
							'encrypted'		=>	'unknown'
						},
		'Access'	=>	{
							'starts_at'		=>	-1,
							'public_ip'		=>	'unknown',
							'always_on'		=>	'unknown'
						},
		'DSL'		=>	{
							'starts_at'		=>	-1,
							'upstream'		=>	'unknown',
							'downstream'	=>	'unknown'
						}
	);
	if ($linesCount <= 0)
	{
		&_unknown('Did not received any status!');
	}
	for (my $index = 0; $index < $linesCount; $index++)
	{
		if (!($lines[$index] =~ m/^(<div class=titel>)/i))
		{
			next;
		}
		my $fLine = $lines[$index];
		SWITCH:
		{
			$fLine =~ /WLAN \(Wireless LAN\)/i	&& do { $chapters{'WLAN'}{'starts_at'} = $index; last SWITCH; };
			$fLine =~ /Internetzugang/i			&& do { $chapters{'Access'}{'starts_at'} = $index; last SWITCH; };
			$fLine =~ /DSL-Anschluss/i			&& do { $chapters{'DSL'}{'starts_at'} = $index; last SWITCH; };
			next;
		};
	}
	SWITCH:
	{
		$chapter eq 'WLAN'						&& do { &_gatherWLAN(\%chapters, \@lines); last SWITCH; };
		$chapter eq 'Access'					&& do { &_gatherAccess(\%chapters, \@lines); last SWITCH; };
		$chapter eq 'DSL'						&& do { &_gatherDSL(\%chapters, \@lines); last SWITCH; };
		&_unknown(sprintf('Cannot find information about the requested chapter (%s)', $chapter));
	};
	if (exists $chapters{$chapter}{$field})
	{
		return $chapters{$chapter}{$field};
	}
	&_unknown(sprintf('Cannot find information about the requested field (%s)', $field));
}

sub prober
{
	if ($p_test !~ m/(.*)\/(.*)/g)
	{
		&_unknown('Malformed test name');
	}
	my ($c, $f) = split(/\//, $p_test);
	# First, download the status page.
	require LWP::UserAgent;
	my $ua = LWP::UserAgent->new;
	$ua->timeout($p_timeout);
	my $res = $ua->get(sprintf('https://%s/cgi-bin/webcm?getpage=../html/top_newstatus.htm', $p_host));
	if (!($res->is_success))
	{
		my $msg = sprintf('Failed to establish HTTPS session (%s)', $res->status_line);
		&_fail($msg);
	}
	my $html = $res->content;
	my $result = &getInformation($html, $c, $f);
	&CRITICAL(sprintf('Result "%s" is considered as CRITICAL (%s)', $result, $p_critical)) if is_critical($result); 
	&WARNING(sprintf('Result "%s" is considered as WARNING (%s)', $result, $p_warning)) if is_warning($result); 
	&OK(sprintf('Result "%s" is considered as OK (%s)', $result, $p_ok)) if is_ok($result);
	my $msg = sprintf('Result "%s" does not fit any (other) rule.', $result); 
	&_unknown($msg);
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

&UNKNOWN('Plugin exited without gathering a status.');