package Term::Sk;

use strict;
use warnings;

use Time::HiRes qw( time );

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw() ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw();

our $VERSION = '0.01';

our $errcode = 0;
our $errmsg  = '';

sub new {
    shift;
    my $self = {};
    bless $self;

    $errcode = 0;
    $errmsg  = '';

    my %hash     = (freq => 1, base => 0, target => 1_000, quiet => 0, test => 0);
    %hash        = (%hash, %{$_[1]}) if defined $_[1];

    my $format = defined $_[0] ? $_[0] : '%8c';

    $self->{base}    = $hash{base};
    $self->{target}  = $hash{target};
    $self->{quiet}   = $hash{quiet};
    $self->{test}    = $hash{test};
    $self->{format}  = $format;
    $self->{freq}    = $hash{freq};
    $self->{value}   = $hash{base};
    $self->{oldtext} = '';
    $self->{line}    = '';

    if (defined $hash{pdisp} and $hash{pdisp} =~ m{!}xms) {
        $self->{pdisp} = '!';
    }
    else {
        $self->{pdisp} = '#';        
    }

    # Here we de-compose the format into $self->{action}

    $self->{action} = [];

    my $fmt = $format;
    while ($fmt ne '') {
        if ($fmt =~ m{^ ([^%]*) % (.*) $}xms) {
            my ($literal, $portion) = ($1, $2);
            unless ($portion =~ m{^ (\d*) ([a-zA-Z]) (.*) $}xms) {
                $errcode = 100;
                $errmsg  = qq{Can't parse '%[<number>]<alpha>' from '%$portion', total line is '$format'};
                return;
            }

            my ($repeat, $disp_code, $remainder) = ($1, $2, $3);

            if ($repeat eq '') { $repeat = 1; }
            if ($repeat < 1)   { $repeat = 1; }

            unless ($disp_code eq 'b'
            or      $disp_code eq 'c'
            or      $disp_code eq 'd'
            or      $disp_code eq 'm'
            or      $disp_code eq 'p'
            or      $disp_code eq 'P'
            or      $disp_code eq 't') {
                $errcode = 110;
                $errmsg  = qq{Found invalid display-code ('$disp_code'), expected ('b', 'c', 'd', 'm', 'p', 'P' or 't') in '%$portion', total line is '$format'};
                return;
            }

            push @{$self->{action}}, {type => '*lit',     len => length($literal), lit => $literal} if length($literal) > 0;
            push @{$self->{action}}, {type => $disp_code, len => $repeat};
            $fmt = $remainder;
        }
        else {
            push @{$self->{action}}, {type => '*lit', len => length($fmt), lit => $fmt};
            $fmt = '';
        }
    }

    # End of format de-composition

    $self->{tick}      = 0;
    $self->{out}       = 0;
    $self->{sec_begin} = int(time * 100);
    $self->{sec_print} = $self->{sec_begin};

    $self->show;

    return $self;
}

sub whisper {
    my $self = shift;
    
    my $back  = qq{\010} x length $self->{oldtext};
    my $blank = q{ }     x length $self->{oldtext};

    $self->{line} = join('', $back, $blank, $back, @_, $self->{oldtext});

    unless ($self->{test}) {
        local $| = 1;
        if ($self->{quiet}) {
            print @_;
        }
        else {
            print $self->{line};
        }
    }
}

sub get_line {
    my $self = shift;

    return $self->{line};
}

sub up    { my $self = shift; $self->{value} += defined $_[0] ? $_[0] : 1; $self->show_maybe; }
sub down  { my $self = shift; $self->{value} -= defined $_[0] ? $_[0] : 1; $self->show_maybe; }
sub close { my $self = shift; $self->{value} = undef;                      $self->show;       }

sub ticks { my $self = shift; return $self->{tick} }

sub DESTROY {
    my $self = shift;
    $self->close;
}

sub show_maybe {
    my $self = shift;

    $self->{line} = '';

    my $sec_now  = int(time * 100);
    my $sec_prev = $self->{sec_print};

    $self->{sec_print} = $sec_now;
    $self->{tick}++;

    if ($self->{freq} eq 's') {
        if (int($sec_prev / 100) != int($sec_now / 100)) {
            $self->show;
        }
    }
    elsif ($self->{freq} eq 'd') {
        if (int($sec_prev / 10) != int($sec_now / 10)) {
            $self->show;
        }
    }
    else {
        unless ($self->{tick} % $self->{freq}) {
            $self->show;
        }
    }
}

sub show {
    my $self = shift;
    $self->{out}++;

    my $back  = qq{\010} x length $self->{oldtext};
    my $blank = q{ }     x length $self->{oldtext};

    my $text = '';
    if (defined $self->{value}) {

        # Here we compose a string based on $self->{action} (which, of course, is the previously de-composed format)

        for my $act (@{$self->{action}}) {
            my ($type, $lit, $len) = ($act->{type}, $act->{lit}, $act->{len});

            if ($type eq '*lit') { # print (= append to $text) a simple literal
                $text .= $lit;
                next;
            }
            if ($type eq 't') { # print (= append to $text) time elapsed in format 'hh:mm:ss'
                my $unit = int(($self->{sec_print} - $self->{sec_begin}) / 100);
                my $hour = int($unit / 3600);
                my $min  = int(($unit % 3600) / 60);
                my $sec  = $unit % 60;
                my $stamp = sprintf '%02d:%02d:%02d', $hour, $min, $sec;
                $text .= sprintf "%${len}.${len}s", $stamp;
                next;
            }
            if ($type eq 'd') { # print (= append to $text) a revolving dash in format '/-\|'
                $text .= substr('/-\|', $self->{out} % 4, 1) x $len;
                next;
            }
            if ($type eq 'b') { # print (= append to $text) progress indicator format '#####_____'
                if ($self->{pdisp} eq '!') {
                    my $progr2 = $self->{target} == $self->{base} ? 0 :
                       int (2 * $len * ($self->{value} - $self->{base}) / ($self->{target} - $self->{base}) + 0.5);
                    if    ($progr2 < 0)        { $progr2 = 0        }
                    elsif ($progr2 > 2 * $len) { $progr2 = 2 * $len }
                    my $progress = int($progr2 / 2);
                    my $modulo   = $progr2 % 2;
                    $text .= "\xdb" x $progress .
                             "\xdd" x $modulo   .
                             '_'    x ($len - $progress - $modulo);
                }
                else {
                    my $progress = $self->{target} == $self->{base} ? 0 :
                       int ($len * ($self->{value} - $self->{base}) / ($self->{target} - $self->{base}) + 0.5);
                    if    ($progress < 0)    { $progress = 0    }
                    elsif ($progress > $len) { $progress = $len }
                    $text .= $self->{pdisp} x $progress.'_' x ($len - $progress);
                }
                next;
            }
            if ($type eq 'p') { # print (= append to $text) progress in percentage format '999%'
                my $percent = $self->{target} == $self->{base} ? 0 :
                   100 * ($self->{value} - $self->{base}) / ($self->{target} - $self->{base});
                $text .= sprintf "%${len}.${len}s", sprintf("%.0f%%", $percent);
                next;
            }
            if ($type eq 'P') { # print (= append to $text) literally '%' characters
                $text .= '%' x $len;
                next;
            }
            if ($type eq 'c') { # print (= append to $text) actual counter value (commified by '_'), format '99_999_999'
                $text .= sprintf "%${len}.${len}s", commify($self->{value});
                next;
            }
            if ($type eq 'm') { # print (= append to $text) target (commified by '_'), format '99_999_999'
                $text .= sprintf "%${len}.${len}s", commify($self->{target});
                next;
            }
            # default: do nothing, in the (impossible) event that $type is none of '*lit', 't', 'b', 'p', 'P', 'c' or 'm'
        }

        # End of string composition
    }

    $self->{line} = join('', $back, $blank, $back, $text);

    unless ($self->{test} or $self->{quiet}) {
        local $| = 1;
        print $self->{line};
    }

    $self->{oldtext} = $text;
}

sub commify {
    local $_ = shift;
    1 while s/^([-+]?\d+)(\d{3})/$1_$2/;
    s/\./,/;
    return $_;
}

1;
__END__

=head1 NAME

Term::Sk - Perl extension for displaying a progress indicator on a terminal.

=head1 SYNOPSIS

  use Term::Sk;

  my $ctr = Term::Sk->new('%d Elapsed: %8t %21b %4p %2d (%8c of %11m)',
    {quiet => 0, freq => 10, base => 0, target => 100, pdisp => '!'})
    or die "Error 0010: Term::Sk->new, ".
           "(code $Term::Sk::errcode) ".
           "$Term::Sk::errmsg";

  $ctr->up for (1..100);

  $ctr->down for (1..100);

  $ctr->whisper('abc'); 

  my last_line = $ctr->get_line;

  $ctr->close;

  print "Number of ticks: ", $ctr->ticks, "\n";

=head1 DESCRIPTION

Term::Sk is a class to implement a progress indicator ("Sk" is a short form for "Show Key"). This is used to provide immediate feedback for
long running processes.

A sample code fragment that uses Term::Sk:

  use Term::Sk;

  print qq{This is a test of "Term::Sk"\n\n};

  my $target = 2_845;
  my $format = '%2d Elapsed: %8t %21b %4p %2d (%8c of %11m)';

  my $ctr = Term::Sk->new($format,
    {freq => 10, base => 0, target => $target, pdisp => '!'})
    or die "Error 0010: Term::Sk->new, ".
           "(code $Term::Sk::errcode) ".
           "$Term::Sk::errmsg";

  for (1..$target) {
      $ctr->up;
      do_something();
  }

  $ctr->close;

  sub do_something {
      my $test = 0;
      for my $i (0..10_000) {
          $test += sin($i) * cos($i);
      }
  }

Another example that counts upwards:

  use Term::Sk;

  my $format = '%21b %4p';

  my $ctr = Term::Sk->new($format, {freq => 's', base => 0, target => 70})
    or die "Error 0010: Term::Sk->new, (code $Term::Sk::errcode) $Term::Sk::errmsg";

  for (1..10) {
      $ctr->up(7);
      sleep 1;
  }

  $ctr->close;

At any time, after Term::Sk->new(), you can query the number of ticks (i.e. number of calls to
$ctr->up or $ctr->down) using the method 'ticks':

  use Term::Sk;

  my $ctr = Term::Sk->new('%6c', {freq => 's', base => 0, target => 70})
    or die "Error 0010: Term::Sk->new, (code $Term::Sk::errcode) $Term::Sk::errmsg";

  for (1..4288) {
      $ctr->up;
  }

  $ctr->close;

  print "Number of ticks: ", $ctr->ticks, "\n";

This example uses a simple progress bar in quiet mode (nothing is printed to STDOUT), but
instead, the content of what would have been printed can now be extracted using the get_line() method:

  use Term::Sk;

  my $format = 'Ctr %4c';

  my $ctr = Term::Sk->new($format, {freq => 2, base => 0, target => 10, quiet => 1})
    or die "Error 0010: Term::Sk->new, (code $Term::Sk::errcode) $Term::Sk::errmsg";

  my $line = $ctr->get_line;
  $line =~ s/\010/</g;
  print "This is what would have been printed upon new(): [$line]\n";

  for my $i (1..10) {
      $ctr->up;

      $line = $ctr->get_line;
      $line =~ s/\010/</g;
      print "This is what would have been printed upon $i. call to up(): [$line]\n";
  }

  $ctr->close;

  $line = $ctr->get_line;
  $line =~ s/\010/</g;
  print "This is what would have been printed upon close(): [$line]\n";

The first parameter to new() is the format string which contains the following
special characters:

=over

=item characters '%d'

a revolving dash, format '/-\|'

=item characters '%t'

time elapsed, format 'hh:mm:ss'

=item characters '%b'

progress bar, format '#####_____'

=item characters '%p'

Progress in percentage, format '999%'

=item characters '%c'

Actual counter value (commified by '_'), format '99_999_999'

=item characters '%m'

Target maximum value (commified by '_'), format '99_999_999'

=item characters '%P'

The '%' character itself

=back

The second parameter are the following options:

=over

=item option {freq => 999}

This option sets the refresh-frequency on STDOUT to every 999 up() or
down() calls. If {freq => 999} is not specified at all, then the
refresh-frequency is set by default to every up() or down() call.

=item option {freq => 's'}

This is a special case whereby the refresh-frequency on STDOUT  is set to every
second.

=item option {freq => 'd'}

This is a special case whereby the refresh-frequency on STDOUT  is set to every
1/10th of a second.

=item option {base => 0}

This specifies the base value from which to count. The default is 0

=item option {target => 10_000}

This specifies the maximum value to which to count. The default is 10_000.

=item option {pdisp => '!'}

This option (with the exclamation mark) forces the progress bar to display
special ASCII characters to simulate blocks, rather than the sharp-symbol ('#').
(Does not work on all terminals) 

=item option {quiet => 1}

This option disables most printing to STDOUT, but the content of the would be printed
line is still available using the method get_line(). The whisper-method, however,
still shows its output.

=item option {test => 1}

This option is used for testing purposes only, it disables all printing to STDOUT, even
the whisper shows no output. But again, the content of the would be printed line is
still available using the method get_line().

=back

The new() method immediately displays the initial values on screen. From now on,
nothing must be printed to STDOUT and/or STDERR. However, you can write to STDOUT during
the operation using the method whisper().

We can either count upwards, $ctr->up, or downwards, $ctr->down. Everytime we do so, the
value is either incremented or decremented and the new value is replaced on STDOUT. We should
do so regularly during the process. Both methods, $ctr->up(99) and $ctr->down(99) can take an
optional argument, in which case the value is incremented/decremented by the specified amount.

When our process has finished, we must close the counter ($ctr->close). By doing so, the last
displayed value is removed from STDOUT, as if nothing had happened. Now we are allowed to print
again to STDOUT and/or STDERR.

=head1 AUTHOR

Klaus Eichner, January 2008

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Klaus Eichner

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
