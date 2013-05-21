#!/usr/bin/env perl

# SETUP

use constant false => 0;
use constant true  => 1;

# CONFIG

$usestdout = true;

# INCLUDES

use Time::localtime;
use File::Basename;
use Sys::Hostname;
use Config;

# GLOBALS
$version = "0.0.1-BETA";

# BUILTIN GLOBALS
$\ = "\n";
$/ = "\n";

# SUBROUTINES

sub printCommand
{
	$fh = shift;
	$cmd = shift;
	$content = slurpCommand($cmd);
	print $fh $content
}

sub slurpCommand
{
	$cmd = shift;
	open(HC, "$cmd|") or die "Can't run $cmd.";
	$/="";
	$slurp = <HC>;
	close(HC);
	$/="\n";
	return $slurp;
}

# MAIN
print basename($0), ": ", $version;

if($usestdout) {
	$file = *STDOUT;
} else {
	$tm = localtime;
	$filename = sprintf("results-%s%s%s-%s%s.log", 
		$tm->year+1900, $tm->mon+1, $tm->mday, $tm->hour, $tm->min);

	print "Saving results to ", $filename, ".";

	open($file, ">$filename") or die "Can't open file.";
}

print $file "Domain: ", $Config{mydomain};
print $file "Hostname: ", hostname . $Config{mydomain};
print $file "OS: ", $Config{osname};
print $file "Version: ", $Config{osvers};
print $file "uname: ", $Config{myuname};
print $file "Arch: ", $Config{archname};
print $file "Byteorder: ", $Config{byteorder};
print $file "Afs?: ", $Config{afs};
print $file "Contents of hosts file: ";
printCommand($file, $Config{hostcat});
print $file "Contents of passwd file: ";
printCommand($file, $Config{passcat});
print $file "Process list: ";
$content = slurpCommand("ps -A -o 'user ruser group rgroup uid ruid gid rgid pid ppid pgid sid pri opri pcpu pmem vsz rss osz nice class time etime stime f s c lwp nlwp psr tty addr wchan fname comm args
'");
$content =~ s/ +/,/g;
print $file $content;

unless($usestdout) {
	close($file);
}

