use strict;
use warnings;

use Test::More tests => 31;

use_ok('Term::Sk');

{
    my $ctr = Term::Sk->new('%2d Elapsed: %8t %21b %4p %2d (%8c of %11m) %P', { test => 1 } );
    ok(defined($ctr), 'standard counter works ok');
}

{
    my $ctr = Term::Sk->new('%', { test => 1 } );
    ok(!defined($ctr), 'invalid id aborts ok');
    is($Term::Sk::errcode, 100, '... with errorcode 100');
    like($Term::Sk::errmsg, qr{Can't parse}, '... and error message Can\'t parse');
}

{
    my $ctr = Term::Sk->new('%z', { test => 1 } );
    ok(!defined($ctr), 'unknown id aborts ok');
    is($Term::Sk::errcode, 110, '... with errorcode 110');
    like($Term::Sk::errmsg, qr{invalid display-code}, '... and error message invalid display-code');
}

{
    my $ctr = Term::Sk->new('Test %d', { test => 1 } );
    ok(defined($ctr), '%d works ok');
    is(content($ctr->get_line), 'Test -',  '... first displays -');
    $ctr->up;
    is(content($ctr->get_line), 'Test \\', '... then  displays \\');
    $ctr->up;
    is(content($ctr->get_line), 'Test |',  '... then  displays |');
    $ctr->up;
    is(content($ctr->get_line), 'Test /',  '... then  displays /');
}

{
    my $ctr = Term::Sk->new('Elapsed %8t', { test => 1 } );
    ok(defined($ctr), '%t works ok');
    like(content($ctr->get_line), qr{^Elapsed \d{2}:\d{2}:\d{2}$},  '... and displays the time elapsed');
}

{
    my $ctr = Term::Sk->new('Bar %10b', { test => 1, target => 20, pdisp => '!' } );
    ok(defined($ctr), '%b works ok');
    $ctr->up for 1..11;
    is(content($ctr->get_line), 'Bar лллллн____',  '... and displays a nice progress bar');
}

{
    my $ctr = Term::Sk->new('Percent %4p', { test => 1, target => 20 } );
    ok(defined($ctr), '%p works ok');
    $ctr->up for 1..5;
    is(content($ctr->get_line), 'Percent  25%',  '... and displays 25% after a quarter of it\'s way');
}

{
    my $ctr = Term::Sk->new('%P', { test => 1 } );
    ok(defined($ctr), '%P (in captital letters) works ok');
    is(content($ctr->get_line), '%',  '... and displays a percent symbol');
}

{
    my $ctr = Term::Sk->new('Ctr %5c', { test => 1, base => 1000 } );
    ok(defined($ctr), '%c works ok');
    $ctr->up for 1..8;
    is(content($ctr->get_line), 'Ctr 1_008',  '... and displays the correct counter value');
}

{
    my $ctr = Term::Sk->new('Tgt %5m', { test => 1, target => 9876 } );
    ok(defined($ctr), '%m works ok');
    is(content($ctr->get_line), 'Tgt 9_876',  '... and displays the correct target value');
}

{
    my $ctr = Term::Sk->new('Test', { test => 1 } );
    ok(defined($ctr), 'Simple fixed text works ok');
    $ctr->whisper('abc');
    is(content($ctr->get_line), 'abcTest',  '... and whisper() works as expected');
}

{
    my $ctr = Term::Sk->new('Dummy', { test => 1 } );
    ok(defined($ctr), 'Simple fixed text works ok');
    $ctr->close;
    is(content($ctr->get_line), '',  '... and close() works as expected');
}

{
    my $ctr = Term::Sk->new('Dummy', { test => 1 } );
    ok(defined($ctr), '%c works ok');
    $ctr->up for 1..27;
    is($ctr->ticks, 27,  '... number of ticks are correct');
}

sub content {
    my ($text) = @_;

    $text =~ s{^ \010+ \s+ \010+}{}xms;
    return $text;
}
