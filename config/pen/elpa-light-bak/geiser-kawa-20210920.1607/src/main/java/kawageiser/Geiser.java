/*
 * Copyright (C) 2020 spellcard199 <spellcard199@protonmail.com>
 *
 * SPDX-License-Identifier: BSD-3-Clause
 */

package kawageiser;

import gnu.expr.Language;
import kawadevutil.complete.find.packagemembers.CompletionFindPackageMemberUtil;

import java.util.HashMap;
import java.util.Map;

public class Geiser implements Runnable {

    @Override
    public void run() {
        // In a previous version, geiser's procedures definitions were like this:
        // lang.defineFunction(new GeiserEval("geiser:eval"));
        // That meant you had to extend Procedure1, Procedure2... which can only have
        // arguments of type Object and must be instanced to be used.
        // Not that symbols are bound to static methods we can have:
        // - parameter names in autodoc: I couldn't find a way to get parameter names for instance methods
        // - parameter types in autodoc: because their types can be other than Object
        // - type warnings: for the same reason of the previous point
        // - less boilerplate for checking argument types

        Language lang = Language.getDefaultLanguage();

        // TODO: find out how to make a new working PrimProcedure from Method
        //  and replace methods paths as string with PrimProcedure. This would avoid Kawa-specific syntax.
        HashMap<String, String> procMap = new java.util.HashMap<>();
        procMap.put("geiser:eval", "kawageiser.GeiserEval:evalStr");
        GeiserEval.evaluator.setPrettyPrintResult(true);
        GeiserEval.evaluator.setPrettyPrintOutput(true);
        procMap.put("geiser:autodoc", "kawageiser.GeiserAutodoc:autodoc");
        procMap.put("geiser:module-completions", "kawageiser.GeiserCompleteModule:completeModule");
        procMap.put("geiser:load-file", "kawageiser.GeiserLoadFile:loadFile");
        procMap.put("geiser:completions", "kawageiser.GeiserCompleteSymbol:getCompletions");
        procMap.put("geiser:no-values", "kawageiser.GeiserNoValues:noValues");
        procMap.put("geiser:kawa-devutil-complete", "kawageiser.kawadevutil.Complete:completeJava");
        procMap.put("geiser:kawa-devutil-complete-expr-tree", "kawageiser.kawadevutil.Complete:getExprTreeFormatted");
        procMap.put("geiser:manual-epub-unzip-to-tmp-dir", "kawageiser.docutil.ManualEpubUnzipToTmpDir:unzipToTmpDir");
        procMap.put("geiser:macroexpand", "kawageiser.GeiserMacroexpand:expand");
        procMap.put("geiser:kawa-devutil-expr-tree-formatted", "kawageiser.kawadevutil.ExprTree:getExprTreeFormatted");

        try {
            if (lang.lookup("geiser:eval") == null) {
                // Tell kawadevutil to build package cache, which takes a couple of seconds,
                // in a separate thread, so user doesn't have to wait later.
                new Thread(() ->
                        CompletionFindPackageMemberUtil
                                .getChildrenNamesOfRoot(true)
                ).start();

                // The reason for this if block is that if someone re-imported this module
                // and the following code was executed, this exception would happen:
                // java.lang.IllegalStateException:
                //   prohibited define/redefine of geiser:eval in #<environment kawa-environment>
                for (Map.Entry<String, String> entry : procMap.entrySet()) {
                    String procName = entry.getKey();
                    String methodPathAsKawaCode = entry.getValue();
                    // Since currently kawaDefineFunction uses lang.eval, lang can only be
                    // Kawa scheme, because it supports the colon notation we used in procMap.
                    kawaDefineFunction(lang, procName, methodPathAsKawaCode);
                }
            }
        } catch (Throwable throwable) {
            throwable.printStackTrace();
        }
    }

    public void
    kawaDefineFunction(Language lang, String procName, String methodPathAsKawaCode)
            throws Throwable {
        // Using lang.eval is a workaround to the fact I don't know
        // how to create a working PrimProcedure using Kawa's java api.
        Object proc = lang.eval(methodPathAsKawaCode);
        if (proc == null) {
            throw new RuntimeException(String.format(
                    "Provided kawa code for `%s' returns null: %s",
                    procName, methodPathAsKawaCode));
        }
        lang.defineFunction(procName, proc);
    }

}
