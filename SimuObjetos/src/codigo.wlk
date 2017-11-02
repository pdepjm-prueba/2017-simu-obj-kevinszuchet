class BiciclopeException inherits Exception {}
class ArreglarMaquinaException inherits Exception {}
class DefenderSectorException inherits Exception {}
class LimpiarSectorException inherits Exception {}
class CapatazException inherits Exception {}

/* MINIONS */
class Minion {
	
	var rol
	var stamina = 10
	var tareas = #{}
	
	constructor(_rol) { rol = _rol }
	
	method comerFruta(fruta) {
		self.aumentarStamina(fruta.aumentoStamina())
	}
	
	method aumentarStamina(cant) {
		stamina += cant
	}	
	
	method disminuirStamina(cant) {
		stamina -= cant
	}
	
	method realizarTareaSiPuede(tarea) {
		if (self.puedeRealizar(tarea)) {
			rol.realizar(tarea, self)
			tareas.add(tarea)
		}
	}
	
	method puedeRealizar(tarea) = tarea.puedeSerRealizada(self)
	
	method experiencia() = tareas.lenght() * tareas.sum({ tarea => tarea.dificultad(self) })
	
	method tieneHerramientasNecesarias(herramientasNecesarias) = herramientasNecesarias.lenght() == 0 || rol.tieneLasHerramientas(herramientasNecesarias)
	
	method fuerzaBase() = (stamina / 2) + 2 
	
	method fuerzaTotal() = (self.fuerzaBase() + rol.fuerzaExtra()) / self.factorRaza()
	
	method factorRaza() = 1
	
	method puedeDefender() = rol.buenoDefendiendo()
	
	method staminaPerdidaEnDefensa() = rol.staminaPerdidaDefendiendo(self)
	
	method factorStaminaPerdidaEnLimpieza() = rol.factorStaminaPerdidaLimpiando(self)
	
	method factorDificultad() = 1
}

class Biclope inherits Minion {
	
	constructor(_rol) = super(_rol)
	
	override method aumentarStamina(cant) {
		if (stamina + cant > 10)
			throw new BiciclopeException('Un biciclope no puede tener mas de 10 puntos de stamina')
		stamina += cant
	}
}

class Ciclope inherits Minion {
	
	constructor(_rol) = super(_rol)
			
	override method factorRaza() = 2
	override method factorDificultad() = 2
}

/* FRUTAS */
object banana {
	method aumentoStamina() = 10
}

object manzana {
	method aumentoStamina() = 5
}

object uva {
	method aumentoStamina() = 1
}

/* ROLES */
class Rol {	
	
	method tieneLasHerramientas(_) = false	
	
	method fuerzaExtra() = 0
	
	method buenoDefendiendo() = true
	
	method staminaPerdidaDefendiendo(empleado) = empleado.stamina() / 2
	
	method factorStaminaPerdidaLimpiando(empleado) = 1
	
	method realizar(tarea, empleado) {
		tarea.realizar(empleado)
	}
}

class Capataz inherits Rol {
	var subordinados = []
	
	method subordinadoQuePuedeRealizarTareas(tarea) = subordinados.filter({ empleado => empleado.puedeRealizar(tarea) })
	method subordinadoMasExperimentadoQuePuedeRealizar(tarea) {
 
		if (self.subordinadoQuePuedeRealizarTareas(tarea).lenght() > 0)
			return self.subordinadoQuePuedeRealizarTareas(tarea).sort({ sub1, sub2 => sub1.experiencia() > sub2.experiencia()}).head()
		else
			throw new CapatazException('No hay subordinados que puedan realizar la tarea') 
	}
	
	override method realizar(tarea, empleado) {
		try {
			tarea.realizar(self.subordinadoMasExperimentadoQuePuedeRealizar(tarea))			
		} catch e: CapatazException('No hay subordinados que puedan realizar la tarea') {
			empleado.realizarTareaSiPuede(tarea)
		}
	}
}

class Soldado inherits Rol {
	var danio
	
	constructor (_danio) {
		danio = _danio
	}
	
	override method fuerzaExtra() = danio
	
	method incrementarDanio(cant) {
		danio += cant
	}
	
	override method tieneLasHerramientas(_) = false
	
	override method staminaPerdidaDefendiendo(empleado) = empleado / 2
}

class Obrero inherits Rol {
	var herramientas
	
	constructor (_herramientas) {
		herramientas = _herramientas
	}
	
	override method tieneLasHerramientas(herramientasNecesarias) = herramientasNecesarias.all({ herramientaNecesaria => herramientas.contains(herramientaNecesaria) })
}

class Mucama inherits Rol {
	override method buenoDefendiendo() = false
	
	override method factorStaminaPerdidaLimpiando(empleado) = 0
}

/* TAREAS */
class ArreglarMaquina {
	var complejidad
	var herramientasNecesarias
	
	constructor (_complejidad, _herramientasNecesarias) {
		complejidad = _complejidad
		herramientasNecesarias = _herramientasNecesarias
	}
	
	method puedeSerRealizada(empleado) {
		if(empleado.stamina() >= complejidad && empleado.tieneHerramientasNecesarias(herramientasNecesarias))
			return true
		else
			throw new ArreglarMaquinaException('El minion no puede arreglar la maquina')
	}
	
	method realizar(empleado) {
		empleado.disminuirStamina(complejidad)				
	}
	
	method dificultad(_) = complejidad * 2
}

class DefenderSector {
	var gradoAmenaza
	var sector
	
	constructor (_gradoAmenaza, _sector) {
		gradoAmenaza = _gradoAmenaza
		sector = _sector
	}
	
	method puedeSerRealizada(empleado) {
		if(empleado.puedeDefender() && empleado.fuerza() >= gradoAmenaza)
			return true
		else
			throw new DefenderSectorException('El minion no puede defender el sector solicitado')
	}
	
	method realizar(empleado) {
		empleado.disminuirStamina(empleado.staminaPerdidaEnDefensa())
	}
	
	method dificultad(empleado) = gradoAmenaza * empleado.factorDificultad() 
}

class LimpiarSector {
	var dificultad = 10
	var staminaRequerida = 0
	var sector
	
	constructor(_dificultad, _staminaRequerida, _sector) {
		dificultad = _dificultad 
		staminaRequerida = _staminaRequerida
		sector = _sector		
	}
	
	method dificultad(_) = dificultad
	
	method modificarDificultad(nuevaDificultad) {
		dificultad = nuevaDificultad
	}
	
	method puedeSerRealizada(empleado) {
		if(self.cumpleCondicionDeRealizacion(empleado))
			true
		else
			throw new LimpiarSectorException('El minion no puede defender el sector solicitado')
	}
	
	method realizar(empleado) {
		empleado.disminuirStamina(staminaRequerida * empleado.factorStaminaPerdidaEnLimpieza())		
	}
	
	method cumpleCondicionDeRealizacion(empleado) = (sector.esGrande() && empleado.stamina() > 4) || (!sector.esGrande() && empleado.stamina() > 1)
}

/* SECTORES */
class Sector {
	var medida
	
	constructor(_medida) {
		medida = _medida
	}
	
	method esGrande() = medida > 10
}

/* HERRAMIENTAS */
class Herramienta {}