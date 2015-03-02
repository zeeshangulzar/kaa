require 'acceptance_helper'

resource "Tips" do
  get "http://www.gokp.com/tips" do
    example "Listing tips" do
      do_request
      status.should == 200
    end
  end
end
