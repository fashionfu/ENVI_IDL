var axios = require("axios");

function reqJson1() {
    const options = {
        method: 'POST',
        url: 'http://localhost:9191/jobs',
        headers: {'content-type': 'application/json'},
        data: {
          "serviceName": 'ENVI',
          "taskName": 'SpectralIndex',
          "inputParameters": {
				input_raster: {
						url: 'http://localhost:9191/data/qb_boulder_msi',
						factory: 'URLRaster'
				},
				index: 'NDVI'
          }
        }
    };

    axios.request(options).then(function (response) {
        console.log(response.data);
    }).catch(function (error) {
        console.error(error);
    });
}

(() => {
    reqJson1()
})();