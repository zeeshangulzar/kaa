# Models a evaluation definition that is used to create an evaluation
class EvaluationDefinition < ActiveRecord::Base
  attr_accessible :name, :days_from_start, :message, :visible_questions

  belongs_to :promotion

  has_many :evaluations

  many_to_many :with => :custom_prompt, :primary => :evaluation_definition

  maintain_sequence

  # Overrides serializable_hash so that questions and custom prompts can be included
  def serializable_hash(options = {})
    hash = super(options)

    hash["questions"] = []

    # Include the default questions.
    EvaluationQuestion.all.each do |question|
      hash["questions"] << question.serializable_hash
    end

    # Include any custom prompts it's promotion might have.
    promotion.custom_prompts.each do |custom_prompt|
      hash["questions"] << custom_prompt.serializable_hash.merge({"name" => custom_prompt.name, "type_of_prompt" => custom_prompt.type_of_prompt.upcase}) #if self.send("is_#{custom_prompt.short_label.downcase..gsub(' ', '_')}_displayed?")
    end

    hash
  end
end