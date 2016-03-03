require 'spec_helper'

class DummyServer
  def join; end
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
          expect { described_class.config = {redis: nil, spaces: nil} }.to raise_error ":management_token configuration missing"
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
