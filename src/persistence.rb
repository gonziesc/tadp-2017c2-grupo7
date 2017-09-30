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

  def all_instances
    self.db.entries.collect {|hash| self.instance_from hash[:id]}
  end

  def instance_from(id)
    instance = self.new
    instance.instance_variable_set('@id', id)
    instance.refresh!
    return instance
  end

  def method_missing(symbol, *args, &block)
    if symbol.to_s.start_with?('search_by_')
      self.search_using symbol, *args, &block
    else
      super symbol, *args, &block
    end
  end

  # Logic for this method MUST match that of the detection in method_missing
  def respond_to_missing?(method_name, include_private = false)
    method_name.to_s.start_with?('search_by_') || super
  end

  def search_using(symbol, *args, &block)
    method_name = symbol.to_s.tap{|s| s.slice!('search_by_')}
    if self.instance_methods.include?(method_name.to_sym) and self.instance_method(method_name).arity == 0
      self.all_instances.select{|instance| instance.send(method_name) == args.first}
    else
      raise(" Falla! No existe el mensaje porque #{method_name} no esta definido o recibe args.")
    end
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
      raise('Falla! Este objeto no tiene id!')
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
