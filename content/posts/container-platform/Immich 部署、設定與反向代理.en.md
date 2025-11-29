---
title: "Immich Deployment, Configuration, and Reverse Proxy - The Best Open-Source Alternative to Google Photos"
slug: "immich-deployment"
date: 2025-11-23T00:00:00+08:00
lastmod: 2025-11-29T22:26:07+08:00
tags: ["docker", "immich", "nginx-proxy-manager"]
categories: ["container-platform"]
---

This guide demonstrates how to deploy Immich using Docker Compose and Portainer, with detailed instructions for optimizing Traditional Chinese reverse geocoding for Taiwan, configuring video transcoding and machine learning hardware acceleration (using NVIDIA as an example), and replacing machine learning models.

<!--more-->

## Introduction

This tutorial follows the Docker Compose approach from the [official Immich documentation](https://immich.app/docs/install/unraid), deploying Immich (including immich-server, immich-machine-learning, Redis, and PostgreSQL) using Portainer. Before proceeding, ensure you have Docker, Docker Compose installed, and a Portainer container running.

## Deploying Immich

1. Create a new stack in Portainer named `immich`.
2. Set the stack content to:
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
3. **Configure environment variables:**
    1. Click `Environment variables` and switch to `Advanced mode`. Then paste the following content:

        ```
        UPLOAD_LOCATION=/IMMICH_DATA_LOCATION
        DB_DATA_LOCATION=/IMMICH_DB_LOCATION
        IMMICH_VERSION=release
        DB_PASSWORD=postgres
        DB_USERNAME=postgres
        DB_DATABASE_NAME=immich
        ```

    2. Customize the following parameters according to your preferences:
        1. **UPLOAD_LOCATION:** Storage location for photo library and data (e.g., `/mnt/smb/immich`). I personally set this to an SMB-mounted NAS location.
        2. **DB_DATA_LOCATION:** PostgreSQL database location (e.g., `/appdata/immich/postgres`). I place this directly on the local hard drive.
        3. **TZ:** Timezone (`Asia/Taipei`).

        > NOTE: Other parameters don't need modification.

4. **Start the stack to complete the basic Immich deployment.**
    > For advanced configurations, refer to the following sections.

## Optimizing Reverse Geocoding Data (Chinese Localization + Taiwan Place Name Optimization)

Immich's default geographic information displays in English, and Taiwan place names lack precision. To address this issue, I developed the [immich-geodata-zh-tw](https://github.com/RxChi1d/immich-geodata-zh-tw) project to optimize reverse geocoding for Taiwan:

- Translates place names into Traditional Chinese commonly used in Taiwan
- Optimizes Taiwan's administrative division display (Counties/Cities → Townships/Districts)
- Uses open data from the [National Land Surveying and Mapping Center of Taiwan](https://whgis-nlsc.moi.gov.tw/Opendata/Files.aspx) to improve accuracy

### Quick Setup

Add the `entrypoint` configuration to the `immich-server` Docker Compose settings:

```yaml
services:
  immich_server:
    container_name: immich_server

    # Other configurations omitted

    entrypoint: [ "tini", "--", "/bin/bash", "-c", "bash <(curl -sSL https://raw.githubusercontent.com/RxChi1d/immich-geodata-zh-tw/refs/heads/main/update_data.sh) --install && exec /bin/bash start.sh" ]

    # Other configurations omitted
```

After configuration, restart the stack. The container will automatically download and install the latest Taiwan Chinese geodata on each startup.

### Detailed Guide

For more details (including installation verification, manual deployment, version specification, troubleshooting, etc.), please refer to the project introduction article:

👉 **[Immich Geodata Taiwan Specialization - immich-geodata-zh-tw Project Introduction and Tutorial](/posts/container-platform/immich-geodata-zh-tw/)** (Traditional Chinese)

Or visit the [GitHub repository](https://github.com/RxChi1d/immich-geodata-zh-tw) directly.

>  [!TIP]
>  For Simplified Chinese users, refer to [ZingLix/immich-geodata-cn](https://github.com/ZingLix/immich-geodata-cn), which provides Simplified Chinese translation and optimization for place names in China.

## Video Transcoding Hardware Acceleration

>  [!WARNING]
> Before installation, you must install the GPU driver and container runtime.
> **For NVIDIA GPUs:** Install the NVIDIA Driver and [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html).

1. **Stop the stack.**

2. **Download the configuration file:**

    Download [hwaccel.transcoding.yml](https://github.com/immich-app/immich/releases/latest/download/hwaccel.transcoding.yml) from the official site and place it at a specified location (e.g., `/appdata/immich/hwaccel.transcoding.yml`).

3. **Edit the stack:**

    Add `extends` and modify the service value based on your hardware (Intel iGPU: quicksync, NVIDIA GPU: nvenc).

    ```yaml
    immich-server:
        container_name: immich_server
        image: ghcr.io/immich-app/immich-server:${IMMICH_VERSION:-release}
        extends:
          file: /mnt/user/appdata/immich/hwaccel.transcoding.yml
          service: nvenc # set to one of [nvenc, quicksync, rkmpp, vaapi, vaapi-wsl] for accelerated transcoding

        # Other configurations omitted
    ```

    >  [!NOTE] For NVIDIA GPUs, you also need to add:
    >
    > ```yaml
    > immich-server:
    >
    >     # Other configurations omitted
    >
    >     runtime: nvidia
    >     environment:
    >         - NVIDIA_VISIBLE_DEVICES=all
    >
    >     # Other configurations omitted
    > ```


4. **Start the stack.**

5. Configure hardware acceleration device:

    `Settings` → `Video Transcoding` → `Hardware Acceleration` → `Corresponding option`.

## Machine Learning Hardware Acceleration

>  [!TIP] This section uses NVIDIA GPUs as an example.
> For other hardware or more detailed documentation, refer to the official [Hardware-Accelerated Machine Learning](https://immich.app/docs/features/ml-hardware-acceleration) guide.

1. **Stop the stack.**

2. **Download the configuration file:**

    Download [hwaccel.ml.yml](https://github.com/immich-app/immich/releases/latest/download/hwaccel.ml.yml) from the official site and place it at a specified location (e.g., `/mnt/user/appdata/immich/hwaccel.ml.yml`).

3. **Edit the stack:**
    1. **`image`:**

        Add a suffix to the image name based on hardware: `-cuda`.

        ```yaml
        # For hardware acceleration, add one of -[armnn, cuda, openvino] to the image tag.
        # Example tag: ${IMMICH_VERSION:-release}-cuda

        image: ghcr.io/immich-app/immich-machine-learning:${IMMICH_VERSION:-release}-cuda
        ```

    2. **`extends`:**

        Add `extends` and modify the service value based on hardware (NVIDIA GPU: cuda, Intel GPU: openvino).

        ```yaml
        immich-machine-learning:
          # Other configurations omitted

          extends: # uncomment this section for hardware acceleration - see https://immich.app/docs/features/ml-hardware-acceleration
            file: /mnt/user/appdata/immich/hwaccel.ml.yml
            service: cuda # set to one of [armnn, cuda, openvino, openvino-wsl] for accelerated inference - use the `-wsl` version for WSL2 where applicable

          # Other configurations omitted
        ```


    >  [!NOTE]
    > The immich-machine-learning container does NOT require `runtime=nvidia` or the `NVIDIA_VISIBLE_DEVICES=all` variable.

4. **Start the stack.**

    >  [!NOTE]
    > After configuring machine learning hardware acceleration, no additional settings are required in the WebUI.

## Replacing Machine Learning Models

For detailed information, refer to the official Immich documentation on [Searching](https://immich.app/docs/features/searching).

### CLIP

1. **Choose a model:**

    Since the default `ViT-B-32__openai` model has insufficient compatibility with Chinese, you need to select a multilingual CLIP model.

    The [official documentation](https://immich.app/docs/features/searching) provides accuracy comparison tables for different models across various languages, along with detailed reports on VRAM requirements and inference time. Users can choose based on their needs. (All models can be found on Immich's Hugging Face collections: [CLIP](https://huggingface.co/collections/immich-app/clip-654eaefb077425890874cd07) and [Multilingual CLIP](https://huggingface.co/collections/immich-app/multilingual-clip-654eb08c2382f591eeb8c2a7))

    We can refer to the "Simplified Chinese" table for selection. If you have sufficient VRAM, you can directly choose the best-performing model `nllb-clip-large-siglip__v1`:

    ![Simplified Chinese Performance Comparison Table for Models](https://cdn.rxchi1d.me/inktrace-files/container-platform/immich-deployment/model-cn-perf-compare.png)
    _Simplified Chinese Performance Comparison Table for Models_

2. **Configure the model:**

    In the settings page, go to `Machine Learning Settings` → `Smart Search` → `CLIP Model`, and enter the desired model name.

    >  [!TIP]
    > - No need to manually download models; the immich-machine-learning container will automatically download the corresponding model when Immich needs to invoke it.
    > - After initial configuration, manually run the `Smart Search` job once and check the immich-machine-learning container logs to verify whether the model was downloaded and loaded automatically.

### Facial Recognition Model

For a detailed model list, refer to Immich's Hugging Face collection on [Facial Recognition](https://huggingface.co/collections/immich-app/facial-recognition-654eb881c0e106160e2e9c95).

According to online sources, `antelopev2` currently provides the best results.

Since the official documentation doesn't provide VRAM overhead information, here are my test results for reference:

>  [!NOTE]
> - Test GPU: NVIDIA Tesla P4.
> - Since the environment wasn't specifically configured for idle GPU state, subtract the initial VRAM overhead (approximately 0.416 GiB) from the table values to get closer to the model's actual VRAM usage.
> - The "Storage Overhead" column represents the model file size.

- Facial Recognition (sorted by size in descending order)

    | Name | VRAM Overhead (**GiB**) (subtract 0.416) | Storage Overhead (MB) |
    | --- | --- | --- |
    | antelopev2 | 1.955 | 265 |
    | buffalo_l | 1.680 | 183 |
    | buffalo_m | 1.428 | 170 |
    | buffalo_s | 0.996 | 16 |

## Nginx Proxy Manager Reverse Proxy

To be continued...
