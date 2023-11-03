#!/bin/bash

originFolder="$(dirname "$(readlink -f -- "$0")")"
set -e

if [ -z "$USER" ];then
	export USER="$(id -un)"
fi
export LC_ALL=C

manifest_url="https://android.googlesource.com/platform/manifest"
branch="$1"
module="$2"

git clone $manifest_url manifests -b $branch
(cd manifests
cat default.xml |uniq > proper.xml
xmlstarlet ed -L -u '//remote[@name="aosp"]/@fetch' -v https://android.googlesource.com/ proper.xml
git add proper.xml
git commit -m 'include fixed manifest'
)

repo init -u $PWD/manifests/ -b $branch -m proper.xml --depth=1
repo sync -c -j 1 --force-sync || repo sync -c -j1 --force-sync

. build/envsetup.sh

mkdir -p release

repo manifest -r > release/manifest.xml
if [ "$module" = art ];then
    pkg=com.android.art
    export SOONG_ALLOW_MISSING_DEPENDENCIES=true BUILD_BROKEN_DISABLE_BAZEL=true # Not said by me but by the doc!
    for arch in x86 x86_64 arm arm64;do
        for variant in "" .debug;do
            banchan com.android.art"$variant" "$arch"
            m apps_only dist
            cp out/dist/com.android.art"$variant".apex release/"$pkg""$variant"-"$arch".apex
        done
    done
fi

