  use v6.d;

unit module WWW::HorizonsEphemerisSystem;

use WWW::HorizonsEphemerisSystem::Client;

my constant @ETYPES = <state orbital-elements observer>;
my constant @MODIFIERS = <data dataset association>;

my constant %FRAME-MAP =
    'icrf'                => { REF_PLANE => "'FRAME'", REF_SYSTEM => "'ICRF'" },
    'fk4'                 => { REF_PLANE => "'FRAME'", REF_SYSTEM => "'B1950'" },
    'ecliptic-j2000'      => { REF_PLANE => "'ECLIPTIC'", REF_SYSTEM => "'ICRF'" },
    'ecliptic-b1950'      => { REF_PLANE => "'ECLIPTIC'", REF_SYSTEM => "'B1950'" },
    'center-body-equator' => { REF_PLANE => "'BODY EQUATOR'", REF_SYSTEM => "'ICRF'" };

my constant %STATE-CORR =
    'none'                          => "'NONE'",
    'light-time'                    => "'LT'",
    'light-time+stellar-aberration' => "'LT+S'";

my constant %STATE-COMPOUND =
    'position'  => <x y z>,
    'velocity'  => <vx vy vz>,
    'state'     => <x y z vx vy vz>,
    'all'       => <x y z vx vy vz distance radial-velocity light-time>;

my constant %STATE-PROP-GROUP =
    x                         => '2',
    y                         => '2',
    z                         => '2',
    vx                        => '2',
    vy                        => '2',
    vz                        => '2',
    distance                  => '3',
    radial-velocity           => '3',
    light-time                => '3',
    x-uncertainty             => '2x',
    y-uncertainty             => '2x',
    z-uncertainty             => '2x',
    vx-uncertainty            => '2x',
    vy-uncertainty            => '2x',
    vz-uncertainty            => '2x',
    along-uncertainty         => '2xa',
    cross-uncertainty         => '2xa',
    normal-uncertainty        => '2xa',
    radial-uncertainty        => '2xar',
    transverse-uncertainty    => '2xar';

my constant %STATE-GROUP-RANK =
    '2xar' => 1,
    '2xa'  => 2,
    '2x'   => 3,
    '3'    => 4,
    '2'    => 5;

my constant %OBSERVER-PROP-CODE =
    azimuth         => 4,
    elevation       => 4,
    'all'           => 'A';

my constant %QUERY-PARAMETERS =
    'state' => <target center dates frame corrections>,
    'orbital-elements' => <target center dates frame>,
    'observer' => <target center dates earth-atmospheric-refraction min-elevation max-relative-airmass skip-day min-max-solar-elongation max-angular-rate rise-transit-set-only>;

my constant %PROPERTIES =
    'state' => <x y z vx vy vz distance radial-velocity light-time position velocity state all>,
    'orbital-elements' => <periapsis-date eccentricity periapsis-distance inclination ascending-node-longitude perifocus-argument mean-motion mean-anomaly true-anomaly semi-major-axis apoapsis-distance orbital-period all>,
    'observer' => <azimuth elevation all>;

#----------------------------------------------------------
# Orbital properties
#----------------------------------------------------------
our %orbitalPropertiesInfo =
'Date' => [['JDTDB'], 'TDB', 'DateObject'],
'PeriapsisDate' => [['Tp'], 'TDB', 'DateObject'],
'Eccentricity' => [['EC'], Nil, 'Numeric'],
'PeriapsisDistance' => [['QR'], 'Kilometers', 'Quantity'],
'Inclination' => [['IN'], 'AngularDegrees', 'Quantity'],
'AscendingNodeLongitude' => [['OM'], 'AngularDegrees', 'Quantity'],
'PerifocusArgument' => [['W'], 'AngularDegrees', 'Quantity'],
'MeanMotion' => [['N'], 'AngularDegrees' / 'Seconds', 'Quantity'],
'MeanAnomaly' => [['MA'], 'AngularDegrees', 'Quantity'],
'TrueAnomaly' => [['Tru_Anom' | 'TA'], 'AngularDegrees', 'Quantity'],
'SemiMajorAxis' => [['A'], 'Kilometers', 'Quantity'],
'ApoapsisDistance' => [['AD'], 'Kilometers', 'Quantity'],
'OrbitalPeriod' => [['PR'], 'Seconds', 'Quantity']
;

