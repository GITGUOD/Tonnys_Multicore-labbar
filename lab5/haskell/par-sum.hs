import Control.Parallel
import Control.DeepSeq
import Data.Time
import Text.Printf (printf)
import GHC.Exts.Heap (GenClosure(key))

int_isqrt = floor . sqrt . fromIntegral

check_is_prime::(Int,Int)->Bool
check_is_prime(a, n) =
	if a == 1+int_isqrt n then
		True
	else if n `mod` a == 0 then
		False
	else
		check_is_prime(a+1, n)
		
is_prime:: Int->Bool
is_prime(n) = 
	if n == 2 then True
	else
		check_is_prime(2, n)

seq_sum_primes:: (Int,Int)->Int
seq_sum_primes(a, b) =
	if a > b then 0
	else if (is_prime(b)) then 	
		b + seq_sum_primes(a, b-1) -- addera primtalen
	else	
		seq_sum_primes(a, b-1) -- ananrsom det inte är ett primtal så kör vi om funk med nästa siffra

-- ganska identisk med seq bara att vi kör två st samtidigt
-- här under delar den arbetet i två delar
-- par_sum_primes:: (Int,Int)->Int
-- par_sum_primes(a, b) =
-- 	let	m = a + (b-a) `div` 2
-- 		s1 = seq_sum_primes(a, m)
-- 		s2 = seq_sum_primes(m+1, b)
-- 	in
-- 		par s1 (pseq s2 (s1 + s2)) -- arbetas/tvingas att göra det parallelt, första och andra halvan summeras sedan

-- Hur våran funkar är att om vi bara har en tråd så delar vi upp programmet i antalet k bitar
-- första fallet är om vi bara har 1 tråd, då kör vi seq
-- annars så räknar vi ut längden vilket är b - a, t.ex [2,10] -> längden, intervallet blir 8
-- räknar ut middlegrown
--
par_sum_primes:: Int -> (Int,Int)->Int
par_sum_primes k (a,b)
	| k <= 1 = seq_sum_primes(a,b)
	| otherwise = par rest (pseq first (first + rest))
	where
		lengh = b - a + 1
		step = lengh `div` k
		m = a + step - 1
		first = seq_sum_primes(a, m)
		rest = par_sum_primes(k-1)(m+1,b)

main:: IO()
main = do
	line <- getLine

	begin <- getCurrentTime

	let	[n] = map read (words line) :: [Int]
		s = par_sum_primes 16 (2,n)

	s `deepseq` do
		end <- getCurrentTime

		printf "par haskell sum of primes in 2..%d = %d \n" n s
		printf "time: "
		print $ diffUTCTime end begin

-- enligt t filen har vi -N4, 4 kärnor men endast två utnyttjas enligt par s1 (pseq s2 (s1 + s2)), vi har en huvudloop s2 och en annan tråd s1.

-- En spark är en liten notering i GHC:s runtime som säger: "det här uttrycket kanske är värt att räkna ut på en annan kärna." Den är ett tips, inte en order.


-- par s1 ...: s1 läggs som spark i kön. Huvudtråden går direkt vidare, utan att vänta. En ledig kapacitet kan nu börja räkna på s1.
-- pseq s2 ...: huvudtråden evaluerar s2 själv. Under tiden räknar den andra kapaciteten på s1.
-- s1 + s2: när s2 är klar beräknas summan.
-- Om s1 redan är klar används värdet direkt.
-- Om den andra kapaciteten fortfarande räknar väntar huvudtråden.
-- Om ingen plockade sparken räknar huvudtråden ut s1 själv.


-- Låt någon annan räkna s1 om de kan. Jag räknar s2 under tiden. När jag är klar tar jag summan av båda typ