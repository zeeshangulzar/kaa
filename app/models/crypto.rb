#!/usr/bin/env ruby

# Example:
# # Randomly generated key use Crypto::RSA::generate_key once to get a key for use
# k = "bmwMv2HdVMmd0jgrBm1TLsKKlp1JRYrVXuKth6l7CrcMeCiMjlDvrxs243nwxE9FQHQ93eGWofJjSXm8drtFtj86PJ6sXwSUKpSsTxOCcLxPOzzP5mB2Vw7MdGoYv4uZtDuN7cJ2kqahdKTslxyzRiKWAyar82VGXS2aXEwfYCXinCVAox2Rxq4BDKfZsqxEVa14wAXWOFp2edG61qlRaS1OHPGAonbJG7vqeLleCtyMr5ht6iDlUvMc6QKOV0tzgx5aOCBbsKhBgI4vR7hoOwpi1FAdv6ubOs6hK5JlsJfsYq8rJTnSnXbku1YxZniE2N6GLEGcPM4qbrZGvD2Pq0BTD1hG7OB9QEk1gcWFhYxob9w6Uj7pk3l7ufy38M5Z7HFVNzzYpPL2EMm85E8QP9amkFFOqzXLehGpObS9MdqZvznn1Cw3qKJbBJCCb3llBmuc0eo2L9Ah3MUOmB5xS2Z8UaJ09QPNjUpMRSfGpPRJ6GZMtbimxNIZNlyAy8QqYOh4rV7C9UbEwlsIpnGHqgApKxeXDz1xSgSXB2jveOC17HQtlM2mwKQH64MMFCWtcBrbgxrH9kiQkEnW7y0GhPMg7hgBMIsqStFY2L6acZ00OuzSDGD06m13Ib4AJvbOFeybio7p2lr5Rorh7cFlmq3LsN98KSKWJDxXo5j3mmJU7vOBKX6RQU1rtXwyGpsuBJGPZoljxew8WzxC4R9lGLxmg8y2NSEnbv1fcsSvVvnu5JGyWqS6xE9wqu4xtFGQD79szXNxPodxM5zqSK9hJ2uAszQm3GWfRliLdc6iOSnCqLpBbqw57S4QjX5RyH3ES6NG3iVVTv3lAex5FMF6myb21rull8v8UgFdaxdOM1M7QgOElsrc5Y6cMFHBeAcnkQX3QfomoDGvBajMQmFWCpRVoApgGwCS51X1wJtrEnfz9nwDtON6JdOms1wF2mqDHpYhhEchyg0JytMGOw6msbZiP0xUEsdj1orM35t99TuVEArjKzrc1xJehmSDHENf"
# # Randomly choosing a range of characters from the key
# m = k[(rand(k.size.to_f/8).round+1)..(rand(k.size.to_f/8).round+1)]
# # Set the instance
# r = RSA::RSA.new(k)
# # Encrypt the value and store it
# se = r.encrypt(m)
# # Decrypt the value and store it
# sd = r.decrypt(se)
# # Print the results
# puts "Original:\n\t#{m}\n\n"
# puts "Encrypted:\n\t#{se}\n\n"
# puts "Decrypted:\n\t#{sd}"

module Crypto
  class RSA

    def initialize(pwd)
      @safeKey = pwd
      @len = pwd.size
    end
    
    def rc4initialize(pwd)
      @sbox = []
      @keys = []

      len = pwd.size
      256.times do |i|
        @keys << pwd[(i % len)]
        @sbox << i
      end
      
      b = 0
      256.times do |i|
        b = (b + @sbox[i] + @keys[i]) % 256
        tempSwap = @sbox[i]
        @sbox[i] = @sbox[b]
        @sbox[b] = tempSwap
      end
    end
    
    def crypt(plaintext)
      rc4initialize(@safeKey)

      len = plaintext.size
      i, j = 0, 0
      
      cipher = ""
      len.times do |a|
        i = (i + 1) % 256
        j = (j + @sbox[i]) % 256
        temp = @sbox[i]
        @sbox[i] = @sbox[j]
        @sbox[j] = temp
        k = @sbox[(@sbox[i] + @sbox[j]) % 256]
        
        cipherby = plaintext[a] ^ k
        cipher << cipherby
      end
      cipher
    end
    
    def encrypt(text)
      crypt(text)
    end

    def decrypt(text)
      crypt(text)
    end
    
    def self.generate_key(len=1024)
      # Defines a character string to pull letters and numbers from
      c = "AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz0123456789"
      key = ""
      # For the length of the key desired, randomly select a character and append to the key
      len.times do |i|
        key << c[rand(c.size)]
      end
      # Return the key
      key
    end
  end
end
