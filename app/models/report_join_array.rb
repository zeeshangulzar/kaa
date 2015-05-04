class ReportJoinArray < Array
  
  def find(id)
    self.detect{|x| x.id.to_i == id.to_i}
  end
  
  def build(attributes={})
    self << ReportJoin.new(attributes)
    self.last
  end
  
  def symbolize
    _symbols = {}
    self.each do |f|
      _symbols[f.id.to_s] = f.symbolize
    end
    
    _symbols
  end
end