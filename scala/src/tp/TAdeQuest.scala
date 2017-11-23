package tp

import java.lang.reflect.Constructor
import scala.util.Try

object TAdeQuest {
  //▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀
  // HEROE
  //▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄
  type Cuantificador = Heroe => Int
  def valorStatPrincipal(heroe: Heroe): Double = heroe.statPrincipal
  case class Stats(
    hp: Double,
    fuerza: Double,
    velocidad: Double,
    inteligencia: Double)

  case class Heroe(stats: Stats, trabajo: Option[Trabajo],
    inventario: Inventario) {
    def equiparItem(unItem: Item): Heroe = {
      if (unItem.puedeEquipar(this)) {
        unItem match {
          case cabeza: Cabeza => this.copy(stats, trabajo, inventario.copy(cabeza = Option(cabeza)))
          case armadura: Armadura => this.copy(stats, trabajo, inventario.copy(torso = Option(armadura)))
          case talisman: Talisman => this.copy(stats, trabajo, inventario.copy(talismanes = inventario.talismanes ++ List(talisman)))
          case dosmanos: manos => this.copy(stats, trabajo, inventario.copy(manos = DosManos(Option(dosmanos))))
          case unamano: mano => inventario.manos match {
            case DosManos(_) => this.copy(stats, trabajo, inventario.copy(manos = UnaMano(Option(unamano))))
            case UnaMano(unaMano, None) => this.copy(stats, trabajo, inventario.copy(manos = UnaMano(unaMano, Option(unamano))))
            case UnaMano(unaMano, otraMano) => this.copy(stats, trabajo, inventario.copy(manos = UnaMano(Option(unamano), otraMano)))
          }
        }
      } else {
        this
      }
    }

    def tieneItem(unItem: Item): Boolean = {
      this.inventario.contiene(unItem)
    }

    def cambiarTrabajo(nuevoTrabajo: Option[Trabajo]): Heroe = {
      this.copy(this.stats, nuevoTrabajo, this.inventario)
    }
    def fuerzaBase = stats.fuerza
    def inteligenciaBase = stats.inteligencia
    def hpBase = stats.hp
    def fuerza = modificarPorItems.heroe.stats.fuerza
    def inteligencia = modificarPorItems.heroe.stats.inteligencia
    def velocidad = modificarPorItems.heroe.stats.velocidad
    def hp = modificarPorItems.heroe.stats.hp
    def incremento: Option[Double] = trabajo match {
      case Some(trabajo) => Some(trabajo.incremento(this))
      case otro => None
    }
    def statPrincipal: Double = trabajo match {
      case Some(trabajo) => trabajo.statPrincipal(this)
      case otro => 0
    }
    def modificarPorItems(): ResultadoDeModificar = {
      var heroeAModificar =
        trabajo match {
          case Some(trabajo) => trabajo.modificarStats(this)
          case None => this

        }
      inventario.items.foldLeft(Seguir(heroeAModificar): ResultadoDeModificar) {
        (heroeAnterior, itemActual) =>
          heroeAnterior match {
            case Seguir(unHeroe) => itemActual.efecto(unHeroe)
            case otro => otro
          }
      }
    }
  }
  trait Stat extends Function1[Stats, Double]
  object Fuerza extends Stat {
    def apply(s: Stats) = s.fuerza
  }

  trait ResultadoDeModificar {
    def heroe: Heroe
  }
  case class Seguir(heroe: Heroe) extends ResultadoDeModificar
  case class Parar(heroe: Heroe) extends ResultadoDeModificar

  //▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀
  // TRABAJOS
  //▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄

  case class Trabajo(stats: Stats) {
    def modificarStats(heroe: Heroe): Heroe = {
      heroe.copy(heroe.stats.copy(
        stats.hp + heroe.stats.hp,
        stats.fuerza + heroe.stats.fuerza,
        stats.velocidad + heroe.stats.velocidad,
        stats.inteligencia + heroe.stats.inteligencia))
    }
    def aumentarStatsNoPrincipales(heroe: Heroe): Stats = ???
    def statPrincipal(heroe: Heroe): Double = ???
    def incremento(heroe: Heroe): Double = statPrincipal(heroe) * 0.1
  }

