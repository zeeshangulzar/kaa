# Models a evaluation definition that is used to create an evaluation
class EvaluationDefinition < ApplicationModel
  attr_accessible :name, :days_from_start, :message, :visible_questions, :start_date, :end_date
  attr_privacy :name, :days_from_start, :message, :visible_questions, :start_date, :end_date, :public
  belongs_to :eval_definitionable, :polymorphic => true

  has_many :evaluations

  many_to_many :with => :custom_prompt, :primary => :evaluation_definition

  maintain_sequence

  scope :active, where("start_date <= '#{Date.today}' AND end_date >= '#{Date.today}'").order("start_date ASC")

  scope :active_with_user, lambda{ |user|
    days = user.promotion.current_date - user.profile.started_on rescue 0
    where("eval_definitionable_type = 'Promotion' AND eval_definitionable_id = #{user.promotion_id} AND ((start_date <= '#{user.promotion.current_date}' AND end_date >= '#{user.promotion.current_date}') OR days_from_start <= #{days})").order("start_date ASC")
  }

  # Overrides serializable_hash so that questions and custom prompts can be included
  def serializable_hash(options = {})
    hash = super(options)

    hash["questions"] = []

    # Include the default questions.
    EvaluationQuestion.all.each do |question|
      hash["questions"] << question.serializable_hash
    end

    # Include any custom prompts it's promotion might have.
    eval_definitionable.custom_prompts.each do |custom_prompt|
      hash["questions"] << custom_prompt.serializable_hash.merge({"name" => custom_prompt.name, "type_of_prompt" => custom_prompt.type_of_prompt.upcase}) #if self.send("is_#{custom_prompt.short_label.downcase..gsub(' ', '_')}_displayed?")
    end

    hash
  end
end
