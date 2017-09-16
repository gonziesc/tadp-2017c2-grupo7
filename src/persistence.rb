require 'tadb'
module Persistence
  attr_accessor :persistable_fields
  def has_one(type, hash)
    @name = hash[:named]
    attr_accessor(@name)
    self.persistable_fields ? self.persistable_fields.push(@name) : self.persistable_fields = [@name]
  end
end

class Class
  extend Persistence

end