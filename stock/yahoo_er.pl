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

#my $sql = 'insert into earning (ticker, date, time, eps ) values (?, ?, ?, ?, ?) 
#            on DUPLICATE KEY UPDATE date = ?, time = ?, eps = ?';
my $sql = 'replace into earning (ticker, date, time, eps ) values (?, ?, ?, ?)'; 

my $sth = $dbh->prepare($sql);
my $data = get_earning_data();
foreach my $er (@$data) {
    my ($company, $ticker, $date, $time, $eps) = @$er;
    $sth->execute($ticker, $date, $time, $eps);
}
$sth->finish();
$dbh->disconnect();
DBI->disconnect_all();

sub get_earning_data {
    my $start= time;
    my @result = ();
    foreach my $i ( 0..60) {
        my $time = $start + 3600*24*$i;
        my $date = time2str('%Y-%m-%d', $time);
        say $date;
        my $d = time2str('%Y%m%d', $time);
        my $url ="http://biz.yahoo.com/research/earncal/$d.html";
        my $page = get($url) or next;
        my $p = HTML::TreeBuilder->new_from_content( $page );
        my @tds = $p->find('td');
        my $table;
        foreach my $td (@tds) {
            if ($td->as_text =~ /Earnings Announcements/ ) {
                $table = $td->parent()->parent();
            }
        }
        my @trs = $table->find('tr');
        $Data::Dumper::Maxdepth = 3;
        foreach my $tr (@trs){
            my @tds = map ($_->as_text(), $tr->find('td'));
            my ($company, $ticker, $eps, $time) = @tds;
            chomp($company);
            if (!$company || $company =~ 'Earnings Announcements' || $company eq 'Company' || $company !~ /\w+/) {
                next;
            }
            next if ( !$ticker ||  $ticker =~ /\./ );
            my $time_char = 'U';
            if ( $time =~ /Before/ ) {
                $time_char  = 'B';
            } elsif ($time =~ /After/) {
                $time_char  = 'A';
            }

            $time = $time_char;
            if ( $eps eq 'N/A') {
                $eps = '';
            }
            push @result, [$company, $ticker, $date, $time, $eps];
        }
    }
    return \@result;
}
