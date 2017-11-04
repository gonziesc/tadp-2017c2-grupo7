import java.lang.reflect.Constructor
import scala.util.Try

object tp {
  //▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀
	// HEROE
	//▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄
  type Cuantificador = Heroe => Int
  def valorStatPrincipal(heroe: Heroe): Double = heroe.statPrincipal
  case class Stats(
		hp: Double,
		fuerza: Double,
		velocidad: Double,
		inteligencia: Double
	)
	
	trait InventarioManos extends Item
  case class UnaMano(manoIzquierda: Option[ItemUnaMano], manoDerecha: Option[ItemUnaMano]) extends InventarioDosManos
  case class DosManos(dosManos: Option[ItemDosMano]) extends InventarioDosManos
	
  case class Inventario(
      manos: InventarioManos,
      cabeza: Option[ItemCabeza],
      torso: Option[ItemTorso],
      talismanes: List[Talisman]
      ) {
    def items() = cabeza.toList ++ torso.toList ++ talismanes ++ manos.items()
  }

  case class Heroe(stats: Stats, trabajo: Option[Trabajo], 
                   items: List[Item] = List()){
    def equiparItem(unItem: Item):Heroe = {
      if(unItem.puedeEquipar(this)) {
        unItem match {
          // se puede abstraer esto?
          case Mano(Mano, Some(Mano), _) => this.desequiparParte(Mano)
          case Item(Mano, _, _) => this.revisarManos()
          case Item(_, None, _) => this.desequiparParte(unItem.parteDelCuerpo)
        }
        this.copy(stats, trabajo, items ++ Some(unItem).toList)
      } else {
        this
      }
    }
    def cambiarTrabajo(nuevoTrabajo: Option[Trabajo]) {
      var nuevoHeroe = this.copy(stats, nuevoTrabajo, items)
      nuevoHeroe.copy(stats, trabajo, items.filter(item => 
                                      item.puedeEquipar(nuevoHeroe)))
      // hay dos copys, esta bien?
    }
    def revisarManos(){
      if(tieneAmbasManosOcupadas){
        // esto quedo feo, hay mejor manera de hacerlo?
        var indice = items.indexWhere(item => item.parteDelCuerpo == Mano)
        items.drop(indice)
      }
      if(tieneItemQueOcupaDosManos){
        this.desequiparParte(Mano)
      }
    }
    def tieneItemQueOcupaDosManos = items.contains((item: Item) => 
        item.parteDelCuerpo == Mano && item.otraParteDelCuerpo == Some(Mano))
    def tieneAmbasManosOcupadas = items.count(item => item.parteDelCuerpo == Mano) > 1
    def desequiparParte(parte: ParteDelCuerpo) = 
      items.filter(item => item.parteDelCuerpo != parte)
    def fuerzaBase = stats.fuerza
    def inteligenciaBase = stats.inteligencia
    def hpBase = stats.hp
    def fuerza = modificarPorItems.stats.fuerza
    def inteligencia = modificarPorItems.stats.inteligencia
    def velocidad = modificarPorItems.stats.velocidad
    def hp = modificarPorItems.stats.hp
    def incremento: Option[Double] = trabajo match {
      case Some(trabajo) => Some(trabajo.incremento(this))
      case otro => None
    }
    def statPrincipal: Double = trabajo match {
      case Some(trabajo) => trabajo.statPrincipal(this)
      case otro => 0
      }
    def modificarPorItems(): ResultadoDeModificar = {
      items.foldLeft(
          Seguir(trabajo.fold(stats) {_.modificarStats(stats)}
          ): ResultadoDeModificar){
        
        //(statsAnteriores, itemActual) => statsAnteriores.flatMap(itemActual.efecto(_))
        (statsAnteriores, itemActual) =>
        itemActual match {
          case `talismanMaldito` => 
		        Parar(new Stats(1, 1, 1, 1))
		      case `cascoVikingo` => 
		        statsAnteriores match { 
		          case Seguir(_) => Seguir(stats.copy(hp = hp + 10))
		          case otro => otro
		        }
		      case `escudoAntiRobo` => 
		        statsAnteriores match { 
		          case Seguir(_) => Seguir(stats.copy(hp = hp + 20))
		          case otro => otro
		        }
		      case `talismanMinimalismo` => 
		        statsAnteriores match { 
		          case Seguir(_) => Seguir(stats.copy(hp = hp + 50 - items.size))
		          case otro => otro
		        }
		      case `palitoMagico` => 
		        statsAnteriores match { 
		          case Seguir(_) => Seguir(stats.copy(
		              inteligencia = inteligencia + 20))
		          case otro => otro
		        }
		      case `armaduraEleganteSport` => 
		        statsAnteriores match { 
		          case Seguir(_) => Seguir(stats.copy(
		              hp = hp - 30,velocidad = velocidad + 30))
		          case otro => otro
		        }
		      case `arcoViejo` => 
		        statsAnteriores match { 
		          case Seguir(_) => Seguir(stats.copy(fuerza = fuerza + 2))
		          case otro => otro
		        }
		      case `talismanDedicacion` => 
		        statsAnteriores match { 
		          case Seguir(_) => {
		            trabajo match{
		              case None => Seguir(stats)
		              case Some(trabajo) => Seguir(trabajo.
		                  aumentarStatsNoPrincipales(this))
		            }
		          }
		          case otro => otro
		        }
		      case `espaldaDeLaVida` => 
		        statsAnteriores match { 
		          case Seguir(_) => Seguir(stats.copy(fuerza = hp))
		          case otro => otro
		        }
		      case `vinchaBufaloAgua` => 
		        statsAnteriores match { 
		          case Seguir(_) if fuerzaBase > inteligenciaBase => 
		            Seguir(stats.copy(inteligencia = inteligencia + 30))
		          case Seguir(_) => Seguir(stats.copy(
		              fuerza = fuerza + 10, hp = hp + 10, 
		              velocidad = velocidad + 10))
		          case otro => otro
		        }
         }
      }
    }
  }
  trait Stat extends Function1[Stats, Double]
  object Fuerza extends Stat {
    def apply(s: Stats) = s.fuerza
  }
    
