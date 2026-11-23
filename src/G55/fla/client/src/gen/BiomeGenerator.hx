package gen;

import Common;
import gen.Generator;

class BiomeGenerator extends Generator {
	
	static inline var EMPTY = Generator.EMPTY;
	static inline var BEDROCK = Generator.BEDROCK;
	static inline var WATER = Generator.WATER;
	
	static inline var CAVE = Generator.CAVE;
	
	static inline var ROCK = Generator.ROCK;
	static inline var SOIL = Generator.SOIL;
	
	static inline var HBITS = Generator.HBITS;
	static inline var HEIGHT = Generator.HEIGHT;

	override function initBiome(biome) {
		switch( biome ) {
		case BIAutumn:
			waterLevel = 32;
			globalScale = 2;
			
			Macro.generate({
				var t = 0.;
				t += addHeight(1, 1);
				t += addHeight(2, 0.5);
				t += addHeight(3, 0.333);
				t += addHeight(4, 0.25);
				t += addHeight(10, 0.4);
				addMulHeight(t, 0.5 / t);
				adjustHeight(1, 1);
				addMulHeight( -0.5, 2);
				
				fillHeight([ { v : -1., h : -32 }, {v : -0.7, h:0 }, { v : 0.2, h : 5 }, { v : 1.0, h : 92 }]);
				
				smoothHeight();
				smoothHeight();
				fillSoil(0.5);
				addHolesLater(4.5, [{ h : waterLevel, v : -0.8 },{ h : maxHeight, v : 0.5 }]);
				addCaves(1, 1, BBrokenRock);
				saveCaveMask();
				removeBlobs();
				smooth3DLater(smoothAgain);
				
				addHighForest();
				addBunker(BRock, 0.5);
				addSand(BAutumnStraw);
				addHerbs(BAutumnHerbs1, BAutumnHerbs2, 1.0, 1.0);
				addHerbs(BAutumnHerbs1, BAutumnHerbs2, 0.5, 1.5);
				addRandom(BPinkFlower, 10);
				addRandomUnderwater( BWood, 100 );
				addCaveCrystals(1.0, BBlueCrystalLight, BBlueCrystalDense, BBrokenRock);
				addMineralsRocks(1);
				
			});
		case BIMoon:
			waterLevel = 32;
			globalScale = 5;
			Macro.generate({
				addHeight(1, 1);
				addHeight(5, 0.15);
				addMulHeight(1, 0.5);
				fillHeight([ {v:0., h:-32}, {v:0.26, h:0}, {v:0.3, h:4}, {v:0.3, h:16}, {v:0.7, h:20}, {v:0.7, h:60}, {v:0.9, h:60}]);//, {v:0.9, h:50}, {v:1.2, h:52 } ]);
				smoothHeight();
				lowerChunks(70, 25);
				fillSoil(0);
				addHoles(6, [ { h : 20 + waterLevel, v : -0.8 }, { h : 55 + waterLevel, v : -0.5 }, { h : 60 + waterLevel, v : -1. } ]);
				addCaves(0.3, 1.5, BMoonBrokenRock);
				addCavePillars(BMoonRockColumn);
				addCaveChampi(BStainPurple);
				removeBlobs();
				addMoonTrees();
				addCliffBalls(75, BPurpleLeaves, BPinkLeaves);
				addBunker(BMoonRock, 2.5);
				addSand(BMoonSand);
				addHerbs(BMoonHerbs1, BMoonHerbs2, 2.0, 0.5);
				addHerbs(BMoonHerbs1, BMoonHerbs2, 0.5, 1.5);
				addRandomFun(makePilar(1, 5, BMoonLightColumn, BMoonLightDead), 8);
				addRandomFun(makePilar(1, 5, BMoonLightColumn, BMoonLight), 20);
				
				addCaveCrystals(1.0, BBlueCrystalLight, BBlueCrystalDense, BMoonBrokenRock);
				addMineralsRocks(1);

				addRandomUnderwater(BCoral2, 100);
			});
		case BIAcidForest:
			waterLevel = 32;
			globalScale = 3;
			Macro.generate({
				addHeight(1, 1);
				addHeight(4, 0.4);
				addHeight(4, 0.4);
				addHeight(4, 0.4);
				fillHeight([ { v : -1., h : -16 }, { v : 0.1, h : 0 }, { v : 1, h : 8 } ]);
				smoothHeight();
				smoothHeight();
				fillSoil(0);
				smooth3DLater(smoothAgain);
				addAcidTrees();
				
				addHerbs(BAcidHerb1, BAcidHerb2, 0.2, 2);
				replaceSomeBlocksLater(BAcidHerb2, BYellowPlant, 10);
				replaceSomeBlocksLater(BYellowPlant, BBluePlant, 20);
				
				var b = alloc(BCoral1);
				addRandomUnderwaterFun(function(x,y,z) {
					for(h in 0...rnd.random(4)+1)
						set(x,y,z+h, b);
				}, 50);
				
				removeBlobs();
			});
			
		case BIWinterPeaks:
			waterLevel = 32;
			globalScale = 5;
			Macro.generate( {
				var t = 0.;
				t += addHeight(1, 1);
				t += addHeight(2, 0.5);
				t += addHeight(3, 0.333);
				t += addHeight(4, 0.25);
				t += addHeight(10, 0.4);
				addMulHeight(t, 0.5 / t);
				adjustHeight(1, 1);
				addMulHeight( -0.5, 2);
				
				fillHeight([ { v : -1., h : -32 }, { v : -0.5, h : 0 }, { v : 0.7, h : 5 }, { v : 0.8, h : 32 }, { v : 1., h : 70 } ]);
				smoothHeight();
				smoothHeight();
				fillSoil(0);
				
				// los 10 agujeros uno detras de otro, cada uno repartido (anadido del port, ver Generator.jobs): mismo azar y orden
				spread(10, function(_) addHolesLater(2 + rnd.rand() * 2, [ { h : 34, v : -0.9 }, { h : 35, v : -0.7 } ], CAVE));
				addHolesLater(2, [ { h : 22, v : -0.8 }, { h : 24, v : -0.5 }, { h : 31, v : -0.6 }, { h : 33, v : -0.9 }, { h : 37, v : -1 } ], CAVE);
				
				smooth3DLater(smoothAgain);

				addCaves(2, 0.75, BWinterBrokenRock);
				addCaveCrystals(3.0, BBlueCrystalLight, BBlueCrystalDense, BWinterBrokenRock, CAVE);
				addCaveMinerals(4.0, 30,100);
				
				addCaveAccesses(30);
				saveCaveMask();
				
				removeBlobs();
				
				addWinterDetails();
				
				addBunker(BBlackIce, 0.15, BBlackIceLight);
				addHerbs(BWinterHerb1, BWinterHerb2, 1.5, 1.5);
				addHerbs(BWinterHerb2, BWinterHerb3, 1.0, 1.0);
				
				addRandomUnderwater(BIce, 5);

				replaceSomeBlocksLater(BWinterHerb2, BFreezerPlant, 12);
			});
		case BIMars:
			waterLevel = 16;
			globalScale = 2;
			Macro.generate( {
				var t = 0.;
				t += addHeight(1, 1);
				t += addHeight(2, 0.5);
				t += addHeight(3, 0.333);
				t += addHeight(4, 0.25);
				t += addHeight(10, 0.4);
				addMulHeight(t, 0.5 / t);
				adjustHeight(1, 1);
				addMulHeight( -0.5, 2);

				fillHeight([ { v : -1., h : -16 }, { v : -0.95, h : 0 }, { v : -0.8, h : 64 }, { v : 1., h : 75 }, { v : 1.12, h : 16 } ]);
				adjustMarsHeight();
				fillSoil(0);
				
				for( i in 0...100 )
					addHoles(3 + rnd.rand() * 3, [ { h : 16, v : -0.7 }, { h : 75, v : -0.8 }, { h : 75, v : -2. } ], EMPTY);
					
				// version 1: como mucho SMOOTH_PASSES * 2 pasadas (antes hasta que no cambiara nada)
				for( i in 0...Generator.SMOOTH_PASSES * 2 ) if( smooth3D(0, 32) == 0 ) break;
				
				addBunker(BMarsQuickSand, 0.5);
				
				addMarsDetails();
				addHerbs(BMarsHerb1, BMarsHerb2, 3.0, 2.0);
				addHerbs(BMarsHerb3, BMarsHerb2, 3.0, 2.0);
				
				addCaveMinerals(2.0, 12, 20, EMPTY);
				addCaveMinerals(1.0, 20, 60, EMPTY);
				addCaveMinerals(0.5, 70, 90, EMPTY);
				
				for(x in 0...size) // un peu lourd non ?
					for(y in 0...size)
						for(z in 0...60)
							if( get(x,y,z)==EMPTY )
								set(x,y,z, CAVE);
				saveCaveMask();
				
				removeBlobs();
			});
		
		case BIDeadCity:
			waterLevel = 32;
			globalScale = 1.0;
			Macro.generate({
				var t = 0.;
				t += addHeight(1, 1);
				t += addHeight(2, 0.5);
				t += addHeight(3, 0.333);
				t += addHeight(4, 0.25);
				t += addHeight(10, 0.4);
				addMulHeight(t, 0.5 / t);
				adjustHeight(1, 1);
				addMulHeight( -0.5, 2);
				fillHeight([ { v : -1., h : -32 }, { v : -0.5, h : 0 }, /*{ v : 0, h : 30 }, { v : 0.7, h : 0 }, { v : 0.7, h : 20 },*/ { v : 1.3, h : 40 } ]);
				createHeightsLevels(35, 5);
				fillSoil(0);
				
				addDeadDetails();
			});
					
		case BIGreyHaven:
			// anadido del port: el planeta de los kubes de Grey Haven (agua 15 %, mesetas 15 %, bosque 50 %, llano 20 %)
			waterLevel = 32;
			globalScale = 2;
			Macro.generate({
				var t = 0.;
				t += addHeight(1, 1);
				t += addHeight(2, 0.5);
				t += addHeight(3, 0.333);
				t += addHeight(6, 0.15);
				addMulHeight(t, 0.5 / t);
				ghHeights();
				ghCuesta();
				ghSmooth();
				ghSmooth();
				fillSoil(0);
				ghTopsoil();
				ghLakeBed();
				addCaves(0.6, 1, BKubeGreyHavenRocks);
				ghCaveRoof();
				ghCaveEntrances();
				ghCaveGlow();
				addCaveMinerals(0.3, 5, 60);
				saveCaveMask();
				removeBlobs();
				addMineralsRocks(1);
				addSand(BKubeGreyHavenSand);
				ghForestMask();
				ghSoilCover();
			});

		default:
			waterLevel = 64;
			globalScale = 5;
			Macro.generate({
				addHeight(1, 1);
				fillHeight([ { v : -1., h : -64 }, { v : 1., h : 64 } ]);
				smoothHeight();
				smoothHeight();
				fillSoil(0);
				if( smooth3D() > 0 && stepTries[curPosition - 1] < Generator.SMOOTH_PASSES ) stepRetry();
			});
		}
	}
	
