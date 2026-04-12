#!/usr/bin/env raku
use v6.d;

use WWW::HorizonsEphemerisSystem;

sub show(Str:D $title, $data) {
    say "=" x 100;
    say "=== {$title}";
    say "=" x 100;
    say $data;
}

# 1) Cartesian position of Mars with default parameters.
my $mars-default = horizons-ephemeris-data(
    'state',
    '499',
    'position',
    :modifier<data>,
);
show('Mars Cartesian position (default parameters)', $mars-default);

# 2) Cartesian position of Mars for a specific date.
my $mars-at-date = horizons-ephemeris-data(
    'state',
    ['499', {
        dates => '2026-Apr-12 00:00:00',
    }],
    'position',
    :modifier<data>,
);
show('Mars Cartesian position for 2026-Apr-12 00:00:00', $mars-at-date);


# 3) Azimuth/Elevation of the Moon from Moscow (lat, lon) for next 12 hours.
my @dates = do with DateTime.now { ($_, $_.later(:12hours), $_.later(minutes => 12*60 + 10))};
@dates = @dates».Str.map({ $_.substr(^19).subst('T', ' ') });
my $tycho-from-moscow = horizons-ephemeris-data(
    'observer',
    {
        target => '301',
        center => (55.7505, 37.6175),
        :@dates,
    },
    <azimuth elevation>,
    :modifier<data>,
);
show('Moon Az/El from Moscow for next 12 hours', $tycho-from-moscow);

# 4) Orbital elements of Saturn moon Pandora for a specific list of date-times.
my $pandora-elements = horizons-ephemeris-data(
    'orbital-elements',
    ['617', {
        center => '699',
        dates  => [
            'Mon 10 Jan 2000 00:00:00',
            'Tue 11 Jan 2000 00:00:00',
            'Wed 12 Jan 2000 00:00:00',
        ],
    }],
    'all',
    :modifier<association>,
);
show('Pandora orbital elements for two specific date-times', $pandora-elements);
