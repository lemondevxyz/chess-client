# env
export PROD_ID="107.191.62.233"
# build
echo "Building"
./build.sh
# compress stuff
echo "Compressing"
cd build/web/
7z a deploy.7z *
# move 7zip archive
echo "Moving archive to current directory"
mv deploy.7z ../..
cd ../../
# upload stuff
echo "Uploading..."
rsync -a deploy.7z "chess@$PROD_ID:~/" --progress
echo "Done uploading"
# execute server side script
echo "Executing Server-Side Script"
ssh "chess@$PROD_ID" "./do.sh"
echo "Done Server-Side Script"
