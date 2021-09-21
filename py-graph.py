#!/usr/bin/python

import sys
import os
import networkx as nx
import matplotlib.pyplot as plt
# import random
import yaml
import PIL


# Meta parameters
DIR_PATH = os.path.dirname(os.path.realpath(__file__))
IMG_EXT = ".png"
IMG_TYPE = PIL.PngImagePlugin.PngImageFile
CTR_INCR = 200 # increment for controller's nodes names
OUT_INCR = 100 # increment for outputs's nodes names

# Graph Layout
INP_NODE_COLOR = "red"
INN_NODE_COLOR = "black"
OUT_NODE_COLOR = "blue"
POSITIONING = "dual" # circular spring dual
MERGE_CONTROLLER_INPUT = False
XLIM = 100
YLIM = 100
NODES_SPACING = 10

def str_to_tuple(s):
	if s[0] == "(":
		s = s[1:-1]
	if s[-1] == ")":
		s = s[0:-2]
	return tuple(map(int, s.split(', ')))

def open_yaml(path):
	with open(path, 'r') as stream:
		try:
			return yaml.safe_load(stream)
		except yaml.YAMLError as exc:
			print(exc)

def retrieve_buffer(ind_name, path, frame):
	if ind_name == "encoder":
		return retrieve_img_buffer(path, frame, "e")
	elif ind_name == "reducer":
		return retrieve_img_buffer(path, frame, "f")
	elif ind_name == "controller":
		return retrieve_cont_buffer(path, frame)
	else:
		raise NameError(ind_name)

def retrieve_img_buffer(path, frame, key):
	b = {}
	for f in os.listdir(path):
		if int(f[0]) == frame and f[2] == key:
			node = int(f[3:-len(IMG_EXT)])
			b[node] = PIL.Image.open(path + f)
	return b

def retrieve_cont_buffer(path, frame):
	fname = path + str(frame) + "_c.yaml"
	b = open_yaml(fname)
	return b

def retrieve_metadata(path, frame):
	fname = path + str(frame) + "_m.yaml"
	return open_yaml(fname)

def get_paths(exp_dir):
	g_dir = exp_dir + "/graphs"
	paths = {}
	for f in os.listdir(g_dir):
		ind_name = f[0:len(f)-len(".yaml")]
		paths[ind_name] = {}
		paths[ind_name]["graph"] = g_dir + "/" + f
		paths[ind_name]["buffer"] = exp_dir + "/buffers/"
	paths["reducer"] = {}
	paths["reducer"]["buffer"] = exp_dir + "/buffers/"
	paths["meta"] = exp_dir + "/buffers/"
	return paths

def gdict_from_paths(paths, frame):
	gdict = {}
	for ind_name in ["encoder", "controller"]:
		v = paths[ind_name]
		g = open_yaml(v["graph"])
		g["inputs"] = list(range(1,1+g["n_in"]))
		g["edges"] = [str_to_tuple(e) for e in g["edges"]]
		g["buffer"] = retrieve_buffer(ind_name, v["buffer"], frame)
		gdict[ind_name] = g
	gdict["reducer"] = {}
	gdict["reducer"]["buffer"] = retrieve_buffer("reducer", paths["reducer"]["buffer"], frame)
	gdict["meta"] = retrieve_metadata(paths["meta"], frame)
	return gdict

def test_gdict():
	bpath = DIR_PATH + '/results/2021-09-01T17:44:01.968_boxing/buffers/'
	eb = retrieve_img_buffer(bpath, 1, "e")
	rb = retrieve_img_buffer(bpath, 1, "f")
	img = eb[1]
	red = rb[list(rb.keys())[0]]
	gdict = {
		'encoder': {
			'nodes': [4, 5, 6],
			'fs': ['f1', 'f2', 'f3'],
			'n_in': 3,
			'n_out': 2,
			'inputs': [1, 2, 3],
			'outputs': [4, 6],
			'edges': [(1, 4), (2, 4), (3, 5), (5, 6)],
			'buffer': {1:img, 2:img, 3:img, 4:img, 5:img, 6:img}
		},
		'controller': {
			'nodes': [6, 7, 8, 9, 10],
			'fs': 5*["f"],
			'n_in': 5,
			'n_out': 5,
			'inputs': [1, 2, 3, 4, 5],
			'outputs': [1, 2, 6, 8, 10],
			'edges': [(1, 6), (2, 6), (3, 7), (7, 8), (4, 10)],
			'buffer': {1:0.0, 2:0.2, 3:0.3, 4:0.4, 5:0.5, 6:0.6, 7:0.7, 8:0.8, 9:0.9, 10:1.0}
		},
		'reducer': {'buffer': {4:red, 6:red}},
		'meta': {'action':1, 'is_sticky': False}
	}
	return gdict

def incr_nodes(g, incr):
	for k in ["nodes", "inputs", "outputs"]:
		g[k] = [n + incr for n in g[k]]
	g["edges"] = [(e[0]+incr, e[1]+incr) for e in g["edges"]]
	init_keys = [k for k in g["buffer"].keys()]
	for k in init_keys:
		g["buffer"][k+incr] = g["buffer"].pop(k)
	return g

