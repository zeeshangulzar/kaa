# Creates contact requests
class ContactRequestsController < ApplicationController
  respond_to :json
  authorize :create, :public

  # Creates a contact request for a user
  #
  # @url [POST] /contact_requests
  #
  # @param [String] first_name First name of the person making the contact request
  # @param [String] last_name Last name of the person making the contact request
  # @param [String] email Email of the person making the contact request
  # @param [String] phone Phone number of the person making the contact request
  # @param [String] comments Description of why contact request is being made
  # @param [String] extra_tags Space delimited string of tags to add to contact request
  # @param [String] organization Name of the organization of person making contact request 
  # @param [Hash] info Information about the session at the moment the contact request was made. Expects browser_name, browser_version, operating_system, user_id, session_data, and/or any extra_info
  #
  # @return [ContactRequest] that was just created
  #
  # @authorize Public
  #
  # [URL] /contact_requests [POST]
  #  [201 CREATED] Successfully created Survey object
  #   # Example response
  #   {
  #    "first_name": 'Ryan',
  #    "last_name": 'Norman',
  #    "organization": 'HES',
  #    "email": 'ryann@hesonline.com',
  #    "phone": '810-240-6882',
  #    "comments": 'This website is broken!!!',
  #    "app_name": "passport",
  #    "created_at": "2014-03-28T12:36:46Z",
  #    "updated_at": "2014-03-28T12:36:46Z"
  #   }
  def create
    params[:contact_request][:survey_type] = Survey::SurveyTypeContactUs
    info = params[:contact_request].delete(:info)
    extra_tags = params[:contact_request].delete(:extra_tags)

    begin
      @contact_request = Survey.create(params[:contact_request])
    rescue
      return HESResponder("Unable to create contact request", "ERROR")
    end

    if @contact_request.errors.empty?
      puts "\n\nCreating Ticket!!!\n\n"
      begin
        ticket = HesContactRequests.ticket.create(*ticket_args(@contact_request, info, extra_tags)) unless HesContactRequests.ticket.nil?
        HesContactRequests.backup_ticket.create(*ticket_args(@contact_request, info, extra_tags)) if ticket.id.nil? && !HesContactRequests.backup_ticket.nil?

        ticket.destroy unless Rails.env.production?
      rescue
        HesContactRequests.backup_ticket.create(*ticket_args(@contact_request, info, extra_tags)) unless HesContactRequests.backup_ticket.nil?
      end
      Resque.enqueue(ContactRequestEmail, params[:contact_request], extra_tags)
    else
      return HESResponder(@contact_request.errors.full_messasges, "ERROR")
    end

    return HESResponder(@contact_request)
  end

  # Just needs to return an empty string since there is no use in having the url since survey is remote
  def survey_url(*args)
    ""
  end

  # Arguments to be passed to all tickets
  # @param [Survey] contact_request survey
  # @param [Hash] info params for extra information about contact request
  # @param [String] tags for the contact request
  # @return [Array<String>] all arguments need to create a ticket
  def ticket_args(contact_request, info, tags)
    _ticket_args = []
    _ticket_args << "#{HesCentral.application_name}: Contact Request"                  # Subject
    _ticket_args << ticket_description(@contact_request, info)                         # Description
    _ticket_args << "#{@contact_request.first_name} #{@contact_request.last_name}"     # Name (first and last)
    _ticket_args << @contact_request.email                                             # Email
    _ticket_args << "#{HesCentral.application_repository_name} gokp #{tags}"           # Tags
    _ticket_args
  end     

  # Description to be added to ticket
  # @param [Survey] contact_request survey
  # @param [Hash] info contact request
  # @return [String] description of contact request
  def ticket_description(contact_request, info)
    <<-EOF
      Name: #{contact_request.first_name + ' '  + contact_request.last_name}
      Email: #{contact_request.email}
      Organization: #{contact_request.organization}
      Phone: #{contact_request.phone}
      Message:

      #{contact_request.comments}
      
      **User Information**
      Browser: #{info[:browser_name]} #{info[:browser_version]}
      OS: #{info[:operating_system]}
      User ID: #{info[:user_id]}
      
      Extra Info: #{info[:extra_info].to_s}
      
      Session Data: #{info[:session_data]}
    EOF
  end
end
