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
use Runtime;
use List::Util qw[min max];
use strict;

my $timer = Runtime->new('summary fetch');
my $date = time2str("%Y-%m-%d", time);
my $dbh = DBI->connect('dbi:mysql:stock:localhost:3306','root','liu123')
     or die "Connection Error: $DBI::errstr\n";
my $sql= "select ticker from ticker where price > 2";
my $sth = $dbh->prepare($sql);
$sth->execute();
my $tickers = $sth->fetchall_arrayref();
my @tickers = map {"'$_->[0]'"} @$tickers;
$sql = "replace into summary (ticker, date, name, price, pre_close, dayhigh, daylow, change_price, change_pct, after_hour, volume, volume_avg, yearhigh, yearlow, cap, pe, fifty_avg, fifty_avg_change, twohundred_avg, twohundred_avg_change, short_ratio ) values (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)";

$sth = $dbh->prepare($sql);
say "tickers count " . scalar @tickers;
my $indx = 0;
while ($indx < @tickers ) {
    my $end = min($indx+199, @tickers-1);
    my @sub_tickers = @tickers[$indx..$end];
    $indx = $indx + 200;
    my $tickers_str = join ',', @sub_tickers;

    $sql= "select * from yahoo.finance.quotes where symbol in ($tickers_str)";
    my $url = "http://query.yahooapis.com/v1/public/yql?q=$sql&env=store://datatables.org/alltableswithkeys&format=json";
    my $json = get($url) or die "could not open $url";
    my $text = decode_json($json);
    next;
    my $quote = $text->{query}->{results}->{quote};

    my $ticker = $quote->{Symbol};
    my $name = $quote->{Name};
    my $price = $quote->{LastTradePriceOnly};
    my $pre_close = $quote->{PreviousClose};
    my $dayhigh = $quote->{DaysHigh} // 0;
    my $daylow = $quote->{DaysLow} // 0;
    my $yearhigh = $quote->{YearHigh};
    my $yearlow = $quote->{YearLow};
    my $change_price = $quote->{Change};
    my $change_pct = $quote->{PercentChange};
    my $after_hour = $quote->{AfterHoursChangeRealtime};
    my $volume = $quote->{Volume};
    my $volume_avg = $quote->{AverageDailyVolume};
    my $cap = $quote->{MarketCapitalization};
    my $pe = $quote->{PERatio} // 0;
    my $fifty_avg = $quote->{FiftydayMovingAverage};
    my $fifty_avg_change = $quote->{PercentChangeFromFiftydayMovingAverage};
    my $twohundred_avg = $quote->{TwoHundreddayMovingAverage};
    my $twohundred_avg_change = $quote->{PercentChangeFromTwoHundreddayMovingAverage};
    my $short_ratio = $quote->{ShortRatio};
    next if (!$price);
    my @param = ($ticker, $date, $name, $price, $pre_close, $dayhigh, $daylow, $change_price, $change_pct, $after_hour, $volume, $volume_avg, $yearhigh, $yearlow, $cap, $pe, $fifty_avg, $fifty_avg_change, $twohundred_avg, $twohundred_avg_change, $short_ratio);
    # say join ',', @param;
#    $sth->execute(@param);
    # say $timer->report();
}

$sth->finish();
$dbh->disconnect();
DBI->disconnect_all();
say $timer->report_elapse();
