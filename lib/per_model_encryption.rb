module PerModelEncryption
  # assumes you have created a migration for this model to add aes_key and aes_iv as strings  
  #  add_column :foo_bars, :aes_key, :string
  #  add_column :foo_bars, :aes_iv, :string
    
  def self.url_base64_encode(string)
    Base64.encode64(string).gsub('+','-').gsub('/','_')
  end
    
  def self.url_base64_decode(data)
    Base64.decode64(data.gsub('-','+').gsub('_','/'))
  end 
    
  def initialize_aes_iv_and_key
    #http://rubylearning.com/blog/2011/07/18/cryptography-or-how-i-learned-to-stop-worrying-and-love-aes/
    require 'openssl'
    require 'digest/sha2'
    
    sha256 = Digest::SHA2.new(256)
    aes = OpenSSL::Cipher.new("AES-256-CFB")
    iv = aes.random_iv
    hex = SecureRandom.hex(32)
    key = sha256.digest(hex)
    aes.encrypt
    
    self.aes_key=Base64.encode64(key).chomp
    self.aes_iv=Base64.encode64(iv).chomp
  end  

  def initialize_aes_iv_and_key_if_blank!
    self.reinitialize_aes_iv_and_key! unless self.aes_key && self.aes_iv
  end
  
  def reinitialize_aes_iv_and_key!
    # warning -- this method will destroy everything you've encrypted for this user because the key and iv will be reinitialized!
    # 
    self.initialize_aes_iv_and_key
    self.save! 
  end
    
  def aes_encrypt(data)
    require 'openssl'
    require 'digest/sha2'
    
    enc_sha256 = Digest::SHA2.new(256)
    enc_aes = OpenSSL::Cipher.new("AES-256-CFB")
    enc_aes.encrypt
    enc_aes.iv = Base64.decode64(self.aes_iv)
    enc_aes.key = Base64.decode64(self.aes_key)
    enc_aes.update(data) + enc_aes.final
  end
 
  def aes_decrypt(data)
    require 'openssl'
    require 'digest/sha2'

    dec_sha256 = Digest::SHA2.new(256)
    dec_aes = OpenSSL::Cipher.new("AES-256-CFB")
    dec_aes.decrypt
    dec_aes.iv = Base64.decode64(self.aes_iv)
    dec_aes.key = Base64.decode64(self.aes_key)
    dec_aes.update(data) + dec_aes.final
  end

  def test_aes_iv_and_key(test_string=SecureRandom.hex(64))
    encrypted_test_string = aes_encrypt(test_string) 
    decrypted_test_string = aes_decrypt(encrypted_test_string)
    return decrypted_test_string==test_string
  end
end