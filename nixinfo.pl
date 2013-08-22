#!/usr/bin/env perl

=head1 NAME

nixinfo - Gather System Information for UNIX and UNIX-like systems.

=head1 SYNPOSIS

nixinfo is a cross-platform UNIX system information collection tool.

=head1 DESCRIPTION

nixinfo is designed to be compatible with many different UNIX systems, with
the only requirement being a functional Perl 5.x installation. 

The following host information is currently collected:

=over 3

=item * Hostname

=item * Domain

=item * OS Name

=item * OS Version

=item * uname

=item * Archiecture

=item * Endianness

=item * Andrew File System status

=item * Contents of hosts file

=item * Contents of /etc/passwd, and if available, /etc/shadow

=item * Name, Owner, Group, Perms, Size, and MAC times for every file

=item * All available details for every running process

=item * List of loaded kernel modules

=item * List of available network interfaces

=item * Routing table

=item * Current connections, listening services

=back 

=head1 TODO

The following information will be collected in the future

=over 4

=item * A hash of any regular files on disk

=item * Identify special files (pipes, symlinks, etc)

=back

=head1 SEE ALSO

TBD

=head1 COPYRIGHT

Copyright (c) 2013 Andrew Benson, et al
All rights reserved.

Redistribution and use in source and binary forms are permitted
provided that the above copyright notice and this paragraph are
duplicated in all such forms and that any documentation,
advertising materials, and other materials related to such
distribution and use acknowledge that the software was developed
by Andrew Benson and its other contributors.  Neither the name of 
Andrew Benson nor any other contributors may be used to endorse 
or promote products derived from this software without specific 
prior written permission.

THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY EXPRESS OR
IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.

=cut

# SETUP

# There is no inherent boolean type, so instead we define true and false
# to their accepted values.
use constant false => 0;
use constant true  => 1;

# CONFIG

# By default, print to standard out. 
$usestdout = true;

# INCLUDES

# Only use capabilities provided by Perl in the default distribution.
use Time::localtime;
use File::Basename;
use Sys::Hostname;
use Config;

# GLOBALS
$version = "0.0.27";

# BUILTIN GLOBALS

# Ensure all input and output is handled on a line-by-line basis. Also, 
# ensure all output includes a newline at the end. This can be overridden,
# but it expected that this will be the value, so if you do change it, 
# change it back, please.
$\ = "\n";
$/ = "\n";

# SUBROUTINES

# Read all of the output for a command and print it to the expected filehandle. 
# Do not use this to generate lengthy output, it may break.
sub printCommand
{
	$fh = shift;
	$cmd = shift;
	$content = slurpCommand($cmd);
	print $fh $content
}

# Clean up some output for tabular data. Removes extraneous spaces.
sub tabulateCommand
{
	$fh = shift;
	$cmd = shift;
	$content = slurpCommand($cmd);
	$content =~ s/^ +//g;
	$content =~ s/ +$//g;
	$content =~ s/ +/;/g;
	print $fh $content;
}

# Execute a command and returns a string containing all of the output.
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

# FUNCTIONS

# Use the built-in Config system to determine generic host data.
sub getHostInfo
{
	$file = shift;
	print $file "Domain: ", $Config{mydomain};
	print $file "Hostname: ", hostname . $Config{mydomain};
	print $file "OS: ", $Config{osname};
	print $file "Version: ", $Config{osvers};
	print $file "uname: ", $Config{myuname};
	print $file "Arch: ", $Config{archname};
	print $file "Byteorder: ", $Config{byteorder};
	print $file "Afs?: ", $Config{afs};
}

# Use the built-in Config system to determine the command to print 
# the hosts file.
sub getHosts
{
	print $file "Contents of hosts file: ";
	printCommand($file, $Config{hostcat});
}

# Use the built-in Config system to determine the command to print
# the password file. 
# If the shadow file exists, print it as well.
sub getPasswordFile
{
	print $file "Contents of passwd file: ";
	printCommand($file, $Config{passcat});
	if(-f "/etc/shadow") {
		printCommand($file, "cat /etc/shadow");
	}
}

# Enumerate through the filesystem and gather some information about 
# any encountered (regular) files. 
sub getFiles
{
	$file = shift;
	@dirs = ( "/" );
	$\ = "\n";
	while($dir = shift(@dirs)) {
		opendir(DH, $dir);
		while($name = readdir(DH)) {
			unless($name =~ /^\.\.?/ || $file =~ /^\/proc/) {
				if($dir eq "/") {
					$path = $dir . $name;
				} else {
					$path = $dir . "/" . $name;
				}
				if(-d $path) {
					push(@dirs, $path);
				} elsif (-f $path) {
					($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,
	       $atime,$mtime,$ctime,$blksize,$blocks) = stat($path);
					print $file "Name: $path";
					print $file "  Owner: $uid";
					print $file "  Group: $gid";
					printf $file "  Permissions: %04o\n", $mode & 07777;
					print $file "  Size: $size";
					print $file "  MAC: $mtime, $atime, $ctime";
				}
			}
		}
		closedir(DH);
	}
}

# Use the ps command to list the running processes. 
sub getProcesses
{
	$output = shift;
	print $output "Process list: ";
	printCommand($output, "ps -A -o 'user ruser group rgroup uid ruid gid rgid pid ppid pgid sid pri opri pcpu pmem vsz rss osz nice class time etime stime f s c lwp nlwp psr tty addr wchan fname comm args'");
}

# Use the appropriate system specific command to list loaded kernel modules.
sub getKernelModules
{
	$output = shift;
	print $output "Kernel Modules: ";
	if($Config{osname} eq "solaris") {
		printCommand($output, "modinfo");
	} elsif ($Config{osname} eq "linux") {
		printCommand($output, "lsmod");
	} else {
		print $output "Not implemented for this platform: $Config{osname}";
	}
}

# Use the ifconfig command to list available interfaces.
sub getInterfaces
{
	$output = shift;
	print $output "Interfaces: ";
	printCommand($output, "ifconfig -a");
}

# Use the system specific command to print the routing tables.
sub getRoutes
{
	$output = shift;
	print $output "Routes: ";
	if($Config{osname} eq "linux") {
		printCommand($output, "route -n");
	} elsif ($Config{osname} eq "solaris") {
		printCommand($output, "netstat -nr");
	} else {
		print $output "Not implemented for this platform: $Config{osname}";
	}
}

# Use the system specific command to list open connections and 
# listening services.
sub getConnections
{
	$output = shift;
	print $output "Connections: ";
	if($Config{osname} eq "linux") {
		printCommand($output, "netstat -pluant");
	} elsif ($Config{osname} eq "solaris") {
		printCommand($output, "netstat -an -f inet");
	} else {
		print $output "Not implemented for this platform: $Config{osname}";
	}
}

# MAIN

# On startup, print the tool name and current version.
print basename($0), ": ", $version;

if($< != 0) {
	print "You must be running as root to execute this command.";
	exit();
}

if($usestdout) {
	$file = *STDOUT;
} else {
	$tm = localtime;
	$filename = sprintf("results-%s%s%s-%s%s.log", 
		$tm->year+1900, $tm->mon+1, $tm->mday, $tm->hour, $tm->min);

	print "Saving results to ", $filename, ".";

	open($file, ">$filename") or die "Can't open file.";
}

getHostInfo($file);
getHosts($file);
getPasswordFile($file);
getProcesses($file);
getKernelModules($file);
getInterfaces($file);
getRoutes($file);
getConnections($file);
getFiles($file);

unless($usestdout) {
	close($file);
}