	function addRandomUnderwaterFun( f:Int->Int->Int->Void, proba : Int ) {
		for( y in 0...size )
			for( x in 0...size ) {
				if( rnd.random(proba)!=0 )
					continue;
				var h = height(x,y);
				if( h>=waterLevel-2 )
					continue;
				var u = get(x,y,h-1);
				if( get(x, y, h) == WATER && (u==SOIL || u==BEDROCK) )
					f(x,y,h);
			}
	}
	
	function addRandomUnderwater( b:BlockKind, proba : Int ) {
		var b = alloc(b);
		for( y in 0...size )
			for( x in 0...size ) {
				if( rnd.random(proba)!=0 )
					continue;
				var h = height(x,y);
				if( h>=waterLevel-2 )
					continue;
				var u = get(x,y,h-1);
				if( get(x, y, h) == WATER && (u==SOIL || u==BEDROCK) )
					set(x,y,h, b);
			}
	}
	
	function addRandom( k : BlockKind, proba : Int ) {
		var block = alloc(k);
		for( y in 0...size )
			for( x in 0...size ) {
				if( x & 3 != 0 || y & 3 != 0 || hash(x + y * size) % proba != 0 ) continue;
				var h = height(x,y);
				if( get(x, y, h - 1) != SOIL ) continue;
				oset(x, y, h, block);
			}
	}

	function addRandomFun( f : Int -> Int -> Int -> Bool, proba : Int ) {
		for( y in 0...size )
			for( x in 0...size ) {
				if( x & 3 != 0 || y & 3 != 0 || hash(x + y * size) % proba != 0 ) continue;
				var h = height(x,y);
				if( get(x, y, h - 1) != SOIL ) continue;
				f(x, y, h);
			}
	}
	
	function makePilar( zmin : Int, zmax : Int, bcol, btop ) {
		var bcol = alloc(bcol);
		var btop = alloc(btop);
		return function(x, y, z) {
			var size = zmin + rnd.random(zmax - zmin + 1);
			for( i in 1...size )
				if( get(x, y, z + 1) != EMPTY )
					return false;
			for( i in 0...size )
				set(x, y, z + i, bcol);
			set(x, y, z + size, btop);
			return true;
		};
	}
	
	function addCaveCrystals( amount = 1.0, b, bcond, brk, bempty = EMPTY ) {
		var b = alloc(b);
		var bcond = alloc(bcond);
		var brk = alloc(brk);
		for( i in 0...Std.int(size * size * amount / 100) ) {
			var x = rnd.random(size);
			var y = rnd.random(size);
			var zmax = height(x,y);
			var z = rnd.random(zmax);
			while( z < zmax ) {
				if( get(x, y, z) != ROCK )
					break;
				if( get(x - 1, y, z) == bempty || get(x + 1, y, z) == bempty || get(x, y - 1, z) == bempty || get(x, y + 1, z) == bempty ) {
					setBlockRec(x, y, z, ROCK, brk, 10 + rnd.random(10));
					var count = 0, max = 4;
					while( count < max ) {
						for( i in 0...100 ) {
							var x = x + rnd.random(10) - 5;
							var y = y + rnd.random(10) - 5;
							var z = z + rnd.random(10) - 5;
							if( get(x, y, z) == brk ) {
								set(x, y, z, rnd.random(8) == 0 ? bcond : b);
								count++;
							}
						}
						max--;
					}
					z += rnd.random(10) + 1;
				} else
					z++;
			}
		}
	}
	
	
	function addCaveMinerals(amount:Float,zmin,zmax,cave=CAVE) {
		var hard = alloc(BHardRock);
		for( i in 0...Math.round(size * size * amount / 4300) ) {
			var ntry = 2000;
			while( ntry-- > 0 ) {
				var x = rnd.random(size);
				var y = rnd.random(size);
				var z = height(x, y);
				if( z > zmax ) z = zmax;
				while( z >= zmin ) {
					if( get(x, y, z) == cave )
						break;
					z -= 1 + rnd.random(4);
				}
				if( z < zmin ) continue;
				while( z < zmax && get(x,y,z) == cave )
					z++;
				if( z >= zmax ) continue;
			
				var el = [];
				for( i in 0...4 ) {
					var x = x + rnd.random(6) - 3;
					var y = y + rnd.random(6) - 3;
					var z = z + rnd.random(6) - 3;
					el.push( { x : x, y :y, z : z, sx : 1.5 + rnd.rand()*2, sy : 1.5 + rnd.rand()*2, sz : 1.5 + rnd.rand()*2 } );
				}
			
				var empty = 0, full = 0;
				for( e in el )
					elipse(e.sx, e.sy, e.sz, function(dx, dy, dz) {
						if( get(e.x+dx, e.y+dy, e.z+dz)&127 == EMPTY ) empty++ else full++;
					});
				
				var ratio = (empty + 1) / (empty + full + 1);
				if( ratio < 0.1 || ratio > 0.8 )
					continue;

				var pts = [];
				for( e in el )
					elipse(e.sx, e.sy, e.sz, function(dx, dy, dz) {
						var x = e.x + dx, y = e.y + dy, z = e.z + dz;
						if( get(x, y, z) & 127 == ROCK && (cave == EMPTY || !around(x,y,z,EMPTY)) ) {
							set(x, y, z, hard);
							pts.push( { x : x, y : y, z : z } );
						}
					});
				fillMinerals(pts);
				break;
			}
		}
	}
	
	function addMineralsRocks( ratio:Float, ?bempty = EMPTY ) {
		var hard = alloc(BHardRock);
		for( i in 0...Math.round(ratio*size*size/4300) ) {
			// version 1: 1000 sitios como mucho (antes sin fin)
			var ntry = 1000;
			while( ntry-- > 0 ) {
				var x = rnd.random(size);
				var y = rnd.random(size);
				var zmax = height(x, y);
				var z = -1;
				for( i in rnd.random(zmax)...zmax )
					if( get(x, y, i) == bempty ) {
						z = i;
						break;
					}
				if( z < 0 ) continue;
								
				var el = [];
				for( i in 0...4 ) {
					var x = x + rnd.random(6) - 3;
					var y = y + rnd.random(6) - 3;
					var z = z + rnd.random(6) - 3;
					el.push( { x : x, y :y, z : z, sx : 2 + rnd.random(3), sy : 2 + rnd.random(3), sz : 2 + rnd.random(2) } );
				}
				
				var empty = 0, full = 0;
				for( e in el )
					elipse(e.sx, e.sy, e.sz, function(dx, dy, dz) {
						if( get(e.x+dx, e.y+dy, e.z+dz) == bempty ) empty++ else full++;
					});
				var ratio = (empty + 1) / (empty + full + 1);
				if( ratio < 0.03 || ratio > 0.2 )
					continue;
				var pts = [];
				for( e in el )
					elipse(e.sx, e.sy, e.sz, function(dx, dy, dz) {
						set(e.x + dx, e.y + dy, e.z + dz, hard);
						pts.push( { x : e.x + dx, y : e.y + dy, z : e.z + dz } );
					});
				fillMinerals(pts);
				break;
			}
		}
	}
	
	function density( x, y, z, xx, yy, zz, bempty = EMPTY ) {
		var empty = 0, total = 0;
		elipse(xx, yy, zz, function(dx,dy,dz) {
			if( get(x + dx, y + dy, z + dz) == bempty )
				empty++;
			total++;
		});
		return empty / total;
	}
	
	function fillMinerals( pts : Array<{x:Int,y:Int,z:Int}> )  {
		var min = randMineral();
		function isEmpty(x, y, z) {
			var b = get(x, y, z);
			return b == EMPTY || b == WATER || b == CAVE;
		}
		for( i in 0...Std.int(pts.length / 6) ) {
			var p = pts[rnd.random(pts.length)];
			if( p == null ) break;
			pts.remove(p);
			if( isEmpty(p.x - 1, p.y, p.z) || isEmpty(p.x + 1, p.y, p.z) || isEmpty(p.x, p.y - 1, p.z) || isEmpty(p.x, p.y + 1, p.z) || isEmpty(p.x, p.y, p.z - 1) || isEmpty(p.x, p.y, p.z + 1) ) {
				if( rnd.random(5) != 0 ) continue;
			}
			set(p.x, p.y, p.z, min);
		}
	}
	
	function setBlockRec(x, y, z, old, b, n) {
		for( i in 0...n ) {
			set(x, y, z, b);
			switch( rnd.random(9)>>1 ) {
			case 0: if( get(x - 1, y, z) == old ) x--;
			case 1: if( get(x + 1, y, z) == old ) x++;
			case 2: if( get(x, y - 1, z) == old ) y--;
			case 3: if( get(x, y + 1, z) == old ) y++;
			}
		}
	}

	
	function addHerbs( block, block2, amount:Float, scale : Float) {
		var block = alloc(block), block2 = alloc(block2);
		var count = Std.int((size * size) / 3000);
		var w = waterLevel;
		for( i in 0...count ) {
			var ntry = 100;
			while( ntry-- > 0 ) {
				var x = rnd.random(size);
				var y = rnd.random(size);
				var z = height(x,y);
				if( fget(addr(x, y, z-1)) == SOIL && fget(addr(x, y, z)) == EMPTY ) {
					for( i in 0...4 ) {
						var x = real(x + Math.ceil((rnd.random(12) - 6) * scale));
						var y = real(y + Math.ceil((rnd.random(12) - 6) * scale));
						elipse( Math.ceil((4 + rnd.random(6)) * scale), Math.ceil((4 + rnd.random(6))*scale), 0, function(dx, dy, _) {
							var x = real(x + dx);
							var y = real(y + dy);
							if( hash(x + y * size) % 100 < 60 ) return;
							var h = height(x,y);
							// version 1: la variante se tira al ponerla (antes la paridad del mismo hash que decide si se pone)
							if( h - z <= 2 && h - z >= -2 && get(x,y,h-1) == SOIL )
								oset(x, y, h, rnd.random(2) == 0 ? block : block2);
						});
					}
					break;
				}
			}
		}
	}
	
