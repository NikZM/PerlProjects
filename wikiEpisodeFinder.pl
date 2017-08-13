#!/usr/bin/perl

use strict;
use warnings;
use LWP::UserAgent;
use open qw(:std :utf8);
use Term::ANSIColor;

$|=1;

my %properties = (
    verbose => 1,
    wikiFormat => 1,
    subFolderName => 'renamed'
);

main();

#-----------------------------------------------------------------------------------------------------

sub main {
    my $folderContents_ref = __readFolderContents();
    my ($title, $season) = __getTitleAndSeason($folderContents_ref);
  
    my $content = __getWikipediaPage($title);
    my $episodeList_ref = __parseWikiToSeasonList($content, $title);
    my %episodeList = %{$episodeList_ref};

    my $titlesFromSeason_ref = $episodeList{$season};
     
   __copyEpisodesWithTitleNames($titlesFromSeason_ref, $title, $season);
}

#-----------------------------------------------------------------------------------------------------

sub __getWikipediaPage {
    my $title = shift;
    my $pageAddress = "https://en.wikipedia.org/wiki/List_of_".$title."_episodes";
    if ($properties{verbose}){
        print "Locating page at $pageAddress\n\n";
    }
    my $ua = LWP::UserAgent->new( ssl_opts => { verify_hostname => 0 } );
    my $response = $ua->get($pageAddress);

    unless( $response->is_success ) {
	    die "unreachable url: $response->status_line\n";
    }
    else {
	    return $response->decoded_content;
    }
}

#-----------------------------------------------------------------------------------------------------

sub __parseWikiToSeasonList{
    my $content = shift;
    my $title = shift;
    my %episodeListing;
    if ($properties{verbose}){
        print "List of episodes found on Wikipedia:\n";
    }
    while ($content =~ /class="mw-headline" id="Season_\d+.*?>Season (\d+)(.*?)<\/table>/gs) {
        my $seasonNum = sprintf ('%.2o', $1);
        my $seasonContent = $2;
        my %seasonInfo;
        while($seasonContent =~ /id="ep\d+".*?\n.*?d>(\d+)<.*\n.*?>"(?|<a href=.*?>(.*?)<|(.*?)")/g) {
            my $episodeNum = sprintf ('%02d', $1);
            my $episodeTitle = $2;
            if ($properties{verbose}){
                print color("cyan"), "\t".$title." S".$seasonNum."E".$episodeNum." - ".$episodeTitle."\n", color("reset");
            }  
            $seasonInfo{$episodeNum} = $episodeTitle;
        }
        $episodeListing{$seasonNum} = \%seasonInfo;
    }
    return \%episodeListing;
}

#-----------------------------------------------------------------------------------------------------

sub __parseWikiToEpisodeList{
    my $content = shift;
    my $title = shift;
    my %episodeListing;
    while ($content =~ /<th scope="row".*?>(\d+).*?\n<.*?>"(?|<a href=.*?>(.*?)<|(.*?)")/g) {
        my $episodeNum = sprintf ('%02d', $1);
        my $episodeTitle = $2;
        if ($properties{verbose}){
            print $title." Ep".$episodeNum." - ".$episodeTitle."\n";
        }
        $episodeListing{$episodeNum} = $episodeTitle;
    }
    return \%episodeListing;
}

#-----------------------------------------------------------------------------------------------------

sub __readFolderContents {
    my $folderContents = `ls`;
    my @folderContents_Arr = split('\n', $folderContents);
    return \@folderContents_Arr;
}

#-----------------------------------------------------------------------------------------------------

sub __getTitleAndSeason {
    my $isMatched = 0;
    my @filesInFolder = @{$_[0]};
    my $title;
    my $season;

    foreach my $file (@filesInFolder) {
       if ($file =~ /(.*?) S(\d+)E\d+/ ){
            $title = $1;
            $season = $2;
            $isMatched = 1;
            if ($properties{verbose}){
                print "Looking for ";
                print color("magenta"), "$title", color("reset");
                print " season ";
                print color("magenta"), $season, color("reset");
                print "....\n\n";
            }
            last;
       } 
    }
    if (!$isMatched){
        die 'Could not find suitably named files, use <Title> S<number>E<number>';
    }
    return ($title, $season);
}

#-----------------------------------------------------------------------------------------------------

sub __copyEpisodesWithTitleNames {
    my $titlesFromSeason_ref = shift;
    my $title = shift;
    my $seasonNum = shift;
    my %titlesFromSeason = %{$titlesFromSeason_ref};

    my $subfoldername = $properties{subFolderName};
    `mkdir $subfoldername`;
    my @episodesInSeason = @{__readFolderContents()};
    foreach my $episode (@episodesInSeason) {
        if ($episode =~ /($title S($seasonNum)E(\d+))\.(.*)/){
            my $newEpisodeName = "$1 - $titlesFromSeason{$3}\.$4";
            my $unixCommandString = "cp \"$episode\" \"$subfoldername/$newEpisodeName\"";
            `$unixCommandString`;
            if ($properties{verbose}){
                print color("green"), "Renamed \"$episode\" to \"$newEpisodeName\" and copied into \"$subfoldername\/\"\n", color("reset");
            }
        }
    }
}