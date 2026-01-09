# frozen_string_literal: true

# OpenSSL 3.x enables CRL (Certificate Revocation List) checking by default.
# This causes SSL errors when servers don't provide CRL distribution points.
# Disable CRL checking in development to avoid local SSL issues.

# THIS MONKEY PATCH FOR DEVELOPMENT ONLY
if Rails.env.development?
  module HTTP
    class Client
      original_perform = instance_method(:perform)

      define_method(:perform) do |request, options|
        unless options.ssl_context
          ctx = OpenSSL::SSL::SSLContext.new
          ctx.verify_mode = OpenSSL::SSL::VERIFY_PEER
          store = OpenSSL::X509::Store.new
          store.set_default_paths
          ctx.cert_store = store
          options = options.with_ssl_context(ctx)
        end
        original_perform.bind(self).call(request, options)
      end
    end
  end
end
