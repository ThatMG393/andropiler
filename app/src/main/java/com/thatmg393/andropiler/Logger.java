package com.thatmg393.andropiler;

public class Logger {
    private boolean verbose = false;
    public int DELAY = 20;

    public Logger(boolean verbose) {
        this.verbose = verbose;
    }

    private class Col {
        public static final String DEF = "\033[0m";
        public static final String BLUE = "\033[0;96m";
        public static final String GREEN = "\033[0;92m";
        public static final String CYAN = "\033[0;94m";
        public static final String YELLOW = "\033[0;93m";
        public static final String RED = "\033[0;91m";
        // Doesn't fit
        // public static final String W_R = "\033[0;37m" + "\033[0;101m";
    }

    public void info(String message) {
        System.out.println(Col.BLUE + "[I] " + message + Col.DEF);
        try { Thread.sleep(DELAY); }
        catch (InterruptedException ie) { }
    }

    public void verbose(String message) {
        if (verbose) System.out.println(Col.CYAN + "[V] " + message + Col.DEF);
        try { Thread.sleep(DELAY); }
        catch (InterruptedException ie) { }
    }

    public void success(String message) {
        /*
        System.out.print("\033[1A\r\033[J");
        try { Thread.sleep(30); }
        catch (InterruptedException ie) { }
        */
        System.out.println(Col.GREEN + "[S] " + message + Col.DEF);
        try { Thread.sleep(DELAY); }
        catch (InterruptedException ie) { }
    }

    public void warn(String message) {
        System.out.println(Col.YELLOW + "[W] " + message + Col.DEF);
        try { Thread.sleep(DELAY); }
        catch (InterruptedException ie) { }
    }

    public void err(String message, boolean exit) {
        System.out.println(Col.RED + "[E] " + message + Col.DEF);
        if (exit) System.exit(1);
        else
            try { Thread.sleep(DELAY); }
            catch (InterruptedException ie) { }
    }
}
