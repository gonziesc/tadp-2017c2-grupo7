module ClassPersistence
  attr_accessor :sticky_fields
  def sticky_fields
    @sticky_fields ||= []
  end

  def superclass_is_sticky?
    self.respond_to? "superclass" and superclass.respond_to?("sticky_fields")
  end

  def set_superclass_sticky_fields
    if superclass_is_sticky?
      sticky_fields.concat(superclass.sticky_fields)
    end
  end

  def set_module_sticky_fields
    mods = included_modules.select{|mod| mod.respond_to?("sticky_fields")}
    sticky_fields.concat(mods.flat_map{|mod| mod.sticky_fields})
  end

  def new
    instance = super
    set_default_for_instance instance
    instance
  end

  def set_default_for_instance (instance)
    sticky_fields.each {|field| field.set_default(instance)}
  end

  def table
    @table ||= TADB::DB.table(name)
  end

  def field_exists?(name)
    return sticky_fields.any? {|field| field.name == name}
  end

  def change_field_type(name, type)
    sticky_fields.find{|field| field.name == name}.type = type
  end

  def has(new_field, type)
    set_superclass_sticky_fields
    if(field_exists? new_field.name)
      change_field_type(new_field.name, type)
    else
      attr_accessor(new_field.name)
      sticky_fields << new_field
    end
  end

  def has_one (type, hash)
    new_field = primitive?(type) ? SimpleField.new(type, hash) : ComplexField.new(type, hash)
    has(new_field, type)
  end

  def has_many(type, hash)
    new_field=  ManyField.new(type, hash)
    has(new_field, type)
  end

  def validate!(instance)
    sticky_fields.each {|field| (field.validate!(instance)) }
  end

  def save!(instance)
    validate!(instance)
    instance.id = table.upsert(instance.to_hash)
  end

  def forget!(instance)
    table.delete(instance.id)
    instance.id = nil
  end

  def refresh!(instance)
    sticky_fields.each {|field| field.refresh!(instance)}
  end

  def to_hash(instance)
    sticky_fields.inject({}) {|hash, field| hash.merge(field.save!(instance))}
  end

  def all_instances
    set_module_sticky_fields
    instances = table.entries.map {|row| create_new_instance(row)}
    descendants.each { |descendant| instances.concat(descendant.all_instances) }
    instances
  end

  def descendants
    ObjectSpace.each_object(Class).select{|klass| klass < self}
  end

  def create_new_instance (attributes)
    instance = self.new
    sticky_fields.each {|field| field.assign(instance, attributes[field.name])}
    instance.id = attributes[:id]
    instance
  end

  def method_missing(sym, *args, &block)
    method = sym.to_s
    if query_method?(method)
      find_by(queryable_attribute(method), args.first)
    else
      super(sym, *args, &block)
    end
  end

  def query_method?(name)
    name.start_with?('find_by_')
  end

  def getFromDB(instance)
    table.entries.find{ |i| i[:id] == instance.id }
  end

  def queryable_attribute(method)
    method[8..-1]
  end

  def find_by(attribute_name, expected_value)
    if self.method_defined? attribute_name and self.instance_method(attribute_name).arity == 0
      all_instances.select {|instance| instance.send(attribute_name) == expected_value}
    else
      raise("El metodo no existe o tiene parametros")
    end
  end

  def primitive?(type)
    type.equal?(String) || type.equal?(Numeric) || type.equal?(Boolean)
  end

end