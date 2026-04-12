# HorizonsEphemerisData

Import ephemeris data from the Jet Propulsion Laboratory Horizons System

## Spec

### Usage

`HorizonsEphemerisData[etype, query, properties]` 
queries [Horizons System](https://ssd.jpl.nasa.gov/horizons/) and gives the values of the properties for the given query and ephemeris type etype.

### Details & Options

- `HorizonsEphemerisData` retrieves data from [Horizons System](https://ssd.jpl.nasa.gov/horizons/) using [Horizons API](https://ssd-api.jpl.nasa.gov/doc/horizons.html).

- Horizons System has ephemerides of planets, natural satellites, spacecrafts, asteroids, comets and several dynamical points.

- The parameter `etype` can take one of the following values: "State", "OrbitalElements" and "Observer". Each ephemeris type has its own query parameters and properties.

- Queries can be specified in the following forms:


| Form                                                                                                                | Meaning                                                   |
|---------------------------------------------------------------------------------------------------------------------|-----------------------------------------------------------|
| `target`	                                                                                                           | query with target specified with default parameter values |
| `{target, <\| "Subscript[param, 1]"->Subscript[val, 1], "Subscript[param, 1]"->Subscript[val, 2], ... \|>}`	        | query with detailed parameters specified                  |
| `<\| "Target"->target, "Subscript[param, 1]"->Subscript[val, 1], "Subscript[param, 1]"->Subscript[val, 2], ... \|>` | query with detailed parameters specified                  |

- The valid `"param "` parameters for query of a given etype can be obtained by evaluating `HorizonsEphemerisData`[etype, "QueryParameters"].
                 i
- The properties available for a given etype can be obtained by evaluating `HorizonsEphemerisData`[etype, "Properties"].

- The following are query parameters of the "State" ephemeris type:

| Value          | Default                  | Meaning                                                                                                                          |
|----------------|--------------------------|----------------------------------------------------------------------------------------------------------------------------------|
| "Center"	      | Solar System Barycenter	 | center of the reference frame and reference place to apply corrections                                                           |                                                          
| "Dates"	       | Now	                     | dates used in the ephemeris output                                                                                               |                                                             
| "Frame"	       | "ICRF"	                  | frame used in the ephemeris output. Can take the values: "ICRF", "FK4", "EclipticJ2000", "EclipticB1950" and "CenterBodyEquator" | 
| "Corrections"	 | None                     | 	corrections applied. Can take the values: None, "LightTime" and "LightTime+StellarAberration"                                   |



- Not all the properties of the "State" ephemeris type can be obtained in one call.

- Following the query parameters of the "OrbitalElements" ephemeris type:

| Field  | Value                  | Description                                                                 |
|--------|------------------------|-----------------------------------------------------------------------------|
| Center | Solar System Barycenter | center of the reference frame.                                              |
| Dates  | Now                    | dates used in the ephemeris output.                                         |
| Frame  | ICRF                   | frame used in the ephemeris output. Can take the values: ICRF, FK4, EclipticJ2000, EclipticB1950, and CenterBodyEquator. |

- Following the query parameters of the "Observer" ephemeris type:

| Field                    | Value        | Description                                                                 |
|--------------------------|--------------|-----------------------------------------------------------------------------|
| Center                   | Here         | center of observation.                                                      |
| Dates                    | Now          | dates used in the ephemeris output.                                         |
| EarthAtmosphericRefraction | False      | whether or not apply corrections due to the Earth's atmosphere.             |
| SkipDay                  | False        | whether or not skip dates during the day in the output.                     |
| RiseTransitSetOnly       | False        | return ephemeris data only when rise, transit or set is happening.          |
| MinElevation             | -90          | return ephemeris data only when the target elevation is higher than the value specified in degrees. |
| MaxRelativeAirmass       | 38           | return ephemeris data only when relative airmass is less than the specified value. |
| MinMaxSolarElongation    | {0,180}      | return ephemeris data only when the target's solar elongation angle is inside the limits specified in degrees. |
| MaxAngularRate           | Infinity     | return ephemeris data only when the target's angular rate is less than the value specified in "Arcseconds"/"Hours". The value can be a Quantity too. |

- The target and the parameter "Center" can be specified as [Entity](https://reference.wolfram.com/language/ref/Entity), [GeoPosition](https://reference.wolfram.com/language/ref/GeoPosition) or [String](https://reference.wolfram.com/language/ref/String). [Entity](https://reference.wolfram.com/language/ref/Entity) can be an object in the solar system. Also, entities of the type "SolarSystemFeature" are supported. [GeoPosition](https://reference.wolfram.com/language/ref/GeoPosition) can be a position on Earth or other object of the solar system. [String](https://reference.wolfram.com/language/ref/String) can be an Horizon's id used to identify an object of the solar system, two-line element set ([TLE](https://en.wikipedia.org/wiki/Two-line_element_set)) or a keyword.

- The ephemeris of an object defined by a TLE can be extrapolated only 14 days before and after the data.

- The query parameter "Dates" can be specified as a single [DateObject](https://reference.wolfram.com/language/ref/DateObject), a [List](https://reference.wolfram.com/language/ref/List) of DateObjects or with the syntax {`StartDate`, `EndDate`, increment}. To get the ephemeris of a big list of dates use the syntax {`StartDate`, `EndDate`, increment}.

- The following modifiers can be used in `HorizonsEphemerisData`[etype, query, properties, "modifier"]:

| Field       | Description                                                                                      |
|-------------|--------------------------------------------------------------------------------------------------|
| Association | a nested association with dates as keys on the first level and properties as keys on the second level |
| Dataset     | a dataset containing the same structure of the "Association" modifier                           |

## Examples

### Basic Examples

Get the Cartesian position of Mars with default parameters:

```wl
HorizonsEphemerisData["State", Entity["Planet", "Mars"], "Position"]
```


Get the position of Mars for a specific date:

```wl
HorizonsEphemerisData["State", {Entity["Planet", "Mars"], <|"Dates" -> Now + Quantity[12, "Hours"]|>}, "Position"]
```

Define a location on Earth:

```wl
pos = Entity["City", {"Riobamba", "Chimborazo", "Ecuador"}]["Position"];
```

Get the azimuth and elevation of the Tycho crater as seen from Riobamba city for the next 12 hours:

```wl
HorizonsEphemerisData["Observer", <|
  "Target" -> Entity["SolarSystemFeature", "TychoMoon"], 
  "Center" -> pos, 
  "Dates" -> {Now, Now + Quantity[12, "Hours"], 
    Quantity[10, "Minutes"]}|>, All, "Dataset"]
```

Get the orbital elements of Saturn's moon Pandora for a specific list of dates:

```wl
HorizonsEphemerisData["OrbitalElements", {Entity["PlanetaryMoon", 
   "Pandora"], <|"Center" -> Entity["Planet", "Saturn"], 
   "Dates" -> {DateObject[{2000, 1, 10, 0, 0, 0}, "Instant", "Gregorian", 0.`], 
     DateObject[{2000, 1, 11, 0, 0, 0}, "Instant", "Gregorian", 0.`]}|>}, All, "Association"]
```

### Scope

Define a location on Mars:

```wl
pos = GeoPosition[{-4.5, -137.4}, Entity["Planet", "Mars"]];
```

Get all the properties of the "Observer" ephemeris type for this location on Mars seen from a location in Earth, applying corrections due to atmospheric refraction and skipping the dates when it is day:

```wl
HorizonsEphemerisData["Observer", {pos, <|"Center" -> Here, 
   "EarthAtmosphericRefraction" -> True, "SkipDay" -> True, 
   "Dates" -> {Now, Now + Quantity[24, "Hours"], Quantity[1, "Hours"]}|>}, All, "Dataset"]
```

Define a TLE:

```wl
tle = "1 11416U 79057A   04363.14000343  .00000107  00000-0  56512-4 0  5663
2 11416  98.5474  30.2466 0011085  51.8150 308.4039 14.31601235328172
1 11416U 79057A   04363.62924579  .00000108  00000-0  56923-4 0  5681
2 11416  98.5473  30.7281 0011072  50.5542 309.6625 14.31601418328243
1 11416U 79057A   04364.67762161  .00000130  00000-0  65019-4 0  5674
2 11416  98.5470  31.7599 0011009  47.6294 312.5820 14.31602047328399
1 11416U 79057A   04365.65610603  .00000127  00000-0  64027-4 0  5704
2 11416  98.5468  32.7230 0010941  45.1722 315.0344 14.31602333328535
1 11416U 79057A   04366.42491512  .00000132  00000-0  65727-4 0  5687
2 11416  98.5467  33.4797 0010912  43.1795 317.0244 14.31602636328645
1 11416U 79057A   04366.70448198  .00000129  00000-0  64650-4 0  5691
2 11416  98.5464  33.7545 0010857  42.9225 317.2802 14.31602697328682";
```

Get the position of the object defined by this TLE seen from the ISS. The Horizons ID of the ISS is -125544 (see Possible Issues section). The character "@" means the center of the object in the Horizons `System`:


```wl
HorizonsEphemerisData["State", {tle, <|"Center" -> "@-125544", "Dates" -> {DateObject[{2005, 1, 9}], DateObject[{2005, 1, 10}], Quantity[1, "Hours"]}, "Frame" -> "ICRF", "Corrections" -> None|>}, "Position", "Dataset"]
```

### Possible Issues

When several objects in the Horizons `System` match the target specification, a `Dataset` is returned:

```wl
HorizonsEphemerisData["State", "ISS", All]
```

```text
 ResourceFunction::usermessage: HorizonsEphemerisData::multipletargets: Target specification match several objects in Horizons system. Choose an ID from the table bellow.
```

Use the ID to uniquely identify the object:

```wl
HorizonsEphemerisData["State", "-125544", All]
```

```wl
Out[] = {{DateObject[{2022, 6, 21, 21, 10, 54.646}, "Instant", "Gregorian", 
   0., "TDB"], Quantity[3445.12, "Kilometers"], 
  Quantity[-2526.58, "Kilometers"], Quantity[-8968.02, "Kilometers"], 
  Quantity[6.01083, ("Kilometers")/("Seconds")], 
  Quantity[-1.85033, ("Kilometers")/("Seconds")], 
  Quantity[3.96331, ("Kilometers")/("Seconds")], 
  Quantity[9933.67, "Kilometers"], 
  Quantity[-1.02278, ("Kilometers")/("Seconds")], 
  Quantity[0.0331352, "Seconds"]}}
```

### Neat Examples

Get the trajectory of the Cassini spacecraft around Saturn (the Horizons ID of Cassini is -82):

```wl
cassini =
HorizonsEphemerisData[
"State", {"-82", <|"Center" -> Entity["Planet", "Saturn"],
"Dates" -> {DateObject[{1997, 10, 16, 0, 0, 0.`}, "Instant", 
        "Gregorian", 0.`],
DateObject[{2017, 9, 15, 0, 0, 4.`}, "Instant", "Gregorian", 
        0.`], Quantity[1, "Days"]}|>}, "Position"];
```

Plot the fly of Cassini:

```wl
ListLinePlot3D[{cassini[[All, 2 ;;]]}, BoxRatios -> Automatic, PlotRange -> All, PlotStyle -> {Opacity[0.1, Blue]}, PlotRange -> All]
```


## Source & Additional Information

### Contributed By

Truman Tapia

### Keywords

- JPL

- jet propulsion lab

- Astronomy

- Ephemeris

- Ephemerides

- Horizons

- astronomical data

- solar system

- planet

- spacecraft

### Categories

- External Interfaces & Connections

- Scientific and Medical Data & Computation

- Time-Related Computation

### Related Symbols

- MinorPlanetData

- PlanetData

- PlanetaryMoonData

- CometData

### Related Resource Objects

- SIMBADData

- VizierCatalogData

- DeepSpaceNetData

- AstroAngularDistance

### Source/Reference Citation

Giorgini, J.D., JPL Solar System Dynamics Group, "NASA/JPL Horizons On-Line Ephemeris System." [https://ssd.jpl.nasa.gov/horizons](https://ssd.jpl.nasa.gov/horizons). Data retrieved 2022-04-16.

Giorgini, J. D., Chodas, P.W., Yeomans, D.K., "Orbit Uncertainty and Close-Approach Analysis Capabilities of the Horizons On-Line Ephemeris System." 33rd AAS/DPS meeting in New Orleans, LA, Nov 26, 2001--Dec 01, 2001.

Giorgini, J. D, Yeomans, D.K., "On-Line System Provides Accurate Ephemeris and Related Data." NASA Tech Briefs, NPO-20416, p. 48, 1999.

Giorgini, J.D., Yeomans, D.K., Chamberlin, A.B., Chodas, P.W., Jacobson, R.A., Keesey, M.S., Lieske, J.H., Ostro, S.J., Standish, E.M., Wimberly, R.N., "JPL's On-Line Solar System Data Service." Bulletin of the American Astronomical Society, Vol 28, No. 3, p. 1158, 1996.

### Links

- [Horizon API](https://ssd-api.jpl.nasa.gov/doc/horizons.html)
