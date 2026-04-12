# horizons-ephemeris-data

Import ephemeris data from the Jet Propulsion Laboratory Horizons System.

## Spec

### Usage

`horizons-ephemeris-data($etype, $query, $properties, :$modifier)`
queries the [Horizons System](https://ssd.jpl.nasa.gov/horizons/) and returns values of the requested properties for the given query and ephemeris type.

### Details & Options

- `horizons-ephemeris-data` retrieves data from [Horizons System](https://ssd.jpl.nasa.gov/horizons/) using [Horizons API](https://ssd-api.jpl.nasa.gov/doc/horizons.html).
- Horizons System has ephemerides of planets, natural satellites, spacecraft, asteroids, comets, and several dynamical points.
- `$etype` can be one of: `state`, `orbital-elements`, `observer`.
- Each ephemeris type has its own query parameters and properties.

- Queries can be specified in these forms:

| Form                                                             | Meaning                                                   |
|------------------------------------------------------------------|-----------------------------------------------------------|
| `$target`                                                        | query with target specified with default parameter values |
| `[$target, { param-1 => val-1, param-2 => val-2, ... }]`         | query with detailed parameters specified                  |
| `{ target => $target, param-1 => val-1, param-2 => val-2, ... }` | query with detailed parameters specified                  |

- Valid query parameters for an ephemeris type can be obtained with `horizons-ephemeris-data($etype, 'query-parameters')`.
- Properties available for an ephemeris type can be obtained with `horizons-ephemeris-data($etype, 'properties')`.

- Query parameters for `state`:

| Value         | Default                   | Meaning                                                                                                         |
|---------------|---------------------------|-----------------------------------------------------------------------------------------------------------------|
| `center`      | `solar-system-barycenter` | center of the reference frame and reference place to apply corrections                                          |
| `dates`       | `now`                     | dates used in ephemeris output                                                                                  |
| `frame`       | `icrf`                    | frame used in ephemeris output. Can be `icrf`, `fk4`, `ecliptic-j2000`, `ecliptic-b1950`, `center-body-equator` |
| `corrections` | `none`                    | corrections applied. Can be `none`, `light-time`, `light-time+stellar-aberration`                               |

- Not all properties of `state` can be obtained in one call.

- Query parameters for `orbital-elements`:

| Value    | Default                   | Meaning                                                                                                         |
|----------|---------------------------|-----------------------------------------------------------------------------------------------------------------|
| `center` | `solar-system-barycenter` | center of the reference frame                                                                                   |
| `dates`  | `now`                     | dates used in ephemeris output                                                                                  |
| `frame`  | `icrf`                    | frame used in ephemeris output. Can be `icrf`, `fk4`, `ecliptic-j2000`, `ecliptic-b1950`, `center-body-equator` |

- Query parameters for `observer`:

| Value                          | Default    | Meaning                                                                               |
|--------------------------------|------------|---------------------------------------------------------------------------------------|
| `center`                       | `here`     | center of observation                                                                 |
| `dates`                        | `now`      | dates used in ephemeris output                                                        |
| `earth-atmospheric-refraction` | `False`    | whether atmospheric refraction corrections are applied                                |
| `skip-day`                     | `False`    | whether dates during day are skipped                                                  |
| `rise-transit-set-only`        | `False`    | return ephemeris only at rise/transit/set events                                      |
| `min-elevation`                | `-90`      | include only times with elevation above this value (degrees)                          |
| `max-relative-airmass`         | `38`       | include only times with relative airmass below this value                             |
| `min-max-solar-elongation`     | `[0, 180]` | include only times with solar elongation inside these limits (degrees)                |
| `max-angular-rate`             | `Inf`      | include only times with angular rate below this value (arcseconds/hour or equivalent) |

- The target and `center` can be specified as:
  - supported object identifiers (strings),
  - keyword-like strings accepted by Horizons,
  - TLE strings,
  - location tuples `(lat, lon)` or `(lat, lon, h)`.

- A location tuple follows latitude-first convention: `(lat, lon)` or `(lat, lon, h)`.
- Time quantities are specified as strings such as `1 h`, `10 m`, `1 d`.
- `dates` can be:
  - one date-time string,
  - a list of date-time strings,
  - `[start-date, end-date, step]` where `step` is a string like `1 h`.

- Modifiers:

| Value         | Description                                                                           |
|---------------|---------------------------------------------------------------------------------------|
| `association` | nested associative structure with dates at first level and properties at second level |
| `dataset`     | tabular dataset-like structure equivalent to `association`                            |

## Examples

### Basic Examples

Get the Cartesian position of Mars with default parameters:

```raku
horizons-ephemeris-data('state', '499', 'position');
```

Get the position of Mars for a specific date:

```raku
horizons-ephemeris-data(
  'state',
  ['499', { dates => 'now + 12 h' }],
  'position'
);
```

Define a location on Earth (Moscow):

```raku
my $pos = (55.7505, 37.6175);
```

Get the azimuth and elevation of the Tycho crater as seen from Moscow for the next 12 hours:

```raku
horizons-ephemeris-data(
  'observer',
  {
    target => 'Tycho',
    center => $pos,
    dates => ['now', 'now + 12 h', '10 m']
  },
  'all',
  :modifier<dataset>
);
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

### Scope

Define a location on Mars:

```raku
my $mars-pos = 499 => (-4.5, -137.4);
```

Get all properties of `observer` for this Mars location as seen from Earth, applying atmospheric refraction and skipping daytime values:

```raku
horizons-ephemeris-data(
  'observer',
  [$mars-pos, {
    center => 'here',
    earth-atmospheric-refraction => True,
    skip-day => True,
    dates => ['now', 'now + 24 h', '1 h']
  }],
  'all',
  :modifier<dataset>
);
```

Define a TLE:

```raku
my $tle = q:to/TLE/;
1 11416U 79057A   04363.14000343  .00000107  00000-0  56512-4 0  5663
2 11416  98.5474  30.2466 0011085  51.8150 308.4039 14.31601235328172
1 11416U 79057A   04363.62924579  .00000108  00000-0  56923-4 0  5681
2 11416  98.5473  30.7281 0011072  50.5542 309.6625 14.31601418328243
TLE
```

Get position for this TLE seen from ISS (Horizons ID `-125544`):

```raku
horizons-ephemeris-data(
  'state',
  [$tle, {
    center => '@-125544',
    dates => ['Sun 09 Jan 2005 00:00:00', 'Mon 10 Jan 2005 00:00:00', '1 h'],
    frame => 'icrf',
    corrections => 'none'
  }],
  'position',
  :modifier<dataset>
);
```

### Possible Issues

When multiple objects match the target specification, a dataset-like result can be returned with candidates.
Use a returned Horizons ID to uniquely identify the object.

Example:

```raku
horizons-ephemeris-data('state', 'iss', 'all');
horizons-ephemeris-data('state', '-125544', 'all');
```

### Neat Examples

Get the trajectory of Cassini around Saturn (Cassini Horizons ID `-82`):

```raku
my $cassini = horizons-ephemeris-data(
  'state',
  ['-82', {
    center => '699',
    dates => ['Thu 16 Oct 1997 00:00:00', 'Fri 15 Sep 2017 00:00:04', '1 d']
  }],
  'position'
);
```

## Source & Additional Information

### Keywords

- JPL
- jet propulsion lab
- astronomy
- ephemeris
- ephemerides
- horizons
- astronomical data
- solar system
- planet
- spacecraft

### Categories

- external interfaces and connections
- scientific and medical data and computation
- time-related computation

### Related Packages

- DSL::Entity::Geographics
- Data::Geographics

### Source/Reference Citation

Giorgini, J.D., JPL Solar System Dynamics Group, "NASA/JPL Horizons On-Line Ephemeris System." [https://ssd.jpl.nasa.gov/horizons](https://ssd.jpl.nasa.gov/horizons). Data retrieved 2022-04-16.

Giorgini, J. D., Chodas, P.W., Yeomans, D.K., "Orbit Uncertainty and Close-Approach Analysis Capabilities of the Horizons On-Line Ephemeris System." 33rd AAS/DPS meeting in New Orleans, LA, Nov 26, 2001--Dec 01, 2001.

Giorgini, J. D, Yeomans, D.K., "On-Line System Provides Accurate Ephemeris and Related Data." NASA Tech Briefs, NPO-20416, p. 48, 1999.

Giorgini, J.D., Yeomans, D.K., Chamberlin, A.B., Chodas, P.W., Jacobson, R.A., Keesey, M.S., Lieske, J.H., Ostro, S.J., Standish, E.M., Wimberly, R.N., "JPL's On-Line Solar System Data Service." Bulletin of the American Astronomical Society, Vol 28, No. 3, p. 1158, 1996.

### Links

- [Horizon API](https://ssd-api.jpl.nasa.gov/doc/horizons.html)
