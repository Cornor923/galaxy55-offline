package gen;

/**
	Array.sort con el mismo resultado que Flash.

	El Array.sort de Flash (Tamarin, ArraySort::qsort) es un quicksort NO estable: los elementos
	empatados quedan en un orden que depende del algoritmo. El generador de planetas ordena listas
	con empates (prioridades iguales) y luego consume numeros aleatorios en ese orden, asi que otro
	algoritmo de ordenacion (por ejemplo el estable de HashLink) genera planetas distintos.

	En Flash se usa el sort nativo. En el resto de plataformas se reproduce el algoritmo de Tamarin:
	pivote en el punto medio, particion tipo Hoare, casos desenrollados para 2 y 3 elementos,
	y la particion pequena se procesa primero.
**/
class FlashSort {

	public static function sort<T>( a : Array<T>, cmp : T -> T -> Int ) : Void {
		#if flash
		a.sort(cmp);
		#else
		var n = a.length;
		if( n < 2 ) return;
		var stkLo = new Array<Int>();
		var stkHi = new Array<Int>();
		var lo = 0;
		var hi = n - 1;
		while( true ) {
			var size = hi - lo + 1;
			if( size < 4 ) {
				if( size == 2 ) {
					if( cmp(a[lo], a[lo + 1]) > 0 ) swap(a, lo, lo + 1);
				} else if( size == 3 ) {
					if( cmp(a[lo], a[lo + 1]) > 0 ) {
						swap(a, lo, lo + 1);
						if( cmp(a[lo + 1], a[lo + 2]) > 0 ) {
							swap(a, lo + 1, lo + 2);
							if( cmp(a[lo], a[lo + 1]) > 0 ) swap(a, lo, lo + 1);
						}
					} else if( cmp(a[lo + 1], a[lo + 2]) > 0 ) {
						swap(a, lo + 1, lo + 2);
						if( cmp(a[lo], a[lo + 1]) > 0 ) swap(a, lo, lo + 1);
					}
				}
			} else {
				swap(a, lo + (size >> 1), lo);
				var left = lo;
				var right = hi + 1;
				while( true ) {
					do left++ while( left <= hi && cmp(a[left], a[lo]) <= 0 );
					do right-- while( right > lo && cmp(a[right], a[lo]) >= 0 );
					if( right < left ) break;
					swap(a, left, right);
				}
				swap(a, lo, right);
				if( right - 1 - lo >= hi - left ) {
					if( lo + 1 < right ) {
						stkLo.push(lo);
						stkHi.push(right - 1);
					}
					if( left < hi ) {
						lo = left;
						continue;
					}
				} else {
					if( left < hi ) {
						stkLo.push(left);
						stkHi.push(hi);
					}
					if( lo + 1 < right ) {
						hi = right - 1;
						continue;
					}
				}
			}
			if( stkLo.length == 0 ) return;
			lo = stkLo.pop();
			hi = stkHi.pop();
		}
		#end
	}

	#if !flash
	static inline function swap<T>( a : Array<T>, i : Int, j : Int ) {
		var t = a[i];
		a[i] = a[j];
		a[j] = t;
	}
	#end

}