	function addBunker( block, ratio:Float, ?core:BlockKind ) {
		var block = alloc(block);
		var core = if( core!=null ) alloc(core) else null;
		var count = Std.int(ratio * (size * size) / 3000);
		for( i in 0...count ) {
			var ntry = 100;
			while( ntry-- > 0 ) {
				var x = rnd.random(size);
				var y = rnd.random(size);
				var z = height(x,y)-1;
				if( fget(addr(x, y, z)) == SOIL ) {
					var n = 4;
					var all = [];
					for( i in 0...n ) {
						var x = real(x + rnd.random(12) - 6);
						var y = real(y + rnd.random(12) - 6);
						elipse(3 + rnd.random(5), 3 + rnd.random(5), 4, function(dx, dy, dz) {
							var a = addr(real(x + dx), real(y + dy), z + dz);
							if( fget(a) == SOIL ) {
								fset(a, block);
								all.push(a);
							}
						});
					}
					if( core!=null )
						for( i in 0...rnd.random(n)+1 )
							if( all.length>0 )
								fset( all.splice(rnd.random(all.length), 1)[0], core );
					break;
				}
			}
		}
	}
	
	function addSand( block ) {
		var block = alloc(block);
		var count = Std.int((size * size) / 3000);
		var w = waterLevel;
		for( i in 0...count ) {
			var ntry = 100;
			while( ntry-- > 0 ) {
				var x = rnd.random(size);
				var y = rnd.random(size);
				if( rnd.random(100) == 0 || (fget(addr(x, y, w)) == WATER && (fget(addr(real(x + 1), y, w)) == SOIL || fget(addr(x, real(y + 1), w)) == SOIL)) ) {
					for( i in 0...4 ) {
						var x = real(x + rnd.random(12) - 6);
						var y = real(y + rnd.random(12) - 6);
						elipse(4 + rnd.random(6), 4 + rnd.random(6), 4, function(dx, dy, dz) {
							var a = addr(real(x + dx), real(y + dy), w + dz);
							if( fget(a) == SOIL ) fset(a, block);
						});
					}
					break;
				}
			}
		}
	}
	
	function addCliffBalls(zmin, mainBlock, secBlock) {
		var mainBlock = alloc(mainBlock);
		var secBlock = alloc(secBlock);
		var crystal = alloc(BYellowCrystalDense);
		var crystalLight = alloc(BYellowCrystalLight);
		var count = Std.int((size*size / 300));
		var delta = 6;
		
		// feuillages
		var balls = new Array();
		for( i in 0...count ) {
			var ntry = 100;
			while( ntry-->0 ) {
				var x = rnd.random(size-2)+1;
				var y = rnd.random(size-2)+1;
				var h = height(x,y);
				if( h>=zmin && ( h-height(x-1,y)>=delta || h-height(x+1,y)>=delta || h-height(x,y-1)>=delta || h-height(x,y+1)>=delta ) ) {
					var z = zmin+rnd.random(h-zmin);
					for( j in 0...4 ) {
						var x = real(x + rnd.random(6) - 3);
						var y = real(y + rnd.random(6) - 3);
						balls.push({x:x,y:y,z:z});
						var sz = 1+rnd.random(2);
						elipse(3 + rnd.random(3), 3 + rnd.random(3), sz, function(dx, dy, dz) {
							var a = addr(real(x + dx), real(y + dy), z + dz);
							if( fget(a) == EMPTY ) {
								if( rnd.random(100)>=20 )
									fset(a, mainBlock);
								else
									fset(a, secBlock);
									
							}
						});
					}
					break;
				}
			}
		}
		
		// crystaux (version 1: sin bolas de follaje no hay donde ponerlos; antes balls[0] era null)
		var count = balls.length == 0 ? 0 : Std.int((size*size / 1000));
		for(i in 0...count) {
			var ntry = 100;
			while( ntry-->0 ) {
				var b = balls[rnd.random(balls.length)];
				var x = real(b.x+rnd.random(3));
				var y = real(b.y+rnd.random(3));
				var z = real(b.z-rnd.random(2));
				if( (get(x,y,z)==mainBlock || get(x,y,z)==secBlock) && get(x,y,z-1)==EMPTY ) {
					set(x,y,z-1, crystal);
					break;
				}
			}
		}
		
		// crystaux morts
		var count = balls.length == 0 ? 0 : Std.int((size*size / 300));
		for(i in 0...count) {
			var ntry = 100;
			while( ntry-->0 ) {
				var b = balls[rnd.random(balls.length)];
				var x = real(b.x+rnd.random(3));
				var y = real(b.y+rnd.random(3));
				var z = real(b.z-rnd.random(2));
				if( (get(x,y,z)==mainBlock || get(x,y,z)==secBlock) && get(x,y,z-1)==EMPTY ) {
					while( get(x,y,z-1)==EMPTY )
						z--;
					var base = get(x,y,z-1);
					if( base==SOIL || base==ROCK )
						set(x,y,z, crystalLight);
					break;
				}
			}
		}
	}

	function addHighForest() {
		initPerlin(2);
		var tree = alloc(BWood), leaves = alloc(BGreenLeaves), champi = alloc(BChampiLight), vines = [alloc(BVines), alloc(BVinesY)];
		var cactus = alloc(BCactus);
		var cactusBase = alloc(BCactusBase);
		var cactusFlower = alloc(BCactusFlower);
		var lightCrystal = alloc(BYellowCrystalLight);
		var denseCrystal = alloc(BYellowCrystalDense);
		for( y in 0...size )
			for( x in 0...size ) {
				if( (x + y) & 1 != 0 ) continue;
				
				var p = x + y * size;
				var h = hval(p);
				if( h == 0 || h > 50 || fget((p << HBITS) + h - 1) != SOIL || fget((p << HBITS) + h) != EMPTY ) continue;
				
				
				var hp = hash(p);
				var g = perlin2D(x, y);
				if( g < 0 ) {
					if( g < -0.25 && x%3 == 0 && y%3==0 && hp % 10 == 0 ) {
						fset((p << HBITS) + h - 1, cactusBase);
						fset((p << HBITS) + h, cactus);
						for(i in 0...rnd.random(5)+1)
							fset((p << HBITS) + h + 1 + i, (rnd.random(100)<20) ? cactusFlower : cactus );
					}
					continue;
				}
				
				if( hp & 7 != 0 ) {
					if( hp & (511-7) == 0 )
						fset((p << HBITS) + h, champi);
					continue;
				}
								
				var size = rnd.random(10) + 15;
				for( i in 1...size+1 ) {
					var z = h + size - i;
					fset((p << HBITS) + z, tree);
				}
				var count = 20;
				for( i in 0...count ) {
					var x : Float = x, y : Float = y, z = h + size;
					var angle = i * 6.28 / count;
					for( i in 0...10 ) {
						var ix = Std.int(x), iy = Std.int(y);
						oset(Std.int(x), Std.int(y), z, leaves);
						if( rnd.random(403) == 0 && get(Std.int(x), Std.int(y), z) == leaves )
							oset(Std.int(x), Std.int(y), z - 1, denseCrystal);
						if( rnd.random(403) == 0 && get(Std.int(x),Std.int(y),h-1) == SOIL )
							oset(Std.int(x), Std.int(y), h, lightCrystal);
						x += Math.cos(angle) * 0.4;
						y += Math.sin(angle) * 0.4;
					}
				}
				for( i in 0...15 ) {
					var x = rnd.random(12) - 6 + x;
					var y = rnd.random(12) - 6 + y;
					var z = h + size - 1;
					var v = vines[rnd.random(2)];
					if( get(x, y, z + 1) == leaves ) {
						var h = (size >> 2) + rnd.random(size >> 2);
						while( h-- > 0 ) {
							if( !oset(x, y, z, v) )
								break;
							z--;
						}
					}
				}
			}
	}

	function addClassicTrees() {
		var tree = alloc(BWood), leaves = alloc(BGreenLeaves);
		for( y in 0...size )
			for( x in 0...size ) {
				if( (x + y) & 1 != 0 ) continue;
				var p = x + y * size;
				var h = hval(p);
				if( h == 0 || h > 40 || fget((p << HBITS) + h - 1) != SOIL || fget((p << HBITS) + h) != EMPTY || hash(p) & 63 != 0 ) continue;
				var size = rnd.random(10) + 6;
				for( i in 0...size-2 )
					fset((p<<HBITS) + i + h, tree);
				var count = 30;
				for( i in 0...count ) {
					var x : Float = x, y : Float = y, z : Float = h + size-1;
					var angle = i * 6.28 / count;
					var gravity = -rnd.rand() * 0.3;
					while( z > h + (size >> 1) ) {
						oset(Std.int(x), Std.int(y), Std.int(z), leaves);
						x += Math.cos(angle) * 0.4;
						y += Math.sin(angle) * 0.4;
						z -= gravity;
						gravity += 0.1;
						if( gravity > 1 ) gravity = 1;
					}
				}
			}
	}
	
	function lowerChunks(zmin:Int, zloss:Int, ?ratio=1.0) {
		var count = ratio * size * size / 300;
		var delta = 10;
		#if genDebug
		{
			var r = rnd.clone();
			var rs = [for( k in 0...6 ) r.random(1000)];
			var hs = [for( k in 0...8 ) height(k * 31, k * 17)];
			Generator.dbg("LC count=" + count + " ceil=" + Math.ceil(count) + " seed=" + rnd.getSeed() + " rnd=" + rs.join(",") + " h=" + hs.join(",") + " zmin=" + zmin + " zloss=" + zloss + " size=" + size);
		}
		var dbgChanged = 0, dbgTry = 0, dbgPass = 0;
		#end
		for( i in 0...Math.ceil(count) ) {
			var ntry = 100;
			while( ntry-->0 ) {
				var x = rnd.random(size);
				var y = rnd.random(size);
				var h = height(x, y);
				#if genDebug dbgTry++; #end
				if( h < zmin ) continue;
				#if genDebug dbgPass++; #end
				if( h >= zmin && ( h - height(x - 1, y) >= delta || h - height(x + 1, y) >= delta || h - height(x, y - 1) >= delta || h - height(x, y + 1) >= delta ) ) {
					var z0 = h - max(rnd.random(zloss), rnd.random(zloss));
					var width = 3 + rnd.random(4);
					var height = 3 + rnd.random(4);
					x += rnd.random(width) - (width >> 1);
					y += rnd.random(height) - (height >> 1);
					var ray = 1 + (rnd.rand() - 0.5) * 0.1;
					var count = 0;
					for( dx in -width...width+1 )
						for( dy in -height...height + 1 )
							if( this.height(real(x + dx), real(y + dy)) < z0 && (dx/width) * (dx/width) + (dy/height)*(dy/height) < ray ) {
								count++;
								setHeight(x + dx, y + dy, z0);
								#if genDebug dbgChanged++; #end
							}
					if( count > 10 )
						break;
				}
			}
		}
		#if genDebug
		Generator.dbg("LC end tries=" + dbgTry + " passMin=" + dbgPass + " changed=" + dbgChanged + " seed=" + rnd.getSeed());
		#end
	}
	
