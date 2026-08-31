---
title: "Immich Traditional Chinese Geodata Deep Dive (5): Rebuilding Taiwan's Administrative Divisions from Official Map Data"
slug: "immich-geodata-tech-05-taiwan"
date: 2026-08-28T10:00:00+08:00
lastmod: 2026-08-31T22:18:14+08:00
description: "Rebuilding Immich's Taiwanese administrative divisions from NLSC village boundary data: 7,986 representative points, coordinate system conversion, field mapping, and why this handler does almost no name processing at all."
tags: ["immich", "gis", "taiwan", "open-data"]
categories: ["engineering"]
series: ["immich-geodata-zh-tw"]
series_order: 6
draft: true
---

[The previous post, on translating place names with Wikidata](/en/posts/engineering/immich-geodata-tech-04-translation/), was about how much you have to pay for trustworthy translations when no official map data exists. This post is the opposite case: **Taiwan has complete, free, regularly updated official map data**, so the processing can be simple to the point of being boring, and that is the best thing about it.

This post doubles as a full walkthrough of one handler. The [pipeline post](/en/posts/engineering/immich-geodata-tech-02-pipeline/) covered the fixed `extract` pipeline and the per-country insertion points. Here we look at what Taiwan actually puts into those slots.

<!--more-->

## Three Problems with the Raw Data

Immich's default GeoNames data runs into three problems in Taiwan:

1. **The country name displays incorrectly**: GeoNames follows ISO 3166, so the raw output is "Taiwan, Province of China".
2. **Administrative levels are missing**: most special municipality and county/city names are absent, and the township/district level is almost entirely missing. A photo taken in Banqiao shows only "New Taipei City", sometimes only the country.
3. **Point density is too low**: GeoNames' `cities500` only includes settlement points with populations above 500. Coverage in Taiwan is too sparse to support a nearest neighbor lookup, so photos frequently get tagged with the neighbouring township.

The first problem is handled separately (see the `en.json` section in the [first technical post of the series](/en/posts/engineering/immich-geodata-tech-01-reverse-geocoding/)). The other two share one root cause: **the data itself is not granular enough**. That leaves exactly one fix, which is to swap in data that is granular enough.

## Data Source: NLSC Village Boundaries

The project uses the "Village Boundaries (TWD97 latitude/longitude)" open dataset from the **National Land Surveying and Mapping Center (NLSC)**, under the Ministry of the Interior.

