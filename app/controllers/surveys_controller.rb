# Adds ability to create surveys through ActiveResource in application
class SurveysController < ApplicationController
  respond_to :json

  authorize :create, :public

  # Creates a contact request for a user
  #
  # @example
  #  #POST /surveys
  #  {
  #    first_name: 'Ryan',
  #    last_name: 'Norman',
  #    organization: 'HES',
  #    email: 'ryann@hesonline.com',
  #    phone: '810-240-6882',
  #    comments: 'This website is broken!!!'
  #  }
  # @return [Survey] that was just created
  #
  # [URL] /surveys [POST]
  #  [201 CREATED] Successfully created Survey object
  #   # Example response
  #   {
  #    "survey_type": 'Contact Us',
  #    "first_name": 'Ryan',
  #    "last_name": 'Norman',
  #    "organization": 'HES',
  #    "email": 'ryann@hesonline.com',
  #    "phone": '810-240-6882',
  #    "comments": 'This website is broken!!!'
  #   }
  def create
    @survey = Survey.create(params[:survey])
    return HESResponder(@survey)
  end
end