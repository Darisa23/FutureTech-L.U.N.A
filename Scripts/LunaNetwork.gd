class_name LunaNetwork
extends RefCounted

# Red feedforward simple: 2 inputs → 2 hidden → 1 output
var weights_ih: Array  # input → hidden  [2][2]
var weights_ho: Array  # hidden → output [2][1]
var bias_h: Array      # bias capa hidden [2]
var bias_o: float      # bias output

func _init():
	randomize()
	weights_ih = [
		[randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)],
		[randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)]
	]
	weights_ho = [
		[randf_range(-1.0, 1.0)],
		[randf_range(-1.0, 1.0)]
	]
	bias_h = [randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)]
	bias_o = randf_range(-1.0, 1.0)

func sigmoid(x: float) -> float:
	return 1.0 / (1.0 + exp(-x))

func forward(inputs: Array) -> float:
	# Input → Hidden
	var hidden = []
	for i in 2:
		var sum = bias_h[i]
		for j in 2:
			sum += inputs[j] * weights_ih[j][i]
		hidden.append(sigmoid(sum))
	
	# Hidden → Output
	var output_sum = bias_o
	for i in 2:
		output_sum += hidden[i] * weights_ho[i][0]
	
	return sigmoid(output_sum)

func set_weight_ih(row: int, col: int, value: float):
	weights_ih[row][col] = value

func set_weight_ho(row: int, col: int, value: float):
	weights_ho[row][col] = value
