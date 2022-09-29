
# shopt -s extglob # Much more powerful pattern matching

infoClr="\033[1;34m"
warnClr='\033[1;33m'
errClr="\033[1;31m"
succClr="\033[1;32m"
defClr="\033[0m"
info() { echo -e "${infoClr}I: ${*}${defClr}";:; }
warn() { echo -e "${warnClr}W: ${*}${defClr}";:;}
err() { echo -e "${errClr}E: ${*}${defClr}"; exit 1;:; }
success() { echo -e "${succClr}S: ${*}${defClr}"; exit 0;:; }

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
    fi
}

GEN_FLDR=app/build/libs

BLD_FLDR="dist/build/$FLAVOR"
BLD_MAIN_FLDR="$BLD_FLDR/main"

PKG_FLDR=dist/pkg

# ARG VARS
LIST_BUILDS=FALSE
CLEAR_BUILDS=FALSE
CLEAR_CACHE=FALSE
CLEAR_PKG=FALSE

# ARG VARS END

make() {
    info "Building..."
    bash gradlew clean build

    if [ -f $BLD_FLDR ]; then rm -rf $BLD_FLDR; fi
    if [ ! -f $BLD_MAIN_FLDR ]; then mkdir -p $BLD_MAIN_FLDR; fi
    if [ ! -f $PKG_FLDR ]; then mkdir -p $PKG_FLDR; fi
    
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

    info "Creating ZIP le..."
    zip -r andropiler$JAR_VER.zip $BLD_FLDR

    echo ""
    info "Moving 'andropiler${JAR_VER}' to '${PKG_FLDR}'"
    mv andropiler$JAR_VER.zip $PKG_FLDR
}

start() {
    if [[ "$LIST_BUILDS" = "TRUE" ]]; then
        for builds in $PKG_FLDR/*; do 
            info "$( echo $builds | grep -Po 'andropiler-[0-9].[0-9]*' )"
        done
        success "Done!"
    elif [[ "$CLEAR_GEN" = "TRUE" ]]; then
        info "Clearing '${BLD_FLDR}'"
        rm -rfdv $BLD_FLDR
        success "Done!"
    elif [[ "$CLEAR_BUILD" = "TRUE" ]]; then
        info "Clearing '$PKG_FLDR'"
        rm -rfdv $PKG_FLDR
        success "Done!"
    elif [[ "$CLEAR_ALL" = "TRUE" ]]; then
        info "Clearing '$BLD_FLDR' and '$PKG_FLDR'"
        rm -rfdv $BLD_FLDR $PKG_FLDR
        success "Done!"
    fi

    getFlavor
    set -e
    info "Making a '$FLAVOR' jar"
    make $*
}

usage() {
    lw='\033[1;37m'
    y='\033[0;33m'
    DISP="bash $0"
    if [ -x $0 ]; then DISP="./$0"; fi
    printf "Usage: ${lw}$DISP${defClr} [${y}<OPTIONS>${defClr}] [${y}<GRADLE_ARGS>${defClr}...]
Script to compile andropiler

${lw}Parameters:${defClr}
    [${y}<GRADLE_ARGS>${defClr}...]   Gradle arguments to use. Default: clean, build
    
${lw}Options:${defClr}
    ${y}-h${defClr},  ${y}--help${defClr}          Print this help message.
    ${y}-v${defClr},  ${y}--version${defClr}       Prints the script version then exit
    ${y}-l${defClr},  ${y}--list${defClr}          List builds in '$PKG_FLDR'
    ${y}-cc${defClr}, ${y}--clear-cache${defClr}   Deletes '$BLD_FLDR'
    ${y}-cp${defClr}, ${y}--clear-build${defClr}   Deletes '$PKG_FLDR'
    ${y}-ca${defClr}, ${y}--clear-all${defClr}     Deletes '$BLD_FLDR' and '$PKG_FLDR'
"
    exit 1 # It's beautied! But at what cost.
}

POS_ARGS=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            usage
            ;;
        -v|--version)
            echo "$0 v4 $(uname -m)"
            exit 1
            ;;
        -l|--list)
            LIST_BUILDS=TRUE
            shift # past argument
            ;;
        -cc|--clear-cache)
            CLEAR_GEN=TRUE
            shift # past argument
            ;;
        -cb|--clear-build)
            CLEAR_BUILD=TRUE
            shift # past argument
            ;;
        -ca|--clear-all)
            CLEAR_ALL=TRUE
            shift # past argument
            ;;
        -*|--*)
            echo -e "${errClr}Unknown option -- '$1'${defClr}"
            usage
            ;;
        *)
            POS_ARGS+=("$1")
            ;;
    esac
done
set -- "${POS_ARGS[@]}" # restore positional parameters

start $*
success "Done!"
