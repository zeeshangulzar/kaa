class ExportsController < ApplicationController
  authorize :index, :public

  def index                                     
    if request.post?                    
      send_data CGI.unescapeHTML(params[:data]), :filename => "#{params[:filename]}.csv", :content_type => 'text/csv'
    end                         
  end                                
end