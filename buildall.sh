#!/bin/bash

TARGETS="mvebu_mcbin-88f8040 rockpro64-rk3399 mvebu_espressobin-88f3720"

for t in $TARGETS; do
	make TARGET=$t
done
