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
use strict;

my $timer = Runtime->new('summary fetch');
#my $date = time2str("%Y-%m-%d", time);
my $dbh = DBI->connect('dbi:mysql:stock:localhost:3306','root','liu123')
     or die "Connection Error: $DBI::errstr\n";
my $sql= "select ticker from ticker where  price > 2  ";
my $sth = $dbh->prepare($sql);
$sth->execute();
my $tickers = $sth->fetchall_arrayref();
my @tickers = map {"'$_->[0]'"} @$tickers;
@tickers = ('^GSPC', '^IXIC', '^dji');
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
    after_hour => 'c8',
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
my @cols = qw(ticker name date close pre_close dayhigh daylow yearhigh yearlow change_price change_pct after_hour 
                volume volume_avg cap pe fifty_avg fifty_avg_pct twohundred_avg twohundred_avg_pct
                short_ratio exchange eps revenue);
say "numbers: " . scalar @cols;                
my $cols_str = join ',', @cols;                
my $columns;
foreach (@cols) {
    $columns .= $dict{$_};
}
#my $columns = 'sl1phgkjc1p2c8va2j1rm3m8m4m6s7';
my $param_str = join ',', ('?') x @cols;
$sql = "replace into summary ($cols_str ) values ($param_str)";
say $sql;

$sth = $dbh->prepare($sql);
say "tickers count " . scalar @tickers;
my $indx = 0;
while ($indx < @tickers ) {
    my $end = min($indx+199, @tickers-1);
    my @sub_tickers = @tickers[$indx..$end];
    $indx = $indx + 200;
    my $tickers_str = join '+', @sub_tickers;
    my $url = "http://finance.yahoo.com/d/quotes.csv?s=$tickers_str&f=$columns";
    my $page = get($url) or die "could not open $url";
    foreach ( split/\n/, $page) {
        my @values = split /,/, $_;
        foreach (@values) {
             $_ =~ s/"//g;
        }

        my %result;
        for (my $indx =0; $indx <@cols; $indx++) {
            my $val = $values[$indx];
            if ($val =~ /N\/A/ ) {
                $val = 0;
            }
            $result{$cols[$indx]} = $val;
        }

        if ($result{cap} =~ /B/ ) {
            chop $result{cap};
            $result{cap} *= 1000;
        } elsif ( $result{cap} !~ /M/ ) {
            $result{cap} = 0;
        }
        if ($result{revenue} =~ /([\d\.]+)B/ ) {
            $result{revenue} = $1;
            $result{revenue} *= 1000;
        } elsif ( $result{revenue} !~ /M/) {
            $result{revenue} = 0;
        }
        $result{volume} /= 1000;
        $result{volume_avg} /= 1000;
        my $d = $result{date};
        $d = time2str('%Y-%m-%d',str2time($d));
        $result{date} = $d;
        say Dumper(\%result);
       
        @values = map {$result{$_} } @cols;
#        $sth->execute(@values);
    }
}

$dbh->disconnect();
DBI->disconnect_all();
say $timer->report_elapse();
