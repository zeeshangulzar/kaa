# Controller for handling all organization related requests
class OrganizationsController < ApplicationController
  respond_to :json

  authorize :show, :public

  get_parent :organization, :only => [:index, :create], :ignore_missing => [:index, :create]

  # Get all organizations for a reseller
  #
  # @url GET /resellers/1/organizations
  # @url GET /organizations
  # @authorize Master
  # @param [Integer] reseller_id The id of the reseller with organizations
  # @return [Array<Organization>] Array of organizations
  def index
    organizations = params[:reseller_id] ? Reseller.find(params[:reseller_id]).organizations : Organization.all
    return HESResponder(organizations)
  end

  # Get a organization
  #
  # @url [GET] /organizations/1
  # @authorize Public Need to grab organization publically to get password requirements for registration
  # @param [Integer] id The of the organization
  # @return [Organization] Organization that matches the id
  #
  # [URL] /organizations/:id [GET]
  #  [200 OK] Successfully retrieved Organization
  #   # Example response
  #   {
  #    "id": 1,
  #    "reseller_id": 1,
  #    "name": "HES",
  #    "contact_name": "Jane Doe",
  #    "contact_email": "janed@hesonline.com",
  #    "password_ignores_case": false,
  #    "password_min_length", 8,
  #    "password_max_length", 12,
  #    "password_min_letters": 0,
  #    "password_min_number": 0,
  #    "password_min_symbols": 0,
  #    "password_max_attempts": nil
  #    "created_at": "2013-03-04T15:40:45-05:00",
  #    "updated_at": "2013-03-04T15:40:45-05:00",
  #    "url": "http://api.roundtriptohealth.com/organizations/1"
  #   }
  def show
    organization = Organization.find(params[:id])
    if !organization
      return HESResponder("Organization", "NOT_FOUND")
    end
    return HESResponder(organization)
  end

  # Create a organization
  #
  # @url [POST] /organizations/1/organizations/1
  # @authorize Master
  # @param [Integer] reseller_id The id of the reseller to create the organization
  # @param [String] name The name of the organization
  # @param [Boolean] password_ignores_case Whether or not the user's password is case sensitive
  # @param [Integer] password_min_length The minimum number of characters required for the password
  # @param [Integer] password_max_length The maximum number of characters allowed for the password
  # @param [Integer] password_min_letters The minimum number of letters required for the password
  # @param [Integer] password_min_number The minimum number of digits required for the password
  # @param [Integer] password_min_symbols The minimum number of symbols required for the password
  # @param [Integer] password_max_attempts The maximum number of attempts the user can try to enter password
  # @param [String] contact_name The contact name for the person in charge of the organization
  # @param [String] contact_email The contact email for the person in charge of the organization
  # @return [Organization] Organization that matches the id
  #
  # [URL] /resellers/:id/organizations [POST]
  #  [201 CREATED] Successfully created a Organization
  #   # Example response
  #   {
  #    "id": 1,
  #    "reseller_id": 1,
  #    "name": "HES",
  #    "contact_name": "Jane Doe",
  #    "contact_email": "janed@hesonline.com",
  #    "password_ignores_case": false,
  #    "password_min_length", 8,
  #    "password_max_length", 12,
  #    "password_min_letters": 0,
  #    "password_min_number": 0,
  #    "password_min_symbols": 0,
  #    "password_max_attempts": nil
  #    "created_at": "2013-03-04T15:40:45-05:00",
  #    "updated_at": "2013-03-04T15:40:45-05:00",
  #    "url": "http://api.roundtriptohealth.com/organizations/1"
  #   }
  def create
    Organization.transction do
      organization = @reseller ? @reseller.organizations.create(params[:organization]) : Organization.create(params[:organization])
    end
    if !organization.valid?
      return HESResponder(organization.errors.full_messages, "ERROR")
    end
    return HESResponder(organization)
  end

  # Update a organization
  #
  # @url [PUT] /organizations/1
  # @authorize Master
  # @param [Integer] id The id of the organization
  # @param [String] name The name of the organization
  # @param [Boolean] password_ignores_case Whether or not the user's password is case sensitive
  # @param [Integer] password_min_length The minimum number of characters required for the password
  # @param [Integer] password_max_length The maximum number of characters allowed for the password
  # @param [Integer] password_min_letters The minimum number of letters required for the password
  # @param [Integer] password_min_number The minimum number of digits required for the password
  # @param [Integer] password_min_symbols The minimum number of symbols required for the password
  # @param [Integer] password_max_attempts The maximum number of attempts the user can try to enter password
  # @param [String] contact_name The contact name for the person in charge of the organization
  # @param [String] contact_email The contact email for the person in charge of the organization
  # @return [Organization] Organization that matches the id
  #
  # [URL] /organizations/:id [PUT]
  #  [202 ACCEPTED] Successfully updated Organization
  #   # Example response
  #   {
  #    "id": 1,
  #    "reseller_id": 1,
  #    "name": "HES",
  #    "contact_name": "Jane Doe",
  #    "contact_email": "janed@hesonline.com",
  #    "password_ignores_case": false,
  #    "password_min_length", 8,
  #    "password_max_length", 12,
  #    "password_min_letters": 0,
  #    "password_min_number": 0,
  #    "password_min_symbols": 0,
  #    "password_max_attempts": nil
  #    "created_at": "2013-03-04T15:40:45-05:00",
  #    "updated_at": "2013-03-04T15:40:45-05:00",
  #    "url": "http://api.roundtriptohealth.com/organizations/1"
  #   }
  def update
    organization = Organization.find(params[:id])
    if !organization
      return HESResponder("Organization", "NOT_FOUND")
    else
      Organization.transaction do
        organization.update_attributes(params[:organization])
      end
      if !organization.valid?
        return HESResponder(organization.errors.full_messages, "ERROR")
      else
        return HESResponder(organization)
      end
    end
  end

  # Deletes a organization
  #
  # @url [DELETE] /organizations/1
  # @authorize Master
  # @param [Integer] id The id of the organization
  # @return [Organization] Organization that matches the id
  #
  # [URL] /organizations/:id [DELETE]
  #  [200 OK] Successfully deleted Organization
  #   # Example response
  #   {
  #    "id": 1,
  #    "reseller_id": 1,
  #    "name": "HES",
  #    "contact_name": "Jane Doe",
  #    "contact_email": "janed@hesonline.com",
  #    "password_ignores_case": false,
  #    "password_min_length", 8,
  #    "password_max_length", 12,
  #    "password_min_letters": 0,
  #    "password_min_number": 0,
  #    "password_min_symbols": 0,
  #    "password_max_attempts": nil
  #    "created_at": "2013-03-04T15:40:45-05:00",
  #    "updated_at": "2013-03-04T15:40:45-05:00",
  #    "url": "http://api.roundtriptohealth.com/organizations/1"
  #   }
  def destroy
    organization = Organization.find(params[:id])
    if !organization
      return HESResponder("Organization", "NOT_FOUND")
    elsif organization.destroy
      return HESResponder(organization)
    else
      return HESResponder("Error deleting.", "ERROR")
    end
  end
end
