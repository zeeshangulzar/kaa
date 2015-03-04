module HesZendesk
  require 'rubygems'
  require 'net/http'
  require 'net/https'
  require 'uri'
  require 'json'

  # Class for creating Zendesk tickets
  # @example
  #  HesZendesk::Ticket.create('Test Ticket from SFTR','Description is here','Dustin Steele','dustins@hesonline.com','sftr www')
  class Ticket

    attr_accessor :id
    attr_accessor :subject
    attr_accessor :description
    attr_accessor :requester_name
    attr_accessor :requester_email
    attr_accessor :tags
    
    # Initializes ticket with all attributes
    # @param [String] subject of the ticket
    # @param [String] description of the ticket
    # @param [String] name of person creating the ticket
    # @param [String] email of the person createing the ticket
    # @param [String] tags that are comma separated, usually contains program name
    def initialize(subject, description, name, email, tags)
      @subject = subject
      @description = description
      @requester_name = name
      @requester_email = email
      @tags = tags
    end

    def to_json
      js = { :ticket => {
          :subject => @subject,
          :description => @description,
          :tags => @tags.split(' '),
          :requester => { :name => @requester_name, :email => @requester_email}
        }
      }
      js.to_json
    end
    
    # Converts ticket to xml
    # @return [String] xml format of ticket
    def to_xml
      xml =  "<ticket>\n"
      xml << "\t<subject>#{@subject}</subject>\n"
      xml << "\t<description>#{@description}</description>\n"
      xml << "\t<requester-name>#{@requester_name}</requester-name>\n"
      xml << "\t<requester-email>#{@requester_email}</requester-email>\n"
      xml << "\t<set-tags>#{@tags}</set-tags>\n"
      xml << "</ticket>"
      return xml
    end
    
    # Returns populated ticket with an ID to reference
    # @param [String] subject of the ticket
    # @param [String] description of the ticket
    # @param [String] name of person creating the ticket
    # @param [String] email of the person createing the ticket
    # @param [String] tags that are comma separated, usually contains program name
    # @return [HesZendesk::Ticket] Zendesk ticket with all fields, nil if there was an error
    # def self.create(subject, description, name, email, tags)
    #   t = Ticket.new(subject,description,name,email,tags)

    #   url = URI.parse('http://hes.zendesk.com/api/v2/tickets')
    #   http = Net::HTTP.new(url.host, url.port)
    #   auth = Base64.encode64("#{HesZendesk::AuthUser}:#{HesZendesk::AuthPwd}")
    #   req = Net::HTTP::Post.new(url.path, {
    #     'Accept' => 'application/xml',
    #     'Authorization' => "Basic #{auth}",
    #     'Content-Type' => 'application/xml'
    #   })
    #   res = http.start { |h| h.request(req,t.to_xml) }
    #   case res
    #     when Net::HTTPSuccess
    #       location = res['location'].to_s
    #       puts location
    #       posStart = location.rindex('/') + 1
    #       posEnd = location.index('.xml') + 1
    #       t.id = location[posStart..posEnd].to_i
    #       return t
    #     else
    #       return nil
    #   end
    # end

    # Returns populated ticket with an ID to reference
    def self.create(subject,description,name,email,tags)
      t = Ticket.new(subject,description,name,email,tags)

      url = URI.parse('https://hes.zendesk.com/api/v2/tickets')
      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      req = Net::HTTP::Post.new(url.path, {
        'Accept' => 'application/json',
        'Content-Type' => 'application/json'
      })
      req.basic_auth HesZendesk::AuthUser, HesZendesk::AuthPwd
      res = http.start { |h| h.request(req,t.to_json) }
      case res
        when Net::HTTPSuccess
          js = JSON.parse(res.body) rescue { 'ticket' => { 'id' => 0 } }
          t.id = js['ticket']['id']
          return t
        else
          return nil
      end
    end 

    # Returns populated ticket with an ID to reference
    def destroy
      url = URI.parse('http://hes.zendesk.com/api/v2/tickets/' + self.id)
      http = Net::HTTP.new(url.host, url.port)
      auth = Base64.encode64("#{HesZendesk::AuthUser}:#{HesZendesk::AuthPwd}")
      req = Net::HTTP::Delete.new(url.path, {
        'Accept' => 'application/xml',
        'Authorization' => "Basic #{auth}",
        'Content-Type' => 'application/xml'
      })
      res = http.start { |h| h.request(req) }
      raise res.inspect
      case res
        when Net::HTTPSuccess
          location = res['location'].to_s
          puts location
          return t
        else
          return nil
      end
    end
  end
end