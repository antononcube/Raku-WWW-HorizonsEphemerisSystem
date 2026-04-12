# HorizonsEphemerisData

Import ephemeris data from the Jet Propulsion Laboratory Horizons System

### Definition

#### Messages

```wl
HorizonsEphemerisData::ephemerides := "`1` is not a valid ephemerides type."
 HorizonsEphemerisData::query := "invalid query parameters."
 HorizonsEphemerisData::queryspe := "invalid query specification."
 HorizonsEphemerisData::target := "`1` is not a valid astronomical target."
 HorizonsEphemerisData::center := "`1` is not a valid astronomical center."
 HorizonsEphemerisData::notarget := "target must be specified."
 HorizonsEphemerisData::invdates := "`1` is not a valid specification for dates."
 HorizonsEphemerisData::dateslim := "500 is the limit of dates."
 HorizonsEphemerisData::correc := "`1` is not a valid correction."
 HorizonsEphemerisData::frame := "`1` is not a valid frame."
 HorizonsEphemerisData::prop := "invalid properties."
 HorizonsEphemerisData::propcase := "Any uncertainty property cannot be queried along with LightTime, Distance or RadialVelocity properties for state ephemeris."
 HorizonsEphemerisData::smallincr := "Time increments must be greater than 1 minute."
 HorizonsEphemerisData::import := "Failed to import data from Horizons."
 HorizonsEphemerisData::error := "Error thrown by Horizons: \"`1`\""
 HorizonsEphemerisData::noresult := "No result."
 HorizonsEphemerisData::modi := "`1` is not a valid modifier."
 HorizonsEphemerisData::refraction := "`1` should be a boolean."
 HorizonsEphemerisData::elevationcut := "`1` should be a number in the range [-90, 90]."
 HorizonsEphemerisData::airmasscut := "`1` should be a number greater or equal to 1."
 HorizonsEphemerisData::skipday := "`1` should be a boolean."
 HorizonsEphemerisData::elongation := "`1` should be a list {min, max} whith the limits of the solar elongation angle."
 HorizonsEphemerisData::angularrate := "`1` should be a number or Quantity greater or equal to 1 \"Arcseconds\"/\"Hours\"."
 HorizonsEphemerisData::risetransitset := "`1` should be a boolean."
 HorizonsEphemerisData::noephemeris := "Ephemeris data was suppressed due to query constraints."
 HorizonsEphemerisData::multipletargets := "Target specification match several objects in Horizons system. Choose an ID from the table bellow."
```

#### Main

Not documented argument:

```wl
Default[HorizonsEphemerisData, 5] = False
```

```wl
Out[]= False
```

Main:

```wl
HorizonsEphemerisData[
    epheType_String, 
    query_, 
    properties_ /; (StringQ[properties] || (ListQ[properties] && Length[properties] > 0 && AllTrue[properties, StringQ]) || SameQ[properties, All]), 
    modifier_String : "Data", 
    print_. 
   ] := Module[
    {answer, q}, 
    answer = Catch[
     (* Parse query*) 
      Which[
        AssociationQ[query], 
        q = query 
       , 
        ListQ[query] && Length[query] == 2 && AssociationQ[Last[query]],
        q = Append[Last @ query, "Target" -> First[query]] 
       , 
        Head[query] === Entity || StringQ[query] || Head[query] === GeoPosition, 
        q = <|"Target" -> query|> 
       , 
        True, 
        ResourceFunction["ResourceFunctionMessage"][HorizonsEphemerisData::queryspe, modifier]; Throw[$failed, "HorizonsEphemerisData"] 
       ]; 
       
      (* Check correct modifier *) 
       If[FreeQ[modifiers, modifier], 
        ResourceFunction["ResourceFunctionMessage"][HorizonsEphemerisData::modi, modifier]; Throw[$failed, "HorizonsEphemerisData"]]; 
       
       Which[epheType === "State", 
        horizonsStateData[q, properties, modifier, print], 
        epheType === "OrbitalElements", 
        horizonsOrbitalData[q, properties, modifier, print], 
        epheType === "Observer", 
        horizonsObserverData[q, properties, modifier, print], 
        True, 
        ResourceFunction["ResourceFunctionMessage"][HorizonsEphemerisData::ephemerides, epheType]; Throw[$failed, "HorizonsEphemerisData"] 
       ] 
      , "HorizonsEphemerisData"]; 
    answer /; answer =!= $failed 
   ]
```

Information about the function:

```wl
HorizonsEphemerisData["State", "QueryParameters"] := stateParams;
```

```wl
HorizonsEphemerisData["OrbitalElements", "QueryParameters"] := orbitalParams;
```

```wl
HorizonsEphemerisData["Observer", "QueryParameters"] := observerParams;
```

```wl
HorizonsEphemerisData["State", "Properties"] := DeleteCases[Join[Keys@statePropertiesInfo, Keys@compoundStateProperties], "Date"];
```

```wl
HorizonsEphemerisData["OrbitalElements", "Properties"] := Append[DeleteCases[Keys@orbitalPropertiesInfo, "Date"], All];
```

```wl
HorizonsEphemerisData["Observer", "Properties"] := DeleteCases[Keys@observerPropertiesInfo, "ObservationDate"];
```

#### Information

All atomic (not compound) properties:

```wl
allPropertiesInfo = Join[statePropertiesInfo, orbitalPropertiesInfo, observerPropertiesInfo];
```

API url:

```wl
apirURL = "https://ssd.jpl.nasa.gov/api/horizons.api?";
```

Available frames:

```wl
frames = <|"ICRF" -> "'F'&REF_SYSTEM='ICRF'", "FK4" -> "'F'&REF_SYSTEM='B1950'", 
     "EclipticJ2000" -> "'E'&REF_SYSTEM='ICRF'", "EclipticB1950" -> "'E'&REF_SYSTEM='B1950'", 
     "CenterBodyEquator" -> "'B'&REF_SYSTEM='ICRF'"|>;
```

Modifiers:

```wl
modifiers = {"Magnitudes", "Data", "MagnitudesAssociation", "Association", "MagnitudesDataset", "Dataset"};
```

Wolfram entities related with the objects managed by Horizons:

```wl
astroEntityTypes = {"Planet", "MinorPlanet", "PlanetaryMoon", "SolarSystemFeature", 
     "Comet"};
```

Horizons specifies to encode the following parameter:

![1kizyzzousekz](../../../../../../Users/antonov/MathFiles/WolframFunctionsRepository-other-authors/img/1kizyzzousekz.png)

#### State ephemerides

##### Info

Information about atomic properties (properties that do not contain other properties). The values are {columns, unit, type}; columns are the Horizons columns from which the information is extracted, unit are the units of the columns, type is the type of property. The properties RightAscensionUncertainty and AlongUncertainty are different, but Horizons uses the same column name for both A_s. Then, given that Horizons always returns the uncertainties in the same position, I will use the position of the A_s column to determine the exact meaning.

```wl
statePropertiesInfo = <|
    (* Date *) 
     "Date" -> {{"JDTDB"}, "TDB", "DateObject"}, 
    (* Quantity Properties *) 
     "Distance" -> {{"RG"}, "Kilometers", "Quantity"}, 
     "RadialVelocity" -> {{"RR"}, "Kilometers"/"Seconds", "Quantity"}, 
     "LightTime" -> {{"LT"}, "Seconds", "Quantity"}, 
     "X" -> {{"X"}, "Kilometers", "Quantity"}, 
     "Y" -> {{"Y"}, "Kilometers", "Quantity"}, 
     "Z" -> {{"Z"}, "Kilometers", "Quantity"}, 
     "Vx" -> {{"VX"}, "Kilometers"/"Seconds", "Quantity"}, 
     "Vy" -> {{"VY"}, "Kilometers"/"Seconds", "Quantity"}, 
     "Vz" -> {{"VZ"}, "Kilometers"/"Seconds", "Quantity"}, 
     "XUncertainty" -> {{"X_s"}, "Kilometers", "Quantity"}, 
     "YUncertainty" -> {{"Y_s"}, "Kilometers", "Quantity"}, 
     "ZUncertainty" -> {{"Z_s"}, "Kilometers", "Quantity"}, 
     "VxUncertainty" -> {{"VX_s"}, "Kilometers"/"Seconds", "Quantity"},
     "VyUncertainty" -> {{"VY_s"}, "Kilometers"/"Seconds", "Quantity"},
     "VzUncertainty" -> {{"VZ_s"}, "Kilometers"/"Seconds", "Quantity"},
    (*RightAscensionUncertainty->{{A_s},Kilometers,Quantity},
    DeclinationUncertainty->{{D_s},Kilometers,Quantity},
    RightAscensionVelocityUncertainty->{{VA_RA_s},Kilometers/Seconds,Quantity},
    DeclinationVelocityUncertainty->{{VD_DEC_s},Kilometers/Seconds,Quantity},*) 
     "AlongUncertainty" -> {{"A_s"}, "Kilometers", "Quantity"}, 
     "CrossUncertainty" -> {{"C_s"}, "Kilometers", "Quantity"}, 
     "NormalUncertainty" -> {{"N_s"}, "Kilometers", "Quantity"}, 
     "AlongVelocityUncertainty" -> {{"VA_s"}, "Kilometers"/"Seconds", "Quantity"}, 
     "CrossVelocityUncertainty" -> {{"VC_s"}, "Kilometers"/"Seconds", "Quantity"}, 
     "NormalVelocityUncertainty" -> {{"VN_s"}, "Kilometers"/"Seconds", "Quantity"}, 
     "RadialUncertainty" -> {{"R_s"}, "Kilometers", "Quantity"}, 
     "TransverseUncertainty" -> {{"T_s"}, "Kilometers", "Quantity"}, 
     "RadialVelocityUncertainty" -> {{"VR_s" | "RNGRT_3sig"}, "Kilometers"/"Seconds", "Quantity"}, 
     "TransverseVelocityUncertainty" -> {{"VT_s"}, "Kilometers"/"Seconds", "Quantity"}, 
    (* Around Properties *) 
     "XWithUncertainty" -> {{"X", "X_s"}, "Kilometers", "Around"}, 
     "YWithUncertainty" -> {{"Y", "Y_s"}, "Kilometers", "Around"}, 
     "ZWithUncertainty" -> {{"Z", "Z_s"}, "Kilometers", "Around"}, 
     "VxWithUncertainty" -> {{"VX", "VX_s"}, "Kilometers"/"Seconds", "Around"}, 
     "VyWithUncertainty" -> {{"VY", "VY_s"}, "Kilometers"/"Seconds", "Around"}, 
     "VzWithUncertainty" -> {{"VZ", "VZ_s"}, "Kilometers"/"Seconds", "Around"} 
    |>;
```

