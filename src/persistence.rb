require 'tadb'
require_relative './boolean.rb'

module Persistence

  def self.included (base)
    base.extend ClassPersistence
    base.include InstancePersistence
  end

  module ClassPersistence
    attr_accessor :persistible_fields

    def descendants
      ObjectSpace.each_object(Class).select { |klass| klass < self }
    end

    def has_one (type, hash)
      @persistible_fields ||= []
      if self.respond_to? "superclass" and self.superclass.instance_variable_get(:@persistible_fields)
        superclass.instance_variable_get(:@persistible_fields).each {|field| @persistible_fields << field}
      end
      self.included_modules.each {|oneModule| define_module_persistible_fields oneModule}
      @persistible_fields << (define_persistible_field hash[:named], type)
    end

      def define_module_persistible_fields (oneModule)
        if oneModule.respond_to? "persistible_fields"
          oneModule.persistible_fields.each {|field| @persistible_fields << field}
        end
      end


    def has_many (type, hash)
      has_one type, hash
    end

    def define_persistible_field (name, type)
      attr_accessor(name)
      {name: name, type: type}
    end

    def all_instances
      instances = []
      table = TADB::DB.table(self.name)
      table.entries.each { |instance| instances << (create_new_instance instance) }
      descendants.each { |descendant| instances.concat(descendant.all_instances) }
      instances
    end

    def create_new_instance (attributes)
      instance = self.new
      @persistible_fields.each { |field| initialize_by_type instance, field[:name], field[:type], attributes }
      instance.instance_variable_set("@id", attributes[:id])
      instance
    end

    def initialize_by_type (instance, name, type, attributes)
      value = attributes[name]
      if is_a_primitive_type? (type.to_s)
        instance.instance_variable_set("@#{name}", value)
      else if value.is_a? String and value.start_with? self.name
             many_table = TADB::DB.table(value)
             has_many_instances = many_table.entries().select {|entry| entry[:self_id] == attributes[:id]}
             real_instances = []
             has_many_instances.each {|instance| real_instances << (type.find_by_id(instance[:foreign_key]).first)}
             instance.instance_variable_set("@#{name}", real_instances)
           else
             has_one_instance = type.find_by_id(value).first
             instance.instance_variable_set("@#{name}", has_one_instance)
           end
      end
    end

    def is_a_primitive_type? (type)
      type == "String" or type == "Boolean" or type == "Numeric"
    end

    def method_missing(sym, *args, &block)
      method = sym.to_s
      if method.start_with? 'find_by'
        instance_method = method[8..-1]
        find_by instance_method, args[0]
      else
        super(sym, *args, &block)
      end
    end

    private

    def find_by (instance_method, arg)
      if self.method_defined? instance_method and self.instance_method(instance_method).arity == 0
        self.all_instances.select {|instance| instance.send(instance_method) == arg}
      else
        raise("El metodo no existe o tiene parametros")
      end
    end

  end

  module InstancePersistence
    attr_accessor :table, :id

    def initialize
      @table = TADB::DB.table(self.class.name)
      @id = nil
    end

    def save!
      hash = {}
      self.class.persistible_fields.each { |field| hash.merge!(save_field field) }
      id = table.insert(hash)
      self.class.persistible_fields.select { |field| self.instance_variable_get("@#{field[:name]}").is_a? Array }
          .each { |field| create_hash_for_many field[:name], id }
      @id = id
    end

    def save_field (field)
      value = self.instance_variable_get("@#{field[:name]}")
      if is_a_primitive_type? value
        { field[:name] => value }
      else if value.is_a? Array
             {field[:name] => self.class.name + "_" + field[:name].to_s}
           else
             value.save!
             { field[:name] => value.id }
           end
      end
    end

    def create_hash_for_many (name, selfId)
      list = self.instance_variable_get("@#{name}")
      table_name = self.class.name + "_" + name.to_s
      many_table = TADB::DB.table(table_name)
      ids = []
      list.each { |object| ids << (object.save!) }
      ids.each {|id| many_table.insert(key_for_many id, selfId)}
    end

    def key_for_many (id, selfId)
      {"foreign_key" => id, "self_id" => selfId}
    end

    def is_a_primitive_type? value
      value.is_a? String or value.is_a? Numeric or value.is_a? Boolean
    end

    def refresh!
      if @id
        instance = @table.entries.find{ |i| i[:id] == @id }
        self.class.persistible_fields.each { |field| refresh_field field, instance}
      else
        raise("Este objeto no tiene id!")
      end
    end

    def refresh_field (field, instance)
      value = instance[field[:name]]
      actualValue =  self.instance_variable_get("@#{field[:name]}")
      if is_a_primitive_type? actualValue
        self.instance_variable_set("@#{field[:name]}", value)
      else if actualValue.is_a? Array
             actualValue.each {|obj| obj.refresh!}
           else
             actualValue.refresh!
           end
      end
    end

    def forget!
      @table.delete(@id)
      remove_instance_variable(:@id)
    end

  end
end