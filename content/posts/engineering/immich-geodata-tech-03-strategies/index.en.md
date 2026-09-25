---
title: "Immich Traditional Chinese Geodata (3): Five Regions, Five Strategies"
slug: "immich-geodata-tech-03-strategies"
date: 2026-08-26T10:00:00+08:00
lastmod: 2026-09-25T12:42:09+08:00
description: "Japan keeps its native kanji names, South Korea uses official hanja, Thailand and Indonesia are translated with a fallback to the official original. Unpacking the single criterion behind all five place-name strategies in immich-geodata-zh-tw."
tags: ["immich", "geodata", "localization", "gis"]
categories: ["engineering"]
series: ["immich-geodata-zh-tw"]
series_order: 4
---

The [first](/en/posts/engineering/immich-geodata-tech-01-reverse-geocoding/) [two posts](/en/posts/engineering/immich-geodata-tech-02-pipeline/) covered the mechanism and the pipeline: Immich reads place names from `cities500.txt`, and that file is produced from national mapping data by `extract` and `release`. Technically, "how to swap the data" is a settled question. The genuinely hard part is something else: **what should a foreign place name look like so that it reads naturally to a Taiwanese user?**

immich-geodata-zh-tw currently handles five regions, and it gives five different answers. This post is about the criterion behind those answers.

<!--more-->

## The Five Regional Strategies

| Region | Display language | Source data |
| :--- | :--- | :--- |
| 🇹🇼 Taiwan | Official Traditional Chinese names | National Land Surveying and Mapping Center (NLSC) village boundaries |
| 🇯🇵 Japan | Native Japanese names (kanji and kana) | 国土数値情報 (N03 administrative areas) |
| 🇰🇷 South Korea | Traditional Chinese for first-level divisions, official Korean hanja for cities and counties | admdongkor administrative-dong boundaries |
| 🇹🇭 Thailand | Traditional Chinese translation, with official English and Thai as fallbacks | COD-AB (Royal Thai Survey Department / OCHA) |
| 🇮🇩 Indonesia | Traditional Chinese translation, with official BIG Indonesian as fallback | Indonesian Geospatial Information Agency (BIG) village-level data |
| 🌏 Everywhere else | NAER official translation → GeoNames Chinese → keep the original | GeoNames |

Five answers looks messy, but there is only one criterion behind them: **which form reads most naturally to a Taiwanese user.**

This is not a linguistic classification. Japanese and Korean administrative names are written in Chinese characters, so a Taiwanese reader understands them without any translation at all. On top of that, when it comes to Japanese place names, Taiwanese users are actually more used to seeing the original form, even when a name contains hiragana or katakana. Given that, translating would not make the information any easier to read; it would only add one more chance to get something wrong.

The reverse case is Thai and Indonesian, which are simply not readable for a Taiwanese audience, so translation is the only option. That, and nothing more, is where the "five answers" come from.

## Japan: Why Immich Shows the Native Japanese Names

Japan is the clearest illustration of this criterion.

Japanese administrative names are already written in Chinese characters: `横浜市`, `静岡県`, `渋谷区`. In principle they could be "translated" into the character forms customary in Taiwan, giving 橫濱市 (Yokohama), 靜岡縣 (Shizuoka), 澀谷區 (Shibuya). Doing so creates two problems.

First, **that is not translation, it is transliteration between character forms**. `横浜市` and 橫濱市 refer to the same place and the same set of characters, only rendered in different glyph conventions. Running this through automated conversion can easily produce half-converted results such as `静岡県` turning into 靜岡県.

Second, **the original is more natural for Taiwanese users**. `横浜市` is readable as-is, and even `うるま市` does not create a real comprehension barrier. After years of seeing Japanese signage, station names, and maps, a reader hits a brief moment of friction when 橫濱市 shows up instead. When the original is both readable and familiar, translation offers nothing but added risk of error.

