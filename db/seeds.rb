
Promotion.find(:all).each{|promo| 
  puts "Destroying #{promo.subdomain}"
  promo.destroy
}

puts "Destroying Tips..."
Tip.find(:all).each{|tip|
  tip.destroy  
}

startDt = Date.new(2014, 11, 1)
puts "Creating Reseller HES"
reseller = Reseller.create :name=>"Health Enhancement Systems", :contact_name=>"HES ADMIN", :contact_email=>"admin@hesapps.com"
puts "Creating Organization HES"
organization = reseller.organizations.create :name=>"Health Enhancement Systems", :contact_name=>"HES ADMIN", :contact_email=>"admin@hesapps.com"

puts "Creating dashboard promotion"
dashboardPromotion = Promotion.create :name=>"Health Enhancement Systems", 
:organization_id => organization.id,
:subdomain=>'dashboard', 
:is_active=>1, 
:program_length => 9000,
:starts_on => Date.today, 
:launch_on => Date.today, 
:registration_starts_on => Date.today
dashboardPromotion.save!

puts "Creating www promotion"
promotion = Promotion.create :name=>"Health Enhancement Systems", 
:organization_id => organization.id,
:subdomain=>'www',
:is_active=>1,
:program_length => 364,
:starts_on => Date.today, 
:launch_on => Date.today,
:registration_starts_on => Date.today

promotion.save!

puts "Creating Evaluation for promotion #{promotion.subdomain}"
promotion.evaluation_definitions.create :name => "Initial Assessment", 
:message => "Welcome, we look forward to you enjoying <i>Keep America Active</i>",
:days_from_start => 0,
visible_questions: "days_active_per_week,exercise_per_day,fruit_vegetable_servings,breakfast,sleep_hours", 
start_date: nil, 
end_date: nil

location1 = promotion.locations.create :name => '712 Cambridge'

promotion_point_thresholes_1 = promotion.point_thresholds.create :value => 1, :min => 6000, :rel => "STEPS", :color => '#ff7c01'
promotion_point_thresholes_2 = promotion.point_thresholds.create :value => 1, :min => 30, :rel => "MINUTES", :color => '#55a746'
promotion_point_thresholes_3 = promotion.point_thresholds.create :value => 1, :min => 2, :rel => "BEHAVIORS", :color => '#55a746'
promotion_point_thresholes_4 = promotion.point_thresholds.create :value => 1, :min => 1, :rel => "GIFTS", :color => '#55a746'

promotion.save!

puts "Creating Healthy Behaviors"
behavior_breakfast = promotion.behaviors.create :name => "Healthy Breakfast", :content => "Eat a healthy breakfast", :summary => "A good breakfast sets you up for success throughout the day. If you skip it or select foods with highly refined carbs (like donuts, muffins, many cereals, or most breakfast bars), you&rsquo;re likely to overeat later in the day. 

Choose a variety of breakfast foods for staying power and lasting energy &mdash; high protein, whole grains, high fiber, and mono or polyunsaturated fats, such as eggs, fresh or frozen produce, low-fat plain yogurt, and whole grain toast.", :sequence => 2
behavior_breakfast.save!

behavior_produce = promotion.behaviors.create :name => "5+ produce servings", :content => "Eat *at least* 5 vegetable and fruit servings", :summary => "Choose from a variety of colors to get the most benefits vegetables and fruit offer &mdash; vitamins, minerals, fiber, and [phytonutrients][2] &mdash; for better health. Aim for 3 or more vegetable servings and 2 fruit servings a day. 

[What&rsquo;s a serving?][1] A vegetable serving is equal to 1 cup of fresh or cooked vegetables or 2 cups of leafy greens.
A fruit serving is equal to 1 cup diced fruit, about 8 strawberries, 1/2 cup dried fruit, 1 small apple, 1 medium pear. 

[1]: http://www.chow.com/assets/2011/05/FRUIT_VEG_SERVINGS.pdf
[2]: http://www.webmd.com/diet/guide/phytonutrients-faq#1", :sequence => 3
behavior_produce.save!

behavior_sugared = promotion.behaviors.create :name => "No sugared drinks", :content => "No sugared drinks", :summary => "Avoid sugar-sweetened beverages (soft drinks, specialty coffees, fruit drinks/punch, sweetened tea, sweetened waters, energy drinks). Staying hydrated with plain or fruit/vegetable-infused water can help limit the temptation. 

Water also plays an important role in regulating body temperature, removing waste, cushioning joints, and protecting your tissue/organs. Make drinking water throughout the day a habit, aiming for 5 or more cups.", :sequence => 4
behavior_sugared.save!

behavior_after_diner = promotion.behaviors.create :name => "No after dinner eating", :content => "No after dinner eating", :summary => "Late night snacking is the biggest downfall for many. You eat healthy all day, then evening comes and you give in to munching while watching a favorite TV program, reading, or surfing the web. In almost every instance, late night snacking has nothing to do with hunger &mdash; it&rsquo;s a habit ingrained over years, tied to an emotional or social need. The first step toward breaking the habit is recognizing it. 

Remember to eat a balanced meal 3-4 hours before going to bed. If you still have the urge, try drinking water with fruit or cucumber slices or herbal tea without sugar or milk &mdash; and add it as a water serving.", :sequence => 5
behavior_after_diner.save!



puts "Creating Tips"
tip1 = Tip.for_promotion(promotion).new :day=>1, :title=> "Count Your Blessings", :summary => "In this season of celebration and giving, take a moment to reflect on what you already have.", :email_subject=> "Experience winter in the Carpathian Mountains", :email_image_caption => "Cozy cabins amid snow-laden trees glow in a Ukrainian winter&rsquo;s night." , :content => "In this season of celebration and giving, take a moment to reflect on what you already have. Cultivate a thankful heart by listing 3 or more people or things you&rsquo;re grateful for today &mdash; like your kids&rsquo; morning hugs, sharing your favorite holiday recipe, or the chance to do [meaningful work you enjoy][1].

Believe it or not, the simple act of recording what you&rsquo;re thankful for can brighten your outlook when you do it regularly. Researcher Sonya Lyubomirsky says keeping a [gratitude journal][2] is a proven way to boost happiness &mdash; and once a week does the trick.

Train your brain to view life through an appreciation lens. Shifting your focus from what&rsquo;s wrong or what you don&rsquo;t have to all you&rsquo;re grateful for is a huge step toward less stress and better well-being. 

[1]: #/articles/article_craft_a_career_you_love
[2]: http://greatergood.berkeley.edu/article/item/tips_for_keeping_a_gratitude_journal"
tip1.save!
tip2 = Tip.for_promotion(promotion).new :day=>2, :title=> "Share a Friendly Smile", :summary => "One of the best ways to feel merrier is also stunningly simple: Smile.", :email_subject=> "Travel by horsepower in an open sleigh", :email_image_caption => "Leroy Anderson&rsquo;s 1948 song &ldquo;Sleigh Ride&rdquo; made the horse-drawn sleigh a symbol of the holiday season." , :content => "One of the best ways to feel merrier is also stunningly simple: Smile. 

