# Synthetic population report — OK

> This population is SYNTHETIC. It is not census data and does not represent the actual population, households, employment, demographics or commuting patterns of Bengaluru.

> Residential weights are footprint-based relative allocation weights, not household or occupancy counts.

> Destination categories and capacities are placeholders derived from OSM tags/footprints; the simulator treats every destination as one WORK location type.

> All weighting, capacity and distance parameters are experimental and configurable (see config.json in this directory).

- agents: **100000**, seed **42**, config sha256 `c7a28882dae9ce4f…`
- locations: **238841** (206478 HOME, 32363 WORK); CEPOP payload CRC `0x24c6bdf8`
- validation: **PASS** (33 checks, 0 failed)

## Residential classification
Tier counts (inside boundary, exact-key de-duplicated): `{"A": 24130, "B": 182348, "C": 606807, "YES_ACTIVITY_TAGGED": 1674}`; other building values: 12542
Buildings matching several residential landuse polygons (assigned to one): 1228
Selected homes: 206478 `{"A": 24130, "B": 182348}`; weight floor hits 2260, cap hits 9907
Audit reference vs this run: `{"tier_A": {"audit": 24130, "this_run": 24130}, "tier_B": {"audit": 182348, "this_run": 182348}, "tier_C": {"audit": 606807, "this_run": 606807}}`

## Exclusions (stage | layer | reason: count)
- destinations | amenities | category_not_selected:other_amenity: **7568** (e.g. node/266472080, node/266472521, node/266737833)
- destinations | amenities | category_not_selected:worship: **2348** (e.g. node/317118536, node/362539259, node/364645835)
- destinations | amenities | no_activity_tag: **1** (e.g. node/10293175809)
- destinations | buildings | category_not_selected:other_amenity: **260** (e.g. way/35912588, way/36965410, way/122737523)
- destinations | buildings | category_not_selected:worship: **715** (e.g. way/52033446, way/52060142, way/82509397)
- destinations | buildings | no_activity_tag: **816548** (e.g. way/24328470, way/24328481, way/24346316)
- destinations | landuse | landuse_is_spatial_context_not_a_destination: **23804** (e.g. )
- destinations | leisure | leisure_value_not_selected: **2070** (e.g. way/26983364, way/27286098, way/27791556)
- residential | buildings | building_yes_with_activity_tag_not_a_home: **1674** (e.g. way/27554059, way/35912588, way/37828662)
- residential | buildings | not_residential_building_value: **12542** (e.g. way/23494413, way/24579528, way/28126732)
- residential | buildings | tier_C_building_yes_outside_residential_landuse: **606807** (e.g. way/24364974, way/31536138, way/31536195)

## Destination de-duplication
```
{
 "input": 33367,
 "after_exact_key_merge": 32633,
 "exact_key_groups_merged": 734,
 "exact_key_records_removed": 734,
 "pairs_considered": 45955,
 "merge_by_name_rule": 275,
 "merge_by_unnamed_rule": 0,
 "largest_proximity_group": 4,
 "proximity_records_removed": 270,
 "close_pairs_kept_distinct": 4448,
 "output": 32363
}
```

