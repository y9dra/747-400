today=`date '+%Y/%m/%d %H:%M'`;
versionid="XP1205-$today";
versionline="fmcVersion=\"$versionid\"";
echo $versionline >> plugins/xtlua/scripts/B747.05.xt.simconfig/version.lua
pandoc -o README.pdf README.md -V fontsize:8pt
git add --all
