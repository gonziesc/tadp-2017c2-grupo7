package tp

import org.junit.Assert.assertEquals
import org.junit.Test

import TAdeQuest._

class TAdeQuestTest {

  def unHeroeGuerrero(): Heroe = {
    var trabajo = Guerrero
    var stats = new Stats(100, 200, 100, 20)
    new Heroe(stats, Some(trabajo), new Inventario(new UnaMano(None, None), None, None, List()))
  }

  def unHeroeMago(): Heroe = {
    var trabajo = Mago
    var stats = new Stats(50, 50, 150, 100)
    new Heroe(stats, Some(trabajo), new Inventario(new UnaMano(None, None), None, None, List()))
  }

  def unEquipo(): Equipo = {
    new Equipo(List(unHeroeGuerrero(), unHeroeMago()), 10000, "Los Mejores")
  }

  def recompensaPozo1(equipo: Equipo): Equipo = {
    equipo.copy(equipo.heroes, equipo.pozo + 1000, equipo.nombre)
  }
  
  def recompensaPozo2(equipo: Equipo): Equipo = {
    equipo.copy(equipo.heroes, equipo.pozo + 5000, equipo.nombre)
  }

  object MisionForzarYMatar extends Mision() {
    override def tareas: List[Tarea] = {
      List(forzarPuerta(), pelearConMonstruo(30))
    }
    override def recompensar: Recompensa = recompensaPozo1
  }
  
  object MisionMatarMonstruos extends Mision() {
    override def tareas: List[Tarea] = {
      List(pelearConMonstruo(50), pelearConMonstruo(30), pelearConMonstruo(20))
    }
    override def recompensar: Recompensa = recompensaPozo2
  }

  object MisionForzarMatarYRobarTalisman extends Mision() {
    override def tareas: List[Tarea] = {
      List(forzarPuerta(), pelearConMonstruo(30), robarTalisman(talismanMinimalismo))
    }
    override def recompensar: Recompensa = recompensaPozo1
  }
  
  object Tablon extends criterios()
  
  def criterioPorPozo(equipo1 : Equipo, equipo2 : Equipo) : Boolean = equipo1.pozo > equipo2.pozo
  
  def cuantificadorPorHpBase(heroe: Heroe): Int = {
    heroe.hpBase.toInt
  }

  @Test
  def trabajoAumentaStats() {
    val guerrero = unHeroeGuerrero()
    assert(215.0 == guerrero.fuerza)
  }

  @Test
  def equiparUnItem() {
    var guerrero = unHeroeGuerrero()
    var guerreroEquipado = guerrero.equiparItem(cascoVikingo)
    assert(guerreroEquipado.tieneItem(cascoVikingo))
  }

  @Test
  def cambioDeTrabajo() {
    var guerrero = unHeroeGuerrero()
    var nuevoGuerrero = guerrero.cambiarTrabajo(Some(Mago))
    assert(nuevoGuerrero.trabajo == Some(Mago))
  }

  @Test
  def mejorHeroeSegunHpBase() {
    var equipo = unEquipo()
    assert(equipo.mejorHeroeSegun(cuantificadorPorHpBase) == Some(unHeroeGuerrero()))
  }

  @Test
  def equiparItemEquipoAlMejor() {
    var equipo = unEquipo()
    var equipoConItem = equipo.entregarItem(cascoVikingo)
    var guerrero1 = unHeroeGuerrero()
    var guerreroEquipado = guerrero1.equiparItem(cascoVikingo)
    var guerrero = equipoConItem.heroes.find(unGuerrero => unGuerrero == guerreroEquipado)
    assert(guerrero.get.tieneItem(cascoVikingo))
  }

  @Test
  def unirHeroeAlEquipo() {
    var equipo = unEquipo()
    var trabajo = Guerrero
    var stats = new Stats(2, 200, 5, 20)
    var otroGuerrero = new Heroe(stats, Some(trabajo), new Inventario(new UnaMano(None, None), None, None, List()))
    var equipoConNuevoIntegrante = equipo.obtenerMiembro(otroGuerrero)
    assert(equipoConNuevoIntegrante.estaEnEquipo(otroGuerrero))
  }

  @Test
  def reemplazarHeroeEnEquipo() {
    var equipo = unEquipo()
    var trabajo = Guerrero
    var stats = new Stats(2, 200, 5, 20)
    var otroGuerrero = new Heroe(stats, Some(trabajo), new Inventario(new UnaMano(None, None), None, None, List()))
    var equipoConNuevoIntegrante = equipo.reemplazarMiembro(unHeroeGuerrero(), otroGuerrero)
    assert(equipoConNuevoIntegrante.estaEnEquipo(otroGuerrero))
  }

  @Test
  def obtenerLider() {
    var equipo = unEquipo()
    assert(equipo.lider() == unHeroeGuerrero())
  }

  @Test
  def misionCumplida() {
    var equipo = unEquipo()
    var mision = MisionForzarYMatar
    var resultado = mision.ejecutar(equipo)
    var equipoResultante = resultado.equipo
    assert(resultado == ContinuaMision(equipoResultante))
  }

  @Test
  def misionFallida() {
    var equipo = unEquipo()
    var mision = MisionForzarMatarYRobarTalisman
    var resultado = mision.ejecutar(equipo)
    var equipoResultante = resultado.equipo
    assert(resultado == NoPuedeSeguirEnLaMision(equipoResultante, robarTalisman(talismanMinimalismo)))
  }
  
  @Test
  def elegirMisionMatarMonstruos(){
    var equipo = unEquipo()
    var resultado = Tablon.elegirMision(equipo, MisionForzarYMatar, MisionMatarMonstruos, criterioPorPozo)
    assert(resultado.get == MisionMatarMonstruos)
  }
  
  @Test
  def entrenarResultadoPositivo(){
    var equipo = unEquipo()
    var misiones = List(MisionMatarMonstruos, MisionForzarYMatar) 
    var resultado = entrenar(equipo, misiones)
    var equipoResultante = resultado.equipo
    assert(resultado == ContinuaMision(equipoResultante))
  }

}
