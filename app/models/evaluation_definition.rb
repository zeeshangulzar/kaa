# Models a evaluation definition that is used to create an evaluation
class EvaluationDefinition < ApplicationModel
  attr_accessible :name, :days_from_start, :message, :visible_questions, :start_date, :end_date, :questions
  attr_privacy :name, :days_from_start, :message, :visible_questions, :start_date, :end_date, :questions, :public
  belongs_to :eval_definitionable, :polymorphic => true
  attr_privacy_no_path_to_user

  has_many :evaluations

  many_to_many :with => :custom_prompt, :primary => :evaluation_definition

  maintain_sequence

  scope :active, where("start_date <= '#{Date.today}' AND end_date >= '#{Date.today}'").order("start_date ASC")

  scope :active_with_user, lambda{ |user|
    days = user.promotion.current_date - user.profile.started_on rescue 0
    where("eval_definitionable_type = 'Promotion' AND eval_definitionable_id = #{user.promotion_id} AND ((start_date <= '#{user.promotion.current_date}' AND end_date >= '#{user.promotion.current_date}') OR days_from_start <= #{days})").order("start_date ASC")
  }

  def questions
    return @questions if @questions
    @questions = []
    EvaluationQuestion.all.each do |question|
      @questions << question.serializable_hash
    end
    # Include any custom prompts it's promotion might have.
    eval_definitionable.custom_prompts.each do |custom_prompt|
      @questions << custom_prompt.serializable_hash.merge({"name" => custom_prompt.udf_def.cfn, "type_of_prompt" => custom_prompt.type_of_prompt.upcase, "custom_prompt" => true}) #if self.send("is_#{custom_prompt.short_label.downcase..gsub(' ', '_')}_displayed?")
    end
    return @questions
  end

end