	function addMoonTrees() {
		var h0 = 60 + 32;
		var tree = alloc(BWood);
		var blocks = [Generator.MINERAL_RARE, alloc(BMoonLight), alloc(BMoonLight), alloc(BMoonLight), alloc(BMoonLightDead)];
		for( i in 0...Math.ceil(size * size / 2000) ) {
			var ntry = 1000;
			while( ntry-->0 ) {
				var x = rnd.random(size);
				var y = rnd.random(size);
				var d = 5;
				if( height(x, y) < h0  || height(real(x+d),y) < h0 || height(real(x-d),y) < h0 || height(x,real(y+d)) < h0 || height(x,real(y-d)) < h0 )
					continue;
				function near() {
					var h = height(x, y) + 5;
					for( dx in -20...20 )
						for( dy in -20...20 )
							if( get(x + dx, y + dy, h) == tree )
								return true;
					return false;
				}
				if( near() )
					continue;
				var h = height(x, y);
				for( i in 0...30 ) {
					var ix = x, iy = y, iz = h;
					var x : Float = x, y : Float = y, z : Float = h;
					var vx = (rnd.rand() - 0.5) * 0.2;
					var vy = (rnd.rand() - 0.5) * 0.2;
					var vz = (rnd.rand() - 0.5) * 0.2 + 0.7;
					var zmax = 0.;
					for( s in 0...rnd.random(50) + 70 ) {
						ix = Std.int(x);
						iy = Std.int(y);
						iz = Std.int(z);
						oset(ix,iy,iz, tree);
						x += vx;
						y += vy;
						z += vz;
						if( z > zmax )
							zmax = z;
						if( z > 125 && vz > 0 )
							vz *= 0.8;
						vz -= 0.01;
						if( z < h + 10 && vz < 0 )
							break;
					}
					if( vz < 0 && z < zmax - 5 ) {
						var leaves = alloc(rnd.random(4) == 0 ? BPinkLeaves : BPurpleLeaves);
						elipse(2, 2, 2, function(dx, dy, dz) set(ix + dx, iy + dy, iz + dz, leaves));
						set(ix,iy,iz, blocks[rnd.random(blocks.length)]);
					}
				}
				break;
			}
		}
	}
	
	function addCavePillars(b) {
		var b = alloc(b);
		for( i in 0...Math.ceil(size * size / 1500) ) {
			var ntry = 100;
			while( --ntry > 0 ) {
				var x = rnd.random(size);
				var y = rnd.random(size);
				var z = rnd.random(height(x, y));
				if( get(x, y, z) != CAVE ) continue;
				var z0 = z;
				while( get(x, y, z) == CAVE )
					z++;
				if( get(x, y, z) == EMPTY )
					z = z0;
				else
					z--;
				while( get(x, y, z) == CAVE )
					set(x, y, z--, b);
				break;
			}
		}
	}
	
	function addCaveChampi(b, ratio = 1.0) {
		var b = alloc(b);
		var dead = alloc(BStainEmpty);
		for( i in 0...Math.ceil(ratio * size * size / 10000) ) {
			var ntry = 100;
			while( --ntry > 0 ) {
				var x = rnd.random(size);
				var y = rnd.random(size);
				var z = rnd.random(height(x, y));
				if( get(x, y, z) != CAVE ) continue;
				while( get(x, y, z) == CAVE )
					z--;
				z++;
				elipse(2, 2, 1, function(dx, dy, dz) {
					if( get(x + dx, y + dy, z + dz) == CAVE && get(x + dx, y + dy, z + dz - 1) == ROCK ) {
						set(x + dx, y + dy, z + dz, rnd.random(100)<80 ? b : dead );
					}
				});
				break;
			}
		}
	}
	
	function carveTreeRec(x, y, z, tree, empty) {
		if( get(x, y, z) != tree )
			return;
		if( get(x - 1, y, z)&127 != tree || get(x + 1, y, z)&127 != tree || get(x, y - 1, z)&127 != tree || get(x, y + 1, z)&127 != tree || get(x, y, z - 1)&127 != tree || get(x, y, z + 1)&127 != tree )
			return;
		set(x, y, z, tree | 128 );
		carveTreeRec(x + 1, y, z, tree,empty);
		carveTreeRec(x - 1, y, z, tree,empty);
		carveTreeRec(x, y + 1, z, tree,empty);
		carveTreeRec(x, y - 1, z, tree,empty);
		carveTreeRec(x, y, z - 1, tree,empty);
		set(x, y, z, empty);
	}
	
	function addAcidTrees() {
		var wood = alloc(BAcidWood);
		var woodHole = alloc(BAcidWoodHole);
		var woodBubble = alloc(BAcidWoodBubble);
		var leaves1 = alloc(BAcidLeaves);
		var leaves1Bubble = alloc(BAcidLeavesBubble);
		var leaves2 = alloc(BAcidLeaves2);
		var leaves2Bubble = alloc(BAcidLeaves2Bubble);
		var champi = alloc(BAcidMush);
		var fruit = alloc(BStainGreen);
		
		var trees = new Array<{x:Int,y:Int,z:Int,h:Int}>();
		for( i in 0...Math.ceil(size * size / 200) ) {
			var ntry = 1000;
			while( ntry-->0 ) {
				var x = rnd.random(size);
				var y = rnd.random(size);
				if( height(x, y) < waterLevel )
					continue;
				var z = height(x, y);
				var h = max(rnd.random(100 - z), rnd.random(100 - z));
				if( h < 30 )
					continue;
				var found = false;
				for( t in trees ) {
					var dx = realDist(t.x - x);
					var dy = realDist(t.y - y);
					var d = dx * dx + dy * dy;
					if( d < 15 * 15 ) {
						found = true;
						break;
					}
				}
				if( found )
					continue;
				trees.push( { x:x, y:y, z : z, h:h } );
				break;
			}
		}
		
		// anadido del port: los arboles, la savia y los minerales, repartidos entre varias llamadas a process (ver
		// Generator.jobs) en el mismo orden y con el mismo azar
		spread(trees.length, function(ti) {
			var t = trees[ti];
			var oz = t.z;
			var x = t.x;
			var y = t.y;
			var z = t.z + 20;
			
			var a = rnd.rand() * Math.PI;
			var k = 5;
			var hasChampi = rnd.random(5) == 0;
			for( i in 0...k ) {
				a += Math.PI * 2 / k;
				var len = 5 + rnd.rand() * 5;
				var dx = Math.ceil(Math.cos(a) * len);
				var dy = Math.ceil(Math.sin(a) * len);
				line(x, y, t.z, dx, dy, -5, function(x, y, z) { set(x, y, z, wood); if( hasChampi && rnd.random(2) == 0 ) oset(x, y, z + 1, champi); });
			}
			
			var falloff = 0.15 + (rnd.rand() - 0.5) * 0.1;
			
			while( true ) {
				var rz = z - z % 10;
				var dx = rnd.random(7) - 3;
				var dy = rnd.random(7) - 3;
				if( rz == oz ) {
					dx = 0;
					dy = 0;
				} else {
					line(x, y, oz, dx, dy, rz - oz, function(x, y, z) elipse(1 + rnd.rand() * 1.5, 1 + rnd.rand() * 1.5, 1 + rnd.rand() * 1.5, function(dx, dy, dz) set(x + dx, y + dy, z + dz, wood)));
					x += dx;
					y += dy;
					oz = rz;
				}
				var light = rnd.random(3)==0;
				var w = 10 + rnd.random(6);
				var h = 10 + rnd.random(6);
				for( i in 0...10 ) {
					var cx = x + rnd.random(w) - (w >> 1);
					var cy = y + rnd.random(h) - (h >> 1);
					var cw, ch, ntry = 100;
					do {
						cw = min(rnd.random(w), rnd.random(w));
						ch = min(rnd.random(h), rnd.random(h));
					} while( (cw < 3 || ch < 3) && --ntry > 0 );
					if( cw < 3 ) cw = 3;
					if( ch < 3 ) ch = 3;
					circle(cw,ch, function(dx, dy) {
						var dx = cx + dx - x;
						var dy = cy + dy - y;
						var ray = Math.sqrt(dx * dx + dy * dy);
						var b = light ? ( rnd.random(100)<5 ? leaves2Bubble : leaves2 ) : ( rnd.random(10)==0 ? leaves1Bubble : leaves1 );
						if( oset(x + dx, y + dy, rz - Std.int(ray * falloff), b) && rnd.random(100) == 0 && ray > rnd.rand() * 10 )
							oset(x + dx, y + dy, rz - Std.int(ray * falloff) + 1, fruit);
					});
				}
				
				if( z == t.z + t.h )
					break;
				z += 8 + rnd.random(8);
				if( z > t.z + t.h )
					break;
			}
			if( oz >= 80 && rnd.random(3) == 0 )
				set(x, y, oz + 1, alloc(BAcidFruit));
			for( dx in -1...2 )
				for( dy in -1...2 )
					for( dz in -3...0 )
						carveTreeRec(x+dx, y+dy, oz + dz, wood, CAVE);
		}, function() {
			
			// add parasits leaves
			var parasit = alloc(BBrownLeaves);
			var count = 0;
			for( i in 0...Math.ceil(size * size / 30) ) {
				var ntry = 100;
				while( ntry-->0 ) {
					var x = rnd.random(size);
					var y = rnd.random(size);
					var z = rnd.random(100);
					if( get(x, y, z) != wood )
						continue;
					elipse(2, 2, 1.5, function(dx, dy, dz) oset(x + dx, y + dy, z + dz, parasit));
					count++;
					break;
				}
			}
			
			// replace CAVE by tree content
			var sap = alloc(BAcidTreeSap);
			spread(size, function(y) {
				// anadido del port: de una celda de madera o de CAVE a la siguiente (findCell2), en el mismo orden
				var end = (y + 1) * size * HEIGHT;
				var i = findCell2(y * size * HEIGHT, end, wood, CAVE);
				while( i < end ) {
					if( fget(i) == wood && rnd.random(10)==0 )
						fset(i, rnd.random(100)<30 ? woodBubble : woodHole );
					if( fget(i) == CAVE )
						fset(i, rnd.random(5) == 0 ? sap : EMPTY);
					i = findCell2(i + 1, end, wood, CAVE);
				}
			}, function() {
				
				// add minerals
				var rock = alloc(BHardRock);
				for( i in 0...Math.ceil(size * size / 3000) ) {
					var ntry = 1000;
					while( ntry-->0 ) {
						var x = rnd.random(size);
						var y = rnd.random(size);
						var z = waterLevel;
						if( get(x, y, z) != WATER ) continue;
						var s = 5;
						if( get(x + s, y, z) != WATER || get(x - s, y, z) != WATER || get(x, y - s, z) != WATER || get(x, y + s, z) != WATER )
							continue;
						var h = 1;
						while( get(x, y, z - h) == WATER && h < 5 )
							h++;
						if( h >= 3 ) continue;
						var el = [];
						for( i in 0...4 ) {
							var x = x + rnd.random(5) - 2;
							var y = y + rnd.random(5) - 2;
							var z = z - h - 1;
							var sx = 1.3 + rnd.rand() * 1.5;
							var sy = 1.2 + rnd.rand() * 1.5;
							var sz = 1 + rnd.rand() * 1.3;
							el.push( { x:x, y:y, z:z, sx:sx, sy:sy, sz:sz } );
						}
						var pts = [];
						for( e in el )
							elipse(e.sx, e.sy, e.sz, function(dx, dy, dz) {
								var x = e.x + dx, y = e.y + dy, z = e.z + dz;
								if( get(x, y, z) == EMPTY || get(x, y, z) == WATER ) {
									set(x, y, z, rock);
									pts.push( { x:x, y:y, z:z } );
								}
							});
						fillMinerals(pts);
					}
				}
			});
		});
	}
	
