
set -e # Stop on error

echo "Compiling to fat jar..."
echo "If you wish to change the application build flavor"
echo "Open app/build.gradle then edit 'flavor' near the top."
# TODO: Add build flavor selection

bash gradlew clean build
rm -rf dist
mkdir -p dist/release/main
cp app/build/libs/app-*.jar dist/release/main
cp andropiler dist/release
cd dist
zip -r andropiler.zip release
cd ../

echo "Done!"