our %orbitalPropertiesMapping =
'JDTDB' => 'Date',
'Tp' => 'PeriapsisDate',
'EC' => 'Eccentricity',
'QR' => 'PeriapsisDistance',
'IN' => 'Inclination',
'OM' => 'AscendingNodeLongitude',
'W' => 'PerifocusArgument',
'N' => 'MeanMotion',
'MA' => 'MeanAnomaly',
'Tru_Anom' => 'TrueAnomaly',
'TA' => 'TrueAnomaly',
'A' => 'SemiMajorAxis',
'AD' => 'ApoapsisDistance',
'PR' => 'OrbitalPeriod'
;

#----------------------------------------------------------
# State properties
#----------------------------------------------------------
my %statePropertiesInfo =
"Date" => [ ["JDTDB"], "TDB", "DateObject" ],
"Distance" => [ ["RG"], "Kilometers", "Quantity" ],
"RadialVelocity" => [ ["RR"], "Kilometers/Seconds", "Quantity" ],
"LightTime" => [ ["LT"], "Seconds", "Quantity" ],
"X" => [ ["X"], "Kilometers", "Quantity" ],
"Y" => [ ["Y"], "Kilometers", "Quantity" ],
"Z" => [ ["Z"], "Kilometers", "Quantity" ],
"Vx" => [ ["VX"], "Kilometers/Seconds", "Quantity" ],
"Vy" => [ ["VY"], "Kilometers/Seconds", "Quantity" ],
"Vz" => [ ["VZ"], "Kilometers/Seconds", "Quantity" ],
"XUncertainty" => [ ["X_s"], "Kilometers", "Quantity" ],
"YUncertainty" => [ ["Y_s"], "Kilometers", "Quantity" ],
"ZUncertainty" => [ ["Z_s"], "Kilometers", "Quantity" ],
"VxUncertainty" => [ ["VX_s"], "Kilometers/Seconds", "Quantity" ],
"VyUncertainty" => [ ["VY_s"], "Kilometers/Seconds", "Quantity" ],
"VzUncertainty" => [ ["VZ_s"], "Kilometers/Seconds", "Quantity" ],
"AlongUncertainty" => [ ["A_s"], "Kilometers", "Quantity" ],
"CrossUncertainty" => [ ["C_s"], "Kilometers", "Quantity" ],
"NormalUncertainty" => [ ["N_s"], "Kilometers", "Quantity" ],
"AlongVelocityUncertainty" => [ ["VA_s"], "Kilometers/Seconds", "Quantity" ],
"CrossVelocityUncertainty" => [ ["VC_s"], "Kilometers/Seconds", "Quantity" ],
"NormalVelocityUncertainty" => [ ["VN_s"], "Kilometers/Seconds", "Quantity" ],
"RadialUncertainty" => [ ["R_s"], "Kilometers", "Quantity" ],
"TransverseUncertainty" => [ ["T_s"], "Kilometers", "Quantity" ],
"RadialVelocityUncertainty" => [ ["VR_s", "RNGRT_3sig"], "Kilometers/Seconds", "Quantity" ],
"TransverseVelocityUncertainty" => [ ["VT_s"], "Kilometers/Seconds", "Quantity" ],
"XWithUncertainty" => [ ["X", "X_s"], "Kilometers", "Around" ],
"YWithUncertainty" => [ ["Y", "Y_s"], "Kilometers", "Around" ],
"ZWithUncertainty" => [ ["Z", "Z_s"], "Kilometers", "Around" ],
"VxWithUncertainty" => [ ["VX", "VX_s"], "Kilometers/Seconds", "Around" ],
"VyWithUncertainty" => [ ["VY", "VY_s"], "Kilometers/Seconds", "Around" ],
"VzWithUncertainty" => [ ["VZ", "VZ_s"], "Kilometers/Seconds", "Around" ],
;

our %statePropertiesMapping;
for %statePropertiesInfo.kv -> $key, $value {
    for $value.head.list -> $source-column {
        # Handle duplicate source columns
        if %statePropertiesMapping{$source-column}:exists {
            if $key.chars < %statePropertiesMapping{$source-column}.chars {
                %statePropertiesMapping{$source-column} = $key;
            }
        } else {
            %statePropertiesMapping{$source-column} = $key
        }
    }
}

#==========================================================
# Client access
#==========================================================
our sub horizons-client(|c --> WWW::HorizonsEphemerisSystem::Client:D) is export {
    WWW::HorizonsEphemerisSystem::Client.new(|c)
}

