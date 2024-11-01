/*
 * Copyright (C) 2020 spellcard199 <spellcard199@protonmail.com>
 *
 * SPDX-License-Identifier: BSD-3-Clause
 */

package kawageiser;

import kawa.standard.Scheme;
import org.testng.annotations.Test;

import static org.testng.Assert.assertEquals;

public class GeiserTest {
    @Test
    public static void testEval() throws Throwable {
        Scheme scheme = new Scheme();
        scheme.eval("(require <kawageiser.Geiser>)");
        String ret = (String) scheme.eval(
                "(geiser:eval (interaction-environment) \"(+ 1 1)\")");
        assertEquals(ret ,"((result \"2\") (output . \"\"))");
    }
}