## Destination candidates
```
{
 "per_layer": {
  "buildings": {
   "rows": 827501,
   "classified_any": 10953,
   "kept": 9978,
   "by_category": {
    "civic_public": 327,
    "commercial_retail": 4264,
    "education": 1501,
    "healthcare": 267,
    "industrial": 2391,
    "office": 1228
   }
  },
  "amenities": {
   "rows": 24498,
   "classified_any": 24497,
   "kept": 14581,
   "by_category": {
    "civic_public": 856,
    "commercial_retail": 10773,
    "education": 2801,
    "healthcare": 49,
    "industrial": 9,
    "office": 93
   }
  },
  "healthcare": {
   "rows": 3536,
   "classified_any": 3536,
   "kept": 3536,
   "by_category": {
    "education": 1,
    "healthcare": 3535
   }
  },
  "leisure": {
   "rows": 7342,
   "classified_any": 5272,
   "kept": 5272,
   "by_category": {
    "leisure": 5272
   }
  }
 },
 "candidates_before_dedup": 33367,
 "inside_building": {
  "destinations_inside_other_building_preserved": 11125,
  "by_category": {
   "civic_public": 368,
   "commercial_retail": 6999,
   "education": 1047,
   "healthcare": 2452,
   "industrial": 6,
   "leisure": 179,
   "office": 74
  }
 },
 "capacity_weights": {
  "area_floor_hits": 354,
  "area_cap_hits": 2473,
  "point_features_using_default_area": 14262
 },
 "destinations_final": 32363,
 "by_category": {
  "civic_public": 1020,
  "commercial_retail": 14507,
  "education": 4155,
  "healthcare": 3710,
  "industrial": 2398,
  "leisure": 5261,
  "office": 1312
 }
}
```

## Capacity
```
{
 "homes": {
  "homes_fixed_at_cap": 0,
  "max_agents_per_home": 25
 },
 "destinations": {
  "slack": 3.0,
  "min_capacity": 3,
  "share_cap_agents": 500,
  "n_raised_to_min_capacity": 0,
  "n_limited_by_share_cap": 0,
  "total_capacity": 309709,
  "capacity_over_agents": 3.09709
 }
}
```

## Spatial fidelity of homes
```
{
 "cell_m": 2000.0,
 "n_cells": 373,
 "pearson_r_weight_share_vs_agent_share": 0.9995853850835648,
 "total_variation_distance": 0.01210116245804303,
 "top5pct_cells_weight_share": 0.2643369701929168,
 "top5pct_cells_agent_share": 0.26308000000000004
}
```

