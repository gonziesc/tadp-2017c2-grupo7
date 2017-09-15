require 'tadb'
module PERSISTENCE

  def has_one(type, hash)
    @name = hash[:named]
    attr_accessor(@name)
  end
  def save!

  end
end