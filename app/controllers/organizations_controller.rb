# Controller for handling all organization related requests
class OrganizationsController < ApplicationController

  authorize :all, :master

  def index
    organizations = params[:reseller_id] ? Reseller.find(params[:reseller_id]).organizations : Organization.all
    return HESResponder(organizations)
  end

  def show
    organization = Organization.find(params[:id])
    if !organization
      return HESResponder("Organization", "NOT_FOUND")
    end
    return HESResponder(organization)
  end

  def create
    organization = @reseller ? @reseller.organizations.create(params[:organization]) : Organization.create(params[:organization])
    if !organization.valid?
      return HESResponder(organization.errors.full_messages, "ERROR")
    end
    return HESResponder(organization)
  end

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