Translation of atomic properties to Horizons columns code. It is not possible to ask for uncertainties and lt, range or range-rate at the same time in Horizons; then if this type of request is done, I will return and error.:

```wl
stateProperties2Horizons = {
    (* Cartesian State *) 
     {"X", "Y", "Z", "Vx", "Vy", "Vz"} -> "2", 
     {"Distance", "RadialVelocity", "LightTime"} -> "3", 
     {"XUncertainty", "YUncertainty", "ZUncertainty", "XWithUncertainty", "YWithUncertainty", "ZWithUncertainty", 
       "VxUncertainty", "VyUncertainty", "VzUncertainty", "VxWithUncertainty", "VyWithUncertainty", "VzWithUncertainty"} ->"2x", 
    (* Uncertainties *) 
    (*{RightAscensionUncertainty,DeclinationUncertainty,
    RightAscensionVelocityUncertainty,DeclinationVelocityUncertainty}->2xp,*) 
     {"AlongUncertainty", "CrossUncertainty", "NormalUncertainty", 
       "AlongVelocityUncertainty", "CrossVelocityUncertainty", "NormalVelocityUncertainty"} -> "2xa", 
     {"RadialUncertainty", "TransverseUncertainty", 
       "RadialVelocityUncertainty", "TransverseVelocityUncertainty"} ->"2xar" 
    };
```

Order of generality of the Horizons API groups of properties (the lower the values the more general):

```wl
groupsRanking = <|"2xar" -> 1, "2xa" -> 2, "2x" -> 3, "3" -> 4, "2" -> 5|>;
```

List of compound properties:

```wl
compoundStateProperties = {
    (* Cartesian State *) 
     "Position" -> Sequence["X", "Y", "Z"], 
     "Velocity" -> Sequence["Vx", "Vy", "Vz"], 
     "State" -> Sequence["X", "Y", "Z", "Vx", "Vy", "Vz"], "PositionWithUncertainty" -> Sequence["XWithUncertainty", "YWithUncertainty", "ZWithUncertainty"], "VelocityWithUncertainty" -> Sequence["VxWithUncertainty", "VyWithUncertainty", "VzWithUncertainty"], "StateWithUncertainty" -> Sequence["XWithUncertainty", "YWithUncertainty", "ZWithUncertainty", "VxWithUncertainty", "VyWithUncertainty", "VzWithUncertainty"], 
     "CartesianUncertainties" -> Sequence["XUncertainty", "YUncertainty", "ZUncertainty"], 
     "CartesianVelocityUncertainties" -> Sequence["VxUncertainty", "VyUncertainty", "VzUncertainty"], 
    (* Uncertainties in different systems *) 
     "ACNUncertainties" -> Sequence["AlongUncertainty", "CrossUncertainty", "NormalUncertainty"], 
     "ACNVelocityUncertainties" -> Sequence["AlongVelocityUncertainty", "CrossVelocityUncertainty", "NormalVelocityUncertainty"], 
     "RTNUncertainties" -> Sequence["RadialUncertainty", "TransverseUncertainty", "NormalUncertainty"], 
     "RTNVelocityUncertainties" -> Sequence["RadialVelocityUncertainty", "TransverseVelocityUncertainty", "NormalVelocityUncertainty"], 
     "SkyUncertainties" -> Sequence["RightAscensionUncertainty", "DeclinationUncertainty", "RadialUncertainty"], 
     "SkyVelocityUncertainties" -> Sequence["RightAscensionVelocityUncertainty", "DeclinationVelocityUncertainty", "RadialVelocityUncertainty"], 
     All -> Sequence["X", "Y", "Z", "Vx", "Vy", "Vz", "Distance", "RadialVelocity", "LightTime"] 
    };
```

The list of the query parameters for this function:

```wl
stateParams = {"Target", "Center", "Dates", "Frame", "Corrections"};
```

Available corrections:

```wl
corrections = <|None -> "NONE", "LightTime" -> "LT", "LightTime+StellarAberration" -> "LT+S"|>;
```

##### main

```wl
horizonsStateData[query_, properties_, modifier_, print_] := Module[
    {target, center, dates, correction, frame, prop, data, pos, headers, horizonsGroup, 
     url = apirURL}, 
    
   (* --Check input parameters-- *) 
   (* check correct query parameters *) 
    If[! SubsetQ[stateParams, Keys @ query], ResourceFunction["ResourceFunctionMessage"][HorizonsEphemerisData::query]; Throw[$failed, "HorizonsEphemerisData"]]; 
   (* check of properties *) 
    prop = If[! ListQ[properties], {properties}, properties]; 
    prop = DeleteDuplicates[prop /. compoundStateProperties]; 
    If[! SubsetQ[Flatten @ stateProperties2Horizons[[All, 1]], prop], 
     ResourceFunction["ResourceFunctionMessage"][HorizonsEphemerisData::prop]; Throw[$failed, "HorizonsEphemerisData"]]; 
    
   (* --Read query parameters-- *) 
   (* read target, no default *) 
    target = readTarget @ Lookup[query, 
       "Target", 
       ResourceFunction["ResourceFunctionMessage"][HorizonsEphemerisData::notarget]; Throw[$failed, "HorizonsEphemerisData"]]; 
   (* read center, default SSB *) 
    center = readCenter @ Lookup[query, "Center", "0"]; 
   (* read dates, default Now *) 
    dates = readDates[Lookup[query, "Dates", Now], "TDB"]; 
   (* read corrections, default None *) 
    correction = Lookup[query, "Corrections", None]; 
    correction = Lookup[corrections, correction, ResourceFunction["ResourceFunctionMessage"][HorizonsEphemerisData::correc, correction]; Throw[$failed, "HorizonsEphemerisData"]]; 
    correction = "'" <> encode[correction] <> "'"; 
   (* read frame, default ICRF*) 
    frame = Lookup[query, "Frame", "ICRF"]; 
    frame = Lookup[frames, 
      frame, 
      ResourceFunction["ResourceFunctionMessage"][HorizonsEphemerisData::frame, frame]; Throw[$failed, "HorizonsEphemerisData"]]; 
   (* read properties *) 
    horizonsGroup = DeleteDuplicates[prop /. MapAt[Alternatives @@ # &, stateProperties2Horizons, {All, 1}]]; 
    horizonsGroup = "'" <> chooseColumnsGroup[horizonsGroup] <> "'"; 
    
   (* --Import data-- *) 
    url = url <> StringTemplate["COMMAND=`Target`&CENTER=`Center`&VEC_CORR=`Correction`&REF_PLANE=`Frame`&`Dates`&EPHEM_TYPE='VECTORS'&CSV_FORMAT='YES'&format=json&OBJ_DATA='NO'&MAKE_EPHEM='YES'&VEC_TABLE=`Prop`&TIME_DIGITS='FRACSEC'" 
       ][<|"Target" -> target, "Center" -> center, "Dates" -> dates, "Frame" -> frame, "Correction" -> correction, "Prop" -> horizonsGroup|>]; 
    data = Check[Import[url, "JSON"], 
      ResourceFunction["ResourceFunctionMessage"][HorizonsEphemerisData::import]; Throw[$Failed, "HorizonsEphemerisData"]]; 
    If[print, Print[data]]; 
   (* check Horizons data *) 
    pos = First[Flatten @ Position[data, Rule["error", ___]], None]; 
    If[pos =!= None, 
     ResourceFunction["ResourceFunctionMessage"][HorizonsEphemerisData::error, data[[pos, 2]]]; Throw[$Failed, "HorizonsEphemerisData"]]; 
    pos = First[Flatten @ Position[data, Rule["result", __]], ResourceFunction["ResourceFunctionMessage"][HorizonsEphemerisData::noresult]; Throw[$Failed, "HorizonsEphemerisData"]]; 
    data = data[[pos, 2]]; 
    
   (* --Arrange output-- *) 
   (* split sections of the output *) 
    data = StringSplit[data, Repeated["*", {2, Infinity}]]; 
   (* check if multiple objects were found *) 
    If[StringContainsQ[data[[1]], "Multiple major-bodies match string"],
     data = StringSplit[data[[1]], ""]; 
     pos = First @ Flatten @ Position[StringContainsQ[data, Repeated["--"]], True]; 
     data = StringSplit[data[[pos + 1 ;; -3]], Repeated[" ", {2, Infinity}]][[All, 1 ;; 2]]; 
     ResourceFunction["ResourceFunctionMessage"][HorizonsEphemerisData::multipletargets]; 
     Throw[Dataset[AssociationThread[{"ID", "Name"}, #] & /@ data], "HorizonsEphemerisData"] 
    ]; 
   (* get headers and data *) 
    pos = Position[StringContainsQ[data, "$$SOE"], True]; 
    If[Length[pos] == 0, 
     ResourceFunction["ResourceFunctionMessage"][HorizonsEphemerisData::noresult]; Throw[$Failed, "HorizonsEphemerisData"]]; 
    headers = Extract[data, pos - 1]; 
    headers = StringTrim /@ First @ StringSplit[headers, ","]; 
   (* There is an error in the API, and it returns wrong the first 2 headers sometimes, this is why I add the following line of correction *) 
    If[StringContainsQ[headers[[1]], "    "], headers[[1]] = {StringTake[headers[[1]], 5], StringTrim@StringTake[headers[[1]], 6 ;;]}; headers = Flatten@headers]; 
    data = Extract[data, pos]; 
    data = ImportString[StringTrim @ First @ data, "CSV"][[2 ;; -2]]; 
   (* Arrange the output *) 
    prop = Prepend[prop, "Date"]; 
    data = arrangeData[headers, data, prop, modifier]; 
    data 
   ]
```

