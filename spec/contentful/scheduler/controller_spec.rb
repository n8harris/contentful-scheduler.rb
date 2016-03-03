require 'spec_helper'

describe Contentful::Scheduler::Controller do
  let(:server) { MockServer.new }
  let(:logger) { Contentful::Webhook::Listener::Support::NullLogger.new }
  let(:timeout) { 10 }
  let(:body) { {sys: { id: 'foo', space: { sys: { id: 'space_foo' } } }, fields: {} } }
  let(:queue) { ::Contentful::Scheduler::Queue.instance }
  subject { described_class.new server, logger, timeout }

  describe 'events' do
    [:create, :save, :unarchive].each do |event|
      it "creates or updates webhook metadata in publish queue on #{event}" do
        expect(queue).to receive(:update_or_create)

        request = RequestDummy.new("ContentfulManagement.Entry.#{event}", body)
        subject.respond(request, MockResponse.new).join
      end
    end

    [:delete, :unpublish, :archive, :publish].each do |event|
      it "deletes webhook metadata in publish queue on #{event}" do
        expect(queue).to receive(:remove)

        request = RequestDummy.new("ContentfulManagement.Entry.#{event}", body)
        subject.respond(request, MockResponse.new).join
      end
    end

    [:create, :save, :unarchive, :delete, :unpublish, :archive, :publish].each do |event|
      ['Asset', 'ContentType'].each do |kind|
        it "ignores #{kind} on #{event}" do
          expect(queue).not_to receive(:remove)
          expect(queue).not_to receive(:update_or_create)

          request = RequestDummy.new("ContentfulManagement.#{kind}.#{event}", body)
          subject.respond(request, MockResponse.new).join
        end
      end
    end
  end
end
