header 
{
/*
 * $Header: /cvsroot/jEdit/DAV/DAV/org/apache/webdav/cmd/Client.g,v 1.1.1.1 2004/08/26 18:37:06 avnur Exp $
 * $Revision: 1.1.1.1 $
 * $Date: 2004/08/26 18:37:06 $
 *
 * ====================================================================
 *
 * The Apache Software License, Version 1.1
 *
 * Copyright (c) 1999-2002 The Apache Software Foundation.  All rights
 * reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in
 *    the documentation and/or other materials provided with the
 *    distribution.
 *
 * 3. The end-user documentation included with the redistribution, if
 *    any, must include the following acknowlegement:
 *       "This product includes software developed by the
 *        Apache Software Foundation (http://www.apache.org/)."
 *    Alternately, this acknowlegement may appear in the software itself,
 *    if and wherever such third-party acknowlegements normally appear.
 *
 * 4. The names "The Jakarta Project", "Slide", and "Apache Software
 *    Foundation" must not be used to endorse or promote products derived
 *    from this software without prior written permission. For written
 *    permission, please contact apache@apache.org.
 *
 * 5. Products derived from this software may not be called "Apache"
 *    nor may "Apache" appear in their names without prior written
 *    permission of the Apache Group.
 *
 * THIS SOFTWARE IS PROVIDED ``AS IS'' AND ANY EXPRESSED OR IMPLIED
 * WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 * OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED.  IN NO EVENT SHALL THE APACHE SOFTWARE FOUNDATION OR
 * ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF
 * USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT
 * OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 * ====================================================================
 *
 * This software consists of voluntary contributions made by many
 * individuals on behalf of the Apache Software Foundation.  For more
 * information on the Apache Software Foundation, please see
 * <http://www.apache.org/>.
 *
 * [Additional notices, if required by prior licensing conditions]
 *
 */
package org.apache.webdav.cmd;

import java.io.*;
import java.util.*;
import org.apache.util.QName;
import org.apache.webdav.lib.PropertyName;

}

// --------------------------------------------------- parser class definitions

/**
 * The Slide WebDAV client parser.
 *
 * @version     $Revision: 1.1.1.1 $ $Date: 2004/08/26 18:37:06 $
 * @author      Dirk Verbeeck 
 */
class ClientParser extends Parser;

// ------------------------------------------------------------ options section

options {
    k = 2;
    exportVocab = Slide;            // call this vocabulary "Slide"
    codeGenMakeSwitchThreshold = 2; // for debug or some optimizations
    codeGenBitsetTestThreshold = 3;
    defaultErrorHandler = false;    // abort parsing on error 
    // TODO: use a tree-parser rule
    // buildAST = true;                // build tree construction
    buildAST = false;               // uses CommonAST by default
}

// ------------------------------------------------------------- tokens section

// Java code
{

    // ------------------------------------------------------------- properties

    /**
     * The Slide WebDAV client.
     */
    protected Client client;
    
    // --------------------------------------------------------- helper methods

    /**
     * Set a client.
     *
     * @param client a client
     */
    void setClient(Client client) {
        this.client = client;
    }


    /**
     * Get the text from a token.
     *
     * @param token a token
     * @return the token string
     */
    private String text(Token token) {
        return (token != null) ? token.getText() : null;
    }
    

    /**
     * Get the qualified name from a token.
     *
     * @param token a token
     * @return the qualified name
     */
    private QName qname(Token token) {
        if (token == null) return null;

        String tmp = token.getText();
        if (!tmp.startsWith("<")) {
            return new PropertyName("DAV:", text(token));
        }
        String namespaceURI = tmp.substring(tmp.indexOf('"') + 1,
                tmp.lastIndexOf('"'));
        String localName = tmp.substring(1, tmp.indexOf(' '));
        
        return new QName(namespaceURI, localName);
    }

    
    /**
     * Get the property name from a token.
     *
     * @param token a token
     * @return the property name
     */
    private PropertyName pname(Token token) {
        if (token == null) return null;

        String tmp = token.getText();
        if (!tmp.startsWith("<")) {
            return new PropertyName("DAV:", text(token));
        }

        String namespaceURI = tmp.substring(tmp.indexOf('"') + 1,
                tmp.lastIndexOf('"'));
        String localName = tmp.substring(1, tmp.indexOf(' '));
        
        return new PropertyName(namespaceURI, localName);
    }

    
    /**
     * Print the usage for a given command.
     *
     * @param command a command
     */
    private void printUsage(String command)
        throws RecognitionException, TokenStreamException {

        client.printUsage(command);
        skip(); // skip the rest of the line
    }

}

