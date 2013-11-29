#!/usr/bin/perl -w
use strict;
use DBI;
use Data::Dumper;
use Date::Format;
use Date::Parse;
use v5.10;

my $dbh = DBI->connect('dbi:mysql:stock:localhost:3306','root','liu123')
     or die "Connection Error: $DBI::errstr\n";

my $sql = "select * from ticker limit 10";
my $sth = $dbh->prepare($sql);
$sth->execute() or die "SQL Error: $DBI::errstr\n";
#my $result = $dbh->do($sql);

my $matches=$sth->rows();
print "$matches returned";
#my ($min_date, $max_date) = $sth->fetchrow_array;
while( my $href = $sth->fetchrow_hashref) {
    print Dumper($href);
}

$sql = 'insert into earning (ticker, date, time, eps, company) values (?, ?, ?, ?, ?)';
$sth = $dbh->prepare($sql);
my $csv;
my $file = 'earning.csv';
open $csv, '<', $file or die "could not open $file for reading";
while( <$csv>) {
    chop($_);
    next if ($_ eq '');
    my ($company, $ticker, $date, $time, $eps ) = split /,/, $_;
    next if (!$date);
    $time //='';
    $ticker //='';
    $eps //='';
    $company //= '';
    $date = time2str('%Y-%m-%d', str2time($date));
    $sth->execute($ticker, $date, $time, $eps, $company);
    say "$company, $ticker, $date, $time, $eps";
}
$sth->finish();
$dbh->disconnect();
DBI->disconnect_all();
