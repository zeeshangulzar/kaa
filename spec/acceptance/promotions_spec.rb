require 'acceptance_helper'

resource "Promotions" do
  get "http://www.gokp.com/promotions/1" do
    example "Show promotion" do
      do_request
      status.should == 200
    end
  end
end
