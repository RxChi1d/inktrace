---
title: "Grafana 基本部署"
slug: "grafana-basic-deployment"
date: 2025-04-26T00:00:00+08:00
lastmod: 2025-06-01T01:01:49+08:00
tags: ["docker", "grafana"]
categories: ["container-platform"]
---

本文介紹如何使用 Docker 部署 Grafana，包含創建資料夾、設定 docker compose 以及登入初始化步驟。

<!--more-->

1. 創建資料夾
    
    ```bash
    mkdir /appdata/grafana
    
    # grafana 預設之 uid 為 472
    sudo chown 472:472 /appdata/grafana
    ```
    
2. 設定 docker compose configuration
    
    ```yaml
    services:
      grafana:
        image: grafana/grafana:latest # keep this fix version of Grafana
        container_name: grafana
        ports:
          - "3000:3000"
        volumes:
          - /appdata/grafana:/var/lib/grafana
        environment:
          - GF_PATHS_PROVISIONING=/etc/grafana/provisioning
          - GF_AUTH_ANONYMOUS_ENABLED=false # disable anonymous login on Grafana
        restart: 'unless-stopped'
    
    ```
    
3. 登入與初始化
    1. 連接 `http://grafana_host:3000/`
    2. 預設帳號：`admin` ；預設密碼：`admin`
