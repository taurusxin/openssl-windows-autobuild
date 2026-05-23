# openssl-windows-autobuild

[![Build OpenSSL for Windows](https://img.shields.io/github/actions/workflow/status/taurusxin/openssl-autobuild/build-openssl-windows.yml?branch=main&style=flat-square&label=build)](https://github.com/taurusxin/openssl-autobuild/actions/workflows/build-openssl-windows.yml)
[![GitHub release](https://img.shields.io/github/v/release/taurusxin/openssl-autobuild?include_prereleases&sort=semver&style=flat-square)](https://github.com/taurusxin/openssl-autobuild/releases)
[![Last commit](https://img.shields.io/github/last-commit/taurusxin/openssl-autobuild?style=flat-square)](https://github.com/taurusxin/openssl-autobuild/commits/main)
[![Platform](https://img.shields.io/badge/platform-Windows-0078D4?style=flat-square)](https://github.com/taurusxin/openssl-autobuild)
[![OpenSSL](https://img.shields.io/badge/OpenSSL-4.0.0-721412?style=flat-square)](https://github.com/openssl/openssl)

Windows OpenSSL 自动编译脚本和 GitHub Actions。

1. 本地一键编译。
2. GitHub Actions 每日自动检查 OpenSSL 新版本，有新版本才构建并发布 Release。

## 本地准备

本地编译需要 Windows、Visual Studio 2026 C++ 工具链和 Strawberry Perl。

### 1. 安装 Visual Studio 2026 C++ 工具链

安装 Visual Studio 2026 或 Build Tools for Visual Studio 2026，并勾选：

- `Desktop development with C++`
- MSVC C++ build tools
- Windows 10/11 SDK

脚本会自动用 `vswhere.exe` 查找最新的 Visual Studio C++ 工具链，然后调用 `vcvarsall.bat`，所以不需要手动打开“开发者命令提示符”。如果本机还在使用 VS2022，脚本也可以继续工作；装了 VS2026 时会优先使用 VS2026。

### 2. 安装 Strawberry Perl

可以从官网下载并安装：

```text
https://strawberryperl.com/
```

也可以用 Chocolatey：

```powershell
choco install strawberryperl -y
```

安装完成后重新打开 PowerShell，确认 Perl 可用：

```powershell
perl -v
```

### 3. 一键编译

编译最新版 OpenSSL，生成 x64 动态库：

```powershell
.\scripts\Invoke-OpenSslBuild.ps1
```

指定版本：

```powershell
.\scripts\Invoke-OpenSslBuild.ps1 -Version 4.0.0
```

同时编译 x64 和 x86：

```powershell
.\scripts\Invoke-OpenSslBuild.ps1 -Version 4.0.0 -Targets "x64,x86"
```

只编译静态库：

```powershell
.\scripts\Invoke-OpenSslBuild.ps1 -Version 4.0.0 -Targets x64 -Linkage static
```

同时编译动态库和静态库：

```powershell
.\scripts\Invoke-OpenSslBuild.ps1 -Version 4.0.0 -Targets "x64,x86" -Linkage both
```

只安装到 `dist`，不打包 zip：

```powershell
.\scripts\Invoke-OpenSslBuild.ps1 -Version 4.0.0 -Targets x64 -Linkage shared -NoPackage
```

默认输出目录：

- 源码和压缩包：`build`
- 安装结果：`dist`
- zip 包：`packages`

生成的 zip 文件名类似：

```text
openssl-4.0.0-windows-x64-shared.zip
openssl-4.0.0-windows-x64-static.zip
openssl-4.0.0-windows-x86-shared.zip
openssl-4.0.0-windows-x86-static.zip
```

## 脚本说明

- `scripts/Get-LatestOpenSslVersion.ps1`：从 OpenSSL GitHub Releases 查询最新稳定版本。
- `scripts/Test-OpenSslReleaseExists.ps1`：检查当前仓库是否已有对应 `openssl-x.y.z` tag 或 release。
- `scripts/New-OpenSslBuildMatrix.ps1`：生成 GitHub Actions matrix。
- `scripts/Build-OpenSslWindows.ps1`：编译单个架构、单种链接方式。
- `scripts/Invoke-OpenSslBuild.ps1`：本地一键入口，可一次编译多个架构和动态/静态组合。

## GitHub Actions

工作流文件在：

```text
.github/workflows/build-openssl-windows.yml
```

它会每天自动运行一次，先检查 OpenSSL 官方最新稳定版本。如果当前仓库已经存在匹配的 `openssl-x.y.z` release 或 tag，就跳过构建，并删除这次没有实际构建的每日巡检 run。

云端构建使用 GitHub 官方的 `windows-2025-vs2026` runner，也就是 Windows Server 2025 with Visual Studio 2026 镜像。

你也可以在 GitHub 的 **Actions** 页面手动运行，参数包括：

- `openssl_version`：OpenSSL 版本。留空表示构建最新稳定版。
- `targets`：`x64`、`x86`，或用逗号传入多个，例如 `x64,x86`。
- `linkage`：`shared`、`static` 或 `both`。
- `upload_release`：是否上传到 GitHub Release。

推送 `openssl-*` tag 也会触发构建：

```powershell
git tag openssl-4.0.0
git push origin openssl-4.0.0
```

tag 触发的构建会自动上传 zip 到对应 GitHub Release。
