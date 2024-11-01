/*
 * Copyright (C) 2020 spellcard199 <spellcard199@protonmail.com>
 *
 * SPDX-License-Identifier: BSD-3-Clause
 */

package kawageiser;

import gnu.kawa.functions.Format;
import gnu.lists.IString;
import gnu.lists.LList;
import gnu.mapping.Environment;
import gnu.mapping.Symbol;

import java.util.ArrayList;

public class GeiserCompleteSymbol {

    public static LList getCompletions(IString prefix) {
        return getCompletions(prefix, Environment.user());
    }

    public static LList getCompletions(IString prefix, Environment env) {
        ArrayList<String> resultArrList = new ArrayList<>();
        env.enumerateAllLocations().forEachRemaining(
                loc -> {
                    Symbol sym = loc.getKeySymbol();
                    String symName = sym.getName();
                    if (symName.contains(prefix)) {
                        // Emacs' completion-at-point works fine with a list of symbols,
                        // but completion through company-mode works only if we display a list
                        // of strings, each delimited by double-quotes.
                        resultArrList.add(Format.formatToString(0, "~S", symName));
                    }
                }
        );
        return LList.makeList(resultArrList);
    }
}
