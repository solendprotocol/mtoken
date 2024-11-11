#!/bin/bash

rm -rf sdk/src/_codegen/_generated/_dependencies/*
rm -rf sdk/src/_codegen/_generated/_framework/*
rm -rf sdk/src/_codegen/_generated/mtoken/*
rm -rf sdk/src/_codegen/_generated/.eslintrc.json

cd sdk/src/_codegen/_generated

sui-client-gen

cd ../../../..