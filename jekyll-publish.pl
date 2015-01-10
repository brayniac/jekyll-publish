#!/usr/bin/perl

# jekyll-publish - sync a local checkout and push remotely via rsync
# (c) brian martin (brayniac@gmail.com) @brayniac

use strict;
use warnings;

use Getopt::Long;
use Carp;

my $help;
my $source;
my $destination;

my $options = GetOptions(
'source=s' => \$source,
'destination=s' => \$destination,
  ) or help();

help() if($help);

sub help
# provide some help
{
	print "usage: jekyll-publish --source /path/to/git/checkout [--destination user@host:/var/www/]\n";
	exit 2;
}

sub pull 
# do a git pull and return 0 for failure, 1 for no-changes, 2 for changes
{
	my (%cnf) = @_;
	
	my $directory = $cnf{directory} or Carp::croak("no directory provided to pull()");
	
	Carp::croak("directory does not exist [$directory]") unless(-d $directory);
	
	my $return = 0;
	
	open(CMD,"git -C $directory pull |") or Carp::croak("Failed to execute git pull!\n$!");
	while(<CMD>) {
		my $l = $_;
		chomp($l);
		if($l =~ /^Already up-to-date.$/) {
			$return = 1;
		}
		if($l =~ /^Fast-forward$/) {
			$return = 2;
		}
	}
	close(CMD);
	
	return $return;
}

sub publish
# do an rsync from one directory to another
{
	my (%cnf) = @_;
	
	my $source = $cnf{source} or Carp::croak("no source provided to publish()");
	my $destination = $cnf{destination} or Carp::croak("no destination provided to publish()");
	
	my $return = 0;
	
	open(CMD,"rsync -rcvzi --delete $source $destination |");
	while(<CMD>) {
		my $l = $_;
		chomp($l);
		if($l =~ /^total size is/) {
			$return = 1;
		}
	}
	close(CMD);
	
	return $return;
}

if($source) {
	my $return = pull( directory => $source );
	Carp::croak("pull() failure") unless($return);
}
sleep 30; # wait for jekyll to regenerate assets
if($destination) {
	my $return = publish( source => "$source/_site/*", destination => $destination );
	Carp::croak("publish() failure") unless($return);
}
