class Behavior < ApplicationModel
  attr_accessible *column_names
  attr_privacy_no_path_to_user
  attr_privacy :name, :cap_value, :content, :public

  belongs_to :promotion

  has_many :entries_behaviors
  has_many :point_thresholds, :as => :pointable, :order => 'min DESC'
  has_many :timed_behaviors
  
  attr_accessible :name, :type_of_prompt, :content, :cap_value, :cap_message, :regex_validation, :options, :summary
  
  # Name, type of prompt and sequence are all required
  validates_presence_of :name, :type_of_prompt

  validates_uniqueness_of :name, :scope => :type_of_prompt
  
  # The types of prompts that are allowed for behaviors
  PROMPT_TYPES = {:textbox => 'textbox', :checkbox => 'checkbox'}
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
  
  # Regular expression validations for testing different values in a text box
  REGEX_VALIDATIONS = {
    :anything => {:name => :anything, :display => 'Any text and/or number', :regex => nil, :message => nil},
    :one_digit => {:name => :one_digit, :display => '0 to 9', :regex => '^(\\d){1,1}$', :message => 'One digit only'},
    :two_digits => {:name => :two_digits, :display => '0 to 99', :regex => '^(\\d){1,2}$', :message => 'One or two digits'},
    :three_digits => {:name => :three_digits, :display => '0 to 999', :regex => '^(\\d){1,3}$', :message => 'Up to three digits'},
    :four_digits => {:name => :four_digits, :display => '0 to 9,999', :regex => '^(\\d){1,4}$', :message => 'Up to four digits'},
    :five_digits => {:name => :five_digits, :display => '0 to 99,999', :regex => '^(\\d){1,5}$', :message => 'Up to five digits'}
  }
  
  # Gets the regulare expression validation hash instead of just name
  # @return [Hash] with regular expression validation properties
  def regex_validation
    REGEX_VALIDATIONS[read_attribute(:regex_validation).to_sym] rescue nil
  end

  def active_timed_behavior
    self.timed_behaviors.select {|ta| ta.begin_date <= self.promotion.current_date && (ta.end_date.nil? || ta.end_date >= self.promotion.current_date)}.first
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
  
end