#### OrbitalElements ephemerides

##### info

Allow parameters for this ephemeris:

```wl
orbitalParams = {"Target", "Center", "Dates", "Frame"};
```

Properties available in the ephemeris OrbitalElements:

```wl
orbitalPropertiesInfo = <|
    (* Date *) 
     "Date" -> {{"JDTDB"}, "TDB", "DateObject"}, 
     "PeriapsisDate" -> {{"Tp"}, "TDB", "DateObject"}, 
    (* Dimensionless *) 
     "Eccentricity" -> {{"EC"}, Missing[], "Numeric"}, 
    (* Quantity *) 
     "PeriapsisDistance" -> {{"QR"}, "Kilometers", "Quantity"}, 
     "Inclination" -> {{"IN"}, "AngularDegrees", "Quantity"}, 
     "AscendingNodeLongitude" -> {{"OM"}, "AngularDegrees", "Quantity"},
     "PerifocusArgument" -> {{"W"}, "AngularDegrees", "Quantity"}, 
     "MeanMotion" -> {{"N"}, "AngularDegrees"/"Seconds", "Quantity"}, 
     "MeanAnomaly" -> {{"MA"}, "AngularDegrees", "Quantity"}, 
     "TrueAnomaly" -> {{"Tru_Anom" | "TA"}, "AngularDegrees", "Quantity"}, 
     "SemiMajorAxis" -> {{"A"}, "Kilometers", "Quantity"}, 
     "ApoapsisDistance" -> {{"AD"}, "Kilometers", "Quantity"}, 
     "OrbitalPeriod" -> {{"PR"}, "Seconds", "Quantity"} 
    |>;
```

##### main

```wl
horizonsOrbitalData[query_, properties_, modifier_, print_] := Module[
    {target, center, dates, frame, prop, data, pos, headers, 
     url = apirURL}, 
    
   (* --Check input parameters-- *) 
   (* check correct query parameters *) 
    If[! SubsetQ[orbitalParams, Keys @ query], ResourceFunction["ResourceFunctionMessage"][HorizonsEphemerisData::query]; Throw[$failed, "HorizonsEphemerisData"]]; 
   (* check of properties *) 
    prop = If[properties === All, Rest @ Keys @ orbitalPropertiesInfo, properties]; 
    prop = If[! ListQ[prop], {prop}, prop]; 
    prop = DeleteDuplicates[prop]; 
    If[! SubsetQ[Keys @ orbitalPropertiesInfo, prop], 
     ResourceFunction["ResourceFunctionMessage"][HorizonsEphemerisData::prop]; Throw[$failed, "HorizonsEphemerisData"]]; 
    
   (* --Read query parameters-- *) 
   (* read target, no default *) 
    target = readTarget @ Lookup[query, 
       "Target", 
       ResourceFunction["ResourceFunctionMessage"][HorizonsEphemerisData::notarget]; Throw[$failed, "HorizonsEphemerisData"]]; 
   (* read center, default SSB *) 
    center = readCenter @ Lookup[query, "Center", "0"]; 
   (* read dates, default Now *) 
    dates = readDates[Lookup[query, "Dates", Now], "TDB"]; 
   (* read frame, default ICRF*) 
    frame = Lookup[query, "Frame", "ICRF"]; 
    frame = Lookup[frames, 
      frame, 
      ResourceFunction["ResourceFunctionMessage"][HorizonsEphemerisData::frame, frame]; Throw[$failed, "HorizonsEphemerisData"]]; 
    
   (* --Import data-- *) 
    url = url <> StringTemplate["COMMAND=`Target`&CENTER=`Center`&REF_PLANE=`Frame`&`Dates`&EPHEM_TYPE='ELEMENTS'&CSV_FORMAT='YES'&format=json&OBJ_DATA='NO'&MAKE_EPHEM='YES'&TIME_DIGITS='FRACSEC'" 
       ][<|"Target" -> target, "Center" -> center, "Dates" -> dates, "Frame" -> frame|>]; 
    data = Check[Import[url, "JSON"], 
      ResourceFunction["ResourceFunctionMessage"][HorizonsEphemerisData::import]; Throw[$Failed, "HorizonsEphemerisData"]]; 
    If[print, Print[data]]; 
   (* check Horizons data *) 
    pos = First[Flatten @ Position[data, Rule["error", ___]], None]; 
    If[pos =!= None, 
     ResourceFunction["ResourceFunctionMessage"][HorizonsEphemerisData::error, data[[pos, 2]]]; Throw[$Failed, "HorizonsEphemerisData"]]; 
    pos = First[Flatten @ Position[data, Rule["result", __]], ResourceFunction["ResourceFunctionMessage"][HorizonsEphemerisData::noresult]; Throw[$Failed, "HorizonsEphemerisData"]]; 
    data = data[[pos, 2]]; 
    
   (* --Arrange output-- *) 
   (* split sections of the output *) 
    data = StringSplit[data, Repeated["*", {2, Infinity}]]; 
   (* check if multiple objects were found *) 
    If[StringContainsQ[data[[1]], "Multiple major-bodies match string"],
     data = StringSplit[data[[1]], ""]; 
     pos = First @ Flatten @ Position[StringContainsQ[data, Repeated["--"]], True]; 
     data = StringSplit[data[[pos + 1 ;; -3]], Repeated[" ", {2, Infinity}]][[All, 1 ;; 2]]; 
     ResourceFunction["ResourceFunctionMessage"][HorizonsEphemerisData::multipletargets]; 
     Throw[Dataset[AssociationThread[{"ID", "Name"}, #] & /@ data], "HorizonsEphemerisData"] 
    ]; 
   (* get headers and data *) 
    pos = Position[StringContainsQ[data, "$$SOE"], True]; 
    If[Length[pos] == 0, ResourceFunction["ResourceFunctionMessage"][HorizonsEphemerisData::noresult]; Throw[$Failed, "HorizonsEphemerisData"]]; 
    headers = Extract[data, pos - 1]; 
    headers = StringTrim /@ First @ StringSplit[headers, ","]; 
    data = Extract[data, pos]; 
    data = ImportString[StringTrim @ First @ data, "CSV"][[2 ;; -2]]; 
   (* Arrange the output *) 
    prop = Prepend[prop, "Date"]; 
    data = arrangeData[headers, data, prop, modifier]; 
    data 
   ]
```

#### Observer ephemerides

##### info

Properties available in the ephemeris OrbitalElements:

```wl
observerPropertiesInfo = <|
    (* Date *) 
     "ObservationDate" -> {{"Date_________JDTT"}, "TT", "DateObject"}, 
    (* GeoPosition *) 
     "NearestPoint" -> {{"ObsSub-LAT", "ObsSub-LON"}, "AngularDegrees","GeoPosition"}, 
     "SubsolarPoint" -> {{"SunSub-LAT", "SunSub-LON"}, "AngularDegrees","GeoPosition"}, 
    (* String *) 
     "Visibility" -> {{"vis."}, "VisibilityCodes", "String"}, 
     "ApparentSunObserverTargetConfiguration" -> {{"/r"}, "ElongationCodes", "String"}, 
     "Constellation" -> {{"Cnst"}, "Constellation", "String"}, 
     "SolarPresence" -> {{""}, "SolarPresence", "String"}, 
     "InterferingBodyPresence" -> {{""}, "LunarPresence", "String"}, 
    (* Dimensionless *) 
     "RelativeAirmass" -> {{"a-mass"}, Missing[], "Numeric"}, 
     "MagnitudeExtinction" -> {{"mag_ex"}, Missing[], "Numeric"}, 
     "ApparentMagnitude" -> {{"APmag"}, Missing[], "Numeric"}, 
     "SignalToNoiseRatio" -> {{"sky_SNR"}, Missing[], "Numeric"}, 
    (* Quantity *) 
     "AstrometricRightAscension" -> {{"R.A._(ICRF)" | "R.A.___(ICRF)"},"AngularDegrees", "Quantity"}, 
     "AstrometricDeclination" -> {{"DEC_(ICRF)" | "DEC____(ICRF)"}, "AngularDegrees", "Quantity"}, 
     "ApparentRightAscension" -> {{"R.A._(r-app)" | "R.A._(a-app)" | "R.A.__(a-app)" | "R.A._(rfct-app)"}, "AngularDegrees", "Quantity"}, 
     "ApparentDeclination" -> {{"DEC_(r-app)" | "DEC_(a-app)" | "DEC___(a-app)" | "DEC_(rfct-app)"}, "AngularDegrees", "Quantity"}, 
     "ApparentRightAscensionVelocity" -> {{"dRA*cosD"}, "Arcseconds"/"Hours", "Quantity"}, 
     "ApparentDeclinationVelocity" -> {{"d(DEC)/dt"}, "Arcseconds"/"Hours", "Quantity"}, 
     "Azimuth" -> {{"Azi_(a-app)" | "Azi_(r-app)" | "Azimuth_(r-app)" |"Azimuth_(a-app)"}, "AngularDegrees", "Quantity"}, 
     "Elevation" -> {{"Elev_(a-app)" | "Elev_(r-app)" | "Elevation_(r-app)" | "Elevation_(a-app)"}, "AngularDegrees", "Quantity"}, 
     "AzimuthVelocity" -> {{"dAZ*cosE"}, "Arcseconds"/"Minutes", "Quantity"}, 
     "ElevationVelocity" -> {{"d(ELV)/dt"}, "Arcseconds"/"Minutes", "Quantity"}, 
     "SatelliteXOffset" -> {{"X_(sat-prim)"}, "Arcseconds", "Quantity"},
     "SatelliteYOffset" -> {{"Y_(sat-prim)"}, "Arcseconds", "Quantity"},
     "SatellitePositionAngle" -> {{"SatPANG"}, "AngularDegrees", "Quantity"}, 
     "LocalSiderealTime" -> {{"L_Ap_Sid_Time"}, "HoursOfRightAscension","Quantity"}, 
     "SurfaceBrightness" -> {{"S-brt"}, ("Arcseconds")^-2, "Quantity"},
     "IlluminatedFraction" -> {{"Illu%"}, "Percent", "Quantity"}, 
     "ObscureAngularWidth" -> {{"Def_illu"}, "Arcseconds", "Quantity"},
     "TargetToPrimaryBodyAngle" -> {{"ang-sep"}, "Arcseconds", "Quantity"}, 
     "AngularDiameter" -> {{"Ang-diam"}, "Arcseconds", "Quantity"}, 
     "NearestPointLongitude" -> {{"ObsSub-LON"}, "AngularDegrees", "Quantity"}, 
     "NearestPointLatitude" -> {{"ObsSub-LAT"}, "AngularDegrees", "Quantity"}, 
     "SubsolarPointLongitude" -> {{"SunSub-LON"}, "AngularDegrees", "Quantity"}, 
     "SubsolarPointLatitude" -> {{"SunSub-LAT"}, "AngularDegrees", "Quantity"}, 
     "NorthPoleToSubSolarPointAngle" -> {{"SN.ang"}, "AngularDegrees", "Quantity"}, 
     "NearestPointToSubSolarPointAngle" -> {{"SN.dist"}, "Arcseconds", "Quantity"}, 
     "NorthPoleToApparentNorthPoleAngle" -> {{"NP.ang"}, "AngularDegrees", "Quantity"}, 
     "NearestPointToApparentNorthPoleAngle" -> {{"NP.dist"}, "Arcseconds", "Quantity"}, 
     "HeliocentricEclipticLongitude" -> {{"hEcl-Lon"}, "AngularDegrees","Quantity"}, 
     "HeliocentricEclipticLatitude" -> {{"hEcl-Lat"}, "AngularDegrees","Quantity"}, 
     "ApparentDistanceToSun" -> {{"r"}, "Kilometers", "Quantity"}, 
     "ApparentSpeedRelativeToSun" -> {{"rdot"}, "Kilometers"/"Seconds","Quantity"}, 
     "ApparentDistanceToObserver" -> {{"delta"}, "Kilometers", "Quantity"}, 
     "ApparentSpeedRelativeToObserver" -> {{"deldot"}, "Kilometers"/"Seconds", "Quantity"}, 
     "TargetToObserverLightTime" -> {{"1-way_down_LT"}, "Minutes", "Quantity"}, 
     "SpeedMagnitudeRelativeToSun" -> {{"VmagSn"}, "Kilometers"/"Seconds", "Quantity"}, 
     "SpeedMagnitudeRelativeToObserver" -> {{"VmagOb"}, "Kilometers"/"Seconds", "Quantity"}, 
     "ApparentSunObserverTargetAngle" -> {{"S-O-T"}, "AngularDegrees", "Quantity"}, 
     "ApparentSunTargetObserverAngle" -> {{"S-T-O"}, "AngularDegrees", "Quantity"}, 
     "ApparentInterferingBodyElongationAngle" -> {{"T-O-M" | "T-O-I"}, "AngularDegrees", "Quantity"}, 
     "InterferingBodyIlluminatedFraction" -> {{"MN_Illu%" | "IB_Illu%"},"Percent", "Quantity"}, 
     "ApparentObserverPrimaryCenterTargetAngle" -> {{"O-P-T"}, "AngularDegrees", "Quantity"}, 
     "HeliocentricNorthPoleToRadiusVectorAngle" -> {{"PsAng"}, "AngularDegrees", "Quantity"}, 
     "HeliocentricNorthPoleToNegativeVelocityAngle" -> {{"PsAMV"}, "AngularDegrees", "Quantity"}, 
     "TargetOrbitalPlaneToObserverAngle" -> {{"PlAng"}, "AngularDegrees", "Quantity"}, 
     "ApparentEclipticLongitude" -> {{"r-ObsEcLon", "ObsEcLon"}, "AngularDegrees", "Quantity"}, 
     "ApparentEclipticLatitude" -> {{"r-ObsEcLat", "ObsEcLat"}, "AngularDegrees", "Quantity"}, 
     "NorthPoleRightAscension" -> {{"N.Pole-RA"}, "AngularDegrees", "Quantity"}, 
     "NorthPoleDeclination" -> {{"N.Pole-DC"}, "AngularDegrees", "Quantity"}, 
     "ApparentGalacticLongitude" -> {{"GlxLon"}, "AngularDegrees", "Quantity"}, 
     "ApparentGalacticLatitude" -> {{"GlxLat"}, "AngularDegrees", "Quantity"}, 
     "ObserverApparentSolarTime" -> {{"L_Ap_SOL_Time"}, "HoursOfRightAscension", "Quantity"}, 
     "ObserverToEarthLightTime" -> {{"399_ins_LT"}, "Minutes", "Quantity"}, 
     "RightAscensionUncertainty" -> {{"RA_3sigma"}, "Arcseconds", "Quantity"}, 
     "DeclinationUncertainty" -> {{"DEC_3sigma"}, "Arcseconds", "Quantity"}, 
     "UncertaintySemiMajorAxis" -> {{"SMAA_3sig"}, "Arcseconds", "Quantity"}, 
     "UncertaintySemiMinorAxis" -> {{"SMIA_3sig"}, "Arcseconds", "Quantity"}, 
     "UncertaintyEllipseOrientationAngle" -> {{"Theta"}, "AngularDegrees", "Quantity"}, 
     "UncertaintyArea" -> {{"Area_3sig"}, ("Arcseconds")^2, "Quantity"},
     "DistanceUncertainty" -> {{"RNG_3sigma"}, "Kilometers", "Quantity"},
     "RadialVelocityUncertainty" -> {{"VR_s" | "RNGRT_3sig"}, "Kilometers"/"Seconds", "Quantity"}, 
     "SDopplerUncertainty" -> {{"DOP_S_3sig"}, "Hertz", "Quantity"}, 
     "XDopplerUncertainty" -> {{"DOP_X_3sig"}, "Hertz", "Quantity"}, 
     "RoundTripDelay" -> {{"RT_delay_3sig"}, "Seconds", "Quantity"}, 
     "ApparentTrueAnomaly" -> {{"Tru_Anom" | "TA"}, "AngularDegrees", "Quantity"}, 
     "LocalHourAngle" -> {{"r-L_Ap_Hour_Ang" | "L_Ap_Hour_Ang"}, "HoursOfRightAscension", "Quantity"}, 
     "PhaseAngle" -> {{"phi"}, "AngularDegrees", "Quantity"}, 
     "PhaseAngleBisectorLongitude" -> {{"PAB-LON"}, "AngularDegrees", "Quantity"}, 
     "PhaseAngleBisectorLatitude" -> {{"PAB-LAT"}, "AngularDegrees", "Quantity"}, 
     "TargetCenteredApparentSunLongitude" -> {{"App_Lon_Sun"}, "AngularDegrees", "Quantity"}, 
     "InertialApparentRightAscension" -> {{"RA_(ICRF-r-app)" | "RA_(ICRF-a-app)"}, "AngularDegrees", "Quantity"}, 
     "InertialApparentDeclination" -> {{"DEC_(ICRF-r-app)" | "DEC_(ICRF-a-app)"}, "AngularDegrees", "Quantity"}, 
     "InertialApparentRightAscensionVelocity" -> {{"I_dRA*cosD"}, "Arcseconds"/"Hours", "Quantity"}, 
     "InertialApparentDeclinationVelocity" -> {{"I_d(DEC)/dt"}, "Arcseconds"/"Hours", "Quantity"}, 
     "ApparentAngularVelocity" -> {{"Sky_motion"}, "Arcseconds"/"Minutes", "Quantity"}, 
     "NorthPoleToMotionDirectionAngle" -> {{"Sky_mot_PA"}, "AngularDegrees", "Quantity"}, 
     "PathAngle" -> {{"RelVel-ANG"}, "AngularDegrees", "Quantity"}, 
     "SkyBrightness" -> {{"Lun_Sky_Brt"}, "Arcseconds", "Quantity"} 
    |>;
```

