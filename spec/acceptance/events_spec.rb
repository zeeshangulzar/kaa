require 'acceptance_helper'

resource "Events" do

  header "Authorization", "Basic NjpjaGFuZ2VtZTY="

  get "http://www.gokp.com/events" do
    example "Listing events" do
      do_request
      status.should == 200
    end
  end
end