	function addCaveAccesses( zchk ) {
		gen(0.2, 100, function() {
			var x = rnd.random(size);
			var y = rnd.random(size);
			var z = zchk;
			if( get(x, y, z) != CAVE )
				return false;
			while( get(x, y, z) == CAVE )
				z++;
			var zstart = z;
			while( true ) {
				var b = get(x, y, z);
				if( b == WATER )
					return false;
				if( b == EMPTY )
					break;
				z++;
			}
			if( z - zstart > 10 )
				return false;
			eraseCaveRec(x, y, z - 1, 20);
			for( z in zstart...z ) {
				if( rnd.random(5) == 0 )
					elipse(1.5, 1.5, 1.5, function(dx, dy, dz) set(x + dx, y + dy, z + dz, EMPTY));
				else
					set(x, y, z, EMPTY);
			}
			return true;
		});
	}
	
	function eraseCaveRec( x, y, z, rec ) {
		if( get(x, y, z) != CAVE )
			return;
		set(x, y, z, EMPTY);
		rec--;
		if( rec == 0 ) return;
		eraseCaveRec(x - 1, y, z, rec);
		eraseCaveRec(x + 1, y, z, rec);
		eraseCaveRec(x, y - 1, z, rec);
		eraseCaveRec(x, y + 1, z, rec);
		eraseCaveRec(x, y, z - 1, rec);
		eraseCaveRec(x, y, z + 1, rec);
	}
	
	function addWinterDetails() {
		var ice = alloc(BIce);
		for( x in 0...size )
			for( y in 0...size ) {
				var z = waterLevel;
				var p = addr(x,y,z);
				if( fget(p) == WATER && fget(p - 1) != WATER ) {
					if( (get(x,y+1,z-1) != WATER && get(x,y-1,z-1) != WATER && get(x+1,y,z-1) != WATER && get(x-1,y,z-1) != WATER) || rnd.random(5) == 0 )
						fset(p, ice);
				}
			}
		
		// small pitonics
		gen(0.2, 100, function() {
			var x = rnd.random(size);
			var y = rnd.random(size);
			var z = height(x, y);
			if( z > 40 )
				return false;
			for( dx in -1...2 )
				for( dy in -1...2 )
					if( get(x + dx, y + dy, z) != EMPTY || get(x + dx, y + dy, z - 1) != SOIL )
						return false;
			var h = 2 + rnd.random(8);
			var isIce = rnd.random(5) == 0;
			for( i in 0...h )
				set(x, y, z + i, isIce ? ice : rnd.random(2) == 0 ? ROCK : SOIL);
			for( d in [[ -1, 0], [1, 0], [0, 1], [0, -1]] ) {
				var dx = d[0], dy = d[1];
				for( i in 0...Math.ceil(h/4) + rnd.random(h >> 1) )
					oset(x + dx, y + dy, z + i, isIce ? ice : rnd.random(2) == 0 ? ROCK : SOIL);
			}
			return true;
		});
		
		// cascades
		var source = alloc(BCascadeSource);
		var fall = alloc(BCascadeFall);
		gen(0.2, 1000, function() {
			var x = rnd.random(size);
			var y = rnd.random(size);
			var z = height(x, y);
			if( z < 80 || get(x,y,z) == EMPTY )
				return false;
			z = 70 + rnd.random((z - 80) >> 1);
			var dx = rnd.random(2) == 0 ? -1 : 1;
			var dy = rnd.random(2) == 0 ? -1 : 1;
			if( rnd.random(2) == 0 ) dx = 0 else dy = 0;
			// version 1: como mucho una vuelta al planeta (antes sin fin si la fila no tenia hueco)
			var steps = 0;
			while( true ) {
				var b = get(x, y, z);
				if( b == EMPTY ) break;
				if( b == source || b == fall || ++steps > size ) return false;
				x += dx;
				y += dy;
			}
			var len = 3 + rnd.random(3);
			for( i in 0...len+1 )
				if( get(x + dx * i, y + dy * i, z) != EMPTY )
					return false;
			var nfall = 0;
			while( get(x + dx * len, y + dy * len, z - nfall) == EMPTY )
				nfall++;
			if( nfall < 10 )
				return false;
			for( i in 0...len ) {
				set(x, y, z, SOIL);
				x += dx;
				y += dy;
			}
			set(x, y, z, source);
			z--;
			while( get(x, y, z) == EMPTY ) {
				set(x, y, z, fall);
				z--;
			}
			return true;
		});
		
		// hidden flowers
		var hidden = alloc(BWinterHidden);
		gen(0.3, 100, function() {
			var x = rnd.random(size);
			var y = rnd.random(size);
			var z = height(x, y);
			if( z <= waterLevel || z > 40 || get(x,y,z) != EMPTY || get(x,y,z-1) != SOIL ) return false;
			set(x, y, z, hidden);
			return true;
		});
		
		// teintures
		var stain = alloc(BStainWhite);
		var empty = alloc(BStainEmpty);
		gen(0.45,1000,function() {
			var x = rnd.random(size);
			var y = rnd.random(size);
			var z = height(x,y);
			if( z>=60 && get(x, y, z)==EMPTY && (get(x,y,z-1)==ROCK || get(x,y,z-1)==SOIL) ) {
				set(x, y, z, rnd.random(100)<75 ? stain : empty);
				return true;
			}
			return false;
		});
		
		// sapins
		var tree = alloc(BWinterWood);
		var leaves = alloc(BWinterLeaves);
		var stalag1 = alloc(BIceStalactite1);
		var stalag2 = alloc(BIceStalactite2);
		gen(0.1, 100, function() {
			var x = rnd.random(size);
			var y = rnd.random(size);
			var z = height(x, y);
			if( get(x, y, z) != EMPTY || get(x, y, z - 1) != SOIL )
				return false;
			var trees = new Array();
			for( i in 0...10 ) {
				var ntry = 20;
				var px, py, pz, h;
				do {
					px = x + rnd.random(17) - 8;
					py = y + rnd.random(17) - 8;
					pz = height(px, py);
					h = 8 + rnd.random(8);
				} while( --ntry > 0 && (get(px, py, pz) != EMPTY || get(px, py, pz - 1) != SOIL || !free(px-4,py-4,pz+1,8,8,h) || pz > 40) );
				if( ntry <= 0 ) break;
				set(px, py, pz, tree);
				trees.push( { x:px, y:py, z:pz, h:h } );
			}
			
			var all = [];
			function addLeaves(x,y,z) {
				oset(x, y, z, leaves);
				all.push( {x:x, y:y, z:z} );
			}
			for( t in trees ) {
				var x = t.x, y = t.y, z = t.z, h = t.h;
				for( i in 0...h )
					set(x, y, z + i, tree);
				set(x, y, z + h, leaves);
				var size = 1;
				var dz = h - 1;
				while( dz > h >> 2 ) {
					for( i in -size...size+1 ) {
						addLeaves(x - size, y + i, z + dz);
						addLeaves(x + size, y + i, z + dz);
						addLeaves(x + i, y - size, z + dz);
						addLeaves(x + i, y + size, z + dz);
					}
					if( size < 4 && rnd.random(3+size*size) == 0 )
						size++;
					dz--;
				}
			}
			var n = 15;
			while( n>0 && all.length>0 ) {
				var c = all.splice(rnd.random(all.length), 1)[0];
				if( get(c.x, c.y, c.z-1)==EMPTY) {
					oset(c.x, c.y, c.z-1, rnd.random(2)==0 ? stalag1 : stalag2 );
					n--;
				}
			}
			return true;
		});
	}
	
	function adjustMarsHeight() {
		gen(0.05, 100, function() {
			var x = rnd.random(size);
			var y = rnd.random(size);
			var z = height(x, y);
			if( z < 80 ) return false;
			var h = 3 + rnd.rand() * 10;
			circle(5 + rnd.rand() * 5, 5 + rnd.rand() * 5, function(dx, dy) {
				var x = x + dx, y = y + dy;
				var r = 30 / (dx * dx + dy * dy + 30);
				setHeight(x, y, height(x, y) + Math.ceil(r * h));
			});
			return true;
		});
	}
	
