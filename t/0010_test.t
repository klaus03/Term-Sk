use strict;
use warnings;

use Test::More tests => 57;

use_ok('Term::Sk');

{
    my $ctr = Term::Sk->new('%2d Elapsed: %8t %21b %4p %2d (%8c of %11m) %P', { test => 1 } );
    ok(defined($ctr),                         'Test-0010: standard counter works ok');
}

{
    my $ctr = eval{ Term::Sk->new('%', { test => 1 } )};
    ok($@,                                    'Test-0020: invalid id aborts ok');
    like($@, qr{\AError-0*100},               'Test-0030: with errorcode 100');
    like($@, qr{Can't parse},                 'Test-0040: and error message Can\'t parse');
}

{
    my $ctr = eval{ Term::Sk->new('%z', { test => 1 } )};
    ok($@,                                    'Test-0050: unknown id aborts ok');
    like($@, qr{\AError-0*110},               'Test-0060: with errorcode 110');
    like($@, qr{invalid display-code},        'Test-0070: and error message invalid display-code');
}

{
    my $ctr = Term::Sk->new('Test %d', { test => 1 } );
    ok(defined($ctr),                         'Test-0080: %d works ok');
    is(content($ctr->get_line), 'Test -',     'Test-0090: first displays -');
    $ctr->up;
    is(content($ctr->get_line), 'Test \\',    'Test-0100: then  displays \\');
    $ctr->up;
    is(content($ctr->get_line), 'Test |',     'Test-0110: then  displays |');
    $ctr->up;
    is(content($ctr->get_line), 'Test /',     'Test-0120: then  displays /');
}

{
    my $ctr = Term::Sk->new('Elapsed %8t', { test => 1 } );
    ok(defined($ctr),                         'Test-0125: %t works ok');
    like(content($ctr->get_line), qr{^Elapsed \d{2}:\d{2}:\d{2}$},
                                              'Test-0130: and displays the time elapsed');
}

{
    my $ctr = Term::Sk->new('Bar %10b', { test => 1, target => 20, pdisp => '!' } );
    ok(defined($ctr),                         'Test-0140: %b works ok');
    $ctr->up for 1..11;
    is(content($ctr->get_line), 'Bar ######____',
                                              'Test-0150: always use hash for progress bar');
}

{
    my $ctr = Term::Sk->new('Percent %4p', { test => 1, target => 20 } );
    ok(defined($ctr),                         'Test-0160: %p works ok');
    $ctr->up for 1..5;
    is(content($ctr->get_line), 'Percent  25%',
                                              'Test-0170: and displays 25% after a quarter of it\'s way');
}

{
    my $ctr = Term::Sk->new('%P', { test => 1 } );
    ok(defined($ctr),                         'Test-0180: %P (in captital letters) works ok');
    is(content($ctr->get_line), '%',          'Test-0190: and displays a percent symbol');
}

{
    my $ctr = Term::Sk->new('Ctr %5c', { test => 1, base => 1000 } );
    ok(defined($ctr),                         'Test-0200: %c works ok');
    $ctr->up for 1..8;
    is(content($ctr->get_line), 'Ctr 1_008',  'Test-0210: and displays the correct counter value');
}

{
    my $ctr = Term::Sk->new('Tgt %5m', { test => 1, target => 9876 } );
    ok(defined($ctr),                         'Test-0220: %m works ok');
    is(content($ctr->get_line), 'Tgt 9_876',  'Test-0230: and displays the correct target value');
}

{
    my $ctr = Term::Sk->new('Test', { test => 1 } );
    ok(defined($ctr),                         'Test-0240: Simple fixed text works ok');
    $ctr->whisper('abc');
    is(content($ctr->get_line), 'abcTest',    'Test-0250: and whisper() works as expected');
}

{
    my $ctr = Term::Sk->new('Dummy', { test => 1 } );
    ok(defined($ctr),                         'Test-0260: Simple fixed text works ok');
    $ctr->close;
    is(content($ctr->get_line), '',           'Test-0270: and close() works as expected');
}

{
    my $ctr = Term::Sk->new('Dummy', { test => 1 } );
    ok(defined($ctr),                         'Test-0280: %c works ok');
    $ctr->up for 1..27;
    is($ctr->ticks, 27,                       'Test-0290: number of ticks are correct');
}

{
    my $ctr = Term::Sk->new('num %2c of %2m', { test => 1, base => 3, target => 45678 } );
    ok(defined($ctr),                                           'Test-0300: %2c of %2m works ok');
    is(content($ctr->get_line), 'num  3 of 45_678',             'Test-0310: first number %2c of %2m displayed correctly');
    $ctr->up(10);
    is(content($ctr->get_line), 'num 13 of 45_678',             'Test-0320: second number %2c of %2m displayed correctly');
    $ctr->up(85612);
    is(content($ctr->get_line), 'num 85_625 of 45_678',         'Test-0330: third number %2c of %2m displayed correctly');
}

{
    my $ctr = Term::Sk->new('num %c of %m', { test => 1, base => 1234567, target => 2345678, num => q{9,999} } );
    ok(defined($ctr),                                           'Test-0340: %c of %m works ok');
    is(content($ctr->get_line), 'num 1,234,567 of 2,345,678',   'Test-0350: first number %c of %m displayed correctly');
}

{
    my $ctr = Term::Sk->new('num %c of %m', { test => 1, base => 1234567, target => 2345678, num => q{9 999} } );
    ok(defined($ctr),                                           'Test-0360: %c of %m works ok');
    is(content($ctr->get_line), 'num 1 234 567 of 2 345 678',   'Test-0370: first number %c of %m displayed correctly');
}

{
    my $ctr = Term::Sk->new('num %c of %m', { test => 1, base => 1234567, target => 2345678, num => q{9_999} } );
    ok(defined($ctr),                                           'Test-0380: %c of %m works ok');
    is(content($ctr->get_line), 'num 1_234_567 of 2_345_678',   'Test-0390: first number %c of %m displayed correctly');
}

{
    my $ctr = Term::Sk->new('num %c of %m', { test => 1, base => 1234567, target => 2345678, num => q{9_99} } );
    ok(defined($ctr),                                           'Test-0400: %c of %m works ok');
    is(content($ctr->get_line), 'num 1_23_45_67 of 2_34_56_78', 'Test-0410: first number %c of %m displayed correctly');
}

{
    my $ctr = Term::Sk->new('num %c of %m', { test => 1, base => 1234567, target => 2345678, num => q{9} } );
    ok(defined($ctr),                                           'Test-0420: %c of %m works ok');
    is(content($ctr->get_line), 'num 1234567 of 2345678',       'Test-0430: first number %c of %m displayed correctly');
}

{
    my $ctr = Term::Sk->new('num %c of %m', { test => 1, base => 1234567, target => 2345678, num => q{9'999} } );
    ok(defined($ctr),                                           'Test-0440: %c of %m works ok');
    is(content($ctr->get_line), q{num 1'234'567 of 2'345'678},  'Test-0450: first number %c of %m displayed correctly');
}

{
    my $ctr = eval{Term::Sk->new('num %c of %m', { test => 1, base => 1234567, target => 2345678, num => q{8'888} } )};
    ok($@,                                                      'Test-0460: fails ok');
    like($@, qr{Can't [ ] parse [ ] num}xms,                    'Test-0470: error message');
}

{
    my $flatfile = "Test hijabc\010\010\010xyzklm";

    Term::Sk::rem_backspace(\$flatfile);

    is($flatfile, 'Test hijxyzklm',                             'Test-0480: backspaces have been removed');
}

{
    my $flatfile = ('abcde' x 37).("\010" x 28).'fghij';

    Term::Sk::rem_backspace(\$flatfile);

    is(length($flatfile), 162,                                  'Test-0540: length abcde (200,15)');
    is(substr($flatfile, -10), 'cdeabfghij',                    'Test-0560: trailing characters for abcde (200,15)');
}

{
    my $ctr = Term::Sk->new('num %c of %m', { test => 1, base => 1234567, target => 2345678, commify => sub{ join '!', split m{}xms, $_[0]; } });
    ok(defined($ctr),                                           'Test-0590: commify sub works ok');
    is(content($ctr->get_line), 'num 1!2!3!4!5!6!7 of 2!3!4!5!6!7!8',
                                                                'Test-0600: show commified numbers');
}

{
    my $ctr = Term::Sk->new('Token %6k Ctr %c', { test => 1, base => 1, token => 'Spain' } );
    ok(defined($ctr),                                           'Test-0610: %6k %c works ok');
    is(content($ctr->get_line), q{Token Spain  Ctr 1},           'Test-0620: first Token displayed correctly');
    $ctr->token('USA');
    is(content($ctr->get_line), q{Token USA    Ctr 2},           'Test-0630: second Token displayed correctly');
}

sub content {
    my ($text) = @_;

    $text =~ s{^ \010+ \s+ \010+}{}xms;
    return $text;
}
