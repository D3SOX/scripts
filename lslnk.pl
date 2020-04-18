#!/usr/bin/env perl
#---------------------------------------------------------------------
# lslnk.pl
# Perl script to parse a shortcut (LNK) file and retrieve data
#
# Usage:
# C:\Perl>lslnk.pl <filename> [> report.txt]
#
# This script is intended to be used against LNK files extracted from 
# from an image, or for LNK files located on a system
#
# Change history
#   20100210
#     [*] Fix MAC reading in the header. Modification and LastAccessTime
#         were flip.
#   20091222
#     [*] Quick fix for a bug in the date/time return by Perl's 'stat', 'lstat'
#         and 'utime' functions under Windows because it may change by an hour
#         as we move into or out of daylight saving time (DST) if the computer
#         is set to "Automatically adjust clock for daylight saving changes"
#         and if the file reside on a NTFS volume.
#         See Win32::UTCFileTime module on CPAN for more details.
#
# References
#   The windows File Format - Jesse Hager
#   MS-SHLLNK - http://msdn.microsoft.com/en-us/library/dd871305(PROT.10).aspx
#
# copyright 2006-2007 H. Carvey, keydet89@yahoo.com
# copyright 2010 J.-F. Gingras
#---------------------------------------------------------------------
use strict;

my $file = shift || die "You must enter a filename.\n";
die "$file not found.\n" unless (-e $file);

# Setup some variables 
my $record;
my $ofs = 0;
my %flags = (0x01 => "Shell Item ID List exists",
               0x02 => "Shortcut points to a file or directory",
               0x04 => "The shortcut has a descriptive string",
               0x08 => "The shortcut has a relative path string",
               0x10 => "The shortcut has working directory",
               0x20 => "The shortcut has command line arguments",
               0x40 => "The shortcut has a custom icon",
               0x80 => "The shortcut use Unicode encoded string");

my %fileattr = (0x01 => "Target is read only",
                0x02 => "Target is hidden",
                0x04 => "Target is a system file",
                0x08 => "Target is a volume label [*]", # ??? MS-SHLLNK said it is a reserved bit and MUST be zero
                0x10 => "Target is a directory",
                0x20 => "Target was modified since last backup",
                0x40 => "Target is encrypted [*]",      # ??? MS-SHLLNK said it is a reserved bit and MUST be zero
                0x80 => "Target is normal",
                0x100 => "Target is temporary",
                0x200 => "Target is a sparse file",
                0x400 => "Target has a reparse point",
                0x800 => "Target is compressed",
                0x1000 => "Target is offline",
                0x4000 => "Target is encrypted");

my %showwnd = (0 => "SW_HIDE [*]",
               1 => "SW_NORMAL",
               2 => "SW_SHOWMINIMIZED [*]",
               3 => "SW_SHOWMAXIMIZED",
               4 => "SW_SHOWNOACTIVE [*]",
               5 => "SW_SHOW [*]",
               6 => "SW_MINIMIZE [*]",
               7 => "SW_SHOWMINNOACTIVE",
               8 => "SW_SHOWNA [*]",
               9 => "SW_RESTORE [*]",
               10 => "SHOWDEFAULT [*]");

my %vol_type = (0 => "Unknown",
                1 => "No root directory",
                2 => "Removable",
                3 => "Fixed",
                4 => "Remote",
                5 => "CD-ROM",
                6 => "Ram drive");

# Get info about the file
my ($size,$atime,$mtime,$ctime) = (stat($file))[7,8,9,10];
print $file." $size bytes\n";
print "Access Time       = ".gmtime(fixWin32StatTime($atime))." (UTC)\n";
print "Creation Date     = ".gmtime(fixWin32StatTime($ctime))." (UTC)\n";
print "Modification Time = ".gmtime(fixWin32StatTime($mtime))." (UTC)\n";
print "\n";
# Open file in binary mode
open(FH,$file) || die "Could not open $file: $!\n";
binmode(FH);
seek(FH,$ofs,0);
read(FH,$record,0x4c);
if (unpack("Vx72",$record) == 0x4c) {
    my %hdr = parseHeader($record);
# print summary info from header
    print "Flags:\n";
    foreach my $i (keys %flags) {
        print $flags{$i}."\n" if ($hdr{flags} & $i);
    }
    print "\n";
    if (scalar keys %fileattr > 0) {
        print "Attributes:\n";
        foreach my $i (keys %fileattr) {
            print $fileattr{$i}."\n" if ($hdr{attr} & $i);
        }
        print "\n";
    }
    print "MAC Times: \n";
    print "Creation Time     = ".gmtime($hdr{ctime})." (UTC)\n";
    print "Modification Time = ".gmtime($hdr{mtime})." (UTC)\n";
    print "Access Time       = ".gmtime($hdr{atime})." (UTC)\n";
    print "\n";
    print "Filesize          = ".$hdr{length}." bytes\n";
    print "\n";
    print "ShowWnd value(s):\n";
    foreach my $i (keys %showwnd) {
        print $showwnd{$i}."\n" if ($hdr{showwnd} & $i);
    }
    
    $ofs += 0x4c;
# Check to see if Shell Item ID List exists.  If so, get the length
# and skip it.
    if ($hdr{flags} & 0x01) {
#        print "Shell Item ID List exists.\n";
        seek(FH,$ofs,0);
        read(FH,$record,2);
# Note: add 2 to the offset as the Shell Item ID list length is not included in the
#       structure itself
        $ofs += unpack("v",$record) + 2;
    }
    
# Check File Location Info
    if ($hdr{flags} & 0x02) {
        seek(FH,$ofs,0);
        read(FH,$record,4);
        my $l = unpack("V",$record);
        if ($l > 0) {
            seek(FH,$ofs,0);
            read(FH,$record,0x1c);
            my %li = fileLocInfo($record);
          print "\n";
            
            if ($li{flags} & 0x1) {
# Get the local volume table
                print "Shortcut file is on a local volume.\n";
                my %lvt = localVolTable($ofs + $li{vol_ofs});
                print  "Volume Name = $lvt{name}\n";
                print  "Volume Type = ".$vol_type{$lvt{type}}."\n";
                printf "Volume SN   = 0x%x\n",$lvt{vol_sn};
                print "\n";
            }
            
            if ($li{flags} & 0x2) {
# Get the network volume table
                print "File is on a network share.\n";
                my %nvt = netVolTable($ofs + $li{network_ofs});
                print "Network Share name = $nvt{name}\n";
            }
            
            if ($li{base_ofs} > 0) {
                my $basename = getBasePathName($ofs + $li{base_ofs});
                print "Base = $basename\n";
            }
        }
        
    }

}
else {
    die "$file does not have a valid shortcut header.\n"
}

