-- deepseq forces a value to be fully evaluated. Haskell is lazy 
import Control.DeepSeq 
-- time imports
import Data.Time
-- print values
import Text.Printf (printf)

-- floor x returns the greatest integer not greater than x
-- . sqrt returns square root
-- from Integral converts int to a floating-point nbr
-- Så den gör om en int till ett heltal, tar kvadratroten och avrundar nedåt till heltal
int_isqrt = floor . sqrt . fromIntegral

-- declaring check_is_prime
check_is_prime::(Int,Int)->Bool
-- function
check_is_prime(a, n) =
	if a == 1+int_isqrt n then -- if, kollar om siffran vi vill kolla (n) primtalet har en rotlösning
		True
	else if n `mod` a == 0 then -- om det går att dela evenly så falsk
		False
	else
		check_is_prime(a+1, n) -- kolla vidare
		
is_prime:: Int->Bool
is_prime(n) = 
	if n == 2 then True -- basfall om vi har at n == 2 så går det snabbt
	else
		check_is_prime(2, n)

-- Räkna primtal
sum_prime:: (Int,Int)->Int
sum_prime(a, b)
	| a > b = 0 -- det översta elementet är mindre -> ger oss ett tomt interval
	| otherwise =
		if (is_prime(b)) then 	
			b + sum_prime(a, b-1) -- arbetar nedåt från b
		else	
			sum_prime(a, b-1)
	
main:: IO()
main = do
	line <- getLine
	begin <- getCurrentTime

	let	[n] = map read (words line) :: [Int]
		s = sum_prime(2,n)

	s `deepseq` do
		end <- getCurrentTime

		printf "seq haskell sum of primes in 2..%d = %d \n" n s
		printf "time: "
		print $ diffUTCTime end begin

-- första versionen adderade bara 1 siffra per prime, här: 1 + sum_prime(a, b-1) -- arbetar nedåt från b
--  nu: 			b + sum_prime(a, b-1) -- arbetar nedåt från b
