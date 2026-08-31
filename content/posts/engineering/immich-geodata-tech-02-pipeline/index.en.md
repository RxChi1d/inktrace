---
title: "Immich Traditional Chinese Geodata, Part 2: The Data Pipeline"
slug: "immich-geodata-tech-02-pipeline"
date: 2026-08-25T10:00:00+08:00
lastmod: 2026-08-31T22:18:14+08:00
description: "A walkthrough of the immich-geodata-zh-tw pipeline: extract turns each country's official map data into an intermediate CSV, release merges it back into GeoNames across six stages and packs release.tar.gz, all verifiable with dry-run and fixture mode."
tags: ["immich", "geodata", "geonames", "etl", "rust"]
categories: ["engineering"]
series: ["immich-geodata-zh-tw"]
series_order: 3
draft: true
---

[The previous post in this series, How Reverse Geocoding Works,](/en/posts/engineering/immich-geodata-tech-01-reverse-geocoding/) took apart the way Immich reads geographic data: a handful of plain text files get imported into PostgreSQL at startup, and a nearest-neighbour query resolves a place name when a photo is uploaded. Since swapping the files is enough to swap what gets displayed, the remaining question is about those "better files" themselves.

This post takes apart the immich-geodata-zh-tw pipeline, from each country's official map data all the way to the `release.tar.gz` that users download.

<!--more-->

## Two Tracks

The whole pipeline splits into two tracks, each with its own job:

- **`extract`**: turns one country's official map data into an intermediate CSV. It runs once per country that has dedicated processing logic, and each run is independent.
- **`release`**: merges every intermediate CSV back into the GeoNames data, translates it, and packs a release. Six stages run in order.

`extract` only serves countries with a dedicated handler, and qualifying takes two things at once: usable official administrative-boundary data for that country, plus processing logic written in the project to read it.

Every other country skips `extract` entirely. But "no `extract`" does not mean "nothing happened". The published data actually comes in three levels of accuracy, and the difference is how many processing steps a given country went through.

**The most accurate level covers the five regions that go through `extract`.** Administrative names and representative point coordinates are both rebuilt from official map data, and point density rises along with it (Taiwan goes all the way down to the village level). The price is that the country needs usable official data, and someone has to write a handler for its particular format.

**The middle level covers countries that go through the `locationiq` lookup.** Coordinates stay exactly as GeoNames has them, but every point is sent through one reverse lookup, and the administrative levels that come back overwrite the original fields. Besides picking up Chinese place-name translations, this level also fixes cases where the point sits in the right spot but upstream assigned it to the wrong administrative unit, or where the name itself is simply wrong. GeoNames is a global database, so this kind of drift is not rare. To reach this level you have to name the country with `--country-code` at run time and supply an API key.

**The baseline level covers everything else.** A country that is never named stops here: administrative assignment and point density stay exactly as GeoNames has them, and only the place names get swapped for Chinese translations during the `translate` stage.

Put differently, **more accurate data costs more processing**. Do nothing and you get the baseline. Spend API quota on reverse lookups and you can correct upstream administrative errors. Go one level higher and you have to find that country's official map data and write dedicated processing logic for it.

When `release` runs, it checks whether `meta_data/` holds an intermediate CSV for a given country and picks its path accordingly. The output of `extract` is committed to version control, and official map data rarely changes, so a release only needs to read the CSVs that are already there instead of reprocessing every country's map data each time.

