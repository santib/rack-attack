# frozen_string_literal: true

require_relative "../spec_helper"
require "timecop"

describe "postrequest" do
  class PostRequestMiddleware
    FILTERS = [
      ->(request, condition = nil) do
        Rack::Attack::Fail2Ban.filter(request.ip, maxretry: 2, findtime: 30, bantime: 60) { condition }
      end
    ]

    def initialize(app)
      @app = app
    end

    def call(env)
      status, headers, body = @app.call(env)
      request = Rack::Attack::Request.new(env)
      FILTERS.each do |filter|
        filter.call(request, status == 404)
      end
      [status, headers, body]
    end
  end

  def app
    Rack::Builder.new do
      # Use Rack::Lint to test that rack-attack is complying with the rack spec
      use Rack::Lint
      # Intentionally added twice to test idempotence property
      use Rack::Attack
      use Rack::Attack
      use Rack::Lint
      use PostRequestMiddleware

      run lambda { |env|
        if env['PATH_INFO'] == '/not_found'
          [404, {}, ['Not Found']]
        else
          [200, {}, ['Hello World']]
        end
      }
    end.to_app
  end

  before do
    PostRequestMiddleware::FILTERS.each do |filter|
      Rack::Attack.blocklist do |request|
        filter.call(request)
      end
    end
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
  end

  it "returns OK for many requests with 200 status" do
    get "/"
    assert_equal 200, last_response.status

    get "/"
    assert_equal 200, last_response.status
  end

  it "returns OK for few requests with 404 status" do
    get "/not_found"
    assert_equal 404, last_response.status

    get "/not_found"
    assert_equal 404, last_response.status
  end

  it "forbids all access after reaching maxretry limit" do
    get "/not_found"
    assert_equal 404, last_response.status

    get "/not_found"
    assert_equal 404, last_response.status

    get "/not_found"
    assert_equal 403, last_response.status

    get "/"
    assert_equal 403, last_response.status
  end
end
