require 'rspec'
require_relative("fixture.rb")

describe "persistence" do
  fixture = Fixture.new
  let!(:person) {fixture.person}

  describe "creating a persistable person" do
    it "Should have persistable attributes" do
      expect(person).to respond_to(:first_name)
      expect(person).to respond_to(:last_name)
      expect(person).to respond_to(:age)
    end

    it "Should not have other attributes" do
      expect(person).not_to respond_to(:saraza)
    end
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

  it "Should raise exception because of no saving" do
    person.first_name = "asd"
    expect(person.refresh!).to raise_exception("Este objeto no tiene id!")
  end

end