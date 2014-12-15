# Models a custom prompt (question) that can be added to any evaluation, test, registration, or assessment
class CustomPrompt < ApplicationModel
  attr_accessible :sequence, :prompt, :data_type, :type_of_prompt, :short_label, :options, :is_active, :is_required

  # Check box type
  CHECKBOX = "CHECKBOX"

  # Dropdown type
  DROPDOWN = "DROPDOWN"

  # Text box type
  TEXTBOX = "TEXTBOX"

  # Multiline text box type
  MULTILINETEXTBOX = "MLTEXTBOX"

  # Likert type
  LIKERT = "LIKERT"

  # Header type
  HEADER = "HEADER"

  # Page break type
  PAGEBREAK = "PAGEBREAK"

  # Array of all custom prompt types
  TYPES = [CHECKBOX, DROPDOWN, TEXTBOX, MULTILINETEXTBOX, LIKERT, HEADER, PAGEBREAK]

  TYPES.each do |type|
    # Creates methods to test the status of a custom prompt
    # @return [Boolean] if custom prompt matches type_of_prompt
    # @example
    #  custom_prompt.checkbox?
    define_method "#{type.downcase}?" do
      type_of_prompt == type
    end

    # Defines scopes that will return custom prompts with a specific type of prompt
    # @example
    #  CustomPrompt.textbox
    scope type.downcase, where(:type_of_prompt => type)
  end

  # Default likert options
  DEFAULTLIKERT = "Strongly agree\nAgree somewhat\nUndecided\nDisagree somewhat\nStrongly disagree"

  belongs_to :custom_promptable, :polymorphic => true

  has_one :udf_def, :class_name => "UdfDef", :conditions => "parent_type = 'CustomPrompt'", :foreign_key => :parent_id, :dependent => :destroy

  # Must have a prompt unless it is a header type
  validates_presence_of :prompt, :short_label, :if => lambda{ |cp| cp.type_of_prompt != CustomPrompt::HEADER }

  # Date type must be included
  validates_presence_of :data_type

  # Options must be present if dropdown or likert custom prompts are created
  validates_presence_of :options, :if => lambda{ |cp| [DROPDOWN, LIKERT].include?(cp.type_of_prompt) }

  validates_uniqueness_of :prompt, :short_label, :scope => [:custom_promptable_id, :custom_promptable_type]

  # Add udf definitions after each custom prompt is created
  after_create :add_udf

  after_create :trigger_after_custom_prompt_add

  # Adds a user defined field definition for each custom prompt. The models that own these definitions are set when declaring a model to have custom prompts.
  # @example
  #  class Promotion
  #   has_custom_prompts :with => :evalutions
  def add_udf
    # don't bother making the UDF fields for headers and page breaks -- there's nothing to record
    unless [HEADER, PAGEBREAK].include?(self.type_of_prompt)
      self.custom_promptable && self.custom_promptable.class.udf_types.each do |udf_type|
        udf_def = UdfDef.new
        udf_def.owner_type = udf_type.to_s.singularize.camelcase
        udf_def.parent_type = CustomPrompt.to_s
        udf_def.parent_id = self.id
        udf_def.data_type = self.data_type.to_s
        udf_def.save!

        field_name = name
        udf_def.owner_type.constantize.send(:attr_accessible, field_name)
        
        udf_def.owner_type.constantize.send(:define_method, "#{field_name}=") do |value|
          set_custom_prompt_field(field_name, value)
        end

        udf_def.owner_type.constantize.send(:define_method, field_name) do
          get_custom_prompt_field(field_name)
        end
      end
    end
  end

  # Triggers after custom prompt added event
  def trigger_after_custom_prompt_add
    custom_promptable.fire_after_custom_prompt_added(self) if custom_promptable && custom_promptable.respond_to?(:fire_after_custom_prompt_added)
  end

  # Breaks options on the new line so that options are in an array
  # @return [Array<String>] options as an array of strings instead of a string
  def options
    self.read_attribute(:options).split("\n") unless self.read_attribute(:options).nil?
  end

  def name
    short_label.downcase.underscore
  end
end
