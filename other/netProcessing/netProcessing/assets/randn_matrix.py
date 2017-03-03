import sys
import random

# Third-party libraries
import numpy as np
if len(sys.argv) == 1:
	sizes = raw_input()#raw_input("what sizes would you like?\n in the format \"number number number\\n\" for example:\n1 2 3\\n")
	a = ''
	b = []
	for i in sizes:
		if i == ' ':
			b.append(a)
			a = ''
		else:
			a += i
	b.append(a)
	sizes = []
	for i in b:
		sizes.append(int(i))
else:
	sizes = sys.argv[1:]
f = open("randomized_matrix.txt", 'w')
f.write(str(len(sizes)) + ' ')
for i in sizes:
	f.write(str(i) + ' ')
num_layers = len(sizes)
sizes = sizes
biases = [np.random.randn(y, 1) for y in sizes[1:]]
weights = [np.random.randn(y, x) for x, y in zip(sizes[:-1], sizes[1:])]
to_out = str(weights)
wrote = 1
for i in to_out:
	if ((i.isalpha() == 0) and (i.isalnum() == 1)) or (i == '-') or (i == '.'):
		f.write(i)
		wrote = 0
	else:
		if wrote == 0:
			f.write(' ')
		wrote = 1
f.close()