// --------------------------------------------------------------- parser rules

commands
    :   {
            client.prompt();
        }
        (   command
            {
                client.prompt();
            }
        )+
    ;

command
    :   exit
    |   help
    |   invalid
    |   nothing
    |   spool
    |   run
    |   echo
    |   debug
    |   status
    |   optionsmethod
    |   connect
    |   disconnect
    |   lpwd
    |   lcd
    |   lls
    |   pwc
    |   cd
    |   ls
    |   mkcol
    |   move
    |   copy
    |   delete
    |   get
    |   put
    |   propfind
    |   propfindall
    |   proppatch
    |   lock
    |   unlock
    |   locks
    |   grant
    |   deny
    |   revoke
    |   acl
    |   principalcollectionset
    |   versioncontrol
    |   report
    |   ereport
    |   lreport
    |   mkws
    |   checkin
    |   checkout
    |   uncheckout
    |   update
    ;

help
    :   (   HELP
        |   QUESTION
        )
        EOL
        {
            client.help(null);
        }
    ;
    exception
    catch [RecognitionException ex]
    {
        printUsage("help");
    }
         
status
    :   STATUS
        EOL
        {
            client.status();
        }
    ;
    exception
    catch [RecognitionException ex]
    {
        printUsage("status");
    }

spool
    :   SPOOL
        (   file:STRING
        |   OFF
        )
        EOL
        {
            if (file != null) {
                client.enableSpoolToFile(text(file));
            } else {
                client.disableSpoolToFile();
            }
        }
    ;
    exception
    catch [RecognitionException ex]
    {
        printUsage("spool");
    }

run
    :   RUN
        script:STRING
        EOL
        {
            client.executeScript(text(script));
        }
    ;
    exception catch [RecognitionException ex]
    {
        printUsage("run");
    }

echo
    :   ECHO
        {
            boolean isEnabled;
        }
        (   ON
            {
                isEnabled = true;
            }
        |   OFF
            {
                isEnabled = true;
            }
        )
        EOL
        {
            client.setEchoEnabled(isEnabled);
        }
    ;
    exception catch [RecognitionException ex]
    {
        printUsage("echo");
    }

debug
    :   {
            int level;
        }
        DEBUG
        (   ON
            {
                level = Client.DEBUG_ON;
            }
        |   OFF
            {
                level = Client.DEBUG_OFF;
            }
        )
        EOL
        {
            client.setDebug(level);
        }
    ;
    exception
    catch [RecognitionException ex]
    {
        printUsage("debug");
    }
          
optionsmethod
    :   OPTIONS
        path:STRING
        EOL
        {
            client.options(text(path));
        }
    ;
    exception
    catch [RecognitionException ex]
    {
        printUsage("options");
    }

connect
    :   (   CONNECT
        |   OPEN
        )
        uri:STRING
        EOL
        {
            client.connect(text(uri));
        }
    ;
    exception
    catch [RecognitionException ex]
    {
        printUsage("connect");
    }

disconnect
    :   DISCONNECT
        EOL
        {
            client.disconnect();
        }
    ;
    exception
    catch [RecognitionException ex]
    {
        printUsage("disconnect");
    }

lpwd
    :   LPWD
        EOL
        {
            client.lpwd();
        }
    ;
    exception
    catch [RecognitionException ex]
    {
        printUsage("lpwd");
    }

pwc
    :   (   PWC
        |   PWD
        )
        EOL
        {
            client.pwc();
        }
    ;
    exception
    catch [RecognitionException ex]
    {
        printUsage("pwc");
    }

lcd
    :   LCD
        path:STRING
        EOL
        {
            client.lcd(text(path));
        }
    ;
    exception
    catch [RecognitionException ex]
    {
        printUsage("lcd");
    }

cd
    :   (   CD
        |   CC
        )
        path:STRING
        EOL
        {
            client.cd(text(path));
        }
    ;
    exception
    catch [RecognitionException ex]
    {
        printUsage("cd");
    }

lls
    :   (   LLS
        |   LDIR
        )
        (option:OPTIONSTRING)?
        (path:STRING)?
        EOL
        {
            client.lls(text(option), text(path));
        }
    ;
    exception
    catch [RecognitionException ex]
    {
        printUsage("lls");
    }

ls
    :   (   LS
        |   DIR
        )
        (option:OPTIONSTRING)?
        (path:STRING)?
        EOL
        {
            client.ls(text(option), text(path));
        }
    ;
    exception
    catch [RecognitionException ex]
    {
        printUsage("ls");
    }

