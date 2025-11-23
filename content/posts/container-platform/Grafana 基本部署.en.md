---
title: "Grafana Basic Deployment"
slug: "grafana-basic-deployment"
date: 2025-11-23T14:00:00+08:00
tags: ["docker", "grafana"]
categories: ["container-platform"]
---

This guide covers deploying Grafana using Docker, including directory setup, Docker Compose configuration, and initial login steps.

<!--more-->

1. Create the data directory

    ```bash
    mkdir /appdata/grafana

    # Grafana runs as UID 472 by default
    sudo chown 472:472 /appdata/grafana
    ```

2. Configure Docker Compose

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

3. Login and initialization
    1. Navigate to `http://grafana_host:3000/`
    2. Default credentials: username `admin`, password `admin`