	function addMarsDetails() {
		// soil2
		var soil2 = alloc(BMarsSoil2);
		initPerlin(3);
		for( x in 0...size )
			for( y in 0...size ) {
				var p = ((perlin2D(x, y) + 1) * 4) % 1;
				if( p < 0.3 ) {
					var z = height(x, y) - 1;
					if( get(x, y, z) == SOIL )
						set(x, y, z, soil2);
				}
			}
					
		
		// rocks
		var rock = alloc(BMarsHardRock);
		gen(1, 100, function() {
			var x = rnd.random(size);
			var y = rnd.random(size);
			var z = height(x, y);
			if( z < 80 ) return false;
			set(x, y, z, rock);
			return true;
		});
		
		// craters
		var crock = alloc(BMarsCraterRock);
		var bluerock = alloc(BMarsBlueRock);
		gen(0.1, 100, function() {
			var x = rnd.random(size);
			var y = rnd.random(size);
			var z = height(x, y);
			if( z < 50 ) return false;
			var size = 4 + rnd.rand() * 8;
			elipse(size, size, size * 0.5, function(dx, dy, dz) {
				var x = x + dx, y = y + dy, z = z + dz;
				if( get(x, y, z - 1) == ROCK && (dx*dx+dy*dy) / (size*size) < 0.33 )
					set(x, y, z - 1, rnd.random(10) == 0 && !around(x,y,z-1,bluerock) ? bluerock : crock);
				while( get(x,y,z) != EMPTY )
					set(x, y, z++, EMPTY);
			});
			return true;
		});
		
		// cactus
		var cactus = alloc(BMarsCactus);
		var bones = alloc(BMarsCactusFossil);
		var flower = alloc(BMarsCactusFlower);
		gen(0.03, 100, function() {
			var x = rnd.random(size);
			var y = rnd.random(size);
			var z = height(x, y);
			if( z < 83 ) return false;
			
			for( i in 0...10 ) {
				var x = x + rnd.random(21) - 10;
				var y = y + rnd.random(21) - 10;
				var z = height(x, y);
				if( z < 83 || get(x, y, z - 1) != SOIL )
					continue;
				var h = 3 + rnd.random(3);
				for( i in 0...h )
					oset(x, y, z++, rnd.random(100)<10 ? bones : cactus);
				for( i in 0...2 ) {
					var z = z -1, x = x, y = y;
					var dx = 0, dy = 0;
					switch( rnd.random(4) ) {
					case 0: dx++;
					case 1: dy++;
					case 2: dx--;
					case 3: dy--;
					}
					function rndCactus() {
						return rnd.random(5) == 0 ? flower : rnd.random(100)<10 ? bones : cactus;
					}
					for( i in 0...min(rnd.random(3), rnd.random(3)) ) {
						x += dx;
						y += dy;
						oset(x, y, z, rndCactus());
					}
					for( i in 0...max(rnd.random(h)+1,rnd.random(h)+1) ) {
						oset(x + dx, y + dy, z, rndCactus());
						z++;
					}
				}
			}
			return true;
		});
		
		// hidden caves
		var qsand = alloc(BMarsQuickSand);
		for( x in 0...size )
			for( y in 0...size ) {
				if( realHeight(x + y * size) > 1.02 ) {
					for( z in 0...2 )
						oset(x, y, 75 + z, qsand);
				}
			}
		
		// fossils
		var fossil = alloc(BMarsRockFossil);
		gen(0.1,1000,function() {
			var x = rnd.random(size);
			var y = rnd.random(size);
			var z = 32 + rnd.random(height(x, y) - 32);
			if( get(x, y, z) == ROCK && around(x, y, z, EMPTY) ) {
				set(x, y, z, fossil);
				return true;
			}
			return false;
		});
		
		// teintures
		var stain = alloc(BStainOrange);
		var empty = alloc(BStainEmpty);
		var n = 30;
		var tries = n*50;
		while(n>0 && tries-->0) {
			var x = rnd.random(size);
			var y = rnd.random(size);
			var z = rnd.random(24)+12;
			if( get(x,y,z)==EMPTY ) {
				while( !isSolidAt(x,y,z-1) )
					z--;
				elipse(4,4,5, function(dx,dy,dz) {
					var x=x+dx, y=y+dy, z=z+dz;
					if( rnd.random(100)<30 && get(x,y,z)==EMPTY && isSolidAt(x,y,z-1) )
						set(x,y,z, rnd.random(100)<60 ? stain : empty);
				});
				n--;
			}
		}
	}
	
	function createHeightsLevels( hmin, hmod ) {
		for( y in 0...size )
			for( x in 0...size ) {
				var h = height(x, y) - hmin;
				if( h < 0 )
					continue;
				setHeight(x, y, hmin + (h - (h % hmod)));
			}
	}
	
	
	function addDeadDetails() {
		var tree = alloc(BDeadTree);
		var leaves = alloc(BDarkLeaves);
		var deadWindows = [];
		
		var swamp = alloc(BDeadSwamp);
		for( x in 0...size )
			for( y in 0...size ) {
				var z = height(x, y);
				if( z <= waterLevel + 2 && get(x, y, z-1) == SOIL )
					set(x, y, z-1, swamp);
			}
				
		
		function genDeadHouse(x, y, z) {
			var w = 4 + rnd.random(5);
			var h = 4 + rnd.random(5);
			function check() {
				for( dx in 0...w +1 )
					for( dy in 0...h + 1 ) {
						if( get(x+dx, y+dy, z) != EMPTY || !isSolid(get(x+dx, y+dy, z - 1)) || get(x+dx,y+dy,z-1) == swamp )
							return false;
					}
				return true;
			}
			if( !check() )
				return false;

				
			// walls
			var mat = rnd.random(5) == 0 ? ROCK : tree;
			var imat = mat == ROCK ? tree : ROCK;
			
			var stairs = 1 + min(rnd.random(4), rnd.random(4));
			var height = 5 * stairs;

			for( dz in 0...height ) {
				for( dx in 0...w + 1 ) {
					set(x + dx, y, z + dz, mat);
					set(x + dx, y + h, z + dz, mat);
				}
				for( dy in 0...h + 1 ) {
					set(x, y + dy, z + dz, mat);
					set(x + w, y + dy, z + dz, mat);
				}
			}

			for( i in 0...stairs+1 ) {
				var z = z + i * 5;
				if( i == stairs ) z--;
				set(x, y, z, imat);
				set(x + w, y, z, imat);
				set(x + w, y + h, z, imat);
				set(x, y + h, z, imat);
			}
			
			// stairs
			for( s in 0...stairs ) {
				var z = z + s * 5;
				
				if( s > 0 ) {
					for( dx in 1...w )
						for( dy in 1...h )
							oset(x + dx, y + dy, z - 1, leaves);
				}
				
				// entrance - window
				{
					var dx = 0, dy = 0;
					switch( rnd.random(4) ) {
					case 0: dx++;
					case 1: dx--;
					case 2: dy++;
					case 3: dy--;
					}
					var x = x, y = y;
					x += 2 + rnd.random(w - 4);
					y += 2 + rnd.random(h - 4);
					var steps = 0;
					while( get(x, y, z) == EMPTY && steps++ < size ) {
						x += dx;
						y += dy;
					}
					if( s > 0 )
						deadWindows.push( { x:x, y:y, z:z, dx:dx,dy:dy } );
					var count = 2;
					while( get(x, y, z) != EMPTY && count-- > 0 ) {
						for( dz in 0...3 )
							set(x, y, z+dz, EMPTY);
						x += dx;
						y += dy;
					}
				}
				
			}
			
			
			
			// roof
			while( w >= 1 && h >= 1 ) {
				w -= 2;
				h -= 2;
				x++;
				y++;
				for( dx in 0...w +1 )
					for( dy in 0...h + 1 )
						set(x + dx, y + dy, z + height, leaves);
				height++;
			}
			
			return true;
		}
		
		// villages
		gen(0.01, 100, function() {
			var x = rnd.random(size);
			var y = rnd.random(size);
			var z = height(x, y);
			if( z > waterLevel || get(x, y, z) != WATER )
				return false;
			for( i in 0...15 ) {
				var ntry = 100;
				while( ntry-- > 0 ) {
					var x = real( x + rnd.random(50) - 25 );
					var y = real( y + rnd.random(50) - 25 );
					var z = height(x, y);
					if( genDeadHouse(x, y, z) )
						break;
				}
			}
			return true;
		});
		
		// add passerels
		
		for( d in deadWindows ) {
			var x = d.x;
			var y = d.y;
			var z = d.z;
			var dx = d.dx;
			var dy = d.dy;
			var dist = 0;
			while( get(x, y, z) == EMPTY && dist++ < 8 ) {
				x += dx;
				y += dy;
			}
			if( get(x, y, z) == tree && get(x - dy, y - dx, z) == tree && get(x + dy, y + dx, z) == tree ) {
				x = d.x + dx;
				y = d.y + dy;
				z--;
				for( i in 1...dist ) {
					oset(x, y, z, tree);
					oset(x + dy, y + dx, z, tree);
					oset(x - dy, y - dx, z, tree);
					x += dx;
					y += dy;
				}
				z++;
				for( dz in 0...3 )
					set(x, y, z + dz, EMPTY);
			}
		}
		
		// trees
		gen(0.03, 100, function() {
			var x = rnd.random(size);
			var y = rnd.random(size);
			for( i in 0...30 ) {
				var x = real( x + rnd.random(30) - 15 );
				var y = real( y + rnd.random(30) - 15 );
				var z = height(x, y);
				if( get(x, y, z) != EMPTY || get(x, y, z - 1) != SOIL )
					continue;
				for( dz in 4...9 )
					if( get(x, y, z + dz) != EMPTY ) {
						z = -1;
						break;
					}
				if( z < 0 ) continue;
					
				var h = 6 + rnd.random(8);
				var sz = z;
				line(x, y, z, rnd.random(5) - 2, rnd.random(5) - 2, h >> 1, function(x, y, z) {
					oset(x, y, z, tree);
					if( z == sz + (h >> 1) )
						for( i in 0...4 )
							line(x, y, z, rnd.random(11) - 5, rnd.random(11) - 5, h >> 1, function(x,y,z) oset(x,y,z,leaves));
				});
			}
			return true;
		});
	}

	// ---------------------------------------------------------------- Grey Haven (anadido del port)

	/** primera altura de las mesetas (lo de debajo y por encima del agua son las tierras bajas) */
	var ghFoot : Int;
	/** bosque de cada columna: 0 = llano o meseta, 1..255 = cada vez mas espeso */
	var ghForest : haxe.io.Bytes;
	/** troncos y tallos de cactus puestos, para dejar sitio entre ellos */
	var ghTaken : haxe.io.Bytes;

	static function ghSorted( v : Array<Float> ) {
		v.sort(function(a, b) return a < b ? -1 : (a > b ? 1 : 0));
		return v;
	}