Putting on a cheerful face &mdash; even when you don&rsquo;t feel like it &mdash; can actually [make you happier][1]. That&rsquo;s right&hellip; &ldquo;fake it &lsquo;til you make it&rdquo; is often true for the act of flashing your pearly whites. 

Facial expressions help us connect; smiling plays an important role in [forming and strengthening relationships][2]. But it&rsquo;s also an easy way to [spread joy][3] and goodwill to people you don&rsquo;t even know.

Nobody wants to walk around with a fake grin &mdash; and we&rsquo;re not saying you should. But the next time you feel bored or blue, why not give it a try?

Make your holiday season jollier &mdash; and lift the spirits of those around you &mdash; by smiling more.  

[1]: http://www.scientificamerican.com/article/smile-it-could-make-you-happier/?page=1
[2]: http://www.yalescientific.org/2012/03/the-subtle-smile-the-effect-of-smiling-and-other-non-verbal-gestures-on-gender-roles/
[3]:#/articles/article_unwrap_holiday_joy"
tip2.save!
tip3 = Tip.for_promotion(promotion).new :day=>3, :title=> "Let It Go", :summary => "Forgiving is easier said than done, but it&rsquo;s vital for your well-being.", :email_subject=> "Get cozy during a winter night", :email_image_caption => "There&rsquo;s nothing like the warm glow of a fire." , :content => "One of the best ways to feel merrier is also stunningly simple: Smile. 

Putting on a cheerful face &mdash; even when you don&rsquo;t feel like it &mdash; can actually [make you happier][1]. That&rsquo;s right&hellip; &ldquo;fake it &lsquo;til you make it&rdquo; is often true for the act of flashing your pearly whites. 

Facial expressions help us connect; smiling plays an important role in [forming and strengthening relationships][2]. But it&rsquo;s also an easy way to [spread joy][3] and goodwill to people you don&rsquo;t even know.

Nobody wants to walk around with a fake grin &mdash; and we&rsquo;re not saying you should. But the next time you feel bored or blue, why not give it a try?

Make your holiday season jollier &mdash; and lift the spirits of those around you &mdash; by smiling more.  

[1]: http://www.scientificamerican.com/article/smile-it-could-make-you-happier/?page=1
[2]: http://www.yalescientific.org/2012/03/the-subtle-smile-the-effect-of-smiling-and-other-non-verbal-gestures-on-gender-roles/
[3]:#/articles/article_unwrap_holiday_joy"
tip3.save!
tip4 = Tip.for_promotion(promotion).new :day=>4, :title=> "Budget-Friendly Gift-Giving", :summary => "Holiday gifts don&rsquo;t have to break the bank. Take a few minutes to map out your strategy for meaningful gift-giving within your budget.", :email_subject=> "Bring the snow to life", :email_image_caption => "Nobody knows who built the first snowman or why, but now they&rsquo;re a favorite of young sculptors." , :content => "One of the best ways to feel merrier is also stunningly simple: Smile. 

Putting on a cheerful face &mdash; even when you don&rsquo;t feel like it &mdash; can actually [make you happier][1]. That&rsquo;s right&hellip; &ldquo;fake it &lsquo;til you make it&rdquo; is often true for the act of flashing your pearly whites. 

Facial expressions help us connect; smiling plays an important role in [forming and strengthening relationships][2]. But it&rsquo;s also an easy way to [spread joy][3] and goodwill to people you don&rsquo;t even know.

Nobody wants to walk around with a fake grin &mdash; and we&rsquo;re not saying you should. But the next time you feel bored or blue, why not give it a try?

Make your holiday season jollier &mdash; and lift the spirits of those around you &mdash; by smiling more.  

[1]: http://www.scientificamerican.com/article/smile-it-could-make-you-happier/?page=1
[2]: http://www.yalescientific.org/2012/03/the-subtle-smile-the-effect-of-smiling-and-other-non-verbal-gestures-on-gender-roles/
[3]:#/articles/article_unwrap_holiday_joy"
tip4.save!
tip5 = Tip.for_promotion(promotion).new :day=>5, :title=> "Bring on the Holiday Fun", :summary => "Whether your job takes you to a busy metropolis or sleepy small town, you&rsquo;ll find a flurry of holiday events waiting outside the workplace walls.", :email_subject=> "Recognize both male and female caribou by their antlers", :email_image_caption => "Caribou &mdash; also known as reindeer &mdash; root through the snow for food and eat nearly 12 pounds each day." , :content => "Whether your job takes you to a busy metropolis or sleepy small town, you&rsquo;ll find a flurry of holiday events waiting outside the workplace walls. From music to craft bazaars, you can find ways to recharge, refresh, and get into the spirit of the season &mdash; by stepping out into your [community][1].

Why not invite a *Keep America Active* buddy to brainstorm a quick list of fun, festive things to do together on your lunch break or after work? Invite several coworkers if you&rsquo;d like; the more, the merrier. Get started with these ideas:

- Sample traditional Hanukkah, Kwanzaa, and Christmas dishes

- Take in free holiday concerts at local high schools, colleges/universities, and places of worship 

- Visit a gingerbread house exhibit

- Attend a coffeehouse poetry reading

- Join a community songfest

- Participate in a 5K jingle bell run or walk

- Go ice skating. 

Choose 1 fun thing to do this week &mdash; and go from there.

[1]: #/articles/article_unwrap_holiday_joy"

tip5.save!
tip6 = Tip.for_promotion(promotion).new :day=>6, :title=> "Give Back This Season", :summary => "For many, the holidays are a time to emphasize giving. If you feel inspired, put your generosity in motion by donating time and effort toward a cause you care about.", :email_subject=> "Take a ride up before speeding down the mountain", :email_image_caption => "Chairlifts give skiers and snowboarders quick access to terrain that once took hours to hike." , :content => "For many, the holidays are a time to emphasize giving. If you feel inspired, put your generosity in motion by donating time and effort toward a cause you care about. Whether you wrap gifts to raise money for charity, help staff a shelter, or visit a nursing home resident, [volunteering][1] benefits both the giver and the receiver.

Besides strengthening community connections and fostering a sense of purpose, volunteering actually [boosts well-being][2] &mdash; but only if it&rsquo;s something you truly want to do. Better health and happiness are just examples of the perks you can get when you pitch in.

Gather your *Keep America Active* teammates, coworkers, family, or friends and work together to make your world brighter. Join a 1-time event, or make an ongoing commitment. Check out [VolunteerMatch.org][3] or [United Way][4] for opportunities near you.

[1]: #/articles/article_deck_the_halls_with_hope 
[2]: http://www.helpguide.org/articles/work-career/volunteering-and-its-surprising-benefits.htm
[3]: http://www.volunteermatch.org 
[4]: http://www.unitedway.org/take-action/volunteer"

