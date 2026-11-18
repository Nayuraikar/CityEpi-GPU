# Synthetic population report — OK

> This population is SYNTHETIC. It is not census data and does not represent the actual population, households, employment, demographics or commuting patterns of Bengaluru.

> Residential weights are footprint-based relative allocation weights, not household or occupancy counts.

> Destination categories and capacities are placeholders derived from OSM tags/footprints; the simulator treats every destination as one WORK location type.

> All weighting, capacity and distance parameters are experimental and configurable (see config.json in this directory).

- agents: **100000**, seed **42**, config sha256 `e132a055c96a3950…`
- locations: **238841** (206478 HOME, 32363 WORK); CEPOP payload CRC `0xb5d0eac9`
- validation: **PASS** (44 checks, 0 failed)

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

## Households (experimental synthetic layer)
```
{
 "households": 32303,
 "mean_household_size": 3.0956877070241156,
 "pmf_mean": 3.1,
 "households_per_building_cap": 4,
 "buildings_with_households": 32303,
 "buildings_at_household_cap": 0,
 "draw": {
  "drawn_until_index": 32302,
  "tail_households_replaced": 0,
  "final_household_adjusted": true
 },
 "apportionment": {
  "homes_fixed_at_cap": 0
 },
 "size_pmf": {
  "1": 0.15,
  "2": 0.2,
  "3": 0.25,
  "4": 0.25,
  "5": 0.1,
  "6": 0.05
 },
 "assumption": "EXPERIMENTAL placeholder PMF; not measured Bengaluru or census data",
 "household_size_histogram": {
  "1": 4992,
  "2": 6351,
  "3": 8043,
  "4": 8035,
  "5": 3255,
  "6": 1627
 },
 "household_size_observed_share": {
  "1": 0.15453673033464385,
  "2": 0.19660712627310156,
  "3": 0.2489861622759496,
  "4": 0.24873850725938768,
  "5": 0.10076463486363496,
  "6": 0.050366838993282356
 },
 "household_size_configured_pmf": {
  "1": 0.15,
  "2": 0.2,
  "3": 0.25,
  "4": 0.25,
  "5": 0.1,
  "6": 0.05
 },
 "agents_in_households_by_size": {
  "1": 4992,
  "2": 12702,
  "3": 24129,
  "4": 32140,
  "5": 16275,
  "6": 9762
 },
 "households_total": 32303,
 "agents_total": 100000,
 "households_per_building_histogram": {
  "0": 174175,
  "1": 32303,
  "2": 0,
  "3": 0,
  "4": 0,
  "5": 0,
  "6-10": 0,
  "11-20": 0,
  "21-50": 0,
  "51+": 0
 },
 "households_per_occupied_building": {
  "n": 32303,
  "min": 1.0,
  "mean": 1.0,
  "p1": 1.0,
  "p5": 1.0,
  "p25": 1.0,
  "p50": 1.0,
  "p75": 1.0,
  "p95": 1.0,
  "p99": 1.0,
  "max": 1.0
 },
 "home_occupancy_histogram": {
  "0": 174175,
  "1": 4992,
  "2": 6351,
  "3": 8043,
  "4": 8035,
  "5": 3255,
  "6-10": 1627,
  "11-20": 0,
  "21-50": 0,
  "51+": 0
 },
 "home_occupancy_occupied_buildings": {
  "n": 32303,
  "min": 1.0,
  "mean": 3.0956877070241156,
  "p1": 1.0,
  "p5": 1.0,
  "p25": 2.0,
  "p50": 3.0,
  "p75": 4.0,
  "p95": 6.0,
  "p99": 6.0,
  "max": 6.0
 },
 "occupied_buildings": 32303
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
 "pearson_r_weight_share_vs_agent_share": 0.9973074226877431,
 "total_variation_distance": 0.03179265109429265,
 "top5pct_cells_weight_share": 0.2643369701929168,
 "top5pct_cells_agent_share": 0.26405
}
```