![The immich-geodata-zh-tw pipeline: extract turns official map data from five regions into intermediate CSVs, and the six stages of release merge them back into GeoNames and pack release.tar.gz](https://cdn.rxchi1d.me/inktrace-files/engineering/immich-geodata-tech-02-pipeline/release-pipeline-stages.png "Two tracks: extract produces intermediate CSVs, and release merges them back into GeoNames across six stages before packing")
{style="width:90%;"}

## Track One: `extract`

The input is a country's official map data; the output is an intermediate CSV in a fixed format:

```bash
cargo run --release -- extract --country TW \
  --shapefile <path to NLSC village boundary data>
```

Each row of the output CSV is one administrative unit, carrying the name at every level plus a computed representative coordinate. Taiwan, for example, produces 7,986 rows, one per village. That makes it possible to merge the CSV back into the GeoNames `cities500.txt` during `release`, replacing the original points and administrative fields.

**All the country-specific differences are concentrated in this step.** Taiwan reads three fields straight out of the [NLSC village boundary data](https://whgis-nlsc.moi.gov.tw/Opendata/Files.aspx). Japan has to distinguish ordinary cities, government-designated cities, and towns and villages under a district. South Korea has to pull Hanja spellings from the Korean Wikipedia. Thailand and Indonesia both need Wikidata queries and P131 membership validation. Those pieces of logic are the subject of later posts in this series, so treat them as a black box for now.

Coordinate computation, by contrast, is shared: project into a coordinate system suited to that country, compute the geometric centre there, then convert back to WGS84. The reason is that computing a centre directly in latitude and longitude distorts the result, which [the Taiwan post](/en/posts/engineering/immich-geodata-tech-05-taiwan/) covers in detail.

### What a Handler Actually Owns

The countries differ a lot, but internally `extract` is a fixed pipeline, and each country's handler only supplies logic at a few specific points along it:

- **`load_context`**: loads the lookup tables and caches that country needs. Taiwan needs none; Thailand and Indonesia have to set up the environment for Wikidata queries.
- **`apply_country_centroids`**: projects according to the `centroid_pipeline` the country declares, then computes the centre. Taiwan uses a fixed EPSG:3826, Japan and South Korea use dynamic UTM, and Thailand and Indonesia each use their own Albers projection.
- **`rows_from_features`**: field mapping and name resolution. Taiwan only reads `COUNTYNAME`, `TOWNNAME`, and `VILLNAME`.

Everything else is shared across all countries: reading the file, parsing features, sorting, rounding coordinates, and writing the CSV with its uniform columns. There is also one conditional stage, `split_parts`, which splits a multipart geometry into one row per part, and only Indonesia enables it today.

![The internal extract pipeline: input map data, read and parse features, load_context, split_parts, apply_country_centroids, rows_from_features, then sort, round, and write, ending in an intermediate CSV with uniform columns. load_context, apply_country_centroids, and rows_from_features are country-specific, while split_parts is conditional and currently enabled only for Indonesia](https://cdn.rxchi1d.me/inktrace-files/engineering/immich-geodata-tech-02-pipeline/extract-handler-architecture.png "Grey stages are shared by every country; coral stages are what you implement when adding a new one")
{style="width:90%;"}

Which countries have a handler is recorded in the `Country` enum. `Country::ALL` is the single source of truth, the CLI list is derived from it, and adding a country neither requires nor permits keeping a second copy in sync.

For a look at what a complete handler looks like end to end, [the Taiwan post](/en/posts/engineering/immich-geodata-tech-05-taiwan/) walks through one from start to finish.

## Track Two: The Six Stages of `release`

```bash
cargo run --release -- release \
  --locationiq-api-key "YOUR_API_KEY" \
  --country-code "US"
```

That single command runs six stages in order:

| Stage | What it does |
| :--- | :--- |
| `cleanup` | Wipes and rebuilds the `output/` directory |
| `prepare` | Downloads source files such as `cities500.txt` and `admin1CodesASCII.txt` from GeoNames |
| `enhance` | Merges each country's intermediate CSV into the source files, allocates `geoname_id` values, writes `*_optimized.txt` |
| `locationiq` | Fills in administrative metadata for countries **without** dedicated processing logic |
| `translate` | Applies official translations and Chinese aliases, producing the translated files |
| `pack` | Packs `release.tar.gz` and `release.zip` |

Every stage can run on its own, and every stage can be skipped with `--pass-<stage>`.

### `cleanup`: The Starting Point for Idempotency

This step does one simple thing: it wipes and rebuilds the `output/` directory so that every run starts from a clean state.

### `prepare`: Fetching the Raw Material

Three source files come from [GeoNames](https://www.geonames.org/export/): `cities500.txt` (settlements and administrative seats with a population of 500 or more, roughly 200,000 entries), `admin1CodesASCII.txt` (first-level administrative codes mapped to names), and `admin2Codes.txt` (second-level units, which this project does not process and only keeps so the file structure stays complete).

Files that already exist are skipped by default rather than downloaded again. `cities500.txt` runs to several hundred MB once decompressed, so that cache is very noticeable when you rerun the pipeline.

### `enhance`: The Core Stage

This step folds two jobs together:

1. **Merging country data**: it reads the intermediate CSVs under `meta_data/` and writes data from countries with dedicated processing logic (a handler) into `admin1CodesASCII.txt` and `cities500.txt`, replacing the original GeoNames points.
2. **Allocating IDs**: newly added rows must not collide with existing `geoname_id` values.

In practice, Immich never validates a `geoname_id` and never stores one; it only stores the resolved place name. Internally, though, a city has to pair with its corresponding admin 1 entry during lookup, so IDs still have to stay unique and correctly paired.

To get that right, the program first computes the **global maximum ID** present in the data, then allocates from that maximum plus one onward: `admin1CodesASCII.txt` takes a block first, and `cities500.txt` continues from there. The benefit of not hard-coding a number range is that when GeoNames expands its data later, the new rows still will not overwrite any official existing points.

![How geoname_id allocation works: existing GeoNames data occupies everything up to the global maximum, new admin1CodesASCII rows start at the maximum plus one, and new cities500 rows continue after them, with the blank space on the right showing that later GeoNames expansion will not collide](https://cdn.rxchi1d.me/inktrace-files/engineering/immich-geodata-tech-02-pipeline/geoname-id-allocation.png "New rows are allocated upward from the current global maximum instead of from a hard-coded range")
{style="width:70%;"}

The output is `cities500_optimized.txt` and `admin1CodesASCII_optimized.txt`.

### `locationiq`: Correcting Administrative Units for Named Countries

This stage **only handles countries named explicitly at run time**; it is not applied to the global dataset. A country has to be listed with `--country-code` in the command (several are allowed), and the five countries that already have a dedicated handler are excluded automatically, because their data was finished during `extract` and there is no point spending API quota on it again.

Once named, every location in that country has its coordinates sent to LocationIQ for one reverse lookup, and the administrative levels that come back overwrite the original GeoNames fields. This is the middle level described earlier: coordinates stay put, but cases where upstream filed a point under the wrong administrative unit, or got the name wrong, get corrected. Countries that are not named never touch this step at all.

This is the only place in the whole pipeline that can be blocked by an external service. LocationIQ enforces a daily request limit, and a single country can have tens of thousands of locations to look up, so the pipeline is designed to be interrupted and resumed:

- Query progress is recorded in `meta_data/<country code>.csv`, and coordinates that have already been looked up are skipped automatically.
- When the daily limit is hit, switch API keys or rerun the same command the next day.
- Add `--pass-cleanup` to keep the existing intermediate artifacts in `output/`, saving another download and another round of preprocessing.

The "stages can be skipped individually" design mentioned earlier exists to solve exactly this.

### `translate`: Deciding the Final Display Name

Countries with a dedicated handler were settled back in `extract` and never reach this stage. For everything else, the Chinese name might come from several places, and this stage decides which one wins.

The candidate sources, in order:

1. **The name returned by the LocationIQ lookup.** The previous stage sends `accept-language: zh,en` with each request, so the administrative names that come back may already be in Chinese.
2. **A Chinese name filtered out of the GeoNames alias file.** `alternateNamesV2.txt`, downloaded during `prepare`, holds aliases in many languages; the program filters the Chinese entries and ranks them `zh-Hant` → `zh-TW` → `zh-HK` → `zh` → `zh-Hans` → `zh-CN` → `zh-SG`, producing `alternate_chinese_name.csv` as a lookup table. This is an intermediate artifact regenerated on every run, not a hand-maintained list.
3. **The `alternatenames` column that ships inside `cities500.txt`.** This is the last Chinese source when the previous one misses. A single location often carries dozens of aliases, and the program picks out the Chinese one.

Once a candidate is in hand, **[the National Academy for Educational Research's foreign place-name glossary](https://data.gov.tw/dataset/15211)** makes the final call: with enough confidence it overwrites the existing name outright; with low confidence it only fills the gap when there was no Chinese name to begin with; and for questionable matches it keeps whatever was already there. All three outcomes are counted separately in the log, which makes it easy to check how much this layer changed before publishing.

If every source misses, the original text stays. Obscure locations can still show up in English inside Immich, and that is deliberate.

![The translate stage decision flow: try the LocationIQ name, then the Chinese entry filtered from alternateNamesV2, then the alternatenames column in cities500; run the candidate through OpenCC to decide whether Traditional conversion is needed; then let the National Academy for Educational Research glossary overwrite, fill a gap, or keep the existing name, falling back to the original text if everything misses](https://cdn.rxchi1d.me/inktrace-files/engineering/immich-geodata-tech-02-pipeline/translate-decision-flow.png "The order of the three candidate sources, the OpenCC check, and the glossary ruling")
{style="width:90%;"}

The output is `cities500_translated.txt` and `admin1CodesASCII_translated.txt`.

#### OpenCC Is Not a Blind Conversion Step

The Chinese names collected in the earlier steps may be written in Simplified Chinese, so this step tries to bring everything over to Traditional Chinese. But **not every Chinese string gets converted**: each one is inspected first. The program keeps both conversion directions ready, Simplified to Traditional (s2t) and Traditional to Simplified (t2s), and compares round-trip results to work out what a given string already is:

- `text == t2s(text)` → the string is already Simplified, so s2t is called to convert it to Traditional
- `text == s2t(text)` → the string is already Traditional, so it is kept untouched

The same rule applies when picking a candidate out of `alternatenames`: **a candidate that is already Traditional is taken as is**, and only Simplified candidates need converting.

The check has to come before the conversion because applying s2t unconditionally corrupts characters that were already correct. Some Simplified characters cover several meanings with one glyph while Traditional Chinese uses different characters for each meaning, so a string wrongly judged as Simplified and converted anyway ends up damaging translations that were fine already: 「里」 becomes 「裏」, 「占」 becomes 「佔」, and so on.

### `pack`: Packing

This stage arranges the translated files, `i18n-iso-countries/` (the country name mapping, covered in [How Reverse Geocoding Works](/en/posts/engineering/immich-geodata-tech-01-reverse-geocoding/)), `LICENSE`, and `NOTICE.md` into the release directory structure, writes `geodata-date.txt`, and finally produces `release.tar.gz` and `release.zip`.

That bundle is exactly what the `update_data.sh` install script downloads, and its directory structure maps directly onto where the files go inside Immich at install time.

## Verifying Without Calling External Services

The awkward part of this pipeline is that it depends on both network downloads and a paid API, so running the full thing to verify every change is out of the question. The CLI therefore offers two verification modes.

**dry-run**: verifies the stage orchestration of a release without downloading data or calling the API.

```bash
cargo run -- release --dry-run \
  --locationiq-api-key "fixture" \
  --country-code "KR" "TH" \
  --batch-size 100 --locationiq-qps 2
```

`--batch-size` and `--locationiq-qps` are throttling parameters for the `locationiq` stage (queries per batch, requests per second). A dry run never issues real requests; passing them is only there to make the orchestration follow the same path.

**fixture mode**: uses local fixed test data to produce a smoke artifact, which verifies that the release archive and the directory structure `update_data.sh` expects are both correct.

```bash
cargo run -- release --fixture-mode \
  --pass-locationiq \
  --output-folder /tmp/rust-release-smoke
```

The official release and nightly workflows both run the real pipeline, but they run the fixture release smoke first as a preflight check.

> [!NOTE] This stage layout is not new to the Rust version
> The six stages date back to the v2 Python and Polars era. The v3.0.0 Rust rewrite largely kept the stage names and responsibilities, and the main differences are at the implementation level.
> The more interesting difference is how each country's processing logic is registered. The Python version used a registry with automatic registration, so defining a handler class was enough for it to be picked up. The Rust version deliberately switched to explicit registration with an enum and static dispatch, which means adding a country requires updating the CLI country parsing and the dispatch in the same change. Those few extra lines buy an escape from "release behavior depends on whatever runtime scanning happened to find". The release pipeline produces the data every user downloads, and dynamic magic in a place like that is painful to debug when it goes wrong.

---

[The next post, Five Regions, Five Answers,](/en/posts/engineering/immich-geodata-tech-03-strategies/) moves into the per-country logic: why one shared pipeline ends up producing five different display strategies for five regions.

## References

- [Local data processing](https://github.com/RxChi1d/immich-geodata-zh-tw/blob/main/docs/zh-tw/development.md) - extract commands per country and instructions for the full pipeline
- [GeoNames Documentation](https://www.geonames.org/export/) - file formats of the source data
- [LocationIQ Documentation](https://locationiq.com/docs) - Reverse Geocoding API