Translation of the properties supported by `HorizonsEphemerisData` to the Horizons API numeric codes:

```wl
observerProp2Horizons = {
     "SolarPresence" -> 1, 
     "InterferingBodyPresence" -> 1, 
     "NearestPoint" -> 14, 
     "SubsolarPoint" -> 15, 
    (* String *) 
     "Visibility" -> 12, 
     "ApparentSunObserverTargetConfiguration" -> 23, 
     "Constellation" -> 29, 
    (* Dimensionless *) 
     "RelativeAirmass" -> 8, 
     "MagnitudeExtinction" -> 8, 
     "ApparentMagnitude" -> 9, 
     "SignalToNoiseRatio" -> 48, 
    (* Quantity *) 
     "AstrometricRightAscension" -> 1, 
     "AstrometricDeclination" -> 1, 
     "ApparentRightAscension" -> 2, 
     "ApparentDeclination" -> 2, 
     "ApparentRightAscensionVelocity" -> 3, 
     "ApparentDeclinationVelocity" -> 3, 
     "Azimuth" -> 4, 
     "Elevation" -> 4, 
     "AzimuthVelocity" -> 5, 
     "ElevationVelocity" -> 5, 
     "SatelliteXOffset" -> 6, 
     "SatelliteYOffset" -> 6, 
     "SatellitePositionAngle" -> 6, 
     "LocalSiderealTime" -> 7, 
     "SurfaceBrightness" -> 9, 
     "IlluminatedFraction" -> 10, 
     "ObscureAngularWidth" -> 11, 
     "TargetToPrimaryBodyAngle" -> 12, 
     "AngularDiameter" -> 13, 
     "NearestPointLongitude" -> 14, 
     "NearestPointLatitude" -> 14, 
     "SubsolarPointLongitude" -> 15, 
     "SubsolarPointLatitude" -> 15, 
     "NorthPoleToSubSolarPointAngle" -> 16, 
     "NearestPointToSubSolarPointAngle" -> 16, 
     "NorthPoleToApparentNorthPoleAngle" -> 17, 
     "NearestPointToApparentNorthPoleAngle" -> 17, 
     "HeliocentricEclipticLongitude" -> 18, 
     "HeliocentricEclipticLatitude" -> 18, 
     "ApparentDistanceToSun" -> 19, 
     "ApparentSpeedRelativeToSun" -> 19, 
     "ApparentDistanceToObserver" -> 20, 
     "ApparentSpeedRelativeToObserver" -> 20, 
     "TargetToObserverLightTime" -> 21, 
     "SpeedMagnitudeRelativeToSun" -> 22, 
     "SpeedMagnitudeRelativeToObserver" -> 22, 
     "ApparentSunObserverTargetAngle" -> 23, 
     "ApparentSunTargetObserverAngle" -> 24, 
     "ApparentInterferingBodyElongationAngle" -> 25, 
     "InterferingBodyIlluminatedFraction" -> 25, 
     "ApparentObserverPrimaryCenterTargetAngle" -> 26, 
     "HeliocentricNorthPoleToRadiusVectorAngle" -> 27, 
     "HeliocentricNorthPoleToNegativeVelocityAngle" -> 27, 
     "TargetOrbitalPlaneToObserverAngle" -> 28, 
     "ApparentEclipticLongitude" -> 31, 
     "ApparentEclipticLatitude" -> 31, 
     "NorthPoleRightAscension" -> 32, 
     "NorthPoleDeclination" -> 32, 
     "ApparentGalacticLongitude" -> 33, 
     "ApparentGalacticLatitude" -> 33, 
     "ObserverApparentSolarTime" -> 34, 
     "ObserverToEarthLightTime" -> 35, 
     "RightAscensionUncertainty" -> 36, 
     "DeclinationUncertainty" -> 36, 
     "UncertaintySemiMajorAxis" -> 37, 
     "UncertaintySemiMinorAxis" -> 37, 
     "UncertaintyEllipseOrientationAngle" -> 37, 
     "UncertaintyArea" -> 37, 
     "DistanceUncertainty" -> 39, 
     "RadialVelocityUncertainty" -> 39, 
     "SDopplerUncertainty" -> 40, 
     "XDopplerUncertainty" -> 40, 
     "RoundTripDelay" -> 40, 
     "ApparentTrueAnomaly" -> 41, 
     "LocalHourAngle" -> 42, 
     "PhaseAngle" -> 43, 
     "PhaseAngleBisectorLongitude" -> 43, 
     "PhaseAngleBisectorLatitude" -> 43, 
     "TargetCenteredApparentSunLongitude" -> 44, 
     "InertialApparentRightAscension" -> 45, 
     "InertialApparentDeclination" -> 45, 
     "InertialApparentRightAscensionVelocity" -> 46, 
     "InertialApparentDeclinationVelocity" -> 46, 
     "ApparentAngularVelocity" -> 47, 
     "NorthPoleToMotionDirectionAngle" -> 47, 
     "PathAngle" -> 47, 
     "SkyBrightness" -> 48 
    };
```

Allow parameters for this ephemeris:

```wl
observerParams = {"Target", "Center", "Dates", "EarthAtmosphericRefraction", "MinElevation", "MaxRelativeAirmass","SkipDay", "MinMaxSolarElongation", "MaxAngularRate", "RiseTransitSetOnly"};
```

##### main