- **Source**: [NLSC Open Data Platform](https://whgis-nlsc.moi.gov.tw/Opendata/Files.aspx)
- **Format**: Shapefile
- **Version currently in use**: `1150624` (the version number is a Republic of China calendar date, meaning 24 June of ROC year 115; all figures below are based on this release and will change after NLSC publishes a new one)
- **Output size**: 7,986 rows, one representative point per village
- **License**: Open Government Data License, version 1.0, which permits free reproduction and derivative use with attribution

Village boundaries were chosen over township boundaries because Immich uses a nearest neighbor query: **the denser the points, the lower the chance of being tagged with the wrong administrative division**. Give a township a single point and photos near its edges are almost guaranteed to be wrong. Go down to the village level and dozens of points spread across the same township, so results converge naturally.

![Point density comparison: with the sparse original GeoNames data, photos get tagged with the neighbouring township; after switching to the 7,986 representative points from the NLSC village boundaries, photos land in the correct township or district](https://cdn.rxchi1d.me/inktrace-files/engineering/immich-geodata-tech-05-taiwan/point-density-comparison.png "Point density decides which administrative division a nearest neighbor query lands in")
{style="width:80%;"}

The village boundary data also carries the full set of parent names (special municipality or county/city, township or district, village), so the administrative hierarchy does not need to be assembled from anywhere else.

## Coordinate Handling: Project First, Then Compute the Centroid

The source data is in geographic coordinates (latitude and longitude), but a geometric centroid cannot be computed directly on latitude and longitude. Doing so treats a sphere as a plane, and the distortion grows with latitude.

There is an easy point of confusion here: **TWD97 refers both to a geographic coordinate system (expressed in degrees) and to a set of projected coordinate systems (expressed in metres)**. The NLSC dataset is the former, and computing centroids requires converting to the latter. Same name, different units.

The processing goes like this:

1. **Read the source CRS**: take the Shapefile's `.prj` declaration as authoritative, never assume a fixed code. If the source declares no CRS, the run aborts with an error instead of guessing one.
2. **Project**: convert to TWD97 / TM2 zone 121 ([EPSG:3826](https://epsg.io/3826)), with metres as the unit.
3. **Compute the centroid**: calculate the geometric centre of each polygon on the projected plane.
4. **Convert back to WGS84**: [EPSG:4326](https://epsg.io/4326), output as latitude and longitude.

Coordinates are rounded to 8 decimal places (roughly 1.1 millimetres), with trailing zeros stripped on write.

A known limitation: the code takes the geometric centroid and applies no extra correction to guarantee the point falls inside the polygon. For long, narrow, or concave villages, coastal or ring-shaped divisions for example, the centroid can end up outside the boundary. In practice the impact on Immich's nearest neighbor query is limited, since a neighbouring village's representative point takes over, but it is an edge condition of this approach.

Multipart features such as outlying islands and exclaves deserve a mention: **Taiwan uses a single area-weighted centroid of the merged geometry, so one village is always one row**. Splitting each part into its own row is currently enabled only for Indonesia. Indonesia is an archipelagic country where one administrative division may be scattered across several islands, and not splitting would throw off the location of some islands badly. Taiwan's outlying islands mostly form villages of their own, so the problem does not arise.

![Representative point comparison: when an administrative division made up of three islands is merged into a single representative point, that point lands on open water between the islands and photos get tagged far from where they were taken; taking a separate representative point per part puts photos on the correct island](https://cdn.rxchi1d.me/inktrace-files/engineering/immich-geodata-tech-05-taiwan/centroid-multipart.png "In archipelagic terrain a merged representative point lands at sea, while splitting per part gives every island its own point")
{style="width:70%;"}

## Mapping NLSC Fields to GeoNames Administrative Levels

| GeoNames level | NLSC field | Taiwanese administrative division | Examples |
| :--- | :--- | :--- | :--- |
| Admin1 | `COUNTYNAME` | Special municipalities, counties, cities | New Taipei City, Changhua County, Hsinchu City |
| Admin2 | `TOWNNAME` | Districts, rural townships, urban townships, county-administered cities | Banqiao District, Lukang Township, East District |
| Admin3 | `VILLNAME` | Villages | Wenhua Village, Yong'an Village |

Only these three fields are read, and the assorted DBF types are all converted to strings on output.

> [!NOTE]
> `admin_3` (village) exists only in the project's intermediate CSV, where it serves traceability and debugging. It is **never written to the `cities500` file that Immich consumes**. The finest level Immich displays is `admin_2`. The value of the village data lies in the dense representative coordinates it provides, not in being displayed.

The intermediate CSV also carries a `country` field hardcoded to "臺灣", again for human inspection only. **The country name Immich actually displays is determined by the country code `TW`**, which maps to a value in `i18n-iso-countries/langs/en.json` and has nothing to do with this field. This came up in the [first post of the series](/en/posts/engineering/immich-geodata-tech-01-reverse-geocoding/).

Where the source `VILLNAME` is empty, mostly map sheets for outlying islands with no village subdivision, the string `None` is written. Note that this is a four character string, not a null value. It is an existing convention carried over in the intermediate CSV, used to distinguish "the source was empty" from "the field does not exist". The current data has 206 such rows, 134 of them in Lienchiang County. Since this column is not part of the output, it does not affect what gets displayed.

## No Translation, No Corrections

The most distinctive thing about the Taiwan handler is that it **does almost no processing at all**:

- No OpenCC conversion.
- No lookups against the National Academy for Educational Research's official translations.
- No name correction or validation of any kind.

Whatever NLSC provides is what gets used. The only things retained are a one-off character fix mapping "裏" to "里" and null normalisation, and under the current NLSC data neither of them actually fires.

That stands in sharp contrast to [the Wikidata process covered in the previous post](/en/posts/engineering/immich-geodata-tech-04-translation/), which needs P131 containment validation, candidate filtering, Simplified Chinese detection, and a row by row review of the untranslated list. None of that is needed here, because **the data source is itself authoritative**. The official name of an administrative division is whatever the Ministry of the Interior says it is, so the question of whether a translation is correct never arises.

How simple the processing can be comes down to the quality of the data source. That is probably the most practical lesson in the whole project.

## ID Allocation

The new rows get merged back into GeoNames' `cities500.txt`, so `geoname_id` values must not collide with existing records.

The approach is to compute the **global maximum ID** in the current data, then allocate upward from that maximum plus one, with `admin1CodesASCII.txt` and `cities500.txt` each receiving a contiguous ID range. The benefit of not hardcoding an ID block is that when GeoNames later expands its data, the newly added rows will not overwrite existing official points.

## Location Accuracy in Taiwan After the Swap

Once the data is replaced, photos taken in Taiwan resolve reliably to the "county/city plus township/district" level instead of stopping at the county or the country. Two things produce that result. `admin_2` comes straight from NLSC's official `TOWNNAME` field with no inference involved, and representative point density goes from GeoNames' settlement points up to 7,986 village centroids, which makes it hard for a nearest neighbor query to fall into the wrong township. For the actual installation and verification steps, see the [illustrated setup guide](/en/posts/container-platform/immich-geodata-zh-tw/).

And the entire processing logic amounts to nothing more than reading a Shapefile, converting coordinate systems, computing centroids, and writing out three fields.

## What It Takes to Add Another Country

Turn the Taiwan case around and you get the checklist for adding a new country:

1. **Register it in the `Country` enum**. This is the single source of truth for which countries have handlers. The CLI list is derived from it, so there is no second copy to keep in sync.
2. **Pick a coordinate strategy**. Taiwan uses a fixed EPSG:3826 because a single projection zone covers the whole island. Japan and Korea use dynamic UTM. Thailand and Indonesia each use their own Albers projection. The choice depends on the country's longitudinal span and its terrain.
3. **Write the field mapping and the name resolution logic**. This step is unusually simple for Taiwan: read three fields, use the names as they are. For other countries this is where all the complexity concentrates, and [five regions, five answers](/en/posts/engineering/immich-geodata-tech-03-strategies/) is about exactly those trade-offs.

Everything else, file reading, projection maths, sorting, and output formatting, is handled by the shared pipeline. So the real workload of "adding a country" depends almost entirely on how clean that country's official map data is, and on whether its place names need translating.

---

## References

- [Taiwan Administrative Division Processing Logic](https://github.com/RxChi1d/immich-geodata-zh-tw/blob/main/docs/zh-tw/taiwan-admin-processing.md) - the project's full technical documentation
- [NLSC Open Data Platform](https://whgis-nlsc.moi.gov.tw/Opendata/Files.aspx) - village boundary map data downloads
- [GeoNames Administrative Division Codes](https://www.geonames.org/export/codes.html) - administrative level definitions