  trait ResultadoDeModificar{
    def stats: Stats
  }
	case class Seguir(stats: Stats) extends ResultadoDeModificar
	case class Parar(stats: Stats) extends ResultadoDeModificar
  
  //▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀
	// TRABAJOS
	//▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄
	
	case class Trabajo(stats: Stats){
	  def modificarStats(unasStats: Stats): Stats = {
	    stats.copy(stats.hp + unasStats.hp, 
	        stats.fuerza  + unasStats.fuerza, 
	        stats.velocidad  + unasStats.velocidad,
	        stats.inteligencia  + unasStats.inteligencia)
	  } 
	   def aumentarStatsNoPrincipales(heroe: Heroe): Stats = ???
	   def statPrincipal(heroe: Heroe): Double = ???
	   def incremento(heroe: Heroe): Double = statPrincipal(heroe) * 0.1
	}
  
  object Guerrero extends Trabajo(new Stats(10, 15, -10, 0)){
    override def statPrincipal(heroe: Heroe) = heroe.fuerza
    override def aumentarStatsNoPrincipales(heroe: Heroe): Stats = {
      var stats = heroe.stats
      var aumento = incremento(heroe)
       stats.copy(stats.hp + aumento,stats.fuerza,
           stats.velocidad + aumento, stats.inteligencia + aumento)
    }
  }
  object Mago extends Trabajo(new Stats(0, -20, 0, 20)){
    override def statPrincipal(heroe: Heroe) = heroe.inteligencia
    override def aumentarStatsNoPrincipales(heroe: Heroe): Stats = {
       var stats = heroe.stats
       var aumento = incremento(heroe)
       stats.copy(stats.hp + aumento,stats.fuerza + aumento,
           stats.velocidad + aumento, stats.inteligencia)
    }
  }
  object Ladron extends Trabajo(new Stats(-5, 0, 10, 0)){
    override def statPrincipal(heroe: Heroe) = heroe.velocidad
    override def aumentarStatsNoPrincipales(heroe: Heroe): Stats = {
      var stats = heroe.stats
      var aumento = incremento(heroe)
      stats.copy(stats.hp + aumento,stats.fuerza  + aumento,
          stats.velocidad, stats.inteligencia + aumento)
    }
  }
  
  //▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀
	// ITEMS
	//▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄
  
  trait ParteDelCuerpo
  object Cabeza extends ParteDelCuerpo
  object Mano extends ParteDelCuerpo
  object Armadura extends ParteDelCuerpo
  object Talisman extends ParteDelCuerpo
  object Espalda extends ParteDelCuerpo
  
  case class Item(parteDelCuerpo: ParteDelCuerpo, 
     otraParteDelCuerpo: Option[ParteDelCuerpo] = None, valor: Int = 0, efecto: 
       Stats => ResultadoDeModificar = ???){
   def puedeEquipar(heroe: Heroe) = true
  }
  
  object cascoVikingo extends Item(Cabeza){
    override def puedeEquipar(heroe: Heroe) = heroe.fuerzaBase > 30 
  }
  
  object vinchaBufaloAgua extends Item(Cabeza){
    override def puedeEquipar(heroe: Heroe) = heroe.trabajo == None
  }
  
  object palitoMagico extends Item(Mano){
    override def puedeEquipar(heroe: Heroe) = 
      heroe.trabajo == Some(Mago) || heroe.trabajo == Some(Ladron) && heroe.inteligenciaBase > 30
  }
  
  object armaduraEleganteSport extends Item(Armadura)
  
  object arcoViejo extends Item(Mano, Some(Mano))
  
  object talismanDedicacion extends Item(Talisman)
  
  object talismanMinimalismo extends Item(Talisman)
  
