require "bundler/setup"
require "active_record"
require "minitest/autorun"
require 'database_cleaner'

require "has_messages"

module HasMessages
  module Test
    class << self
      def connect_to_db
        ActiveRecord::Base.establish_connection({
          :adapter => "sqlite3",
          :database => ":memory:",
          :encoding => "utf8"
        })
      end

      def disconnect_from_db
        ActiveRecord::Base.connection.disconnect!
      end

      def run_migrations
        HasMessages::Test::CreateMessages.migrate :up
        HasMessages::Test::CreateMessageRecipients.migrate :up
        HasMessages::Test::CreateUsers.migrate :up
      end
    end

    class CreateUsers < ActiveRecord::Migration
      def self.up
        create_table :users do |t|
          t.string :login, :null => false
        end
      end

      def self.down
        drop_table :users
      end
    end

    class CreateMessages < ActiveRecord::Migration
      def self.up
        create_table :messages do |t|
          t.references :sender, :polymorphic => true, :null => false
          t.text :subject, :body
          t.string :state, :null => false
          t.datetime :hidden_at
          t.string :type
          t.timestamps
        end
      end

      def self.down
        drop_table :messages
      end
    end

    class CreateMessageRecipients < ActiveRecord::Migration
      def self.up
        create_table :message_recipients do |t|
          t.references :message, :null => false
          t.references :receiver, :polymorphic => true, :null => false
          t.string :kind, :null => false
          t.integer :position
          t.string :state, :null => false
          t.datetime :hidden_at
        end
        add_index :message_recipients, [:message_id, :kind, :position], :unique => true
      end

      def self.down
        drop_table :message_recipients
      end
    end

    class User < ActiveRecord::Base
      has_messages
    end

    module Factory
      # Build actions for the model
      def self.build(model, &block)
        name = model.to_s.demodulize.underscore

        define_method("#{name}_attributes", block)
        define_method("valid_#{name}_attributes") {|*args| valid_attributes_for(model, *args)}
        define_method("new_#{name}")              {|*args| new_record(model, *args)}
        define_method("create_#{name}")           {|*args| create_record(model, *args)}
      end

      # Get valid attributes for the model
      def valid_attributes_for(model, attributes = {})
        name = model.to_s.demodulize.underscore
        send("#{name}_attributes", attributes)
        attributes.stringify_keys!
        attributes
      end

      # Build an unsaved record
      def new_record(model, *args)
        attributes = valid_attributes_for(model, *args)
        record = model.new(attributes)
        attributes.each {|attr, value| record.send("#{attr}=", value) }
        record
      end

      # Build and save/reload a record
      def create_record(model, *args)
        record = new_record(model, *args)
        record.save!
        record.reload
        record
      end

      build Message do |attributes|
        attributes[:sender] = create_user unless attributes.include?(:sender)
        attributes.reverse_merge!(
          :subject => 'New features',
          :body => 'Lots of new things to talk about... come to the meeting tonight to find out!',
          :created_at => Time.current + Message.count
        )
      end

      build MessageRecipient do |attributes|
        attributes[:message] = create_message unless attributes.include?(:message)
        attributes[:receiver] = create_user(:login => 'me') unless attributes.include?(:receiver)
        attributes.reverse_merge!(
          :kind => 'to'
        )
      end

      build HasMessages::Test::User do |attributes|
        attributes.reverse_merge!(
          :login => 'admin'
        )
      end
    end

    module Callbacks
      def before_setup
        super
        DatabaseCleaner.start
      end

      def after_teardown
        DatabaseCleaner.clean
        super
      end
    end
  end
end

Minitest::Test.class_eval do
  include HasMessages::Test::Factory
  include HasMessages::Test::Callbacks
end

DatabaseCleaner.strategy = :transaction

HasMessages::Test.connect_to_db
HasMessages::Test.run_migrations

# uncomment this line if you need more logs
# require "logger"
# ActiveRecord::Base.logger = Logger.new($stdout)
