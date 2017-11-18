package tp

import TAdeQuest._

class TAdeQuestFixture {

  def unHeroeGuerrero() {
    var trabajo = Guerrero
    var stats = new Stats(0, 0, 0, 0)
    new Heroe(stats, Some(trabajo), new Inventario(new UnaMano(None, None), None, None, List()))
  }

}