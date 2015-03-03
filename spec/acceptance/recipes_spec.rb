require 'acceptance_helper'

resource "Recipes" do
  get "http://www.gokp.com/recipes" do
    example "Listing recipes" do
      do_request
      status.should == 200
    end
  end
end
