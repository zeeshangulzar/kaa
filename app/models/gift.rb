class Gift < ApplicationModel
  attr_accessible *column_names
  attr_privacy_no_path_to_user
  attr_privacy :name, :cap_value, :content, :summary, :image, :visible_date, :public
  attr_privacy :sequence, :master
  belongs_to :promotion

  has_many :entries_gifts
  
  attr_accessible :name, :type_of_prompt, :content, :cap_value, :cap_message, :regex_validation, :options, :summary, :image, :sequence
  
  # Name, type of prompt and sequence are all required
  validates_presence_of :name, :type_of_prompt

  validates_uniqueness_of :name, :scope => :type_of_prompt

  mount_uploader :image, GiftImageUploader
  
  # The types of prompts that are allowed for behaviors
  PROMPT_TYPES = {:checkbox => 'checkbox'}
  PROMPT_TYPES.each_pair do |k, v|
    # Define constants for prompt types
    const_set k.to_s.upcase, v

    # Define scopes for prompt type
    scope k, where(:type_of_prompt => v)

    # Define test methods for prompt type
    define_method("#{k}?") do
      type_of_prompt == v
    end
  end
  
  # Array of options
  # @return [Array<String>] options in array
  def options
    read_attribute(:options).to_s.split("\n")
  end

  def options=(value)
    value = value.join("\n") if value.is_a?(Array)
    super
  end
  
  # Overrides as_json so that regular expression validation hash is included instead of just name
  # @param [Hash] options for as_json
  # @return [Hash] json format of Behavior
  def as_json(options = {})
    _json = super
    _json['regex_validation'] = self.regex_validation.as_json unless self.read_attribute(:regex_validation).nil?
    _json
  end

  def visible_date
    return self.promotion.starts_on + (self.sequence || 0)
  end
  
end
