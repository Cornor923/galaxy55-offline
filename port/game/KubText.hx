/**
 * Textos de la Base de datos ESCorp (Kubindex, DatabasePanel) en espanol, ingles y frances, aparte de Lang para no alargarlo.
 * %n%, %t%, %g%, %s%, %p% y %b% se cambian donde se usan.
 */
class KubText {

	// clave => [es, en, fr]
	static var T : Map<String, Array<String>> = [
		"computer.database" => ["Base de datos ESCorp", "ESCorp database", "Base de données ESCorp"],
		"title" => ["BASE DE DATOS ESCORP", "ESCORP DATABASE", "BASE DE DONNÉES ESCORP"],
		"tab.kubindex" => ["Kubindex", "Kubindex", "Kubindex"],
		"tab.planets" => ["Espacio", "Space", "Espace"],
		"tab.recipes" => ["Recetas", "Recipes", "Recettes"],
		"hint" => [
			"Tab: pestaña   Flechas: elegir   Intro: abrir   Esc: cerrar",
			"Tab: tab   Arrows: choose   Enter: open   Esc: close",
			"Tab : onglet   Flèches : choisir   Entrée : ouvrir   Échap : fermer"],
		// categorias del Kubindex
		"kub.cat.all" => ["Todos", "All", "Tous"],
		"kub.cat.planet" => ["Planetas", "Planets", "Planètes"],
		"kub.cat.anomaly" => ["Anomalías", "Anomalies", "Anomalies"],
		"kub.cat.comet" => ["Cometas", "Comets", "Comètes"],
		"kub.cat.craft" => ["Fabricados", "Crafted", "Fabriqués"],
		"kub.cat.special" => ["Especiales", "Special", "Spéciaux"],
		"kub.tag.planet" => ["Planeta", "Planet", "Planète"],
		"kub.tag.anomaly" => ["Anomalía", "Anomaly", "Anomalie"],
		"kub.tag.comet" => ["Cometa", "Comet", "Comète"],
		"kub.tag.craft" => ["Fabricable", "Craftable", "Fabricable"],
		"kub.tag.special" => ["Especial", "Special", "Spécial"],
		"kub.count" => ["%g% recuperados · %s% identificados", "%g% collected · %s% identified", "%g% récupérés · %s% identifiés"],
		"kub.empty" => [
			"Ningún kube en esta categoría. Apunta a un kube con el láser para identificarlo.",
			"No kube in this category yet. Aim at a kube with your laser to identify it.",
			"Aucun kube dans cette catégorie. Vise un kube avec ton laser pour l'identifier."],
		"kub.unknown" => ["???", "???", "???"],
		"kub.status.got" => ["Recuperado", "Collected", "Récupéré"],
		"kub.status.seen" => ["Identificado", "Identified", "Identifié"],
		"kub.where.planets" => ["Planetas:", "Planets:", "Planètes :"],
		"kub.where.anomalies" => ["Anomalías:", "Anomalies:", "Anomalies :"],
		"kub.where.comets" => ["Cometas:", "Comets:", "Comètes :"],
		"kub.where.special" => ["Especial: solo lo suministra la ESCorp", "Special: supplied by ESCorp only", "Spécial : fourni uniquement par l'ESCorp"],
		"kub.short.craft" => ["Sintetizador", "Synthesizer", "Synthétiseur"],
		"kub.drop.charge" => ["Al minarlo da %n% × %c%", "When mined: gives %n% × %c%", "Au minage : donne %n% × %c%"],
		"kub.charge" => ["Láser: necesita una carga %n%", "Laser: needs a %n% charge", "Laser : charge %n% nécessaire"],
		"charge.CYellow" => ["amarilla", "yellow", "jaune"],
		"charge.CBlue" => ["azul", "blue", "bleue"],
		"charge.CPink" => ["rosa", "pink", "rose"],
		"charge.CBonus" => ["de bonus", "bonus", "bonus"],
		"kub.stats" => ["Puestos: %p%   Rotos: %b%", "Placed: %p%   Broken: %b%", "Posés : %p%   Cassés : %b%"],
		"kub.made" => ["Fabricación", "Crafting", "Fabrication"],
		"kub.uses" => ["Se usa en", "Used in", "Utilisé dans"],
		"kub.locked" => [
			"Recupera este kube para desbloquear sus recetas y sus estadísticas.",
			"Collect this kube to unlock its recipes and statistics.",
			"Récupère ce kube pour débloquer ses recettes et ses statistiques."],
		"kub.choose" => ["Elige un kube.", "Choose a kube.", "Choisis un kube."],
		// avisos en el juego
		"kub.seen" => ["ESCorp · Kube identificado", "ESCorp · Kube identified", "ESCorp · Kube identifié"],
		"kub.newanomaly" => ["ESCorp · Anomalía identificada", "ESCorp · Anomaly identified", "ESCorp · Anomalie identifiée"],
		"kub.got" => ["ESCorp · Nuevo kube", "ESCorp · New kube", "ESCorp · Nouveau kube"],
		"kub.newbiome" => ["ESCorp · Nuevo tipo de planeta", "ESCorp · New planet type", "ESCorp · Nouveau type de planète"],
		"kub.newcomet" => ["ESCorp · Nuevo tipo de cometa", "ESCorp · New comet type", "ESCorp · Nouveau type de comète"],
		// planetas
		"pl.planets" => ["Tipos de planeta", "Planet types", "Types de planètes"],
		"pl.comets" => ["Tipos de cometa", "Comet types", "Types de comètes"],
		"pl.explored" => ["Explorados: %n%", "Explored: %n%", "Explorées : %n%"],
		"pl.unknown" => ["Tipo desconocido", "Unknown type", "Type inconnu"],
		"pl.notexplored" => [
			"Explora un planeta de este tipo para conocer sus kubes.",
			"Explore a planet of this type to learn its kubes.",
			"Explore une planète de ce type pour connaître ses kubes."],
		"pl.progress" => ["Kubes recuperados: %g% / %t%", "Kubes collected: %g% / %t%", "Kubes récupérés : %g% / %t%"],
		"pl.terrain" => ["Terreno", "Terrain", "Terrain"],
		"pl.blocks" => ["Kubes", "Kubes", "Kubes"],
		"pl.anomalies" => ["Anomalías posibles", "Possible anomalies", "Anomalies possibles"],
		"pl.anomalytypes" => ["Anomalías", "Anomalies", "Anomalies"],
		"pl.anomalyunknown" => ["Anomalía desconocida", "Unknown anomaly", "Anomalie inconnue"],
		"pl.anomalynone" => ["Ninguna anomalía en las cometas.", "No anomalies on comets.", "Aucune anomalie sur les comètes."],
		"pl.anomalymore" => ["%n% desconocidas", "%n% unknown", "%n% inconnues"],
		"pl.everywhere" => ["Todos los planetas", "Every planet", "Toutes les planètes"],
		"pl.caves" => ["(cuevas)", "(caves)", "(grottes)"],
		"pl.found" => ["Kubes identificados: %g% / %t%", "Kubes identified: %g% / %t%", "Kubes identifiés : %g% / %t%"],
		// recetas
		"rc.count" => ["Recetas descubiertas: %n% / %t%", "Recipes discovered: %n% / %t%", "Recettes découvertes : %n% / %t%"],
		"rc.made" => ["Fabricada %n% veces", "Crafted %n% times", "Fabriquée %n% fois"],
		"rc.never" => ["Nunca fabricada", "Never crafted", "Jamais fabriquée"],
		"rc.empty" => [
			"Recupera kubes para descubrir recetas.",
			"Collect kubes to discover recipes.",
			"Récupère des kubes pour découvrir des recettes."],
		"rc.square" => ["cuadrado %n%×%n%", "%n%×%n% square", "carré %n%×%n%"],
		"rc.line" => ["línea de %n%", "line of %n%", "ligne de %n%"],
		"rc.layer" => ["Niv. %n%", "Lvl %n%", "Niv. %n%"],
	];

	/** texto en el idioma elegido */
	public static function get( key : String ) : String {
		var a = T.get(key);
		return a == null ? key : a[Lang.cur];
	}
}