	/**
	 * Alturas por cuantiles del ruido, asi cada planeta tiene las mismas proporciones: el 15 % mas bajo bajo el agua, las tierras
	 * bajas onduladas y una cuesta suave hasta el pie de las mesetas; el 15 % mas alto se queda en ese pie y ghCuesta lo levanta
	 */
	function ghHeights() {
		var n = size * size;
		var v = ghSorted([for( p in 0...n ) realHeight(p)]);
		inline function q( f : Float ) return v[Std.int(f * (n - 1))];
		var lo = v[0] - 0.001, hi = v[n - 1] + 0.001;
		var levels = [
			{ v : lo, h : -14 }, { v : q(0.07), h : -5 }, { v : q(0.15), h : 1 }, { v : q(0.55), h : 4 }, { v : q(0.80), h : 8 },
			{ v : q(0.845), h : 12 }, { v : hi, h : 12 },
		];
		// cuantiles iguales (planeta muy liso): cada nivel un poco por encima del anterior
		for( i in 1...levels.length )
			if( levels[i].v <= levels[i - 1].v ) levels[i].v = levels[i - 1].v + 1e-6;
		fillHeight(levels);
		ghFoot = waterLevel + 12;
	}

	/** la roca que fillSoil deja arriba (sobre todo en las mesetas) se tapa con 1 a 3 de tierra; las paredes y el borde de las mesetas se quedan en roca */
	function ghTopsoil() {
		for( y in 0...size )
			for( x in 0...size ) {
				var p = x + y * size;
				var h = hval(p);
				if( h <= waterLevel ) continue;
				var a = (p << HBITS) + h - 1;
				var low = height(x - 1, y);
				for( d in [height(x + 1, y), height(x, y - 1), height(x, y + 1)] ) if( d < low ) low = d;
				if( h - low >= 4 ) {
					for( i in 0...8 )
						if( fget(a - i) == SOIL ) fset(a - i, ROCK);
					continue;
				}
				if( fget(a) != ROCK ) continue;
				for( i in 0...1 + rnd.random(3) )
					if( fget(a - i) == ROCK ) fset(a - i, SOIL);
			}
	}

	/**
	 * Las mesetas en cuesta: por un lado suben suave (0,7 por bloque) hasta su meseta, a unos 24 por encima de su pie, y por el otro
	 * caen de golpe. El lado suave mira hacia una direccion que cambia despacio por el planeta (cada meseta la suya); la subida se
	 * mide hacia atras en tres direcciones (de frente y a 50 grados a cada lado) y se toma la mas corta, asi los lados bajan tambien
	 */
	function ghCuesta() {
		var n = size * size;
		var foot = ghFoot;
		var mount = haxe.io.Bytes.alloc(n);
		for( p in 0...n ) if( hval(p) >= foot ) mount.set(p, 1);
		var ang = new Array<Float>();
		initPerlin(0.4);
		for( p in 0...n ) ang.push(mount.get(p) == 0 ? 0. : (perlin2D(p % size, Std.int(p / size)) + 1) * Math.PI * 1.5);
		var bump = new Array<Float>();
		initPerlin(3);
		for( p in 0...n ) bump.push(mount.get(p) == 0 ? 0. : (perlin2D(p % size, Std.int(p / size)) + 1) * 1.5);
		var maxRun = 48;
		for( y in 0...size )
			for( x in 0...size ) {
				var p = x + y * size;
				if( mount.get(p) == 0 ) continue;
				var run = maxRun;
				for( da in [0., 0.87, -0.87] ) {
					var a = ang[p] + da, dx = -Math.cos(a), dy = -Math.sin(a);
					var k = 1;
					while( k < run ) {
						var q = real(x + Math.round(dx * k)) + real(y + Math.round(dy * k)) * size;
						if( mount.get(q) == 0 ) break;
						k++;
					}
					if( k - 1 < run ) run = k - 1;
				}
				var rise = Math.min(24 + bump[p], run * 0.7);
				setHeight(x, y, foot + Std.int(rise));
			}
	}

	/** el fondo del agua: 2 bloques de arena y 3 de tierra por encima de la roca (fillSoil dejaba roca al aire bajo el agua) */
	function ghLakeBed() {
		var sand = alloc(BKubeGreyHavenSand);
		for( p in 0...size * size ) {
			var h = hval(p);
			if( h > waterLevel ) continue;
			var a = (p << HBITS) + h - 1;
			for( i in 0...5 )
				if( h - 1 - i > 0 && fget(a - i) != EMPTY && fget(a - i) != WATER ) fset(a - i, i < 2 ? sand : SOIL);
		}
	}

	/** smoothHeight solo lejos de las mesetas: su corte se queda brusco */
	function ghSmooth() {
		var n = size * size;
		var src = haxe.io.Bytes.alloc(n);
		for( p in 0...n ) src.set(p, hval(p));
		for( y in 0...size )
			for( x in 0...size ) {
				inline function at( dx : Int, dy : Int ) return src.get(real(x + dx) + real(y + dy) * size);
				var h = at(0, 0), a = at(-1, 0), b = at(1, 0), c = at(0, -1), d = at(0, 1);
				if( h >= ghFoot || a >= ghFoot || b >= ghFoot || c >= ghFoot || d >= ghFoot ) continue;
				perlin.setByte(outHeight + x + y * size, ((h << 2) + (a + b + c + d) * 3 + 7) >> 4);
			}
	}

	inline function ghLowland( h : Int ) return h > waterLevel && h < ghFoot;

	/** bosque y llano: un ruido grande con algo de detalle; el llano es 2/7 de las tierras bajas (20 % del planeta frente a 50 %) */
	function ghForestMask() {
		var n = size * size;
		initPerlin(1.5);
		var f = [for( p in 0...n ) perlin2D(p % size, Std.int(p / size))];
		initPerlin(5);
		for( p in 0...n ) f[p] += 0.35 * perlin2D(p % size, Std.int(p / size));
		var low = ghSorted([for( p in 0...n ) if( ghLowland(hval(p)) ) f[p]]);
		ghForest = haxe.io.Bytes.alloc(n);
		if( low.length == 0 ) return;
		var t = low[Std.int(low.length * 2 / 7)];
		var dense = low[Std.int((low.length - 1) * 0.97)];
		var spread = dense > t ? dense - t : 1.;
		for( p in 0...n ) {
			if( !ghLowland(hval(p)) || f[p] <= t ) continue;
			var k = 1 + Std.int((f[p] - t) / spread * 254);
			ghForest.set(p, k > 255 ? 255 : k);
		}
	}

	/** columnas de las anomalias de la superficie (stageDecor): la vegetacion no se pone en ellas */
	var ghBlocked : haxe.io.Bytes;

	/**
	 * La vegetacion, despues de las anomalias (DetailsGenerator.stageDecor) y fuera de sus cajas: arboles, cactus, corales y
	 * plantas, cada uno con su azar
	 */
	function ghDecor( blocked : haxe.io.Bytes ) {
		ghBlocked = blocked;
		// coverAll ya ha cubierto la tierra al aire: el suelo de arriba es el suelo de Grey Haven
		ghCovered = alloc(BKubeGreyHavenSoil);
		rnd = stream(biomeName + "/decor/trees");
		ghTrees();
		rnd = stream(biomeName + "/decor/cacti");
		ghCacti();
		rnd = stream(biomeName + "/decor/corals");
		ghCorals();
		rnd = stream(biomeName + "/decor/plants");
		ghPlants();
		ghBlocked = null;
	}

	/** la tierra cubierta (suelo de Grey Haven) en stageDecor, que va despues de coverAll; -1 antes */
	var ghCovered = -1;

	/** una columna de suelo libre: tierra (o suelo) arriba, aire encima y fuera de las anomalias */
	inline function ghGround( p : Int, h : Int ) {
		var g = fget((p << HBITS) + h - 1);
		return h > waterLevel && (g == SOIL || g == ghCovered) && fget((p << HBITS) + h) == EMPTY && (ghBlocked == null || ghBlocked.get(p) == 0);
	}

	/** algo puesto en ghTaken a menos de d columnas */
	function ghNear( x : Int, y : Int, d : Int ) {
		for( dy in -d...d + 1 )
			for( dx in -d...d + 1 )
				if( ghTaken.get(real(x + dx) + real(y + dy) * size) != 0 )
					return true;
		return false;
	}

	/** suelo casi llano alrededor (los arboles no se ponen al borde de una meseta) */
	function ghFlat( x : Int, y : Int, h : Int ) {
		for( d in [[1, 0], [-1, 0], [0, 1], [0, -1]] ) {
			var dh = height(x + d[0], y + d[1]) - h;
			if( dh > 2 || dh < -2 ) return false;
		}
		return true;
	}

	/** arboles cerca unos de otros en el bosque (mas en lo espeso, con huecos en el borde); en el llano y las mesetas, alguno suelto */
	function ghTrees() {
		var trunk = alloc(BKubeGreyHavenTreeTrunk), leaves = alloc(BKubeGreyHavenLeaves), easy = alloc(BKubeGreyHavenLeavesEasy);
		ghTaken = haxe.io.Bytes.alloc(size * size);
		for( y in 0...size )
			for( x in 0...size ) {
				var p = x + y * size;
				var h = hval(p);
				if( !ghGround(p, h) ) continue;
				var f = ghForest.get(p);
				var chance = f == 0 ? 0.0015 : 0.02 + 0.05 * f / 255;
				if( rnd.rand() >= chance ) continue;
				if( ghNear(x, y, f == 0 ? 6 : (f > 150 ? 3 : 4)) || !ghFlat(x, y, h) ) continue;
				ghTaken.set(p, 1);
				if( rnd.random(4) == 0 )
					ghRoundTree(x, y, h, trunk, leaves);
				else
					ghCrossTree(x, y, h, trunk, easy);
			}
	}

	/**
	 * El arbol recto de Grey Haven, de hojas simples y sin huecos: alrededor del tronco, capas de 3 x 3 llenas que alternan con
	 * capas en cruz (con brazos de 2 en la mitad de abajo); arriba una cruz y la punta
	 */
	function ghCrossTree( x : Int, y : Int, h : Int, trunk : Int, easy : Int ) {
		var height = 10 + rnd.random(4);
		var top = h + height;
		for( z in h...top ) set(x, y, z, trunk);
		inline function leaf( dx : Int, dy : Int, z : Int ) oset(x + dx, y + dy, z, easy);
		var start = h + 3 + rnd.random(2);
		for( z in start...top ) {
			var wide = z < start + ((top - start) >> 1);
			if( (top - 1 - z) & 1 == 0 ) {
				for( dx in -1...2 )
					for( dy in -1...2 )
						if( dx != 0 || dy != 0 ) leaf(dx, dy, z);
			} else
				for( d in [[1, 0], [-1, 0], [0, 1], [0, -1]] ) {
					leaf(d[0], d[1], z);
					if( wide ) leaf(d[0] * 2, d[1] * 2, z);
				}
		}
		for( d in [[1, 0], [-1, 0], [0, 1], [0, -1]] ) leaf(d[0], d[1], top);
		leaf(0, 0, top);
		leaf(0, 0, top + 1);
	}

