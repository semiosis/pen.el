define(SMART_HOST',[smtp.gmail.com]')dnl 
define(RELAY_MAILER_ARGS', TCP $h 587')dnl 
define(ESMTP_MAILER_ARGS', TCP $h 587')dnl 
define(confAUTH_OPTIONS', A p')dnl 
TRUST_AUTH_MECH(EXTERNAL DIGEST-MD5 CRAM-MD5 LOGIN PLAIN')dnl 
define(confAUTH_MECHANISMS', EXTERNAL GSSAPI DIGEST-MD5 CRAM-MD5 LOGIN PLAIN')dnl 
FEATURE(authinfo',`hash /etc/mail/auth/client-info')dnl