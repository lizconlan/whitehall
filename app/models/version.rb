class Version < ActiveRecord::Base
  belongs_to :item, polymorphic: true
  validates_presence_of :event
  attr_accessible :item_type, :item_id, :event, :whodunnit, :state

  def self.with_item_keys(item_type, item_id)
    scoped(conditions: {item_type: item_type, item_id: item_id})
  end

  scope :preceding, lambda { |version|
    where(["id < ?", version.id]).order("id DESC")
  }

  def sibling_versions
    self.class.with_item_keys(item_type, item_id)
  end

  def previous
    sibling_versions.preceding(self).first
  end

  def user
    if whodunnit
      User.find(whodunnit)
    else
      nil
    end
  end
end
