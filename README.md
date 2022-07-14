# Simple Vector Tiles

Create vector tiles with [Natural Earth](https://www.naturalearthdata.com/) data.

- Convert shapefile to geojson with `GDAL ogr2ogr`
- Create and merge mbtiles with `tippecanoe`

[Map Demo](https://yuchuntsao.github.io/simple-vector-tiles/)

## How To Use

### With docker

You need Docker.

Install [Docker](https://docs.docker.com/engine/install/).

Execute make to create tiles

```bash
make
```

### Without docker

You need [GDAL](https://gdal.org/download.html) and [tippecanoe](https://github.com/mapbox/tippecanoe)

```bash
$ gdalinfo --version
GDAL 3.0.4, released 2020/01/28

$ tippecanoe --version
tippecanoe v1.36.0
```

Execute make to create tiles

```bash
make -f create-tiles.mk
```

## Map example

```bash
make run-example
```

## References

- [Natural Earth Data](https://www.naturalearthdata.com/)
- [GDAL](https://gdal.org/)
- [mapbox/tippecanoe](https://github.com/mapbox/tippecanoe)
- [Mapbox GL JS - Style Specification](https://docs.mapbox.com/mapbox-gl-js/style-spec/)
- [Github Actions](https://docs.github.com/en/actions)
- [thttpd](https://acme.com/software/thttpd/)
- [sed, a stream editor](https://www.gnu.org/software/sed/manual/sed.html)
