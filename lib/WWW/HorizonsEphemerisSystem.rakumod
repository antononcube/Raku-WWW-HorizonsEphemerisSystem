  use v6.d;

unit module WWW::HorizonsEphemerisSystem;

use WWW::HorizonsEphemerisSystem::Client;
use Hash::Merge;

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
    all             => 'A';

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
    for $value.head.Array -> $source-column {
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

#----------------------------------------------------------
# Observer properties
#----------------------------------------------------------

my %observerPropertiesInfo =
"ObservationDateTT" => [["Date_________JDTT"], "TT", "DateObject"],
"ObservationDateUT" => [["Date_________JDUT"], "UT", "DateObject"],
"ObservationDateTDB" => [["Date_________JD_TDB"], "TDB", "DateObject"],
"NearestPoint" => [["ObsSub-LAT", "ObsSub-LON"], "AngularDegrees", "GeoPosition"],
"SubsolarPoint" => [["SunSub-LAT", "SunSub-LON"], "AngularDegrees", "GeoPosition"],
"Visibility" => [["vis."], "VisibilityCodes", "String"],
"ApparentSunObserverTargetConfiguration" => [["/r"], "ElongationCodes", "String"],
"Constellation" => [["Cnst"], "Constellation", "String"],
"SolarPresence" => [[""], "SolarPresence", "String"],
"InterferingBodyPresence" => [[""], "LunarPresence", "String"],
"RelativeAirmass" => [["a-mass"], Any, "Numeric"],
"MagnitudeExtinction" => [["mag_ex"], Any, "Numeric"],
"ApparentMagnitude" => [["APmag"], Any, "Numeric"],
"SignalToNoiseRatio" => [["sky_SNR"], Any, "Numeric"],
"AstrometricRightAscension" => [["R.A._(ICRF)", "R.A.___(ICRF)"], "AngularDegrees", "Quantity"],
"AstrometricDeclination" => [["DEC_(ICRF)", "DEC____(ICRF)"], "AngularDegrees", "Quantity"],
"ApparentRightAscension" => [["R.A._(r-app)", "R.A._(a-app)", "R.A.__(a-app)", "R.A._(rfct-app)"], "AngularDegrees", "Quantity"],
"ApparentDeclination" => [["DEC_(r-app)", "DEC_(a-app)", "DEC___(a-app)", "DEC_(rfct-app)"], "AngularDegrees", "Quantity"],
"ApparentRightAscensionVelocity" => [["dRA*cosD"], "Arcseconds"/"Hours", "Quantity"],
"ApparentDeclinationVelocity" => [["d(DEC)/dt"], "Arcseconds"/"Hours", "Quantity"],
"Azimuth" => [["Azi_(a-app)", "Azi_(r-app)", "Azimuth_(r-app)", "Azimuth_(a-app)"], "AngularDegrees", "Quantity"],
"Elevation" => [["Elev_(a-app)", "Elev_(r-app)", "Elevation_(r-app)", "Elevation_(a-app)"], "AngularDegrees", "Quantity"],
"AzimuthVelocity" => [["dAZ*cosE"], "Arcseconds"/"Minutes", "Quantity"],
"ElevationVelocity" => [["d(ELV)/dt"], "Arcseconds"/"Minutes", "Quantity"],
"SatelliteXOffset" => [["X_(sat-prim)"], "Arcseconds", "Quantity"],
"SatelliteYOffset" => [["Y_(sat-prim)"], "Arcseconds", "Quantity"],
"SatellitePositionAngle" => [["SatPANG"], "AngularDegrees", "Quantity"],
"LocalSiderealTime" => [["L_Ap_Sid_Time"], "HoursOfRightAscension", "Quantity"],
"SurfaceBrightness" => [["S-brt"], ("Arcseconds")**-2, "Quantity"],
"IlluminatedFraction" => [["Illu%"], "Percent", "Quantity"],
"ObscureAngularWidth" => [["Def_illu"], "Arcseconds", "Quantity"],
"TargetToPrimaryBodyAngle" => [["ang-sep"], "Arcseconds", "Quantity"],
"AngularDiameter" => [["Ang-diam"], "Arcseconds", "Quantity"],
"NearestPointLongitude" => [["ObsSub-LON"], "AngularDegrees", "Quantity"],
"NearestPointLatitude" => [["ObsSub-LAT"], "AngularDegrees", "Quantity"],
"SubsolarPointLongitude" => [["SunSub-LON"], "AngularDegrees", "Quantity"],
"SubsolarPointLatitude" => [["SunSub-LAT"], "AngularDegrees", "Quantity"],
"NorthPoleToSubSolarPointAngle" => [["SN.ang"], "AngularDegrees", "Quantity"],
"NearestPointToSubSolarPointAngle" => [["SN.dist"], "Arcseconds", "Quantity"],
"NorthPoleToApparentNorthPoleAngle" => [["NP.ang"], "AngularDegrees", "Quantity"],
"NearestPointToApparentNorthPoleAngle" => [["NP.dist"], "Arcseconds", "Quantity"],
"HeliocentricEclipticLongitude" => [["hEcl-Lon"], "AngularDegrees", "Quantity"],
"HeliocentricEclipticLatitude" => [["hEcl-Lat"], "AngularDegrees", "Quantity"],
"ApparentDistanceToSun" => [["r"], "Kilometers", "Quantity"],
"ApparentSpeedRelativeToSun" => [["rdot"], "Kilometers"/"Seconds", "Quantity"],
"ApparentDistanceToObserver" => [["delta"], "Kilometers", "Quantity"],
"ApparentSpeedRelativeToObserver" => [["deldot"], "Kilometers"/"Seconds", "Quantity"],
"TargetToObserverLightTime" => [["1-way_down_LT"], "Minutes", "Quantity"],
"SpeedMagnitudeRelativeToSun" => [["VmagSn"], "Kilometers"/"Seconds", "Quantity"],
"SpeedMagnitudeRelativeToObserver" => [["VmagOb"], "Kilometers"/"Seconds", "Quantity"],
"ApparentSunObserverTargetAngle" => [["S-O-T"], "AngularDegrees", "Quantity"],
"ApparentSunTargetObserverAngle" => [["S-T-O"], "AngularDegrees", "Quantity"],
"ApparentInterferingBodyElongationAngle" => [["T-O-M", "T-O-I"], "AngularDegrees", "Quantity"],
"InterferingBodyIlluminatedFraction" => [["MN_Illu%", "IB_Illu%"], "Percent", "Quantity"],
"ApparentObserverPrimaryCenterTargetAngle" => [["O-P-T"], "AngularDegrees", "Quantity"],
"HeliocentricNorthPoleToRadiusVectorAngle" => [["PsAng"], "AngularDegrees", "Quantity"],
"HeliocentricNorthPoleToNegativeVelocityAngle" => [["PsAMV"], "AngularDegrees", "Quantity"],
"TargetOrbitalPlaneToObserverAngle" => [["PlAng"], "AngularDegrees", "Quantity"],
"ApparentEclipticLongitude" => [["r-ObsEcLon", "ObsEcLon"], "AngularDegrees", "Quantity"],
"ApparentEclipticLatitude" => [["r-ObsEcLat", "ObsEcLat"], "AngularDegrees", "Quantity"],
"NorthPoleRightAscension" => [["N.Pole-RA"], "AngularDegrees", "Quantity"],
"NorthPoleDeclination" => [["N.Pole-DC"], "AngularDegrees", "Quantity"],
"ApparentGalacticLongitude" => [["GlxLon"], "AngularDegrees", "Quantity"],
"ApparentGalacticLatitude" => [["GlxLat"], "AngularDegrees", "Quantity"],
"ObserverApparentSolarTime" => [["L_Ap_SOL_Time"], "HoursOfRightAscension", "Quantity"],
"ObserverToEarthLightTime" => [["399_ins_LT"], "Minutes", "Quantity"],
"RightAscensionUncertainty" => [["RA_3sigma"], "Arcseconds", "Quantity"],
"DeclinationUncertainty" => [["DEC_3sigma"], "Arcseconds", "Quantity"],
"UncertaintySemiMajorAxis" => [["SMAA_3sig"], "Arcseconds", "Quantity"],
"UncertaintySemiMinorAxis" => [["SMIA_3sig"], "Arcseconds", "Quantity"],
"UncertaintyEllipseOrientationAngle" => [["Theta"], "AngularDegrees", "Quantity"],
"UncertaintyArea" => [["Area_3sig"], ("Arcseconds")**2, "Quantity"],
"DistanceUncertainty" => [["RNG_3sigma"], "Kilometers", "Quantity"],
"RadialVelocityUncertainty" => [["VR_s", "RNGRT_3sig"], "Kilometers"/"Seconds", "Quantity"],
"SDopplerUncertainty" => [["DOP_S_3sig"], "Hertz", "Quantity"],
"XDopplerUncertainty" => [["DOP_X_3sig"], "Hertz", "Quantity"],
"RoundTripDelay" => [["RT_delay_3sig"], "Seconds", "Quantity"],
"ApparentTrueAnomaly" => [["Tru_Anom", "TA"], "AngularDegrees", "Quantity"],
"LocalHourAngle" => [["r-L_Ap_Hour_Ang", "L_Ap_Hour_Ang"], "HoursOfRightAscension", "Quantity"],
"PhaseAngle" => [["phi"], "AngularDegrees", "Quantity"],
"PhaseAngleBisectorLongitude" => [["PAB-LON"], "AngularDegrees", "Quantity"],
"PhaseAngleBisectorLatitude" => [["PAB-LAT"], "AngularDegrees", "Quantity"],
"TargetCenteredApparentSunLongitude" => [["App_Lon_Sun"], "AngularDegrees", "Quantity"],
"InertialApparentRightAscension" => [["RA_(ICRF-r-app)", "RA_(ICRF-a-app)"], "AngularDegrees", "Quantity"],
"InertialApparentDeclination" => [["DEC_(ICRF-r-app)", "DEC_(ICRF-a-app)"], "AngularDegrees", "Quantity"],
"InertialApparentRightAscensionVelocity" => [["I_dRA*cosD"], "Arcseconds"/"Hours", "Quantity"],
"InertialApparentDeclinationVelocity" => [["I_d(DEC)/dt"], "Arcseconds"/"Hours", "Quantity"],
"ApparentAngularVelocity" => [["Sky_motion"], "Arcseconds"/"Minutes", "Quantity"],
"NorthPoleToMotionDirectionAngle" => [["Sky_mot_PA"], "AngularDegrees", "Quantity"],
"PathAngle" => [["RelVel-ANG"], "AngularDegrees", "Quantity"],
"SkyBrightness" => [["Lun_Sky_Brt"], "Arcseconds", "Quantity"],
;

our %observerPropertiesMapping;
for %observerPropertiesInfo.kv -> $key, $value {
    for $value.head.Array -> $source-column {
        # Handle duplicate source columns
        if %observerPropertiesMapping{$source-column}:exists {
            if $key.chars < %observerPropertiesMapping{$source-column}.chars {
                %observerPropertiesMapping{$source-column} = $key;
            }
        } else {
            %observerPropertiesMapping{$source-column} = $key
        }
    }
}

#----------------------------------------------------------
# Observer properties to Horizons codes
#----------------------------------------------------------

our %observerPropToHorizons =
"SolarPresence" => 1,
"InterferingBodyPresence" => 1,
"NearestPoint" => 14,
"SubsolarPoint" => 15,
"Visibility" => 12,
"ApparentSunObserverTargetConfiguration" => 23,
"Constellation" => 29,
"RelativeAirmass" => 8,
"MagnitudeExtinction" => 8,
"ApparentMagnitude" => 9,
"SignalToNoiseRatio" => 48,
"AstrometricRightAscension" => 1,
"AstrometricDeclination" => 1,
"ApparentRightAscension" => 2,
"ApparentDeclination" => 2,
"ApparentRightAscensionVelocity" => 3,
"ApparentDeclinationVelocity" => 3,
"Azimuth" => 4,
"Elevation" => 4,
"AzimuthVelocity" => 5,
"ElevationVelocity" => 5,
"SatelliteXOffset" => 6,
"SatelliteYOffset" => 6,
"SatellitePositionAngle" => 6,
"LocalSiderealTime" => 7,
"SurfaceBrightness" => 9,
"IlluminatedFraction" => 10,
"ObscureAngularWidth" => 11,
"TargetToPrimaryBodyAngle" => 12,
"AngularDiameter" => 13,
"NearestPointLongitude" => 14,
"NearestPointLatitude" => 14,
"SubsolarPointLongitude" => 15,
"SubsolarPointLatitude" => 15,
"NorthPoleToSubSolarPointAngle" => 16,
"NearestPointToSubSolarPointAngle" => 16,
"NorthPoleToApparentNorthPoleAngle" => 17,
"NearestPointToApparentNorthPoleAngle" => 17,
"HeliocentricEclipticLongitude" => 18,
"HeliocentricEclipticLatitude" => 18,
"ApparentDistanceToSun" => 19,
"ApparentSpeedRelativeToSun" => 19,
"ApparentDistanceToObserver" => 20,
"ApparentSpeedRelativeToObserver" => 20,
"TargetToObserverLightTime" => 21,
"SpeedMagnitudeRelativeToSun" => 22,
"SpeedMagnitudeRelativeToObserver" => 22,
"ApparentSunObserverTargetAngle" => 23,
"ApparentSunTargetObserverAngle" => 24,
"ApparentInterferingBodyElongationAngle" => 25,
"InterferingBodyIlluminatedFraction" => 25,
"ApparentObserverPrimaryCenterTargetAngle" => 26,
"HeliocentricNorthPoleToRadiusVectorAngle" => 27,
"HeliocentricNorthPoleToNegativeVelocityAngle" => 27,
"TargetOrbitalPlaneToObserverAngle" => 28,
"ApparentEclipticLongitude" => 31,
"ApparentEclipticLatitude" => 31,
"NorthPoleRightAscension" => 32,
"NorthPoleDeclination" => 32,
"ApparentGalacticLongitude" => 33,
"ApparentGalacticLatitude" => 33,
"ObserverApparentSolarTime" => 34,
"ObserverToEarthLightTime" => 35,
"RightAscensionUncertainty" => 36,
"DeclinationUncertainty" => 36,
"UncertaintySemiMajorAxis" => 37,
"UncertaintySemiMinorAxis" => 37,
"UncertaintyEllipseOrientationAngle" => 37,
"UncertaintyArea" => 37,
"DistanceUncertainty" => 39,
"RadialVelocityUncertainty" => 39,
"SDopplerUncertainty" => 40,
"XDopplerUncertainty" => 40,
"RoundTripDelay" => 40,
"ApparentTrueAnomaly" => 41,
"LocalHourAngle" => 42,
"PhaseAngle" => 43,
"PhaseAngleBisectorLongitude" => 43,
"PhaseAngleBisectorLatitude" => 43,
"TargetCenteredApparentSunLongitude" => 44,
"InertialApparentRightAscension" => 45,
"InertialApparentDeclination" => 45,
"InertialApparentRightAscensionVelocity" => 46,
"InertialApparentDeclinationVelocity" => 46,
"ApparentAngularVelocity" => 47,
"NorthPoleToMotionDirectionAngle" => 47,
"PathAngle" => 47,
"SkyBrightness" => 48,
;

%observerPropToHorizons = merge-hash(%observerPropToHorizons, %observerPropToHorizons.map({ $_.key.lc => $_.value }).Hash );
%observerPropToHorizons = merge-hash(%observerPropToHorizons, %observerPropertiesMapping.map({ $_.value => %observerPropToHorizons{$_.key} }).Hash);

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
    @rows = @rows.map({ map-observer-record($_) }).Array if $etype-n eq 'observer';

    return $result unless @rows.elems;

    if $modifier-n eq 'association' {
        my %assoc;
        for @rows -> %row {
            my $k = %row.keys[0] // 'row';
            $k = 'Date' if %row{'Date'}:exists;
            $k = 'Date_________JDTT' if %row{'Date_________JDTT'}:exists;
            $k = 'Date_________JDUT' if %row{'Date_________JDUT'}:exists;
            $k = 'Date_________JD_TDB' if %row{'Date_________JD_TDB'}:exists;
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
    return 'A' if $properties.isa(Whatever);

    my @props = $properties ~~ Positional:D ?? $properties.List !! [$properties, ];
    @props = @props.map({ norm($_) });

    return 'A' if @props.grep(* eq 'all').so;

    my @codes = @props.map({ %observerPropToHorizons{$_} // die "Unsupported observer property '$_'" }).unique.sort;
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

#----------------------------------------------------------
# Time conversion functions
#----------------------------------------------------------
# Julian Date of Unix epoch 1970-01-01T00:00:00Z
constant JD_UNIX_EPOCH = 2440587.5;

# Convert JD in UTC/UT to DateTime
sub jdut-to-datetime(Real $jd --> DateTime) {
    DateTime.new( ($jd - JD_UNIX_EPOCH) * 86400 );
}

# Convert JD in TT to DateTime representing the TT instant
# (TT-UTC = ΔAT + 32.184 s)
sub jdtt-to-datetime(
        Real $jd,
        Real :$tt-minus-utc = 69.184
        --> DateTime
                     ) {
    DateTime.new(
            ($jd - JD_UNIX_EPOCH) * 86400 - $tt-minus-utc
            );
}

# Convert JD in TDB to DateTime
# TDB differs from TT by at most about ±1.7 ms,
# so for most Horizons work TT≈TDB.
sub jdtdb-to-datetime(
        Real $jd,
        Real :$tt-minus-utc = 69.184
        --> DateTime
                      ) {
    jdtt-to-datetime($jd, :$tt-minus-utc);
}

#----------------------------------------------------------
# Process records for different E-types
#----------------------------------------------------------

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

sub map-observer-record($row where * ~~ Associative --> Hash:D) {
    my %mapped;

    for $row.kv -> $k, $v is copy {
        my $mk = %observerPropertiesMapping{$k} // $k;
        next if %mapped{$mk}:exists && %mapped{$mk}.Str.chars;
        if %observerPropertiesInfo{$mk}.tail ∈ <Numeric Quantity> { $v .= Numeric }
        if %observerPropertiesInfo{$mk}.tail ∈ <DateObject> {
            if $mk.ends-with('DateUT') { $v = jdut-to-datetime($v.Numeric) }
            elsif $mk.ends-with('DateJDTT') { $v = jdtt-to-datetime($v.Numeric) }
            elsif $mk.ends-with('DateJD_TDB') { $v = jdtdb-to-datetime($v.Numeric) }
        }
        %mapped{$mk} = $v;
    }

    %mapped;
}
