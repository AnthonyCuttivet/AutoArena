class_name Scalings

static var fibs = [
	1, 2, 3, 5, 8, 13, 21, 34,
	55, 89, 144, 233, 377, 610, 987, 1597, 2584, 4181,
	6765, 10946, 17711, 28657, 46368, 75025, 121393, 196418, 317811, 514229,
	832040, 1346269, 2178309, 3524578, 5702887, 9227465, 14930352, 24157817, 39088169, 63245986,
]

static var primes = [
	2, 3, 5, 7, 11, 13, 17, 19, 23, 29,
	31, 37, 41, 43, 47, 53, 59, 61, 67, 71,
	73, 79, 83, 89, 97, 101, 103, 107, 109, 113
]

static func linear(v:int):
	return v+1;

static func prime(current_index: int) -> int:
	if current_index < primes.size():
		return primes[current_index]
	else:
		# Generate more primes on the fly if list exhausted
		var candidate = primes[-1] + 2
		while true:
			var is_prime = true
			for p in primes:
				if candidate % p == 0:
					is_prime = false
					break
				if p * p > candidate:
					break
			if is_prime:
				primes.append(candidate)
				return candidate
			candidate += 2

	return 0;


static func fibonacci(current_index: int) -> int:
	if current_index < fibs.size():
		return fibs[current_index]
	else:
		# Generate more if list exhausted
		var a = fibs[-2]
		var b = fibs[-1]
		var next_val = a + b
		fibs.append(next_val)
		return next_val

static func triangular(current_index: int) -> int:
	return int(current_index * (current_index + 1) / 2.0);

static func random(m:int) -> int:
	return randi_range(1,m);

static func factorial(current_index: int) -> int:
	var result: int = 1
	for i in range(2, current_index + 1):
		result *= i
	return result

static func log_(current_index: int, base_value: float = 10.0) -> float:
	return log(current_index + 1) / log(base_value)