```wl
horizonsObserverData[query_, properties_, modifier_, print_] := Module[
    {target, center, dates, prop, data, pos, headers, refraction, minElevation, maxAirmass, skipDay, horizonsProp, 
     minmaxElongation, maxAngularRate, riseTransitSet, url = apirURL}, 
    
   (* --Check input parameters-- *) 
   (* check correct query parameters *) 
    If[! SubsetQ[observerParams, Keys @ query], ResourceFunction["ResourceFunctionMessage"][HorizonsEphemerisData::query]; Throw[$failed, "HorizonsEphemerisData"]]; 
   (* check of properties *) 
    prop = If[properties === All, Rest @ Keys @ observerPropertiesInfo, properties]; 
    prop = If[! ListQ[prop], {prop}, prop]; 
    prop = DeleteDuplicates[prop]; 
    If[! SubsetQ[Keys @ observerPropertiesInfo, prop], 
     ResourceFunction["ResourceFunctionMessage"][HorizonsEphemerisData::prop]; Throw[$failed, "HorizonsEphemerisData"]]; 
    
   (* --Read query parameters-- *) 
   (* read target, no default *) 
    target = readTarget @ Lookup[query, 
       "Target", 
       ResourceFunction["ResourceFunctionMessage"][HorizonsEphemerisData::notarget]; Throw[$failed, "HorizonsEphemerisData"]]; 
   (* read center, default SSB *) 
    center = readCenter @ Lookup[query, "Center", $GeoLocation]; 
   (* read dates, default Now *) 
    dates = readDates[Lookup[query, "Dates", Now], "TT"]; 
   (* read EarthAtmosphericRefraction *) 
    refraction = readAtmosphericRefraction @ Lookup[query, "EarthAtmosphericRefraction", False]; 
   (* read MinElevation *) 
    minElevation = elevationCut @ Lookup[query, "MinElevation", -90]; 
   (* read MaxRelativeAirmass *) 
    maxAirmass = airmassCut @ Lookup[query, "MaxRelativeAirmass", 38]; 
   (* read SkipDay *) 
    skipDay = readSkipDay @ Lookup[query, "SkipDay", False]; 
   (* read MinMaxSolarElongation *) 
    minmaxElongation = readMinmaxElongation @ Lookup[query, "MinMaxSolarElongation", {0, 180}]; 
   (* read MaxAngularRate *) 
    maxAngularRate = readMaxAngularRate @ Lookup[query, "MaxAngularRate", Infinity]; 
   (* read RiseTransitSetOnly *) 
    riseTransitSet = readriseTransitSet @ Lookup[query, "RiseTransitSetOnly", False]; 
    
   (* --Read Properties-- *) 
    horizonsProp = "'" <> encode @ StringRiffle[Sort @ DeleteDuplicates[prop /. observerProp2Horizons], " "] <> "'"; 
    
   (* --Import data-- *) 
    url = url <> StringTemplate["COMMAND=`Target`&CENTER=`Center`&`Dates`&EPHEM_TYPE='OBSERVER'&CSV_FORMAT='YES'&format=json&OBJ_DATA='NO'&MAKE_EPHEM='YES'&TIME_DIGITS='FRACSEC'&QUANTITIES=`Properties`&CAL_FORMAT='JD'&ANG_FORMAT='DEG'&APPARENT=`Refraction`&RANGE_UNITS='KM'&ELEV_CUT=`MinElevation`&SKIP_DAYLT=`SkipDay`&SOLAR_ELONG=`Elongation`&AIRMASS=`Airmass`&ANG_RATE_CUTOFF=`AngularRate`&EXTRA_PREC='YES'&R_T_S_ONLY=`RiseTransitSet`" 
       ][<|"Target" -> target, "Center" -> center, "Dates" -> dates, "Refraction" -> refraction, "MinElevation" -> minElevation, "SkipDay" -> skipDay, "Elongation" -> minmaxElongation, "Airmass" -> maxAirmass, "AngularRate" -> maxAngularRate, "RiseTransitSet" -> riseTransitSet, "Properties" -> horizonsProp|>]; 
    data = Check[Import[url], 
      ResourceFunction["ResourceFunctionMessage"][HorizonsEphemerisData::import]; Throw[$Failed, "HorizonsEphemerisData"]]; 
    If[print, Print[data]]; 
   (* check Horizons data *) 
    pos = First[Flatten @ Position[data, Rule["error", ___]], None]; 
    If[pos =!= None, 
     ResourceFunction["ResourceFunctionMessage"][HorizonsEphemerisData::error, data[[pos, 2]]]; Throw[$Failed, "HorizonsEphemerisData"]]; 
    pos = First[Flatten @ Position[data, Rule["result", __]], ResourceFunction["ResourceFunctionMessage"][HorizonsEphemerisData::noresult]; Throw[$Failed, "HorizonsEphemerisData"]]; 
    data = data[[pos, 2]]; 
    
   (* --Arrange output-- *) 
   (* split sections of the output *) 
    data = StringSplit[data, Repeated["*", {2, Infinity}]]; 
   (* check if multiple objects were found *) 
    If[StringContainsQ[data[[1]], "Multiple major-bodies match string"],
     data = StringSplit[data[[1]], ""]; 
     pos = First @ Flatten @ Position[StringContainsQ[data, Repeated["--"]], True]; 
     data = StringSplit[data[[pos + 1 ;; -3]], Repeated[" ", {2, Infinity}]][[All, 1 ;; 2]]; 
     ResourceFunction["ResourceFunctionMessage"][HorizonsEphemerisData::multipletargets]; 
     Throw[Dataset[AssociationThread[{"ID", "Name"}, #] & /@ data], "HorizonsEphemerisData"] 
    ]; 
   (* get headers and data *) 
    pos = Position[StringContainsQ[data, "$$SOE"], True]; 
    If[Length[pos] == 0, ResourceFunction["ResourceFunctionMessage"][HorizonsEphemerisData::noresult]; Throw[$Failed, "HorizonsEphemerisData"]]; 
    headers = Extract[data, pos - 1]; 
    headers = StringTrim /@ First @ StringSplit[headers, ","]; 
    data = Extract[data, pos]; 
   (* check if ephemeris where suppresed due to query constrains *) 
    If[StringContainsQ[data[[1]], "No ephemeris meets criteria"], ResourceFunction["ResourceFunctionMessage"][HorizonsEphemerisData::noephemeris]; Throw[{}, "HorizonsEphemerisData"]]; 
   (* check if output is different due to observation constrains *) 
    If[Lookup[query, "RiseTransitSetOnly", False] || Lookup[query, "MaxAngularRate", Infinity] =!= Infinity || Lookup[query, "MinMaxSolarElongation", {0, 180}] =!= {0, 180} || Lookup[query, "SkipDay", False] || Lookup[query, "MaxRelativeAirmass", 38] < 38 || Lookup[query, "MinElevation", -90] > -90, 
     data = StringReplace[First @ data, Shortest[">" ~~ ___ ~~ "<"] -> ""], 
     data = First @ data]; 
    data = ImportString[StringTrim @ data, "CSV"][[2 ;; -2]]; 
    data = data /. {} -> Nothing; 
   (* sometimes the Horizons columns Lun_Sky_Brt and sky_SNR are not correctly displayed by the API, here I fixe this. *) 
    If[AnyTrue[StringMatchQ[headers, "Lun_Sky_Brt" ~~ Whitespace ~~ "sky_SNR"], TrueQ], 
     pos = First @ Flatten @ Position[StringMatchQ[headers, "Lun_Sky_Brt" ~~ Whitespace ~~ "sky_SNR"],True]; 
     headers[[pos]] = Sequence @@ StringSplit[headers[[pos]]]; 
     data[[All, pos]] = ToExpression[StringSplit[data[[All, pos]]] /. "n.a." -> "\"n.a.\""];
     data = Flatten /@ data 
    ]; 
   (* Arrange the output *) 
    prop = Prepend[prop, "ObservationDate"]; 
   (*Print[Join[{headers},data]];*) 
    data = arrangeData[headers, data, prop, modifier]; 
    data 
   ]
```

#### Support functions

Observer ephemeris support functions:

##### readriseTransitSet

Reads the query parameter RiseTransitSetOnly. This parameter allows printing the ephemeris only when rise, transit or set are happening.

```wl
readriseTransitSet[riseTransitSet_] := (
    If[! BooleanQ[riseTransitSet], ResourceFunction["ResourceFunctionMessage"][HorizonsEphemerisData::risetransitset, riseTransitSet]]; 
    If[riseTransitSet, "'YES'", "'NO'"] 
   )
```

##### readMaxAngularRate

Reads the query parameter MaxAngularRate. This parameter allows skipping ephemeris when angular rate of the target exceeds the value given. The numeric value is interpreted in "Arcseconds"/"Hours" by Horizons. 	

```wl
readMaxAngularRate[maxValue_] := Module[
    {value}, 
    value = Which[
      QuantityQ[maxValue] && CompatibleUnitQ[maxValue, "Arcseconds"/"Hours"], 
      QuantityMagnitude @ UnitConvert[maxValue, "Arcseconds"/"Hours"], 
      NumberQ[maxValue], 
      maxValue, 
      maxValue === Infinity, 
      maxValue, 
      True, 
      ResourceFunction["ResourceFunctionMessage"][HorizonsEphemerisData::angularrate, maxValue] 
     ]; 
    If[value < 1, ResourceFunction["ResourceFunctionMessage"][HorizonsEphemerisData::angularrate, maxValue]]; 
    If[value === Infinity, value = 0]; 
    "'" <> ToString[value] <> "'" 
   ]
```

##### readMinmaxElongation

Reads the query parameter MinMaxSolarElongation. This parameter allows skipping ephemeris when solar elongation angle of the target is out of the limits.

```wl
readMinmaxElongation[interval_] := (
    If[! (ListQ[interval] && AllTrue[interval, NumericQ] && Length[interval] == 2), ResourceFunction["ResourceFunctionMessage"][HorizonsEphemerisData::elongation, interval]; Throw[$failed, "HorizonsEphemerisData"]]; 
    "'" <> StringRiffle[interval, ","] <> "'" 
   )
```

##### readSkipDay

Reads the SkipDay query parameter. This parameter allows skipping ephemerides when daylight at observer.

```wl
readSkipDay[skipDay_] := Which[
    skipDay === True, 
    "'YES'", 
    skipDay === False, 
    "'NO'", 
    True, 
    ResourceFunction["ResourceFunctionMessage"][HorizonsEphemerisData::skipday, skipDay]; Throw[$failed, "HorizonsEphemerisData"] 
   ]
```

##### airmassCut