close(FH);


sub parseHeader {
    my $data = $_[0];
    my %hdr;
    my @hd = unpack("Vx16V12x8",$data);
    $hdr{id}       = $hd[0];
    $hdr{flags}    = $hd[1];
    $hdr{attr}     = $hd[2];
    $hdr{ctime}    = getTime($hd[3],$hd[4]);
    $hdr{atime}    = getTime($hd[5],$hd[6]);
    $hdr{mtime}    = getTime($hd[7],$hd[8]);
    $hdr{length}   = $hd[9];
    $hdr{icon_num} = $hd[10];
    $hdr{showwnd}  = $hd[11];
    $hdr{hotkey}   = $hd[12];
    undef @hd;
    return %hdr;
}

sub fileLocInfo {
    my $data = $_[0];
    my %fl;
    ($fl{len},$fl{ptr},$fl{flags},$fl{vol_ofs},$fl{base_ofs},$fl{network_ofs},
     $fl{path_ofs}) = unpack("V7",$data);
    return %fl;
}

sub localVolTable {
    my $offset = $_[0];
    my $data;
    my %lv;
    seek(FH,$offset,0);
    read(FH,$data,0x10);
    ($lv{len},$lv{type},$lv{vol_sn},$lv{ofs}) = unpack("V4",$data);
    seek(FH,$offset + $lv{ofs},0);
    read(FH,$data, $lv{len} - 0x10);
    $lv{name} = $data;
    return %lv;
}

sub getBasePathName {
    my $ofs = $_[0];
    my $data;
    my @char;
    my $len;
    my $tag = 1;
    while($tag) {
        seek(FH,$ofs,0);
        read(FH,$data,2);
        $tag = 0 if (unpack("v",$data) == 0x00);
        push(@char,$data);
        $ofs += 2;
    }
    return join('',@char);
}

sub netVolTable {
    my $offset = $_[0];
    my $data;
    my %nv;
    seek(FH,$offset,0);
    read(FH,$data,0x14);
    ($nv{len},$nv{ofs}) = unpack("Vx4Vx8",$data);
#    printf "Length of the network volume table = 0x%x\n",$nv{len};
#    printf "Offset to the network share name   = 0x%x\n",$nv{ofs};
    seek(FH,$offset + $nv{ofs},0);
    read(FH,$data, $nv{len} - 0x14);
    $nv{name} = $data;
    return %nv;
}

#---------------------------------------------------------
# fixWin32StatTime()
# Fix the date/time return by 'stat', 'lstat' and 'utime'
# under Windows because it may change by an hour as we move
# into or out of daylight saving time (DST) if the computer
# is set to "Automatically adjust clock for daylight saving
# changes" and if the file reside on a NTFS volume.
# Input : Unix-style date/time
# Output: Unix-style date/time
#
# For more information, see Win32::UTCFileTime
# NOTES: I do assume a few things here :
#   - you are in north america
#   - your daylight bias is 1 hour
#---------------------------------------------------------
sub fixWin32StatTime {
  my $time = shift;
  
  my $i = 0;
  my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) =
                                              gmtime($time);
  $year += 1900;
  $mon  += 1;
  $wday += 1;
  if ($year >= 1987 && $year < 2007) {
    $i = 1 if ($mon == 4 && ($mday > 7 || ($wday == 1 && $hour >= 2)));
    $i = 1 if ($mon == 10 && ($mday < 25 || ($wday == 1 && $hour < 2)));
    $i = 1 if ($mon > 4 && $mon < 10);
  } elsif ($year >= 2007) {
    $i = 1 if ($mon == 3 && ($mday > 14 || ($mday >= 8 && $wday == 1 && $hour >= 2)));
    $i = 1 if ($mon == 11 && ($mday > 7 || ($wday == 1 && $hour < 2)));
    $i = 1 if ($mon > 3 && $mon < 11);
  }
  $time += ($i * 60 * 60);
}

sub getTime {
    my $lo = shift;
    my $hi = shift;
    my $t;
    if ($lo == 0 && $hi == 0) {
        $t = 0;
    } else {
        $lo -= 0xd53e8000;
        $hi -= 0x019db1de;
        $t = int($hi*429.4967296 + $lo/1e7);
    };
    $t = 0 if ($t < 0);
    return $t;
}
