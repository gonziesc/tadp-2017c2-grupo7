require 'rspec'
require_relative("fixture.rb")

describe "persistence" do
  fixture = Fixture.new
  let!(:person) {fixture.person}

    after(:each) do
      if File.exist? "./db/Person"
       File.delete("./db/Person")
      end
    end

    it "Should have persistable attributes" do
      expect(person).to respond_to(:first_name)
      expect(person).to respond_to(:last_name)
      expect(person).to respond_to(:age)
    end

    it "Should not have other attributes" do
      expect(person).not_to respond_to(:saraza)
    end

  it "Should have persistable attributes" do
    expect(person.first_name).to eq("gonza")
    expect(person.age).to eq(20)
  end

  it "Should have id after save" do
    person.save!
    expect(person).to respond_to(:id)
  end

  it "Should change attribute after refreshing" do
    person.save!
    person.first_name = "asd"
    person.refresh!
    expect(person.first_name).to eq("gonza")
  end

  # it "Should raise exception because of no saving" do
  #  person.first_name = "asd"
  #  expect(person.refresh!).to raise("Este objeto no tiene id!")
  # end

  it "Should forget id after forgetting" do
    person.save!
    person.forget!
    expect(person.id).to eq(nil)
  end

  it "Should bring 2 instances with all instances" do
    person.save!
    anotherPerson = fixture.person
    anotherPerson.save!
    personThatWontSave = fixture.person
    personThatWontSave.first_name = "nono"
    expect(Person.all_instances.size).to eq(2)
  end

  it "Should understand variables with all instances" do
    person.save!
    anotherPerson = fixture.person
    anotherPerson.save!
    expect(Person.all_instances.first).to respond_to(:first_name)
  end

  describe "find by" do

    before(:each) do
      person.save!
      anotherPerson = fixture.person
      anotherPerson.save!
      otherPerson = fixture.person
      otherPerson.save!
    end

    it "Should filter by first name bringing 3 instances" do
      expect(Person.find_by_first_name("gonza").size).to eq(3)
    end

    it "Should filter by first name bringing 0 instances" do
      expect(Person.find_by_first_name("asd").size).to eq(0)
    end

    it "Should filter by id bringing 1 instances" do
      expect(Person.find_by_id(person.id).size).to eq(1)
    end
  end

end