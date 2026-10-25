## Tea & Tarts deterministic RNG (xorshift32). Never uses the global randi()/randomize():
## the same seed gives the same sequence on every platform and engine build (pure shifts/xors, masked to 32 bits).
extends RefCounted

const M32 := 0xFFFFFFFF
var _s: int = 1

func _init(seed_value: int = 1) -> void:
	set_seed(seed_value)

func set_seed(seed_value: int) -> void:
	# fold the 64-bit seed into 32 bits, avoid the all-zero state, then warm up
	var x := ((seed_value & M32) ^ ((seed_value >> 32) & M32) ^ 0x9E3779B9) & M32
	if x == 0: x = 0x6D2B79F5
	_s = x
	for i in 8: next_u32()

func next_u32() -> int:
	var x := _s
	x = (x ^ (x << 13)) & M32
	x = x ^ (x >> 17)
	x = (x ^ (x << 5)) & M32
	_s = x
	return x

## Uniform-ish integer in [0, n).
func below(n: int) -> int:
	return next_u32() % n if n > 0 else 0

func pick(arr: Array):
	return arr[below(arr.size())]

func shuffle(arr: Array) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j := below(i + 1)
		var t = arr[i]; arr[i] = arr[j]; arr[j] = t