## Distributions
```
{
 "home_occupancy_histogram": {
  "0": 114956,
  "1": 83044,
  "2": 8478,
  "3": 0,
  "4": 0,
  "5": 0,
  "6-10": 0,
  "11-20": 0,
  "21-50": 0,
  "51+": 0
 },
 "home_occupancy_nonzero": {
  "n": 91522,
  "min": 1.0,
  "mean": 1.0926334651777714,
  "p1": 1.0,
  "p5": 1.0,
  "p25": 1.0,
  "p50": 1.0,
  "p75": 1.0,
  "p95": 2.0,
  "p99": 2.0,
  "max": 2.0
 },
 "destination_occupancy_histogram": {
  "0": 11020,
  "1": 5326,
  "2": 3463,
  "3": 2540,
  "4": 4292,
  "5": 971,
  "6-10": 2524,
  "11-20": 1609,
  "21-50": 618,
  "51+": 0
 },
 "destination_occupancy_nonzero": {
  "n": 21343,
  "min": 1.0,
  "mean": 4.685376938574708,
  "p1": 1.0,
  "p5": 1.0,
  "p25": 2.0,
  "p50": 3.0,
  "p75": 5.0,
  "p95": 16.0,
  "p99": 28.0,
  "max": 28.0
 },
 "unused_homes": 114956,
 "unused_destinations": 11020,
 "agents_by_destination_category": {
  "civic_public": 3419,
  "commercial_retail": 28334,
  "education": 22077,
  "healthcare": 7358,
  "industrial": 4463,
  "leisure": 29647,
  "office": 4702
 },
 "destinations_by_category": {
  "civic_public": 1020,
  "commercial_retail": 14507,
  "education": 4155,
  "healthcare": 3710,
  "industrial": 2398,
  "leisure": 5261,
  "office": 1312
 },
 "assignment_distance_m": {
  "n": 100000,
  "min": 0.0,
  "mean": 467.7352304335853,
  "p1": 47.488563889849445,
  "p5": 91.1720616925755,
  "p25": 203.60887387279507,
  "p50": 337.8532581519637,
  "p75": 562.7453520064771,
  "p95": 1263.1313029954276,
  "p99": 2317.3692561890552,
  "max": 7675.025934391446
 },
 "assignment_distance_m_by_category": {
  "civic_public": {
   "n": 3419,
   "min": 13.98251457721307,
   "mean": 441.94313259885837,
   "p1": 57.309717052237566,
   "p5": 107.27784660143335,
   "p25": 210.39956639191976,
   "p50": 334.37503773841576,
   "p75": 526.2319791753273,
   "p95": 1138.2143239875043,
   "p99": 2000.1097097037134,
   "max": 5739.673491229527
  },
  "commercial_retail": {
   "n": 28334,
   "min": 1.591325228983804,
   "mean": 372.6896303582782,
   "p1": 40.37378733957701,
   "p5": 78.84770534313148,
   "p25": 167.67251257630716,
   "p50": 271.8608122177601,
   "p75": 441.12147009156746,
   "p95": 979.3829608590797,
   "p99": 2009.399214882988,
   "max": 7675.025934391446
  },
  "education": {
   "n": 22077,
   "min": 1.24280695507114,
   "mean": 585.4235937262008,
   "p1": 58.12054559059188,
   "p5": 110.74436323317484,
   "p25": 245.1330643882576,
   "p50": 412.5726776611039,
   "p75": 730.6311237863217,
   "p95": 1598.8444230148448,
   "p99": 2800.154506287417,
   "max": 7073.801847647753
  },
  "healthcare": {
   "n": 7358,
   "min": 1.3355917494137128,
   "mean": 379.0152421305103,
   "p1": 41.610530908691416,
   "p5": 83.56802301672023,
   "p25": 179.9280745200143,
   "p50": 281.7191610138987,
   "p75": 441.7887200692522,
   "p95": 1021.823730357381,
   "p99": 1823.1149042681745,
   "max": 5173.0739186904375
  },
  "industrial": {
   "n": 4463,
   "min": 39.93517808378059,
   "mean": 660.9507756436731,
   "p1": 98.64663059040177,
   "p5": 174.1381732767633,
   "p25": 331.52295310476836,
   "p50": 483.69247863924085,
   "p75": 860.6178230474478,
   "p95": 1631.7170150706993,
   "p99": 2521.3340167970746,
   "max": 3806.2493256414327
  },
  "leisure": {
   "n": 29647,
   "min": 2.982765271016137,
   "mean": 479.52373783951646,
   "p1": 46.46616681471172,
   "p5": 90.02805037316722,
   "p25": 213.963937823333,
   "p50": 358.2777500742956,
   "p75": 588.8584427458118,
   "p95": 1249.6153431152509,
   "p99": 2297.10115620896,
   "max": 7027.934672731219
  },
  "office": {
   "n": 4702,
   "min": 0.0,
   "mean": 387.76628854021607,
   "p1": 54.31320209425245,
   "p5": 102.2681632664953,
   "p25": 212.64610589491883,
   "p50": 326.89456080900925,
   "p75": 477.54386479485083,
   "p95": 896.0507671071668,
   "p99": 1402.22083770123,
   "max": 2394.7950374432553
  }
 },
 "assignment_stage_counts": {
  "0": 95902,
  "1": 3894,
  "2": 204
 },
 "homes_by_tier_agents": {
  "A": 20104,
  "B": 79896
 }
}
```

## Assignment
```
{
 "n_unassigned": 0,
 "distance_m": {
  "n": 100000,
  "min": 0.0,
  "mean": 467.7352304335853,
  "p1": 47.488563889849445,
  "p5": 91.1720616925755,
  "p25": 203.60887387279507,
  "p50": 337.8532581519637,
  "p75": 562.7453520064771,
  "p95": 1263.1313029954276,
  "p99": 2317.3692561890552,
  "max": 7675.025934391446
 },
 "max_destination_occupancy": 28,
 "destinations_used": 21343,
 "destinations_total": 32363,
 "destinations_at_capacity": 5503,
 "top1pct_destinations_agent_share": 0.09017,
 "occupancy_gini": 0.6632269486759571,
 "stages": [
  {
   "stage": 0,
   "radius_m": 15000.0,
   "rounds": 5,
   "placed": 95902,
   "unassigned_after": 4098
  },
  {
   "stage": 1,
   "radius_m": 30000.0,
   "rounds": 5,
   "placed": 3894,
   "unassigned_after": 204
  },
  {
   "stage": 2,
   "radius_m": 60000.0,
   "rounds": 3,
   "placed": 204,
   "unassigned_after": 0
  }
 ]
}
```

