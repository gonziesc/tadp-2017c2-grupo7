import java.lang.reflect.Constructor


object tp {
  case class Heroe(stats: Stats, trabajo: Option[Trabajo], items: List[Item] = List()){
    
    def equiparItem(unItem: Item){
      if(unItem.puedeEquipar(this)) {
        unItem match {
          // se puede abstraer esto?
          case Item(Mano, Some(Mano)) => this.desequiparParte(Mano)
          case Item(Mano, _) => this.revisarManos()
          case Item(_, None) => this.desequiparParte(unItem.parteDelCuerpo)
        }
      }
    }
    def cambiarTrabajo(nuevoTrabajo: Option[Trabajo]) {
      var nuevoHeroe = this.copy(stats, nuevoTrabajo, items)
      nuevoHeroe.copy(stats, trabajo, items.filter(item => item.puedeEquipar(nuevoHeroe)))
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
    def tieneItemQueOcupaDosManos = items.contains((item: Item) => item.parteDelCuerpo == Mano && item.otraParteDelCuerpo == Some(Mano))
    def tieneAmbasManosOcupadas = items.count(item => item.parteDelCuerpo == Mano) > 1
    def desequiparParte(parte: ParteDelCuerpo) = items.dropWhile(item => item.parteDelCuerpo == parte)
    def fuerzaBase = stats.fuerza
    def inteligenciaBase = stats.inteligencia
    def fuerza = modificarPorItems.stats.fuerza
    def inteligencia = modificarPorItems.stats.inteligencia
    def velocidad = modificarPorItems.stats.velocidad
    def hp = modificarPorItems.stats.hp
    def modificarPorItems(): ResultadoDeModificar = {
      var statsAModificar =
      trabajo match {
        case Some(trabajo) => trabajo.modificarStats(stats)
        case None => stats
        
      }
      items.foldLeft(Seguir(statsAModificar): ResultadoDeModificar){ (statsAnteriores, itemActual) =>
        itemActual match {
          case `talismanMaldito` => 
		        EstaMaldito(new Stats(1, 1, 1, 1))
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
		          case Seguir(_) => Seguir(stats.copy(inteligencia = inteligencia + 20))
		          case otro => otro
		        }
		      case `armaduraEleganteSport` => 
		        statsAnteriores match { 
		          case Seguir(_) => Seguir(stats.copy(hp = hp - 30, velocidad = velocidad + 30))
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
		              case Some(trabajo) => Seguir(trabajo.aumentarStatsNoPrincipales(stats))
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
		          case Seguir(_) if fuerzaBase > inteligenciaBase => Seguir(stats.copy(inteligencia = inteligencia + 30))
		          case Seguir(_) => Seguir(stats.copy(fuerza = fuerza + 10, hp = hp + 10, velocidad = velocidad + 10))
		          case otro => otro
		        }
         }
      }
    }
  }
    
  trait ResultadoDeModificar{
    def stats: Stats
  }
	case class Seguir(stats: Stats) extends ResultadoDeModificar
	case class EstaMaldito(stats: Stats) extends ResultadoDeModificar
  
  case class Trabajo(stats: Stats){
	  def modificarStats(unasStats: Stats): Stats = {
	    // no me deja hacer copy
	    return new Stats(stats.hp + unasStats.hp, 
	        stats.fuerza  + unasStats.fuerza, 
	        stats.velocidad  + unasStats.velocidad,
	        stats.inteligencia  + unasStats.inteligencia)
	  } 
	   def aumentarStatsNoPrincipales(stats: Stats): Stats = ???
	}
  
  object Guerrero extends Trabajo(new Stats(10, 15, -10, 0)){
    override def aumentarStatsNoPrincipales(stats: Stats): Stats = {
      var aumento = stats.fuerza * 0.1
      // no me deja hacer copy
      return new Stats(stats.hp + aumento,stats.fuerza, stats.velocidad + aumento, stats.inteligencia + aumento)
    }
  }
  object Mago extends Trabajo(new Stats(0, -20, 0, 20)){
    override def aumentarStatsNoPrincipales(stats: Stats): Stats = {
      var aumento = stats.inteligencia * 0.1
       return new Stats(stats.hp + aumento,stats.fuerza + aumento, stats.velocidad + aumento, stats.inteligencia)
    }
  }
  object Ladron extends Trabajo(new Stats(-5, 0, 10, 0)){
    override def aumentarStatsNoPrincipales(stats: Stats): Stats = {
      var aumento = stats.velocidad * 0.1
      return new Stats(stats.hp + aumento,stats.fuerza  + aumento, stats.velocidad, stats.inteligencia + aumento)
    }
  }
  
  
  trait ParteDelCuerpo
  object Cabeza extends ParteDelCuerpo
  object Mano extends ParteDelCuerpo
  object Armadura extends ParteDelCuerpo
  object Talisman extends ParteDelCuerpo
  object Espalda extends ParteDelCuerpo
  
  case class Item(parteDelCuerpo: ParteDelCuerpo, otraParteDelCuerpo: Option[ParteDelCuerpo] = None){
   def puedeEquipar(heroe: Heroe) = true
  }
  
  object cascoVikingo extends Item(Cabeza){
    override def puedeEquipar(heroe: Heroe) = heroe.fuerzaBase > 30 
  }
  
  object vinchaBufaloAgua extends Item(Cabeza){
    override def puedeEquipar(heroe: Heroe) = heroe.trabajo == None
  }
  
  object palitoMagico extends Item(Mano){
    override def puedeEquipar(heroe: Heroe) = heroe.trabajo == Some(Mago) || heroe.trabajo == Some(Ladron) && heroe.inteligenciaBase > 30
  }
  
  object armaduraEleganteSport extends Item(Armadura)
  
  object arcoViejo extends Item(Mano, Some(Mano))
  
  object talismanDedicacion extends Item(Talisman)
  
  object talismanMinimalismo extends Item(Talisman)
  
  object talismanMaldito extends Item(Talisman)
  
  object espaldaDeLaVida extends Item(Espalda)
  
  object escudoAntiRobo extends Item(Mano){
    override def puedeEquipar(heroe: Heroe) = heroe.trabajo != Some(Ladron) && heroe.fuerzaBase > 20 
  }
  
  
  case class Stats(
		hp: Double,
		fuerza: Double,
		velocidad: Double,
		inteligencia: Double
	)
}

