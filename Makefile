.PRECIOUS: census/%.zip shp/%.shp

states = shp/STATE/tl_2015_us_state.shp
counties = shp/COUNTY/tl_2015_us_county.shp
districts = shp/CD/tl_2015_us_cd114.shp
zipcodes = shp/ZCTA5/tl_2015_us_zcta510.shp
national = $(states) $(counties) $(districts)

help:
	@echo "View the README.md file for help"

#
# Download census files
#

census/%.zip:
	mkdir -p $(dir $@)
	curl -o $@ --create-dirs http://www2.census.gov/geo/tiger/TIGER2015/$*.zip

#
# Unzips Census files to shapefiles
#

shp/%.shp: census/%.zip
	mkdir -p $(dir $@)
	unzip -n $< -d $(dir $@)
	chmod 644 $(dir $@)*
	touch $(dir $@)*

#
# Topojson output
# Note: the states/%.json target is looking for a FIPS code for a state
#

us.json: $(national)
	mkdir -p us
	topojson -o us/states.json --id-property GEOID -p name=NAME,usps=STUSPS -s 2e-6 -- states=$(states)
	topojson -o us/counties.json --id-property GEOID -p name=NAME,sfp=STATEFP,cfp=COUNTYFP -s 2e-6 -- counties=$(counties)
	topojson -o us/cd114.json --id-property GEOID -p name=NAMELSAD,sfp=STATEFP,cdfp=CD114FP -s 2e-6 -- districts=$(districts)
	topojson -o us.json -- us/states.json us/counties.json us/cd114.json
 
states/%.json: $(national) shp/SLDL/tl_2015_%_sldl.shp shp/SLDU/tl_2015_%_sldu.shp
	mkdir -p $(dir $@) tmp
	ogr2ogr -where "STATEFP='$*'" tmp/state.shp $(states)
	ogr2ogr -where "STATEFP='$*'" tmp/county.shp $(counties)
	ogr2ogr -where "STATEFP='$*'" tmp/cd114.shp $(districts)
	topojson -o tmp/state.json --id-property GEOID -p name=NAME,usps=STUSPS -s 2e-7 -- state=tmp/state.shp
	topojson -o tmp/counties.json --id-property GEOID -p name=NAME,sfp=STATEFP,cfp=COUNTYFP -s 2e-7 -- counties=tmp/county.shp
	topojson -o tmp/districts.json --id-property GEOID -p name=NAMELSAD,sfp=STATEFP,cdfp=CD114FP -s 2e-7 -- districts=tmp/cd114.shp
	topojson -o tmp/senate.json --id-property GEOID -p name=NAMELSAD,sfp=STATEFP,did=SLDLST -s 2e-7 -- senate=shp/SLDU/tl_2015_$*_sldu.shp
	topojson -o tmp/house.json --id-property GEOID -p name=NAMELSAD,sfp=STATEFP,did=SLDLST -s 2e-7 -- house=shp/SLDL/tl_2015_$*_sldl.shp
	topojson -o $@ -- tmp/state.json tmp/counties.json tmp/districts.json tmp/senate.json tmp/house.json
	rm -rf tmp

ks.json: $(national) states/20.json $(zipcodes)
	mkdir -p tmp
	ogr2ogr -where "GEOID10 >= '66002' and GEOID10 <= '67954'" tmp/zips.shp $(zipcodes)
	topojson -o tmp/zips.json --id-property GEOID10 -s 2e-7 -- zips=tmp/zips.shp
	topojson -o ks.json -- states/20.json tmp/zips.json
	rm -rf tmp

mo.json: $(national) states/29.json $(zipcodes)
	mkdir -p tmp
	ogr2ogr -where "GEOID10 >= '63001' and GEOID10 <= '65899'" tmp/zips.shp $(zipcodes)
	topojson -o tmp/zips.json --id-property GEOID10 -s 2e-7 -- zips=tmp/zips.shp
	topojson -o mo.json -- states/29.json tmp/zips.json
	rm -rf tmp