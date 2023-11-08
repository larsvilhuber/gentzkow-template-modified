# A Stata + R + Python Docker Project

## Details

See [https://github.com/AEADataEditor/docker-stata-R-example](https://github.com/AEADataEditor/docker-stata-R-example) for details on creating and setup.

## Docker image

[aeadataeditor/aer-2021-0867:2022-03-19](https://hub.docker.com/r/aeadataeditor/aer-2021-0867:2022-03-19)

## Entrypoint

The entry point has been set to `/bin/bash`.

## Testing

```{bash}
docker run $DOCKEROPTS
   -v ${STATALIC}:/usr/local/stata/stata.lic
   -v $(pwd)/${codedir}:/code   
   -v $(pwd)/data:/data   
   $DOCKERIMG:$TAG  -l test.sh
```

## Running

You also need the Stata license for running it all. For convenience, use the `run.sh` script:

```{bash}
./run.sh 
```