def dualcgp_colors(G, gdict):
	colors = []
	for n in G:
		if n in gdict["encoder"]["inputs"] + gdict["controller"]["inputs"]:
			c = INP_NODE_COLOR
		elif n in gdict["encoder"]["outputs"] + gdict["controller"]["outputs"]:
			c = OUT_NODE_COLOR
		else:
			c = INN_NODE_COLOR
		colors.append(c)
	return colors

def merge_cinpos(pos, gdict):
	gc = gdict["controller"]
	# refpos = pos[gc["inputs"][0]]
	refpos = (0, 0)
	for o in gc["inputs"]:
		pos[o] = refpos
	return pos
	
def get_pos(G, gdict, seed, verbose=False):
	if POSITIONING == "spring":
		pos = nx.spring_layout(G, seed=seed)
	elif POSITIONING == "circular":
		pos = nx.circular_layout(G)
	elif POSITIONING == "dual":
		pos = dual_pos(G, gdict)
	else:
		raise NameError(POSITIONING)
	if MERGE_CONTROLLER_INPUT:
		pos = merge_cinpos(pos, gdict)
	if verbose:
		print("\nNodes positions:")
		for k, v in pos.items():
			print(k, v)
	return pos

def dual_pos(G, gdict):
	ge = gdict["encoder"]
	gc = gdict["controller"]
	e_out = get_output_nodes_labels(G, ge["outputs"])
	c_out = get_output_nodes_labels(G, gc["outputs"])
	e_mid = [n for n in ge["buffer"].keys() if n not in ge["inputs"]]
	c_mid = [n for n in gc["buffer"].keys() if n not in gc["inputs"]]
	e_n_mid, e_n_inp, e_n_out = len(e_mid), len(ge["inputs"]), len(ge["outputs"])
	c_n_mid, c_n_inp, c_n_out = len(c_mid), len(gc["inputs"]), len(gc["outputs"])
	d = NODES_SPACING
	pos = {}
	
	# Encoder pos
	e_xs = [(x-0.5*(e_n_mid+1))*d for x in range(e_n_mid+2)]
	e_inp_ys = [d*(y-(e_n_inp-1)/2) for y in range(e_n_inp)]
	e_out_ys = [d*(y-(e_n_out-1)/2) for y in range(e_n_out)]
	for i in range(len(ge["inputs"])):
		pos[ge["inputs"][i]] = (e_xs[0], e_inp_ys[i])
	for i in range(len(e_mid)):
		pos[e_mid[i]] = (e_xs[i+1], 0.0)
	for i in range(len(e_out)):
		pos[e_out[i]] = (e_xs[-1], e_out_ys[i])

	# Controller pos
	y_drift = 0.6 * d * (e_n_out+c_n_out) # max(e_n_inp+c_n_inp, e_n_out+c_n_out)
	c_xs = [(x-0.5*(c_n_mid+1))*d for x in range(c_n_mid+2)]
	c_inp_ys = [d*(y-(c_n_inp-1)/2)-y_drift for y in range(c_n_inp)]
	c_out_ys = [d*(y-(c_n_out-1)/2)-y_drift for y in range(c_n_out)]
	for i in range(len(gc["inputs"])):
		# pos[gc["inputs"][i]] = (c_xs[0], c_inp_ys[i])  # Equally spanned input
		pos[gc["inputs"][i]] = (c_xs[0], 5*d-y_drift)  # Single input node
	for i in range(len(c_mid)):
		pos[c_mid[i]] = (c_xs[i+1], -y_drift)
	for i in range(len(c_out)):
		pos[c_out[i]] = (c_xs[-1], c_out_ys[i])

	return pos
	
def get_output_nodes_labels(G, outputs):
	out = []
	for i in range(len(outputs)):
		out_i = outputs[i] + OUT_INCR
		while out_i in out:
			out_i += 1
		out.append(out_i)
	return out
	
def set_graph(G, g, gr=None):
	# Nodes
	G.add_nodes_from(g["buffer"].keys())
	output_nodes = get_output_nodes_labels(G, g["outputs"])
	G.add_nodes_from(output_nodes)

	# Edges
	G.add_edges_from(g["edges"])
	for i in range(len(output_nodes)):
		G.add_edge(g["outputs"][i], output_nodes[i])
	edgelabels = {}
	for e in g["edges"]:
		dest_node = e[1]
		dest_node_index = g["nodes"].index(dest_node)
		edgelabels[e] = g["fs"][dest_node_index]

	# Set colors
	edgecolors = []
	for n in G:
		if n in g["inputs"]:
			edgecolors.append(INP_NODE_COLOR)
		elif n in g["outputs"]:
			edgecolors.append(OUT_NODE_COLOR)
		else:
			edgecolors.append(INN_NODE_COLOR)

	# Set inner buffer
	for n in g["buffer"].keys():
		G.nodes[n]["buffer"] = g["buffer"][n]
	
	# Set output buffer
	for i in range(len(output_nodes)):
		out_node_i = output_nodes[i]
		out_i = g["outputs"][i]
		r_buffer_i = g["buffer"][out_i] if gr is None else gr["buffer"][out_i]
		G.nodes[out_node_i]["buffer"] = r_buffer_i
		
	return G, edgelabels, edgecolors
	
