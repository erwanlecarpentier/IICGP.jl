#!/usr/bin/python

import sys
import os
import networkx as nx
import matplotlib.pyplot as plt
import yaml


DIR_PATH = os.path.dirname(os.path.realpath(__file__))


def str_to_tuple(s):
	if s[0] == "(":
		s = s[1:-1]
	if s[-1] == ")":
		s = s[0:-2]
	return tuple(map(int, s.split(', ')))

def get_g_paths_dict(exp_dir):
	g_dir = exp_dir + "/graphs"
	dct = {}
	for f in  os.listdir(g_dir):
		ind_name = f[0:len(f)-len(".yaml")]
		dct[ind_name] = g_dir + "/" + f
	return dct

def g_dict_from_g_paths_dict(g_paths_dict):
	g_dict = {}
	for k, v in g_paths_dict.items():
		with open(v, 'r') as stream:
			try:
				g = yaml.safe_load(stream)
				g["edges"] = [str_to_tuple(e) for e in g["edges"]]
				g_dict[k] = g
			except yaml.YAMLError as exc:
				print(exc)		
	return g_dict

def make_graph(g):
	G = nx.DiGraph()
	G.add_nodes_from(list(range(1, g["n_in"] + 1))) # Input nodes
	G.add_nodes_from(g["nodes"])
	G.add_edges_from(g["edges"])
	edge_labels = {}
	for e in g["edges"]:
		dest_node = e[1]
		dest_node_index = g["nodes"].index(dest_node)
		edge_labels[e] = g["fs"][dest_node_index]
	return G, edge_labels

def draw_graph_structure(G, edge_labels, seed=123):
	pos = nx.spring_layout(G, seed=seed)
	options = {
		"font_size": 15,
		# "node_size": 1000,
		"node_color": "white",
		"edgecolors": "black",
		"linewidths": 1,
		"width": 1 # , "with_labels": True
	}
	nx.draw_networkx(G, pos, **options)
	nx.draw_networkx_edge_labels(G, pos, edge_labels=edge_labels, font_color='red')

	# Set margins for the axes so that nodes aren't clipped
	ax = plt.gca()
	ax.margins(0.20)
	plt.axis("off")
	plt.show()

'''
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
'''

if __name__ == "__main__":
	exp_dir = sys.argv[1]
	seed = 0 if (len(sys.argv) < 3) else int(sys.argv[2])

	g_paths_dict = get_g_paths_dict(exp_dir)
	g_dict = g_dict_from_g_paths_dict(g_paths_dict)

	# TODO rm START
	print("\nLoaded graph dict:")
	print(g_dict["encoder"])
	print()
	# TODO rm END

	g_enco, enco_edge_labels = make_graph(g_dict["encoder"])
	draw_graph_structure(g_enco, enco_edge_labels, seed)