  object Guerrero extends Trabajo(new Stats(10, 15, -10, 0)) {
    override def statPrincipal(heroe: Heroe) = heroe.fuerza
    override def aumentarStatsNoPrincipales(heroe: Heroe): Stats = {
      var stats = heroe.stats
      var aumento = incremento(heroe)
      stats.copy(stats.hp + aumento, stats.fuerza,
        stats.velocidad + aumento, stats.inteligencia + aumento)
    }
  }
  object Mago extends Trabajo(new Stats(0, -20, 0, 20)) {
    override def statPrincipal(heroe: Heroe) = heroe.inteligencia
    override def aumentarStatsNoPrincipales(heroe: Heroe): Stats = {
      var stats = heroe.stats
      var aumento = incremento(heroe)
      stats.copy(stats.hp + aumento, stats.fuerza + aumento,
        stats.velocidad + aumento, stats.inteligencia)
    }
  }
  object Ladron extends Trabajo(new Stats(-5, 0, 10, 0)) {
    override def statPrincipal(heroe: Heroe) = heroe.velocidad
    override def aumentarStatsNoPrincipales(heroe: Heroe): Stats = {
      var stats = heroe.stats
      var aumento = incremento(heroe)
      stats.copy(stats.hp + aumento, stats.fuerza + aumento,
        stats.velocidad, stats.inteligencia + aumento)
    }
  }

  //▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀
  // ITEMS
  //▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄

  trait InventarioManos {
    def items(): List[Item] = ???
  }
  case class UnaMano(manoIzquierda: Option[mano], manoDerecha: Option[mano] = None) extends InventarioManos {
    override def items() = manoIzquierda.toList ++ manoDerecha.toList
  }
  case class DosManos(dosManos: Option[manos]) extends InventarioManos {
    override def items() = dosManos.toList
  }

  case class Inventario(
    manos: InventarioManos,
    cabeza: Option[Cabeza],
    torso: Option[Armadura],
    talismanes: List[Talisman]) {
    def items() = cabeza.toList ++ torso.toList ++ talismanes ++ manos.items()
    def contiene(unItem: Item): Boolean = {
      items().contains(unItem)
    }
  }

  trait Item {
    val valor: Int = 0
    def puedeEquipar(heroe: Heroe): Boolean = ???
    def efecto(heroe: Heroe): ResultadoDeModificar = ???
  }

  case class Cabeza() extends Item
  case class mano() extends Item
  case class manos() extends Item
  case class Armadura() extends Item
  case class Talisman() extends Item
  case class Espalda() extends Item

  object cascoVikingo extends Cabeza() {
    override def puedeEquipar(heroe: Heroe) = heroe.fuerzaBase > 30
    override def efecto(heroe: Heroe) = Seguir(heroe.copy(stats = heroe.stats.copy(hp = heroe.stats.hp + 10)))
  }

  object vinchaBufaloAgua extends Cabeza() {
    override def puedeEquipar(heroe: Heroe) = heroe.trabajo == None
    override def efecto(heroe: Heroe) = if (heroe.fuerzaBase > heroe.inteligenciaBase)
      Seguir(heroe.copy(stats = heroe.stats.copy(inteligencia = heroe.inteligencia + 30)))
    else Seguir(heroe.copy(stats = heroe.stats.copy(
      fuerza = heroe.stats.fuerza + 10, hp = heroe.stats.hp + 10,
      velocidad = heroe.stats.velocidad + 10)))
  }

  object palitoMagico extends mano() {
    override def puedeEquipar(heroe: Heroe) =
      heroe.trabajo == Some(Mago) || heroe.trabajo == Some(Ladron) && heroe.inteligenciaBase > 30
    override def efecto(heroe: Heroe) = Seguir(heroe.copy(stats = heroe.stats.copy(inteligencia = heroe.stats.inteligencia + 20)))
  }

