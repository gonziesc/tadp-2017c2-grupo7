require_relative("../lib/persistence")

class Fixture
  def person
    person = Person.new
    person.first_name = "gonza"
    person.last_name = "esc"
    person.age = 20
    person.animal = animal
    person
  end

  def animal
    animal = Animal.new
    animal.first_name = "juno"
    animal.last_name = "esc"
    animal.age = 1
    animal
  end
end

class Animal
  include Persistence
  has_one String, named: :first_name
  has_one String, named: :last_name
  has_one Numeric, named: :age
end


class Person
  include Persistence
  has_one Animal, named: :animal
  has_one String, named: :first_name
  has_one String, named: :last_name
  has_one Numeric, named: :age
end




