#!/bin/bash
mkdir -p _build

./gener.sh
./genclear.sh > _build/clear.sh
(cat Informacje_Medyczne.sql; ./gendata.sh) > _build/create.sql
cp README.txt _build
cp er.png _build/diagram.png

cd _build
zip ../build.zip *
