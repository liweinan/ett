class Comment < ActiveRecord::Base

  include ActsAsCommentable::Comment

  belongs_to :commentable, :polymorphic => true

  if Rails::VERSION::STRING < "4"
    default_scope :order => 'created_at ASC'
  else
    default_scope { order('created_at ASC') }
  end

  # NOTE: install the acts_as_votable plugin if you
  # want user to vote on the quality of comments.
  #acts_as_voteable

  # NOTE: Comments belong to a user
  belongs_to :user
  validates_presence_of :user_id

  validates_presence_of :comment

  if Rails::VERSION::STRING < "4"
    acts_as_textiled :comment
  end

  def is_older_than(time)
    time > self.created_at
  end

  def after_create
    Changelog.comment_added(self)
  end
end