tip6.save!
tip7 = Tip.for_promotion(promotion).new :day=>7, :title=> "Ho, Ho, Ho!", :summary => "When was the last time you laughed out loud? Nurturing a sense of humor &mdash; and letting it show &mdash; adds to the joy of the holidays.", :email_subject=> "Remember to thank Thomas Edison", :email_image_caption => "In addition to inventing the first practical lightbulb, Edison is also responsible for the first strand of electric lights." , :content => "When was the last time you laughed out loud? Nurturing a sense of humor &mdash; and letting it show &mdash; adds to the joy of the holidays. 

It&rsquo;s no secret that a good belly laugh makes us feel great &mdash; emotionally and physically. Whether your laugh is more of a chortle, a snicker, or a snort, laughing is a great way to de-stress; it relaxes muscles, boosts mood, and even [decreases pain][1]. The best part? It also helps us connect with others &mdash; anywhere.

Make a point of getting your giggle on this season; spot the comedy in everyday work and life. Try these ideas, and come up with your own:

- Watch a funny holiday movie or attend a light-hearted school play

- Do something out of the ordinary &mdash; go dancing, snowshoeing, or caroling

- Tell a *Keep America Active* friend a hilarious story&hellip; something that really happened to you.

For more ways to feel great, read [Santa Baby, Bring Me More Energy][2].

[1]: http://www.helpguide.org/articles/emotional-health/laughter-is-the-best-medicine.htm
[2]: #articles/article_bring_me_more_energy"

tip7.save!
tip8 = Tip.for_promotion(promotion).new :day=>8, :title=> "Savor a Holiday Moment", :summary => "Looking for ways to enhance your holiday happiness? It&rsquo;s easier than you think.", :email_subject=> "Take advantage of activities only winter can offer", :email_image_caption => "Adventurers paddle over the clear, icy ocean to witness Antarctica&rsquo;s breathtaking views and unique wildlife." , :content => "Looking for ways to enhance your holiday happiness? It&rsquo;s easier than you think. 

According to happiness researchers, tuning in to all your senses to fully experience positive moments can brighten your outlook. Why not give it a try? Instead of grabbing your phone to record holiday fun, take a deep breath&hellip; and capture the moment by [being completely in it][1].

Remembering good times from holidays past can also spark happy feelings. Did you get to light the candles, or help prepare a traditional treat? Was that the year Grandpa dressed up in a red suit? Reflect on one of your favorite memories &mdash; from a childhood holiday or another time in your life. For fun, tell a *Keep America Active* teammate about it.  

Gathering with friends and family is often the highlight of the holidays. Enjoy these special times even more this year by truly relishing them &mdash; and by stirring up warm memories of yesteryear.

[1]: #/articles/article_unwrap_holiday_joy"
tip8.save!
tip9 = Tip.for_promotion(promotion).new :day=>9, :title=> "Write an Old-Fashioned Thank You Note", :summary => "When somebody thanks you for a gift or a kindness, it can make your day. But being a giver of gratitude has rewards, too.", :email_subject=> "Celebrate the holidays with family", :email_image_caption => "Roe deer tend to gather in large family groups during winter, near foraging areas." , :content => "When somebody thanks you for a gift or a kindness, it can make your day. But being a giver of gratitude has rewards, too. Enhance your joy and peace this season by reaching out to someone with a heartfelt [thank you note][1].

Giving thanks is linked with a surprising assortment of [benefits][2] &mdash; like increased happiness, optimism, generosity, and compassion. Showing gratitude makes people feel more connected, and even boosts physical well-being.

Send a thank-you note for anything. Trust your feelings &mdash; if you&rsquo;re truly grateful for a gesture, a gift, or an effort, your genuine thanks will go over well. Saying thank you communicates appreciation, respect, and caring; writing it down goes the extra mile. 

Everyone realizes that putting pen to paper, addressing an envelope, and mailing it take more effort than an email, quick text, or Facebook post. Your handwritten words are guaranteed to delight. Dash off a thank you note today.

[1]: http://www.hallmark.com/thank-you/ideas/how-to-write-a-thank-you-note/
[2]: http://greatergood.berkeley.edu/article/item/why_gratitude_is_good"
tip9.save!
tip10 = Tip.for_promotion(promotion).new :day=>10, :title=> "Friendly Festivities", :summary => "Celebrating the holidays with friends brings comfort and joy &mdash; and strengthens ties that enrich your life all year round.", :email_subject=> "Take the whole family skiing", :email_image_caption => "Skiers enjoys a freshly groomed run on a bluebird day." , :content => "Celebrating the holidays with friends brings comfort and joy &mdash; and strengthens ties that enrich your life all year round. Make your season merrier by inviting others to join you for festive fun. A warm invitation might be all it takes to spark a lifelong connection.

The darker days of winter drive us indoors &mdash; and colder, wetter weather makes us want to stay there. So make the most of chances to [get social][1] &mdash; on the job or after work. Try these ideas, or come up with a list of your own:

- Invite a *Keep America Active* buddy or someone else to join you for coffee or lunch today

- Organize a potluck featuring holiday favorites

- Recruit a colleague to go for a brisk break-time walk

- Gather a group to take in a seasonal art display at lunchtime

- Show up at employer or other holiday events.

Take a moment to jot down 1 fun way to mix and mingle this week.

[1]: #/articles/article_deck_the_halls_with_hope"
tip10.save!
tip11 = Tip.for_promotion(promotion).new :day=>11, :title=> "Hark, the Herald Compliments Ring", :summary => "&ldquo;What a beautiful sweater.&rdquo; &ldquo;Great work &mdash; you nailed it.&rdquo; There&rsquo;s nothing like getting a compliment to make you feel merry and bright.", :email_subject=> "Beat the chill with a cup of warmth", :email_image_caption => "A steaming mug of green tea helps thaw cold fingers." , :content => "&ldquo;What a beautiful sweater.&rdquo; &ldquo;Great work &mdash; you nailed it.&rdquo; There&rsquo;s nothing like getting a compliment to make you feel merry and bright. 

Mark Twain said, &ldquo;I can live for 2 months on a good compliment.&rdquo; Getting noticed for efforts, accomplishments, or even what we&rsquo;re wearing can make us feel happy and more connected, but some people are embarrassed by compliments. If you&rsquo;re one of them, consider the giver&rsquo;s good intentions next time; simply smile and say, &ldquo;Thank you.&rdquo; 

[Giving a compliment][1] feels great, too &mdash; but it&rsquo;s easy to let the moment slip by without saying anything. When you feel genuine praise or admiration take shape, go ahead and deliver it&hellip; and see what happens. Chances are, your kind words will make someone&rsquo;s day; the smile you get in return might even make yours.

In this season of [giving][2], why not offer a gift you can&rsquo;t wrap? 

