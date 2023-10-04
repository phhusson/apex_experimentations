#!/bin/bash

rom_fp="$(date +%y%m%d)"
originFolder="$(dirname "$(readlink -f -- "$0")")"
mkdir -p release/$rom_fp/
set -e

if [ -z "$USER" ];then
	export USER="$(id -un)"
fi
export LC_ALL=C

manifest_url="https://android.googlesource.com/platform/manifest"
branch="$1"
module="$2"

repo init -u "$manifest_url" -b $branch --depth=1
repo sync -c -j 1 --force-sync || repo sync -c -j1 --force-sync

. build/envsetup.sh

mkdir -p release

repo manifest -r > release/$rom_fp/manifest.xml
if [ "$module" = art ];then
    pkg=com.android.art
    bash art/build/build-art-module.sh
    for arch in x86 x86_64 arm arm64;do
        for variant in "" .debug;do
            cp out/dist/$arch/"$pkg""$variant".apex release/"$pkg""$variant"-"$arch".apex
        done
    done
fi

