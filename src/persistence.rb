require 'tadb'
module Boolean end
class TrueClass; include Boolean; end
class FalseClass; include Boolean; end

module ClassPersistence

  attr_accessor :own_persistable_fields

  def db
    TADB::DB.table(self.name)
  end

  def has_one(type, hash)
    @own_persistable_fields ||= {}
    name = hash[:named]
    attr_accessor(name)
    @own_persistable_fields[name]=type
  end

  ## ----------------------------------------------------------------------------Punto 2--------------------------------

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
    if symbol.to_s.start_with?('find_by_')
      self.search_using symbol, *args, &block
    else
      super symbol, *args, &block
    end
  end

  # Logic for this method MUST match that of the detection in method_missing
  def respond_to_missing?(method_name, include_private = false)
    method_name.to_s.start_with?('find_by_') || super
  end

  def search_using(symbol, *args, &block)
    method_name = symbol.to_s.tap{|s| s.slice!('find_by_')}
    if self.instance_methods.include?(method_name.to_sym) and self.instance_method(method_name).arity == 0
      self.all_instances.select{|instance| instance.send(method_name) == args.first}
    else
      raise(" Falla! No existe el mensaje porque #{method_name} no esta definido o recibe args.")
    end
  end

  ## ----------------------------------------------------------------------------Punto 3--------------------------------

  def persistable_fields
    (@own_persistable_fields || {}).merge(self.included_modules_persistable_fields).merge(self.superclass_persistable_fields)
  end

  def included_modules_persistable_fields
    mods = self.included_modules.select{|mod| mod.respond_to? :persistable_fields}
    mods.inject({}) {|hash, mod| hash.merge(mod.persistable_fields)}
  end

  def superclass_persistable_fields
    self.superclass.respond_to?(:persistable_fields) ? self.superclass.persistable_fields : {}
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
      hash[name] = self.persistable_object_for name
    end
    if @id
      hash[:id]= @id
      self.forget! ##ASCO, solo lo hago para mantener el id porque la interfaz de db no permite update
    end
    return hash
  end

  def save!
    self.validate!
    @id = self.db.insert(self.persistable_hash)
  end

  def refresh!
    if @id
      self.persisted_hash.each do |name, value|
        self.instance_variable_set("@#{name}", self.persisted_object_named_value(name,value))
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

  ## ----------------------------------------------------------------------------Punto 3--------------------------------

  def persistable_object_for(name)
    var = self.instance_variable_get("@#{name}")
    if var.respond_to? :save!
      var.save!
    else
      var
    end
  end

  def persisted_object_named_value(name, value)
    klass = persistable_fields[name]
    if klass.respond_to? :find_by_id
        klass.find_by_id(value)
    else
      value
    end
  end

  ## ----------------------------------------------------------------------------Punto 4--------------------------------

  def validate!
    self.validate_type(name, type)
    self.validate_no_blank
    self.validate_from
    self.validate_to
    self.validate_validate
  end

  def validate_block_for(&block)

  end

  def validateType
    self.persistable_fields.each do |name, type|
      if not self.instance_variable_get("@#{name}").is_a? type
        raise("El atributo @#{name} deberia ser de tipo #{type}")
      end
    end
  end
end

class Class

  def make_persistable
    self.extend(ClassPersistence)
    self.include(InstancePersistence)
  end

end
