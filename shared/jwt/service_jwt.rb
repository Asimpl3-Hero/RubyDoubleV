require 'jwt'
require 'securerandom'
require_relative 'jwt_logger'

module ServiceJWT
  SECRET_KEY = ENV['JWT_SECRET_KEY'] || raise("JWT_SECRET_KEY not set")
  ALGORITHM = 'HS256'
  EXPIRATION_MINUTES = 5

  def self.generate(service_name:, additional_claims: {})
    payload = {
      iss: service_name,
      iat: Time.now.to_i,
      exp: Time.now.to_i + (EXPIRATION_MINUTES * 60),
      jti: SecureRandom.uuid
    }.merge(additional_claims)

    token = JWT.encode(payload, SECRET_KEY, ALGORITHM)

    # Log token generation
    JwtLogger.log_token_generation(service_name: service_name)

    token
  end

  def self.validate(token)
    decoded = JWT.decode(token, SECRET_KEY, true, { algorithm: ALGORITHM })
    payload = decoded[0]

    {
      valid: true,
      issuer: payload['iss'],
      issued_at: Time.at(payload['iat']),
      expires_at: Time.at(payload['exp']),
      claims: payload
    }
  rescue JWT::ExpiredSignature
    { valid: false, error: 'Token expirado' }
  rescue JWT::DecodeError => e
    { valid: false, error: "Token inválido: #{e.message}" }
  end

  def self.generate_for_current_service
    service_name = ENV['SERVICE_NAME'] || 'unknown-service'
    generate(service_name: service_name)
  end
end
