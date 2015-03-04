require 'acceptance_helper'

resource "Entries" do

  header "Authorization", auth_basic_header

  get "http://www.gokp.com/entries" do
    example "Listing entries" do
      do_request
      status.should == 200
    end
  end
end
