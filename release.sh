
set -e

echo "Compiling to release..."
bash gradlew clean build
rm -rf dist dist.zip
mkdir -p dist/release/main
cp app/build/libs/app-*.jar dist/release/main
cp andropiler dist/release
cd dist
zip -r andropiler.zip release
cd ../
echo "Done!"
