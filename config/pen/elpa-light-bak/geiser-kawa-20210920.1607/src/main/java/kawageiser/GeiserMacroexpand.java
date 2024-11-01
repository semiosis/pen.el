/*
 * Copyright (C) 2020 spellcard199 <spellcard199@protonmail.com>
 *
 * SPDX-License-Identifier: BSD-3-Clause
 */

package kawageiser;

import gnu.kawa.functions.Format;
import gnu.kawa.slib.syntaxutils;
import gnu.mapping.Environment;

public class GeiserMacroexpand {

    public static String expand(Object form) throws Throwable {
        return expand(form, true);
    }

    public static String expand(Object form, boolean all) throws Throwable {
        // `all' is ignored: geiser passes #t or #f depending on whether it needs
        // expand-1 or expand-all, but Kawa's `expand' can only expand the whole tree.
        return expand(form, Environment.user());
    }

    public static String expand(Object form, Environment env) throws Throwable {
        // TODO: How do you invoke kawa procedures with keyword arguments from java?
        //  - ignoring env and using apply1, for now
        //  - an alternative would be to port gnu.kawa.slib.syntaxutils.expand from scheme to java (it's easy)

        //  I keep getting Wrong arguments using syntaxutils.expand.apply2(form, (Object) env)
        //  Same from scheme:
        //  (gnu.kawa.slib.syntaxutils:expand:apply2
        //    (quote (cond ((< 1 3) (display "hi"))))
        //    (interaction-environment))
        //  gnu.mapping.WrongArguments
        //  at gnu.mapping.CallContext.matchError(CallContext.java:150)
        //  at gnu.mapping.CallContext.checkDone(CallContext.java:228)
        //  at gnu.kawa.slib.syntaxutils.expand$check(syntaxutils.scm:67)
        //  at gnu.mapping.CallContext.runUntilValue(CallContext.java:656)
        //  at gnu.mapping.Procedure.apply2(Procedure.java:160)
        //  at kawageiser.GeiserMacroexpand.expand(GeiserMacroexpand.java:35)
        //  at kawageiser.GeiserMacroexpand.apply2(GeiserMacroexpand.java:31)
        //  at gnu.mapping.Procedure2.applyToObject(Procedure2.java:62)
        //  at gnu.mapping.Procedure.applyToConsumerDefault(Procedure.java:75)
        //  at gnu.kawa.functions.ApplyToArgs.applyToConsumerA2A(ApplyToArgs.java:132)
        //  at gnu.mapping.CallContext.runUntilDone(CallContext.java:586)
        //  at gnu.expr.ModuleExp.evalModule2(ModuleExp.java:343)
        //  at gnu.expr.ModuleExp.evalModule(ModuleExp.java:211)
        //  at kawa.Shell.run(Shell.java:289)
        //  at kawa.Shell.run(Shell.java:196)
        //  at kawa.Shell.run(Shell.java:183)
        //  at kawa.TelnetRepl.apply0(TelnetRepl.java:25)
        //  at gnu.mapping.RunnableClosure.run(RunnableClosure.java:75)
        //  at java.base/java.lang.Thread.run(Thread.java:834)
        //
        //  This, instead, works:
        //  (gnu.kawa.slib.syntaxutils:expand
        //    (quote (cond ((< 1 3) (display "hi"))))
        //    env: (interaction-environment))
        Object expanded = syntaxutils.expand.apply1(form);
        // Double formatting so that double quotes around strings are not lost.
        return Format.format(
                "~S",
                Format.format("~S", expanded)).toString();
    }
}