	/** el arbol redondo: tronco algo mas bajo y una copa en bola llena de hojas que caen (las de Grey Haven) */
	function ghRoundTree( x : Int, y : Int, h : Int, trunk : Int, leaves : Int ) {
		var height = 8 + rnd.random(3);
		var top = h + height;
		for( z in h...top ) set(x, y, z, trunk);
		var r = 2.4 + rnd.rand() * 0.8, rz = 2.0 + rnd.rand() * 0.5;
		var cz = top - 1;
		elipse(r, r, rz, function(dx, dy, dz) {
			if( dx == 0 && dy == 0 && dz < 1 ) return;
			oset(x + dx, y + dy, cz + dz, leaves);
		});
	}

	/** columnas de cactus de 3 a 5 de alto (tallos y un fruto que alumbra arriba): muchas en el bosque, pocas fuera */
	function ghCacti() {
		var stem = alloc(BKubeGreyHavenCactiStem), fruit = alloc(BKubeGreyHavenCactiFruit);
		for( y in 0...size )
			for( x in 0...size ) {
				var p = x + y * size;
				var h = hval(p);
				if( !ghGround(p, h) ) continue;
				var f = ghForest.get(p);
				if( rnd.rand() >= (f == 0 ? 0.0008 : 0.008) ) continue;
				if( ghNear(x, y, 2) ) continue;
				var n = 2 + rnd.random(3);
				var ok = true;
				for( z in h...h + n + 1 )
					if( get(x, y, z) != EMPTY ) ok = false;
				if( !ok ) continue;
				ghTaken.set(p, 2);
				for( z in h...h + n ) set(x, y, z, stem);
				set(x, y, h + n, fruit);
			}
	}

	/** corales en los sitios abiertos (llano y mesetas): grupos de 1 a 4 bloques, alguno de dos de alto; casi ninguno en el bosque */
	function ghCorals() {
		var coral = alloc(BKubeGreyHavenLandCoral);
		for( y in 0...size )
			for( x in 0...size ) {
				var p = x + y * size;
				var h = hval(p);
				if( !ghGround(p, h) ) continue;
				if( rnd.rand() >= (ghForest.get(p) == 0 ? 0.0025 : 0.0001) ) continue;
				for( i in 0...1 + rnd.random(3) ) {
					var cx = real(x + rnd.random(3) - 1), cy = real(y + rnd.random(3) - 1);
					var cp = cx + cy * size, ch = hval(cp);
					if( ch != h || !ghGround(cp, ch) ) continue;
					set(cx, cy, ch, coral);
					if( rnd.random(6) == 0 ) oset(cx, cy, ch + 1, coral);
				}
			}
	}

	/**
	 * Las plantas repartidas un poco por todas partes, mas en unos sitios que en otros (un ruido): las pequenas sobre todo en el
	 * llano y las altas sobre todo en el bosque; de cada una, la variante con flor de vez en cuando
	 */
	function ghPlants() {
		var plant = alloc(BKubeGreyHavenBasicPlant), plantF = alloc(BKubeGreyHavenBasicPlantFlowering);
		var tall = alloc(BKubeGreyHavenTallPlant), tallF = alloc(BKubeGreyHavenTallPlantFlowering);
		initPerlin(6);
		for( y in 0...size )
			for( x in 0...size ) {
				var p = x + y * size;
				var h = hval(p);
				if( !ghGround(p, h) ) continue;
				var patch = perlin2D(x, y);
				var forest = ghForest.get(p) != 0;
				var pTall = forest ? 0.045 + 0.03 * patch : 0.01 + 0.008 * patch;
				var pShort = forest ? 0.06 + 0.04 * patch : 0.12 + 0.06 * patch;
				var r = rnd.rand();
				if( r < pTall )
					set(x, y, h, rnd.random(100) < 35 ? tallF : tall);
				else if( r < pTall + pShort )
					set(x, y, h, rnd.random(100) < 30 ? plantF : plant);
			}
	}

	/**
	 * SOIL es la tierra de Grey Haven: al aire se cubre de hierba (BFCover: el suelo de Grey Haven) en coverAll, como la tierra roja.
	 * Aqui solo el suelo con flores, bloque a bloque (de 2 a 8 % segun un ruido, sin manchas), en la tierra de la superficie (lo
	 * primero desde arriba sin contar las plantas, los arboles, los cactus y los corales)
	 */
	function ghSoilCover() {
		var flowers = alloc(BKubeGreyHavenFloweringSoil);
		var skip = [for( id in 0...blocks.length ) id == EMPTY || (btrans[id] && id != WATER)];
		for( k in [BKubeGreyHavenLeaves, BKubeGreyHavenLeavesEasy, BKubeGreyHavenTreeTrunk, BKubeGreyHavenLandCoral, BKubeGreyHavenCactiStem, BKubeGreyHavenCactiFruit] ) {
			var id = alloc(k);
			while( skip.length <= id ) skip.push(false);
			skip[id] = true;
		}
		initPerlin(5);
		for( y in 0...size )
			for( x in 0...size ) {
				var base = (x + y * size) << HBITS;
				var z = HEIGHT - 1;
				while( z > 0 && skip[fget(base + z)] ) z--;
				if( fget(base + z) == SOIL && rnd.rand() < 0.05 + 0.03 * perlin2D(x, y) ) fset(base + z, flowers);
			}
	}

	/**
	 * Las grutas de addCaves se quedan a 5 bloques del aire como poco: por arriba (llegaban a la superficie de las tierras bajas) y
	 * de lado (si no, abrian ranuras en las paredes de las mesetas). Lo que salia por encima de la superficie se queda en aire
	 */
	function ghCaveRoof() {
		var n = size * size;
		var low = haxe.io.Bytes.alloc(n);
		for( y in 0...size )
			for( x in 0...size ) {
				var m = 255;
				for( dy in -2...3 )
					for( dx in -2...3 ) {
						var v = height(x + dx, y + dy);
						if( v < m ) m = v;
					}
				low.set(x + y * size, m);
			}
		for( p in 0...n ) {
			var h = hval(p);
			var a = p << HBITS;
			var limit = low.get(p) - 5;
			if( limit < 1 ) limit = 1;
			for( z in limit...h )
				if( fget(a + z) == CAVE ) fset(a + z, z >= h - 4 ? SOIL : ROCK);
			for( z in h...HEIGHT )
				if( fget(a + z) == CAVE ) fset(a + z, EMPTY);
		}
	}

	/**
	 * Entradas a las grutas, una cada 6400 columnas (24 en un planeta grande): desde el suelo llano de las tierras bajas, una rampa ancha (5 de ancho)
	 * que baja hasta una gruta que pase de 6 a 14 bloques por debajo, con alguna phosphomousse en sus paredes
	 */
	function ghCaveEntrances() {
		for( i in 0...Math.ceil(size * size / 6400) ) {
			var ntry = 600;
			while( ntry-- > 0 ) {
				var x = rnd.random(size), y = rnd.random(size);
				var h = height(x, y);
				if( !ghLowland(h) || !ghFlat(x, y, h) ) continue;
				var cz = -1;
				var z = h - 6;
				while( z > h - 15 && z > 1 ) {
					if( get(x, y, z) == CAVE ) {
						cz = z;
						break;
					}
					z--;
				}
				if( cz < 0 ) continue;
				var a = rnd.rand() * Math.PI * 2, dx = Math.cos(a), dy = Math.sin(a);
				var len = h - cz + 3;
				// la boca (donde la rampa sale al aire): tierra baja y llana, sin agua a menos de 10 columnas
				var ox = Math.round(x + dx * (h - cz) * 1.6), oy = Math.round(y + dy * (h - cz) * 1.6), oh = height(ox, oy);
				if( oh < waterLevel + 3 || !ghLowland(oh) || !ghFlat(ox, oy, oh) ) continue;
				var wet = false;
				for( wy in -10...11 )
					for( wx in -10...11 )
						if( get(ox + wx, oy + wy, waterLevel) == WATER ) wet = true;
				if( wet ) continue;
				for( k in 0...len ) {
					var px = Math.round(x + dx * k * 1.6), py = Math.round(y + dy * k * 1.6), pz = cz + k;
					elipse(2.5, 2.5, 1.7, function(ex, ey, ez) {
						var c = get(px + ex, py + ey, pz + ez);
						if( c == ROCK || c == SOIL ) set(px + ex, py + ey, pz + ez, CAVE);
					});
				}
				// unas phosphomousses en las paredes de la rampa: se ve de lejos que hay una gruta
				var glow = alloc(BKubeGreyHavenPhosphomoss);
				var left = 3;
				for( t in 0...60 ) {
					if( left == 0 ) break;
					var k = 1 + rnd.random(len - 2);
					var gx = Math.round(x + dx * k * 1.6) + rnd.random(7) - 3, gy = Math.round(y + dy * k * 1.6) + rnd.random(7) - 3, gz = cz + k + rnd.random(3) - 1;
					var c = get(gx, gy, gz);
					if( (c == ROCK || c == SOIL) && around(gx, gy, gz, CAVE) ) {
						set(gx, gy, gz, glow);
						left--;
					}
				}
				break;
			}
		}
	}

	/**
	 * La phosphomousse violeta en las paredes, el suelo y el techo de las grutas, en grupitos de 1 a 3 bloques repartidos; en lo
	 * hondo, algun grupito de phosphomousse del desierto
	 */
	function ghCaveGlow() {
		var purple = alloc(BKubeGreyHavenPhosphomoss), orange = alloc(BKubeDesertPhosphomoss);
		for( i in 0...Math.ceil(size * size / 600) ) {
			var ntry = 200;
			while( ntry-- > 0 ) {
				var x = rnd.random(size), y = rnd.random(size);
				var zmax = height(x, y);
				if( zmax <= 2 ) continue;
				var z = rnd.random(zmax);
				if( get(x, y, z) != CAVE ) continue;
				var b = z < waterLevel - 6 && rnd.random(10) == 0 ? orange : purple;
				var left = 1 + rnd.random(3);
				for( k in 0...24 ) {
					if( left == 0 ) break;
					var cx = x + rnd.random(5) - 2, cy = y + rnd.random(5) - 2, cz = z + rnd.random(5) - 2;
					var c = get(cx, cy, cz);
					if( (c == ROCK || c == SOIL) && around(cx, cy, cz, CAVE) ) {
						set(cx, cy, cz, b);
						left--;
					}
				}
				break;
			}
		}
	}

}
