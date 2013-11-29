#!/usr/bin/perl -w
use strict;
use DBI;
use Data::Dumper;
use Date::Format;
use Date::Parse;
use v5.10;
use LWP::Simple;
use HTML::TreeBuilder;
use strict;

my $dbh = DBI->connect('dbi:mysql:stock:localhost:3306','root','liu123')
     or die "Connection Error: $DBI::errstr\n";
my $sql = 'select ticker from ticker where cap > ?';
my $sth = $dbh->prepare($sql);
$sth->execute(50);
my $tickers = $sth->fetchall_arrayref();
my @tickers = map {$_->[0]} @$tickers;

$sql = 'replace into price(ticker, date, open, high, low, close, volumn) values (?, ?, ?, ?, ?,?,?) ';
$sth = $dbh->prepare($sql);

my $N = 30;
my $since = time - 3600*24*$N;
my $since_str = time2str('%Y-%m-%d', $since); 
my ($Y, $m, $d) = split(/-/, $since_str);
$m -= 1;
foreach my $ticker (@tickers) {
    my $url ="http://ichart.finance.yahoo.com/table.csv?s=$ticker&a=$m&b=$d&c=$Y&ignore=.csv";
    my $rows = get($url) or next;
    foreach (split /\n/, $rows) {
        next if ($_ eq '');
        my ($date, $open, $high, $low, $close, $volumn ) = split /,/, $_;
        next if (!$date || !$close || $close =~ /[a-zA-Z]/);
        $volumn /= 1000;
        $sth->execute($ticker, $date, $open, $high, $low, $close, $volumn);
        say "$ticker, $date, $open, $high, $low, $close, $volumn";
    }
}
$sth->finish();
$dbh->disconnect();
DBI->disconnect_all();