Reads the MaxRelativeAirmass query parameter. This parameter allows not display ephemerides if the airmass of the target is greater than the value specified.

```wl
airmassCut[maxAirmass_] := (
    If[! NumericQ[maxAirmass], ResourceFunction["ResourceFunctionMessage"][HorizonsEphemerisData::airmasscut, maxAirmass]; Throw[$Failed, "HorizonsEphemerisData"]]; 
    If[! (Abs[maxAirmass] >= 1), ResourceFunction["ResourceFunctionMessage"][HorizonsEphemerisData::airmasscut, maxAirmass]; Throw[$Failed, "HorizonsEphemerisData"]]; 
    "'" <> ToString[maxAirmass] <> "'" 
   )
```

##### elevationCut

Reads the parameter MinElevation. This parameter allows not displaying ephemerides if the elevation of the target is less than the value specified.

```wl
elevationCut[minElevation_] := (
    If[! NumericQ[minElevation], ResourceFunction["ResourceFunctionMessage"][HorizonsEphemerisData::elevationcut, minElevation]; Throw[$Failed, "HorizonsEphemerisData"]]; 
    If[Abs[minElevation] > 90, ResourceFunction["ResourceFunctionMessage"][HorizonsEphemerisData::elevationcut, minElevation]; Throw[$Failed, "HorizonsEphemerisData"]]; 
    "'" <> ToString[minElevation] <> "'" 
   )
```

##### readAtmosphericRefraction

Reads the query parameter EarthAtmosphericRefraction. This parameter apply atmospheric refraction when Earth is the center of observation.

```wl
readAtmosphericRefraction[refraction_] := Which[
    refraction === True, 
    "'REFRACTED'", 
    refraction === False, 
    "'AIRLESS'", 
    True, 
    ResourceFunction["ResourceFunctionMessage"][HorizonsEphemerisData::refraction, refraction]; Throw[$failed, "HorizonsEphemerisData"] 
   ]
```

State support function:

##### Choose columns group

For VECTOR ephemeris Horizons API does not allow specifying what columns the user wants. Instead, the user has to specify a group of properties (described in the API documentation). This is a problem because `HorizonsEphemerisData` will work by specifying individual properties. The properties involving any type of uncertainty cannot be recovered along with *light time* or *range* properties (because that is how Horizons works).

The variable stateProperties2Horizons contains the translation of `HorizonsEphemerisData` properties to Horizons API groups of properties. This translation is not unique since some groups contain other groups. Just one group can be passed to the API. The following functions selects the most general group from a list of groups to include all the properties that the user wants:

```wl
chooseColumnsGroup[l_List] := Module[
    {ans}, 
    If[AnyTrue[(ContainsAll[#][l]) & /@ {{"3", "2x"}, {"3", "2xa"}, {"3", "2xar"}}, TrueQ], 
     ResourceFunction["ResourceFunctionMessage"][HorizonsEphemerisData::propcase]; Throw[$failed, "HorizonsEphemerisData"]]; 
    ans = Association @@ (# -> groupsRanking[#] & /@ l); 
    ans = TakeSmallest[ ans, 1]; 
    First @ Keys @ ans 
   ]
```

##### Encoder

Encode the special parameters:

```wl
encode[s_] := StringReplace[s, encoding]
```

##### Parse Target

```wl
readTarget[object_] := Module[
    {position, ans, input}, 
    Which[
    (* Entity of astronomical body *) 
    (* change to use NAIFIdentifier property *) 
     Quiet[Head[object] === Entity && MemberQ[DeleteCases[astroEntityTypes, "SolarSystemFeature"], EntityTypeName[object]]], 
     ans = EntityValue[object, "NAIFIdentifier"]; 
     If[MissingQ @ ans, ans = EntityValue[object, "Name"], ans = ToString @ ans]; 
     "'" <> ans <> "'" 
    , 
    (* Position not in Earth *) 
     Quiet[Head[object] === GeoPosition && MemberQ[{"Planet", "PlanetaryMoon"}, EntityTypeName[object["Datum"]]]], 
     ans = EntityValue[object["Datum"], "NAIFIdentifier"]; 
     If[MissingQ @ ans, ans = EntityValue[object["Datum"], "Name"], ans = ToString @ ans]; 
     ans = "g: " <> StringRiffle[{object["Longitude"], object["Latitude"], object["Elevation"]}, ", "] <> " @ " <> ans; 
     "'" <> encode[ans] <> "'" 
    , 
    (* Position in Earth *) 
     Quiet[Head[object] === GeoPosition && Quiet @ MemberQ[GeodesyData[], object["Datum"]]], 
     position = GeoPosition[object, "ITRF93"]; 
     ans = "g: " <> StringRiffle[{position["Longitude"], position["Latitude"], position["Elevation"]}, ", "] <> " @ " <> "399"; 
     "'" <> encode[ans] <> "'" 
    , 
    (* Solar System Feature *) 
     Quiet[Head[object] === Entity && EntityTypeName[object] === "SolarSystemFeature"], 
     readTarget[object["Position"]] 
    , 
    (* TLEs *) 
     Quiet[input = StringSplit[StringSplit[object, EndOfLine]]; 
      Last[Dimensions[input[[;; ;; 2]]]] == 9 && Last[Dimensions[input[[2 ;; ;; 2]]]] == 8], 
     "'TLE'&TLE='" <> encode@object <> "'" 
    , 
    (* Keyword *) 
     Quiet[StringQ[object]], 
     "'" <> encode[object] <> "'" 
    , 
    (* Error *) 
     True, 
     ResourceFunction["ResourceFunctionMessage"][HorizonsEphemerisData::target, object]; Throw[$failed, "HorizonsEphemerisData"] 
    ] 
   ]
```

##### Parse Center

```wl
readCenter[object_] := Module[
    {position, ans, input, dumy}, 
    ans = Which[
     (* Entity of astronomical body *) 
     (* change to use NAIFIdentifier property *) 
      Quiet[Head[object] === Entity && MemberQ[{"Planet", "PlanetaryMoon"}, EntityTypeName[object]]], 
      dumy = EntityValue[object, "NAIFIdentifier"]; 
      If[MissingQ @ dumy, dumy = EntityValue[object, "Name"], dumy = ToString @ dumy]; 
      encode["'500@"] <> dumy <> "'" 
     , 
     (* Position not in Earth *) 
      Quiet[Head[object] === GeoPosition && Quiet @ MemberQ[{"Planet", "PlanetaryMoon"}, EntityTypeName[object["Datum"]]]], 
      dumy = EntityValue[object["Datum"], "NAIFIdentifier"]; 
      If[MissingQ @ dumy, dumy = EntityValue[object["Datum"], "Name"], dumy = ToString @ dumy]; 
      encode["'c @ "] <> dumy <> "'&COORD_TYPE='GEODETIC'&SITE_COORD='" <> encode @ StringRiffle[{object["Longitude"], object["Latitude"], object["Elevation"]}, ", "] <> "'" 
     , 
     (* Position in Earth *) 
      Quiet[Head[object] === GeoPosition && Quiet @ MemberQ[GeodesyData[], object["Datum"]]], 
      position = GeoPosition[object, "ITRF93"]; 
      encode["'c @ 399"] <> "'&COORD_TYPE='GEODETIC'&SITE_COORD='" <> encode @ StringRiffle[{position["Longitude"], position["Latitude"],position["Elevation"]}, ", "] <> "'" 
     , 
     (* Solar System Feature *) 
      Quiet[Head[object] === Entity && EntityTypeName[object] === "SolarSystemFeature"], 
      readCenter[object["Position"]] 
     , 
     (* TLE *) 
      Quiet[input = StringSplit[StringSplit[object, EndOfLine]]; 
       Last[Dimensions[input[[;; ;; 2]]]] == 9 && Last[Dimensions[input[[2 ;; ;; 2]]]] == 8], 
      encode["'@TLE'"] <> "&TLE='" <> encode@object <> "'" 
     , 
     (* Keyword *) 
      Quiet[StringQ[object]], 
      "'" <> encode[object] <> "'" 
     , 
     (* Error *) 
      True, 
      ResourceFunction["ResourceFunctionMessage"][HorizonsEphemerisData::center, object]; Throw[$failed, "HorizonsEphemerisData"] 
     ]; 
    ans 
   ]
```

##### Parser Date

Read dates of ephemerides:

```wl
readDates[date_, system_] := Module[
    {d, ans, start, end, increment}, 
    If[DateObjectQ[date], d = {date}, d = date]; 
    If[! ListQ[d], ResourceFunction["ResourceFunctionMessage"][HorizonsEphemerisData::invdates, date]; Throw[$failed, "HorizonsEphemerisData"]]; 
    If[Length[d] > 500, ResourceFunction["ResourceFunctionMessage"][HorizonsEphemerisData::dateslim]; Throw[$failed, "HorizonsEphemerisData"]]; 
    Which[
    (* List of Dates *) 
     AllTrue[d, DateObjectQ], 
     ans = StringReplace[StringRiffle[DateString[#, {"Year", "-", "Month", "-", "Day", " ", "Hour", ":","Minute", ":", "SecondExact"}] & /@ TimeSystemConvert[DateObject[#, "Instant", TimeZone -> 0] & /@ d, "TDB"], 
        {"'", "' '", "'"}], 
       Join[encoding, {"'" -> "%27"}] 
      ]; 
     ans = "TLIST=" <> ans <> "&TLIST_TYPE='CAL'" <> "&TIME_TYPE='" <> system <> "'" 
    , 
    (* {start, end, increment} *) 
     Length[d] == 3 && DateObjectQ @ d[[1]] && DateObjectQ @ d[[2]] && Quiet @ CompatibleUnitQ[d[[3]], "Seconds"], 
     {start, end} = encode /@ (DateString[#, {"Year", "-", "Month", "-", "Day", " ", "Hour", ":", "Minute", ":", "SecondExact"}] & /@ TimeSystemConvert[DateObject[#, "Instant", TimeZone -> 0] & /@ Most[d], "TDB"]); 
     start = start <> encode[" " <> system]; 
     If[d[[3]] < Quantity[1, "Minutes"], 
      ResourceFunction["ResourceFunctionMessage"][HorizonsEphemerisData::smallincr]; Throw[$failed, "HorizonsEphemerisData"]]; 
     increment = UnitConvert[d[[3]], "Minutes"]; 
     increment = encode @ ToString[QuantityMagnitude @ increment] <> "m"; 
     ans = StringTemplate["START_TIME='`Start`'&STOP_TIME='`End`'&STEP_SIZE='`Increment`'"][<|"Start" -> start, "End" -> end, "Increment" -> increment|>] 
    , 
    (* Error *) 
     True, 
     ResourceFunction["ResourceFunctionMessage"][HorizonsEphemerisData::invdates, date]; Throw[$failed, "HorizonsEphemerisData"] 
    ]; 
    ans 
   ]
```

##### ArrangeData

Function that arrange data:

```wl
arrangeData[headers_, data_, prop_, modifier_] := Module[
    {pos, ans, columns}, 
   (* --For each property arrange the data-- *) 
    ans = Transpose @ Map[
       (pos = Flatten @ Position[headers, Alternatives @@ First @ allPropertiesInfo[#]]; 
         columns = Extract[data, {All, pos}]; 
         arrangeProperty[#, columns]) &, 
       prop 
      ]; 
    
   (* --Apply the modifier-- *) 
    Label["Continue"]; 
    Which[
     modifier === "MagnitudesDataset" || modifier === "Dataset", 
     Dataset @ AssociationThread[ans[[All, 1]], AssociationThread[Rest @ prop, #] & /@ ans[[All, 2 ;;]]], 
     modifier === "Magnitudes" || modifier === "Data", 
     ans, 
     modifier === "MagnitudesAssociation" || modifier === "Association",
     AssociationThread[ans[[All, 1]], AssociationThread[Rest @ prop, #] & /@ ans[[All, 2 ;;]]] 
    ] 
   ]
```

##### arrangeProperty

Function that arrange a property:

```wl
arrangeProperty[property_, columns_] := 
   (* arrange the data depending on the tyoe of property *) 
    Which[
     allPropertiesInfo[property][[3]] === "Quantity", 
     Normal[QuantityArray[Flatten @ columns, allPropertiesInfo[property][[2]]],QuantityArray] /. {_["n.a.", _] | _["", _] -> Missing[]}, 
     allPropertiesInfo[property][[3]] === "DateObject", 
     FromJulianDate[#, TimeZone -> 0, TimeSystem -> allPropertiesInfo[property][[2]]] & /@ Flatten[columns], 
     allPropertiesInfo[property][[3]] === "Numeric", 
     Flatten[columns] /. "n.a." | "" -> Missing[], 
     allPropertiesInfo[property][[3]] === "Around", 
     Normal[QuantityArray[Around[#[[1]], #[[2]]] & /@ columns, allPropertiesInfo[property][[2]]], QuantityArray] /. {"n.a." | "" -> Missing[]}, 
     allPropertiesInfo[property][[3]] === "String", 
     arrangeString[property, columns], 
     allPropertiesInfo[property][[3]] === "GeoPosition", 
     Normal[QuantityArray[{#[[1]], #[[2]]} & /@ columns, allPropertiesInfo[property][[2]]], QuantityArray] /. {_["n.a.", _] | _["", _] -> Missing[]} 
    ];
```

##### arrangeString

```wl
arrangeString[prop_, columns_] := Which[
    prop === "Visibility", 
    Flatten[columns] /. {"t" | "/t" -> "Transiting primary body disk", "p" | "/p" -> "Partial umbral eclipse", "u" | "/u" -> "Total umbral eclipse", "-" | "/-" -> "Target is the primary body", "O" | "/O" -> "Occulted by primary body disk", "P" | "/P" -> "Occulted partial umbral eclipse", "U" | "/U" -> "Occulted total umbral eclipse", "*" | "/*" -> "Free and clear", "n.a." | "" -> Missing[]}, 
    prop === "ApparentSunObserverTargetConfiguration", 
    Flatten[columns] /. {"T" | "/T" -> "Target trails Sun", "/L" | "L" -> "Target leads Sun", "*" | "/*" -> "Observer is Sun-centered", "?" | "/?" -> "Target is aligned with Sun center", "n.a." | "" -> Missing[]}, 
    prop === "Constellation", 
    Flatten[columns] /. {"And" -> "Andromeda", "Leo" -> "Leo","Ant" -> "Antila", "LMi" -> "Leo Minor", "Aps" -> "Apus", "Lep" -> "Lepus", "Aqr" -> "Aquarius", "Lib" -> "Libra", "Aql" -> "Aquila", "Lup" -> "Lupus", "Ara" -> "Ara","Lyn" -> "Lynx", "Ari" -> "Aries", "Lyr" -> "Lyra","Aur" -> "Auriga", "Men" -> "Mensa", "Boo" -> "Bootes", "Mic" -> "Microscopium", "Cae" -> "Caelum", "Mon" -> "Monoceros", "Cam" -> "Camelopardis", "Mus" -> "Musca", "Cnc" -> "Cancer", "Nor" -> "Norma", "CVn" -> "Canes Venatici", "Oct" -> "Octans", "CMa" -> "Canis Major", "Oph" -> "Ophiuchus", "CMi" -> "Canis Minor", "Ori" -> "Orion", "Cap" -> "Capricornus", "Pav" -> "Pavo", "Car" -> "Carina", "Peg" -> "Pegasus", "Cas" -> "Cassiopeia", "Per" -> "Perseus", "Cen" -> "Centaurus", "Phe" -> "Phoenix", "Cep" -> "Cepheus", "Pic" -> "Pictor", "Cet" -> "Cetus", "Psc" -> "Pisces", "Cha" -> "Chamaeleon", "PsA" -> "Pisces Austrinus", "Cir" -> "Circinus", "Pup" -> "Puppis", "Col" -> "Columba", "Pyx" -> "Pyxis", "Com" -> "Coma Berenices", "Ret" -> "Reticulum", "CrA" -> "Corona Australis", "Sge" -> "Sagitta", "CrB" -> "Corona Borealis", "Sgr" -> "Sagittarius", "Crv" -> "Corvus", "Sco" -> "Scorpius", "Crt" -> "Crater", "Scl" -> "Sculptor", "Cru" -> "Crux", "Sct" -> "Scutum", "Cyg" -> "Cygnus", "Ser" -> "Serpens", "Del" -> "Delphinus", "Sex" -> "Sextans", "Dor" -> "Dorado", "Tau" -> "Taurus", "Dra" -> "Draco", "Tel" -> "Telescopium", "Equ" -> "Equuleus", "Tri" -> "Triangulum", "Eri" -> "Eridanus", "TrA" -> "Triangulum Australe", "For" -> "Fornax", "Tuc" -> "Tucana", "Gem" -> "Gemini", "UMa" -> "Ursa Major", "Gru" -> "Grus", "UMi" -> "Ursa Minor", "Her" -> "Hercules", "Vel" -> "Vela", "Hor" -> "Horologium", "Vir" -> "Virgo", "Hya" -> "Hydra", "Vol" -> "Volans", "Hyi" -> "Hydrus", "Vul" -> "Vulpecula", "Ind" -> "Indus", "Lac" -> "Lacerta"}, 
    prop === "SolarPresence", 
    columns[[All, 1]] /. {"*" -> "Daylight", "C" -> "Civil twilight/dawn", "N" -> "Nautical twilight/dawn", "A" -> "Astronomical twilight/dawn", "" -> "Night or geocentric ephemeris"}, 
    prop === "InterferingBodyPresence", 
    columns[[All, 2]] /. {"m" | "x" -> "Interfering body on or above apparent horizon", "" -> "Interfering body below apparent horizon or geocentric ephemeris", "r" -> "Target body on or above cut-off elevation", "s" -> "Target body on or below cut-off elevation", "e" -> "Target body maximum elevation angle has occurred", "t" -> "Target body at or passed through observer meridian"}, 
    True, 
    columns 
   ]
```