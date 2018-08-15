.PHONY: f-droid-sign f-droid-clean \
build-external-libs use-prebuilt-external-libs \
toolchain openssl boost wownero collect \
clean-external-libs \
f-droid-sign f-droid-clean \
gradle-release gradle-build gradle-sign gradle-clean

all: build-external-libs

build-external-libs: clean-external-libs collect

# faster build for testing f-droid release
use-prebuilt-external-libs:
	script/build-external-libs/use-archive.sh

clean-external-libs:
	script/build-external-libs/clean.sh

toolchain:
	script/build-external-libs/prep-toolchain.sh

openssl: toolchain
	script/build-external-libs/fetch-openssl.sh
	script/build-external-libs/patch-openssl.sh
	script/build-external-libs/build-openssl.sh
	script/build-external-libs/post-build-openssl.sh

boost: toolchain
	script/build-external-libs/fetch-boost.sh
	script/build-external-libs/build-boost.sh

wownero: toolchain openssl boost
	script/build-external-libs/fetch-wownero.sh
	script/build-external-libs/patch-wownero.sh
	script/build-external-libs/build-wownero.sh

collect: wownero
	script/build-external-libs/collect.sh





fdroid_apk_path := vendor/fdroiddata/unsigned
app_id := com.wownero.wownerujo

gradle_apk_path := app/build/outputs/apk/release
gradle_app_name := wownerujo-${gradle_app_version}_universal



f-droid-sign:
	zipalign -v -p 4 \
$(fdroid_apk_path)/$(app_id)_${app_version}.apk \
$(fdroid_apk_path)/$(app_id)_${app_version}-aligned.apk

	apksigner sign --ks ${release_key} \
--out $(fdroid_apk_path)/$(app_id)_${app_version}-release.apk \
$(fdroid_apk_path)/$(app_id)_${app_version}-aligned.apk

f-droid-clean:
	@rm -f $(fdroid_apk_path)/$(app_id)_${app_version}-aligned.apk
	@rm -f $(fdroid_apk_path)/$(app_id)_${app_version}-release.apk

gradle-release: gradle-build gradle-sign

gradle-build:
	./gradlew assembleRelease

gradle-sign: gradle-clean
	zipalign -v -p 4 \
$(gradle_apk_path)/$(gradle_app_name).apk \
$(gradle_apk_path)/$(gradle_app_name)-aligned.apk

	apksigner sign --ks ${release_key} \
--out $(gradle_apk_path)/$(gradle_app_name)-release.apk \
$(gradle_apk_path)/$(gradle_app_name)-aligned.apk

gradle-clean:
	@rm -f $(gradle_apk_path)/$(gradle_app_name)-aligned.apk
	@rm -f $(gradle_apk_path)/$(gradle_app_name)-release.apk


remove-exif:
	exiftool -all= `find app/ -name '*.jp*g' -o -name '*.png'`
