require "hes-evaluations/engine"

# Evaluations module that contains the ability for any model to create evaluation definitions and have users complete evaluations generated from the definitions
module HesEvaluations
end

include HesEvaluations

# Common Answer Groups
EvaluationAnswerGroup.new :zero_six, [0, 1, 2, 3, 4, 5, 6]
EvaluationAnswerGroup.new :zero_seven, [0, 1, 2, 3, 4, 5, 6, 7]
EvaluationAnswerGroup.new :zero_nine, [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
EvaluationAnswerGroup.new :zero_ten, [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
EvaluationAnswerGroup.new :fruit_vegetable_servings, ['0', '1', '2', '3', '4', '5', '6+']
EvaluationAnswerGroup.new :poor_good, ['Poor', 'Fair', 'Good', 'Very Good']
EvaluationAnswerGroup.new :never_always, ['Never', 'Rarely', 'Sometimes', 'Most of the time', 'Always']
EvaluationAnswerGroup.new :sleep_hours, ['Less than 7', '7-9', '9+']
EvaluationAnswerGroup.new :minutes_per_day, ['0 - 15', '16 - 30', '31 - 45', '46 - 60', 'More than 60']
EvaluationAnswerGroup.new :perceptions, ['Not thinking about achieving an active lifestyle', 'Thinking about achieving an active lifestyle', 'Preparing to achieve an active lifestyle', 'Achieving an active lifestyle, but for less than 6 months', 'Achieving an active lifestyle for 6 months or more']

# Common Questions
EvaluationQuestion.new(:days_active_per_week, "How many days each week do you exercise for at least 30 minutes at a moderate or strenuous level?", :zero_seven)
EvaluationQuestion.new(:exercise_per_day, "On average, about how many minutes did you spend exercising on these days?", :minutes_per_day)
EvaluationQuestion.new(:perception, "When it comes to achieving or maintaining an active lifestyle, I am:", :perceptions)
EvaluationQuestion.new(:fruit_servings, "On average, how many servings of fruits do you eat each day?", :zero_six)
EvaluationQuestion.new(:vegetable_servings, "On average, how many servings of vegetables do you eat each day?", :zero_six)
EvaluationQuestion.new(:fruit_vegetable_servings, "On average, how many servings of fruits and vegetables do you eat each day?", :zero_nine)
EvaluationQuestion.new(:whole_grains, "On average, how many servings of whole grains do you eat each day?", :zero_six)
EvaluationQuestion.new(:breakfast, "On average, how many days each week do you eat breakfast?", :zero_seven)
EvaluationQuestion.new(:stress, "How would you rate your ability to cope with daily stress?", :poor_good)
EvaluationQuestion.new(:sleep_hours, "On average, how many hours do you sleep each night?", :sleep_hours)
EvaluationQuestion.new(:social, "How would you rate the overall frequency and quality of your social connections?", :poor_good)
EvaluationQuestion.new(:water_glasses, "On average, how many 8-ounce glasses of water do you drink each day?", :zero_ten)
EvaluationQuestion.new(:kindness, "How many days a week do you perform a random act of kindness, such as volunteering, donating money, or holding the door open for someone?", :zero_seven)
EvaluationQuestion.new(:energy, "In the last month, how often did you have enough energy to do the things you enjoy?", :never_always)
EvaluationQuestion.new(:overall_health, "How would you describe your overall health?", :poor_good)
EvaluationQuestion.new(:liked_most, "What did you like most about this program?")
EvaluationQuestion.new(:liked_least, "What did you like least about this program?")


#KP Answers
EvaluationAnswerGroup.new :find_out_answers, ["Email", "Website", "Flyer/poster", "Word-of-mouth", "My manager", "Event", "Other"]
EvaluationAnswerGroup.new :focus_options, ["Physical activity", "Healthy eating", "Weight management", "Stress management", "Other"]

#KP Questions
EvaluationQuestion.new(:average_days_active_per_week, "On average, how many days per week are you active at a moderate or strenuous level? (like a brisk walk)", :zero_seven)
EvaluationQuestion.new(:average_minutes_per_day, "On average, about how many minutes per day are you active at this level?", :minutes_per_day)
EvaluationQuestion.new(:find_out, "How did you find out about Go KP?", :find_out_answers)
EvaluationQuestion.new(:focus, "What healthy activity do you most want to focus on? (select one)", :focus_options)
EvaluationQuestion.new(:liked_most_gokp, "What do you like most about Go KP?")
EvaluationQuestion.new(:liked_least_gokp, "What do you like least about Go KP?")
EvaluationQuestion.new(:change_one_thing, "If you could change one thing to improve Go KP, what would it be?")