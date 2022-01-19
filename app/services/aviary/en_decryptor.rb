# EnDecryptor
#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
class EnDecryptor
  @alg = 'aes-128-cbc'
  @key = Rails.application.secrets.secret_key_base[0..15] if Rails.application.secrets.secret_key_base.present? ## 32 Characters
  @iv = Rails.application.secrets.secret_key_base[0..15] if Rails.application.secrets.secret_key_base.present? ## 16 characters

  def self.encrypt(des_text)
    des = OpenSSL::Cipher::Cipher.new(@alg)
    des.encrypt
    des.key = @key
    des.iv = @iv
    result = des.update(des_text)
    result << des.final
    Base64.urlsafe_encode64(result)
  end

  def self.decrypt(des_text)
    des = OpenSSL::Cipher::Cipher.new(@alg)
    des.decrypt
    des.key = @key
    des.iv = @iv
    result = des.update(Base64.urlsafe_decode64(des_text))
    result << des.final
    result
  end
end