[1]: http://www.psychologytoday.com/articles/200403/the-art-the-compliment 
[2]: #/articles/article_unwrap_holiday_joy"
tip11.save!
tip12 = Tip.for_promotion(promotion).new :day=>12, :title=> "Be Kind... to Yourself", :summary => "On an average day, do you give yourself more kudos or criticism? Most people say they&rsquo;re too hard on themselves.", :email_subject=> "Remember some surfaces freeze before others", :email_image_caption => "Water vapor freezes on glass, creating a kaleidoscope of colors." , :content => "On an average day, do you give yourself more kudos or criticism? Most people say they&rsquo;re too hard on themselves. Try an experiment this season: Treat yourself with more kindness and compassion.

Researcher Kristin Neff explains that [self-compassion][1] involves [3 steps][2]:

- Responding in a caring way to your own suffering. Acknowledge the tough place you&rsquo;re in; speak words of understanding and encouragement. Be as kind to yourself as you are to your best friend.

- Recognizing that suffering is part of life, with its many outside influences you can&rsquo;t control everything. If you did your best, give yourself some credit.

- Practicing [mindfulness][3], which involves moving toward your own suffering instead of avoiding it. Observing negative feelings and emotions without judging helps you proceed with a clear mind instead of reacting.

More self-compassion might be the best gift you&rsquo;ve ever unwrapped.

[1]: http://www.self-compassion.org/what-is-self-compassion/definition-of-self-compassion.html 
[2]: http://www.self-compassion.org/what-is-self-compassion/the-three-elements-of-self-compassion.html
[3]: http://www.helpguide.org/harvard/benefits-of-mindfulness.htm"
tip12.save!
tip13 = Tip.for_promotion(promotion).new :day=>13, :title=> "Silver and Gold", :summary => "Does the season of snowflakes and sleigh bells find you forking over the green stuff or giving your credit cards a workout?", :email_subject=> "Take part in holiday tradition", :email_image_caption => "Strands of colorful lights &mdash; made popular by Albert Sadacca in 1917 &mdash; drape trees and outline homes during the holidays." , :content => "Does the season of snowflakes and sleigh bells find you forking over the green stuff or giving your credit cards a workout? Believe it or not, the way you pay influences how much you spend &mdash; and how you feel when you&rsquo;re spending. 

Paying with cash is an obvious way to stay out of debt or avoid taking on more. But researchers say handing over cash also causes [pain receptors in the brain to light up][1]. Paying with credit cards has a more numbing effect because the loss isn&rsquo;t immediate; it doesn&rsquo;t hurt&hellip; right away.

With auto deposits and online banking, handling cash is a lot less common. If you&rsquo;re motivated to [stay within your budget][2] &mdash; and start the New Year without more bills to pay &mdash; get in touch with your dough, literally. This approach will make you think twice &mdash; or maybe 3 times &mdash; before parting with it.

[1]: http://www.cmu.edu/homepage/practical/2007/winter/spending-til-it-hurts.shtml
[2]: #/articles/article_deck_the_halls_with_hope"
tip13.save!
tip14 = Tip.for_promotion(promotion).new :day=>14, :title=> "Cheers to Your Career", :summary => "Got a knack for customer service, crunching numbers, or driving a one-horse open sleigh? When you get to use your strengths each day, the work week is much merrier.", :email_subject=> "Try a new winter sport or activity", :email_image_caption => "A team of sled dogs pulls the musher along a flat stretch." , :content => "Got a knack for customer service, crunching numbers, or driving a one-horse open sleigh? When you get to use your strengths each day, the work week is much merrier. And looking forward to the day ahead is a really nice way to wake up.

Gallup research says [career well-being][1] is a huge influence on overall health and happiness. When your job is a [good fit][2] for your strengths, you&rsquo;ll feel less stressed and more satisfied. So look for ways to do more of what you do well &mdash; even if your current role isn&rsquo;t exactly your cup of hot cocoa. Here&rsquo;s how:

- Create a shine list &mdash; things where you excel 

- Brainstorm ideas for using your top skills to get the job done or take on new responsibilities 

- Talk to your boss about your strengths and interests &mdash; highlighting how you can help achieve department/organization goals.

Spend some time this week to identify your personal and professional strengths. Need help? Invite input from people that know you well.

[1]: http://businessjournal.gallup.com/content/127034/career-wellbeing-identity.aspx 
[2]: #/articles/article_craft_a_career_you_love"
tip14.save!
tip15 = Tip.for_promotion(promotion).new :day=>15, :title=> "Share the Bounty", :summary => "Fending off weight gain is a top priority for many this time of year. Yet 50 million US households are worried about going hungry.", :email_subject=> "Make some tracks in the snow", :email_image_caption => "Excited snow-goers stomp through the white stuff while playing in a park." , :content => "Fending off weight gain is a top priority for many this time of year. Yet 50 million US households are worried about going hungry. [Food insecurity][1] is a bigger problem than many people realize, even if it&rsquo;s not evident in your area. This season, pitch in to make the holidays easier for hungry kids and adults in your community.

Donation tips:

- Non-perishable, high-nutrition items are best &mdash; like canned meats, fish, fruits and vegetables, soup, and pasta sauce; dried pasta, beans, and rice; cereal, crackers, nut butters, and breakfast bars.

- Donating from your cupboards? Check expiration dates first.

- If you have a winter garden, see if the food bank accepts fresh produce.

- Gifts of money help food banks purchase in bulk; if available through your employer, complete a matching gift request to double your impact.

Helping neighbors in need does more than fight hunger &mdash; it sends a message of [hope][2]. What&rsquo;s 1 way you can help this week?

[1]: http://feedingamerica.org/hunger-in-america/hunger-facts/hunger-and-poverty-statistics.aspx 
[2]: #/articles/article_deck_the_halls_with_hope"
tip15.save!
tip16 = Tip.for_promotion(promotion).new :day=>16, :title=> "Walk in a Winter Wonderland", :summary => "Walking works wonders for well-being any time of year, and winter is no exception.", :email_subject=> "Snack healthily, like this bird", :email_image_caption => "The Parus major is common throughout Europe and isn&rsquo;t migratory, so it eats seeds and berries throughout the winter." , :content => "Walking works wonders for well-being any time of year, and winter is no exception. So gather your coworkers and get moving to [keep your energy][1] and mood high this season. 

Whatever your climate, there&rsquo;s a way to get your walk on. Try these ideas:

- Organize a break-time walking group, and send calendar invitations. Create several nearby walking routes, and rotate through them each week.

- Warm up indoors for 5-10 minutes before heading out into chilly weather.

- Too cold out? Walk the stairwells, do loops inside your building, or head to a shopping mall.

- Turn up the heat by including hills or stairs in your indoor or outdoor routes.

- Try a fitness-walking DVD.

- Fire up the treadmill before or after work.

- Use Nordic walking poles to burn more calories and work your upper body.

- Knee-deep in white, fluffy stuff? Break out your snowshoes or cross-country skis.

If winter walks aren&rsquo;t already on your weekly calendar, schedule them today.

