package Runtime;

use strict;

sub new {
    my ($class, $name) = @_;
    my $obj = {
        name => $name,
        start  => time,
        last => time,
    };
    bless $obj, $class;
    return $obj;
}

# report the elapse time since last report
sub report {
    my ($self, $node) = @_;
    $node //='';
    my $runtime = time - $self->{last};
    my $str = "$self->{name}: $node interval time $runtime seconds.";
    # set the last to now
    $self->{last} = time;
    return $str;
}


# report the elapse time since start
sub report_elapse {
    my ($self, $node) = @_;
    $node //='';
    my $runtime = time - $self->{start};
    my $str = "$self->{name}: $node elapse time $runtime seconds.";
    # set the last to now
    $self->{last} = time;
    return $str;
}

sub reset {
    my ($self, $name) = @_;
    $self->{start} = time;
    $self->{last} = time;
    if ($name ) {
        $self->{name} = $name;
    }
}

1;

