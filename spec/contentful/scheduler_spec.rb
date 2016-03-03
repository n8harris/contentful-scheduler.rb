require 'spec_helper'

class DummyServer
  def join; end
end

class DummyLogger
end

describe Contentful::Scheduler do
  let(:config) {
    {
      redis: {
        host: 'localhost',
        port: 12341,
        password: 'foobar'
      },
      spaces: {},
      management_token: 'foo'
    }
  }

  before :each do
    described_class.class_variable_set(:@@config, nil)
  end

  describe 'static methods' do
    describe '::config=' do
      describe 'failures' do
        it 'fails if :redis is not configured' do
          expect { described_class.config = {} }.to raise_error ":redis configuration missing"
        end

        it 'fails if :spaces are not configured' do
          expect { described_class.config = {redis: nil} }.to raise_error ":spaces configuration missing"
        end

        it 'fails if :management_token is not configured' do
          expect { described_class.config = {redis: nil, spaces: {example_space: {}}} }.to raise_error ":management_token missing for space: example_space"
        end
      end

      describe 'success' do
        it 'sets a resque redis config' do
          expect(Resque).to receive(:redis=).with(config[:redis])

          described_class.config = config
        end

        it 'sets global config' do
          described_class.config = config

          expect(described_class.config).to eq config
        end
      end
    end

    describe '::config' do
      it 'fetches the config' do
        expect(described_class.config).to eq nil

        allow(Resque).to receive(:redis=)

        described_class.config = config

        expect(described_class.config).to eq config
      end

      it ':port defaults to 32123' do
        described_class.config = config

        expect(described_class.config[:port]).to eq 32123
      end

      it ':port to ENV["PORT"] if available and :port not set' do
        ENV['PORT'] = '8000'

        described_class.config = config

        expect(described_class.config[:port]).to eq 8000

        ENV['PORT'] = nil
      end

      it ':port can be set' do
        described_class.config = {port: 10101}.merge(config)

        expect(described_class.config[:port]).to eq 10101
      end

      it ':logger can be set' do
        described_class.config = {logger: DummyLogger.new}.merge(config)

        expect(described_class.config[:logger]).to be_a DummyLogger
      end

      it ':logger defaults to NullLogger' do
        described_class.config = config

        expect(described_class.config[:logger]).to be_a ::Contentful::Webhook::Listener::Support::NullLogger
      end

      it ':endpoint can be set' do
        described_class.config = {endpoint: '/foobar'}.merge(config)

        expect(described_class.config[:endpoint]).to eq '/foobar'
      end

      it ':endpoint defaults to "/scheduler"' do
        described_class.config = config

        expect(described_class.config[:endpoint]).to eq '/scheduler'
      end
    end

    describe '::start' do
      it 'fails when not configured' do
        expect { described_class.start }.to raise_error "Scheduler not configured"
      end

      it 'runs when config set' do
        allow(Resque).to receive(:redis=)
        expect(::Contentful::Webhook::Listener::Server).to receive(:start) { DummyServer.new }

        described_class.config = config
        described_class.start
      end

      it 'can be configured by a block' do
        allow(Resque).to receive(:redis=)
        expect(::Contentful::Webhook::Listener::Server).to receive(:start) { DummyServer.new }

        described_class.start do |config|
          config[:redis] = {}
          config[:spaces] = {}
          config[:management_token] = ''
        end
      end
    end
  end
end