## Distributions
```
{
 "home_occupancy_histogram": {
  "0": 174175,
  "1": 4992,
  "2": 6351,
  "3": 8043,
  "4": 8035,
  "5": 3255,
  "6-10": 1627,
  "11-20": 0,
  "21-50": 0,
  "51+": 0
 },
 "home_occupancy_nonzero": {
  "n": 32303,
  "min": 1.0,
  "mean": 3.0956877070241156,
  "p1": 1.0,
  "p5": 1.0,
  "p25": 2.0,
  "p50": 3.0,
  "p75": 4.0,
  "p95": 6.0,
  "p99": 6.0,
  "max": 6.0
 },
 "destination_occupancy_histogram": {
  "0": 11185,
  "1": 5251,
  "2": 3462,
  "3": 2396,
  "4": 4292,
  "5": 957,
  "6-10": 2624,
  "11-20": 1564,
  "21-50": 632,
  "51+": 0
 },
 "destination_occupancy_nonzero": {
  "n": 21178,
  "min": 1.0,
  "mean": 4.721881197469072,
  "p1": 1.0,
  "p5": 1.0,
  "p25": 2.0,
  "p50": 3.0,
  "p75": 5.0,
  "p95": 16.0,
  "p99": 28.0,
  "max": 28.0
 },
 "unused_homes": 174175,
 "unused_destinations": 11185,
 "agents_by_destination_category": {
  "civic_public": 3377,
  "commercial_retail": 28631,
  "education": 21845,
  "healthcare": 7453,
  "industrial": 4190,
  "leisure": 29747,
  "office": 4757
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
  "mean": 466.0736963930363,
  "p1": 47.748429797815426,
  "p5": 90.4572816800047,
  "p25": 204.46579317980672,
  "p50": 339.54901934946787,
  "p75": 562.3010883068885,
  "p95": 1248.9768255590338,
  "p99": 2335.1115855985945,
  "max": 7207.093352693416
 },
 "assignment_distance_m_by_category": {
  "civic_public": {
   "n": 3377,
   "min": 8.57530128532297,
   "mean": 433.8813763896846,
   "p1": 53.21169172202431,
   "p5": 97.91772561931494,
   "p25": 213.09399945489133,
   "p50": 335.1484824230292,
   "p75": 513.6580082972491,
   "p95": 1103.7176093162168,
   "p99": 1986.4792129512546,
   "max": 5739.673491229527
  },
  "commercial_retail": {
   "n": 28631,
   "min": 3.685371952366514,
   "mean": 371.4847148163093,
   "p1": 39.3212896712301,
   "p5": 76.94627923207071,
   "p25": 167.96145774917878,
   "p50": 272.0011409290061,
   "p75": 441.3745859392265,
   "p95": 977.2248048987775,
   "p99": 1956.2923539802596,
   "max": 7207.093352693416
  },
  "education": {
   "n": 21845,
   "min": 0.32061757959107023,
   "mean": 584.808624788802,
   "p1": 59.565543453934616,
   "p5": 115.52885837264989,
   "p25": 251.88208724540632,
   "p50": 416.87191955247704,
   "p75": 724.3356689468887,
   "p95": 1626.2612362726632,
   "p99": 2746.290117630167,
   "max": 7055.131470976128
  },
  "healthcare": {
   "n": 7453,
   "min": 5.017478861289914,
   "mean": 382.7034317398482,
   "p1": 38.394409094394966,
   "p5": 80.84718758103307,
   "p25": 180.01472893688148,
   "p50": 285.73127675278073,
   "p75": 452.7530350725392,
   "p95": 1015.2953193243073,
   "p99": 1826.1902772713715,
   "max": 5041.296819403561
  },
  "industrial": {
   "n": 4190,
   "min": 31.530545846764195,
   "mean": 674.0177910294764,
   "p1": 100.78118455367316,
   "p5": 175.35063122702766,
   "p25": 335.63903484823516,
   "p50": 503.3966630216123,
   "p75": 887.1204270139117,
   "p95": 1665.1407239925534,
   "p99": 2473.9398745555172,
   "max": 3694.007178810619
  },
  "leisure": {
   "n": 29747,
   "min": 6.699112054064725,
   "mean": 478.2443554974574,
   "p1": 47.47246155194588,
   "p5": 90.74314910253634,
   "p25": 214.74387785752225,
   "p50": 360.08011362291626,
   "p75": 588.4088766356472,
   "p95": 1248.1928741508668,
   "p99": 2298.7157426505364,
   "max": 7095.094460476261
  },
  "office": {
   "n": 4757,
   "min": 0.0,
   "mean": 384.33274935149836,
   "p1": 52.77561021437433,
   "p5": 102.02539800986585,
   "p25": 213.57026839744034,
   "p50": 328.371157765609,
   "p75": 473.07477898898617,
   "p95": 887.8393524076484,
   "p99": 1282.9114982325973,
   "max": 2579.8156584362137
  }
 },
 "assignment_stage_counts": {
  "0": 95995,
  "1": 3873,
  "2": 132
 },
 "homes_by_tier_agents": {
  "A": 20011,
  "B": 79989
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
  "mean": 466.0736963930363,
  "p1": 47.748429797815426,
  "p5": 90.4572816800047,
  "p25": 204.46579317980672,
  "p50": 339.54901934946787,
  "p75": 562.3010883068885,
  "p95": 1248.9768255590338,
  "p99": 2335.1115855985945,
  "max": 7207.093352693416
 },
 "max_destination_occupancy": 28,
 "destinations_used": 21178,
 "destinations_total": 32363,
 "destinations_at_capacity": 5560,
 "top1pct_destinations_agent_share": 0.09011,
 "occupancy_gini": 0.6660607106881316,
 "stages": [
  {
   "stage": 0,
   "radius_m": 15000.0,
   "rounds": 5,
   "placed": 95995,
   "unassigned_after": 4005
  },
  {
   "stage": 1,
   "radius_m": 30000.0,
   "rounds": 4,
   "placed": 3873,
   "unassigned_after": 132
  },
  {
   "stage": 2,
   "radius_m": 60000.0,
   "rounds": 2,
   "placed": 132,
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
   "n_unassigned": 779,
   "distance_m": {
    "n": 99221,
    "min": 0.0,
    "mean": 640.2190142334742,
    "p1": 49.36353760055549,
    "p5": 95.41350157807393,
    "p25": 219.9777158185884,
    "p50": 385.8764550038106,
    "p75": 747.6292969141939,
    "p95": 2046.8509537764469,
    "p99": 3541.349822549063,
    "max": 8738.486147527074
   },
   "max_destination_occupancy": 14,
   "destinations_used": 23441,
   "destinations_total": 32363,
   "destinations_at_capacity": 15236,
   "top1pct_destinations_agent_share": 0.04571612864212213,
   "occupancy_gini": 0.5545289521218638,
   "stages": [
    {
     "stage": 0,
     "radius_m": 15000.0,
     "rounds": 5,
     "placed": 83341,
     "unassigned_after": 16659
    },
    {
     "stage": 1,
     "radius_m": 30000.0,
     "rounds": 5,
     "placed": 10049,
     "unassigned_after": 6610
    },
    {
     "stage": 2,
     "radius_m": 60000.0,
     "rounds": 5,
     "placed": 3765,
     "unassigned_after": 2845
    },
    {
     "stage": 3,
     "radius_m": null,
     "rounds": 4,
     "placed": 2066,
     "unassigned_after": 779
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
   "n_unassigned": 5,
   "distance_m": {
    "n": 99995,
    "min": 0.0,
    "mean": 550.341217135659,
    "p1": 48.95765021473006,
    "p5": 93.57627485911036,
    "p25": 214.2003345540765,
    "p50": 366.1034520138179,
    "p75": 660.8515154706636,
    "p95": 1587.1351789156217,
    "p99": 2878.0450082763355,
    "max": 8009.386363951835
   },
   "max_destination_occupancy": 19,
   "destinations_used": 22278,
   "destinations_total": 32363,
   "destinations_at_capacity": 11348,
   "top1pct_destinations_agent_share": 0.06156307815390769,
   "occupancy_gini": 0.6176596837752155,
   "stages": [
    {
     "stage": 0,
     "radius_m": 15000.0,
     "rounds": 5,
     "placed": 88738,
     "unassigned_after": 11262
    },
    {
     "stage": 1,
     "radius_m": 30000.0,
     "rounds": 5,
     "placed": 8591,
     "unassigned_after": 2671
    },
    {
     "stage": 2,
     "radius_m": 60000.0,
     "rounds": 4,
     "placed": 2066,
     "unassigned_after": 605
    },
    {
     "stage": 3,
     "radius_m": null,
     "rounds": 4,
     "placed": 600,
     "unassigned_after": 5
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
    "mean": 466.0736963930363,
    "p1": 47.748429797815426,
    "p5": 90.4572816800047,
    "p25": 204.46579317980672,
    "p50": 339.54901934946787,
    "p75": 562.3010883068885,
    "p95": 1248.9768255590338,
    "p99": 2335.1115855985945,
    "max": 7207.093352693416
   },
   "max_destination_occupancy": 28,
   "destinations_used": 21178,
   "destinations_total": 32363,
   "destinations_at_capacity": 5560,
   "top1pct_destinations_agent_share": 0.09011,
   "occupancy_gini": 0.6660607106881316,
   "stages": [
    {
     "stage": 0,
     "radius_m": 15000.0,
     "rounds": 5,
     "placed": 95995,
     "unassigned_after": 4005
    },
    {
     "stage": 1,
     "radius_m": 30000.0,
     "rounds": 4,
     "placed": 3873,
     "unassigned_after": 132
    },
    {
     "stage": 2,
     "radius_m": 60000.0,
     "rounds": 2,
     "placed": 132,
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
    "mean": 440.734459932259,
    "p1": 46.18175852852912,
    "p5": 88.15193840469092,
    "p25": 198.0185515298498,
    "p50": 323.9895431349939,
    "p75": 521.4116447843472,
    "p95": 1175.173977606609,
    "p99": 2261.4891132446387,
    "max": 7207.093352693416
   },
   "max_destination_occupancy": 47,
   "destinations_used": 20766,
   "destinations_total": 32363,
   "destinations_at_capacity": 1199,
   "top1pct_destinations_agent_share": 0.11431,
   "occupancy_gini": 0.6875388591910515,
   "stages": [
    {
     "stage": 0,
     "radius_m": 15000.0,
     "rounds": 4,
     "placed": 99725,
     "unassigned_after": 275
    },
    {
     "stage": 1,
     "radius_m": 30000.0,
     "rounds": 2,
     "placed": 275,
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
    "mean": 437.9622950917992,
    "p1": 46.0370416380002,
    "p5": 87.95616921820148,
    "p25": 197.29891233671253,
    "p50": 322.5300155336338,
    "p75": 518.7057507722952,
    "p95": 1165.902767814433,
    "p99": 2238.2226727960515,
    "max": 7207.093352693416
   },
   "max_destination_occupancy": 87,
   "destinations_used": 20738,
   "destinations_total": 32363,
   "destinations_at_capacity": 47,
   "top1pct_destinations_agent_share": 0.11626,
   "occupancy_gini": 0.690659249760529,
   "stages": [
    {
     "stage": 0,
     "radius_m": 15000.0,
     "rounds": 2,
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
    "mean": 437.94333410956176,
    "p1": 46.0370416380002,
    "p5": 87.95616921820148,
    "p25": 197.2794780922132,
    "p50": 322.52206010768015,
    "p75": 518.6979593440038,
    "p95": 1165.6188200390272,
    "p99": 2238.2226727960515,
    "max": 7207.093352693416
   },
   "max_destination_occupancy": 87,
   "destinations_used": 20738,
   "destinations_total": 32363,
   "destinations_at_capacity": 0,
   "top1pct_destinations_agent_share": 0.11618,
   "occupancy_gini": 0.6906775366931373,
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
- `population.cepop`: `0bd14209ddcd867c6754577b2a578e9703fe1f9a0912acefee4f093215392ecf`
- `locations.geoparquet`: `35a0bf6768888ac8847d2f6832faca83faa9a54f60b271cb608d6ad349d23360`
- `agents.parquet`: `82413bfbfc2c406faef7475ebdae82dbb4a753b6205dfe1e67fb022f7fff78b5`
- `dedup_decisions.parquet`: `b13446086ae230e7fe5bc09ce6bfeb7eae209e8893e4d14e58e80af6632ef2cf`
- `households.parquet`: `f783d7126645dc6beadfc6269cea41dadc1e0f9ded9ff198faf639a44ef912ae`

## Inputs
- `boundary`: {"file": "bengaluru_urban.geojson", "sha256": "080d882fecdf28cf865b9d1fa9d8aead193f890cb5d6d6db5f3d1588b1666442"}
- `buildings`: {"path_name": "buildings.parquet", "n_raw": 827501, "columns": ["addr:city", "addr:country", "addr:full", "addr:housenumber", "addr:housename", "addr:postcode", "addr:place", "addr:street", "email", "name", "opening_hours", "operator", "phone", "ref", "url", "visible", "website", "building", "amenity", "building:flats", "building:levels", "building:material", "building:max_level", "building:min_level", "building:use", "craft", "height", "internet_access", "landuse", "levels", "office", "shop", "source", "start_date", "wikipedia", "id", "timestamp", "version", "tags", "osm_type", "geometry"], "missing_geometry": 0, "empty_geometry": 0, "missing_id": 0, "missing_tag_columns": ["healthcare", "leisure", "highway", "man_made", "tourism", "industrial", "public_transport", "railway", "residential"], "invalid_repaired": 1, "outside_boundary": 0, "exact_key_duplicates_same_layer": 0, "n_kept": 827501, "geometry_types": {"3": 827499, "6": 2}, "sha256": "1457cf7ad8680fe2ab5366ffcc19628fbf4964cb143efcaab2653342388a6c11"}
- `landuse`: {"path_name": "landuse.parquet", "n_raw": 23804, "columns": ["basin", "construction", "depot", "industrial", "landuse", "military", "railway", "residential", "visible", "id", "timestamp", "version", "tags", "osm_type", "geometry"], "missing_geometry": 0, "empty_geometry": 0, "missing_id": 0, "missing_tag_columns": ["building", "building:use", "amenity", "shop", "office", "healthcare", "leisure", "highway", "man_made", "tourism", "craft", "public_transport", "building:levels", "name"], "invalid_repaired": 0, "exact_key_duplicates_same_layer": 0, "n_kept": 23804, "geometry_types": {"1": 2, "3": 23777, "6": 25}, "sha256": "3df74051b1dc7be8dc4d7321ba37ed25c84ef38ec9aa0b5fdc93dc99431462a4"}
- `amenities`: {"path_name": "amenities.parquet", "n_raw": 24498, "columns": ["id", "lon", "lat", "tags", "visible", "version", "timestamp", "changeset", "addr:city", "addr:country", "addr:full", "addr:housenumber", "addr:housename", "addr:postcode", "addr:place", "addr:street", "email", "name", "opening_hours", "operator", "phone", "ref", "url", "website", "amenity", "atm", "bank", "bicycle_parking", "bicycle_rental", "bar", "building", "building:levels", "cafe", "drinking_water", "fast_food", "fountain", "internet_access", "landuse", "office", "parking", "post_office", "school", "social_facility", "source", "start_date", "wikipedia", "bakery", "bicycle", "coffee", "craft", "motorcycle", "organic", "religion", "shop", "guest_house", "tourism", "geometry", "osm_type", "fuel", "kindergarten"], "missing_geometry": 0, "empty_geometry": 0, "missing_id": 0, "missing_tag_columns": ["building:use", "healthcare", "leisure", "highway", "man_made", "industrial", "public_transport", "railway", "residential"], "invalid_repaired": 0, "outside_boundary": 0, "exact_key_duplicates_same_layer": 0, "n_kept": 24498, "geometry_types": {"0": 17781, "1": 11, "3": 6706}, "sha256": "f136a5ffb618ae6bbdb6b0f78a09adeb5eb3d3ec3adcf1bb34359828d356729c"}
- `healthcare`: {"path_name": "healthcare.parquet", "n_raw": 3536, "columns": ["id", "lon", "lat", "tags", "visible", "version", "timestamp", "changeset", "addr:city", "addr:country", "addr:full", "addr:housenumber", "addr:housename", "addr:postcode", "addr:place", "addr:street", "email", "name", "opening_hours", "operator", "phone", "website", "amenity", "building", "internet_access", "social_facility", "source", "start_date", "shop", "tourism", "geometry", "osm_type", "url", "building:levels", "landuse", "office", "wikipedia", "religion"], "missing_geometry": 0, "empty_geometry": 0, "missing_id": 0, "missing_tag_columns": ["building:use", "healthcare", "leisure", "highway", "man_made", "craft", "industrial", "public_transport", "railway", "residential"], "invalid_repaired": 0, "outside_boundary": 0, "exact_key_duplicates_same_layer": 0, "n_kept": 3536, "geometry_types": {"0": 3223, "3": 313}, "sha256": "b5a3ddcb81f2e4c5687c5ceb5e2d1c05fbb3dc934a18f384e705248b26208134"}
- `leisure`: {"path_name": "leisure.parquet", "n_raw": 7342, "columns": ["addr:city", "addr:country", "addr:full", "addr:housenumber", "addr:housename", "addr:postcode", "addr:street", "email", "name", "opening_hours", "operator", "phone", "ref", "url", "visible", "website", "fishing", "fitness_station", "leisure", "playground", "swimming_pool", "id", "timestamp", "version", "tags", "osm_type", "geometry"], "missing_geometry": 0, "empty_geometry": 0, "missing_id": 0, "missing_tag_columns": ["building", "building:use", "landuse", "amenity", "shop", "office", "healthcare", "highway", "man_made", "tourism", "craft", "industrial", "public_transport", "railway", "residential", "building:levels"], "invalid_repaired": 0, "outside_boundary": 0, "exact_key_duplicates_same_layer": 0, "n_kept": 7342, "geometry_types": {"1": 17, "3": 7325}, "sha256": "59884f9a237c84b7d7dedfa96100bcedc435fde8ad7d011b673833e127fa79ab"}