  object armaduraEleganteSport extends Armadura() {
    override def puedeEquipar(heroe: Heroe) = true
    override def efecto(heroe: Heroe) = Seguir(heroe.copy(stats = heroe.stats.copy(hp = heroe.stats.hp - 30, velocidad = heroe.stats.velocidad + 30)))
  }

  object arcoViejo extends manos() {
    override def puedeEquipar(heroe: Heroe) = true
    override def efecto(heroe: Heroe) = Seguir(heroe.copy(stats = heroe.stats.copy(fuerza = heroe.stats.fuerza + 2)))
  }

  object talismanDedicacion extends Talisman() {
    override def puedeEquipar(heroe: Heroe) = true
    override def efecto(heroe: Heroe) = heroe.trabajo match {
      case None => Seguir(heroe)
      case Some(trabajo) => Seguir(heroe.copy(stats = trabajo.
        aumentarStatsNoPrincipales(heroe)))
    }
  }

  object talismanMinimalismo extends Talisman() {
    override def puedeEquipar(heroe: Heroe) = true
    override def efecto(heroe: Heroe) = Seguir(heroe.copy(stats = heroe.stats.copy(hp = heroe.stats.hp + 50 - heroe.inventario.items.size)))
  }

  object talismanMaldito extends Talisman() {
    override def puedeEquipar(heroe: Heroe) = true
    override def efecto(heroe: Heroe) = Parar(heroe.copy(stats = new Stats(1, 1, 1, 1)))
  }

  object espaldaDeLaVida extends Espalda() {
    override def puedeEquipar(heroe: Heroe) = true
    override def efecto(heroe: Heroe) = Seguir(heroe.copy(stats = heroe.stats.copy(fuerza = heroe.stats.hp)))
  }

  object escudoAntiRobo extends manos() {
    override def puedeEquipar(heroe: Heroe) =
      heroe.trabajo != Some(Ladron) && heroe.fuerzaBase > 20
    override def efecto(heroe: Heroe) = Seguir(heroe.copy(stats = heroe.stats.copy(hp = heroe.stats.hp + 20)))
  }

  //▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀
  // EQUIPO
  //▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄
  case class Equipo(
    heroes: List[Heroe],
    pozo: Int,
    nombre: String) {
    def entregarItem(item: Item): Equipo = {

      Try(heroes.map(heroe => heroe.equiparItem(item))).toOption match {
        case Some(unosHeroes) =>
          Try(unosHeroes.maxBy(h => h.incremento)).toOption match {
            case Some(heroe) =>
              this.copy(unosHeroes.map(h => if (h == heroe) h.equiparItem(item) else h), pozo, nombre)
            case otro => this.copy(heroes, pozo + item.valor, nombre)
          }
        case otro => this.copy(heroes, pozo + item.valor, nombre)
      }
    }

    def esLiderDeTipo(tipo: Trabajo) = lider.trabajo == tipo
    def cantidadDeLadrones() = heroes.count(heroe => heroe.trabajo == Ladron)
    def mejorHeroeSegun(cuantificador: Cuantificador): Option[Heroe] =
      Try(heroes.maxBy(heroe => cuantificador(heroe))).toOption

    def lider() = heroes.maxBy(heroe => valorStatPrincipal(heroe))
    def obtenerMiembro(heroe: Heroe): Equipo = {
      if (!estaEnEquipo(heroe)) this.copy(heroes ++ Some(heroe).toList, pozo, nombre) else this
    }
    def estaEnEquipo(heroe: Heroe): Boolean = heroes.contains(heroe)
    def reemplazarMiembro(heroe: Heroe, reemplazo: Heroe) =
      this.copy(heroes.filter(unHeroe => unHeroe != heroe) :+ reemplazo, pozo, nombre)
  }

  //▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀
  // TAREAS
  //▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄

