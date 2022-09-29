package com.thatmg393.andropiler;

import java.util.concurrent.ThreadLocalRandom;

import picocli.CommandLine;
import picocli.CommandLine.Command;
import picocli.CommandLine.Option;
import picocli.CommandLine.ParameterException;
import picocli.CommandLine.Parameters;
import picocli.CommandLine.ParseResult;

@Command(name = "./" + BuildConfig.APP_NAME,
    description = "Compile Android Projects on ANDROID!",
    version = "\n" // Based on 'gradle --version' output
    + "------------------------------------------------------------\n"
    + BuildConfig.APP_NAME + " v" + BuildConfig.APP_VERSION_DISPLAY + "\n"
    + "------------------------------------------------------------\n"
    + "\n"
    + "Compiled On: " + BuildConfig.APP_BUILD_TIME_FORMATTED + "\n"
    + "Compiled By: " + BuildConfig.APP_BUILD_VENDOR + "\n"
    + "Built On: " + BuildConfig.APP_BUILD_PLATFORM + "\n"
    + "\n"
    + "Build Flavor: " + BuildConfig.APP_BUILD_FLAVOR + "\n"
    + "Version: " + BuildConfig.APP_VERSION_FULL + "\n"
    + "\n"
    + "Git Commit Hash: " + BuildConfig.APP_BUILD_COMMIT_HASH + "\n"
    + "Git Commit Tag: " + BuildConfig.APP_BUILD_COMMIT_TAG + "\n"
    + "Git Commit Count: " + BuildConfig.APP_BUILD_COMMIT_COUNT + "\n",
    mixinStandardHelpOptions = true)
public class App {
    private Logger LOGGER;
    private Builder BUILDER;
    public void newBuilder() {
        BUILDER = new Builder();
    }

    @Option(names = { "-vb", "--verbose" }, description = "Makes console logging more verbose.")
    private boolean verbose;

    @Parameters(index = "0..*", 
        description = "Gradle arguments to use. Default: ${DEFAULT-VALUE}", 
        defaultValue = "assembleDebug")
    private String[] gargs; 
    // Gradle options might be a huge problem. 
    // Might be solved by putting '--' before putting Gradle options

    public static void main(String... args) {
        App I = new App();
        Logger MAIN_LOGGER = new Logger(I.verbose);
        I.LOGGER = MAIN_LOGGER;

        try {
            ParseResult result = new CommandLine(I).parseArgs(args);
            if (!CommandLine.printHelpIfRequested(result)) {
                int range = ThreadLocalRandom.current().nextInt(15, 31); // x + 1
                for (int prog = 0; prog < range + 1; prog++) {
                    System.out.print("\033[1A\r\033[J");
                    System.out.println("Loading... (" + prog + "/" + range + ")");

                    try { Thread.sleep(ThreadLocalRandom.current().nextInt(20, 130)); }
                    catch (InterruptedException ie) { System.out.println("OOOH!"); }
                }
                I.start(I);
            }
        } catch (ParameterException pe) {
            System.out.println(pe.getMessage());
            pe.getCommandLine().usage(System.out);
        }
    }

    private void start(App I) {
        System.out.print("\033[1A\r\033[J"); // Cursor move up by 1, Go to beginning of line, Delete until end of line
        I.LOGGER.info("Welcome to andropiler v" + BuildConfig.APP_VERSION_DISPLAY + "!"); // Greetings
        I.LOGGER.info("Starting...");

        try { Thread.sleep(1200); }
        catch (InterruptedException ie) { }

        I.LOGGER.success("Done!");
        I.newBuilder();
        I.BUILDER.initialize(I.LOGGER);
        I.BUILDER.start(gargs);
    }
}
