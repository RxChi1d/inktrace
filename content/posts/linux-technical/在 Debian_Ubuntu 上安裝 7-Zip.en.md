---
title: "Installing 7-Zip on Debian/Ubuntu"
slug: "install-7zip-on-debian-ubuntu"
date: 2025-11-23T14:05:00+08:00
lastmod: 2025-11-29T22:26:07+08:00
tags: ["debian-ubuntu", "package"]
categories: ["linux-technical"]
---

A guide to installing the latest version of 7-Zip on Debian/Ubuntu. This resolves bugs present in `p7zip`, such as the inability to compress large files.

<!--more-->

> [!NOTE] Why Manual Installation is Necessary
> p7zip is outdated and has bugs (cannot compress files larger than 5GB).
> The 7zip package in apt repositories is also an older version, so downloading from the official website is required.

1. **Download from the 7-Zip official website**

    Visit the [official download page](https://www.7-zip.org/download.html) to find the latest version package and copy the download link.

    ![Official Download Page](https://cdn.rxchi1d.me/inktrace-files/linux-technical/install-7zip-on-debian-ubuntu/image-01.png)
    _Official Download Page_

    ```bash
    # Navigate to download directory
    cd ~/Downloads

    # Download the file
    wget -O 7zip.tar.xz download-link
    ```

2. **Extract the archive**

    ```bash
    tar -xf 7zip.tar.xz --one-top-level
    ```

3. **Install**

    Copy the `7zz` executable to the `/usr/local/bin/` directory to complete the installation.

    > [!NOTE]
    > - Since `/usr/local/bin` is a system executable directory, `sudo` privileges are required to copy files.
    > - The 7-Zip executable is named `7zz`, which differs from p7zip's `7z`. Therefore, the command after installation is `7zz` rather than `7z`. For example: `7zz a test.7z test.txt`.
    > - If you prefer to use the `7z` command, first remove `p7zip` to avoid conflicts (if installed), then create a symbolic link pointing to `7zz`: `sudo ln -s /usr/local/bin/7zz /usr/local/bin/7z`.


    ```bash
    sudo cp 7zip/7zz /usr/local/bin/7zz
    ```
