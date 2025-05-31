---
title: "Immich 部署、設定與反向代理 - Google 相簿的最佳開源替代方案"
date: 2025-04-26 00:00:00 +0800
lastmod: 2025-06-01T01:01:49+08:00
tags: ["docker", "immich", "nginx-proxy-manager"]
categories: ["container-platform"]
slug: "immich-deployment"
---

這篇文章介紹如何使用 Docker Compose 和 Portainer 部署 Immich，並提供優化臺灣繁體中文地名反向地理編碼、設定影片轉碼與機器學習硬體加速 (以 NVIDIA 為例)，以及更換機器學習模型的詳細步驟。

<!--more-->

## 前言

這個筆記中，我參考 [Immich 官方文件](https://immich.app/docs/install/unraid) 中 docker compose 的做法，使用 Portainer 來部署 Immich (包含 immich-server, immich-machining-learning, redis 和 postgres)。因此在開始之前，請確認已經安裝 Docker, Docker Compose ，並部署 Portainer 容器。

## 部署 Immich

1. 在 Portainer 中增新一個新的 stack，名稱為 `immich`。
2. stack 的內容為：
    ```yaml
    services:
      immich-server:
        container_name: immich_server
        image: ghcr.io/immich-app/immich-server:${IMMICH_VERSION:-release}
        volumes:
          - ${UPLOAD_LOCATION}:/usr/src/app/upload
          - /etc/localtime:/etc/localtime:ro
        env_file:
          - stack.env
        ports:
          - "2283:2283"
        depends_on:
          - redis
          - database
        restart: always
        healthcheck:
          disable: false

      immich-machine-learning:
        container_name: immich_machine_learning
        image: ghcr.io/immich-app/immich-machine-learning:${IMMICH_VERSION:-release}
        volumes:
          - model-cache:/cache
        env_file:
          - stack.env
        restart: always
        healthcheck:
          disable: false

      redis:
        container_name: immich_redis
        image: docker.io/redis:6.2-alpine@sha256:905c4ee67b8e0aa955331960d2aa745781e6bd89afc44a8584bfd13bc890f0ae
        healthcheck:
          test: redis-cli ping || exit 1
        restart: always

      database:
        container_name: immich_postgres
        image: docker.io/tensorchord/pgvecto-rs:pg14-v0.2.0@sha256:90724186f0a3517cf6914295b5ab410db9ce23190a2d9d0b9dd6463e3fa298f0
        environment:
          POSTGRES_PASSWORD: ${DB_PASSWORD}
          POSTGRES_USER: ${DB_USERNAME}
          POSTGRES_DB: ${DB_DATABASE_NAME}
          POSTGRES_INITDB_ARGS: '--data-checksums'
        volumes:
          - ${DB_DATA_LOCATION}:/var/lib/postgresql/data
        healthcheck:
          test: >-
            pg_isready --dbname="$${POSTGRES_DB}" --username="$${POSTGRES_USER}" || exit 1;
            Chksum="$$(psql --dbname="$${POSTGRES_DB}" --username="$${POSTGRES_USER}" --tuples-only --no-align
            --command='SELECT COALESCE(SUM(checksum_failures), 0) FROM pg_stat_database')";
            echo "checksum failure count is $$Chksum";
            [ "$$Chksum" = '0' ] || exit 1
          interval: 5m
          start_interval: 30s
          start_period: 5m
        command: >-
          postgres
          -c shared_preload_libraries=vectors.so
          -c 'search_path="$$user", public, vectors'
          -c logging_collector=on
          -c max_wal_size=2GB
          -c shared_buffers=512MB
          -c wal_compression=on
        restart: always

    volumes:
      model-cache:
    ```
3. **編輯 Environment variables：**
    1. 點擊 `Environment variables` 並切換至 `Advanced mode`。隨後，貼上下面的內容：
    
        ```
        UPLOAD_LOCATION=/IMMICH_DATA_LOCATION
        DB_DATA_LOCATION=/IMMICH_DB_LOCATION
        IMMICH_VERSION=release
        DB_PASSWORD=postgres
        DB_USERNAME=postgres
        DB_DATABASE_NAME=immich
        ```
        
    2. 根據個人偏好，設定以下參數：
        1. **UPLOAD_LOCATION:** 相片庫與資料的存放位置 (如 `/mnt/smb/immich`)。我個人是設定在通過 SMB 掛載 NAS 的位置。
        2. **DB_DATA_LOCATION:** postgres database 的位置 (如 `/appdata/immich/postgres`)。這個我是直接放在本機硬碟中。
        3. **TZ:** 時區 (`Asia/Taipei`)。
        
        > NOTE: 其餘參數不需要修改。
        
4. **啟動 stack，即可完成 Immich 的基本部署。**
    > 進階的調整，可以參考後續章節。

## 優化反向地理編碼資料（中文化＋臺灣地名顯示優化）

參考我的臺灣繁體中文化專案 [RxChi1d/immich-geodata-zh-tw](https://github.com/RxChi1d/immich-geodata-zh-tw) 設定 Immich 的 docker compose file。

在這個專案中，將地名翻譯為臺灣大眾習慣之繁體中文名稱之外，也優化了臺灣的行政區表示，使其可以準確地顯示出縣市以及鄉鎮市區。除此之外，也使用 [中華民國國土測繪中心](https://whgis-nlsc.moi.gov.tw/Opendata/Files.aspx) 的開放資料取代 [geodata](https://www.geodata.com/en/) 的開放資料，藉此更精準的反解臺灣的地名。

1. **停止 stack。**

2. **在 stack 設定中添加 `entrypoint`：**

    ```yaml
    services:
      immich_server:
       container_name: immich_server

       # 其他配置省略

       entrypoint: [ "tini", "--", "/bin/bash", "-c", "bash <(curl -sSL https://raw.githubusercontent.com/RxChi1d/immich-geodata-zh-tw/refs/heads/main/update_data.sh) --install && exec /bin/bash start.sh" ]
       
       # 其他配置省略
       ```
       
3. **啟動 stack。**

    通過添加 `entrypoint` 設定，未來每次重啟 stack，在 immich_server 容器啟動時，會自動下載並安裝最新版本的臺灣中文化地理資料。
    
>  💡 **Note:**
>  如果是簡體中文或中國的用戶可以參考 [ZingLix/immich-geodata-cn](https://github.com/ZingLix/immich-geodata-cn) ，該專案除了簡體中文翻譯之外，亦有針對中國地區之地名進行優化。

## 影片轉碼硬體加速

> 💡 **NOTE:**
> 安裝之前需要先安裝顯示卡的驅動程式與容器驅動。
> **以 NVIDIA 顯示卡為例:** 需安裝 NVIDIA Driver 以及 [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html)。

1. **停止stack。**
    
2. **下載設定檔:**
    
    從官網下載 [hwaccel.transcoding.yml](https://github.com/immich-app/immich/releases/latest/download/hwaccel.transcoding.yml) ，並將其放置到指定位置 (如 `/appdata/immich/hwaccel.transcoding.yml`)。
    
3. **編輯 stack:**
    
    添加 `extends`，並根據自己的硬體修改 service 的值。（Intel iGPU: quicksync, NVIDIA GPU: nvenc）。
    
    ```yaml
    immich-server:
        container_name: immich_server
        image: ghcr.io/immich-app/immich-server:${IMMICH_VERSION:-release}
        extends:
          file: /mnt/user/appdata/immich/hwaccel.transcoding.yml
          service: nvenc # set to one of [nvenc, quicksync, rkmpp, vaapi, vaapi-wsl] for accelerated transcoding
    
        # 其他配置省略
    ```
    
    > 💡 如果是 NVDIA 的顯示卡還需要加上：
    >     
    > ```yaml
    > immich-server:
    >
    >     # 其他配置省略
    >
    >     runtime: nvidia
    >     environment:
    >         - NVIDIA_VISIBLE_DEVICES=all
    >     	  
    >     # 其他配置省略
    > ```
    
    
4. **啟動 stack。**
    
5. 設定硬體加速的設備：

    `設定` → `影片轉碼` → `硬體加速` → `對應的選項`。

## 機器學習硬體加速

> 本篇使用 NVIDIA 的顯示卡實作。
> 如果是使用其他的硬體，或需要更詳細的參考文件，可以參考官方的 [Hardware-Accelerated Machine Learning](https://immich.app/docs/features/ml-hardware-acceleration)。

1. **停止 stack。**
    
2. **下載設定檔:**
    
    從官網下載 [hwaccel.ml.yml](https://github.com/immich-app/immich/releases/latest/download/hwaccel.ml.yml) ，並將其放置到指定位置 (如 `/mnt/user/appdata/immich/hwaccel.ml.yml`)。
    
3. **編輯 stack:**
    1. **`image`:**
        
        映像名稱字尾根據硬體加上後綴 `-cuda`。
        
        ```yaml
        # For hardware acceleration, add one of -[armnn, cuda, openvino] to the image tag.
        # Example tag: ${IMMICH_VERSION:-release}-cuda
        
        image: ghcr.io/immich-app/immich-machine-learning:${IMMICH_VERSION:-release}-cuda
        ```
        
    2. **`extends`:**
    
        加入 `extends`，並根據硬體更改 service 的值。（NVDIA GPU: cuda, Intel GPU: openvino）。
        
        ```yaml
        immich-machine-learning:
          # 其他配置省略

          extends: # uncomment this section for hardware acceleration - see https://immich.app/docs/features/ml-hardware-acceleration
            file: /mnt/user/appdata/immich/hwaccel.ml.yml
            service: cuda # set to one of [armnn, cuda, openvino, openvino-wsl] for accelerated inference - use the `-wsl` version for WSL2 where applicable
        
          # 其他配置省略
        ```
        
    
    > **NOTE:** immich-machine-learning 容器「不需要」加上 `runtime=nvidia` 和 `NVIDIA_VISIBLE_DEVICES=all` 變數。
    
4. **啟動 stack。**
    
    > **NOTE:** 機器學習硬體加速設定後，「不需要」在 WebUI 中做額外的設定。

## 更換機器學習模型

詳細內容可以參考 Immich 官方文件的 [Searching](https://immich.app/docs/features/searching)。

### CLIP

1. **選擇模型:**

    由於預設的 `ViT-B-32__openai` 模型對於中文的適配性不足，因此需要選擇支援多語言的 CLIP 模型。

    在 [官方文件](https://immich.app/docs/features/searching) 中，有提供各語言中，不同模型的準確度比較表格，其中也有詳細報告顯存需求以及推理時間，用戶可以根據需求選擇。（所有模型可以參考 Immich Hugging Face 的 [CLIP](https://huggingface.co/collections/immich-app/clip-654eaefb077425890874cd07) 和[Multilingual CLIP](https://huggingface.co/collections/immich-app/multilingual-clip-654eb08c2382f591eeb8c2a7)

    這邊我們可以參考「簡體中文」的表格來進行選擇。如果顯存足夠的話，可以直接選表現最好的模型 `nllb-clip-large-siglip__v1`：

    ![模型的簡體中文性能比較表](https://cdn.rxchi1d.me/inktrace-files/Docker_Container_Deployment/2025-04-26-Immich_Deployment_Configuration_and_Reverse_Proxy/Model_CN_Perf_Compare.png)
    _模型的簡體中文性能比較表_

2. **設定模型:**

    在設定頁面中，`機器學習設定` → `智慧搜尋` → `CLIP 模型`，填入所需模型的名稱即可。

    > 💡 **NOTE:**
    > 無需自行下載模型，immich-machine-learning 容器會在 Immich 需要調用模型時自動下載對應的模型。
    > 剛設定完後，可以在手動執行一次 `智慧搜尋` 作業，並在 immich-machine-learning 容器的 log 中查看是否有自動下載模型，並載入。

### 人臉辨識模型

詳細模型清單可以參考 Immich Hugging Face 的 [Facial Recognition](https://huggingface.co/collections/immich-app/facial-recognition-654eb881c0e106160e2e9c95)。

目前根據網路上的消息稱 `antelopev2` 的效果最佳。

由於官方沒有提供顯存開銷，這邊我提供我自己測試的結果供大家參考：

> - 測試顯卡為 NVIDIA Tesla P4
> - 由於並非特別將環境設定至顯卡空佔用，因此需要將表格的值扣除初始顯存開銷 (約 0.416 GiB) 才比較接近模型本身的顯存佔用。
> - 「儲存開銷欄位」表示模型的檔案大小。

- Facial Recognition (按大小降序排序)
    
    | Name | 顯存開銷 (**GiB**) (要減0.416) | 儲存開銷 (M) |
    | --- | --- | --- |
    | antelopev2 | 1.955 | 265 |
    | buffalo_l | 1.680 | 183 |
    | buffalo_m | 1.428 | 170 |
    | buffalo_s | 0.996 | 16 |
    
## Nginx Proxy Manager 反向代理

未完待續...
