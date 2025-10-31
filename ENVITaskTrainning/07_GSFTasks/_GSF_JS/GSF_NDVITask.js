var axios = require("axios");

function reqJson1() {
    const options = {
        method: 'POST',
        url: 'http://localhost:9191/jobs',
        headers: {'content-type': 'application/json'},
        data: {
          "serviceName": 'ENVI',
          "taskName": 'GSF_NDVITask',
          "inputParameters": {
				input_file:'C:\\Works\\ENVITaskTrainning\\02_ENVITasks\\data\\beijing_miyun.dat',
				output_format : 'TIFF'
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