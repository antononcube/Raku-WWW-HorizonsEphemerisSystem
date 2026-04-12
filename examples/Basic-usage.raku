#!/usr/bin/env raku
use v6.d;

use WWW::HorizonsEphemerisSystem;

my $h = WWW::HorizonsEphemerisSystem.new;

sub show(Str:D $title, $response) {
    say "=" x 100;
    say "=== {$title}";
    say "=" x 100;
    say "HTTP status: {$response.status} {$response.reason}";

    if $response.is-json {
        say "API version: {$response.api-version}" if $response.api-version.chars;
        say $response.result;
    }
    else {
        say $response.body;
    }
}

# 1) Cartesian position of Mars with default parameters (minimal request).
my $mars-default = $h.vectors-ephemeris(
    format  => 'json',
    COMMAND => "'499'",
);
show('Mars Cartesian position (default vectors settings)', $mars-default);

# 2) Cartesian position of Mars for a specific date-time.
my $mars-at-date = $h.vectors-ephemeris(
    format     => 'json',
    COMMAND    => "'499'",
    CENTER     => "'500@399'",
    TLIST      => "'2026-Apr-12 00:00:00'",
    TLIST_TYPE => 'CAL',
);
show('Mars Cartesian position for 2026-Apr-12 00:00:00', $mars-at-date);

# 3) Azimuth/Elevation of Tycho crater from Moscow (55.7505 N, 37.6175 E)
#    over the next 12 hours.
my $tycho-from-moscow = $h.observer-ephemeris(
    format      => 'json',
    COMMAND     => "'Tycho'",
    CENTER      => "'coord@399'",
    COORD_TYPE  => 'GEODETIC',
    SITE_COORD  => "'37.6175,55.7505,0'",
    START_TIME  => "'NOW'",
    STOP_TIME   => "'NOW+12 HOURS'",
    STEP_SIZE   => "'30 m'",
    QUANTITIES  => "'4'",  # Azimuth/Elevation output quantity
);
show('Tycho crater Az/El from Moscow for next 12 hours', $tycho-from-moscow);

# 4) Orbital elements of Saturn moon Pandora for specific date-times.
my $pandora-elements = $h.elements-ephemeris(
    format      => 'json',
    COMMAND     => "'617'",  # Pandora
    CENTER      => "'500@6'", # Saturn system barycenter
    TLIST       => q['Mon 10 Jan 2000 00:00:00','Tue 11 Jan 2000 00:00:00'],
    TLIST_TYPE  => 'CAL',
);
show('Pandora orbital elements for two specific date-times', $pandora-elements);
