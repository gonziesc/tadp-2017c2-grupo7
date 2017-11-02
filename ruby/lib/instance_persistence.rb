module InstancePersistence
  attr_accessor :id

  def initialize
    @id = nil
  end

  def save!
    define_singleton_method(:refresh!) {self.class.refresh!(self)}
    self.class.save!(self)
  end

  def refresh!
    raise 'Este objeto no tiene id!'
  end

  def forget!
    self.class.forget!(self)
  end

  def validate!
    self.class.validate!(self)
  end

  def getFromDB
    self.class.getFromDB(self)
  end

  def to_hash
    self.class.to_hash(self)
  end

end