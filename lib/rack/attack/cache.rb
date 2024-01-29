# frozen_string_literal: true

module Rack
  class Attack
    class Cache
      def self.default_store
        if Object.const_defined?(:Rails) && Rails.respond_to?(:cache)
          ::Rails.cache
        end
      end

      def initialize(store: self.class.default_store)
        self.store = store
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

      def count(key, expires_in)
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

      def read(key)
        enforce_store_presence!
        enforce_store_method_presence!(:read)

        store.read(key)
      end

      def write(key, value, expires_in)
        store.write(key, value, expires_in: expires_in)
      end

      def reset_count(key)
        store.delete(key)
      end

      def delete(key)
        store.delete(key)
      end

      def reset!
        if store.respond_to?(:delete_matched)
          store.delete_matched("#{Rack::Attack::Cache::KeyGenerator::PREFIX}*")
        else
          raise(
            Rack::Attack::IncompatibleStoreError,
            "Configured store #{store.class.name} doesn't respond to #delete_matched method"
          )
        end
      end

      private

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
