---
title: "Immich Traditional Chinese Geodata Deep Dive (1): How Reverse Geocoding Actually Works"
slug: "immich-geodata-tech-01-reverse-geocoding"
aliases: ["/posts/engineering/immich-geodata-tech-01-pipeline/"]
date: 2025-12-11T12:00:00+08:00
lastmod: 2026-08-31T22:18:14+08:00
description: "A breakdown of Immich's offline reverse geocoding: which GeoNames files get imported at container startup, how earthdistance turns coordinates into place names with a nearest neighbor query, and why swapping those files is enough to make your library show accurate Traditional Chinese place names."
tags: ["immich", "geodata", "geonames", "reverse-geocoding"]
categories: ["engineering"]
series: ["immich-geodata-zh-tw"]
series_order: 2
---

Every time you upload a photo to Immich, the system automatically tags where it was taken, say "Xinyi District, Taipei" or "Shibuya, Tokyo". That is not the work of a cloud API. It is a reverse geocoding system that runs entirely offline.

Because it runs offline, there is room for a project like [immich-geodata-zh-tw](https://github.com/RxChi1d/immich-geodata-zh-tw) to exist (for the actual installation steps, see the [illustrated setup guide](/en/posts/container-platform/immich-geodata-zh-tw/) in the first post of this series). Immich reads place names from a handful of plain text files, so replacing those files changes the place names it displays.

This is the first technical post in the series, and it lays the groundwork: what actually happens when Immich resolves a place name, which files it reads, and what room that mechanism leaves for us to work with. Everything in the later posts, the per-country strategies, the translation work, the validation, builds on this.

<!--more-->

## How Immich's Reverse Geocoding Works

To understand what this project can do, you first need to see the shape of Immich's mechanism. The whole system **depends entirely on a local offline database and never calls a cloud API**.

The process splits into two stages that happen at different times:

- **At container startup**: a few plain text geodata files get imported into PostgreSQL and a spatial index is built. This step only reruns when the data content changes.
- **At photo upload**: the photo's GPS coordinates are used to find **the nearest point** in the database, and its field values are read out and assembled into an address string.

There is no boundary matching, no external service lookup, and no validation step. It finds the closest point and copies its fields.

![Immich reverse geocoding flow diagram](https://cdn.rxchi1d.me/inktrace-files/engineering/immich-geodata-tech-01-reverse-geocoding/immich-reverse-geocoding-flow.png "Immich's two stages: data import at container startup, place name lookup via nearest neighbor query at photo upload")
{style="width:80%;"}

### The Query: From Coordinates to a Place Name

When you upload a photo carrying GPS coordinates (25.033, 121.565, for example), Immich uses a **nearest neighbor query** to pick out "Xinyi District, Taipei" from 200,000 records. In short, Immich will:

1. Convert the photo's latitude and longitude into 3D spherical coordinates
2. Find the closest location in the `geodata_places` table
3. Pull that location's Country, Admin1, and City fields
4. Assemble the final address string

Here is Immich's actual query logic, simplified:

```typescript {title="server/src/repositories/map.repository.ts"}
// simplified query logic
this.db
  .selectFrom('geodata_places')
  .selectAll()
  .where(
    sql`earth_box(ll_to_earth_public(${point.latitude}, ${point.longitude}), ${reverseGeocodeMaxDistance})`,
    '@>',
    sql`ll_to_earth_public(latitude, longitude)`,
  )
  .orderBy(
    sql`(earth_distance(ll_to_earth_public(${point.latitude}, ${point.longitude}), ll_to_earth_public(latitude, longitude)))`,
  )
  .limit(1)
```

> [!INFO] Source code
> This logic lives in [map.repository.ts](https://github.com/immich-app/immich/blob/main/server/src/repositories/map.repository.ts) in the official Immich repository. This article is based on the `main` branch as of late 2025; the implementation may shift as Immich evolves, and the link deliberately omits line numbers so it does not go stale.

The key functions:
- `ll_to_earth_public(lat, lng)`: converts latitude and longitude into 3D spherical coordinates (based on an earth ellipsoid model)
- `earth_box(point, radius)`: builds a search window centered on that point with the given radius
- `earth_distance()`: computes the actual spherical distance between two points
- `reverseGeocodeMaxDistance`: the upper bound on the search radius. If no location exists within that distance, the query comes back empty and the photo gets no location info. This is exactly why "increasing data density" matters

The query first narrows the search window with `earth_box`, then sorts precisely with `earth_distance`, and finally returns the single closest record.

### Once You Understand the Query, You Can Game It

Reading through Immich's query logic surfaces one crucial point: **the entire reverse geocoding system depends purely on the contents of `cities500.txt` and its companion files**. Immich never validates whether a place name is correct, and it never goes online to check. It simply finds the nearest point and reads the field values.

That means we can change the contents of these files to:
- **Increase data density**: add finer-grained locations to `cities500.txt` (villages in Taiwan, municipalities in Japan, and so on)
- **Improve place name quality**: replace the `name` field with accurate Traditional Chinese instead of English
- **Refine translation logic**: handle Simplified-to-Traditional conversion, variant character normalization, and similar issues

That is the core strategy of immich-geodata-zh-tw: **rebuild these files from each country's official geodata, then swap out Immich's defaults**.

---

## Which Files Immich Reads

As mentioned above, geodata gets imported at startup. There are four files in total, mostly from [GeoNames](https://www.geonames.org/), an open geographical database (its maintainers claim over 11 million geographical points).

| File | Purpose | How this project handles it |
| :--- | :--- | :--- |
| `cities500.txt` | Primary data of location coordinates and names | Merges in points generated from each country's official geodata and rewrites the names |
| `admin1CodesASCII.txt` | Maps first-level administrative division codes to names | Replaced with localized names to stay in sync |
| `i18n-iso-countries/langs/en.json` | Maps country codes to country names | Entire contents swapped for Traditional Chinese (see below) |
| `geodata-date.txt` | Decides whether to reimport | Content updated with every release |

Here is each one in turn.

### admin1CodesASCII.txt: First-Level Administrative Division Names

Format: `country code.division code TAB name TAB ASCII name TAB geoname_id`

For example:
```
TW.03    Taiwan Province    Taiwan Province    1668284
```

This file is used to turn the `admin1_code` in `cities500.txt` into an actual administrative division name.

### cities500.txt: The Core Geographical Coordinate Database

This is the heart of Immich's reverse geocoding, and it is the GeoNames `cities500` dataset: settlements and administrative centers with a population of 500 or more, roughly 200,000 records (the count shifts as GeoNames updates). The file is tab-separated (TSV), with each line representing one geographical point across 19 fields:

```
geoname_id  name  asciiname  alternatenames  latitude  longitude  feature_class  feature_code  country_code  cc2  admin1_code  admin2_code  admin3_code  admin4_code  population  elevation  dem  timezone  modification_date
```

Immich imports this data into the PostgreSQL `geodata_places` table. At query time the system relies on `latitude` and `longitude` to locate the nearest place, then assembles a full address from the `name`, `country_code`, `admin1_code`, and related fields.

### i18n-iso-countries/langs/en.json: Country Name Mapping

Immich uses this file to convert a country code such as `TW` into a country name. On top of that, Immich **always reads `en.json`**, so the language of country names is unaffected by the interface language.

immich-geodata-zh-tw takes advantage of this by replacing the contents of `en.json` with Traditional Chinese while keeping the locale as "en", so Immich displays 臺灣 rather than "Taiwan". The details are covered later in the section "Country Names: Working Around an Immich Limitation".

### geodata-date.txt: Deciding Whether to Reimport

This is a single-line text file containing nothing but a timestamp. Immich compares the file's **contents** against the `reverse-geocoding-state` record in the database, and only reimports the data when **the two differ**.

Note that the comparison is on content equality, not on the file's modification time and not on which date comes first. So to force Immich to reimport, changing the content to any different value works, including an earlier date.

> [!NOTE] About `admin2Codes.txt`
> `admin2Codes.txt` holds second-level administrative division data. This project does nothing to it and keeps the original file only to preserve the same file structure. That is sufficient in practice, because the place name fields Immich displays come from `cities500.txt` itself and never touch `admin2Codes.txt`.

![GeoNames data file relationship diagram](https://cdn.rxchi1d.me/inktrace-files/engineering/immich-geodata-tech-01-reverse-geocoding/geonames-file-relationships.png "Relationships among the core GeoNames files: cities500.txt references the administrative division lookup tables through admin1_code and admin2_code")
{style="width:80%;"}

## Country Names: Working Around an Immich Limitation

That covers where place names (cities and administrative divisions) come from. What remains is country names (`TW` → 臺灣). Those bypass the geodata processing flow entirely and come down to swapping one static file.

### The Immich Limitation

As noted in the file list above, Immich **always reads `i18n-iso-countries/langs/en.json`** to display country names, even when the user interface language is set to Traditional Chinese. That is a design decision inside Immich, and we cannot change the behavior from the outside.

In theory that means country names will forever display in English: `Taiwan`, `Japan`, `South Korea`.

### The Workaround: Rewrite en.json

But we can fool Immich by **replacing the contents of `en.json` with Traditional Chinese**.

```json {title="i18n-iso-countries/langs/en.json"}
{
  "locale": "en",     // ← locale stays "en", which is what makes Immich read this file
  "countries": {
    "TW": "臺灣",     // ← but the value is already Traditional Chinese
    "CN": "中國",
    "JP": "日本",
    "KR": "南韓",
    "US": "美國",
    "GB": "英國"
    // ... roughly 250 countries and regions, all in Traditional Chinese
  }
}
```

With that in place, Immich reads `en.json` and gets Traditional Chinese country names. The location line users see in their library becomes 臺灣 · 臺北市 · 信義區 instead of "Taiwan · Taipei City · Xinyi District".

### Authoritative Translation Sources

To keep the translated names correct, these Traditional Chinese renderings follow data published by the Taiwanese government:

- Country and region names published by the Ministry of Foreign Affairs of the Republic of China
- Country and region name mappings from the International Trade Administration, Ministry of Economic Affairs

The full source list and license notices are in the project's [NOTICE.md](https://github.com/RxChi1d/immich-geodata-zh-tw/blob/main/NOTICE.md).

They are then fine-tuned to match the usage Taiwanese readers expect. For example:
- 臺灣 rather than 台灣 (following official government orthography)
- 南韓 rather than 韓國 (the wording used by Taiwanese media and in everyday speech)
- 阿拉伯聯合大公國 rather than 阿聯酋 (the official International Trade Administration name)

> [!NOTE]
> We still keep `zh-tw.json` as the Traditional Chinese reference baseline for country names.

---

## Where These Files Come From

At this point the mechanism is fully covered: Immich reads those files, finds place names with a nearest neighbor query, and assembles the fields into an address. Only one question remains: **where the contents of those files come from**.

They are produced by a Rust CLI whose processing splits into two tracks:

- **`extract`**: converts one country's official geodata (Shapefile, GeoJSON, or an official API response) into an intermediate CSV containing administrative division names and computed representative coordinates. It runs once per country that has dedicated processing logic.
- **`release`**: merges the intermediate CSVs back into the original GeoNames files, handles ID allocation and translation, and finally packages everything into `release.tar.gz`. This track consists of six stages: `cleanup`, `prepare`, `enhance`, `locationiq`, `translate`, and `pack`.

[The next post](/en/posts/engineering/immich-geodata-tech-02-pipeline/) takes both tracks apart in full: what each of the six stages does, why every one of them has to be runnable on its own, how IDs are allocated so they never collide, and how to validate a pipeline that depends on a paid API.

---

## References

- [immich-geodata-cn README](https://github.com/ZingLix/immich-geodata-cn/tree/main/geodata#readme) - Detailed documentation of the GeoNames file formats
- [Analysis of Immich Reverse Geocoding](https://zinglix.xyz/2025/01/23/immich-reverse-geocoding/) - A similar project's author analyzing the query mechanism
- [GeoNames Documentation](https://www.geonames.org/export/) - Official file format documentation
- [immich-geodata-zh-tw project documentation](https://github.com/RxChi1d/immich-geodata-zh-tw/tree/main/docs) - Per-region processing details and development notes
