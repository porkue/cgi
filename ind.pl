#!/usr/bin/perl 
use strict;
use DBI;
use Data::Dumper;
use Date::Format;
use Date::Parse;
use URI::Escape;
use HTML::Entities;
use CGI;
#use CGI::cgiuest;
use v5.10;

my $cgi = CGI->new;
my $sql = decode_entities($cgi->param('sql_box'));
$sql =~ s/^\s+//;
$sql =~ s/\s+$//;
my $history = $cgi->param('sql_history') . '&#10' . $sql;
my $cols;
my $rows;

if ($sql ) {
    my $dbh = DBI->connect('dbi:mysql:stock:localhost:3306','root','liu123')
         or die "Connection Error: $DBI::errstr\n";

    my $sth = $dbh->prepare($sql);
    $sth->execute();
    $cols = $sth->{NAME};
    $rows = $sth->fetchall_arrayref();

    $dbh->disconnect();
    DBI->disconnect_all();
}


print $cgi->header();
print $cgi->start_html(
    -title=>'My Stock Legend',
    -id => 'mypage',
    -style => [
                {-src => '../css/demo_table.css'},
                {-src => '../css/demo_page.css'},
                {-src => '../css/my.css'},
              ],
    -script => [{ -type =>'JAVASCRIPT', -src => '../js/jquery.js'},
                { -type =>'JAVASCRIPT', -src => '../js/jquery.dataTables.js'},
                { -type =>'JAVASCRIPT', -src => '../js/jquery.dataTables.min.js'},
                { -type =>'JAVASCRIPT', -src => '../js/my.js'},
            ],
);

my $sql_form = "
    <form name='sql_form' id='sql_form'  method=get'> 
    <textarea  placeholder='Input SQL command here.' name='sql_box' id='sql_box'></textarea>
    <textarea  placeholder='SQL command history.' tabindex=-1 name='sql_history' id='sql_history' readonly >$history</textarea> <br>
    <button type='submit' value = 'Submit'> Submit </button>
    <button type='reset' value='clear'>Clear</button>
    </form> ";
print $sql_form;
print " <div id = 'sql_cmd' > $sql </div>";

print $cgi->start_div({id=>'table_div'});
print $cgi->start_table({id => 'mytable'});
print $cgi->start_thead();
print $cgi->Tr($cgi->th($cols));
print $cgi->end_thead();

print $cgi->start_tbody();
for my $row (@$rows) {
    print $cgi->Tr($cgi->td($row));
}
print $cgi->end_tbody();
print $cgi->end_table();
print $cgi->end_div();
print $cgi->end_html();



