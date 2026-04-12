
----

## First version

> Carefully analyze the content of "./resources/horizons.md" and implement the Raku package in this directory -- "WWW::HorizonsEphemerisSystem". Make sure you use the package "HTTP::Tiny" to make the API calls.

----

## From WL spec to Raku spec

> From Wolfram Language (WL) spec "./resources/HorizonsEphemerisData-spec-WL.md" make the Raku spec "./resources/HorizonsEphemerisData-spec-Raku.md":
> - Use kebab case instead of camel case, e.g. `horizons-ephemeris-data`
> - WL time quantities, like, `Quantity[1, "Hours"]` are transformed as "1 h"
> - WL `GeoPosition[...]` spec is a Raku list `(lat, lon)` or (lat, lon, h)`


----

## Raku implementation strategy

> Evaluate the WL imlplementation in "./resources/HorizonsEphemerisData-definitions-WL.md" and the Raku spec of  `&horizons-ephemeris-data` and propose Raku implementation strategy:
> - Should a client be used?
> - Should the WL functional programming style be preserved?
> - Which WL specific features do not have obvious or easy to implement Raku features?

**Recommendation**

1. **Use a client?**  
Yes. Keep a dedicated Horizons HTTP client as the transport layer, then build `&horizons-ephemeris-data` as a higher-level facade on top of it.  
Use 3 layers:
- `Horizons::Client` (HTTP + URL params + raw response)
- `Horizons::Query` (normalize query forms, validate params, map to API params)
- `Horizons::Parse` (parse CSV sections, map properties, shape output by modifier)

Your current module in [lib/WWW/HorizonsEphemerisSystem.rakumod](/Volumes/Macintosh%20HD/Users/antonov/Raku-WWW-HorizonsEphemerisSystem/lib/WWW/HorizonsEphemerisSystem.rakumod) is the right base for layer 1.

2. **Preserve WL functional style?**  
Partially.
- **Preserve at API boundary**: keep a single function `horizons-ephemeris-data(...)` accepting flexible query forms from the spec.
- **Do not preserve internally**: WL’s deeply functional/pattern style should be translated into Raku idioms (typed helpers, multis, explicit exceptions, small classes/roles).  
This will be easier to test and maintain than a literal WL-style port.

3. **WL-specific features without direct/easy Raku equivalents**
- `Entity[...]`, `EntityValue[...]`, `GeodesyData[]`, `GeoPosition[...]` automatic knowledge base integration.
- `Quantity`, `UnitConvert`, `CompatibleUnitQ` unit algebra.
- `DateObject` + `TimeSystemConvert` (especially TDB/TT correctness).
- `Dataset` object semantics.
- `Around[value, uncertainty]` as first-class numeric type.
- Pattern-heavy symbolic matching (`Alternatives`, rule transforms) over headers/properties.
- Tagged `Catch/Throw` and `ResourceFunctionMessage` behavior.
- `$GeoLocation` (“Here”) automatic observer location.

**Practical strategy for these gaps**
- Represent units as `{ value => Num, unit => Str }` (or plain numbers first, units metadata later).
- Represent dates as ISO/JD strings; avoid full time-system conversion in v1 unless needed.
- Represent `dataset`/`association` as arrays/hashes.
- Represent `around` as `{ value => ..., uncertainty => ... }`.
- Make entity/geoposition support explicit and minimal: strings + `(lat, lon[, h])` per your Raku spec, with optional future plugin for richer astronomy IDs.

If you want, I can draft the concrete module/function skeleton next (`lib/Horizons/EphemerisData.rakumod`) with stubs for `state`, `orbital-elements`, and `observer` pipelines.

-----

## 2nd imlementation

> Ok. Implement the new version of the package "WWW::HorizonsEphemerisSystem" move client class in the file "./lib/WWW/HorizonsEphemerisSystem/Client.rakumod". Implement the sub `horizons-ephemeris-data` in "./lib/WWW/HorizonsEphemerisSystem.rakumod". 
> Make "top level" tests of `horizons-ephemeris-data`  in a separate test file. 
> Those tests should cover the commands in the Raku spec.