#==========================================================
# Main function
#==========================================================
our sub horizons-ephemeris-data(
    Str:D $etype,
    $query,
    $properties = 'all',
    Str :$modifier = 'data',
    :$client,
    Bool :$raw = False,
    Bool :$throw = True,
) is export {
    my $etype-n = norm($etype);
    die "Invalid ephemeris type '$etype'. Expected one of: {@ETYPES.join(', ')}"
        unless $etype-n eq any(@ETYPES);

    if $query ~~ Str {
        my $meta = norm($query);
        return %QUERY-PARAMETERS{$etype-n}.Array if $meta eq 'query-parameters';
        return %PROPERTIES{$etype-n}.Array if $meta eq 'properties';
    }

    my $modifier-n = norm($modifier);
    die "Invalid modifier '$modifier'. Expected one of: {@MODIFIERS.join(', ')}"
        unless $modifier-n eq any(@MODIFIERS);

    my $c = $client // horizons-client();
    my %q = normalize-query($query);
    my %api = build-api-params($etype-n, %q, $properties);

    my $response = do given $etype-n {
        when 'state' {
            $c.vectors-ephemeris(|%api, throw => $throw)
        }
        when 'orbital-elements' {
            $c.elements-ephemeris(|%api, throw => $throw)
        }
        default {
            $c.observer-ephemeris(|%api, throw => $throw)
        }
    };

    return {
        etype         => $etype-n,
        query         => %q,
        api-params    => %api,
        response      => $response,
    } if $raw;

    my $result = $response.result;
    my @rows = parse-result-csv($result);
    @rows = @rows.map({ map-state-record($_) }).Array if $etype-n eq 'state';
    @rows = @rows.map({ map-orbital-record($_) }).Array if $etype-n eq 'orbital-elements';

    return $result unless @rows.elems;

    if $modifier-n eq 'association' {
        my %assoc;
        for @rows -> %row {
            my $k = %row.keys[0] // 'row';
            $k = 'Date' if %row{'Date'}:exists;
            $k = 'Date_________JDTT' if %row{'Date_________JDTT'}:exists;
            $k = 'JDTDB' if %row{'JDTDB'}:exists;
            %assoc{%row{$k}.Str} = %row;
        }
        return %assoc;
    }

    @rows;
}

#==========================================================
# Helpers
#==========================================================
sub norm($x --> Str:D) {
    $x.Str.trim.lc.subst('_', '-', :g).subst(' ', '-', :g)
}

sub normalize-query($query --> Hash:D) {
    if $query ~~ Associative {
        return $query.Hash;
    }

    if $query ~~ Positional && $query.elems == 2 && $query[1] ~~ Associative {
        my %h = $query[1].Hash;
        %h<target> = $query[0] unless %h<target>:exists;
        return %h;
    }

    return { target => $query };
}

