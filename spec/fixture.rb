require_relative("../lib/persistence")

class Fixture
  def person
    person = Person.new
    person.first_name = "gonza"
    person.last_name = "esc"
    person.age = 20
    person
  end

end


class Person
  include Persistence
  has_one String, named: :first_name
  has_one String, named: :last_name
  has_one Numeric, named: :age
end