[1]: #/articles/article_bring_me_more_energy"
tip16.save!
tip17 = Tip.for_promotion(promotion).new :day=>17, :title=> "Light Up Your Career", :summary => "Reflecting on the past, present, and future is a popular holiday tradition. Why not think about ways to boost your career?", :email_subject=> "Put the fireplace to good use", :email_image_caption => "Have you ever tried chestnuts on an open fire? They&rsquo;re the only nuts with vitamin C." , :content => "Reflecting on the past, present, and future is a popular holiday tradition. Why not think about ways to boost your career? Whether or not your current job rings your bell, look ahead. Are you on the right path to get where you want to go in the New Year? 

Boost your professional mojo by plugging in to [career resources][1]. Try these ideas, and come up with your own:

- Say yes to in-house learning opportunities; find out if tuition reimbursement is offered for external classes

- Join an association specific to your job interests; read up on trends and issues, then get involved

- Introduce yourself; get better at networking, inside and outside your workplace

- Sidle up to a mentor &mdash; someone who can coach you toward your career goals

- Volunteer for a challenging project that stretches your skills.

Take a moment today to write down 1 thing you can do this week to enhance your career.

[1]: #/articles/article_craft_a_career_you_love"
tip17.save!
tip18 = Tip.for_promotion(promotion).new :day=>18, :title=> "Lighten a Load", :summary => "Simple acts of kindness &mdash; like smiling as you hold a door, running an errand, or pitching in to finish a project &mdash; remind us that we&rsquo;re all in this together.", :email_subject=> "Dress for 20 degrees warmer than actual temps when running outside in winter", :email_image_caption => "A run through the snow is a great way to stay fit." , :content => "Simple acts of kindness &mdash; like smiling as you hold a door, running an errand, or pitching in to finish a project &mdash; remind us that we&rsquo;re all in this together. Helping builds connections, stirs compassion, and even boosts happiness.

We all need help sooner or later. So make the season brighter by lending a hand &mdash; or a shoulder. Try these ideas:

- Knock out some extra chores at home

- Volunteer in a school classroom

- Help a friend decorate or prepare for a holiday event

- Let a weary parent go ahead of you in the checkout line

- Surprise your spouse or partner with a home-cooked meal and a kitchen that sparkles

- Give up your seat on the bus or train

- Support your local [Toys For Tots][1] by sorting and wrapping gifts.

What&rsquo;s 1 small or big way you can make the world a better place this week?

[1]: http://www.toysfortots.org/Default.aspx"
tip18.save!
tip19 = Tip.for_promotion(promotion).new :day=>19, :title=> "The Gift of Presence", :summary => "In the holiday hustle and bustle, make a point of slowing down. Practicing everyday mindfulness builds a habit you&rsquo;ll benefit from all year.", :email_subject=> "Keep dry and warm with wool", :email_image_caption => "This kitten gets comfortable, burrowing into warm woolen layers." , :content => "In the holiday hustle and bustle, make a point of slowing down. Practicing everyday mindfulness builds a habit you&rsquo;ll benefit from all year. Quieting your mind and body nurtures your soul&hellip; and brings about a wonderful feeling of [peace and joy][1].

[Mindfulness][2] is about nonjudgmental awareness of the present; it&rsquo;s the opposite of distraction and reaction. Like any skill, becoming mindful takes practice &mdash; and patience. Make ideas like these part of your routine to enhance feelings of compassion for yourself and others, relieve stress, and improve [well-being][3].

You&rsquo;ll enjoy the holidays even more through a lens of calm:

- Help yourself stay calm through rituals &mdash; a warm bath, morning walk, favorite music

- Take 5 minutes each day to breathe slowly &mdash; in through your nose, out through your mouth &mdash; focusing only your breathing

- Tune in to all your senses to fully experience your meal 

- Learn more by reading *Full Catastrophe Living* by Dr. Jon Kabat-Zinn.

What&rsquo;s 1 way you can be more mindful today?

[1]: #/articles/article_unwrap_holiday_joy
[2]: http://www.helpguide.org/harvard/benefits-of-mindfulness.htm
[3]: http://nau.edu/Research/Feature-Stories/Mindfulness-Training-Has-Positive-Health-Benefits/"
tip19.save!
tip20 = Tip.for_promotion(promotion).new :day=>20, :title=> "Take a Trip on the Way-Back Machine, Holiday Style", :summary => "There&rsquo;s something about this time of year that makes you feel like a kid again.", :email_subject=> "Take advantage of wintery conditions on a snowmobile", :email_image_caption => "Snowmobilers ride through a winter wonderland." , :content => "There&rsquo;s something about this time of year that [makes you feel like a kid again][1]. Whether it&rsquo;s the thrill of a fresh snowfall, the joy of sharing family traditions, or the smell of pumpkin pie in the oven, one thing&rsquo;s for sure: excitement is in the air.

Sharing favorite memories with family and friends is a great part of the season. Digging up old photos &mdash; even if they&rsquo;re cringe-inducing &mdash; is a fun way to reminisce&hellip; and conjure up some of the magic from holidays past. 

Try these ideas, then come up with more of your own:

- Show your kids what the holidays were like in the olden days

- Challenge your coworkers to an awkward family photo contest

- Frame a favorite holiday shot and keep it at your work station

- That adorable picture of you at age 5, next to a snowman? Post it on Facebook or Instagram for Throwback Thursday.

Take a minute to jot down 1 idea for enjoying your holiday photo faves this week.

[1]: #/articles/article_unwrap_holiday_joy"
tip20.save!
tip21 = Tip.for_promotion(promotion).new :day=>21, :title=> "Thankful Tidings", :summary => "Service workers come through for us every day, whether they whip up that nonfat latte, give us a safe ride to work, or ring up our holiday gifts.", :email_subject=> "Head outside during the warmest time of day", :email_image_caption => "Looking for a midday snack, a red squirrel stops to pose." , :content => "Service workers come through for us every day, whether they whip up that nonfat latte, give us a safe ride to work, or ring up our holiday gifts. Expressing gratitude for a job well done is an easy way to spread [happiness and goodwill][1] wherever you go.

Make a habit of connecting with the people behind your daily transactions. Treating others with kindness and appreciation adds to our own gladness, too.

Say thank-you today with these ideas; they take only a second, but can make a world of difference:

- Look your cashier in the eye and flash a sincere smile as you say, &ldquo;thank you&rdquo;

- Be specific about what you appreciate &mdash; if your mechanic always goes the extra mile, say so

- When asked about your day, return the courtesy

- Let management know when you receive outstanding service 

- Tip generously.

What are a few ways you&rsquo;ll show your gratitude this week?

[1]: #/articles/article_unwrap_holiday_joy"
tip21.save!
tip22 = Tip.for_promotion(promotion).new :day=>22, :title=> "Words to Inspire", :summary => "Simple words can warm our hearts, lift our spirits, and inspire action.", :email_subject=> "Get your heart racing in the snow", :email_image_caption => "A snowboarder soars like a snowflake after launching from a cliff." , :content => "Simple words can warm our hearts, lift our spirits, and inspire action. Here are a few favorites:

