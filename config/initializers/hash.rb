class Hash
  # don't overwrite keys with nil values
  def nil_merge!(x)
    return self.merge!(x.reject{|k,v|v.nil?})
  end
end