def make_enco_graph(gdict):
	ge = gdict["encoder"]
	G = nx.DiGraph()
	G, edgelabels, edgecolors = set_graph(G, ge, gdict["reducer"])
	return G, edgelabels, edgecolors
	
def make_cont_graph(gdict):
	gc = incr_nodes(gdict["controller"], CTR_INCR)
	G = nx.DiGraph()
	G, edgelabels, edgecolors = set_graph(G, gc)
	return G, edgelabels, edgecolors

def make_dualcgp_graph(gdict):
	ge = gdict["encoder"]
	gc = incr_nodes(gdict["controller"], CTR_INCR)
	G = nx.DiGraph()
	edgelabels, edgecolors = {}, []
	
	# Fetch encoder graph info
	G, lab, _ = set_graph(G, ge, gdict["reducer"])
	edgelabels.update(lab)
	
	# Fetch controller graph info
	G, lab, _ = set_graph(G, gc)
	edgelabels.update(lab)
	
	edgecolors = dualcgp_colors(G, gdict)
	return G, edgelabels, edgecolors

def draw_graph(G, edgelabels, edgecolors, pos):
	#fig, ax = plt.subplots()
	fig = plt.figure(figsize=(5,5))
	ax = plt.subplot(111)
	ax.set_aspect('equal')
	ax.margins(0.20)
	#ax.axis("off")
	#plt.axis("off")
	
	plt.xlim(-XLIM, XLIM)
	plt.ylim(-2.2*YLIM, 0.4*YLIM)
	'''
	plt.xlim(-2, 2)
	plt.ylim(-2, 2)
	'''	
	
	options = {
		"with_labels": True,
		"font_size": 10,
		"node_size": 100,
		"node_shape": 'o', # s o
		"node_color": "white",
		"edgecolors": edgecolors,
		"linewidths": 1,
		"width": 1 # , "with_labels": True
	}
	nx.draw_networkx(G, pos, **options)
	nx.draw_networkx_edge_labels(G, pos, edge_labels=edgelabels, font_color='black')
	
	"""
	# Transform from data coordinates (scaled between xlim and ylim) to display coordinates
	tr_figure = ax.transData.transform
	# Transform from display to figure coordinates
	tr_axes = fig.transFigure.inverted().transform

	# Select the size of the image (relative to the X axis)
	img_size = (ax.get_xlim()[1] - ax.get_xlim()[0]) * 0.002
	img_center = img_size / 2.0

	# Add the respective image to each node
	for n in G.nodes:
		if type(G.nodes[n]["buffer"]) == IMG_TYPE:
			xf, yf = tr_figure(pos[n])
			xa, ya = tr_axes((xf, yf))
			a = plt.axes([xa - img_center, ya - img_center, img_size, img_size])
			a.imshow(G.nodes[n]["buffer"])
			a.axis("off")
	"""
	plt.show()

def show_img_buffer(gdict, elt="encoder", node=1):
	image = gdict[elt]["buffer"][node]
	print(image.format)
	print(image.mode)
	print(image.size)
	image.show()

def print_gdict(gdict):
	print("\nLoaded graph dict:")
	print("\nencoder:")
	print(gdict["encoder"])
	print("\nreducer:")
	print(gdict["reducer"])
	print("\ncontroller:")
	print(gdict["controller"])
	print("\nmetadata:")
	print(gdict["meta"])
	print()

if __name__ == "__main__":
	exp_dir = sys.argv[1]
	seed = 0 if (len(sys.argv) < 3) else int(sys.argv[2])

	frame = 1
	
	paths = get_paths(exp_dir)
	is_test = False
	verbose = True

	gdict = test_gdict() if is_test else gdict_from_paths(paths, frame)

	if verbose:
		print_gdict(gdict)

	G, lab, col = make_dualcgp_graph(gdict)
	pos = get_pos(G, gdict, seed, verbose=False)
	
	draw_graph(G, lab, col, pos)

	"""
	G, lab, col = make_enco_graph(gdict)
	pos = get_pos(G, gdict, seed, verbose=False)
	draw_graph(G, lab, col, pos)

	G, lab, col = make_cont_graph(gdict)
	pos = get_pos(G, gdict, seed, verbose=False)
	draw_graph(G, lab, col, pos)
	"""

# python3.7 py-graph.py /home/wahara/.julia/dev/IICGP/results/2021-09-01T17:44:01.968_boxing
# python3.8 py-graph.py /home/opaweynch/.julia/environments/v1.6/dev/IICGP/results/2021-09-01T17:44:01.968_boxing