mkcol
    :   (   MKCOL
        |   MKDIR
        )
        path:STRING
        EOL
        {
            client.mkcol(text(path));
        }
    ;
    exception
    catch [RecognitionException ex]
    {
        printUsage("mkcol");
    }

move
    :   MOVE
        source:STRING
        destination:STRING
        EOL
        {
            client.move(text(source), text(destination));
        }
    ;
    exception
    catch [RecognitionException ex]
    {
        printUsage("move");
    }

copy
    :   COPY
        source:STRING
        destination:STRING
        EOL
        {
            client.copy(text(source), text(destination));
        }
    ;
    exception
    catch [RecognitionException ex]
    {
        printUsage("copy");
    }

delete
    :   (   DELETE
        |   DEL
        |   RM
        )
        path:STRING
        EOL
        {
            client.delete(text(path));
        }
    ;
    exception
    catch [RecognitionException ex]
    {
        printUsage("delete");
    }

propfind
    :   (   PROPFIND
        |   PROPGET
        )
        path:STRING
        {
            Vector properties = new Vector();
        }
        (   prop:STRING
            {
                properties.add(pname(prop));
            }
        |   nsprop:QNAME
            {
                properties.add(pname(nsprop));
            }
        )+
        EOL
        {
            client.propfind(text(path), properties);
        }
    ;
    exception
    catch [RecognitionException ex]
    {
        printUsage("propfind");
    }

propfindall
    :   (   PROPFINDALL
        |   PROPGETALL
        )
        (path:STRING)?
        EOL
        {
            client.propfindall(text(path));
        }
    ;
    exception
    catch [RecognitionException ex]
    {
        printUsage("propfindall");
    }

proppatch
    :   (   PROPPATCH
        |   PROPSET
        )
        path:STRING
        prop:STRING
        value:STRING
        EOL
        {
            client.proppatch(text(path), text(prop), text(value));
        }
    ;
    exception
    catch [RecognitionException ex]
    {
        printUsage("proppatch");
    }

get
    :   GET
        path:STRING
        (file:STRING)?
        EOL
        {
            client.get(text(path), text(file));
        }
    ;
    exception
    catch [RecognitionException ex]
    {
        printUsage("get");
    }

put
    :   PUT
        file:STRING
        (path:STRING)?
        EOL
        {
            client.put(text(file), text(path));
        }
    ;
    exception
    catch [RecognitionException ex]
    {
        printUsage("put");
    }

lock
    :   LOCK
        (path:STRING)?
        EOL
        {
            client.lock(text(path));
        }
    ;
    exception
    catch [RecognitionException ex]
    {
        printUsage("lock");
    }

unlock
    :   UNLOCK
        (path:STRING)?
        EOL
        {
            client.unlock(text(path));
        }
    ;
    exception
    catch [RecognitionException ex]
    {
        printUsage("unlock");
    }

locks
    :   LOCKS
        (path:STRING)?
        EOL
        {
            client.locks(text(path));
        }
    ;
    exception
    catch [RecognitionException ex]
    {
        printUsage("locks");
    }

grant
    :   GRANT
        (   permission:STRING
        |   nspermisssion:QNAME
        )
        (   ON
        path:STRING)?
        TO
        principal:STRING
        EOL
        {
            if (permission != null)
                client.grant(text(permission), text(path), text(principal));
            else
                client.grant(qname(nspermisssion), text(path), text(principal));
        }
    ;
    exception
    catch [RecognitionException ex]
    {
        client.printUsage("grant");
    }

deny
    :   DENY
        (   permission:STRING
        |   nspermisssion:QNAME)
        (   ON
            path:STRING
        )?
        TO
        principal:STRING
        EOL
        {
            if (permission != null)
                client.deny(text(permission), text(path), text(principal));
            else
                client.deny(qname(nspermisssion), text(path), text(principal));
        }
    ;
    exception
    catch [RecognitionException ex]
    {
        client.printUsage("deny");
    }

revoke
    :   REVOKE
        (   permission:STRING
        |   nspermisssion:QNAME
        )
        (   ON
            path:STRING
        )?
        FROM
        principal:STRING
        EOL
        {
            if (permission != null)
                client.revoke(text(permission), text(path), text(principal));
            else
                client.revoke(qname(nspermisssion), text(path),
                        text(principal));
            }
    ;
    exception
    catch [RecognitionException ex]
    {
        client.printUsage("revoke");
    }

