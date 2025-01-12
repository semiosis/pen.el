#!/usr/bin/env python
# coding : utf-8

try:
  from xml.etree import ElementTree # for Python 2.5 users
except ImportError:
  from elementtree import ElementTree
import gdata.calendar.service
import gdata.service
import atom.service
import gdata.calendar
import atom
import getopt
import sys
import string
import time
import platform

class CalendarInsert:

 def __init__(self, email, password):
    """Creates a CalendarService and provides ClientLogin auth details to it.
    The email and password are required arguments for ClientLogin.  The 
    CalendarService automatically sets the service to be 'cl', as is 
    appropriate for calendar.  The 'source' defined below is an arbitrary 
    string, but should be used to reference your name or the name of your
    organization, the app name and version, with '-' between each of the three
    values.  The account_type is specified to authenticate either 
    Google Accounts or Google Apps accounts.  See gdata.service or 
    http://code.google.com/apis/accounts/AuthForInstalledApps.html for more
    info on ClientLogin.  NOTE: ClientLogin should only be used for installed 
    applications and not for multi-user web applications."""

    self.cal_client = gdata.calendar.service.CalendarService()
    self.cal_client.email = email
    self.cal_client.password = password
    self.cal_client.source = 'Google-Calendar_InsertEvents-1.0'
    self.cal_client.ProgrammaticLogin()

 def Run(self, title, content, where, all_day,
    start_date=None, end_date=None, start_time=None, end_time=None):
    """Inserts a basic event using either start_time/end_time definitions
    or gd:recurrence RFC2445 icalendar syntax.  Specifying both types of
    dates is not valid.  Note how some members of the CalendarEventEntry
    class use arrays and others do not.  Members which are allowed to occur
    more than once in the calendar or GData "kinds" specifications are stored
    as arrays.  Even for these elements, Google Calendar may limit the number
    stored to 1.  The general motto to use when working with the Calendar data
    API is that functionality not available through the GUI will not be 
    available through the API.  Please see the GData Event "kind" document:
    http://code.google.com/apis/gdata/elements.html#gdEventKind
    for more information"""
    
    event = gdata.calendar.CalendarEventEntry()
    event.title = atom.Title(text=title)
    if  content != 'no_data':
        print content
        event.content = atom.Content(text=content)
    if  where != 'no_data':
        print where
        event.where.append(gdata.calendar.Where(value_string=where))
    if all_day is 'Y':
        event.when.append(gdata.calendar.When(start_time=start_date, 
                                              end_time=end_date))
    else:
        start_time = time.strftime('%Y-%m-%dT%H:%M:%S.000Z', time.strptime(start_time, '%Y-%m-%d-%H-%M'))
        end_time = time.strftime('%Y-%m-%dT%H:%M:%S.000Z', time.strptime(end_time, '%Y-%m-%d-%H-%M'))
        event.when.append(gdata.calendar.When(start_time=start_time, end_time=end_time))
    
    new_event = self.cal_client.InsertEvent(event, 
        '/calendar/feeds/default/private/full')
    
    return new_event

def main():
  """Insert an Event in the Google Calendar"""

  # parse command line options
  try:
    opts, args = getopt.getopt(sys.argv[1:], "", ["user=", "pw=", "t=", "c=", "w=", "ad=", "sd=", "ed=", "st=", "et="])
  except getopt.error, msg:
    print ('ERROR: ')
    sys.exit(2)

  user = ''
  pw = ''
  t = ''
  c = ''
  w = ''
  ad = ''
  sd = ''
  ed = ''
  st = ''
  et = ''

  # Process options
  for o, a in opts:
    if o == "--user":
      user = a
    elif o == "--pw":
      pw = a
    elif o == "--t":
      if platform.system() == 'Windows':
        t = a.decode('cp932')
      else:
        t = a
    elif o == "--c":
      if platform.system() == 'Windows':
        c = a.decode('cp932')
      else:
        c = a
    elif o == "--w":
      if platform.system() == 'Windows':
        w = a.decode('cp932')
      else:
        w = a
    elif o == "--ad":
      ad = a
    elif o == "--sd":
      sd = a
    elif o == "--ed":
      ed = a
    elif o == "--st":
      st = a
    elif o == "--et":
      et = a

  if user == '' or pw == '':
    sys.exit(2)

  aEvent = CalendarInsert(user, pw)
  aEvent.Run(t, c, w, ad, sd, ed, st, et,)

if __name__ == '__main__':
  main()