## Cap sensitivity
```
[
 {
  "slack": 1.5,
  "capacity": {
   "slack": 1.5,
   "min_capacity": 3,
   "share_cap_agents": 500,
   "n_raised_to_min_capacity": 15660,
   "n_limited_by_share_cap": 0,
   "total_capacity": 174431,
   "capacity_over_agents": 1.74431
  },
  "result": {
   "n_unassigned": 761,
   "distance_m": {
    "n": 99239,
    "min": 0.0,
    "mean": 637.7770894439549,
    "p1": 50.077113876522276,
    "p5": 96.4869852247042,
    "p25": 219.19055883333704,
    "p50": 384.45015148037766,
    "p75": 746.2834397826452,
    "p95": 2028.2554859772486,
    "p99": 3475.1268546486344,
    "max": 8690.830871087657
   },
   "max_destination_occupancy": 14,
   "destinations_used": 23577,
   "destinations_total": 32363,
   "destinations_at_capacity": 15160,
   "top1pct_destinations_agent_share": 0.045707836636806096,
   "occupancy_gini": 0.5527139839652051,
   "stages": [
    {
     "stage": 0,
     "radius_m": 15000.0,
     "rounds": 5,
     "placed": 83321,
     "unassigned_after": 16679
    },
    {
     "stage": 1,
     "radius_m": 30000.0,
     "rounds": 5,
     "placed": 10128,
     "unassigned_after": 6551
    },
    {
     "stage": 2,
     "radius_m": 60000.0,
     "rounds": 5,
     "placed": 3995,
     "unassigned_after": 2556
    },
    {
     "stage": 3,
     "radius_m": null,
     "rounds": 4,
     "placed": 1795,
     "unassigned_after": 761
    }
   ]
  }
 },
 {
  "slack": 2.0,
  "capacity": {
   "slack": 2.0,
   "min_capacity": 3,
   "share_cap_agents": 500,
   "n_raised_to_min_capacity": 505,
   "n_limited_by_share_cap": 0,
   "total_capacity": 215096,
   "capacity_over_agents": 2.15096
  },
  "result": {
   "n_unassigned": 0,
   "distance_m": {
    "n": 100000,
    "min": 0.0,
    "mean": 553.5630818425358,
    "p1": 49.36723148003299,
    "p5": 93.98159140278311,
    "p25": 213.16648627304545,
    "p50": 365.17176410198135,
    "p75": 660.6491611621013,
    "p95": 1608.0390631830528,
    "p99": 2913.454386895791,
    "max": 7938.099132783987
   },
   "max_destination_occupancy": 19,
   "destinations_used": 22459,
   "destinations_total": 32363,
   "destinations_at_capacity": 11233,
   "top1pct_destinations_agent_share": 0.06156,
   "occupancy_gini": 0.6153399697185057,
   "stages": [
    {
     "stage": 0,
     "radius_m": 15000.0,
     "rounds": 5,
     "placed": 88734,
     "unassigned_after": 11266
    },
    {
     "stage": 1,
     "radius_m": 30000.0,
     "rounds": 5,
     "placed": 8539,
     "unassigned_after": 2727
    },
    {
     "stage": 2,
     "radius_m": 60000.0,
     "rounds": 6,
     "placed": 2079,
     "unassigned_after": 648
    },
    {
     "stage": 3,
     "radius_m": null,
     "rounds": 4,
     "placed": 648,
     "unassigned_after": 0
    }
   ]
  }
 },
 {
  "slack": 3.0,
  "capacity": {
   "slack": 3.0,
   "min_capacity": 3,
   "share_cap_agents": 500,
   "n_raised_to_min_capacity": 0,
   "n_limited_by_share_cap": 0,
   "total_capacity": 309709,
   "capacity_over_agents": 3.09709
  },
  "result": {
   "n_unassigned": 0,
   "distance_m": {
    "n": 100000,
    "min": 0.0,
    "mean": 467.7352304335853,
    "p1": 47.488563889849445,
    "p5": 91.1720616925755,
    "p25": 203.60887387279507,
    "p50": 337.8532581519637,
    "p75": 562.7453520064771,
    "p95": 1263.1313029954276,
    "p99": 2317.3692561890552,
    "max": 7675.025934391446
   },
   "max_destination_occupancy": 28,
   "destinations_used": 21343,
   "destinations_total": 32363,
   "destinations_at_capacity": 5503,
   "top1pct_destinations_agent_share": 0.09017,
   "occupancy_gini": 0.6632269486759571,
   "stages": [
    {
     "stage": 0,
     "radius_m": 15000.0,
     "rounds": 5,
     "placed": 95902,
     "unassigned_after": 4098
    },
    {
     "stage": 1,
     "radius_m": 30000.0,
     "rounds": 5,
     "placed": 3894,
     "unassigned_after": 204
    },
    {
     "stage": 2,
     "radius_m": 60000.0,
     "rounds": 3,
     "placed": 204,
     "unassigned_after": 0
    }
   ]
  }
 },
 {
  "slack": 5.0,
  "capacity": {
   "slack": 5.0,
   "min_capacity": 3,
   "share_cap_agents": 500,
   "n_raised_to_min_capacity": 0,
   "n_limited_by_share_cap": 0,
   "total_capacity": 516648,
   "capacity_over_agents": 5.16648
  },
  "result": {
   "n_unassigned": 0,
   "distance_m": {
    "n": 100000,
    "min": 0.0,
    "mean": 440.91880993939554,
    "p1": 46.589748170787054,
    "p5": 89.12792206158188,
    "p25": 197.3483563757187,
    "p50": 323.0010441417544,
    "p75": 520.5142711281637,
    "p95": 1189.1742789985253,
    "p99": 2227.4450812746877,
    "max": 7675.025934391446
   },
   "max_destination_occupancy": 47,
   "destinations_used": 20948,
   "destinations_total": 32363,
   "destinations_at_capacity": 1207,
   "top1pct_destinations_agent_share": 0.11427,
   "occupancy_gini": 0.6852687445539659,
   "stages": [
    {
     "stage": 0,
     "radius_m": 15000.0,
     "rounds": 4,
     "placed": 99678,
     "unassigned_after": 322
    },
    {
     "stage": 1,
     "radius_m": 30000.0,
     "rounds": 2,
     "placed": 322,
     "unassigned_after": 0
    }
   ]
  }
 },
 {
  "slack": 10.0,
  "capacity": {
   "slack": 10.0,
   "min_capacity": 3,
   "share_cap_agents": 500,
   "n_raised_to_min_capacity": 0,
   "n_limited_by_share_cap": 0,
   "total_capacity": 1023217,
   "capacity_over_agents": 10.23217
  },
  "result": {
   "n_unassigned": 0,
   "distance_m": {
    "n": 100000,
    "min": 0.0,
    "mean": 437.6220367175655,
    "p1": 46.40432238539298,
    "p5": 88.84928769576935,
    "p25": 196.4106184161521,
    "p50": 320.9915041358596,
    "p75": 516.994773451961,
    "p95": 1177.4116707874334,
    "p99": 2191.762099653292,
    "max": 7675.025934391446
   },
   "max_destination_occupancy": 84,
   "destinations_used": 20912,
   "destinations_total": 32363,
   "destinations_at_capacity": 47,
   "top1pct_destinations_agent_share": 0.11717,
   "occupancy_gini": 0.6885053999938201,
   "stages": [
    {
     "stage": 0,
     "radius_m": 15000.0,
     "rounds": 3,
     "placed": 100000,
     "unassigned_after": 0
    }
   ]
  }
 },
 {
  "slack": 1000000000.0,
  "capacity": {
   "slack": 1000000000.0,
   "min_capacity": 3,
   "share_cap_agents": 500,
   "n_raised_to_min_capacity": 0,
   "n_limited_by_share_cap": 32363,
   "total_capacity": 16181500,
   "capacity_over_agents": 161.815
  },
  "result": {
   "n_unassigned": 0,
   "distance_m": {
    "n": 100000,
    "min": 0.0,
    "mean": 437.62652804931963,
    "p1": 46.40432238539298,
    "p5": 88.84676772990188,
    "p25": 196.40241725888447,
    "p50": 320.9523861009003,
    "p75": 516.9325376986092,
    "p95": 1177.44328708179,
    "p99": 2191.762099653292,
    "max": 7675.025934391446
   },
   "max_destination_occupancy": 82,
   "destinations_used": 20912,
   "destinations_total": 32363,
   "destinations_at_capacity": 0,
   "top1pct_destinations_agent_share": 0.11698,
   "occupancy_gini": 0.688553089639403,
   "stages": [
    {
     "stage": 0,
     "radius_m": 15000.0,
     "rounds": 1,
     "placed": 100000,
     "unassigned_after": 0
    }
   ]
  }
 }
]
```

