---
title: "Localized Place Names for Immich - immich-geodata-zh-tw Project Overview and Setup Guide"
slug: "immich-geodata-zh-tw"
date: 2025-10-05T13:35:00+08:00
lastmod: 2026-08-31T22:18:14+08:00
description: "immich-geodata-zh-tw setup guide: add one entrypoint line to your Docker Compose file and Immich will show localized place names for Taiwan, Japan, South Korea, Thailand, and Indonesia. Manual and non-container deployment included."
tags: ["docker", "immich"]
categories: ["container-platform"]
series: ["immich-geodata-zh-tw"]
series_order: 1
---

This article introduces immich-geodata-zh-tw, a reverse geocoding optimization for Immich built for Traditional Chinese users. Besides deep localization for Taiwan (Chinese place names and complete administrative levels), coverage currently extends to Japan, South Korea, Thailand, and Indonesia. Every other region falls back to the Chinese names commonly used in Taiwan, and the whole dataset is kept current by an automated update mechanism.

<!--more-->

In "[Immich Deployment, Configuration, and Reverse Proxy - The Best Open-Source Alternative to Google Photos](/en/posts/container-platform/immich-deployment/)" we finished a basic Immich deployment. You may have run into a few problems since then:
- Photo location data is all in **English**. For example, Immich's raw output shows "Sanzhi, Taipei, Taiwan, Province of China".
- **Administrative levels are incomplete**, so you cannot narrow a photo down to a township or district, and sometimes the location is simply wrong.
- **Asian place names are unfriendly**. Locations in Japan, South Korea, Thailand, and Indonesia usually show up as romanized text only.