  object talismanMaldito extends Item(Talisman)
  
  object espaldaDeLaVida extends Item(Espalda)
  
  object escudoAntiRobo extends Item(Mano){
    override def puedeEquipar(heroe: Heroe) = 
      heroe.trabajo != Some(Ladron) && heroe.fuerzaBase > 20 
  }
	
	//▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀
	// EQUIPO
	//▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄
  case class Equipo(
    heroes: List[Heroe],
    pozo: Int,
    nombre: String
   ){
    def entregarItem(item: Item) = {

      Try(heroes.map(heroe => heroe.equiparItem(item))).toOption match {
        case Some(unosHeroes) => 
          Try(unosHeroes.maxBy(h => h.incremento)).toOption match {
        case Some(heroe) => 
          this.copy(heroes.map(h => 
            if(h==heroe) h.equiparItem(item) else h), pozo, nombre)
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
    def obtenerMiembro(heroe: Heroe) = this.copy(
        heroes ++ Some(heroe).toList, pozo, nombre)
    def reemplazarMiembro(heroe: Heroe, reemplazo: Heroe) = 
      this.copy(heroes.filter(
          unHeroe => unHeroe != reemplazo) :+ heroe, pozo, nombre)
  }
  
  //▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀
	// TAREAS
	//▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄

  // armo polimorfismo adhoc por la doble condicion de que puede segun eficacia
  // y la accion de realizarla, me parece demasiada logica como para usar pattern
  trait Tarea{
    def realizarTarea(heroe: Heroe): Heroe = ???
    def facilidad(equipo: Equipo): PartialFunction[Heroe, (Heroe, Double)] = ???
  }
  case class pelearConMonstruo(danio: Int) extends Tarea{
    override def realizarTarea(heroe: Heroe): Heroe = 
      if (heroe.fuerza < 20) heroe.copy(
          heroe.stats.copy(heroe.hpBase - danio), 
          heroe.trabajo, heroe.items) else heroe
    override def facilidad(heroe: Heroe, equipo: Equipo): Option[Double] = 
      if (equipo.esLiderDeTipo(Guerrero)) Some(20) else Some(10)
  }
  case class forzarPuerta() extends Tarea {
     override def realizarTarea(heroe: Heroe) = heroe.trabajo.fold(heroe)( _ match {
       case Mago => heroe
       case Ladron => heroe
       case _ => heroe.copy(heroe.stats.copy(heroe.hpBase - 5,
           heroe.fuerzaBase +1))
     })
  
     override def facilidad(heroe: Heroe, equipo: Equipo): Option[Double] =
       Some(heroe.inteligencia + equipo.cantidadDeLadrones())
  }
    case class robarTalisman(talisman: Item) extends Tarea{
      // validar que sea un talisman?
    override def realizarTarea(heroe: Heroe) = heroe.copy(
        heroe.stats, heroe.trabajo, heroe.items ++ Some(talisman).toList)
    override def facilidad(heroe: Heroe, equipo: Equipo): Option[Double] =
      if(equipo.esLiderDeTipo(Ladron)) Some(heroe.velocidad) else None  
   }
    
  //▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀
	// MISION
	//▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄
    
   trait ResultadoDeTarea{
    def equipo: Equipo
    def tarea: Option[Tarea] = None
  }
	case class ContinuaMision(equipo: Equipo) extends ResultadoDeTarea
	case class NoPuedeSeguirEnLaMision(equipo: Equipo,
	    tareaFallida: Tarea)extends ResultadoDeTarea
	
  type Recompensa = Equipo => Equipo
  
  def aplicarTarea(tareaActual: Tarea, equipo:Equipo) =  
//    fequipo.heroes.map((heroe) => (heroe, tareaActual.facilidad(heroe, equipo))).
//      filter(_._2.isDefined).sortBy(_.2.).headOption.getOrElse(NoPuedeSeguirEnLaMision(equipo, tareaActual))
    equipo.heroes.collect(tareaActual.facilidad(equipo)).sortBy(_._2).headOption
//            case Some(heroe) =>
//              ContinuaMision(equipo.copy(
//                  equipo.heroes.map(h =>
//                    if(h==heroe) tareaActual.realizarTarea(heroe)
//                    else heroe), equipo.pozo, equipo.nombre))
//            case otro => NoPuedeSeguirEnLaMision(equipo, tareaActual)
  
  trait mision{
    def tareas: List[Tarea]
    def recompensar: Recompensa = ???
    def ejecutar(equipo: Equipo) : ResultadoDeTarea = {
      tareas.foldLeft(ContinuaMision(equipo): ResultadoDeTarea){
        (equipoAnterior, tareaActual) => 
          equipoAnteriro.flatMap(tareaActual
        equipoAnterior match {
          case ContinuaMision(equipo) =>
           
          }
          case otro => otro
        }
      } match {
        case ContinuaMision(equipo) => ContinuaMision(recompensar(equipo))
        case otro => otro
      }
    }
  }
}


