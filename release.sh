#!/bin/sh

version=0.3.0
name="enemy-distance-evolution_${version}"

git archive HEAD --format=zip --prefix="${name}/" -o "${name}.zip"
