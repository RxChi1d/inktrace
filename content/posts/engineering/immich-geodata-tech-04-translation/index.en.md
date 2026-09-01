---
title: "Immich Traditional Chinese Geodata (4): Translating Place Names with Wikidata, and How It Fails Silently"
slug: "immich-geodata-tech-04-translation"
date: 2026-08-27T10:00:00+08:00
lastmod: 2026-08-31T22:21:53+08:00
description: "Six known failure modes when translating place names with Wikidata: errors never break the pipeline, they quietly emit a valid Chinese name pointing at the wrong place. With a real case of a safeguard causing the bug."
tags: ["immich", "wikidata", "sparql", "knowledge-graph", "data-quality"]
categories: ["engineering"]
series: ["immich-geodata-zh-tw"]
series_order: 5
---

[The previous post, Five Regions, Five Strategies](/en/posts/engineering/immich-geodata-tech-03-strategies/), noted that place names written in non-Han scripts, as in Thailand and Indonesia, can only go down the translation route, and that the translation source this project settled on is Wikidata.

What follows is not about how to query. SPARQL itself is not the hard part. The hard part is this: **when Wikidata gets it wrong, there is usually no sign at all**. The pipeline does not stop, the log reports no error, and the output is a perfectly valid Chinese string that simply points to the wrong place.

<!--more-->

## Why Wikidata

Place-name data has a few properties that make general-purpose translation a poor fit:

1. **Duplicate names are everywhere**: South Korea has a Jung-gu in Seoul, another in Busan, another in Daegu. Thailand and Indonesia are equally full of repeated district names. A translation API sees no context and cannot tell them apart.
2. **Place names are a lookup, not a semantic translation**: what "Ngawi" should become depends on the Chinese rendering already conventional in usage, not on the literal meaning of the word.
3. **A verification channel is required**: the result has to be confirmable as "this really is that administrative division", not merely "this string reads plausibly".

Wikidata fills exactly that gap. It is a structured knowledge graph in which every geographic entity carries:

- **[P131 (located in the administrative territorial entity)](https://www.wikidata.org/wiki/Property:P131)**: an explicit statement of the parent administrative division.
- **P31 (instance of)**: distinguishes a city from a district, a train station, or a government body.
- **Multilingual labels**: including Chinese variants such as `zh-tw` and `zh-hant`.

With P131 available, duplicate names can be settled by parent division. When querying Jung-gu (`중구`), additionally require its P131 chain to contain Seoul (`Q86`), and Busan's Jung-gu falls out on its own.

```sparql
SELECT ?item ?itemLabel WHERE {
  # Bind the Korean name directly; do not FILTER over every label in the graph (that will almost certainly time out)
  ?item rdfs:label "중구"@ko.

  # The key step: verify it really sits on Seoul's administrative chain
  ?item wdt:P131+ wd:Q86.

  SERVICE wikibase:label { bd:serviceParam wikibase:language "zh-tw,zh-hant,zh,en". }
}
```

Up to this point, everything looks fine.

## Failure Is Silent

Run this in practice and you find that the pipeline fails in two ways, and that **the two look nothing like each other**:

**The first: no entity is found, or every candidate fails the containment check.**
The result falls back to the source-language original, and that place name stays untranslated. This is actually the good outcome. It lands in the untranslated list, visible at a glance.

**The second: the wrong entity gets selected, and that entity passes the P131 check.**
The translated name is taken straight from the wrong entity. This is the hardest one to notice, because the output is a valid Chinese string that never appears in any anomaly list.

A real instance of the second kind: Seoul's `관악구` (Gwanak-gu, 冠嶽區) was once emitted as 新林洞 (Sillim-dong). Gwanak-gu really does contain Sillim-dong, and Sillim-dong's P131 chain really does contain Seoul, so the check passes cleanly. Nothing in the data looks wrong, unless somebody sits down and compares every single district name.

![Three outcomes of Wikidata place-name translation: passing verification yields the correct name; finding nothing falls back to the original and shows up in the untranslated list; selecting the wrong entity yet passing verification yields an invisible mistranslation](https://cdn.rxchi1d.me/inktrace-files/engineering/immich-geodata-tech-04-translation/wikidata-failure-paths.png "Of the three paths, only the fallback to the original is a visible failure")
{style="width:80%;"}

## Six Known Ways to Get It Wrong

These are the forms the project has actually run into and recorded:

| Failure mode | Case | How to spot it |
| :--- | :--- | :--- |
| Search selects the wrong entity | `관악구` matched `신림동`, a neighborhood inside it; `송파구` matched the subway station `잠실역` | The candidate's source-language label is not equal to the queried name |
| Upstream label stuck on an older designation | The Chinese label for `여주시` used to be 驪州郡, the name it held before promotion | The administrative-level suffix does not line up (시 → 市, 군 → 郡, 구 → 區) |
| Claims to be Traditional, but the glyphs are wrong | The `zh-tw` label for `함평군` turns 咸 into 鹹; Indonesia's Papua leaves the Simplified form 巴布亚 sitting in `zh-hant` | Manual spot checks, or a scan against a list of Simplified-only characters |
| P131 statement missing | `영종구` had none at all for a while after the district was created | The containment check fails and no statement can be found |
| P131 marked deprecated | The statement placing Indonesia's `Kabupaten Ngawi` in East Java was once marked deprecated | SPARQL's [`wdt:` prefix follows only best-rank statements](https://www.wikidata.org/wiki/Wikidata:SPARQL_query_service/queries#Truthy_statements), so deprecated is equivalent to absent |
| Our own filter rules kill the correct candidate | See the next section | The correct entity is simply not in the candidate set |

The fifth one deserves particular attention, because it runs entirely against intuition. The `Kabupaten Ngawi` data was still sitting on Wikidata the whole time, just flagged as deprecated, and the `wdt:` prefix only ever follows best-rank statements. As far as the query is concerned, that statement does not exist.

## The Most Ironic One: The Safeguard Manufactures the Error

The sixth mode is entirely our own doing.

To stop the search from landing on government bodies (district offices, education bureaus, that sort of thing), the original approach was a keyword blacklist: walk through every label retrieved for a candidate entity and discard anything containing characters like 廳 or 所.

And then the correct `관악구` got discarded. Its `zh-hant` label had been imported by a bot from a Chinese Wikipedia infobox as 冠嶽區**廳**, which is the name of the district office, not the name of the district. The blacklist duly recognized 廳 and kicked out the one correct candidate. The closest thing left in the pool was that Sillim-dong.

**A blacklist of exclusion rules can never be completed**, and it will take out a correct candidate over a label in some entirely unrelated language. The South Korea handler was later switched to a whitelist test: the candidate's source-language label must be an **exact match** for the queried name. Government bodies, job titles, electoral districts and stations never carry exactly the same name as the administrative division, so they drop out on their own, and no keyword list needs maintaining.

> [!WARNING]
> The Indonesian processing path still retains a similar keyword-matching mechanism, covering both Chinese-family labels and wiki article titles, which is precisely the scope that killed `관악구` in the first place. No false positives have been observed for Indonesia so far, but the risk is known.

## Verification Methodology: Counts Are Not Enough

These failure modes lead to one operating principle: **when verifying data, compare the full list of untranslated names, never just the count**.

A real case: when Indonesia moved from the old dataset to the new one, the number of untranslated second-level divisions held steady at 51, apparently unchanged. Only a line-by-line comparison revealed that `Kabupaten Ngawi` had dropped out, while a different place name had been translated successfully for the first time, the two canceling out exactly.

By the same token, a rise in the untranslated count cannot be taken at face value as "upstream added new divisions". New divisions upstream and a translation that has stopped working look identical in the numbers.

## Caching: Layered, and It Short-Circuits

SPARQL queries are slow, so caching is not optional. The cache file lives at `geoname_data/{country_code}_wikidata_cache.json` in the project (`KR_wikidata_cache.json`, for example) and is split internally into several layers:

- `cache.search`: search results
- `cache.labels`: an entity's multilingual labels
- `cache.instance_of`: P31 classes
- `cache.p131`: containment verification results
- `translations`: the final naming decision

There is a pitfall here that shows up in practice. A `translations` hit has to satisfy two conditions at once: the parent QID computed on this run matches the one recorded in the cache, and that cached entry is either a translation failure or has already passed containment verification. When both hold, the pipeline **takes the cached result directly and never reads `cache.p131` at all**.

Which means that after fixing a P131 statement upstream, clearing only `cache.p131` and re-running will appear to change nothing, because that layer is never reached. To re-verify a single entity, both `cache.p131` and `translations` have to be cleared. If what changed is the candidate filtering logic, re-running against an empty cache is less trouble.

## Fix Upstream First

Last comes a principle about direction: **if a translation error originates in Wikidata itself, go and fix Wikidata rather than adding another mapping entry inside the project.**

Fixing upstream benefits every user. A mapping table benefits only this project, and it has to be maintained indefinitely. The South Korea example came up in [the previous post](/en/posts/engineering/immich-geodata-tech-03-strategies/): the seven manual mapping entries originally planned to patch upstream errors dropped to zero once Korean Wikipedia's hanja notation was adopted as the name source.

The core lesson of the translation route is roughly this: **do not translate what you can avoid translating, make what you must translate verifiable, and fall back honestly to the original when verification fails.** A place name that visibly went untranslated is worth far more than a wrong one that looks entirely reasonable.

## References

- [Known failure modes of Wikidata-based translation](https://github.com/RxChi1d/immich-geodata-zh-tw/blob/main/docs/zh-tw/wikidata-translation.md) - the project's full technical documentation
- [Wikidata Query Service](https://query.wikidata.org/) - the SPARQL query interface
- [Wikidata P131](https://www.wikidata.org/wiki/Property:P131) - located in the administrative territorial entity

---

[The next post, Rebuilding Taiwan's Administrative Divisions from Official Datasets](/en/posts/engineering/immich-geodata-tech-05-taiwan/), returns to Taiwan and looks at just how simple the pipeline can get when an official dataset is available.
