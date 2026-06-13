class_name Arc2CodeData
extends RefCounted

# Cada línea: {"indent": nivel de indentación (x4 espacios), "code": texto sin indent}
static func get_blocks() -> Array:
	return [
		{
			"narrative": "El Colapso destruyó la interfaz visual. Solo queda el núcleo.\nReconstruye la clase que define la arquitectura de LUNA.",
			"lines": [
				{"indent": 0, "code": "class NeuralNetwork:"},
				{"indent": 1, "code": "def __init__(self):"},
				{"indent": 2, "code": "self.layers = []"},
				{"indent": 1, "code": "def add_layer(self, size, activation):"},
				{"indent": 2, "code": "self.layers.append(Layer(size, activation))"},
			]
		},
		{
			"narrative": "La arquitectura está en pie. Ahora instancia y configura el modelo.",
			"lines": [
				{"indent": 0, "code": "model = NeuralNetwork()"},
				{"indent": 0, "code": "model.add_layer(2, activation='relu')"},
				{"indent": 0, "code": "model.add_layer(4, activation='relu')"},
				{"indent": 0, "code": "model.add_layer(1, activation='sigmoid')"},
				{"indent": 0, "code": "optimizer = SGD(learning_rate=0.1)"},
			]
		},
		{
			"narrative": "Última fase: el ciclo de entrenamiento. LUNA depende de esto.",
			"lines": [
				{"indent": 0, "code": "for epoch in range(100):"},
				{"indent": 1, "code": "output = model.forward(X)"},
				{"indent": 1, "code": "loss = binary_crossentropy(output, y)"},
				{"indent": 1, "code": "model.backward(loss)"},
				{"indent": 1, "code": "optimizer.step()"},
			]
		}
	]
