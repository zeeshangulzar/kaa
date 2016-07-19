unless Rails.env == 'production'
  require 'benchmark'
  require 'multi_json'

  module MultiJson
    def self.my_dump(object, options = {})
      the_dump = nil
      ApplicationModel.benchmark 'json dump' do
        the_dump = self.dump(object, options)
      end
      return the_dump
    end
  end
end