acl
    :   ACL
        (path:STRING)?
        EOL
        {
            client.acl(text(path));
        }
    ;
    exception
    catch [RecognitionException ex]
    {
        printUsage("acl");
    }

principalcollectionset
    :   PRINCIPALCOLLECTIONSET
        (path:STRING)?
        EOL
        {
            client.principalcollectionset(text(path));
        }
    ;
    exception
    catch [RecognitionException ex]
    {
        printUsage("principalcollectionset");
    }

versioncontrol
    :   VERSIONCONTROL
        (target:STRING)?
        path:STRING
        EOL
        {
            if (target == null)
                client.versioncontrol(text(path));
            else
                client.versioncontrol(text(target), text(path));
        }
    ;
    exception
    catch [RecognitionException ex]
    {
        printUsage("versioncontrol");
    }


update
    :   UPDATE
        path:STRING
        target:STRING
        EOL
        {
            client.update(text(path), text(target));
        }
    ;
    exception
    catch [RecognitionException ex]
    {
        printUsage("update <path> <historyURL>");
    }




checkin
    :   CHECKIN
        path:STRING
        EOL
        {
            client.checkin(text(path));
        }
    ;
    exception
    catch [RecognitionException ex]
    {
        printUsage("checkin");
    }

checkout
    :   CHECKOUT
        path:STRING
        EOL
        {
            client.checkout(text(path));
        }
    ;
    exception
    catch [RecognitionException ex]
    {
        printUsage("checkout");
    }

uncheckout
    :   UNCHECKOUT
        path:STRING
        EOL
        {
            client.uncheckout(text(path));
        }
    ;
    exception
    catch [RecognitionException ex]
    {
        printUsage("uncheckout");
    }

report
    :   REPORT
        path:STRING
        {
            Vector properties = new Vector();
        }
        (   prop:STRING
            {
                properties.add(pname(prop));
            }
        |   nsprop:QNAME
            {
                properties.add(pname(nsprop)); }
        )?
        EOL
        {
            client.report(text(path), properties);
        }
    ;
    exception
    catch [RecognitionException ex]
    {
        printUsage("report");
    }

ereport
    :   EREPORT
        path:STRING
        (filename:STRING)?
        EOL
        {
            client.ereport(text(path), text(filename));
        }
    ;
    exception
    catch [RecognitionException ex]
    {
        printUsage("ereport");
    }

lreport
    :   LREPORT
        path:STRING
        {
            Vector properties = new Vector();
        }
        (   prop:STRING
            {
                properties.add(pname(prop));
            }
        |   nsprop:QNAME
            {
                properties.add(pname(nsprop));
            }
        )+
        ON
        {
            Vector historyUris = new Vector();
        }
        (   uri:STRING
            {
                historyUris.add(text(uri));
            }
        )+
        EOL
        {
            client.lreport(text(path), properties, historyUris);
        } 
    ;
    exception
    catch [RecognitionException ex]
    {
        printUsage("lreport");
    }

mkws
    :   MKWS
        path:STRING
        EOL
        {
            client.mkws(text(path));
        }
    ;
    exception
    catch [RecognitionException ex]
    {
        printUsage("mkws");
    }

exit
    :   (   EXIT
        |   QUIT
        |   BYE
        )
        EOL
        {
            throw new TokenStreamException("exit");
        }
    ;

invalid
    :   cmd:STRING (STRING)* EOL
        {
            client.printInvalidCommand(text(cmd));
        }
    ;

nothing
    :   EOL
    ;

skip
    :   (   STRING
        |   all_tokens
        )*
        EOL
        { /* skip all */ }
    ;

all_tokens
    :   EXIT
    |   QUIT
    |   BYE
    |   HELP
    |   QUESTION
    |   RUN
    |   SPOOL
    |   STATUS
    |   ECHO
    |   ON
    |   OFF
    |   SET
    |   DEBUG
    |   OPTIONS
    |   OPEN
    |   CONNECT
    |   CLOSE
    |   DISCONNECT
    |   LPWD
    |   LCD
    |   LLS
    |   LDIR
    |   PWC
    |   PWD
    |   CC
    |   CD
    |   LS
    |   DIR
    |   GET
    |   PUT
    |   MKCOL
    |   MKDIR
    |   DELETE
    |   DEL
    |   RM
    |   COPY
    |   CP
    |   MOVE
    |   MV
    |   LOCK
    |   UNLOCK
    |   LOCKS
    |   PROPGET
    |   PROPFIND
    |   PROPGETALL
    |   PROPFINDALL
    |   PROPPUT
    |   PROPPATCH
    |   ACL
    |   PRINCIPALCOL
    |   GRANT
    |   DENY
    |   REVOKE
    |   TO
    |   FROM
    |   PRINCIPALCOLLECTIONSET
    |   VERSIONCONTROL
    |   REPORT
    |   EREPORT
    |   LREPORT
    |   MKWS
    |   CHECKIN
    |   CHECKOUT
    |   UNCHECKOUT
    |   UPDATE
    ;

