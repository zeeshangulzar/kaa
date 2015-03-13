# XmlEmailDelivery

# allows you to simply switch this:
#    Mailer.deliver_some_email(someoption1,someoption2)
# to:
#    mail = Mailer.create_some_email(someoption1,someoption2)
#    XmlEmailDelivery.deliver_one(mail,"on-demand-email")

# also allows:
#    mails = []
#    mails << Mailer.create_some_email(someoption1,someoption2)
#    mails << Mailer.create_some_email(someoption1,someoption2)
#    mails << Mailer.create_some_email(someoption1,someoption2)
#    mails << Mailer.create_some_email(someoption1,someoption2)
#    XmlEmailDelivery.deliver_many(mails,"pile-of-emails")


# tag is whatever you want it to be
# but try to make sure it includes the program abbreviation, promotion, and purpose 
# (e.g. gpw-1-www-daily)

class XmlEmailDelivery
  require 'rexml/document'

  def self.deliver_one(tmail,tag)
    self.deliver_many [tmail],tag
  end
  
  def self.deliver_many(tmails,tag)
    base_path = ''
    if File.exists?('/var/xml')  # production
      base_path = "/var/xml"
    else                         # development
      base_path = "#{RAILS_ROOT}/email"
    end

    emailFile = "#{base_path}/#{tag}.xml"
    emailTempFile = emailFile.gsub('.xml','.temp')

    xmlEmailRoot = REXML::Document.new "<emails></emails>"
    xmlRecipientRoot = REXML::Document.new "<recipients></recipients>"

    tmails.each_with_index do |tmail,idx|
      html_body = tmail.parts.select{|part| part["content-type"].to_s =~ /text\/html/ }.first.body rescue ''
      plain_body = tmail.parts.select{|part| part["content-type"].to_s =~ /text\/plain/ }.first.body rescue ''

      xmlEmail = xmlEmailRoot.root.add_element "email"
      
      xmlEmailId = xmlEmail.add_element "id"
      xmlEmailId.text = "#{tag}-#{Time.now.strftime('%Y%m%d%H%M%S')}-#{idx+1}"

      xmlSendDate = xmlEmail.add_element "send_date"
      xmlSendDate.text = Time.now.strftime('%m/%d/%Y')

      xmlFromAddress = xmlEmail.add_element "from_address"
      xmlFromAddress.text = tmail.from_addrs.first.address

      xmlFromName = xmlEmail.add_element "from_name"
      xmlFromName.text = tmail.from_addrs.first.name

      xmlReplyTo = xmlEmail.add_element "reply_to"
      xmlReplyTo.text = tmail.reply_to.is_a?(Array) ? tmail.reply_to.first.to_s : xmlFromAddress.text

      xmlSubject = xmlEmail.add_element "subject"
      xmlSubject.text = tmail.subject

      xmlHTMLEmail = xmlEmail.add_element "html"
      xmlHTMLEmail.add REXML::CData.new(html_body)

      xmlTextEmail = xmlEmail.add_element "plain"
      xmlTextEmail.add REXML::CData.new(plain_body)
      
      tmail.bcc_addrs.each do |bcc|
        xmlRecipient = xmlRecipientRoot.root.add_element "recipient"
        xmlRecipientEmailId = xmlRecipient.add_element "email_id"
        xmlRecipientEmailId.text = xmlEmail.elements["id"].text
        xmlRecipientEmailAddress = xmlRecipient.add_element "address"
        xmlRecipientEmailAddress.text = bcc.address
        xmlRecipientEmailAddress = xmlRecipient.add_element "encrypted_address"
        xmlRecipientEmailAddress.text = CGI.escape(Base64.encode64(bcc.address).chomp)
      end
    end

    # write it to a temp file, then rename the temp file
    # otherwise the thing that looks for the xml file MIGHT open it while the code below is still writing to it
    File.open(emailTempFile,'w') do |f|
      f.puts "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
      f.puts "<rails_email>\n"
      f.puts xmlEmailRoot.to_s
      f.puts xmlRecipientRoot.to_s
      f.puts "\n</rails_email>"
    end
    File.move(emailTempFile,emailFile)
  end

end




    
       
