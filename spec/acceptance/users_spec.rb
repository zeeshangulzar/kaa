require 'acceptance_helper'

resource "Users" do
  post "http://www.gokp.com/users/authenticate" do
    example "Authenticating user" do
      do_request(:email => "richardw@hesonline.com", :password => "test")
      status.should == 200
    end
  end
end
