require 'tadb'
module Boolean end
class TrueClass; include Boolean; end
class FalseClass; include Boolean; end

module ClassPersistence

  attr_accessor :persistable_fields

  def db
    TADB::DB.table(self.name)
  end

  def has_one(type, hash)
    @persistable_fields ||= {}
    name = hash[:named]
    attr_accessor(name)
    @persistable_fields[name]=type
  end

end

module InstancePersistence

  attr_accessor :id

  def initialize
    @id = nil
  end

  def db
    self.class.db
  end

  def persistable_fields
    self.class.persistable_fields
  end

  def persistable_hash
    hash = {}
    self.persistable_fields.each do |name, type|
      hash[name] = self.instance_variable_get("@#{name}")
    end
    if @id
      hash[:id]= @id
      self.forget! ##ASCO, solo lo hago para mantener el id porque la interfaz de db no permite update
    end
    return hash
  end

  def save!
    @id = self.db.insert(self.persistable_hash)
  end

  def refresh!
    if @id
      self.persisted_hash.each do |name, value|
        self.instance_variable_set("@#{name}", value)
      end
    else
      raise("Falla! Este objeto no tiene id!")
    end
  end

  def forget!
    if @id
      self.db.delete(@id)
      @id = nil
      end
  end

  def persisted_hash
    self.db.entries.detect {|hash| hash[:id] == @id}
  end

end

class Class

  def make_persistable
    self.extend(ClassPersistence)
    self.include(InstancePersistence)
  end

end
