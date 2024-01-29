# frozen_string_literal: true

module Rack
  class Attack
    class Fail2Ban
      class << self
        def filter(discriminator, options)
          bantime   = options[:bantime]   or raise ArgumentError, "Must pass bantime option"
          findtime  = options[:findtime]  or raise ArgumentError, "Must pass findtime option"
          maxretry  = options[:maxretry]  or raise ArgumentError, "Must pass maxretry option"

          if banned?(discriminator)
            # Return true for blocklist
            true
          elsif yield
            fail!(discriminator, bantime, findtime, maxretry)
          end
        end

        def reset(discriminator, options)
          findtime = options[:findtime] or raise ArgumentError, "Must pass findtime option"
          cache.reset_count(count_key_generator(discriminator, findtime).key)
          # Clear ban flag just in case it's there
          cache.delete(ban_key_generator(discriminator).key)
        end

        def banned?(discriminator)
          cache.read(ban_key_generator(discriminator).key) ? true : false
        end

        protected

        def key_prefix
          'fail2ban'
        end

        def fail!(discriminator, bantime, findtime, maxretry)
          key_generator = count_key_generator(discriminator, findtime)
          count = cache.count(key_generator.key, key_generator.expires_in)
          if count >= maxretry
            ban!(discriminator, bantime)
          end

          true
        end

        private

        def ban!(discriminator, bantime)
          cache.write(ban_key_generator(discriminator).key, 1, bantime)
        end

        def cache
          Rack::Attack.cache
        end

        def count_key_generator(discriminator, findtime)
          Rack::Attack::Cache::ExpirableKeyGenerator.new("#{key_prefix}:count", discriminator, findtime)
        end

        def ban_key_generator(discriminator)
          Rack::Attack::Cache::KeyGenerator.new("#{key_prefix}:ban", discriminator)
        end
      end
    end
  end
end
