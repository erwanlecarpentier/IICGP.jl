"2022-02-08T15:19:07.129_1_boxing" : { # Simple encoder alternating between positive and negative view of the opponent. Controller simply runs towards the top right corner and hits when one of the two regions where the boxers are supposed to be is bright.
	"encoder": {
		"1": (0,0), "2": (2.4,-1.1), "5": (2.4,1.1), "6": (4.6,0), "9": (6.9,0), "out9": (4.6,0),
		"names": {"5": "E1", "2": "E2"},
		"avoided": ["6", "9"],
		"extra_edges": [("5", "out9")],
		"backgroundnode": {"pos": (-1, 0), "width": (1.8, 2.5, 1.4), "height": 4.4}
	},
	"controller": {
		"34": (2,8),
		"32": (2,6),
		"29": (2,5),
		"35": (2,3),
		"27": (2,-3),
		"30": (2,-5),
		"26": (2,-6),
		"77": (11,9), "46": (8,9),
		"48": (11,8),
		"86": (11,7), "57": (8,7), "45": (5,7),
		"69": (11,5),
		"47": (11,0),
		"68": (8,-1),
		"38": (11,-4), "37": (8,-4),
		"76": (11,-6), "55": (8,-6), "36": (5,-6),
		"94": (8,-8),
		"names": {"46": "C1", "77": "C2", "48": "C3", "45": "C4", "57": "C5", "86": "C6", "69": "C7", "47": "C8", "68": "C9", "37": "C10", "38": "C11", "36": "C12", "55": "C13", "76": "C14", "94": "C15"},
		"sticky": (-1,6), #(14, 10),
		"customndopt": { # last custom opt
			"thick, draw=orange": [
				"9", "46", "77", "out77",
				"2", "20", "94", "out94"
			],
			"thick, draw=red!80!yellow": ["13", "48", "out48"],
			"thick, draw=teal": ["10", "21", "45", "57", "86", "out86"],
			"thick, draw=purple": [
				"29", "17", "69", "out69",
				"7", "6", "55", "76", "out76"
			],
			"thick, text=black, draw=yellow!70!orange": [
				"35", "out35", "out41",
				"25", "30", "37", "38"
			],
			"thick, draw=cyan": ["8", "18", "47", "out47", "out47'"],
			"thick, draw=red": ["15", "68", "out68"],
			"thick, draw=black": ["34", "36", "14", "16"],
			"thick, draw=black!50!white": [
				"4", "out4",
				"32", "out32",
				"23", "out23",
				"27", "out27",
				"5", "out5",
				"26", "out81",
				"out38"
			]
		},
		"customedgeopt": { # last custom opt
			"thick, color=orange": [
				(9,46), (36,77), (34,46), (46,77), (77,"out77"),
				(20,94), (94,"out94")
			],
			"thick, color=orange, out=-120, in=-120": [
				(2,94)
			],
			"thick, color=red!80!yellow": [(13,48), (14,48), (48,"out48")],
			"thick, color=teal": [(10,57), (21,86), (34,45), (45,57), (57,86), (86,"out86")],
			"thick, color=black!50!white": [
				(4, "out4"),
				(32,"out32"),
				(27,"out27"),
				(23,"out23"),
				(5,"out5"),
				(26,"out81"),
				(26, "out38")
			],
			"thick, color=purple": [
				(29,69), (17,69), (69,"out69"),
				(7,55),(6,76),(36,55),(55,76),(76,"out76")
			],
			"thick, color=yellow!70!orange": [
				(35,"out35"), (35,"out41")
				#(25,37), (30,38), (37,38), (38,"out38")
			],
			#"thick, color=yellow!70!orange, out=-40, in=-168": [(16,37)],
			"thick, color=cyan": [(8,47),(18,47),(47,"out47"),(47,"out47'")],
			"thick, color=red": [(15,68),(36,68),(68,"out68")],
			"thick, color=black": [(14,36),(16,36)],
		},
		"customedges": {
			(4,"out4"): "bend left=10",
			(27,"out27"): "bend left=20",
			(23,"out23"): "bend right=20",
			(26,"out38"): "bend left=8",
			(26,"out81"): "bend right=12", # (30,38): "bend right=10",
			(16,36): "bend right=5",
			(2, 94): "bend right=90, looseness=1.2"
		},
		"customedgesanchors": {
			("2", "94"): ("west", "west")
		},
		"inputs": {"type": "squares", "origin": (0, 0), "innerspan": 1, "squarespan": 7,
			"cst_in": True, "cst_input_y": -5},
		"avoided": [
			"25", "30", "37", "38",
			"41", "42", "81",
			"1", "3", "11", "12", "19", "22", "24",
			"28", "31", "33"
		],
		"extra_edges": [(13,48), ("26","out81"), ("35","out41"), ("26", "out38")],
		"outputs": {"type": "column", "pos": (14, 0), "span": 1},
		"backgroundnode": {"pos": (-2.8, 0.7), "width": (5.3, 9.8, 2.1), "height": 18.5}
	}
}
