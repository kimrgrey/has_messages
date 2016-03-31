# Represents a recipient on a message.  The kind of recipient (to, cc, or bcc) is
# determined by the +kind+ attribute.
#
# == States
#
# Recipients can be in 1 of 2 states:
# * +unread+ - The message has been sent, but not yet read by the recipient.  This is the *initial* state.
# * +read+ - The message has been read by the recipient
#
# == Interacting with the message
#
# In order to perform actions on the message, such as viewing, you should always
# use the associated event action:
# * +view+ - Marks the message as read by the recipient
#
# == Hiding messages
#
# Although you can delete a recipient, it will also delete it from everyone else's
# message, meaning that no one will know that person was ever a recipient of the
# message.  Instead, you can change the *visibility* of the message.  Messages
# have 1 of 2 states that define its visibility:
# * +visible+ - The message is visible to the recipient
# * +hidden+ - The message is hidden from the recipient
#
# The visibility of a message can be changed by running the associated action:
# * +hide+ -Hides the message from the recipient
# * +unhide+ - Makes the message visible again
class MessageRecipient < ActiveRecord::Base
  belongs_to :message
  belongs_to :receiver, :polymorphic => true

  validates :message_id, :presence => true
  validates :kind, :presence => true
  validates :state, :presence => true
  validates :receiver_id, :presence => true
  validates :receiver_type, :presence => true

  before_create :set_position
  before_destroy :reorder_positions

  # Make this class look like the actual message
  delegate :sender, :subject, :body, :recipients, :to, :cc, :bcc, :created_at, :to => :message

  scope :visible, -> { where(:hidden_at => nil) }

  # Defines actions for the recipient
  state_machine :state, :initial => :unread do
    # Indicates that the message has been viewed by the receiver
    event :view do
      transition :unread => :read, :if => :message_sent?
    end
  end

  # Defines actions for the visibility of the message to the recipient
  state_machine :hidden_at, :initial => :visible do
    # Hides the message from the recipient's inbox
    event :hide do
      transition all => :hidden
    end

    # Makes the message visible in the recipient's inbox
    event :unhide do
      transition all => :visible
    end

    state :visible, :value => nil
    state :hidden, :value => lambda {Time.now}, :if => lambda {|value| value}
  end

  # Forwards this message, including the original subject and body in the new
  # message
  def forward
    message = self.message.class.new(:subject => subject, :body => body)
    message.sender = receiver
    message
  end

  # Replies to this message, including the original subject and body in the new
  # message.  Only the original direct receivers are added to the reply.
  def reply
    message = self.message.class.new(:subject => subject, :body => body)
    message.sender = receiver
    message.to(sender)
    message
  end

  # Replies to all recipients on this message, including the original subject
  # and body in the new message.  All receivers (sender, direct, cc, and bcc) are
  # added to the reply.
  def reply_to_all
    message = reply
    message.to(to - [receiver] + [sender])
    message.cc(cc - [receiver])
    message.bcc(bcc - [receiver])
    message
  end

  private

  def message_sent?
    message.sent?
  end

  def set_position
    self.position = message.recipients.where(:kind => kind).maximum(:position).to_i + 1
  end

  def reorder_positions
    return if position.nil?
    pos = self.position
    update(:position => nil)
    MessageRecipient.where("message_id = ? AND kind = ? AND position > ?", message_id, kind, pos).update_all("position = (position - 1)")
  end
end
