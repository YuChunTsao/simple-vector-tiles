#!/usr/bin/make

zip_url = https://www.naturalearthdata.com/http//www.naturalearthdata.com/download/50m/cultural/ne_50m_admin_0_countries.zip
filename = ne_50m_admin_0_countries

SHELL = /bin/sh

CURRENT_UID := $(shell id -u)
CURRENT_GID := $(shell id -g)

all: build-tiles

download-data:
	wget $(zip_url) -O $(filename).zip

unzip-data:
	unzip -o $(filename).zip -d ./data/
	rm -r $(filename).zip

create-geojson:
	echo "Create geojson from shapefile with ogr2ogr"
	make create-countries-geojson
	make create-places-geojson

create-countries-geojson:
	docker run --rm  --user ${CURRENT_UID}:${CURRENT_GID} -v $(CURDIR)/data:/data tsao84672776/gdal ogr2ogr -dialect sqlite -sql "SELECT name, geometry FROM ne_50m_admin_0_countries" -f GeoJSON ./data/countries.geojson -nln countries ./data/ne_50m_admin_0_countries.shp

create-places-geojson:
	docker run --rm  --user ${CURRENT_UID}:${CURRENT_GID} -v $(CURDIR)/data:/data tsao84672776/gdal ogr2ogr -dialect sqlite -sql "select * from (select tt1.name as name, ST_PointOnSurface(tt2.polygon) as Centroid from ( select name as name, max(ST_Area(polygon)) as area from ( WITH RECURSIVE my_generate_series(name, value, maxv) AS ( select name, 1, ST_NumGeometries(geometry) from ne_50m_admin_0_countries UNION ALL SELECT name, value+1, maxv FROM my_generate_series WHERE value+1<=maxv) 		SELECT my_generate_series.*, ST_GeometryN(ne_50m_admin_0_countries.geometry, my_generate_series.value) as polygon FROM my_generate_series inner join ne_50m_admin_0_countries on my_generate_series.name = ne_50m_admin_0_countries.name 	) as t1 group by t1.name ) as tt1 inner join ( 	select name as name, polygon as polygon, ST_Area(polygon) as area from ( 		WITH RECURSIVE my_generate_series(name, value, maxv) AS ( 			select name, 1, ST_NumGeometries(geometry) from ne_50m_admin_0_countries 			UNION ALL 			SELECT name, value+1, maxv FROM my_generate_series 			WHERE value+1<=maxv 		) 		SELECT my_generate_series.*, ST_GeometryN(ne_50m_admin_0_countries.geometry, my_generate_series.value) as polygon FROM my_generate_series join ne_50m_admin_0_countries on my_generate_series.name = ne_50m_admin_0_countries.name 	) as t2 ) as tt2 ON tt1.name == tt2.name and tt1.area == tt2.area ) as o" -nln places -f GeoJSON ./data/places.geojson ./data/ne_50m_admin_0_countries.shp

create-mbtiles:
	echo "Create mbtiles from geojson with tippecanoe"
	make create-countries-mbtiles
	make create-places-mbtiles

create-countries-mbtiles:
	docker run --rm --user ${CURRENT_UID}:${CURRENT_GID} -v $(CURDIR)/data:/data tsao84672776/tippecanoe tippecanoe --force -zg --coalesce-densest-as-needed --extend-zooms-if-still-dropping ./data/countries.geojson -o ./data/countries.mbtiles

create-places-mbtiles:
	docker run --rm --user ${CURRENT_UID}:${CURRENT_GID} -v $(CURDIR)/data:/data tsao84672776/tippecanoe tippecanoe --force -r1 --cluster-distance=1 ./data/places.geojson -o ./data/places.mbtiles
	
create-tiles-directory:
	docker run --rm --user ${CURRENT_UID}:${CURRENT_GID} -v $(CURDIR):/workspace -w /workspace tsao84672776/tippecanoe tile-join --force -e ./example/tiles -n "tiles" -N "Natural Earth Vector Tile" --no-tile-compression ./data/countries.mbtiles ./data/places.mbtiles

build-tiles: download-data unzip-data create-geojson create-mbtiles create-tiles-directory

run-example:
	@echo 🚀 "http://localhost:8080"
	docker run --rm --name thttpd -p 8080:80 -v $(CURDIR)/example:/var/www/http tsao84672776/thttpd