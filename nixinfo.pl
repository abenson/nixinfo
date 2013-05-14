#!/usr/bin/env perl

# SETUP

use strict;
use warnings;

use constant false => 0;
use constant true  => 1;

# CONFIG

my $usestdout = true;

# INCLUDES

use Time::localtime;
use File::Basename;

use Sys::Hostname;
use Config;

# GLOBALS
my $version = "0.0.1-BETA";

# BUILTIN GLOBALS
$\ = "\n";

# MAIN
print basename($0), ": ", $version;

my $file;
if($usestdout == true) {
	$file = *STDOUT;
} else {
	my $tm = localtime;
	my $filename = sprintf("results-%s%s%s-%s%s.log", 
		$tm->year+1900, $tm->mon+1, $tm->mday, $tm->hour, $tm->min);

	print "Saving results to ", $filename, ".";

	open($file, ">", $filename) or die "Can't open file.";
}

print $file "Domain: ", $Config{mydomain};
print $file "Hostname: ", hostname . $Config{mydomain};
print $file "OS: ", $Config{osname};
print $file "Arch: ", $Config{archname};
print $file "Byteorder: ", $Config{byteorder};
print $file "Afs?: ", $Config{afs};

if($usestdout == false) {
	close($file);
}

