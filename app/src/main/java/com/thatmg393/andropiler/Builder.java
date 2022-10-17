package com.thatmg393.andropiler;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.lang.reflect.Array;
import java.net.URL;
import java.nio.channels.Channels;
import java.nio.channels.ReadableByteChannel;
import java.nio.charset.StandardCharsets;
import java.util.Iterator;
import java.util.Scanner;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.apache.commons.io.FileUtils;
import org.json.JSONException;
import org.json.JSONObject;

public class Builder {
    private Logger LOGGER;
    private String UNRECOVERABLE_DEATH = "Fatal error occurred... Exiting...";

    private String OS_ARCH = System.getProperty("os.arch");
    private String PWD = getPWD();
    private File HOME_DIR = new File(System.getProperty("user.home") + "/.andropiler");
    
    private String MANIFEST_URL = "https://raw.githubusercontent.com/ThatMG393/android-compiler/master/manifest.json";
    private File MANIFEST_FILE = new File(HOME_DIR, "/manifest.json");
    private File AAPT2_BIN = new File(HOME_DIR, "/aapt2-bin/" + OS_ARCH);
    private File AAPT2_FILE = new File(AAPT2_BIN, "/aapt2");

    private boolean USE_GRADLEW = true;

    public Builder() {
        // Dont know what to put.
    }

    public void initialize(Logger MAIN_LOGGER) {
        LOGGER = MAIN_LOGGER;

        // We check for OS
        boolean SUPPORTED = System.getProperty("os.name").toLowerCase().contains("linux");
        if (!SUPPORTED) LOGGER.err("Andropiler is only supported for Linux!", true);
        
        // then the terminal
        try {
            SUPPORTED = System.getenv("LD_PRELOAD").toLowerCase().contains("libtermux-exec");
        } catch (Exception e) {
            SUPPORTED = false;
        }
        if (!SUPPORTED) LOGGER.err("Andropiler is only for Termux! ONLY FOR TERMUX! This is specifically designed for Android.", true);
    }

    public void start(String[] gargs)  { // Might use start(String... args) in the future
        LOGGER.info("Checking for Home directory...");
        if (!HOME_DIR.exists()) {
            LOGGER.info("Home directory does not exists... Creating...");
            if (HOME_DIR.mkdirs()) {
                LOGGER.success("Success!");
            } else {
                LOGGER.err("Failed to create Home directory!", true);
            }
        } else {
            LOGGER.info("Home directory exists!");
        }
        update();

        LOGGER.info("Starting build...");
        LOGGER.verbose("Executing at: " + PWD);
        gradlew(gargs);
     }

    public void update() {
        LOGGER.info("Checking for manifest file...");
        LOGGER.verbose("Looking for manifest at " + MANIFEST_FILE.getAbsolutePath());
        if (MANIFEST_FILE.exists()) {
            LOGGER.warn("Manifest file exists, do you want to redownload it? ([y]es/[n]o): ");
            Scanner sc = new Scanner(System.in);
            String ans = sc.next(); sc.close();
            switch (ans) {
                case "Y":
                case "y":
                case "yes":
                    LOGGER.info("Ok, Redownloading...");
                    LOGGER.info("Deleting manifest...");
                    if (MANIFEST_FILE.delete()) {
                        LOGGER.success("Success!");
                        download(MANIFEST_URL, MANIFEST_FILE);
                    } else {
                        if (!MANIFEST_FILE.exists()) 
                            LOGGER.err("The file is already deleted! Wait wha-", false);
                        download(MANIFEST_URL, MANIFEST_FILE);
                    }
                    break;
                case "N":
                case "n":
                case "no":
                    LOGGER.info("Ok, doing nothing...");
                    break;
                default:
                    LOGGER.info("Ok, doing nothing...");
            }
        } else {
            LOGGER.info("Manifest not found... Downloading...");
            LOGGER.verbose("Fetching manifest using: " + MANIFEST_URL);
            download(MANIFEST_URL, MANIFEST_FILE);
        }

        LOGGER.info("Checking for AAPT2 " + OS_ARCH);
        LOGGER.verbose("Looking for AAPT2 at directory " + AAPT2_BIN.getAbsolutePath());
        AAPT2_BIN.mkdirs(); // Make sure aapt2-bin exists
        if (AAPT2_FILE.exists()) {
            LOGGER.info("Found AAPT2 v" + getAAPT2Ver() + " for " + OS_ARCH);
        } else {
            LOGGER.info("AAPT2 not found! Downloading...");
            String AAPT2_URL = getAAPT2Url();
            LOGGER.verbose("Fetching AAPT2 using: " + AAPT2_URL);
            download(AAPT2_URL, AAPT2_FILE);
        }
    }

    public void gradlew(String[] gargs) {
        if (USE_GRADLEW) {
            File GRADLEW = new File(PWD, "/gradlew");
            if (GRADLEW.exists()) {
                try {
                    String[] args = concat(
                        new String[] {
                            ((GRADLEW.canExecute()) ? "./gradlew" : "bash gradlew"),
                            "-Pandroid.aapt2FromMavenOverride=" + AAPT2_FILE.getAbsolutePath()
                        }, gargs);
                    LOGGER.verbose("Launching Gradle with commands: " + String.join(", ", args));
                    newProcess(args);
                } catch (Exception ioe) {
                    LOGGER.err("Failed to execute 'gradlew'! Caused by: " + ioe.getClass(), false);
                    LOGGER.verbose("Stacktrace:\n" + ioe.toString());
                    LOGGER.err(UNRECOVERABLE_DEATH, true);
                }
            } else {
                LOGGER.info("'gradlew' not found, make sure you are in the right directory! Using Gradle instead.");
                gradle(gargs);
            }
        } else {
            LOGGER.info("'USE_GRADLEW' is false. Using Gradle instead");
            gradle(gargs);
        }
    }

