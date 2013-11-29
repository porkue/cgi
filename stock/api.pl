#!/usr/bin/perl -w
use strict;
$| = 1;
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

sub quote {
    my @tickers = @_;

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
                    pe fifty_avg fifty_avg_pct twohundred_avg twohundred_avg_pct
                    short_ratio exchange eps revenue  date name );

    my $columns;
    foreach (@cols) {
        $columns .= $dict{$_};
    }

    my $tickers_str = join '+', @tickers;
    my $url = "http://finance.yahoo.com/d/quotes.csv?s=$tickers_str&f=$columns";
    my $page = get($url) or die "could not open $url";
    my $result_array = [] ;
    foreach ( split/\n/, $page) {
        say $_ ;
        my @values = split /,/, $_;
        foreach (@values) {
             $_ =~ s/"//g;
        }

        say '';
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
            $result{$col} = $val;
            $values[$indx] = $val;
            $indx++;
            say "$col => $val";
        }
        push $result_array, \@values;
    }

    return $result_array;
}

my $result = quote(@ARGV);
say Dumper($result);
1;