So the Japan handler (the module in the project responsible for processing one region's data) uses the Japanese names from the `N03` field of the official mapping data verbatim, without changing a single character. That one decision also removes every problem an entire translation pipeline would have to deal with.

> [!NOTE]
> Japan's government-designated cities get extra handling: `admin_2` shows only the city name (for example `横浜市`), while the ward name (for example `中区`) goes into `admin_3` of the intermediate CSV. For towns and villages under a district, the handler decides whether a district prefix is needed to avoid name collisions.

## South Korea: Official Hanja for Cities, Customary Chinese Names for First-Level Divisions

The Korean source data is in Hangul: `관악구`, `청주시`. But Korean administrative names are likewise built from Chinese characters. The official hanja for `청주시` is 淸州市 (Cheongju), and for `관악구` it is 冠岳區 (Gwanak). Those characters are not the output of a translation process; they are how the name is written to begin with.

The current approach therefore works in two layers.

**City and county level comes from the hanja notation in Korean Wikipedia articles.** There are more than 200 divisions at this level, so maintaining them one by one is not realistic, and the hanja notation is itself the official written form, so it can be adopted directly. Wikidata's role here is limited to identifying which entity a division is and validating its administrative parentage; the names themselves are not taken from it.

In terms of character orthography, the project adheres strictly to official Korean hanja notation. Just as Japanese data preserves shinjitai forms (such as 「県」 and 「浜」), South Korea deliberately preserves the Kangxi dictionary forms officially used in Korea (such as 「淸州市」 rather than 「清」, and 「尙州市」 rather than 「尚」).

At the same time, this mechanism permanently eliminated the long-standing errors previously caused by volatile Traditional Chinese labels in Wikidata.

**First-level divisions use a lookup table built into the handler.** There are only 16 of them, the count is fixed, and hardcoding is more reliable than querying, which also keeps results from drifting between versions.

> [!NOTE]
> This lookup table directly incorporates South Korea's latest administrative reforms effective 2026-07-01: Jeollanam-do and Gwangju Metropolitan City merged into "Jeonnam-Gwangju Integrated Special City" (reducing first-level divisions from 17 to 16); while Jung-gu, Dong-gu, and Seo-gu in Incheon Metropolitan City were reorganized into Jemulpo-gu, Yeongjong-gu, Seohae-gu, and Geomdan-gu.

The more interesting detail is that the table stores customary short forms rather than full official names:

- 首爾特別市 (Seoul Special City) → 首爾市
- 釜山廣域市 (Busan Metropolitan City) → 釜山市
- 世宗特別自治市 (Sejong Special Self-Governing City) → 世宗市
- 全南光州統合特別市 (Jeonnam-Gwangju Integrated Special City) → 全南光州市

Those administrative-category qualifiers almost never appear in everyday usage, and putting them in an album's location field only adds reading overhead.

Provinces follow the same rule and always come out as "X道", so `경기도` becomes 京畿道 (Gyeonggi).

The benefit of normalizing everything to "X市" and "X道" is consistency: all 16 first-level divisions look alike in the album location field, instead of alternating between 特別自治道 and 廣域市.

The rule also explains a few outputs that look like the project is holding on to pre-reform names. Stripping the modifier from `강원특별자치도` gives 江原道 and `제주특별자치도` gives 濟州道, which happen to match what both provinces were called before their reclassification. That is a coincidence, not a deliberate choice to keep the old names. The one case that needs extra handling is `전북특별자치도`, where the Korean name already uses the contraction 전북 (全北). Applying the rule mechanically would produce 全北道, which is not a real name, so the mapping expands it to the full 全羅北道.

## Thailand and Indonesia: Translation Is the Only Option, and the "City" Level Dilemma

Neither Thai nor Indonesian uses Chinese characters, so `นครราชสีมา` (Nakhon Ratchasima) and `Kecamatan Ubud` (Ubud) have no "original Chinese-character form" to fall back on. These two countries therefore have to go the translation route, resolving the administrative entity through Wikidata and then taking its Traditional Chinese name.

Once you are translating, you have to be ready for the cases where translation fails. Both countries use a layered fallback:

- **Thailand**: Wikidata Traditional Chinese → COD-AB official English → official Thai.
- **Indonesia**: Mapping table Traditional Chinese (NAER → Wikidata → OSM) → BIG official Indonesian.

### Indonesia's Level Dilemma: Why "District" (Kecamatan)?

In Immich's three-part `Country · State · City` interface, mapping Indonesia to level 2 (Kabupaten, regency) yields higher Chinese translation coverage, but regency jurisdictions are so large that album localization loses meaning. For example, photos taken in the popular destination Ubud would merely display `Indonesia · Bali · Gianyar Regency` (吉亞尼亞爾縣), which prevents most users from identifying where the photo was actually taken.

To ensure locations remain genuinely recognizable, the project subdivides Indonesia to the more granular level 3 administrative unit: **Kecamatan (district)**. However, finer granularity introduces a critical trade-off: **the finer the administrative level, the sharper the drop in authoritative Chinese translation coverage**.

The project's design philosophy places **recognizability as top priority**:
- Popular tourist destinations and major urban centers are supplemented with Chinese district names via official translation datasets and open map data.
- Uncataloged areas fall back directly to native BIG Indonesian names (e.g., `Indonesia · Bali · Ubud`).

Falling back to native names might look like a compromise, but it is a deliberate choice: displaying the native name `Ubud` is both accurate and immediately clear, whereas forcing an obscure or unverified Chinese translation risks obscuring errors. This trade-off is explored in detail in [Part 4: Six Failure Modes of Wikidata Translations](/en/posts/engineering/immich-geodata-tech-04-translation/).

### Extending to Malaysia: Normalizing Messy Hierarchy to Districts (Daerah)

The same principle of level consistency extends to regions processed by LocationIQ. Taking Malaysia as an example:
Directly applying standard reverse geocoding often elevates miscellaneous address attributes to city names, mixing housing developments, mile markers, or street numbers into the same area.
The project normalizes Malaysia to the **daerah (district)** level, where the vast majority of locations have official Traditional Chinese district names, completely resolving level skipping and fragmented naming.

## Everywhere Else: A Three-Layer Fallback

Regions without a dedicated handler go through the global pipeline:

1. **[NAER *Foreign Place Names* dataset](https://data.gov.tw/dataset/15211)**: official Taiwanese translations, currently over sixty thousand entries, used first.
2. **GeoNames Chinese data**: used when NAER has no entry.
3. **Keep the original**: when neither has an entry, the source language stays.

So obscure locations may still show up in English inside Immich. That is intentional. Rather than forcing a translation, it is better to show users a name they can at least search for.

## One Criterion, Five Outcomes

Looking back, the differences across regions all trace to the same question: what reads most naturally to a Taiwanese user:

- Place names in Taiwan, Japan, and South Korea are written in Chinese characters, so readers understand them without translation, and the official written form is used as-is. The only difference is that Taiwan's is Chinese while Japan's and South Korea's are their respective official kanji and hanja.
- Thai and Indonesian scripts are not readable for a Taiwanese audience, so those names are translated, with a fallback to the official original ready.
- Other regions have no dedicated source data, so translation databases fill the gap, and anything they miss keeps its original name.

Worth noting: none of these decisions is about which approach is more correct. Each one is about which approach is more useful to the people who actually use this data.

[The next post, on translating place names with Wikidata and how it fails quietly](/en/posts/engineering/immich-geodata-tech-04-translation/), gets into the messiest part of this route: when Wikidata gets a place name wrong, the failure usually does not break the pipeline. It quietly produces a perfectly plausible-looking, wrong Chinese name.

---

## References

- [Supported regions and language strategies](https://github.com/RxChi1d/immich-geodata-zh-tw#支援地區與語言策略) - the comparison table in the project README
- [Per-region processing docs](https://github.com/RxChi1d/immich-geodata-zh-tw/tree/main/docs/zh-tw) - full processing logic for Taiwan, Japan, South Korea, Thailand, and Indonesia
- [国土数値情報ダウンロードサービス](https://nlftp.mlit.go.jp/ksj/) - Japanese administrative area data
- [admdongkor](https://github.com/vuski/admdongkor) - South Korean administrative-dong boundary data
- [COD-AB Thailand](https://data.humdata.org/dataset/cod-ab-tha) - Thai administrative boundaries
- [Indonesian Geospatial Information Agency (BIG)](https://www.big.go.id/) - Indonesian village-level administrative data
- [NAER *Foreign Place Names* dataset](https://data.gov.tw/dataset/15211) - official Taiwanese translations for place names worldwide
