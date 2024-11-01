/*
 * Copyright (C) 2020 spellcard199 <spellcard199@protonmail.com>
 *
 * SPDX-License-Identifier: BSD-3-Clause
 */

package kawageiser.kawadevutil;

import gnu.expr.Language;
import gnu.mapping.Environment;
import kawadevutil.exprtree.ExprWrap;

import java.io.IOException;

public class ExprTree {

    public static ExprWrap
    getExprTree(String codeStr, Language lang, Environment env)
            throws IOException {
        return new ExprWrap(codeStr, lang, env);
    }

    public static ExprWrap
    getExprTree(String codeStr) throws IOException {
        return getExprTree(codeStr, Language.getDefaultLanguage(), Environment.user());
    }

    public static String
    getExprTreeFormatted(String codeStr, Language lang, Environment env)
            throws IOException {
        return getExprTree(codeStr, lang, env).formatElem(true);
    }

    public static String
    getExprTreeFormatted(String codeStr) throws IOException {
        return getExprTree(codeStr).formatElem(true);
    }
}
