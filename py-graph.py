#!/usr/bin/python

import sys
import os
import networkx as nx
import matplotlib.pyplot as plt
import yaml


# Meta parameters
DIR_PATH = os.path.dirname(os.path.realpath(__file__))
IMG_TYPE = ".png"
INP_NODE_COLOR = "red"
INN_NODE_COLOR = "black"
OUT_NODE_COLOR = "blue"


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
		return retrieve_enco_buffer(path, frame)
	elif ind_name == "controller":
		return retrieve_cont_buffer(path, frame)
	else:
		raise NameError("ind_name ", ind_name, " not implemented")

def retrieve_enco_buffer(path, frame):
	b = {}
	for f in os.listdir(path):
		if int(f[0]) == frame and f[2] == "e":
			node = int(f[3:-len(IMG_TYPE)])
			b[node] = node # TODO load image
	return b

def retrieve_cont_buffer(path, frame):
	fname = path + str(frame) + "_c.yaml"
	b = open_yaml(fname)
	
	return b

def get_paths(exp_dir):
	g_dir = exp_dir + "/graphs"
	dct = {}
	for f in os.listdir(g_dir):
		ind_name = f[0:len(f)-len(".yaml")]
		dct[ind_name] = {}
		dct[ind_name]["graph"] = g_dir + "/" + f
		dct[ind_name]["buffer"] = exp_dir + "/buffers/"
	return dct

def g_dict_from_paths(paths, frame):
	g_dict = {}
	for ind_name, v in paths.items():
		g = open_yaml(v["graph"])
		g["edges"] = [str_to_tuple(e) for e in g["edges"]]
		g["buffer"] = retrieve_buffer(ind_name, v["buffer"], frame)
		g_dict[ind_name] = g
	return g_dict

def make_graph(g):
	G = nx.DiGraph()
	G.add_nodes_from(list(range(1, g["n_in"] + 1))) # Input nodes
	G.add_nodes_from(g["nodes"])
	G.add_edges_from(g["edges"])
	edgelabels = {}
	for e in g["edges"]:
		dest_node = e[1]
		dest_node_index = g["nodes"].index(dest_node)
		edgelabels[e] = g["fs"][dest_node_index]
	edgecolors = []
	for n in G:
		if n <= g["n_in"]:
			edgecolors.append(INP_NODE_COLOR)
		elif n in g["outputs"]:
			edgecolors.append(OUT_NODE_COLOR)
		else:
			edgecolors.append(INN_NODE_COLOR)
	return G, edgelabels, edgecolors

def draw_graph_structure(G, edgelabels, edgecolors, seed=123):
	pos = nx.spring_layout(G, seed=seed)
	options = {
		"font_size": 15,
		# "node_size": 1000,
		"node_shape": 's',
		"node_color": "white",
		"edgecolors": edgecolors,
		"linewidths": 1,
		"width": 1 # , "with_labels": True
	}
	nx.draw_networkx(G, pos, **options)
	nx.draw_networkx_edge_labels(G, pos, edge_labels=edgelabels, font_color='black')

	# Set margins for the axes so that nodes aren't clipped
	ax = plt.gca()
	ax.margins(0.20)
	plt.axis("off")
	plt.show()

def draw_graph(G, seed=123):
	fig, ax = plt.subplots()
	ax.set_aspect('equal')
	plt.xlim(-1.5,1.5)
	plt.ylim(-1.5,1.5)
	pos = nx.spring_layout(G, seed=seed)
	edge_options = {
		"pos": pos,
		"ax": ax,
		"arrows": True,
		"arrowstyle": "-"
	}

	# Note: the min_source/target_margin kwargs only work with FancyArrowPatch objects.
	# Force the use of FancyArrowPatch for edge drawing by setting `arrows=True`,
	# but suppress arrowheads with `arrowstyle="-"`
	nx.draw_networkx_edges(G, **edge_options)
	# nx.draw_networkx(G, **graph_options)

	# Transform from data coordinates (scaled between xlim and ylim) to display coordinates
	tr_figure = ax.transData.transform
	# Transform from display to figure coordinates
	tr_axes = fig.transFigure.inverted().transform

	# Select the size of the image (relative to the X axis)
	img_size = (ax.get_xlim()[1] - ax.get_xlim()[0]) * 0.1
	img_center = img_size / 2.0

	# Add the respective image to each node
	for n in G.nodes:
		xf, yf = tr_figure(pos[n])
		print(pos[n])
		print(xf, yf)
		print()
		xa, ya = tr_axes((xf, yf))
		# get overlapped axes and plot icon
		a = plt.axes([xa - img_center, ya - img_center, img_size, img_size])
		a.imshow(G.nodes[n]["image"])
		a.axis("off")

	ax.axis("off")
	plt.show()

def makedraw_graph(g):
	g, lab, col = make_graph(g)
	draw_graph_structure(g, lab, col, seed)

if __name__ == "__main__":
	exp_dir = sys.argv[1]
	seed = 0 if (len(sys.argv) < 3) else int(sys.argv[2])

	frame = 1

	paths = get_paths(exp_dir)
	g_dict = g_dict_from_paths(paths, frame)

	# TODO rm START
	print("\nLoaded graph dict:")
	print("\nencoder:")
	print(g_dict["encoder"])
	print("\ncontroller:")
	print(g_dict["controller"])
	print()
	# TODO rm END

	# makedraw_graph(g_dict["encoder"])
	# makedraw_graph(g_dict["controller"])

