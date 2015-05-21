#!/usr/bin/perl

use strict;
use warnings;

use Getopt::Long;

my $show_help;
my $debug_flag;
my $no_convert_flag;
my $ifn;
my $ofn;
my $lfn;
my $mapping;
my $start_time;
my $end_time;
my $tn_timestamp;
my $tn_fn;
my $url;

my $cmd;
my $ffmpeg="ffmpeg";
my $at="/usr/bin/AtomicParsley";
my $downloader="youtube-dl";

GetOptions("help"           => \$show_help,
	   "iwww=s"         => \$url,
    	   "if=s"           => \$ifn,
    	   "of=s"           => \$ofn,
	   "mapping=s"      => \$mapping,
	   "start-time=s"   => \$start_time,
	   "end-time=s"     => \$end_time,
           "tn-timestamp=s" => \$tn_timestamp,
	   "tn-file=s"      => \$tn_fn,
	   "debug"          => \$debug_flag,
           "no-conv"        => \$no_convert_flag)
    or die ("Error in command line arguments.\n");

if ($show_help)
{
  printf "TODO: show help.\n";
  exit 0;
}

$lfn="$ofn.log";

print "$lfn\n";

if ($url)
{
# 140         m4a       audio only  DASH audio , audio@128k
# 137         mp4       1080p       DASH video , video only
# 136         mp4       720p        DASH video
# 135         mp4       480p        DASH video , video only

    my %v_formats = (
	"137" => "mp4       1080p       DASH video , video only",
	"136" => "mp4       720p        DASH video",
	"135" => "mp4       480p        DASH video , video only"
    );

    my $success=0;

    my %a_formats = (
	"140" => "m4a       audio only  DASH audio , audio\@128k"
    );

    $ifn = "orig.$ofn";

    while ((my $acode, my $aname) = each %a_formats)
    {
	while ((my $vcode, my $vname) = each %v_formats)
	{
	    print "Trying this combination:\n";
	    print "  $aname\n";
	    print "  $vname\n";

	    $cmd = $downloader;
	    $cmd .= " \"$url\" --write-thumbnail -f \"$acode+$vcode\" --output \"$ifn\" ";

	    print "$cmd\n";
	    if ( system ($cmd) == 0 )
	    {
		$success = 1;
		last;
	    }
	    else
	    {
		print "Error downloading video.\n"
	    }
	}
    }

    die "Cannot download video. Stop.\n" if (! $success);

    ($tn_fn = $ifn) =~ s/\.[^.]+$//;
    $tn_fn .= ".jpg";
}

if ( ! $no_convert_flag)
{
    $cmd = $ffmpeg;
    $cmd .= " -ss $start_time " if ($start_time);
    $cmd .= " -t $end_time" if ($end_time);
    $cmd .= " -i \"$ifn\" ";
    $cmd .= " -s 1024x768 ";
    $cmd .= " -filter:v \"scale=1024:-1\" ";
    $cmd .= " -codec:a aac";
    $cmd .= " -codec:s mov_text";
    $cmd .= " -strict experimental";
    $cmd .= " -y";
    $cmd .= " $mapping " if ($mapping);
    $cmd .= " -vframes 100 " if ($debug_flag);
    $cmd .= " \"$ofn\" ";

    print "$cmd\n";
    system ($cmd) == 0 or die "Error converting video!\n";
}

if ($tn_timestamp || $tn_fn)
{
    my $fn;
    my $ret;
    if ($tn_timestamp)
    {
        $fn="thumbnail.$$.png";

        $cmd = $ffmpeg;
        $cmd .= " -i \"$ifn\" ";
        $cmd .= " -filter:v \"scale=1024:-1\" ";
        $cmd .= " -vframes 1";
        $cmd .= " -y ";
        $cmd .= " -ss \"$tn_timestamp\" ";
        $cmd .= " \"$fn\" ";

        print "$cmd\n";
        system ($cmd) == 0 or die "Error extracting thumbnail.\n";
    }
    else
    {
        $fn = $tn_fn;
    }

    $cmd=$at;
    $cmd .= " \"$ofn\" ";
    $cmd .= " --artwork";
    $cmd .= " \"$fn\" ";
    $cmd .= " --overWrite";

    print "$cmd\n";
    system ($cmd) == 0 or die "Error incorporating thumbnail.\n";
}
