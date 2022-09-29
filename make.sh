
set -e # Stop on error

GEN_FLDR=app/build/libs

BLD_FLDR=dist/build
BLD_MAIN_FLDR="$BLD_FLDR/main"

PKG_FLDR=dist/pkg

echo ""
echo "Compiling to fat jar..."
echo "If you wish to change the application build flavor"
echo "Open app/build.gradle then edit 'flavor' near the top."
echo ""
# TODO: Add build flavor selection

start() {
    echo "Building..."
    bash gradlew clean build

    rm -rf $BLD_FLDR
    mkdir -p $BLD_MAIN_FLDR
    mkdir -p $PKG_FLDR
    
    echo ""
    echo "Copying app-*.jar to $BLD_MAIN_FLDR..."
    cp $GEN_FLDR/app-*.jar $BLD_MAIN_FLDR
    
    JAR_FNAME=$( basename -- $GEN_FLDR/app-*.jar )
    JAR_VER=$( echo "$JAR_FNAME" | grep -o "\-[0-9]*.[0-9]*" )

    cp andropiler $BLD_FLDR

    echo ""
    echo "Installing 'zip'..."
    apt install zip # Install ZIP

    cd $BLD_FLDR
    echo ""
    echo "Creating ZIP file..."
    zip -r andropiler$JAR_VER.zip ../build
    mv andropiler$JAR_VER.zip ../pkg
    cd ../../
}

start
echo "Done!"
