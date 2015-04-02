class Encryption
  include Crypto

  def self.decrypt(v)
    if v != nil && v.empty? == false
      r = Crypto::RSA.new(Constant::SafeKey)
      v = r.decrypt v.unpack('m').to_s
    end
    v
  end

  def self.encrypt(v)
    if v != nil && v.empty? == false
      r = Crypto::RSA.new(Constant::SafeKey)
      v = r.encrypt(v).to_a.pack('m')
    end
    v
  end
end