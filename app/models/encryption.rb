class Encryption
  include Crypto

  def self.decrypt(v)
    if v != nil && v.empty? == false
      r = Crypto::RSA.new(Constant::SafeKey)
      v = r.decrypt(v)
    end
    v
  end

  def self.encrypt(v)
    if v != nil && v.empty? == false
      r = Crypto::RSA.new(Constant::SafeKey)
      v = r.encrypt(v)
    end
    v
  end
end