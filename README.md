nixinfo
=======

System information tool for *NIX. 

# SYNPOSIS

nixinfo is a cross-platform UNIX system information collection tool.

# DESCRIPTION

nixinfo is designed to be compatible with many different UNIX systems, with
the only requirement being a functional Perl 5.x installation. 

The following host information is currently collected:

- Hostname
- Domain
- OS Name
- OS Version
- uname
- Archiecture
- Endianness
- Andrew File System status
- Contents of hosts file
- Contents of /etc/passwd, and if available, /etc/shadow
- Name, Owner, Group, Perms, Size, and MAC times for every file
- All available details for every running process
- List of loaded kernel modules
- List of available network interfaces
- Routing table
- Current connections, listening services

# TODO

The following information will be collected in the future

- A hash of any regular files on disk
- Identify special files (pipes, symlinks, etc)

# SEE ALSO

TBD
