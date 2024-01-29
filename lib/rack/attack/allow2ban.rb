# frozen_string_literal: true

module Rack
  class Attack
    class Allow2Ban < Fail2Ban
      class << self
        protected

        def key_prefix
          'allow2ban'
        end

        # everything is the same here except we only return true
        # (blocking the request) if they have tripped the limit.
        def fail!(discriminator, bantime, findtime, maxretry)
          key_generator = count_key_generator(discriminator, findtime)
          count = cache.count(key_generator.key, key_generator.expires_in)
          if count >= maxretry
            ban!(discriminator, bantime)
          end
          # we may not block them this time, but they're banned for next time
          false
        end
      end
    end
  end
end
