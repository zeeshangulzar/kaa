# abstraction layer between models and active record
class ApplicationModel < ActiveRecord::Base

  self.abstract_class = true
  def all_attrs
    return *self.class.column_names
  end


#  def as_json(options = nil)
#    parent_class = self.class.table_name
#    hash = serializable_hash(options)
#
#    tables = ApplicationModel.connection.tables
#
#
#    hash.keys.each do |key|
#      if tables.include?(key) && hash[key].is_a?(Array)
#        data = hash[key].clone
#        hash[key] = {
#          :data => data.first(ApplicationController::PAGE_SIZE),
#          :meta => {
#            :links  => {
#              :count => data.size,
#              :current   => '/' + parent_class + '/' + hash['id'].to_s + '/' + key.to_s
#            }
#          }
#        }
#
#        if data.size > ApplicationController::PAGE_SIZE
#          hash[key][:meta][:links][:next] = '/' + parent_class + '/' + hash['id'].to_s + '/' + key.to_s + '?offset=' + ApplicationController::PAGE_SIZE.to_s
#        end
#     end
#    end
#    hash
#  end


  def url
    return '/' + self.class.table_name.to_s + '/' + self.id.to_s
  end
  
end