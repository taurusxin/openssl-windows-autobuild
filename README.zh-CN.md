# openssl-windows-autobuild

[![Build OpenSSL for Windows](https://img.shields.io/github/actions/workflow/status/taurusxin/openssl-windows-autobuild/build-openssl-windows.yml?branch=main&style=flat-square&label=build)](https://github.com/taurusxin/openssl-windows-autobuild/actions/workflows/build-openssl-windows.yml)
[![GitHub release](https://img.shields.io/github/v/release/taurusxin/openssl-windows-autobuild?include_prereleases&sort=semver&style=flat-square)](https://github.com/taurusxin/openssl-windows-autobuild/releases)
[![Last commit](https://img.shields.io/github/last-commit/taurusxin/openssl-windows-autobuild?style=flat-square)](https://github.com/taurusxin/openssl-windows-autobuild/commits/main)
[![Platform](https://img.shields.io/badge/platform-Windows-0078D4?style=flat-square)](https://github.com/taurusxin/openssl-windows-autobuild)
[![OpenSSL](https://img.shields.io/badge/OpenSSL-4.0.0-721412?style=flat-square)](https://github.com/openssl/openssl)

[English](README.md) | 中文

使用本地 PowerShell 脚本和 GitHub Actions 自动编译 OpenSSL Windows 版本。

1. 本地一条命令编译 OpenSSL。
2. GitHub Actions 每日检查 OpenSSL 官方最新稳定版。
3. 当前仓库不存在匹配 release 或 tag 时才构建。
4. 将 x64/x86 动态库和静态库 ZIP 包发布到 GitHub Releases。

## 本地准备

本地编译需要 Windows、Visual Studio C++ 工具链和 Strawberry Perl。

### 1. 安装 Visual Studio C++ 生成工具

安装 Visual Studio 2026 或 Build Tools for Visual Studio 2026，并勾选：

- `Desktop development with C++`
- MSVC C++ build tools
- Windows 10/11 SDK

脚本会自动用 `vswhere.exe` 查找最新的 Visual Studio C++ 工具链，然后调用 `vcvarsall.bat`，所以不需要手动打开“开发者命令提示符”。

如果本机还在使用 Visual Studio 2022，脚本也可以继续工作。安装 Visual Studio 2026 后会自动优先使用 Visual Studio 2026。

### 2. 安装 Strawberry Perl

可以从官网下载并安装 Strawberry Perl：

```text
https://strawberryperl.com/
```

也可以用 Chocolatey 安装：

```powershell
choco install strawberryperl -y
```

安装完成后重新打开 PowerShell，确认 Perl 可用：

```powershell
perl -v
```

### 3. 编译 OpenSSL

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

只安装到 `dist`，不打包 ZIP：

```powershell
.\scripts\Invoke-OpenSslBuild.ps1 -Version 4.0.0 -Targets x64 -Linkage shared -NoPackage
```

默认输出目录：

- 源码压缩包和解压后的源码：`build`
- OpenSSL 安装结果：`dist`
- ZIP 包：`packages`

生成的包名类似：

```text
openssl-4.0.0-windows-x64-shared.zip
openssl-4.0.0-windows-x64-static.zip
openssl-4.0.0-windows-x86-shared.zip
openssl-4.0.0-windows-x86-static.zip
```

## 脚本说明

- `scripts/Get-LatestOpenSslVersion.ps1`：从 GitHub Releases 查询 OpenSSL 最新稳定版本。
- `scripts/Test-OpenSslReleaseExists.ps1`：检查当前仓库是否已有对应 `openssl-x.y.z` release 或 tag。
- `scripts/New-OpenSslBuildMatrix.ps1`：生成 GitHub Actions 构建矩阵。
- `scripts/Build-OpenSslWindows.ps1`：编译单个架构、单种链接方式。
- `scripts/Invoke-OpenSslBuild.ps1`：本地一键入口，可一次编译多个架构和链接方式。

## GitHub Actions

工作流文件在：

```text
.github/workflows/build-openssl-windows.yml
```

定时工作流每周运行一次，会先检查 OpenSSL 官方最新稳定版。如果当前仓库已经存在匹配的 `openssl-x.y.z` release 或 tag，就跳过构建。

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

tag 触发的构建会自动上传 ZIP 包到对应的 GitHub Release。
