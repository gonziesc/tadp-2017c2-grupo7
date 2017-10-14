class Field
  attr_accessor :type, :name, :validations
  def initialize(type, hash)
    @type = type
    @name = hash[:named]
    @validations = hash.reject!{ |k| k == :named }
  end

  def field(instance)
    instance.send(name)
  end

  def validate!(instance)
    @validations.each {|name, value| send(name, value, field(instance), instance)}
    validate_type(field(instance))
  end

  def validate (proc, value, instance)
    unless value.instance_eval(&proc)
      raise("Error de tipos")
    end
  end

  def validate_type(value)
    unless value.is_a? type
      raise("Error de tipos")
    end
  end

  def set_default(instance)
    if @validations.any? {|name, value| name.to_s == "default"}
      value = @validations[:default]
      instance.send("#{@name}=", value)
    end
  end

  def default (validation, value, instance)
    if value == nil
      instance.send("#{@name}=", validation)
    end
  end

end

class SimpleField < Field

  def no_blank (validation, value, instance)
    if value.is_a? Boolean and validation == true
      if value == nil or value == ""
        raise("Error de tipos")
      end
    end
  end

  def from (validation, value, instance)
    if value.is_a? Numeric
      if value < validation
        raise("Error de tipos")
      end
    end
  end

  def to (validation, value, instance)
    if value.is_a? Numeric
      if value > validation
        raise("Error de tipos")
      end
    end
  end


  def assign(instance, value)
    instance.tap do |this|
      this.send("#{name}=", value)
    end
  end

  def save! (instance)
    {name => field(instance)}
  end

  def refresh!(instance)
    instance.send("#{name}=", saved_value(instance))
  end

  def saved_value(instance)
    instance.class.find_by_id(instance.id).first.send(name)
  end

end

class ComplexField < Field

  def assign(instance, value)
    instance.tap do |this|
      this.send("#{name}=", type.find_by_id(value).first)
    end
  end

  def save! (instance)
    has_object = field(instance)
    id = has_object.save!
    {name => id}
  end

  def refresh!(instance)
    has_object = field(instance)
    has_object.refresh!
    instance.send("#{name}=", has_object)
  end

  def validate_type(value)
    super(value)
    value.validate!
  end

end

class ManyField < Field

  def assign(instance, value)
    instances = @ids.map {|id| type.find_by_id(id).first }
    instance.send("#{@name}=", instances)
  end

  def save! (instance)
    has_object = field(instance)
    @ids = has_object.map {|object| object.save!}
    table_name = instance.class.name + "_" + @name.to_s
    @table = TADB::DB.table(table_name)
    @ids.each {|id| @table.insert( {"foreign_key" => id})}
    hash = {}
    hash[name] = table_name
    hash
  end

  def refresh!(instance)
    has_object = field(instance)
    has_object.each {|object| object.refresh!}
    instance.send("#{@name}=", has_object)
  end

  def validate_type(array)
    unless array.all? {|object| object.is_a? type}
      raise("Error de tipos")
    end
    array.each{|object| object.validate!}
  end
end