---
title: "在 Debian/Ubuntu 上 7-Zip 安裝"
date: 2024-06-19 00:00:00 +0800
lastmod: 2025-06-01T01:01:49+08:00
tags: ["debian-ubuntu", "package"]
categories: ["linux-technical"]
slug: "install-7zip-on-debian-ubuntu"
---

在 Debian/Ubuntu 上安裝最新版 7-Zip 教學。可以解決 `p7zip` 存在的一些 bug，如無法壓縮大檔案等問題。

<!--more-->

>  💡 **需要手動安裝 7-Zip 的原因:** 
>  `p7zip` 太舊了，有 bug (超過5GB的大檔案無法壓縮)。
>  apt 中的 7zip 也是舊版，因此需要從官網下載。

1. **從 7-Zip 官網下載**
    
    在 [官網下載頁面](https://www.7-zip.org/download.html) 中查找最新版本的安裝包，並複製下載連結。
    
    ![官網下載頁面](https://cdn.rxchi1d.me/inktrace-files/Linux_Related/2024-06-19-Install_7-Zip_on_Debian_Ubuntu/image-01.png)
    _官網下載頁面_
    
    ```bash
    # 切換至下載目錄
    cd ~/Downloads

	# 下載檔案
    wget -O 7zip.tar.xz download-link
    ```
    
2. **解壓縮**
    
    ```bash
    tar -xf 7zip.tar.xz --one-top-level
    ```
    
3. **安裝**

	將 `7zz` 執行檔複製到 `/usr/local/bin/` 資料夾下即安裝完成。
	
	> 💡 **注意**  
	> - 由於 `/usr/local/bin`  是系統的執行檔目錄，因此需要使用 `sudo` 權限來複製檔案。
	> - 7-Zip 的執行檔名稱是 `7zz`，有別於 p7zip 的 `7z`。因此安裝後的執行命令是 `7zz` 而不是 `7z`。如 `7zz a test.7z test.txt`。
	> - 如果想要使用 `7z` 命令，需要先移除 `p7zip` 來避免衝突 (如果有的話)。隨後建立一個軟連結，指向 `7zz`: `sudo ln -s /usr/local/bin/7zz /usr/local/bin/7z`。


    ```bash   
    sudo cp 7zip/7zz /usr/local/bin/7zz
    ```
