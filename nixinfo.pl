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

sub getHosts
{
	print $file "Contents of hosts file: ";
	printCommand($file, $Config{hostcat});
}

sub getPasswordFile
{
	print $file "Contents of passwd file: ";
	printCommand($file, $Config{passcat});
	if(-f "/etc/shadow") {
		printCommand($file, "cat /etc/shadow");
	}
}

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

sub getProcesses
{
	$output = shift;
	print $output "Process list: ";
	printCommand($output, "ps -A -o 'user ruser group rgroup uid ruid gid rgid pid ppid pgid sid pri opri pcpu pmem vsz rss osz nice class time etime stime f s c lwp nlwp psr tty addr wchan fname comm args'");
}

sub getKernelModules
{
	$output = shift;
	print $output "Kernel Modules: ";
	if($Config{osname} eq "solaris") {
		printCommand($output, "modinfo");
	} elsif ($Config{osname} eq "linux") {
		printCommand($output, "lsmod");
	}
}

sub getInterfaces
{
	$output = shift;
	print $output "Interfaces: ";
	printCommand($output, "ifconfig -a");
}

sub getRoutes
{
	$output = shift;
	print $output "Routes: ";
	if($Config{osname} eq "linux") {
		printCommand($output, "route -n");
	} elsif ($Config{osname} eq "solaris") {
		printCommand($output, "netstat -nr");
	}
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

getHostInfo($file);
getProcesses($file);
#getFiles($file);
getKernelModules($file);
getInterfaces($file);
getRoutes($file);

unless($usestdout) {
	close($file);
}