  trait Tarea {
    def realizarTarea(heroe: Heroe): Heroe = ???
    def facilidad(heroe: Heroe, equipo: Equipo): Option[Double] = ???
  }
  case class pelearConMonstruo(danio: Int) extends Tarea {
    override def realizarTarea(heroe: Heroe): Heroe =
      if (heroe.fuerza < 20) heroe.copy(
        heroe.stats.copy(heroe.hpBase - danio),
        heroe.trabajo, heroe.inventario)
      else heroe
    override def facilidad(heroe: Heroe, equipo: Equipo): Option[Double] =
      if (equipo.esLiderDeTipo(Guerrero)) Some(20) else Some(10)
  }
  case class forzarPuerta() extends Tarea {
    override def realizarTarea(heroe: Heroe) = heroe.trabajo match {
      case Some(Mago) => heroe
      case Some(Ladron) => heroe
      case Some(_) => heroe.copy(heroe.stats.copy(
        heroe.hpBase - 5,
        heroe.fuerzaBase + 1))
      case otro => heroe
    }

    override def facilidad(heroe: Heroe, equipo: Equipo): Option[Double] =
      Some(heroe.inteligencia + equipo.cantidadDeLadrones())
  }
  case class robarTalisman(talisman: Talisman) extends Tarea {
    override def realizarTarea(heroe: Heroe) = heroe.copy(
      heroe.stats, heroe.trabajo, heroe.inventario.copy(talismanes = heroe.inventario.talismanes ++ Some(talisman).toList))
    override def facilidad(heroe: Heroe, equipo: Equipo): Option[Double] =
      if (equipo.esLiderDeTipo(Ladron)) Some(heroe.velocidad) else None
  }

  //▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀
  // MISION
  //▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄

  trait ResultadoDeTarea {
    def equipo: Equipo
    def tarea: Option[Tarea] = None
  }
  case class ContinuaMision(equipo: Equipo) extends ResultadoDeTarea
  case class NoPuedeSeguirEnLaMision(
    equipo: Equipo,
    tareaFallida: Tarea) extends ResultadoDeTarea

  type Recompensa = Equipo => Equipo
  trait Mision {
    def tareas: List[Tarea]
    def recompensar: Recompensa = ???
    def ejecutar(equipo: Equipo): ResultadoDeTarea = {
      tareas.foldLeft(ContinuaMision(equipo): ResultadoDeTarea) {
        (equipoAnterior, tareaActual) =>
          equipoAnterior match {
            case ContinuaMision(equipoAnterior) =>
              Try(equipoAnterior.heroes.filter(heroe => tareaActual.facilidad(heroe, equipoAnterior) != None)
                .maxBy(heroe => tareaActual.facilidad(heroe, equipoAnterior))).toOption match {
                case Some(heroe) => ContinuaMision(equipoAnterior.copy(equipoAnterior.heroes.map(h => if (h == heroe) tareaActual.realizarTarea(heroe) else heroe), equipoAnterior.pozo, equipoAnterior.nombre))
                case otro => NoPuedeSeguirEnLaMision(equipoAnterior, tareaActual)
              }
            case otro => otro
          }
      } match {
        case ContinuaMision(equipo) => ContinuaMision(recompensar(equipo))
        case otro => otro
      }
    }
  }
  type Criterio = (Equipo, Equipo) => Boolean
  trait criterios {
    def elegirMision(equipo: Equipo, mision1: Mision, mision2: Mision, criterio: Criterio): Option[Mision] = {
      val equipoMision1 = mision1.ejecutar(equipo)
      val equipoMision2 = mision2.ejecutar(equipo)
      equipoMision1 match {
        case ContinuaMision(e1) => {
          equipoMision2 match {
            case ContinuaMision(e2) if ((criterio(e1, e2))) => Some(mision1)
            case ContinuaMision(e2) => Some(mision2)
            case otro => Some(mision1)
          }
        }
        case otro => equipoMision2 match {
          case ContinuaMision(e2) => Some(mision2)
          case otro => None
        }
      }
    }
  }

  def entrenar(equipo: Equipo, misiones: List[Mision]): ResultadoDeTarea = {
    misiones.foldLeft(ContinuaMision(equipo): ResultadoDeTarea) {
      (equipoAnterior, misionActual) =>
        equipoAnterior match {
          case ContinuaMision(e) => misionActual.ejecutar(e)
          case otro => otro
        }
    }
  }

}






