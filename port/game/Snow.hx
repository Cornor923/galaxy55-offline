import h3d.parts.GpuParticles;

/**
	Nieve que cae alrededor de la camara (anadido de este port: el juego original no la tiene).
	Usa las particulas en GPU de Heaps en modo CameraBounds: los copos quedan fijos en el mundo
	mientras la camara se mueve, y se reciclan alrededor de ella.
**/
class Snow {

	var parts : GpuParticles;

	public function new( parent : h3d.scene.Object ) {
		parts = new GpuParticles(parent);
		parts.volumeBounds = h3d.col.Bounds.fromValues(-18, -18, -10, 36, 36, 20);
		var g = parts.addGroup();
		g.name = "snow";
		g.emitMode = CameraBounds;
		g.emitDist = 1;
		g.nparts = 9000;
		g.life = 4;
		g.lifeRand = 0.35;
		g.size = 0.16;
		g.sizeRand = 0.5;
		g.speed = 0.8;
		g.speedRand = 0.5;
		g.gravity = 0.5;
		g.fadeIn = 0.05;
		g.fadeOut = 0.15;
		g.texture = h3d.mat.Texture.fromColor(0xFFFFFF);
		// sin iluminacion: los copos se ven blancos y no grisaceos
		for( m in parts.getMaterials() ) {
			m.shadows = false;
			m.mainPass.enableLights = false;
		}
	}

	public function dispose() {
		parts.remove();
	}
}