- &ldquo;If we had no winter, the spring would not be so pleasant.&rdquo; &mdash; Anne Bradstreet

- &ldquo;How wonderful it is that nobody need wait a single moment before starting to improve the world.&rdquo; &mdash; Anne Frank

- &ldquo;Make the most of yourself by fanning the tiny, inner sparks of possibility into flames of achievement.&rdquo; &mdash; Golda Meir

- &ldquo;Be kinder than necessary, because everyone you meet is fighting some kind of battle.&rdquo; &mdash; J.M. Barrie

- &ldquo;The last of human freedoms: the ability to choose ones attitude in a given set of circumstances.&rdquo; &mdash; Viktor E. Frankl

- &ldquo;Laugh as much as possible, always laugh. It is the sweetest thing one can do for oneself and one&rsquo;s fellow human beings.&rdquo; &mdash; Maya Angelou

- &ldquo;Believe you can and you&rsquo;re halfway there.&rdquo; &mdash; Theodore Roosevelt

Share a quote to encourage a *Keep America Active* buddy today."
tip22.save!
tip23 = Tip.for_promotion(promotion).new :day=>23, :title=> "Soul-Soothing Habits", :summary => "Peace and quiet can be hard to find in the hubbub of everyday life &mdash; especially during the holidays.", :email_subject=> "Start your day with a warm beverage", :email_image_caption => "Covered in layers, a couple shares a morning cup of tea on the front porch." , :content => "Peace and quiet can be hard to find in the hubbub of everyday life &mdash; especially during the holidays. How often are you alone with your own thoughts &mdash; without people talking, your phone vibrating, or music playing? Taking time out for the solace of stillness isn&rsquo;t a luxury; it&rsquo;s a daily must.

Create a tranquil oasis to [refresh and renew][1] wherever you are. Sample different ways to calm your mind, unburden your heart, and let your spirit speak. Try these ideas:

- Take 5 to [meditate][2]. Focus on your breathing, relax, and observe your thoughts instead of getting carried away with them

- Pray or quietly contemplate the matters of your heart

- Put a do not disturb sign on your office or bedroom door

- Use noise-canceling headphones

- If silence is distracting, use an app featuring [ocean, thunder, or rainforest sounds][3].

Jot down 1 way you can create more tranquil moments this week.

[1]: #/articles/article_unwrap_holiday_joy 
[2]: http://www.mayoclinic.org/healthy-living/stress-management/multimedia/meditation/vid-20084741
[3]: https://itunes.apple.com/us/app/meditationbuddy/id453981398?mt=8"
tip23.save!
tip24 = Tip.for_promotion(promotion).new :day=>24, :title=> "Saving for the Season", :summary => "Do the holidays inspire you to take stock of your life &mdash; your blessings, challenges, accomplishments, and dreams?", :email_subject=> "Be careful not to hit someone while sledding at a public hill", :email_image_caption => "A family takes their sled back to the top for round 2." , :content => "Do the holidays inspire you to take stock of your life &mdash; your blessings, challenges, accomplishments, and dreams? Savoring the moment heightens happiness, but there&rsquo;s value to planning, too, especially when that helps you meet your goals. Whether you&rsquo;re more of a saver or spender, streamlining your finances will give you more to celebrate in the New Year. 

[Managing money][1] is a skill anyone can learn; here&rsquo;s how to get started:

- *Face it.* Create a monthly [budget][2], listing household income, bills, and expenses.

- *Share it.* Talk with your spouse/partner/housemate/kids; teamwork is vital to financial well-being.

- *Track it.* Use pen and paper, simple spreadsheets, software, or a free app like [Mint][3] to track every dollar.

- *Pay it off.* List all debts, smallest to largest. Some experts recommend [knocking out your smallest debt first][4], or focus on the one with the highest interest. 

- *Set it and forget it.* Build your emergency fund, retirement, and other savings with automatic deposits and transfers.

What&rsquo;s 1 thing you can do this week to boost your financial well-being?

[1]: #/articles/article_deck_the_halls_with_hope 
[2]: http://www.bankrate.com/finance/financial-literacy/secrets-to-creating-a-budget-1.aspx
[3]: https://www.mint.com/how-it-works/anywhere/ 
[4]: http://www.daveramsey.com/blog/how-the-debt-snowball-method-works"
tip24.save!
tip25 = Tip.for_promotion(promotion).new :day=>25, :title=> "Traditional Trimmings", :summary => "Hanukkah, Kwanzaa, Christmas, Winter Solstice, and more&hellip; the season&rsquo;s celebrations are taking place around the world in secular and faith-based traditions.", :email_subject=> "Gather up some friends and make snow angels", :email_image_caption => "You&rsquo;ll need more than 2 to break the Guinness World Record for people making snow angels simultaneously in one place: 8962." , :content => "Hanukkah, Kwanzaa, Christmas, Winter Solstice, and more&hellip; the season&rsquo;s celebrations are taking place around the world in secular and faith-based traditions. 

Get a sample of global cheer by showing an interest in the holiday customs of your friends, neighbors, and coworkers. It&rsquo;s a chance to learn something new and interesting, plus a fun way to be social and [spread goodwill][1].

- Organize a holiday potluck with foods representing different countries and customs.

- Take your family to a community holiday event highlighting unfamiliar festivities.

- Discover &mdash; and share &mdash; the origins of your own family&rsquo;s rituals and customs. Did your ancestors bring them from another country? Were they practiced in ancient times, or did your great-great-grandma start something new?

- Start a casual conversation &mdash; inviting others to talk about their holiday traditions, music, decorations, activities, and more.

Promote peace this season with the gifts of understanding and respect.  

[1]: #/articles/article_deck_the_halls_with_hope"
tip25.save!
tip26 = Tip.for_promotion(promotion).new :day=>26, :title=> "Sprinkle Joy, Spread Happiness", :summary => "Looking for a way to make a difference in your community? Sporting a sunny attitude is a good place to start.", :email_subject=> "Spend time in the company of loved ones", :email_image_caption => "Polar bear cubs snuggle up to their mother for warmth and protection as the sun goes down in arctic Russia." , :content => "Looking for a way to make a difference in your community? Sporting a sunny attitude is a good place to start. Even when things aren&rsquo;t going your way, [looking on the bright side][1] can help.

It&rsquo;s no secret that emotions are contagious. A happy employee can energize the whole office &mdash; and a sourpuss quickly spreads clouds of doom and gloom. But did you know that even the [friends of your friend&rsquo;s friends][2] influence your mood? 

Hanging out with upbeat, positive people is a tried-and-true way to heighten your outlook. And choosing a cheerful countenance pays it forward in big ways. Try these ideas for sowing a spirit of optimism and buoyancy wherever you go for the holidays and beyond:

- Speak words of kindness and encouragement

- Seek solutions rather than complaining

- Look for reasons to be thankful every day

- Smile often &mdash; even when you&rsquo;re alone. 

