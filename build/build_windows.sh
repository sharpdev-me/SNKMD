#!/bin/bash
cd build

7z a -r game.zip ../ -xr!engine/love -xr!build -xr!.git -xr!*.moon -xr!conf.lua -xr!.gitignore -xr!.vscode
mv game.zip game.love

mkdir -p windows/build64

cat ../engine/love.exe game.love > windows/build64/SNKRX.exe

cp ../engine/love/*.dll windows/build64/
cp ../engine/love/*.txt windows/build64/

7z a windows/SNKRX-windows64.zip windows/build64/


## Done!
rm game.love