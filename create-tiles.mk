zip_url = https://www.naturalearthdata.com/http//www.naturalearthdata.com/download/50m/cultural/ne_50m_admin_0_countries.zip
filename = ne_50m_admin_0_countries

.PHONY : all

all: create-tiles

$(filename).zip:
	wget ${zip_url} -O $@

$(filename).shp: $(filename).zip
	unzip -o $< -d ./data/
	rm -rf $<

# GDAL 3.0.4
# Create countries.geojson
countries.geojson: $(filename).shp
	rm -rf $@
	ogr2ogr -dialect sqlite -sql "SELECT name, geometry FROM $(filename)" -f GeoJSON ./data/$@ -nln countries ./data/$<

# SQLite does no implement ST_Dump
# SQLite generate_series (3.37.0)
# Create places.geojson
places.geojson: $(filename).shp
	rm -rf $@
	ogr2ogr -dialect sqlite -sql "select * from (select tt1.name as name, ST_PointOnSurface(tt2.polygon) as Centroid from ( select name as name, max(ST_Area(polygon)) as area from ( WITH RECURSIVE my_generate_series(name, value, maxv) AS ( select name, 1, ST_NumGeometries(geometry) from ne_50m_admin_0_countries UNION ALL SELECT name, value+1, maxv FROM my_generate_series WHERE value+1<=maxv) 		SELECT my_generate_series.*, ST_GeometryN(ne_50m_admin_0_countries.geometry, my_generate_series.value) as polygon FROM my_generate_series inner join ne_50m_admin_0_countries on my_generate_series.name = ne_50m_admin_0_countries.name 	) as t1 group by t1.name ) as tt1 inner join ( 	select name as name, polygon as polygon, ST_Area(polygon) as area from ( 		WITH RECURSIVE my_generate_series(name, value, maxv) AS ( 			select name, 1, ST_NumGeometries(geometry) from ne_50m_admin_0_countries 			UNION ALL 			SELECT name, value+1, maxv FROM my_generate_series 			WHERE value+1<=maxv 		) 		SELECT my_generate_series.*, ST_GeometryN(ne_50m_admin_0_countries.geometry, my_generate_series.value) as polygon FROM my_generate_series join ne_50m_admin_0_countries on my_generate_series.name = ne_50m_admin_0_countries.name 	) as t2 ) as tt2 ON tt1.name == tt2.name and tt1.area == tt2.area ) as o" -nln places -f GeoJSON ./data/$@ ./data/$<

# tippecanoe v1.36.0
# Output to directory
countries.mbtiles: countries.geojson
	tippecanoe --force -zg --coalesce-densest-as-needed --extend-zooms-if-still-dropping ./data/$< -o $@

places.mbtiles: places.geojson
	tippecanoe --force -r1 --cluster-distance=1 ./data/$< -o $@

create-tiles: countries.mbtiles places.mbtiles
	tile-join --force -e ./example/tiles -n "tiles" -N "Natural Earth Vector Tile" --no-tile-compression $^
	rm -rf ./data
	rm $^