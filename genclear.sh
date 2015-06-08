#!/bin/bash
src=Informacje_Medyczne.sql
cat $src | grep 'create table' | cut -d' ' -f3 | while read line; do
    echo "drop table if exists $line cascade;"
done

cat $src | grep 'create function' | cut -d' ' -f3 | while read line; do
    echo "drop function if exists $line cascade;"
done