sub build-api-params(Str:D $etype, %query, $properties --> Hash:D) {
    my %q = %query.map({ .key => .value });
    my %api = (
        format      => 'json',
        OBJ_DATA    => 'NO',
        MAKE_EPHEM  => 'YES',
        CSV_FORMAT  => 'YES',
        TIME_DIGITS => "'FRACSEC'",
    ).Hash;

    my $target = %q<target> // die "Query must include a target";
    %api<COMMAND> = command-value($target);

    if %q<center>:exists {
        for center-params(%q<center>).pairs -> $p {
            %api{$p.key} = $p.value;
        }
    }
    else {
        %api<CENTER> = "'500@0'" if $etype ne 'observer';
    }

    if %q<dates>:exists {
        for dates-params(%q<dates>).pairs -> $p {
            %api{$p.key} = $p.value;
        }
    }
    else {
        %api<TLIST> = "'" ~ default-date-time-utc() ~ "'";
        %api<TLIST_TYPE> = 'CAL';
    }

    if %q<frame>:exists {
        my $f = norm(%q<frame>);
        my %frame = %FRAME-MAP{$f} // die "Unsupported frame '%q<frame>'";
        for %frame.pairs -> $p {
            %api{$p.key} = $p.value;
        }
    }

    if $etype eq 'state' {
        my $corr = norm(%q<corrections> // 'none');
        %api<VEC_CORR> = %STATE-CORR{$corr} // die "Unsupported corrections '%q<corrections>'";
        %api<VEC_TABLE> = "'" ~ state-columns-group($properties) ~ "'";
    }

    if $etype eq 'observer' {
        %api<CAL_FORMAT> = 'JD';
        %api<ANG_FORMAT> = 'DEG';
        %api<RANGE_UNITS> = 'KM';

        %api<APPARENT> = bool-word(%q<earth-atmospheric-refraction> // False, 'REFRACTED', 'AIRLESS');
        %api<SKIP_DAYLT> = bool-word(%q<skip-day> // False, 'YES', 'NO');
        %api<R_T_S_ONLY> = bool-word(%q<rise-transit-set-only> // False, 'YES', 'NO');

        %api<ELEV_CUT> = "'" ~ (%q<min-elevation> // -90).Str ~ "'";
        %api<AIRMASS> = "'" ~ (%q<max-relative-airmass> // 38).Str ~ "'";

        my @elong = (%q<min-max-solar-elongation> // [0, 180]).list;
        %api<SOLAR_ELONG> = "'" ~ @elong.join(',') ~ "'";

        my $rate = %q<max-angular-rate> // Inf;
        $rate = 0 if $rate ~~ Real && $rate == Inf;
        %api<ANG_RATE_CUTOFF> = "'" ~ $rate.Str ~ "'";

        %api<QUANTITIES> = "'" ~ observer-quantities($properties) ~ "'";
    }

    %api;
}

sub bool-word($v, Str:D $true, Str:D $false --> Str:D) {
    "'" ~ ($v ?? $true !! $false) ~ "'"
}

sub is-geo-tuple($x --> Bool:D) {
    return False unless $x ~~ Positional;
    my @v = $x.list;
    return False unless @v.elems == 2 || @v.elems == 3;
    @v.all ~~ Numeric;
}

sub command-value($target --> Str:D) {
    if $target ~~ Pair && is-geo-tuple($target.value) {
        return location-command($target.value, $target.key.Str);
    }

    if is-geo-tuple($target) {
        return location-command($target, '399');
    }

    "'" ~ $target.Str ~ "'";
}

sub location-command($tuple, Str:D $datum --> Str:D) {
    my @v = $tuple.list;
    my $lat = @v[0].Str;
    my $lon = @v[1].Str;
    my $h = (@v.elems == 3 ?? @v[2] !! 0).Str;
    "'g: $lon, $lat, $h @ $datum'";
}

sub center-params($center --> Hash:D) {
    if $center ~~ Pair && is-geo-tuple($center.value) {
        return location-center-params($center.value, $center.key.Str);
    }

    if is-geo-tuple($center) {
        return location-center-params($center, '399');
    }

    return { CENTER => "'" ~ $center.Str ~ "'" };
}

sub location-center-params($tuple, Str:D $datum --> Hash:D) {
    my @v = $tuple.list;
    my $lat = @v[0].Str;
    my $lon = @v[1].Str;
    my $h = (@v.elems == 3 ?? @v[2] !! 0).Str;

    {
        CENTER => "'coord@$datum'",
        COORD_TYPE => 'GEODETIC',
        SITE_COORD => "'$lon,$lat,$h'",
    }
}

sub looks-like-step(Str:D $s --> Bool:D) {
    so $s.lc ~~ /^\s*\d+ [ '.' \d+ ]? \s* <[smhdy]>+ \s*$/;
}

sub dates-params($dates --> Hash:D) {
    if $dates ~~ Positional {
        my @d = $dates.list;

        if @d.elems == 3 && @d[0] ~~ Str:D && @d[1] ~~ Str:D && @d[2] ~~ Str:D && looks-like-step(@d[2]) {
            return {
                START_TIME => "'" ~ @d[0] ~ "'",
                STOP_TIME  => "'" ~ @d[1] ~ "'",
                STEP_SIZE  => "'" ~ @d[2] ~ "'",
            };
        }

        my $tlist = @d.map({ "'" ~ .Str ~ "'" }).join(',');
        return {
            TLIST      => $tlist,
            TLIST_TYPE => 'CAL',
        };
    }

    {
        TLIST      => "'" ~ $dates.Str ~ "'",
        TLIST_TYPE => 'CAL',
    }
}

sub default-date-time-utc(--> Str:D) {
    my $now = DateTime.now.utc;
    sprintf(
        '%04d-%02d-%02d %02d:%02d:%02d',
        $now.year,
        $now.month,
        $now.day,
        $now.hour,
        $now.minute,
        $now.second.Int,
    );
}

sub expand-state-properties($properties --> Array:D) {
    my @in = $properties ~~ Positional ?? $properties.list !! [$properties];
    my @out;

    for @in.map({ norm($_) }) -> $p {
        if %STATE-COMPOUND{$p}:exists {
            @out.append: %STATE-COMPOUND{$p}.list;
        }
        else {
            @out.push: $p;
        }
    }

    @out.unique.Array;
}

sub state-columns-group($properties --> Str:D) {
    my @props = expand-state-properties($properties);

    my $has-uncertainty = @props.grep(* ~~ /'uncertainty'/).so;
    my $has-range = @props.grep(* eq any(<distance radial-velocity light-time>)).so;
    die 'Any uncertainty property cannot be queried along with light-time, distance or radial-velocity for state ephemeris'
        if $has-uncertainty && $has-range;

    my @groups = @props.map({ %STATE-PROP-GROUP{$_} // die "Unsupported state property '$_'" }).unique;
    @groups = <2> unless @groups.elems;

    @groups.sort({ %STATE-GROUP-RANK{$^a} <=> %STATE-GROUP-RANK{$^b} })[0];
}

sub observer-quantities($properties --> Str:D) {
    my @props = $properties ~~ Positional ?? $properties.list !! [$properties];
    @props = @props.map({ norm($_) });

    return 'A' if @props.grep(* eq 'all').so;

    my @codes = @props.map({ %OBSERVER-PROP-CODE{$_} // die "Unsupported observer property '$_'" }).unique.sort;
    @codes.join(',');
}

sub parse-result-csv(Str:D $result --> Array:D) {
    my @all = $result.lines;
    return [] unless @all.elems;

    my $soe = @all.first(*.contains('$$SOE'), :k);
    my $eoe = @all.first(*.contains('$$EOE'), :k);
    return [] unless $soe.defined && $eoe.defined && $eoe > $soe;

    my $header-line;
    my $data-start = $soe + 1;
    for reverse ^$soe -> $i {
        my $line = @all[$i].trim;
        next unless $line.chars;
        if $line.contains(',') {
            $header-line = $line;
            last;
        }
    }
    unless $header-line.defined {
        for $soe + 1 .. $eoe - 1 -> $i {
            my $line = @all[$i].trim;
            next unless $line.chars;
            if $line.contains(',') {
                $header-line = $line;
                $data-start = $i + 1;
                last;
            }
        }
    }
    return [] unless $header-line.defined;

    my @headers = split-csv-line($header-line)
        .map(*.trim)
        .grep(*.chars);
    return [] unless @headers.elems;

    my @rows;
    for @all[$data-start .. $eoe - 1].grep(*.trim.chars) -> $line {
        my @cols = split-csv-line($line);
        next unless @cols.elems;

        my %row;
        for @headers.kv -> $i, $h {
            %row{$h} = (@cols[$i] // '').trim;
        }
        @rows.push: %row;
    }

    @rows;
}

sub _extract-table(Str:D $text --> Str:D) {
    my $start = $text.index('$$SOE');
    my $end   = $text.index('$$EOE');
    return '' if $start == -1 || $end == -1 || $end <= $start;
    $text.substr($start + '$$SOE'.chars, $end - ($start + '$$SOE'.chars)).trim;
}

sub split-csv-line(Str:D $line --> Array:D) {
    my @out;
    my $current = '';
    my $in-quote = False;

    for $line.comb -> $ch {
        if $ch eq '"' {
            $in-quote = !$in-quote;
            next;
        }

        if $ch eq ',' && !$in-quote {
            @out.push: $current;
            $current = '';
            next;
        }

        $current ~= $ch;
    }

    @out.push: $current;
    @out;
}

sub map-orbital-record($row where * ~~ Associative --> Hash:D) {
    my %mapped;

    for $row.kv -> $k, $v is copy {
        my $mk = %orbitalPropertiesMapping{$k} // $k;
        next if %mapped{$mk}:exists && %mapped{$mk}.Str.chars;
        if %orbitalPropertiesInfo{$mk}.tail ∈ <Numeric Quantity> { $v .= Numeric }
        %mapped{$mk} = $v;
    }

    %mapped;
}

sub map-state-record($row where * ~~ Associative --> Hash:D) {
    my %mapped;

    for $row.kv -> $k, $v is copy {
        my $mk = %statePropertiesMapping{$k} // $k;
        next if %mapped{$mk}:exists && %mapped{$mk}.Str.chars;
        if %statePropertiesInfo{$mk}.tail ∈ <Numeric Quantity> { $v .= Numeric }
        %mapped{$mk} = $v;
    }

    %mapped;
}
