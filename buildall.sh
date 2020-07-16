#!/bin/bash

TARGETS="mvebu_mcbin-88f8040 rockpro64-rk3399"

for t in $TARGETS; do
	make TARGET=$t
done
