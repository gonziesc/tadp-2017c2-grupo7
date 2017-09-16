require 'tadb'
module Persistence
  attr_accessor :persistable_fields
  def has_one(type, hash)
    @name = hash[:named]
    attr_accessor(@name)
    self.persistable_fields ? self.persistable_fields.push(@name) : self.persistable_fields = [@name]
  end
end

class ActiveRecord
  extend Persistence

  def save!
    table = TADB::DB.table(self.class.name)
    hash = {}
    self.class.persistable_fields.each { |field| hash[field] = self.instance_eval("#{field}") }
    table.insert(hash)
  end
end