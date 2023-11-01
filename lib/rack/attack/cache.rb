# frozen_string_literal: true

require 'digest'

module Rack
  class Attack
    class Cache
      attr_accessor :prefix
      attr_reader :last_epoch_time

      def initialize
        self.store = ::Rails.cache if defined?(::Rails.cache)
        @prefix = 'rack::attack'
      end

      attr_reader :store

      def store=(store)
        @store =
          if (proxy = BaseProxy.lookup(store))
            proxy.new(store)
          else
            store
          end
      end

      def count(unprefixed_key, period, offset = 0)
        key, expires_in = key_and_expiry(unprefixed_key, period, offset)
        do_count(key, expires_in)
      end

      def read(unprefixed_key)
        enforce_store_presence!
        enforce_store_method_presence!(:read)

        store.read("#{prefix}:#{unprefixed_key}")
      end

      def write(unprefixed_key, value, expires_in)
        store.write("#{prefix}:#{unprefixed_key}", value, expires_in: expires_in)
      end

      def reset_count(unprefixed_key, period)
        key, _ = key_and_expiry(unprefixed_key, period)
        store.delete(key)
      end

      def delete(unprefixed_key)
        store.delete("#{prefix}:#{unprefixed_key}")
      end

      def reset!
        if store.respond_to?(:delete_matched)
          store.delete_matched("#{prefix}*")
        else
          raise(
            Rack::Attack::IncompatibleStoreError,
            "Configured store #{store.class.name} doesn't respond to #delete_matched method"
          )
        end
      end

      private

      def key_and_expiry(unprefixed_key, period, offset = 0)
        @last_epoch_time = Time.now.to_i
        time_with_offset = @last_epoch_time + offset
        period_number = (time_with_offset / period).to_i
        time_into_period = time_with_offset % period
        # Add 1 to expires_in to avoid timing error: https://github.com/rack/rack-attack/pull/85
        expires_in = period - time_into_period + 1
        ["#{prefix}:#{period_number}:#{unprefixed_key}", expires_in]
      end

      def do_count(key, expires_in)
        enforce_store_presence!
        enforce_store_method_presence!(:increment)

        result = store.increment(key, 1, expires_in: expires_in)

        # NB: Some stores return nil when incrementing uninitialized values
        if result.nil?
          enforce_store_method_presence!(:write)

          store.write(key, 1, expires_in: expires_in)
        end
        result || 1
      end

      def enforce_store_presence!
        if store.nil?
          raise Rack::Attack::MissingStoreError
        end
      end

      def enforce_store_method_presence!(method_name)
        if !store.respond_to?(method_name)
          raise(
            Rack::Attack::MisconfiguredStoreError,
            "Configured store #{store.class.name} doesn't respond to ##{method_name} method"
          )
        end
      end
    end
  end
end