## Notes
- buildings: 1 invalid geometries repaired with make_valid (kept)

## Checksums
- `population.cepop`: `acd681061b4d0e06adb38a2a59a563f2ff297502a0b39b7d31e170dca7206377`
- `locations.geoparquet`: `d21785b85f5ea65ad8ab6a9162be1eba31a256cc7ed763bcf095c93630a12008`
- `agents.parquet`: `eb76d184dc431b7ae3b164e78d2635cceef18b01ae981619445e94a23aaadd22`
- `dedup_decisions.parquet`: `b13446086ae230e7fe5bc09ce6bfeb7eae209e8893e4d14e58e80af6632ef2cf`

## Inputs
- `boundary`: {"file": "bengaluru_urban.geojson", "sha256": "080d882fecdf28cf865b9d1fa9d8aead193f890cb5d6d6db5f3d1588b1666442"}
- `buildings`: {"path_name": "buildings.parquet", "n_raw": 827501, "columns": ["addr:city", "addr:country", "addr:full", "addr:housenumber", "addr:housename", "addr:postcode", "addr:place", "addr:street", "email", "name", "opening_hours", "operator", "phone", "ref", "url", "visible", "website", "building", "amenity", "building:flats", "building:levels", "building:material", "building:max_level", "building:min_level", "building:use", "craft", "height", "internet_access", "landuse", "levels", "office", "shop", "source", "start_date", "wikipedia", "id", "timestamp", "version", "tags", "osm_type", "geometry"], "missing_geometry": 0, "empty_geometry": 0, "missing_id": 0, "missing_tag_columns": ["healthcare", "leisure", "highway", "man_made", "tourism", "industrial", "public_transport", "railway", "residential"], "invalid_repaired": 1, "outside_boundary": 0, "exact_key_duplicates_same_layer": 0, "n_kept": 827501, "geometry_types": {"3": 827499, "6": 2}, "sha256": "1457cf7ad8680fe2ab5366ffcc19628fbf4964cb143efcaab2653342388a6c11"}
- `landuse`: {"path_name": "landuse.parquet", "n_raw": 23804, "columns": ["basin", "construction", "depot", "industrial", "landuse", "military", "railway", "residential", "visible", "id", "timestamp", "version", "tags", "osm_type", "geometry"], "missing_geometry": 0, "empty_geometry": 0, "missing_id": 0, "missing_tag_columns": ["building", "building:use", "amenity", "shop", "office", "healthcare", "leisure", "highway", "man_made", "tourism", "craft", "public_transport", "building:levels", "name"], "invalid_repaired": 0, "exact_key_duplicates_same_layer": 0, "n_kept": 23804, "geometry_types": {"1": 2, "3": 23777, "6": 25}, "sha256": "3df74051b1dc7be8dc4d7321ba37ed25c84ef38ec9aa0b5fdc93dc99431462a4"}
- `amenities`: {"path_name": "amenities.parquet", "n_raw": 24498, "columns": ["id", "lon", "lat", "tags", "visible", "version", "timestamp", "changeset", "addr:city", "addr:country", "addr:full", "addr:housenumber", "addr:housename", "addr:postcode", "addr:place", "addr:street", "email", "name", "opening_hours", "operator", "phone", "ref", "url", "website", "amenity", "atm", "bank", "bicycle_parking", "bicycle_rental", "bar", "building", "building:levels", "cafe", "drinking_water", "fast_food", "fountain", "internet_access", "landuse", "office", "parking", "post_office", "school", "social_facility", "source", "start_date", "wikipedia", "bakery", "bicycle", "coffee", "craft", "motorcycle", "organic", "religion", "shop", "guest_house", "tourism", "geometry", "osm_type", "fuel", "kindergarten"], "missing_geometry": 0, "empty_geometry": 0, "missing_id": 0, "missing_tag_columns": ["building:use", "healthcare", "leisure", "highway", "man_made", "industrial", "public_transport", "railway", "residential"], "invalid_repaired": 0, "outside_boundary": 0, "exact_key_duplicates_same_layer": 0, "n_kept": 24498, "geometry_types": {"0": 17781, "1": 11, "3": 6706}, "sha256": "f136a5ffb618ae6bbdb6b0f78a09adeb5eb3d3ec3adcf1bb34359828d356729c"}
- `healthcare`: {"path_name": "healthcare.parquet", "n_raw": 3536, "columns": ["id", "lon", "lat", "tags", "visible", "version", "timestamp", "changeset", "addr:city", "addr:country", "addr:full", "addr:housenumber", "addr:housename", "addr:postcode", "addr:place", "addr:street", "email", "name", "opening_hours", "operator", "phone", "website", "amenity", "building", "internet_access", "social_facility", "source", "start_date", "shop", "tourism", "geometry", "osm_type", "url", "building:levels", "landuse", "office", "wikipedia", "religion"], "missing_geometry": 0, "empty_geometry": 0, "missing_id": 0, "missing_tag_columns": ["building:use", "healthcare", "leisure", "highway", "man_made", "craft", "industrial", "public_transport", "railway", "residential"], "invalid_repaired": 0, "outside_boundary": 0, "exact_key_duplicates_same_layer": 0, "n_kept": 3536, "geometry_types": {"0": 3223, "3": 313}, "sha256": "b5a3ddcb81f2e4c5687c5ceb5e2d1c05fbb3dc934a18f384e705248b26208134"}
- `leisure`: {"path_name": "leisure.parquet", "n_raw": 7342, "columns": ["addr:city", "addr:country", "addr:full", "addr:housenumber", "addr:housename", "addr:postcode", "addr:street", "email", "name", "opening_hours", "operator", "phone", "ref", "url", "visible", "website", "fishing", "fitness_station", "leisure", "playground", "swimming_pool", "id", "timestamp", "version", "tags", "osm_type", "geometry"], "missing_geometry": 0, "empty_geometry": 0, "missing_id": 0, "missing_tag_columns": ["building", "building:use", "landuse", "amenity", "shop", "office", "healthcare", "highway", "man_made", "tourism", "craft", "industrial", "public_transport", "railway", "residential", "building:levels"], "invalid_repaired": 0, "outside_boundary": 0, "exact_key_duplicates_same_layer": 0, "n_kept": 7342, "geometry_types": {"1": 17, "3": 7325}, "sha256": "59884f9a237c84b7d7dedfa96100bcedc435fde8ad7d011b673833e127fa79ab"}
