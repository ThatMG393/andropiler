
# Welcome to make.sh v8!
# 
# Features:
# Full argument support (since 'v6')
# Auto-detect project flavor (since 'v5')
# Pass custom Gradle arguments (since 'v6')

VERSION="v8"

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

setVars() {
    getFlavor
    readonly GEN_FLDR=app/build/libs

    readonly BLD_FLDR="dist/build/$FLAVOR"
    readonly BLD_MAIN_FLDR="$BLD_FLDR/main"

    readonly PKG_FLDR=dist/pkg
}

# ARG VARS
LIST_BUILDS=FALSE
CLEAR_BUILDS=FALSE
CLEAR_CACHE=FALSE
CLEAR_PKG=FALSE
DELIMETER_PRESENT=FALSE
# ARG VARS END

make() {
    info "Building..."
    if [[ ! $# -gt 0 ]]; then
        info "Launching Gradle with arguments: clean, build"
        bash gradlew clean build
    else
        info "Launching Gradle with arguments: $*"
        bash gradlew clean -q
        bash gradlew $*
    fi

    if [ ! -f $GEN_FLDR/app-*.jar ]; then err "Gradle did not generate any jar files"; fi
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
    setVars
    lw="\033[1;37m"
    if [[ "$LIST_BUILDS" = "TRUE" ]]; then
        INDEX=1
        for BUILDS in $PKG_FLDR/*; do
            if [[ "$BUILDS" = "$PKG_FLDR/*" ]]; then
                echo -e "${lw}No ZIP files has been found.${defClr}"
                exit 0
            fi
            echo -e "${INDEX}: ${lw}$( echo $BUILDS | grep -Po 'andropiler-[0-9].[0-9]*' )${defClr}"
            INDEX=$(expr $INDEX + 1)
        done
        exit 0
        # success "Done!"
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
    set -e

    info "Making a '$FLAVOR' jar"
    make $*
}

usage() {
    setVars
    lw='\033[1;37m'
    y='\033[0;33m'
    DISP="bash $0"
    if [ -x $0 ]; then DISP="$0"; fi
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
    if [[ "$DELIMETER_PRESENT" = "TRUE" ]]; then # Anti delimeter duplication
        if [[ "$1" = "--" ]]; then
            POS_ARGS+=("$1")
            shift # Shift past the impostor delimeter
        fi
    fi

    case "$1" in
        -h|--help)
            if [[ "$DELIMETER_PRESENT" = "FALSE" ]]; then 
                usage 
            else
                POS_ARGS+=("$1")
                shift # past argument
            fi
            ;;
        -v|--version)
            if [[ "$DELIMETER_PRESENT" = "FALSE" ]]; then
                echo "$0 $VERSION $(uname -m)"
                exit 1
            else
                POS_ARGS+=("$1")
                shift # past argument
            fi
            ;;
        -l|--list)
            if [[ "$DELIMETER_PRESENT" = "FALSE" ]]; then 
                LIST_BUILDS=TRUE 
            else
                POS_ARGS+=("$1")
            fi
            shift # past argument
            ;;
        -cc|--clear-cache)
            if [[ "$DELIMETER_PRESENT" = "FALSE" ]]; then 
                CLEAR_GEN=TRUE 
            else
                POS_ARGS+=("$1")
            fi
            shift # past argument
            ;;
        -cb|--clear-build)
            if [[ "$DELIMETER_PRESENT" = "FALSE" ]]; then 
                CLEAR_BUILD=TRUE 
            else
                POS_ARGS+=("$1")
            fi
            shift # past argument
            ;;
        -ca|--clear-all)
            if [[ "$DELIMETER_PRESENT" = "FALSE" ]]; then 
                CLEAR_ALL=TRUE 
            else 
                POS_ARGS+=("$1")
            fi
            shift # past argument
            ;;
        --)
            DELIMETER_PRESENT=TRUE
            shift # past delimeter
            ;;
        -*|--*)
            if [[ "$DELIMETER_PRESENT" = "FALSE" ]]; then
                echo -e "${errClr}Unknown option -- '$1'${defClr}"
                usage
            else
                POS_ARGS+=("$1")
                shift
            fi
            ;;
        *)
            POS_ARGS+=("$1")
            shift # past argument
            ;;
    esac
done
set -- "${POS_ARGS[@]}" # restore positional parameters

start $*
success "Done!"