    public void gradle(String[] gargs) {
        String[] args = concat(
            new String[] { 
                "gradle", 
                "-Pandroid.aapt2FromMavenOverride=" + AAPT2_FILE.getAbsolutePath() 
            }, gargs);

        try {
            LOGGER.verbose("Launching Gradle with commands: " + String.join(", ", args));
            newProcess(args);
        } catch (Exception e) {
            LOGGER.err("Failed to execute 'gradle'!", false);
            LOGGER.err("Is Gradle installed? You might want to use 'gradlew'(if available). Caused by: " + e.getClass(), false);
            LOGGER.verbose("Stacktrace:\n" + e.toString());
            LOGGER.err(UNRECOVERABLE_DEATH, true); 
        }
    }

    public void download(String url, File file) {
        LOGGER.info("Downloading file...");
        try (FileOutputStream fos = new FileOutputStream(file)) {
            ReadableByteChannel rbc = Channels.newChannel(new URL(url).openStream());
            fos.getChannel().transferFrom(rbc, 0, Long.MAX_VALUE);
            rbc.close();
        } catch (IOException ioe) {
            LOGGER.err("Failed to download file! Caused by: " + ioe.getClass(), false);
            LOGGER.verbose("Stacktrace:\n" + ioe.toString());
            LOGGER.err(UNRECOVERABLE_DEATH, true);
        }
        LOGGER.success("Success!");
    }

    public String getAAPT2Url() {
        try {
            JSONObject json = new JSONObject(FileUtils.readFileToString(MANIFEST_FILE, StandardCharsets.UTF_8));
            Iterator<String> keys = json.keys();

            while (keys.hasNext()) {
                String key = keys.next();
                if (json.get(key) instanceof JSONObject) {
                    JSONObject json_aapt2 = ((JSONObject)json.get(key)).getJSONObject(OS_ARCH);
                    return json_aapt2.getString("url");
                }
            }
        } 
        catch (JSONException | IOException e) {
            LOGGER.err("Failed to get AAPT2 URL! Caused by: " + e.getClass(), false);
            LOGGER.verbose("Stacktrace:\n" + e.toString());
            LOGGER.err(UNRECOVERABLE_DEATH, true);
        }
        return null;
    }

    public String getAAPT2Ver() {
        try {
            if (!AAPT2_FILE.canExecute()) AAPT2_FILE.setExecutable(true); 
            ProcessBuilder pb = new ProcessBuilder(AAPT2_FILE.getAbsolutePath(), "version");
            pb.redirectErrorStream(true);
            Process p = pb.start();
            InputStream is = p.getInputStream();
            BufferedReader br = new BufferedReader(new InputStreamReader(is));
        
            String o = br.readLine();
            Pattern re = Pattern.compile("([0-9]{1,}\\.)+[0-9]{1,}\\-[A-Z0-9]*", Pattern.MULTILINE);
            Matcher mt = re.matcher(o);
            while (mt.find()) return mt.group(0);
        } catch (IOException | IllegalStateException e) {
            LOGGER.err("Failed to get AAPT2 Version! Caused by: " + e.getClass(), false);
            LOGGER.verbose("Stacktrace:\n" + e.toString());
            LOGGER.err(UNRECOVERABLE_DEATH, true);
        }
        return null;
    }

    private void newProcess(String... commands) {
        try {
            Process p = ((ProcessBuilder)new ProcessBuilder(commands).redirectErrorStream(true)).start();
            InputStream out = p.getInputStream();
            BufferedReader br = new BufferedReader(new InputStreamReader(out));

            String tmp = null;
            while ((tmp= br.readLine()) != null) {
                System.out.println(tmp);
            }
        } catch (IOException ioe) {
            LOGGER.err("Failed to create process with " + ((commands.length > 1) ? "commands" : "command") + ": " + String.join(",", commands), false);
            LOGGER.verbose("Stacktrace:\n" + ioe.toString());
            LOGGER.err(UNRECOVERABLE_DEATH, true);
        }
    }

    private String getPWD() {
        try {
            Process p = ((ProcessBuilder)new ProcessBuilder("pwd").redirectErrorStream(true)).start();
            InputStream out = p.getInputStream();
            BufferedReader br = new BufferedReader(new InputStreamReader(out));

            return br.readLine();
        } catch (IOException ioe) {
            LOGGER.err("Failed to get PWD!, Caused by: " + ioe.getClass(), false);
            LOGGER.verbose("Stacktrace:\n" + ioe.toString());
            LOGGER.err(UNRECOVERABLE_DEATH, true);     
        }
        return null;
    }

    private <T> T concat(T a, T b) {
        if (!a.getClass().isArray() || !b.getClass().isArray()) {
            throw new IllegalArgumentException("You passed a non-array object!-");
        }

        Class<?> resCompType;
        Class<?> aCompType = a.getClass().getComponentType();
        Class<?> bCompType = b.getClass().getComponentType();

        if (aCompType.isAssignableFrom(bCompType)) {
            resCompType = aCompType;
        } else if (bCompType.isAssignableFrom(aCompType)) {
            resCompType = bCompType;
        } else {
            throw new IllegalArgumentException();
        }

        int aLen = Array.getLength(a);
        int bLen = Array.getLength(b);

        @SuppressWarnings("unchecked")
        T result = (T) Array.newInstance(resCompType, aLen + bLen);
        System.arraycopy(a, 0, result, 0, aLen);
        System.arraycopy(b, 0, result, aLen, bLen);        

        return result;
    }
}
