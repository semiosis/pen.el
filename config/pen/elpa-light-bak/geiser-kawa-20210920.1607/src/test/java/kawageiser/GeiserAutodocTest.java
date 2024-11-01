/*
 * Copyright (C) 2020 spellcard199 <spellcard199@protonmail.com>
 *
 * SPDX-License-Identifier: BSD-3-Clause
 */

package kawageiser;

import gnu.expr.Language;
import gnu.lists.LList;
import gnu.mapping.Environment;
import gnu.mapping.Symbol;
import kawa.lib.ports;
import kawa.standard.Scheme;
import kawadevutil.data.ProcDataGeneric;
import org.testng.annotations.Test;

import static org.testng.Assert.*;

public class GeiserAutodocTest {

    @Test
    public void testApply2() throws Throwable {
        Scheme scheme = new Scheme();
        Environment env = scheme.getEnvironment();
        Symbol displaySym = env.getSymbol("display");
        Symbol cdddrSym = env.getSymbol("cdddr");
        Language saveLang = Language.setSaveCurrent(scheme);
        String autodocDisplay = GeiserAutodoc.autodoc(LList.list1(displaySym), env);
        String autodocCdddr = GeiserAutodoc.autodoc(LList.list1(cdddrSym), env);
        Language.restoreCurrent(saveLang);

        assertTrue(autodocDisplay.startsWith("((\"display\""));
        assertTrue(autodocDisplay.contains(" (\"args\" "));
        assertTrue(autodocDisplay.contains("((\"required\" "));
        assertTrue(autodocDisplay.contains("(\"optional\" "));
        assertTrue(autodocDisplay.contains("(\"module\" "));

        assertTrue(autodocCdddr.startsWith("((\"cdddr\""));
        assertTrue(autodocCdddr.contains(" (\"args\" "));
        assertTrue(autodocCdddr.contains("((\"required\" "));
        assertTrue(!autodocCdddr.contains("(\"optional\" "));
        assertTrue(autodocCdddr.contains("(\"module\" "));
    }

    public static class OperatorArgListDataTest {

        @Test
        public void testToLList() {
            ProcDataGeneric procDataNonGenericList = ProcDataGeneric.makeForProcedure(ports.display);
            GeiserAutodoc.OperatorArgListData operatorArgListData = new GeiserAutodoc.OperatorArgListData(procDataNonGenericList);
            LList llist = operatorArgListData.toLList();
            // System.out.println(llist);
            String required = (String) ((LList) ((LList) llist.get(0)).get(0)).get(0);
            String optional = (String) ((LList) ((LList) llist.get(0)).get(1)).get(0);

            assertEquals(required, "required");
            assertEquals(optional, "optional");

        }
    }

    public static class AutodocDataForSymIdTest {

        @Test
        public void testToLListForProc1() {
            Scheme scheme = new Scheme();
            Environment env = scheme.getEnvironment();
            Symbol display = env.getSymbol("display");
            GeiserAutodoc.AutodocDataForSymId autodocDataForDisplay = new GeiserAutodoc.AutodocDataForSymId(display, env, scheme);;
            assertEquals(display.toString(), autodocDataForDisplay.toLList().get(0));
        }

        @Test
        public void testToLListForProcN() {
            Scheme scheme = new Scheme();
            Environment env = scheme.getEnvironment();
            Symbol strFormatSym = null;
            try {
                strFormatSym = (Symbol) scheme.eval("'java.lang.String:format");
            } catch (Throwable throwable) {
                throwable.printStackTrace();
            }
            GeiserAutodoc.AutodocDataForSymId autodocDataForDisplay = new GeiserAutodoc.AutodocDataForSymId(strFormatSym, env, scheme);;
            LList llist = autodocDataForDisplay.toLList();
            assertEquals("java.lang.String:format", llist.get(0));
        }
    }

    @Test
    public static void
    testLangObjType() {
        Scheme scheme = new Scheme();
        Environment env = scheme.getEnvironment();
        Symbol filepath = env.getSymbol("filepath");
        GeiserAutodoc.AutodocDataForSymId autodocDataForFilepath
                = new GeiserAutodoc.AutodocDataForSymId(filepath, env, scheme);
        String filepathDataAsString = autodocDataForFilepath.toLList().toString();
        assertTrue(filepathDataAsString.startsWith("(filepath"));
        assertTrue(filepathDataAsString.contains("module gnu kawa io FilePath"));

        Symbol list = env.getSymbol("list");
        GeiserAutodoc.AutodocDataForSymId autodocDataForList
                = new GeiserAutodoc.AutodocDataForSymId(list, env, scheme);
        String listDataAsString = autodocDataForList.toLList().toString();
        assertTrue(listDataAsString.startsWith("(list"));
        assertTrue(listDataAsString.contains("module gnu kawa functions MakeList"));
    }
}