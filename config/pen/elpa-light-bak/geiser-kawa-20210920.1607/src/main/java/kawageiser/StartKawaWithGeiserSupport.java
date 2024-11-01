/*
 * Copyright (C) 2020 spellcard199 <spellcard199@protonmail.com>
 *
 * SPDX-License-Identifier: BSD-3-Clause
 */

package kawageiser;

import kawa.standard.Scheme;
import kawadevutil.kawa.KawaTelnetServerTrackingClients;

public class StartKawaWithGeiserSupport {

    public static void main(String[] args) throws Throwable {
        if (args.length == 0) {
            int defaultPort = 37146;
            System.out.println(String.format(
                    "No port specified. Starting kawa server on default port (%d)...",
                    defaultPort));
            startKawaServerWithGeiserSupport(defaultPort);

        } else if (args.length == 1 && args[0].matches("[0-9]+")) {
            int port = Integer.parseInt(args[0]);
            startKawaServerWithGeiserSupport(port);

        } else if (args.length == 1 && args[0].equals("--no-server")) {
            System.out.println("Starting kawa repl in current terminal...");
            startKawaReplWithGeiserSupport();
        } else {
            System.out.println(
                    "You must pass at most 1 argument and it can be only one of:\n"
                            + "- a port number"
                            + "- --no-server"
            );
        }
    }

    public static Scheme
    startKawaReplWithGeiserSupport() {
        String[] interpArgs = new String[]{
                "-e", "(require <kawageiser.Geiser>)",
                "--",
        };
        return runSchemeAsApplication(interpArgs);
    }

    public static Scheme
    runSchemeAsApplication(String[] args) {
        kawa.standard.Scheme scheme = kawa.standard.Scheme.getInstance();
        scheme.runAsApplication(args);
        return scheme;

    }

    public static KawaTelnetServerTrackingClients
    startKawaServerWithGeiserSupport(int port) throws Throwable {
        Scheme scheme = new Scheme();
        scheme.eval("(require <kawageiser.Geiser>)");
        KawaTelnetServerTrackingClients ktstc =
                new KawaTelnetServerTrackingClients(
                        port, scheme, true);
        ktstc.startServer();
        return ktstc;
    }

}
