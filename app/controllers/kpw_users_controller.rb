class KpwUsersController < ApplicationController
  authorize :authenticate, :find_by_token, :enter, :public
  authorize :show, :user

  def authenticate
    return HESResponder("Email and password are required.", 422) if params[:email].to_s.strip.empty? || params[:password].to_s.strip.empty?

    # find user in kpwalk database where email = params[:email]
    sql = User.get_kpwalk_authenticate_sql(params[:email])

    potential_kpw_users = User.connection.select_all(sql)
    potential_kpw_users.each do |row|
      password = decrypt(Base64.decode64(row['password'])).downcase
      if password==params[:password].downcase && !row['gokp_token'].empty?
        if @promotion.users.count(:all,:conditions=>"kpwalk_user_id = #{User.sanitize(row['user_id'])}").zero?
          params[:token] = row['gokp_token']
          find_by_token
          return
        else
          return HESResponder("'#{params[:email]}' is already linked to another participant.", 422)
        end
      end
    end

    # if we got this far, there wasn't a match
    return HESResponder("Email or password is incorrect.",401)
  end

  def find_by_token
    # find user in kpwalk database where gokp_token = params[:token]
    #   - if so, proceed
    #   - if not, return nothing
    hash = User.get_kpwalk_data_from_token(params[:token])
    if hash 
      render :json=>hash
    else
      return HESResponder("User not found.", 404)
    end
  end

  def show
    # params[:id] is THIS APP's user_id
    if @current_user.master? || @current_user.id == params[:id].to_i
      user = @current_user.master? ? User.find(params[:id]) : @current_user
      hash = User.get_kpwalk_data_from_user_id(user.kpwalk_user_id)
      if hash 
        render :json=>hash
      else
        return HESResponder("User not found.", 404)
      end
    else
      return HESResponder("You may not view this user.", "DENIED")
    end
  end

  def enter
    # params[:token] is the kpwalk user's token; pass it through
    # but first see if there is a user in this promotion where kpwalk_user_id = that token's user_id
    #   - if so, then this is a replay, so return nothing
    #   - otherwise, store the token in a session cookie so the UI can pick it up
    id = User.get_kpwalk_user_id_from_token(params[:token])
    token = nil # ensure it gets cleared if need be (it may already be set!)
    if id
      if @promotion.users.count(:all,:conditions=>"kpwalk_user_id = #{User.sanitize(id)}").zero?
        token = params[:token]
      end
    end
    if token
      cookies[:kpwalk_token] = token
    else
      cookies.delete :kpwalk_token
    end
    redirect_to '/'
  end

  :private
  # mostly copied and pasted from kp walk
  KPWALK_AES_KEY = '4659cbf6d4f39bc9c5f81a03e4534636a51a08b20a333132f2a199a4957d2ec24d19ac2ae8e53453e3702a7d70967e8d20754d5644b6b02a6701b6306fdbb69c'
  KPWALK_AES_IV = '61ca71d2f5e0b341d003b87c2575e79ada2fdefe'
  KPWALK_AES_CIPHER = 'AES-256-CBC'

  def decrypt(data)     
    return data.nil? ? '' : _crypt(data,KPWALK_AES_KEY,KPWALK_AES_IV,KPWALK_AES_CIPHER,true)
  end
  
  def _crypt(data,key,iv,cipher_type,decrypt)
    aes = OpenSSL::Cipher::Cipher.new(cipher_type)
    if decrypt
      aes.decrypt
    else
      aes.encrypt            
    end
    aes.key = key
    aes.iv = iv if iv != nil 
    aes.update(data) + aes.final    
  end

end