Jot down your own ideas for sprinkling joy and spreading happiness this week.

[1]:#/articles/article_deck_the_halls_with_hope 
[2]: http://www.bmj.com/content/337/bmj.a2338"
tip26.save!
tip27 = Tip.for_promotion(promotion).new :day=>27, :title=> "Get This Party Started", :summary => "*The more, the merrier* is right on the mark when it comes to holiday fun.", :email_subject=> "Begin the New Year with a refreshing dip", :email_image_caption => "A brave man pops his head out of a hole in the ice after a polar bear plunge." , :content => "*The more, the merrier* is right on the mark when it comes to holiday fun. Seasonal galas and informal get-togethers are a great way to celebrate with workplace friends &mdash; and make new connections. Why not kick up your heels and join in this year?

[Holiday socializing][1] strengthens bonds that help you and your colleagues work together as a team. And, like it or not, your coworkers have a big influence on your well-being. Getting to know them better outside of your work space enhances on-the-job interactions &mdash; and may even forge lasting friendships. 

So, go ahead &mdash; get your holiday groove on. A few tips:

- Feeling shy? Invite a *Keep America Active* friend to join you.

- Avoid shop talk. Ask workmates about their holiday or vacation plans, musical interests, and families. 

- Let your hair down, but not too much. Limiting alcohol &mdash; and karaoke &mdash; is *always* a good idea.

Jot down 1 idea for joining in the holiday fun this season.

[1]: #/articles/article_unwrap_holiday_joy"
tip27.save!
tip28 = Tip.for_promotion(promotion).new :day=>28, :title=> "Speak Up for the Greater Good", :summary => "Got an opinion about federal, state, or local issues? Raise your voice&hellip; and not just at the dinner table.", :email_subject=> "Avoid throngs of tourists by visiting countries that thrive throughout the winter", :email_image_caption => "Amid caf&#233;s, restaurants, and shops in Istanbul, a street vendor sells traditional Turkish fast food." , :content => "Got an opinion about federal, state, or local issues? Raise your voice&hellip; and not just at the dinner table. Voting is vital, but there&rsquo;s plenty of business between elections, and your input matters year-round. 

Staying informed about public matters &mdash; and speaking up &mdash; is every voter&rsquo;s civic duty. We&rsquo;re all guardians of local and global communities, safeguarding our liberties and well-being now and for generations to come. 

As the New Year approaches, resolve to step up. Here&rsquo;s how:

- Get to know your elected officials. Visit their websites, view voting records, and learn about the issues they&rsquo;re tackling.

- Dash off a note to your representatives about an issue you care about. Explain why it matters to you and your family &mdash; and what you think should happen.

- Support a cause you&rsquo;re passionate about; join a political action group, show up at a rally, or help with a fundraiser.

Jot down 1 way you can get more involved now &mdash; or after the holidays are over."
tip28.save!
tip29 = Tip.for_promotion(promotion).new :day=>29, :title=> "Be Jolly, By Golly", :summary => "Even the merriest holiday revelers run out of steam at times. Need a mid-afternoon or after-work pick-me-up?", :email_subject=> "Get out your cookie cutters for the holidays", :email_image_caption => "Baking homemade gifts is good for friends and family as well as your budget." , :content => "Even the merriest holiday revelers run out of steam at times. Need a mid-afternoon or after-work pick-me-up? Lift your spirits any time of day, all year-round with these natural mood-boosters:

- Head outside for a quick walk. Even 10 minutes of fresh air and [brisk exercise][1] will make you feel better.

- Chat with your coworkers over lunch or coffee. A little socializing goes a long way when you&rsquo;re feeling out of sorts.

- Create a good-mood go-to playlist. Whether it&rsquo;s upbeat or mellow, listen to whatever makes you happiest.

- Catch a few winks. Even a 10-30 minute [afternoon nap][2] can make a world of difference.

- Introduce yourself. Making a new friend or contact is remarkably energizing.

- Relive a happy moment. Think of something that made you smile yesterday; share it with a *Keep America Active* buddy. 

Write down 1-2 mood-boosting ideas you&rsquo;d like to try this week.

[1]: #/articles/article_bring_me_more_energy 
[2]: http://www.mayoclinic.org/healthy-living/adult-health/in-depth/napping/art-20048319?pg=1"
tip29.save!
tip30 = Tip.for_promotion(promotion).new :day=>30, :title=> "Give Them a Jingle", :summary => "Connecting with family and friends is a highlight of the holiday season for many.", :email_subject=> "Embrace what winter offers", :email_image_caption => "A waddle of penguins sends off the first brave one into the water." , :content => "Connecting with family and friends is a highlight of the holiday season for many. Social networking has made keeping in touch year-round easier, but a personal call means a lot more than a Facebook post.

Believe it or not, the sound of your voice is a treasured gift to those who hold you dear. Whether you [ring up Grandma][1] or a far-flung college roommate, odds are good you&rsquo;ll make their day. 

A few tips:

- Check the time zone. Early-morning and late-night calls can be startling.

- Let the person you call know you just wanted to say hi &mdash; and ask if now is a good time to talk before launching a conversation.

- Scheduling a voice or video call instead of an out-of-the-blue visit works better for some.

This is the perfect time to put those unused mobile minutes to good use. Who&rsquo;d be delighted to hear from you today?

[1]: #/articles/article_unwrap_holiday_joy"
tip30.save!

puts "Creating Master User for Dashboard"
master = dashboardPromotion.users.build
master.role=User::Role[:master]
master.password = 'test'
master.email = 'admin@hesapps.com'
master.username = 'admin'
master.auth_key = 'changeme'
master.location = location1
if master.save
  master_profile = master.create_profile :first_name => 'HES', :last_name => 'Admin'
end

puts "Creating done promotion"
start_on = Date.today - 42
length = 28
promotionDone = Promotion.create :name=>"Done", 
:organization_id => organization.id,
:subdomain=>'done',
:is_active=>1,
:program_length => length,
:starts_on => start_on, 
:ends_on => start_on + length,
:launch_on => start_on,
:registration_starts_on => start_on,
:registration_ends_on => start_on + 14,
:late_registration_ends_on => start_on + 14,
:weekly_goal => 12, 
:logging_ends_on => start_on + 35

promotionDone.save!

puts "Creating now4 promotion"
start_on = Date.today
length = 28
promotionNow4 = Promotion.create :name=>"Now 4 weeks", 
:organization_id => organization.id,
:subdomain=>'now4',
:is_active=>1,
:program_length => length,
:starts_on => start_on, 
:ends_on => start_on + length,
:launch_on => start_on,
:registration_starts_on => start_on,
:registration_ends_on => start_on + 14,
:late_registration_ends_on => start_on + 14,
:weekly_goal => 12, 
:logging_ends_on => start_on + 35

promotionNow4.save!

