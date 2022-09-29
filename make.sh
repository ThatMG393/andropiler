
# shopt -s extglob # Much more powerful pattern matching

infoClr="\033[1;34m"
warnClr='\033[1;33m'
errClr="\033[1;31m"
defClr="\033[0m"
info() { echo -e "${infoClr}I: ${*}${defClr}";:; }
warn() { echo -e "${warnClr}W: ${*}${defClr}";:;}
err() { echo -e "${errClr}E: ${*}${defClr}"; exit 1;:; }

FLAVOR="unknown"

# If no VALID flavor has been found, we will fallback to 'debug'
getFlavor() {
    BLD_GRDL=$( sed -n -e '5,15 p' app/build.gradle )
    FLAVOR="$( echo $BLD_GRDL | grep -Po "(debug)|(release)" )"

    if [ ! -n "${FLAVOR##+([[:space:]])}" ]; then
        warn "\$FLAVOR is empty, falling back to 'debug'"

        replace=$( echo $BLD_GRDL | grep -Po 'def flavor = \"\b(?!\w*[debug][release]\w*)\w*\w*\b\"')
        replacement='def flavor = "debug"'
        sed -i "s|${replace}|${replacement}|" app/build.gradle

        getFlavor # Call getFlavor again
    else
        info "Flavor : $FLAVOR"
    fi
}
getFlavor

set -e # Moving it here since the above line can return a non-zero exit codes

GEN_FLDR=app/build/libs

BLD_FLDR="dist/build/$FLAVOR"
BLD_MAIN_FLDR="$BLD_FLDR/main"

PKG_FLDR=dist/pkg

echo ""
info "Compiling to a $FLAVOR jar..."
info "If you wish to change the application build flavor"
info "Open app/build.gradle then edit 'flavor' near the top."
info "Flavor can only be 'debug' or 'release'"
echo ""
# TODO: Add build flavor selection
# Since we getFlavor() I think we can override it's fallback value!

start() {
    info "Building..."
    bash gradlew clean build

    rm -rf $BLD_FLDR
    mkdir -p $BLD_MAIN_FLDR
    mkdir -p $PKG_FLDR
    
    echo ""
    info "Copying app-*.jar to '${BLD_MAIN_FLDR}'..."
    cp $GEN_FLDR/app-*.jar $BLD_MAIN_FLDR
    
    JAR_FNAME=$( basename -- $GEN_FLDR/app-*.jar )
    JAR_VER=$( echo "$JAR_FNAME" | grep -o "\-[0-9]*.[0-9]*" )

    cp andropiler $BLD_FLDR

    echo ""
    info "Skipping 'zip' install."
    # echo "Installing 'zip'..."
    # apt install zip # Install ZIP (Not supported on Github Actions)

    info "Creating ZIP file..."
    zip -r andropiler$JAR_VER.zip $BLD_FLDR

    echo ""
    info "Moving 'andropiler${JAR_VER}' to '${PKG_FLDR}'"
    mv andropiler$JAR_VER.zip $PKG_FLDR
}

start
info "Done!"
