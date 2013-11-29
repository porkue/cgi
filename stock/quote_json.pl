#!/usr/bin/perl -w
use strict;
use DBI;
use Data::Dumper;
use Date::Format;
use Date::Parse;
use v5.10;
use LWP::Simple;
use HTML::TreeBuilder;
use JSON;
use strict;

my @tickers = map {"'$_'"} @ARGV;
my $tickers_str = join ',', @tickers;
my $sql= "select * from yahoo.finance.quotes where symbol in ($tickers_str)";
my $url = "http://query.yahooapis.com/v1/public/yql?q=$sql&env=store://datatables.org/alltableswithkeys&format=json";
#say $url;
my $json = get($url) or die "could not open url";
my $text = decode_json($json);
my $quote = $text->{query}->{results}->{quote};
say Dumper($quote);