puts "Creating now6 promotion"
start_on = Date.today
length = 42
promotionNow6 = Promotion.create :name=>"Now 6 weeks", 
:organization_id => organization.id,
:subdomain=>'now6',
:is_active=>1,
:program_length => length,
:starts_on => start_on, 
:ends_on => start_on + length,
:launch_on => start_on,
:registration_starts_on => start_on,
:registration_ends_on => start_on + 14,
:late_registration_ends_on => start_on + 14,
:weekly_goal => 12, 
:logging_ends_on => start_on + 49

promotionNow6.save!

puts "Creating mid4 promotion"
start_on = Date.today - 14
length = 28
promotionMid4 = Promotion.create :name=>"Middle 4 weeks", 
:organization_id => organization.id,
:subdomain=>'mid4',
:is_active=>1,
:program_length => length,
:starts_on => start_on, 
:ends_on => start_on + length,
:launch_on => start_on,
:registration_starts_on => start_on,
:registration_ends_on => start_on + 14,
:late_registration_ends_on => start_on + 14,
:weekly_goal => 12, 
:logging_ends_on => start_on + 35

promotionMid4.save!

puts "Creating mid6 promotion"
start_on = Date.today - 21
length = 42
promotionMid6 = Promotion.create :name=>"Middle 6 weeks", 
:organization_id => organization.id,
:subdomain=>'mid6',
:is_active=>1,
:program_length => length,
:starts_on => start_on, 
:ends_on => start_on + length,
:launch_on => start_on,
:registration_starts_on => start_on,
:registration_ends_on => start_on + 14,
:late_registration_ends_on => start_on + 14,
:weekly_goal => 12, 
:logging_ends_on => start_on + 49

promotionMid6.save!

puts "Creating team6 promotion"
start_on = Date.today - 14
length = 42
promotionTeam6 = Promotion.create :name=>"Team 6 weeks", 
:organization_id => organization.id,
:subdomain=>'team6',
:is_active=>1,
:program_length => length,
:starts_on => start_on,
:ends_on => start_on + length,
:launch_on => start_on,
:registration_starts_on => start_on,
:registration_ends_on => start_on + 28,
:late_registration_ends_on => start_on + 14,
:weekly_goal => 12, 
:logging_ends_on => start_on + 49

competition = promotionTeam6.competitions.create :enrollment_starts_on => promotionTeam6.starts_on, :enrollment_ends_on => promotionTeam6.registration_ends_on, :competition_starts_on => promotionTeam6.starts_on, :competition_ends_on => promotionTeam6.ends_on, :active => 1, :name=> 'Team Competition', :team_size_min => 2, :team_size_max => 8, :freeze_team_scores => 2

promotionTeam6.save!

Promotion.find(:all).each{|promo|

  if !(promo.is_default? || promo.is_dashboard?)
    puts "Creating users for Promotion #{promo.name}"
    user = promo.users.build
    user.role = User::Role[:user]
    user.password = 'test'
    user.email = 'johns@hes.com'
    user.username = 'johns'
    user.location = location1
    if user.save
      user_profile = user.create_profile :first_name => 'John', :last_name => 'Stanfield', :started_on => promo.starts_on, :registered_on => promo.starts_on
      #Override the defaults and have this user start in the past... for seeding purposes
      user_profile.started_on = (startDt + 7)
      user_profile.save!
    end

    user2 = promo.users.build
    user2.role = User::Role[:user]
    user2.password = 'test'
    user2.email = 'bobb@hes.com'
    user2.username = 'bobb'
    user2.location = location1
    if user2.save
      user2_profile = user2.create_profile :first_name => 'Bob', :last_name => 'Baldwin', :started_on => promo.starts_on, :registered_on => promo.starts_on
      #Override the defaults and have this user start in the past... for seeding purposes
      user2_profile.started_on = (startDt)
      user2_profile.save!
    end

    user3 = promo.users.build
    user3.role = User::Role[:user]
    user3.password = 'test'
    user3.email = 'jakes@hes.com'
    user3.username = 'jakes'
    user3.location = location1
    if user3.save
      user3_profile = user3.create_profile :first_name => 'Jake', :last_name => 'Smith', :started_on => promo.starts_on, :registered_on => promo.starts_on
      #Override the defaults and have this user start in the past... for seeding purposes
      user3_profile.started_on = (startDt + 7)
      user3_profile.save!
    end

    user4 = promo.users.build
    user4.role = User::Role[:user]
    user4.password = 'test'
    user4.email = 'drewp@hes.com'
    user4.username = 'drewp'
    user4.location = location1
    if user4.save
      user4_profile = user4.create_profile :first_name => 'Drew', :last_name => 'Papworth', :started_on => promo.starts_on, :registered_on => promo.starts_on
      #Override the defaults and have this user start in the past... for seeding purposes
      user4_profile.started_on = (startDt + 7)
      user4_profile.save!
    end

    user5 = promo.users.build
    user5.role = User::Role[:user]
    user5.password = 'test'
    user5.email = 'richardw@hes.com'
    user5.username = 'richardw'
    user5.location = location1
    if user5.save
      user5_profile = user5.create_profile :first_name => 'Richard', :last_name => 'Wardin', :started_on => promo.starts_on, :registered_on => promo.starts_on
      #Override the defaults and have this user start in the past... for seeding purposes
      user5_profile.started_on = (startDt + 7)
      user5_profile.save!
    end

    user6 = promo.users.build
    user6.role = User::Role[:user]
    user6.password = 'test'
    user6.email = 'miker@hes.com'
    user6.username = 'miker'
    user6.location = location1
    if user6.save
      user6_profile = user6.create_profile :first_name => 'Mike', :last_name => 'Robertson', :started_on => promo.starts_on, :registered_on => promo.starts_on
      #Override the defaults and have this user start in the past... for seeding purposes
      user6_profile.started_on = (startDt + 7)
      user6_profile.save!
    end

    user7 = promo.users.build
    user7.role = User::Role[:user]
    user7.password = 'test'
    user7.email = 'nathanp@hes.com'
    user7.username = 'nathanp'
    user7.location = location1
    if user7.save
      user7_profile = user7.create_profile :first_name => 'Nathan', :last_name => 'Papes', :started_on => promo.starts_on, :registered_on => promo.starts_on
      #Override the defaults and have this user start in the past... for seeding purposes
      user7_profile.started_on = (startDt + 7)
      user7_profile.save!
    end


    #Build up user entries
    if !promo.individual_logging_frozen?
      entry_1 = user.entries.build(:recorded_on => user.profile.started_on, :exercise_minutes => nil)
      entry_1.save!
      entry_1.entry_behaviors.build(:behavior_id => behavior_breakfast.id, :value => 1)
      entry_1.exercise_minutes = 28
      entry_1.save!

      entry_2 = user.entries.build(:recorded_on => user.profile.started_on + 1 , :exercise_steps => 10302, :exercise_minutes => nil)
      entry_2.save!
    end
  end 

}

# puts "to make testing easy, auth-basic headers are below"
# User.all.each do |user|
#   puts user.email
#   puts user.auth_basic_header 
# end