To solve these problems I built **[immich-geodata-zh-tw](https://github.com/RxChi1d/immich-geodata-zh-tw)**, which replaces Immich's reverse geocoding database with one that matches what users in Taiwan actually expect to read.

{{< github repo="rxchi1d/immich-geodata-zh-tw" showThumbnail=true >}}

## Why does Immich show photo locations in English?

Immich's built-in reverse geocoding relies mainly on the global GeoNames database, which causes three problems for Traditional Chinese users:

1. **English place names**: no Traditional Chinese translations.
2. **Incomplete administrative levels**: only the county or city name, with no township or district level below it.
3. **Imprecise place name resolution**: without localized boundary data, the result is sometimes the wrong location entirely.

For example, a photo taken at Taipei 101 may show only "Taipei, Taiwan, Province of China" instead of "Taiwan, Taipei City, Xinyi District". Likewise, Chiyoda in Tokyo becomes the romanized "Chiyoda, Tokyo, Japan" rather than 東京都千代田区.

This project fixes all of the above by importing official or open-source high-precision boundary data from each country and combining it with an automated translation pipeline.

If you want to know why swapping a few plain text files changes the place names Immich displays, see [How Reverse Geocoding Works](/en/posts/engineering/immich-geodata-tech-01-reverse-geocoding/) in the technical series.

## Which regions does immich-geodata-zh-tw support?

| Region | Display language | Boundary data source |
| :--- | :--- | :--- |
| 🇹🇼 Taiwan | Official Traditional Chinese names | NLSC village and borough boundaries |
| 🇯🇵 Japan | Native Japanese (kanji and kana) | National Land Numerical Information (KSJ) |
| 🇰🇷 South Korea | Traditional Chinese for provinces, official Korean hanja for cities | admdongkor administrative dong boundaries |
| 🇹🇭 Thailand | Traditional Chinese, with official English and Thai as fallback | COD-AB (OCHA) |
| 🇮🇩 Indonesia | Traditional Chinese, with official BIG Indonesian as fallback | Indonesian Geospatial Information Agency (BIG) village-level data |
| 🌏 Other regions | NAER official translation → GeoNames Chinese → original name | GeoNames |

For Taiwan, on top of the Chinese names, the project also fixes the incorrect country name, fills in the many missing county and city names, and completes the full hierarchy from special municipality or county down to township and district.

> [!NOTE]
> South Korean cities are shown using the official Korean hanja, for example 淸州市 rather than 清州市. Korean place names are hanja words to begin with, so the hanja is the original name rather than a translation. This follows the same logic as keeping Japanese kanji, and small glyph differences from the forms normally written in Taiwan are expected.
>
> For why each region uses a different strategy, see [Five Regions, Five Answers](/en/posts/engineering/immich-geodata-tech-03-strategies/) in the technical series.

## Before and after

![Before and after comparison](https://cdn.rxchi1d.me/inktrace-files/container-platform/immich-geodata-zh-tw/comparison.png)
{style="width:80%;"}

Place names are more accurate, and Chinese search works far better too.

---

## Installation

### Before you start

Check the following prerequisites:

- **Immich is already deployed and starts normally** (if not, start with "[Immich Deployment, Configuration, and Reverse Proxy](/en/posts/container-platform/immich-deployment/)")
- You can modify `docker-compose.yml` and restart containers
- **Integrated deployment requires the container to reach `github.com` at startup**. If your environment has no outbound access, use manual deployment instead
- You know your Immich version (this project supports v2 and v3; only environments still on old v1 releases need to watch for the path differences noted below)
- Your photos contain GPS data, otherwise Immich has no way to determine a location

Method A fits most people: if you deploy with Docker Compose and the container can reach GitHub, one added line in `docker-compose.yml` is all it takes, and the data stays updated automatically afterwards. If you have special mount requirements, or your environment has no outbound access to begin with, use method B and download the data yourself. If Immich is not running in a container at all (native macOS installs, LXC, or bare metal), go straight to "[Other deployment methods](#other-deployment-methods)".

### Method A: Integrated deployment 🚀 (recommended) {#method-a}

If you deploy Immich with Docker Compose, this is the simplest option and the only one that keeps itself updated.

> If you use the Synology Docker package, see Chiyuan Chien's [Immich 相簿地理位置如何改以中文顯示？](https://cychien.tw/wordpress/2025/04/05/immich%E7%9B%B8%E7%B0%BF%E5%9C%B0%E7%90%86%E4%BD%8D%E7%BD%AE%E5%A6%82%E4%BD%95%E6%94%B9%E4%BB%A5%E4%B8%AD%E6%96%87%E9%A1%AF%E7%A4%BA%EF%BC%9F/).

#### 1. Modify docker-compose.yml

Add an `entrypoint` setting to the `immich_server` service:

```yaml
services:
  immich_server:
    container_name: immich_server
    # ...remaining settings omitted
    # Note: releases/latest/download is used here to make sure a stable release is downloaded
    entrypoint: [ "tini", "--", "/bin/bash", "-c", "bash <(curl -sSL https://github.com/RxChi1d/immich-geodata-zh-tw/releases/latest/download/update_data.sh) --install && exec start.sh" ]
```

> [!IMPORTANT]
> The command must end with `exec start.sh`. Writing it as `exec /bin/bash start.sh` prevents Immich v1.142.0 and later from resolving its own path, which sends the container into a restart loop.

> [!WARNING] Immich will not start if it cannot reach GitHub
> `&&` is a short-circuit operator: if the download fails the script exits non-zero, `exec start.sh` never runs, and the container exits immediately. This is deliberate. It stops Immich from starting without the Chinese geodata, which would leave you thinking the localized place names were applied when they were not.

Using the official Immich [docker-compose.yml example](https://github.com/immich-app/immich/releases/latest/download/docker-compose.yml), the complete file looks like this:

![docker-compose.yml example](https://cdn.rxchi1d.me/inktrace-files/container-platform/immich-geodata-zh-tw/docker-compose-example.png "docker-compose.yml example")

#### 2. Restart Immich

```bash
docker compose down && docker compose up -d
```

#### 3. Verify the installation {#check-install-status}

Check the container logs:
```bash
docker logs immich_server
```

What to look for:
1. Whether the `immich-geodata-zh-tw` execution and download messages appear.
  Output similar to the following means the script ran successfully:
  ![Checking the immich-geodata-zh-tw script output](https://cdn.rxchi1d.me/inktrace-files/container-platform/immich-geodata-zh-tw/check-geodata-script.png "Checking the immich-geodata-zh-tw script output")
  If the script ends by printing `驗證通過` (verification passed), the data really was written to the locations Immich reads from, including the `en.json` file that determines how country names are displayed. This is a more reliable signal than searching the log for keywords.
2. Whether Immich prints `10000 geodata records imported` after it starts, which means the data loaded successfully.
  ![Checking the Immich geodata import result](https://cdn.rxchi1d.me/inktrace-files/container-platform/immich-geodata-zh-tw/check-geodata-import.png "Checking the Immich geodata import result")

<a id="fix-import-failed"></a>
> [!QUESTION] No import message?
> Immich compares the contents of `geodata/geodata-date.txt` against the record in its database and only re-imports when the two **differ in content**. It compares content, not which date is newer.
> Integrated deployment reinstalls the data on every startup, so an unchanged date simply means the same dataset has already been imported. In that case, check that "Extract Metadata" was run with the "All" option and that your photos actually contain GPS data.
> For manual and other deployment methods, you can change `geodata/geodata-date.txt` to something **different** from its current value (today's date, for example) and restart Immich to force a re-import.

That completes the integrated deployment. **If your Immich library already contains photos, one step remains**: "[Re-extract photo metadata](#extract-metadata)", which is what applies the new location data to existing photos.

---

### Method B: Manual deployment 🛠️

For environments with special mount requirements or no outbound network access.

#### 1. Modify the docker-compose.yml volumes

```yaml
volumes:
  - /path/to/your/immich/geodata:/build/geodata:ro
  - /path/to/your/immich/i18n-iso-countries/langs:/usr/src/app/server/node_modules/i18n-iso-countries/langs:ro
```

> [!IMPORTANT]
> On Immich versions before v1.136.0 the container's internal layout differs, so the second line must be changed to `/path/to/your/immich/i18n-iso-countries/langs:/usr/src/app/node_modules/i18n-iso-countries/langs:ro`.

#### 2. Download the data

First fetch the download script:

```bash
curl -sSL https://github.com/RxChi1d/immich-geodata-zh-tw/releases/latest/download/update_data.sh -o update_data.sh
```

Then edit the `DOWNLOAD_DIR` variable near the top of the script (it lives in the configuration block in the first part of the file, so searching for `DOWNLOAD_DIR=` will find it) and set it to the **common parent directory** of the two mount paths above, which in this example is `/path/to/your/immich`. Then run:

```bash
bash update_data.sh
```

The result is the following structure, with no files to move by hand:

```text
/path/to/your/immich/geodata/
/path/to/your/immich/i18n-iso-countries/langs/
```

You can also download `release.tar.gz` or `release.zip` directly from the [GitHub Releases](https://github.com/RxChi1d/immich-geodata-zh-tw/releases) page, extract it, and place the `geodata` and `i18n-iso-countries` folders in the same locations.

> [!NOTE]
> UnRAID users can run the script through the User Scripts plugin.

#### 3. Restart the services

```bash
docker compose down && docker compose up -d
```

Once that is done, follow "[3. Verify the installation](#check-install-status)" to confirm the import succeeded.

---

### Other deployment methods (native macOS worker, LXC, and bare metal) 🖥️ {#other-deployment-methods}

The data can be installed even when Immich is not running in a Docker container, for example with [immich-apple-silicon](https://github.com/epheterson/immich-apple-silicon) or in LXC. The only difference is that the commands must run on **the machine running the microservices worker**, because geodata is imported only when that service starts.

Before installing, it is worth having the script print the locations it intends to write to:

```bash
bash <(curl -sSL https://github.com/RxChi1d/immich-geodata-zh-tw/releases/latest/download/update_data.sh) --print-paths
```

Once the paths look right, swap `--print-paths` for `--install` to perform the installation. If the paths are wrong, override them with `IMMICH_SERVER_ROOT` and `IMMICH_BUILD_DATA`. For details such as how to restart the macOS accelerator, and `sudo` considerations for LXC and bare metal, see the [Non-container deployment](https://github.com/RxChi1d/immich-geodata-zh-tw#非容器部署) section of the project README.

---

## Final step (all deployment methods): re-extract photo metadata 📸 {#extract-metadata}

After the data is imported you must **re-extract metadata** so that existing photos pick up the new location data. Newly uploaded photos get it automatically.

> [!TIP]
> If your Immich library has no photos yet, for example because you just deployed it, you can skip this step.

1. **Log in to the Immich admin panel**
  ![Logging in to the Immich admin panel](https://cdn.rxchi1d.me/inktrace-files/container-platform/immich-geodata-zh-tw/extract-metadata-step-1.png "Logging in to the Immich admin panel")
2. Go to **Administration** → **Jobs**
  ![Opening the Jobs page under Administration](https://cdn.rxchi1d.me/inktrace-files/container-platform/immich-geodata-zh-tw/extract-metadata-step-2.png "Opening the Jobs page under Administration")
3. Find **Extract Metadata** and click **All**
  ![Selecting Extract Metadata and clicking All](https://cdn.rxchi1d.me/inktrace-files/container-platform/immich-geodata-zh-tw/extract-metadata-step-3.png "Selecting Extract Metadata and clicking All")

Location data on existing photos will now be updated to the localized place names, and new uploads will use them directly.

> [!QUESTION] Metadata extracted, but the names did not change?
> See "[No import message?](#fix-import-failed)" to confirm whether Immich really re-imported the geodata.
---

## Advanced usage

### Pinning a specific version

If the latest release has a problem, or you want to stay on a specific version such as `v3.2.0`, use the `--tag` option. **The script itself is always fetched from the latest release; `--tag` only determines the data version.**

**Integrated deployment:**
Modify the command in `entrypoint`:
```yaml
entrypoint: [ "tini", "--", "/bin/bash", "-c", "bash <(curl -sSL https://github.com/RxChi1d/immich-geodata-zh-tw/releases/latest/download/update_data.sh) --install --tag v3.2.0 && exec start.sh" ]
```

**Manual deployment:**
```bash
bash update_data.sh --install --tag v3.2.0
```

> [!IMPORTANT]
> Do not change the script URL to `releases/download/<tag_name>/update_data.sh`. Automatically published releases such as `nightly` do not contain `update_data.sh`, so that URL returns a 404 and integrated deployment fails to start.

For the available versions, see the [Releases page](https://github.com/RxChi1d/immich-geodata-zh-tw/releases). If your environment has no outbound access, you can download `release.tar.gz` first and install it with `--archive`. Full option documentation is in the project's [update_data.sh usage guide](https://github.com/RxChi1d/immich-geodata-zh-tw/blob/main/docs/zh-tw/update-script.md).

---

## FAQ 🔧

**Q: How do I update the data?**
A: For integrated deployment, just restart docker compose and it updates itself. For manual deployment, run `bash update_data.sh` again and restart the container. For other deployment methods, run the same `--install` command again and restart the Immich service. After updating, remember to re-extract metadata if needed.

**Q: There is no import message and the localized names are not applied.**
A: Check the log for `geodata records imported`. If it is missing, see "[No import message?](#fix-import-failed)" to review the import conditions. Do not forget to re-extract metadata.

**Q: County and city names are now in Traditional Chinese, but the country name is still in English.**
A: This usually happens when you run Immich 1.136.0 or later together with an immich-geodata-zh-tw version older than v1.2.0. Using the latest release (the default) or any version from v1.2.0 onwards resolves it.
> Related link: [Issue #8](https://github.com/RxChi1d/immich-geodata-zh-tw/issues/8)

**Q: The container keeps restarting with `main.js not found`.**
A: This typically happens on Immich v1.142.0 and later, because Immich changed the name of its startup file. If you are still using an older `entrypoint` command (anything containing `exec node dist/main` or `exec /bin/bash start.sh`), update the entrypoint in your docker-compose.yml as shown in "[Method A: Integrated deployment 🚀 (recommended)](#method-a)".

> Related link: [Issue #13](https://github.com/RxChi1d/immich-geodata-zh-tw/issues/13)

**Q: Some photos show a location that differs from where they were actually taken.**
A: Immich matches place names by nearest distance, so coordinates near an administrative boundary can be assigned to the neighbouring district, and small islands or unusual terrain may not map precisely either. This is a consequence of how Immich resolves locations, not an error in the data. For how this nearest-neighbour lookup works, see [How Reverse Geocoding Works](/en/posts/engineering/immich-geodata-tech-01-reverse-geocoding/).

**Q: How do I remove this and restore the original place names?**
A: For integrated deployment, delete the `entrypoint` line from `docker-compose.yml`. For manual deployment, remove the two volume mounts. After restarting the container Immich falls back to the official GeoNames data (if the change does not take effect immediately, it is the same `geodata/geodata-date.txt` comparison issue), and a final metadata re-extraction finishes the job.

---

## Summary

Starting from v3, **immich-geodata-zh-tw** covers Thailand and Indonesia with official boundary data alongside Taiwan, Japan, and South Korea, and it applies the NAER official Taiwanese translations to place names worldwide. The result is a photo library where locations from trips around Asia read the way users in Taiwan expect.

If you want to know how this geodata is actually produced, including which files Immich reads, how each country's boundary data is processed, and how place names are translated and verified, the technical series walks through the entire pipeline. Start with [How Reverse Geocoding Works](/en/posts/engineering/immich-geodata-tech-01-reverse-geocoding/).

If you find this project useful, a star ⭐ on [GitHub](https://github.com/RxChi1d/immich-geodata-zh-tw) is always appreciated.

---

## References

- [Project GitHub repository](https://github.com/RxChi1d/immich-geodata-zh-tw)
- [GeoNames (global base data)](https://www.geonames.org/)
- [NLSC Open Data (Taiwan)](https://whgis-nlsc.moi.gov.tw/Opendata/Files.aspx)
- [National Land Numerical Information download (Japan)](https://nlftp.mlit.go.jp/ksj/)
- [admdongkor (South Korea)](https://github.com/vuski/admdongkor)
- [COD-AB Thailand (Thailand)](https://data.humdata.org/dataset/cod-ab-tha)
- [Geospatial Information Agency BIG (Indonesia)](https://www.big.go.id/)
- [National Academy for Educational Research, Foreign Place Name Translations](https://data.gov.tw/dataset/15211)
- [OpenStreetMap (global supplementary data)](https://www.openstreetmap.org/)
