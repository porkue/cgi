#!/usr/bin/perl -w
$|++;
use strict;
use DBI;
use Data::Dumper;
use Date::Format;
use Date::Parse;
use v5.10;
use LWP::Simple;
use HTML::TreeBuilder;
use JSON;
use Runtime;
use List::Util qw(min max);
use Number::Format qw(format_number unformat_number);
use CGI;

use strict;

my $cgi = CGI->new;
print $cgi->header();
my $timer = Runtime->new('summary fetch');
my $dbh = DBI->connect('dbi:mysql:stock:localhost:3306','root','liu123')
     or die "Connection Error: $DBI::errstr\n";
my $sql= "select ticker from ticker";
my $sth = $dbh->prepare($sql);
$sth->execute();
my $tickers = $sth->fetchall_arrayref();
my @tickers;
for my $ticker (@$tickers) {
    push @tickers, $ticker->[0];
}
warn "tickers count " . scalar @tickers;

my %dict = (
    ticker => 's',
    name => 'n',
    close => 'l1',
    pre_close => 'p',
    dayhigh => 'h',
    daylow => 'g',
    yearhigh => 'k',
    yearlow => 'j',
    change_price => 'c1',
    change_pct => 'p2',
    volume => 'v',
    volume_avg => 'a2',
    cap => 'j1',
    pe => 'r',
    fifty_avg => 'm3',
    fifty_avg_pct => 'm8',
    twohundred_avg => 'm4',
    twohundred_avg_pct => 'm6',
    short_ratio => 's7',
    exchange => 'x',
    eps => 'e',
    revenue => 's6',
    date=>'d1',
);
my @cols = qw(ticker change_pct close volume volume_avg cap pre_close dayhigh daylow yearhigh yearlow change_price 
                 fifty_avg fifty_avg_pct twohundred_avg twohundred_avg_pct
                short_ratio exchange eps revenue pe date);

my $cols_str = join ',', @cols;                
my $columns;
foreach (@cols) {
    $columns .= $dict{$_};
}

my $param_str = join ',', ('?') x @cols;
$sql = "replace into summary ($cols_str ) values ($param_str)";

$sth = $dbh->prepare($sql);

my $indx = 0;
my $count = 0;
while ($indx < @tickers ) {
    my $end = min($indx+199, @tickers-1);
    my @sub_tickers = @tickers[$indx..$end];
    $indx = $indx + 200;
    my $tickers_str = join '+', @sub_tickers;
    my $url = "http://finance.yahoo.com/d/quotes.csv?s=$tickers_str&f=$columns";
    my $page = get($url) or die "could not open $url";
    foreach ( split/\n/, $page) {
        my @values = split /,/, $_;
        if (@values != @cols) {
            next;
        }
        foreach (@values) {
             $_ =~ s/"//g;
        }
        my %result;
        my $indx = 0;
        for my $col (@cols) {
            my $val = $values[$indx];
            if ($val =~ /N\/A/ ) {
                $val = 0;
            }

            if ($col =~ /cap|rev/ ) {
                if ($val =~ /B/ ) {
                    chop $val;
                    $val *= 1000;
                } elsif ($val =~ /M/) {
                    chop $val;
                } else {
                    $val = 0;
                }
            }
            if ($col =~ /volume/) {
                $val /= 1000;
            }
            if ($col =~ /date/) {
                $val = time2str('%Y-%m-%d',str2time($val));
            }
            $result{$col} = $val;
            $values[$indx] = $val;
            $indx++;
        }
        $count++;
        warn Dumper(\%result);
        $sth->execute(@values);
    }
}

$dbh->disconnect();
DBI->disconnect_all();
warn $timer->report_elapse();

print $cgi->start_html();
print $cgi->div("$count tickers updated!");
print $cgi->end_html();