// ----------------------------------------- lexical analyzer class definitions

/**
 * The Slide WebDAV client scanner.
 *
 * @version     $Revision: 1.1.1.1 $ $Date: 2004/08/26 18:37:06 $
 * @author      Dirk Verbeeck 
 */
class ClientLexer extends Lexer;

// ------------------------------------------------------------ options section

options {
    k = 2;
    caseSensitiveLiterals = false;
    charVocabulary = '\u0003'..'\uFFFF';
}

// ------------------------------------------------------------- tokens section

tokens {
    EXIT                    = "exit";
    QUIT                    = "quit";
    BYE                     = "bye";
    HELP                    = "help";
    STATUS                  = "status";
    RUN                     = "run";
    SPOOL                   = "spool";
    ECHO                    = "echo";
    ON                      = "on";
    OFF                     = "off";
    SET                     = "set";
    DEBUG                   = "debug";
                            
    OPTIONS                 = "options";
    OPEN                    = "open";
    CONNECT                 = "connect";
    CLOSE                   = "close";
    DISCONNECT              = "disconnect";
    LPWD                    = "lpwd";
    LCD                     = "lcd";
    LLS                     = "lls";
    LDIR                    = "ldir";
    PWC                     = "pwc";
    PWD                     = "pwd";
    CC                      = "cc";
    CD                      = "cd";
    LS                      = "ls";
    DIR                     = "dir";
    GET                     = "get";
    PUT                     = "put";
    MKCOL                   = "mkcol";
    MKDIR                   = "mkdir";
    DELETE                  = "delete";
    DEL                     = "del";
    RM                      = "rm";
    COPY                    = "copy";
    CP                      = "cp";
    MOVE                    = "move";
    MV                      = "mv";
    LOCK                    = "lock";
    UNLOCK                  = "unlock";
    LOCKS                   = "locks";
    PROPGET                 = "propget";
    PROPFIND                = "propfind";
    PROPGETALL              = "propgetall";
    PROPFINDALL             = "propfindall";
    PROPPUT                 = "propput";
    PROPPATCH               = "proppatch";
    ACL                     = "acl";
    PRINCIPALCOL            = "principalcol";
    GRANT                   = "grant";
    DENY                    = "deny";
    REVOKE                  = "revoke";
    TO                      = "to";
    FROM                    = "from";
    PRINCIPALCOLLECTIONSET  = "principalcollectionset";
    VERSIONCONTROL          = "versioncontrol";
    REPORT                  = "report";
    EREPORT                 = "ereport";
    LREPORT                 = "lreport";
    MKWS                    = "mkws";
    CHECKIN                 = "checkin";
    CHECKOUT                = "checkout";
    UNCHECKOUT              = "uncheckout";
    UPDATE                  = "update";
}

// ---------------------------------------------------------------- lexer rules

WS
    :   (   ' '
        |   '\t'
        )
        {
            _ttype = Token.SKIP;
        }
    ;

EOL     // the end of line
    :   "\r\n"    // DOS
    |   '\r'      // MAC
    |   '\n'      // UN*X
    ;

OPTIONSTRING
    : '-' (CHARS)+
    ;

// TODO: make the flexible string like STRING:
// '"' (~('"'|'\n'|'\r'))* '"' | (~(' '|'\n'|'\r'))+
STRING
    :   CHARS (CHARS | '-')+
    |   '"'!
        (   CHARS
        |   ' '
        |   '-'
        )+
        '"'!
    ;

protected        
CHARS
    :   'a'..'z'
    |   'A'..'Z'
    |   '0'..'9'
    |   '.'
    |   ':'
    |   '/'
    ;

QNAME
    :   '<' STRING " xmlns=\"" STRING "\">"
    ;

protected
ALPHANUM
    :   ALPHA
    |   DIGIT
    ;

protected
ALPHA
    :   LOWALPHA
    |   UPALPHA
    ;

protected
LOWALPHA
    :   'a'..'z'
    ;

protected
UPALPHA
    :   'A'..'Z'
    ;

protected
DIGIT
    :   '0'..'9'
    ;

QUESTION
    :   '?'
    ;

