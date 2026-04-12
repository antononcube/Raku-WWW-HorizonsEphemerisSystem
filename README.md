# WWW::HorizonsEphemerisSystem

Raku package for accessing 
[Jet Propulsion Laboratory](https://www.jpl.nasa.gov)'s 
[Horizons Ephemeris System](https://ssd.jpl.nasa.gov/horizons/) 
through the [HTTP API](https://ssd-api.jpl.nasa.gov/doc/horizons.html).

----

## Features

- Uses ["HTTP::Tiny"](https://raku.land/zef:jjatria/HTTP::Tiny), [JJp1], for all API requests.
- Percent-encodes query parameters for safe Horizons URL usage.
- Supports `json` and `text` output.
- Convenience methods for `OBSERVER`, `VECTORS`, `ELEMENTS`, `APPROACH`, and `SPK` requests.
- Raises typed exceptions for HTTP errors and API-level JSON errors.

----

### Basic Examples

Get the Cartesian position of Mars with default parameters:

```raku
use WWW::HorizonsEphemerisSystem;
horizons-ephemeris-data('state', '499', 'position');
```
```
# [{Calendar Date (TDB) => A.D. 2026-Apr-12 20:36:13.0000, JDTDB => 2461143.358483796, VX => 6.287563927771337E+00, VY => 2.570580966937223E+01, VZ => 3.845332881854393E-01, X => 2.014304520912988E+08, Y => -4.647156190196239E+07, Z => -5.887010820251506E+06}]
```

Get the position of Mars for a specific date:

```raku
my $date = "{.year}-{.month.fmt('%02s')}-{.day.fmt('%02s')}" with DateTime.now(:12hours);
horizons-ephemeris-data(
  'state',
  ['499', { dates => $date }],
          
  'position'
);
```
```
# [{Calendar Date (TDB) => A.D. 2026-Apr-12 00:00:00.0000, JDTDB => 2461142.500000000, VX => 6.511407089780921E+00, VY => 2.565403899986164E+01, VZ => 3.779598135296425E-01, X => 2.009557804368319E+08, Y => -4.837633215147470E+07, Z => -5.915289234365197E+06}]
```

Define a location on Earth (Moscow):

```raku
my $pos = (55.7505, 37.6175);
```
```
# (55.7505 37.6175)
```

Get the azimuth and elevation of the Moon as seen from Moscow for the next 12 hours:

```raku
my @dates = do with DateTime.now { ($_, $_.later(:12hours), $_.later(minutes => 12*60 + 10))};
@dates = @dates.map({ "{.year}-{.month.fmt('%02s')}-{.day.fmt('%02s')}" });

horizons-ephemeris-data(
  'observer',
  {
      target => '301', 
      center => $pos, 
      :@dates
  },
  'all',
  :modifier<dataset>
);
```
```
# [{/r => 0.9650163, 1-way_down_LT => 3.9323841123E+05, 399_ins_LT => -37.612316, APmag => n.a., Ang-diam => 287949.1, App_Lon_Sun => 257.0483, Area_3sig => n.a., Azi_(a-app) => 1653.945, Cnst => 82.464, DEC_(ICRF) => , DEC_(ICRF-a-app) => 48.7094620, DEC_(a-app) => -20.08113, DEC_3sigma => 0.000354, DOP_S_3sig => n.a., DOP_X_3sig => n.a., Date_________JDUT => 2461142.500000000, Def_illu => 5.620, Elev_(a-app) => 518.2465, GlxLat => 67.99522, GlxLon => 271.57141, I_d(DEC)/dt => -        20.08144, I_dRA*cosD => 315.73674, Illu% => -9.202, L_Ap_Hour_Ang => n.a., L_Ap_SOL_Time => 27.636889, L_Ap_Sid_Time => n.a., Lun_Sky_Brt => 72.602164, MN_Illu% => 110.4423, N.Pole-DC => -3.1132741, N.Pole-RA => 312.7140735, NP.ang => 72.15, NP.dist => -853.92, O-P-T => 0.0000, ObsEcLat => 69.185618, ObsEcLon => Cap, ObsSub-LAT => 1822.638, ObsSub-LON => *, PAB-LAT => 110.4443, PAB-LON => -5.218814985, POS_3sigma => n.a., PlAng => 252.258, PsAMV => n.a., PsAng => 32.5352, R.A._(ICRF) => , R.A._(a-app) => 315.73894, RA_(ICRF-a-app) => -2.7307, RA_3sigma => 2.4931584775, RNGRT_3sig => n.a., RNG_3sigma => n.a., RT_delay_3sig => n.a., RelVel-ANG => 28.887304, S-O-T => 29.3223939, S-T-O => 69.4168, S-brt => n.a., SMAA_3sig => n.a., SMIA_3sig => n.a., SN.ang => 243.405897, SN.dist => 1.087721, SatPANG => n.a., Sky_mot_PA => 515.0509, Sky_motion => 1654.943, SunSub-LAT => 3.779346, SunSub-LON => 353.977365, T-O-M => /L, TDB-UT => 3.26344, Theta => n.a., Tru_Anom => n.a., UT1-UTC => n.a., VmagOb => 0.02186170, VmagSn => -0.2978766, X_(sat-prim) => 675.19, Y_(sat-prim) => 466.45, a-mass => n.a., ang-sep => 32.53516, d(DEC)/dt => -19.97756, d(ELV)/dt => -10.077869, dAZ*cosE => 110.826491, dRA*cosD => 316.11284, deldot => -0.3394243, delta => 1.498023722E+08, hEcl-Lat => 909.337, hEcl-Lon => 344.7230, mag_ex => 15.8553742199, phi => n.a., r => 201.8768, rdot => -0.0042, sky_SNR => -17.98148, vis. => 1229.640} {/r => 1.0344294, 1-way_down_LT => 3.8797288474E+05, 399_ins_LT => -46.738640, APmag => n.a., Ang-diam => 280542.6, App_Lon_Sun => 263.9097, Area_3sig => n.a., Azi_(a-app) => 1756.465, Cnst => 73.909, DEC_(ICRF) => , DEC_(ICRF-a-app) => 50.1537916, DEC_(a-app) => -15.09860, DEC_3sigma => 0.000354, DOP_S_3sig => n.a., DOP_X_3sig => n.a., Date_________JDUT => 2461143.500000000, Def_illu => 5.862, Elev_(a-app) => 683.1413, GlxLat => 67.98781, GlxLon => 271.56388, I_d(DEC)/dt => -        15.09948, I_dRA*cosD => 328.03551, Illu% => -8.629, L_Ap_Hour_Ang => n.a., L_Ap_SOL_Time => 39.670343, L_Ap_Sid_Time => n.a., Lun_Sky_Brt => 68.747463, MN_Illu% => 122.1856, N.Pole-DC => -2.0470160, N.Pole-RA => 325.4144775, NP.ang => 68.89, NP.dist => -781.71, O-P-T => 0.0000, ObsEcLat => 69.185614, ObsEcLon => Cap, ObsSub-LAT => 1847.375, ObsSub-LON => *, PAB-LAT => 122.1888, PAB-LON => -5.971922631, POS_3sigma => n.a., PlAng => 248.974, PsAMV => n.a., PsAng => 23.3645, R.A._(ICRF) => , R.A._(a-app) => 328.03860, RA_(ICRF-a-app) => -2.1173, RA_3sigma => 2.4974327612, RNGRT_3sig => n.a., RNG_3sigma => n.a., RT_delay_3sig => n.a., RelVel-ANG => 31.410589, S-O-T => 29.1232436, S-T-O => 57.6888, S-brt => n.a., SMAA_3sig => n.a., SMIA_3sig => n.a., SN.ang => 231.195304, SN.dist => 1.098205, SatPANG => n.a., Sky_mot_PA => 680.6172, Sky_motion => 1757.444, SunSub-LAT => 2.386089, SunSub-LON => 353.476115, T-O-M => /L, TDB-UT => 2.19327, Theta => n.a., Tru_Anom => n.a., UT1-UTC => n.a., VmagOb => 0.02156897, VmagSn => -0.3168424, X_(sat-prim) => 682.43, Y_(sat-prim) => 494.25, a-mass => n.a., ang-sep => 23.36449, d(DEC)/dt => -14.97586, d(ELV)/dt => -12.099241, dAZ*cosE => 98.901756, dRA*cosD => 328.39509, deldot => -0.2584441, delta => 1.497762715E+08, hEcl-Lat => 922.887, hEcl-Lon => 341.6949, mag_ex => 15.9210831588, phi => n.a., r => 202.8425, rdot => -0.0013, sky_SNR => -17.83930, vis. => 1415.745} {/r => 1.0344294, 1-way_down_LT => 3.8797288474E+05, 399_ins_LT => -46.738640, APmag => n.a., Ang-diam => 280542.6, App_Lon_Sun => 263.9097, Area_3sig => n.a., Azi_(a-app) => 1756.465, Cnst => 73.909, DEC_(ICRF) => , DEC_(ICRF-a-app) => 50.1537916, DEC_(a-app) => -15.09860, DEC_3sigma => 0.000354, DOP_S_3sig => n.a., DOP_X_3sig => n.a., Date_________JDUT => 2461143.500000000, Def_illu => 5.862, Elev_(a-app) => 683.1413, GlxLat => 67.98781, GlxLon => 271.56388, I_d(DEC)/dt => -        15.09948, I_dRA*cosD => 328.03551, Illu% => -8.629, L_Ap_Hour_Ang => n.a., L_Ap_SOL_Time => 39.670343, L_Ap_Sid_Time => n.a., Lun_Sky_Brt => 68.747463, MN_Illu% => 122.1856, N.Pole-DC => -2.0470160, N.Pole-RA => 325.4144775, NP.ang => 68.89, NP.dist => -781.71, O-P-T => 0.0000, ObsEcLat => 69.185614, ObsEcLon => Cap, ObsSub-LAT => 1847.375, ObsSub-LON => *, PAB-LAT => 122.1888, PAB-LON => -5.971922631, POS_3sigma => n.a., PlAng => 248.974, PsAMV => n.a., PsAng => 23.3645, R.A._(ICRF) => , R.A._(a-app) => 328.03860, RA_(ICRF-a-app) => -2.1173, RA_3sigma => 2.4974327612, RNGRT_3sig => n.a., RNG_3sigma => n.a., RT_delay_3sig => n.a., RelVel-ANG => 31.410589, S-O-T => 29.1232436, S-T-O => 57.6888, S-brt => n.a., SMAA_3sig => n.a., SMIA_3sig => n.a., SN.ang => 231.195304, SN.dist => 1.098205, SatPANG => n.a., Sky_mot_PA => 680.6172, Sky_motion => 1757.444, SunSub-LAT => 2.386089, SunSub-LON => 353.476115, T-O-M => /L, TDB-UT => 2.19327, Theta => n.a., Tru_Anom => n.a., UT1-UTC => n.a., VmagOb => 0.02156897, VmagSn => -0.3168424, X_(sat-prim) => 682.43, Y_(sat-prim) => 494.25, a-mass => n.a., ang-sep => 23.36449, d(DEC)/dt => -14.97586, d(ELV)/dt => -12.099241, dAZ*cosE => 98.901756, dRA*cosD => 328.39509, deldot => -0.2584441, delta => 1.497762715E+08, hEcl-Lat => 922.887, hEcl-Lon => 341.6949, mag_ex => 15.9210831588, phi => n.a., r => 202.8425, rdot => -0.0013, sky_SNR => -17.83930, vis. => 1415.745}]
```

Get the orbital elements of Saturn's moon Pandora for a specific list of date-times:

```raku
horizons-ephemeris-data(
  'orbital-elements',
  ['617', {
    center => '699',
    dates => [
      'Mon 10 Jan 2000 00:00:00',
      'Tue 11 Jan 2000 00:00:00'
    ]
  }],
  'all',
  :modifier<association>
);
```
```
# {2451553.500000000 => {ApoapsisDistance => 1.433743106559601E+05, AscendingNodeLongitude => 1.696335315019282E+02, Calendar Date (TDB) => A.D. 2000-Jan-10 00:00:00.0000, Date => 2451553.500000000, Eccentricity => 7.172397742012902E-03, Inclination => 2.805499635514195E+01, MeanAnomaly => 3.268105687601845E+02, MeanMotion => 6.570065022861554E-03, OrbitalPeriod => 5.479397825551567E+04, PeriapsisDate => 2.451553558467752E+06, PeriapsisDistance => 1.413322817355549E+05, PerifocusArgument => 1.592125915955030E+02, SemiMajorAxis => 1.423532961957575E+05, TrueAnomaly => 3.263572600664454E+02}, 2451554.500000000 => {ApoapsisDistance => 1.427587809891930E+05, AscendingNodeLongitude => 1.696327742925100E+02, Calendar Date (TDB) => A.D. 2000-Jan-11 00:00:00.0000, Date => 2451554.500000000, Eccentricity => 2.891206540971475E-03, Inclination => 2.805729862777266E+01, MeanAnomaly => 6.597381843160082E+01, MeanMotion => 6.570485300699162E-03, OrbitalPeriod => 5.479047338583843E+04, PeriapsisDate => 2.451554383785470E+06, PeriapsisDistance => 1.419356705287859E+05, PerifocusArgument => 2.728440191077048E+02, SemiMajorAxis => 1.423472257589894E+05, TrueAnomaly => 6.627686610268884E+01}}
```

----

## Client object

```raku
use WWW::HorizonsEphemerisSystem;

my $client = horizons-client();
```
```
# WWW::HorizonsEphemerisSystem::Client::WWW::HorizonsEphemerisSystem::Client.new(api-url => "https://ssd.jpl.nasa.gov/api/horizons.api", expected-api-version => "1.3", strict-version-check => Bool::False)
```

----

## Client usage example

```raku
my $horizons = WWW::HorizonsEphemerisSystem::Client.new;

my $response = $horizons.observer-ephemeris(
    format      => 'json',
    COMMAND     => "'499'",
    OBJ_DATA    => 'YES',
    MAKE_EPHEM  => 'YES',
    CENTER      => "'500@399'",
    START_TIME  => "'2006-01-01'",
    STOP_TIME   => "'2006-01-20'",
    STEP_SIZE   => "'1 d'",
    QUANTITIES  => "'1,9,20,23,24,29'",
);

say $response.api-version;
say $response.result;
```
```
# 1.2
# *******************************************************************************
#  Revised: June 02, 2025                 Mars                            499 / 4
#  
#  PHYSICAL DATA (updated 2025-Jun-02):
#   Vol. mean radius (km) = 3389.92+-0.04   Density (g/cm^3)      =  3.933(5+-4)
#   Mass x10^23 (kg)      =    6.4171       Flattening, f         =  1/169.779
#   Volume (x10^10 km^3)  =   16.318        Equatorial radius (km)=  3396.19
#   Sidereal rot. period  =   24.622962 hr  Sid. rot. rate, rad/s =  0.0000708822 
#   Mean solar day (sol)  =   88775.24415 s Polar gravity m/s^2   =  3.758
#   Core radius (km)      = ~1700           Equ. gravity  m/s^2   =  3.71
#   Geometric Albedo      =    0.150                                              
# 
#   GM (km^3/s^2)         = 42828.375662    Mass ratio (Sun/Mars) = 3098703.59
#   GM 1-sigma (km^3/s^2) = +- 0.00028      Mass of atmosphere, kg= ~ 2.5 x 10^16
#   Mean temperature (K)  =  210            Atmos. pressure (bar) =    0.0056 
#   Obliquity to orbit    =   25.19 deg     Max. angular diam.    =  17.9"
#   Mean sidereal orb per =    1.88081578 y Visual mag. V(1,0)    =  -1.52
#   Mean sidereal orb per =  686.98 d       Orbital speed,  km/s  =  24.13
#   Hill's sphere rad. Rp =  319.8          Escape speed, km/s    =   5.027
#                                  Perihelion  Aphelion    Mean
#   Solar Constant (W/m^2)         717         493         589
#   Maximum Planetary IR (W/m^2)   470         315         390
#   Minimum Planetary IR (W/m^2)    30          30          30
# *******************************************************************************
# 
# 
# *******************************************************************************
# Ephemeris / API_USER Sun Apr 12 13:36:17 2026 Pasadena, USA      / Horizons    
# *******************************************************************************
# Target body name: Mars (499)                      {source: mar099}
# Center body name: Earth (399)                     {source: DE441}
# Center-site name: GEOCENTRIC
# *******************************************************************************
# Start time      : A.D. 2006-Jan-01 00:00:00.0000 UT      
# Stop  time      : A.D. 2006-Jan-20 00:00:00.0000 UT      
# Step-size       : 1440 minutes
# *******************************************************************************
# Target pole/equ : IAU_MARS                        {West-longitude positive}
# Target radii    : 3396.19, 3396.19, 3376.2 km     {Equator_a, b, pole_c}       
# Center geodetic : 0.0, 0.0, -6378.137             {E-lon(deg),Lat(deg),Alt(km)}
# Center cylindric: 0.0, 0.0, 0.0                   {E-lon(deg),Dxy(km),Dz(km)}
# Center pole/equ : ITRF93                          {East-longitude positive}
# Center radii    : 6378.137, 6378.137, 6356.752 km {Equator_a, b, pole_c}       
# Target primary  : Sun
# Vis. interferer : MOON (R_eq= 1737.400) km        {source: DE441}
# Rel. light bend : Sun                             {source: DE441}
# Rel. lght bnd GM: 1.3271E+11 km^3/s^2                                          
# Atmos refraction: NO (AIRLESS)
# RA format       : HMS
# Time format     : CAL 
# Calendar mode   : Mixed Julian/Gregorian
# EOP file        : eop.260410.p260707                                           
# EOP coverage    : DATA-BASED 1962-JAN-20 TO 2026-APR-10. PREDICTS-> 2026-JUL-06
# Units conversion: 1 au= 149597870.700 km, c= 299792.458 km/s, 1 day= 86400.0 s 
# Table cut-offs 1: Elevation (-90.0deg=NO ),Airmass (>38.000=NO), Daylight (NO )
# Table cut-offs 2: Solar elongation (  0.0,180.0=NO ),Local Hour Angle( 0.0=NO )
# Table cut-offs 3: RA/DEC angular rate (     0.0=NO )                           
# **************************************************************************************************************************
#  Date__(UT)__HR:MN     R.A._____(ICRF)_____DEC    APmag   S-brt             delta      deldot     S-O-T /r     S-T-O  Cnst
# **************************************************************************************************************************
# $$SOE
#  2006-Jan-01 00:00     02 32 15.02 +16 35 29.9   -0.597   4.456  0.77519869764264  14.7500341  120.6420 /T   33.5358   Ari
#  2006-Jan-02 00:00     02 33 13.14 +16 40 57.7   -0.571   4.457  0.78375024572645  14.8614541  119.8715 /T   33.8025   Ari
#  2006-Jan-03 00:00     02 34 13.47 +16 46 32.6   -0.550   4.453  0.79236500521378  14.9689214  119.1098 /T   34.0595   Ari
#  2006-Jan-04 00:00     02 35 15.96 +16 52 14.5   -0.523   4.454  0.80104071550073  15.0725261  118.3569 /T   34.3070   Ari
#  2006-Jan-05 00:00     02 36 20.56 +16 58 02.8   -0.487   4.465  0.80977518809526  15.1724248  117.6126 /T   34.5451   Ari
#  2006-Jan-06 00:00     02 37 27.23 +17 03 57.5   -0.440   4.488  0.81856633892153  15.2688184  116.8766 /T   34.7742   Ari
#  2006-Jan-07 00:00     02 38 35.91 +17 09 58.0   -0.422   4.481  0.82741220692898  15.3619283  116.1487 /T   34.9944   Ari
#  2006-Jan-08 00:00     02 39 46.57 +17 16 04.2   -0.405   4.474  0.83631095987380  15.4519763  115.4287 /T   35.2060   Ari
#  2006-Jan-09 00:00     02 40 59.14 +17 22 15.6   -0.371   4.484  0.84526089082616  15.5391730  114.7164 /T   35.4092   Ari
#  2006-Jan-10 00:00     02 42 13.60 +17 28 32.0   -0.328   4.502  0.85426040925600  15.6237103  114.0116 /T   35.6041   Ari
#  2006-Jan-11 00:00     02 43 29.89 +17 34 53.2   -0.313   4.494  0.86330802951239  15.7057591  113.3142 /T   35.7911   Ari
#  2006-Jan-12 00:00     02 44 47.97 +17 41 18.7   -0.303   4.479  0.87240235823975  15.7854680  112.6238 /T   35.9702   Ari
#  2006-Jan-13 00:00     02 46 07.80 +17 47 48.3   -0.279   4.480  0.88154208138094  15.8629630  111.9404 /T   36.1417   Ari
#  2006-Jan-14 00:00     02 47 29.34 +17 54 21.7   -0.266   4.470  0.89072595104293  15.9383472  111.2637 /T   36.3058   Ari
#  2006-Jan-15 00:00     02 48 52.56 +18 00 58.7   -0.244   4.468  0.89995277250819  16.0117018  110.5935 /T   36.4627   Ari
#  2006-Jan-16 00:00     02 50 17.42 +18 07 39.0   -0.225   4.463  0.90922139183063  16.0830870  109.9297 /T   36.6124   Ari
#  2006-Jan-17 00:00     02 51 43.88 +18 14 22.3   -0.228   4.437  0.91853068454968  16.1525452  109.2722 /T   36.7553   Ari
#  2006-Jan-18 00:00     02 53 11.91 +18 21 08.4   -0.198   4.445  0.92787954597364  16.2201032  108.6207 /T   36.8914   Ari
#  2006-Jan-19 00:00     02 54 41.49 +18 27 57.0   -0.176   4.444  0.93726688321527  16.2857753  107.9751 /T   37.0209   Ari
#  2006-Jan-20 00:00     02 56 12.58 +18 34 48.0   -0.161   4.437  0.94669160877907  16.3495662  107.3353 /T   37.1439   Ari
# $$EOE
# **************************************************************************************************************************
# Column meaning:
#  
# TIME
# 
#   Times PRIOR to 1962 are UT1, a mean-solar time closely related to the
# prior but now-deprecated GMT. Times AFTER 1962 are in UTC, the current
# civil or "wall-clock" time-scale. UTC is kept within 0.9 seconds of UT1
# using integer leap-seconds for 1972 and later years.
# 
#   Conversion from the internal Barycentric Dynamical Time (TDB) of solar
# system dynamics to the non-uniform civil UT time-scale requested for output
# has not been determined for UTC times after the next July or January 1st.
# Therefore, the last known leap-second is used as a constant over future
# intervals.
# 
#   Time tags refer to the UT time-scale conversion from TDB on Earth
# regardless of observer location within the solar system, although clock
# rates may differ due to the local gravity field and no analog to "UT"
# may be defined for that location.
# 
#   Any 'b' symbol in the 1st-column denotes a B.C. date. First-column blank
# (" ") denotes an A.D. date.
#  
# CALENDAR SYSTEM
# 
#   Mixed calendar mode was active such that calendar dates after AD 1582-Oct-15
# (if any) are in the modern Gregorian system. Dates prior to 1582-Oct-5 (if any)
# are in the Julian calendar system, which is automatically extended for dates
# prior to its adoption on 45-Jan-1 BC.  The Julian calendar is useful for
# matching historical dates. The Gregorian calendar more accurately corresponds
# to the Earth's orbital motion and seasons. A "Gregorian-only" calendar mode is
# available if such physical events are the primary interest.
# 
#   NOTE: "n.a." in output means quantity "not available" at the print-time.
#  
#  'R.A._____(ICRF)_____DEC' =
#   Astrometric right ascension and declination of the target center with
# respect to the observing site (coordinate origin) in the reference frame of
# the planetary ephemeris (ICRF). Compensated for down-leg light-time delay
# aberration.
# 
#   Units: RA  in hours-minutes-seconds of time,    HH MM SS.ff{ffff}
#          DEC in degrees-minutes-seconds of arc,  sDD MN SC.f{ffff}
#  
#  'APmag   S-brt' =
#   The targets' approximate apparent visual magnitude and surface brightness.
# For planets and natural satellites, output is restricted to solar phase angles
# covered by observational data. Outside the observed phase angle range, "n.a."
# may be output to avoid extrapolation beyond the limit of model validity.
# 
#    For Earth-based observers, the estimated dimming due to atmospheric
# absorption (extinction) is available as a separate, requestable quantity.
# 
#    Surface brightness is the average airless visual magnitude of a
# square-arcsecond of the illuminated portion of the apparent disk. It is
# computed only if the target radius is known.
# 
#    Units: MAGNITUDES & MAGNITUDES PER SQUARE ARCSECOND
#  
#  'delta      deldot' =
#    Apparent range ("delta", light-time aberrated) and range-rate ("delta-dot")
# of the target center relative to the observer. A positive "deldot" means the
# target center is moving away from the observer, negative indicates movement
# toward the observer.  Units: AU and KM/S
#  
#  'S-O-T /r' =
#    Sun-Observer-Target apparent SOLAR ELONGATION ANGLE seen from the observers'
# location at print-time.
# 
#    The '/r' column provides a code indicating the targets' apparent position
# relative to the Sun in the observers' sky, as described below:
# 
#    Case A: For an observing location on the surface of a rotating body, that
# body rotational sense is considered:
# 
#     /T indicates target TRAILS Sun   (evening sky: rises and sets AFTER Sun)
#     /L indicates target LEADS Sun    (morning sky: rises and sets BEFORE Sun)
# 
#    Case B: For an observing point that does not have a rotational model (such
# as a spacecraft), the "leading" and "trailing" condition is defined by the
# observers' heliocentric ORBITAL motion:
# 
#     * If continuing in the observers' current direction of heliocentric
#        motion would encounter the targets' apparent longitude first, followed
#        by the Sun's, the target LEADS the Sun as seen by the observer.
# 
#     * If the Sun's apparent longitude would be encountered first, followed
#        by the targets', the target TRAILS the Sun.
# 
#    Two other codes can be output:
#     /* indicates observer is Sun-centered    (undefined)
#     /? Target is aligned with Sun center     (no lead or trail)
# 
#    The S-O-T solar elongation angle is numerically the minimum separation
# angle of the Sun and target in the sky in any direction. It does NOT indicate
# the amount of separation in the leading or trailing directions, which would
# be defined along the equator of a spherical coordinate system.
# 
#    Units: DEGREES
#  
#  'S-T-O' =
#    The Sun-Target-Observer angle; the interior vertex angle at target center
# formed by a vector from the target to the apparent center of the Sun (at
# reflection time on the target) and the apparent vector from target to the
# observer at print-time. Slightly different from true PHASE ANGLE (requestable
# separately) at the few arcsecond level in that it includes stellar aberration
# on the down-leg from target to observer.  Units: DEGREES
#  
#  'Cnst' =
#    Constellation ID; the 3-letter abbreviation for the name of the
# constellation containing the target centers' astrometric position,
# as defined by IAU (1930) boundary delineation.  See documentation
# for list of abbreviations.
# 
# Computations by ...
# 
#     Solar System Dynamics Group, Horizons On-Line Ephemeris System
#     4800 Oak Grove Drive, Jet Propulsion Laboratory
#     Pasadena, CA  91109   USA
# 
#     General site: https://ssd.jpl.nasa.gov/
#     Mailing list: https://ssd.jpl.nasa.gov/email_list.html
#     System news : https://ssd.jpl.nasa.gov/horizons/news.html
#     User Guide  : https://ssd.jpl.nasa.gov/horizons/manual.html
#     Connect     : browser        https://ssd.jpl.nasa.gov/horizons/app.html#/x
#                   API            https://ssd-api.jpl.nasa.gov/doc/horizons.html
#                   command-line   telnet ssd.jpl.nasa.gov 6775
#                   e-mail/batch   https://ssd.jpl.nasa.gov/ftp/ssd/horizons_batch.txt
#                   scripts        https://ssd.jpl.nasa.gov/ftp/ssd/SCRIPTS
#     Author      : Jon.D.Giorgini@jpl.nasa.gov
# 
# **************************************************************************************************************************
```

-----

## Implementation details

- The first version -- 0.0.1 -- was made using ChatGPT Codex with "gpt-5.3-codex" over the API spec [horizons.html](https://ssd-api.jpl.nasa.gov/doc/horizons.html).

- The client object is fairly non-useful computations-wise -- it "only retrieves."

- The "top level" sub `horizons-ephemeris-data` aims to produce computation-ready outputs, that are Raku data structures.

- The overall functionalities design is very similar to the Wolfram Language [`HorizonsEphemerisData`](https://resources.wolframcloud.com/FunctionRepository/resources/HorizonsEphemerisData), [TTf1].
  - The [Raku spec](./resources/HorizonsEphemerisData-spec-Raku.md) given to ChatGPT was made from the Wolfram Language documentation of [TTf1].

----

## References

[JJp1] José Joaquín Atria,
[HTTP::Tiny, Raku package](https://gitlab.com/jjatria/http-tiny),
(2020-2025),
[GitLab/jjatria](https://gitlab.com/jjatria).

[TTf1] Truman Tapia,
[HorizonsEphemerisData, Wolfram Language Function](https://resources.wolframcloud.com/FunctionRepository/resources/HorizonsEphemerisData),
(2022),
[Wolfram Function Repository](https://resources.wolframcloud.com/FunctionRepository).

