#!/usr/bin/env ruby

###############
#GmailAlarmDaemon:
#   stop hitting refresh!!  use this
#       
#HEADERFIELD OPTIONS
# SUBJECT
# TO
# FROM
#
#
# USERNAME = gmail username
# PASSWORD = gmail password
# HEADERFIELD = what header field to search on (as listed above)
# FIELDSTRING = what the headerfield should include to test true
# BODYTEXT = any string to seach for in the body of the email 
#           (use "" for wildcard
#DELAY = seconds before updates ( passed to start() )
#EXAMPLE:
#         alarm on any email from sender=anotherEmail@anywhere.com
#
#         alarm = GmailAlarmDaemon.new(
#                   "youremail@gmail.com",
#                   "<yourpassword>",
#                   "FROM",
#                   "anotherEmail@anywhere.com",
#                   "")
#
#         alarm.start(5) { |x| puts "new mail from dj"
#                              puts x #prints email text body}
#
######################

require 'net/imap'

class GmailAlarmDaemon
  def initialize(username, 
                 password, 
                 headerfield,
                 fieldstring,
                 bodytext)

    @new = false
    @username = username
    @password = password
    @headerfield = headerfield
    @fieldstring = fieldstring
    @bodytext = bodytext
    @lastIndex = 0
    @server = Net::IMAP.new("imap.gmail.com",993,true,nil,false)
  end

  def fetchHeaders(t)
    @valid = []
    fetch = @server.fetch(@lastindex..t, 
    "BODY[HEADER.FIELDS (#{@headerfield})]")
    fetch.each do |pull|
      data = pull.attr["BODY[HEADER.FIELDS (#{@headerfield})]"]
      if data.chomp.include?(@fieldstring)
        @valid.push(pull.seqno)
      end
    end
  end

  def testEmail()
    if @valid.length > 0
      fetch = @server.fetch(@valid,'BODY[TEXT]')
      fetch.each do |pull|
        data = pull.attr['BODY[TEXT]']
        if data.include?(@bodytext)
          yield data
        end
      end
    end
  end
      
  def start(delay)
    @server.login(@username,@password)
    @server.select('INBOX')
    @server.add_response_handler() { |resp|
    if resp.kind_of?(Net::IMAP::UntaggedResponse) and resp.name == "EXISTS"
      @new = true
    end }

    i = 0
    while 1
      @server.check 
      if @new
        t =  @server.responses["EXISTS"][-1]
        if i < 1 || t <= @lastindex
          @lastindex = t 
        end
        if t > 0
          fetchHeaders(t) 
          testEmail() { |email| yield email }
          @lastindex = t + 1
        end
      end
      @new = false
      sleep delay
    end
  end
end



