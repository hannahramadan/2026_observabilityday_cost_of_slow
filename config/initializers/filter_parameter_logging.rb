# Be sure to restart your server when you modify this file.

# Configure parameters to be partially matched (e.g. passw matches password) and filtered from the log file.
# Use this to limit dissemination of sensitive information.
# See the ActiveSupport::ParameterFilter documentation for supported notations and behaviors.
#
# The default list has :token, which also matches the OpenTelemetry attributes
# gen_ai.usage.input_tokens / gen_ai.usage.output_tokens. Anything that applies this filter
# to those keys would silently replace the token COUNTS with "[FILTERED]". The regexp below
# keeps filtering real secrets (api_token, auth_token, ...) but exempts exactly those two keys.
TOKEN_SECRET = /(?<!gen_ai\.usage\.input_)(?<!gen_ai\.usage\.output_)token/i

Rails.application.config.filter_parameters += [
  :passw, :email, :secret, TOKEN_SECRET, :_key, :crypt, :salt, :certificate, :otp, :ssn, :cvv, :cvc
]
