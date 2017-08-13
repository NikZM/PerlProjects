#/usr/bin/perl

use warnings;
use strict;
use LWP::Simple;

$|=1;

sub main{
	my ($showname) = @ARGV;
	my %showMatches = getMatchesAndNextLetters($showname);
	foreach my $keys (keys %showMatches){
		print "$keys\n";
	}
}

sub getMatchesAndNextLetters($) {
	my $content = get("http://showrss.info/browse/");

	unless(defined($content)){
		die "unreachable url\n";
	}	
	my $letter = $_[0];
	my %showMatches;
	while($content =~ /<option value=\"(\d+)\">($letter(.).*?)<\/option>/sig){
		$showMatches{$2} = $3;
	}
	return %showMatches;	
}

main();