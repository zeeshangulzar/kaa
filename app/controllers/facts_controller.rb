class FactsController < ContentController
  authorize :current, :public
  def current
    return HESResponder(Fact.where("date <= '#{@promotion.current_date}'").limit(1))
  end
end
